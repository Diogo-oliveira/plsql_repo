/*-- Last Change Revision: $Rev: 1980720 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2021-02-24 11:42:17 +0000 (qua, 24 fev 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_exams IS 

    PROCEDURE get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar
    ) IS
    
    BEGIN
    
        IF i_table_name = 'EXAM'
        THEN
            SELECT /*+rule*/
             erd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM exam_req_det erd
             WHERE erd.id_exam IN (SELECT id_exam e
                                     FROM exam e
                                    WHERE e.rowid IN (SELECT column_value
                                                        FROM TABLE(i_rowids)));
        ELSIF i_table_name = 'EXAM_REQ'
        THEN
            SELECT /*+rule*/
             erd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM exam_req_det erd
             WHERE erd.id_exam_req IN (SELECT id_exam_req er
                                         FROM exam_req er
                                        WHERE er.rowid IN (SELECT column_value
                                                             FROM TABLE(i_rowids)));
        ELSIF i_table_name = 'EXAM_REQ_DET'
        THEN
            o_rowids := i_rowids;
        ELSIF i_table_name = 'EXAM_RESULT'
        THEN
            SELECT /*+rule*/
             erd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det IN (SELECT er.id_exam_req_det
                                             FROM exam_result er
                                            WHERE er.rowid IN (SELECT column_value
                                                                 FROM TABLE(i_rowids)));
        ELSIF i_table_name = 'EPIS_DOCUMENTATION'
        THEN
            SELECT rid
              BULK COLLECT
              INTO o_rowids
              FROM (SELECT /*+rule*/
                     erd.rowid rid
                      FROM exam_req_det erd
                     WHERE erd.id_exam_req_det IN
                           (SELECT ed.id_epis_context
                              FROM epis_documentation ed
                             WHERE ed.rowid IN (SELECT column_value
                                                  FROM TABLE(i_rowids))
                               AND ed.id_doc_area = pk_exam_constant.g_doc_area_exam
                               AND ed.flg_status = pk_touch_option.g_epis_bartchart_act)
                    UNION
                    SELECT /*+rule*/
                     erd.rowid rid
                      FROM exam_req_det erd
                     WHERE erd.id_exam_req_det IN
                           (SELECT eres.id_exam_req_det
                              FROM exam_result eres, epis_documentation ed
                             WHERE ed.rowid IN (SELECT column_value
                                                  FROM TABLE(i_rowids))
                               AND ed.id_doc_area = pk_exam_constant.g_doc_area_exam_result
                               AND ed.flg_status = pk_touch_option.g_epis_bartchart_act
                               AND eres.id_epis_documentation = ed.id_epis_documentation
                               AND eres.id_exam_result = ed.id_epis_context));
        
        ELSIF i_table_name = 'EXAM_MEDIA_ARCHIVE'
        THEN
            SELECT /*+rule*/
             erd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det IN (SELECT ema.id_exam_req_det
                                             FROM exam_media_archive ema
                                            WHERE ema.rowid IN (SELECT column_value
                                                                  FROM TABLE(i_rowids)));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_rowids := table_varchar();
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_data_rowid;

    FUNCTION get_exam_status_det_all
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN table_ea_struct IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
        l_table_ea_struct table_ea_struct := table_ea_struct(NULL);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_det(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_episode           => i_episode,
                                              i_flg_time          => i_flg_time,
                                              i_flg_status_det    => i_flg_status_det,
                                              i_flg_referral      => i_flg_referral,
                                              i_flg_status_result => i_flg_status_result,
                                              i_dt_req            => i_dt_req,
                                              i_dt_pend_req       => i_dt_pend_req,
                                              i_dt_begin          => i_dt_begin,
                                              o_status_str        => l_status_str,
                                              o_status_msg        => l_status_msg,
                                              o_status_icon       => l_status_icon,
                                              o_status_flg        => l_status_flg);
    
        SELECT t_ea_struct(l_status_str, l_status_msg, l_status_icon, l_status_flg)
          BULK COLLECT
          INTO l_table_ea_struct
          FROM (SELECT l_status_str, l_status_msg, l_status_icon, l_status_flg
                  FROM dual);
    
        RETURN l_table_ea_struct;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_det_all;

    FUNCTION get_exam_status_req_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN table_ea_struct IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
        l_table_ea_struct table_ea_struct := table_ea_struct(NULL);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_req(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              i_flg_time       => i_flg_time,
                                              i_flg_status_req => i_flg_status_req,
                                              i_dt_req         => i_dt_req,
                                              i_dt_begin       => i_dt_begin,
                                              o_status_str     => l_status_str,
                                              o_status_msg     => l_status_msg,
                                              o_status_icon    => l_status_icon,
                                              o_status_flg     => l_status_flg);
    
        SELECT t_ea_struct(l_status_str, l_status_msg, l_status_icon, l_status_flg)
          BULK COLLECT
          INTO l_table_ea_struct
          FROM (SELECT l_status_str, l_status_msg, l_status_icon, l_status_flg
                  FROM dual);
    
        RETURN l_table_ea_struct;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_req_all;

    PROCEDURE get_exam_status_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE,
        o_status_str        OUT exams_ea.status_str%TYPE,
        o_status_msg        OUT exams_ea.status_msg%TYPE,
        o_status_icon       OUT exams_ea.status_icon%TYPE,
        o_status_flg        OUT exams_ea.status_flg%TYPE
    ) IS
    
        l_display_type  VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200) := '';
        l_status_flg    VARCHAR2(200) := '';
        l_message_style VARCHAR2(200) := '';
        l_message_color VARCHAR2(200) := '';
        l_default_color VARCHAR2(200) := '';
        l_icon_color    VARCHAR2(200) := '';
    
        -- text 
        l_text VARCHAR2(200);
        -- icon
        l_aux VARCHAR2(200);
        -- date
        l_date_begin VARCHAR2(200);
    
        l_ref sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_AVAILABILITY', i_prof);
    
    BEGIN
    
        -- l_date_begin
        IF i_dt_pend_req IS NULL
        THEN
            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                               nvl(i_dt_begin, i_dt_req),
                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        ELSE
            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                               nvl(i_dt_pend_req, i_dt_begin),
                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        END IF;
    
        -- l_aux
        IF i_flg_referral IN
           (pk_exam_constant.g_flg_referral_r, pk_exam_constant.g_flg_referral_s, pk_exam_constant.g_flg_referral_i)
        THEN
            l_aux := 'EXAM_REQ_DET.FLG_REFERRAL';
        ELSE
            IF i_flg_status_det = pk_exam_constant.g_exam_sos
            THEN
                l_aux := 'EXAM_REQ_DET.FLG_STATUS';
            ELSIF i_flg_status_det IN (pk_exam_constant.g_exam_wtg_tde,
                                       pk_exam_constant.g_exam_tosched,
                                       pk_exam_constant.g_exam_sched,
                                       pk_exam_constant.g_exam_toexec,
                                       pk_exam_constant.g_exam_draft,
                                       pk_exam_constant.g_exam_exec,
                                       pk_exam_constant.g_exam_transp,
                                       pk_exam_constant.g_exam_end_transp,
                                       pk_exam_constant.g_exam_read,
                                       pk_exam_constant.g_exam_nr,
                                       pk_exam_constant.g_exam_cancel,
                                       pk_exam_constant.g_exam_req)
            THEN
                l_aux := 'EXAM_REQ_DET.FLG_STATUS';
            ELSIF i_flg_status_det = pk_exam_constant.g_exam_exterior
            THEN
                IF l_ref = pk_exam_constant.g_yes
                THEN
                    l_aux := 'EXAM_REQ_DET.FLG_STATUS';
                ELSE
                    l_aux := 'EXAM_REQ_DET.FLG_STATUS.PP';
                END IF;
            ELSIF i_flg_status_det = pk_exam_constant.g_exam_result
            THEN
                IF instr(i_flg_status_result, pk_exam_constant.g_exam_urgent) != 0
                THEN
                    l_aux := 'EXAM_REQ_DET.FLG_STATUS.URGENT';
                ELSE
                    IF i_flg_status_result = pk_exam_constant.g_exam_result_preliminary
                    THEN
                        l_aux := 'RESULT_STATUS.VALUE';
                    ELSE
                        l_aux := 'EXAM_REQ_DET.FLG_STATUS';
                    END IF;
                END IF;
            ELSIF i_flg_status_det = pk_exam_constant.g_exam_req
            THEN
                l_aux := NULL;
            ELSE
                IF i_flg_time = pk_exam_constant.g_flg_time_n
                THEN
                    l_aux := 'EXAM_REQ_DET.FLG_STATUS';
                ELSE
                    IF i_dt_begin IS NULL
                    THEN
                        l_aux := 'EXAM_REQ_DET.FLG_STATUS';
                    ELSE
                        l_aux := NULL;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        --l_text
        l_text := l_aux;
    
        -- l_display_type
        IF i_flg_referral IN
           (pk_exam_constant.g_flg_referral_r, pk_exam_constant.g_flg_referral_s, pk_exam_constant.g_flg_referral_i)
        THEN
            l_display_type := pk_alert_constant.g_display_type_icon;
        ELSE
            IF i_flg_status_det = pk_exam_constant.g_exam_sos
            THEN
                l_display_type := pk_alert_constant.g_display_type_icon;
            ELSIF i_flg_status_det IN (pk_exam_constant.g_exam_wtg_tde,
                                       pk_exam_constant.g_exam_tosched,
                                       pk_exam_constant.g_exam_sched,
                                       pk_exam_constant.g_exam_transp,
                                       pk_exam_constant.g_exam_end_transp,
                                       pk_exam_constant.g_exam_toexec,
                                       pk_exam_constant.g_exam_draft,
                                       pk_exam_constant.g_exam_exec,
                                       pk_exam_constant.g_exam_result,
                                       pk_exam_constant.g_exam_read,
                                       pk_exam_constant.g_exam_nr,
                                       pk_exam_constant.g_exam_cancel)
            THEN
                l_display_type := pk_alert_constant.g_display_type_icon;
            ELSIF i_flg_status_det = pk_exam_constant.g_exam_exterior
            THEN
                IF l_ref = pk_exam_constant.g_yes
                THEN
                    l_display_type := pk_alert_constant.g_display_type_date_icon;
                ELSE
                    l_display_type := pk_alert_constant.g_display_type_icon;
                END IF;
            ELSIF i_flg_status_det = pk_exam_constant.g_exam_req
            THEN
                l_display_type := pk_alert_constant.g_display_type_date;
            ELSE
                IF i_flg_time = pk_exam_constant.g_flg_time_n
                THEN
                    l_display_type := pk_alert_constant.g_display_type_icon;
                ELSE
                    IF i_dt_begin IS NULL
                    THEN
                        l_display_type := pk_alert_constant.g_display_type_icon;
                    ELSE
                        l_display_type := pk_alert_constant.g_display_type_date;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- l_back_color
        IF i_flg_referral IN
           (pk_exam_constant.g_flg_referral_r, pk_exam_constant.g_flg_referral_s, pk_exam_constant.g_flg_referral_i)
        THEN
            l_back_color := NULL;
        ELSE
            IF i_flg_status_det IN (pk_exam_constant.g_exam_sos,
                                    pk_exam_constant.g_exam_tosched,
                                    pk_exam_constant.g_exam_sched,
                                    pk_exam_constant.g_exam_req,
                                    pk_exam_constant.g_exam_transp,
                                    pk_exam_constant.g_exam_end_transp,
                                    pk_exam_constant.g_exam_toexec,
                                    pk_exam_constant.g_exam_exec,
                                    pk_exam_constant.g_exam_draft,
                                    pk_exam_constant.g_exam_result,
                                    pk_exam_constant.g_exam_read,
                                    pk_exam_constant.g_exam_nr,
                                    pk_exam_constant.g_exam_cancel)
            THEN
                l_back_color := pk_alert_constant.g_color_null;
            ELSIF i_flg_status_det = pk_exam_constant.g_exam_wtg_tde
            THEN
                l_back_color := pk_alert_constant.g_color_icon_dark_grey;
            ELSIF i_flg_status_det = pk_exam_constant.g_exam_exterior
            THEN
                IF l_ref = pk_exam_constant.g_yes
                THEN
                    l_back_color := pk_alert_constant.g_color_red;
                ELSE
                    l_back_color := pk_alert_constant.g_color_null;
                END IF;
            ELSE
                IF i_episode IS NULL
                THEN
                    IF i_dt_begin IS NULL
                    THEN
                        IF i_flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
                        THEN
                            l_back_color := pk_alert_constant.g_color_null;
                        ELSE
                            l_back_color := pk_alert_constant.g_color_green;
                        END IF;
                    ELSE
                        l_back_color := pk_alert_constant.g_color_null;
                    END IF;
                ELSE
                    IF i_dt_begin IS NULL
                    THEN
                        IF i_flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
                        THEN
                            l_back_color := pk_alert_constant.g_color_null;
                        ELSE
                            l_back_color := pk_alert_constant.g_color_red;
                        END IF;
                    ELSE
                        l_back_color := pk_alert_constant.g_color_null;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- l_status_flg
        IF i_flg_referral IN
           (pk_exam_constant.g_flg_referral_r, pk_exam_constant.g_flg_referral_s, pk_exam_constant.g_flg_referral_i)
        THEN
            l_status_flg := i_flg_referral;
        ELSE
            IF i_flg_status_det IN (pk_exam_constant.g_exam_wtg_tde,
                                    pk_exam_constant.g_exam_exterior,
                                    pk_exam_constant.g_exam_tosched,
                                    pk_exam_constant.g_exam_sched,
                                    pk_exam_constant.g_exam_transp,
                                    pk_exam_constant.g_exam_end_transp,
                                    pk_exam_constant.g_exam_toexec,
                                    pk_exam_constant.g_exam_draft,
                                    pk_exam_constant.g_exam_exec,
                                    pk_exam_constant.g_exam_read,
                                    pk_exam_constant.g_exam_nr,
                                    pk_exam_constant.g_exam_cancel,
                                    pk_exam_constant.g_exam_sos)
            THEN
                l_status_flg := i_flg_status_det;
            ELSIF i_flg_status_det = pk_exam_constant.g_exam_req
            THEN
                l_status_flg := NULL;
            ELSIF i_flg_status_det = pk_exam_constant.g_exam_result
            THEN
                IF i_flg_status_result = pk_exam_constant.g_exam_result_preliminary
                THEN
                    l_status_flg := i_flg_status_result;
                ELSE
                    l_status_flg := i_flg_status_det;
                END IF;
            ELSE
                IF i_episode IS NULL
                THEN
                    IF i_flg_time = pk_exam_constant.g_flg_time_n
                    THEN
                        IF i_dt_begin IS NULL
                        THEN
                            l_status_flg := i_flg_status_det;
                        ELSE
                            l_status_flg := NULL;
                        END IF;
                    END IF;
                ELSE
                    IF i_dt_begin IS NULL
                    THEN
                        l_status_flg := i_flg_status_det;
                    ELSE
                        l_status_flg := NULL;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- l_default_color
        IF i_flg_status_det = pk_exam_constant.g_exam_result
           AND instr(i_flg_status_result, pk_exam_constant.g_exam_urgent) != 0
        THEN
            l_default_color := pk_exam_constant.g_yes;
        ELSE
            l_default_color := pk_exam_constant.g_no;
        END IF;
    
        --l_icon_color
        IF i_flg_status_det = pk_exam_constant.g_exam_pending
           AND l_back_color IS NOT NULL
        THEN
            l_icon_color := pk_alert_constant.g_color_icon_light_grey;
        ELSIF i_flg_status_det = pk_exam_constant.g_exam_sos
        THEN
            l_icon_color := pk_alert_constant.g_color_icon_dark_grey;
        END IF;
    
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_status_flg,
                                     i_value_text    => l_aux,
                                     i_value_date    => l_date_begin,
                                     i_value_icon    => l_aux,
                                     i_back_color    => l_back_color,
                                     i_icon_color    => l_icon_color,
                                     i_message_style => l_message_style,
                                     i_message_color => l_message_color,
                                     i_default_color => l_default_color,
                                     o_status_str    => o_status_str,
                                     o_status_msg    => o_status_msg,
                                     o_status_icon   => o_status_icon,
                                     o_status_flg    => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END;

    FUNCTION get_exam_status_str_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_det(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_episode           => i_episode,
                                              i_flg_time          => i_flg_time,
                                              i_flg_status_det    => i_flg_status_det,
                                              i_flg_referral      => i_flg_referral,
                                              i_flg_status_result => i_flg_status_result,
                                              i_dt_req            => i_dt_req,
                                              i_dt_pend_req       => i_dt_pend_req,
                                              i_dt_begin          => i_dt_begin,
                                              o_status_str        => l_status_str,
                                              o_status_msg        => l_status_msg,
                                              o_status_icon       => l_status_icon,
                                              o_status_flg        => l_status_flg);
    
        RETURN l_status_str;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_str_det;

    FUNCTION get_exam_status_msg_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_det(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_episode           => i_episode,
                                              i_flg_time          => i_flg_time,
                                              i_flg_status_det    => i_flg_status_det,
                                              i_flg_referral      => i_flg_referral,
                                              i_flg_status_result => i_flg_status_result,
                                              i_dt_req            => i_dt_req,
                                              i_dt_pend_req       => i_dt_pend_req,
                                              i_dt_begin          => i_dt_begin,
                                              o_status_str        => l_status_str,
                                              o_status_msg        => l_status_msg,
                                              o_status_icon       => l_status_icon,
                                              o_status_flg        => l_status_flg);
    
        RETURN l_status_msg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_msg_det;

    FUNCTION get_exam_status_icon_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_det(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_episode           => i_episode,
                                              i_flg_time          => i_flg_time,
                                              i_flg_status_det    => i_flg_status_det,
                                              i_flg_referral      => i_flg_referral,
                                              i_flg_status_result => i_flg_status_result,
                                              i_dt_req            => i_dt_req,
                                              i_dt_pend_req       => i_dt_pend_req,
                                              i_dt_begin          => i_dt_begin,
                                              o_status_str        => l_status_str,
                                              o_status_msg        => l_status_msg,
                                              o_status_icon       => l_status_icon,
                                              o_status_flg        => l_status_flg);
    
        RETURN l_status_icon;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_icon_det;

    FUNCTION get_exam_status_flg_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_det(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_episode           => i_episode,
                                              i_flg_time          => i_flg_time,
                                              i_flg_status_det    => i_flg_status_det,
                                              i_flg_referral      => i_flg_referral,
                                              i_flg_status_result => i_flg_status_result,
                                              i_dt_req            => i_dt_req,
                                              i_dt_pend_req       => i_dt_pend_req,
                                              i_dt_begin          => i_dt_begin,
                                              o_status_str        => l_status_str,
                                              o_status_msg        => l_status_msg,
                                              o_status_icon       => l_status_icon,
                                              o_status_flg        => l_status_flg);
    
        RETURN l_status_flg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_flg_det;

    PROCEDURE get_exam_status_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE,
        o_status_str     OUT exams_ea.status_str_req%TYPE,
        o_status_msg     OUT exams_ea.status_msg_req%TYPE,
        o_status_icon    OUT exams_ea.status_icon_req%TYPE,
        o_status_flg     OUT exams_ea.status_flg_req%TYPE
    ) IS
    
        l_display_type  VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200) := '';
        l_status_flg    VARCHAR2(200) := '';
        l_message_style VARCHAR2(200) := '';
        l_message_color VARCHAR2(200) := '';
        l_default_color VARCHAR2(200) := '';
    
        -- text 
        l_text VARCHAR2(200);
        -- icon
        l_aux VARCHAR2(200);
        -- date
        l_date_begin VARCHAR2(200);
    
        l_ref sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_AVAILABILITY', i_prof);
    
    BEGIN
    
        -- l_date_begin
        l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                           nvl(i_dt_begin, i_dt_req),
                                                           pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
    
        -- l_aux
        IF i_flg_status_req = pk_exam_constant.g_exam_sos
        THEN
            l_aux := 'COMMON_M112';
        ELSE
            IF i_flg_status_req IN (pk_exam_constant.g_exam_req,
                                    pk_exam_constant.g_exam_tosched,
                                    pk_exam_constant.g_exam_sched,
                                    pk_exam_constant.g_exam_ongoing,
                                    pk_exam_constant.g_exam_partial,
                                    pk_exam_constant.g_exam_result,
                                    pk_exam_constant.g_exam_draft,
                                    pk_exam_constant.g_exam_read_partial,
                                    pk_exam_constant.g_exam_read,
                                    pk_exam_constant.g_exam_nr,
                                    pk_exam_constant.g_exam_cancel)
            THEN
                l_aux := 'EXAM_REQ.FLG_STATUS';
            ELSIF i_flg_status_req = pk_exam_constant.g_exam_exterior
            THEN
                IF l_ref = pk_exam_constant.g_yes
                THEN
                    l_aux := 'EXAM_REQ.FLG_STATUS';
                ELSE
                    l_aux := 'EXAM_REQ.FLG_STATUS.PP';
                END IF;
            ELSIF i_flg_status_req = pk_exam_constant.g_exam_req
            THEN
                l_aux := NULL;
            ELSIF i_flg_status_req = pk_exam_constant.g_exam_result || pk_exam_constant.g_exam_urgent
            THEN
                l_aux := 'EXAM_REQ.FLG_STATUS.URGENT';
            ELSE
                IF i_flg_time = pk_exam_constant.g_flg_time_n
                THEN
                    l_aux := 'EXAM_REQ.FLG_STATUS';
                ELSE
                    IF i_dt_begin IS NULL
                    THEN
                        l_aux := 'EXAM_REQ.FLG_STATUS';
                    ELSE
                        l_aux := NULL;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        --l_text
        l_text := l_aux;
    
        -- l_display_type
        IF i_flg_status_req = pk_exam_constant.g_exam_sos
        THEN
            l_display_type := pk_alert_constant.g_display_type_text;
        ELSE
            IF i_flg_status_req IN (pk_exam_constant.g_exam_tosched,
                                    pk_exam_constant.g_exam_sched,
                                    pk_exam_constant.g_exam_ongoing,
                                    pk_exam_constant.g_exam_partial,
                                    pk_exam_constant.g_exam_result,
                                    pk_exam_constant.g_exam_draft,
                                    pk_exam_constant.g_exam_read_partial,
                                    pk_exam_constant.g_exam_read,
                                    pk_exam_constant.g_exam_nr,
                                    pk_exam_constant.g_exam_cancel)
            THEN
                l_display_type := pk_alert_constant.g_display_type_icon;
            ELSIF i_flg_status_req = pk_exam_constant.g_exam_exterior
            THEN
                IF l_ref = pk_exam_constant.g_yes
                THEN
                    l_display_type := pk_alert_constant.g_display_type_date_icon;
                ELSE
                    l_display_type := pk_alert_constant.g_display_type_icon;
                END IF;
            ELSIF i_flg_status_req = pk_exam_constant.g_exam_req
            THEN
                l_display_type := pk_alert_constant.g_display_type_date;
            ELSE
                IF i_flg_time = pk_exam_constant.g_flg_time_n
                THEN
                    l_display_type := pk_alert_constant.g_display_type_icon;
                ELSE
                    IF i_dt_begin IS NULL
                    THEN
                        l_display_type := pk_alert_constant.g_display_type_icon;
                    ELSE
                        l_display_type := pk_alert_constant.g_display_type_date;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- l_back_color
        IF i_flg_status_req IN (pk_exam_constant.g_exam_tosched,
                                pk_exam_constant.g_exam_sched,
                                pk_exam_constant.g_exam_ongoing,
                                pk_exam_constant.g_exam_partial,
                                pk_exam_constant.g_exam_result,
                                pk_exam_constant.g_exam_draft,
                                pk_exam_constant.g_exam_read_partial,
                                pk_exam_constant.g_exam_read,
                                pk_exam_constant.g_exam_nr,
                                pk_exam_constant.g_exam_cancel)
        THEN
            l_back_color := pk_alert_constant.g_color_null;
        ELSIF i_flg_status_req = pk_exam_constant.g_exam_exterior
        THEN
            IF l_ref = pk_exam_constant.g_yes
            THEN
                l_back_color := pk_alert_constant.g_color_red;
            ELSE
                l_back_color := pk_alert_constant.g_color_null;
            END IF;
        ELSE
            IF i_episode IS NULL
            THEN
                IF i_dt_begin IS NULL
                THEN
                    IF i_flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
                    THEN
                        l_back_color := pk_alert_constant.g_color_null;
                    ELSE
                        l_back_color := pk_alert_constant.g_color_green;
                    END IF;
                ELSE
                    l_back_color := pk_alert_constant.g_color_null;
                END IF;
            ELSE
                IF i_dt_begin IS NULL
                THEN
                    IF i_flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
                    THEN
                        l_back_color := pk_alert_constant.g_color_null;
                    ELSE
                        l_back_color := pk_alert_constant.g_color_red;
                    END IF;
                ELSE
                    l_back_color := pk_alert_constant.g_color_null;
                END IF;
            END IF;
        END IF;
    
        -- l_status_flg
        IF i_flg_status_req IN (pk_exam_constant.g_exam_exterior,
                                pk_exam_constant.g_exam_tosched,
                                pk_exam_constant.g_exam_sched,
                                pk_exam_constant.g_exam_ongoing,
                                pk_exam_constant.g_exam_partial,
                                pk_exam_constant.g_exam_result,
                                pk_exam_constant.g_exam_draft,
                                pk_exam_constant.g_exam_read_partial,
                                pk_exam_constant.g_exam_read,
                                pk_exam_constant.g_exam_nr,
                                pk_exam_constant.g_exam_cancel)
        THEN
            l_status_flg := i_flg_status_req;
        ELSIF i_flg_status_req = pk_exam_constant.g_exam_req
        THEN
            l_status_flg := NULL;
        ELSE
            IF i_episode IS NULL
            THEN
                IF i_flg_time = pk_exam_constant.g_flg_time_n
                THEN
                    IF i_dt_begin IS NULL
                    THEN
                        l_status_flg := i_flg_status_req;
                    ELSE
                        l_status_flg := NULL;
                    END IF;
                END IF;
            ELSE
                IF i_dt_begin IS NULL
                THEN
                    l_status_flg := i_flg_status_req;
                ELSE
                    l_status_flg := NULL;
                END IF;
            END IF;
        END IF;
    
        -- l_message_style
        IF i_flg_status_req = pk_exam_constant.g_exam_sos
        THEN
            IF length(pk_message.get_message(i_lang, l_text)) > 3
            THEN
                l_message_style := 'PRNSmallStyle';
            ELSE
                l_message_style := 'PRNStyle';
            END IF;
        END IF;
    
        -- l_default_color
        IF i_flg_status_req = pk_exam_constant.g_exam_result || pk_exam_constant.g_exam_urgent
        THEN
            l_default_color := pk_exam_constant.g_yes;
        ELSE
            l_default_color := pk_exam_constant.g_no;
        END IF;
    
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_status_flg,
                                     i_value_text    => l_text,
                                     i_value_date    => l_date_begin,
                                     i_value_icon    => l_aux,
                                     i_back_color    => l_back_color,
                                     i_message_style => l_message_style,
                                     i_message_color => l_message_color,
                                     i_default_color => l_default_color,
                                     o_status_str    => o_status_str,
                                     o_status_msg    => o_status_msg,
                                     o_status_icon   => o_status_icon,
                                     o_status_flg    => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END;

    FUNCTION get_exam_status_str_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_req(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              i_flg_time       => i_flg_time,
                                              i_flg_status_req => i_flg_status_req,
                                              i_dt_req         => i_dt_req,
                                              i_dt_begin       => i_dt_begin,
                                              o_status_str     => l_status_str,
                                              o_status_msg     => l_status_msg,
                                              o_status_icon    => l_status_icon,
                                              o_status_flg     => l_status_flg);
    
        RETURN l_status_str;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_str_req;

    FUNCTION get_exam_status_msg_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_req(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              i_flg_time       => i_flg_time,
                                              i_flg_status_req => i_flg_status_req,
                                              i_dt_req         => i_dt_req,
                                              i_dt_begin       => i_dt_begin,
                                              o_status_str     => l_status_str,
                                              o_status_msg     => l_status_msg,
                                              o_status_icon    => l_status_icon,
                                              o_status_flg     => l_status_flg);
    
        RETURN l_status_msg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_msg_req;

    FUNCTION get_exam_status_icon_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_req(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              i_flg_time       => i_flg_time,
                                              i_flg_status_req => i_flg_status_req,
                                              i_dt_req         => i_dt_req,
                                              i_dt_begin       => i_dt_begin,
                                              o_status_str     => l_status_str,
                                              o_status_msg     => l_status_msg,
                                              o_status_icon    => l_status_icon,
                                              o_status_flg     => l_status_flg);
    
        RETURN l_status_icon;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_icon_req;

    FUNCTION get_exam_status_flg_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_exams.get_exam_status_req(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              i_flg_time       => i_flg_time,
                                              i_flg_status_req => i_flg_status_req,
                                              i_dt_req         => i_dt_req,
                                              i_dt_begin       => i_dt_begin,
                                              o_status_str     => l_status_str,
                                              o_status_msg     => l_status_msg,
                                              o_status_icon    => l_status_icon,
                                              o_status_flg     => l_status_flg);
    
        RETURN l_status_flg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_exam_status_flg_req;

    PROCEDURE set_exams
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row exams_ea%ROWTYPE;
        l_rowids      table_varchar;
    
        l_flg_result VARCHAR2(3 CHAR);
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_error := 'GET EXAMS ROWIDS';
        get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'EXAMS_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process update event
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- Loop through changed records
            g_error := 'LOOP UPDATED';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                FOR r_cur IN (SELECT *
                                FROM (SELECT row_number() over(PARTITION BY erd.id_exam_req_det ORDER BY eres.dt_exam_result_tstz DESC) rn,
                                             er.id_exam_req,
                                             erd.id_exam_req_det,
                                             eres.id_exam_result,
                                             erd.id_exam,
                                             er.id_exam_group,
                                             er.dt_req_tstz dt_req,
                                             erd.dt_target_tstz dt_begin,
                                             er.dt_pend_req_tstz dt_pend_req,
                                             eres.dt_exam_result_tstz dt_result,
                                             erd.flg_priority priority,
                                             e.flg_type,
                                             e.id_exam_cat,
                                             e.flg_available,
                                             decode(erd.notes || erd.notes_tech ||
                                                    dbms_lob.substr(erd.notes_patient, 3800),
                                                    NULL,
                                                    pk_exam_constant.g_no,
                                                    pk_exam_constant.g_yes) flg_notes,
                                             decode((SELECT 1
                                                      FROM exam_media_archive ema
                                                     WHERE ema.id_exam_req_det = erd.id_exam_req_det
                                                       AND ema.flg_type = pk_exam_constant.g_media_archive_exam_doc
                                                       AND ema.flg_status = pk_exam_constant.g_active
                                                       AND rownum = 1),
                                                    1,
                                                    pk_exam_constant.g_yes,
                                                    pk_exam_constant.g_no) flg_doc,
                                             er.flg_time,
                                             er.flg_status flg_status_req,
                                             erd.flg_status flg_status_det,
                                             erd.flg_referral,
                                             er.id_prof_req,
                                             erd.id_prof_performed,
                                             erd.start_time,
                                             erd.end_time,
                                             (SELECT ed.id_epis_documentation
                                                FROM epis_documentation ed
                                               WHERE ed.id_episode = ep.id_episode
                                                 AND ed.id_doc_area = pk_exam_constant.g_doc_area_exam
                                                 AND ed.flg_status = pk_touch_option.g_epis_bartchart_act
                                                 AND ed.id_epis_context = erd.id_exam_req_det) id_epis_doc_perform,
                                             (SELECT ed.notes
                                                FROM epis_documentation ed
                                               WHERE ed.id_episode = ep.id_episode
                                                 AND ed.id_doc_area = pk_exam_constant.g_doc_area_exam
                                                 AND ed.flg_status = pk_touch_option.g_epis_bartchart_act
                                                 AND ed.id_epis_context = erd.id_exam_req_det) desc_perform_notes,
                                             (SELECT ed.id_epis_documentation
                                                FROM epis_documentation ed
                                               WHERE ed.id_episode = ep.id_episode
                                                 AND ed.id_doc_area = pk_exam_constant.g_doc_area_exam_result
                                                 AND ed.flg_status = pk_touch_option.g_epis_bartchart_act
                                                 AND ed.id_epis_context = eres.id_exam_result) id_epis_doc_result,
                                             (SELECT ed.notes
                                                FROM epis_documentation ed
                                               WHERE ed.id_episode = ep.id_episode
                                                 AND ed.id_doc_area = pk_exam_constant.g_doc_area_exam_result
                                                 AND ed.flg_status = pk_touch_option.g_epis_bartchart_act
                                                 AND ed.id_epis_context = eres.id_exam_result) desc_result,
                                             rs.value flg_status_result,
                                             eres.id_abnormality,
                                             eres.flg_relevant,
                                             erd.id_exam_codification,
                                             erd.id_room,
                                             erd.id_movement,
                                             erd.id_task_dependency,
                                             erd.flg_req_origin_module,
                                             erd.notes,
                                             erd.notes_scheduler,
                                             dbms_lob.substr(erd.notes_patient, 3800) notes_patient,
                                             erd.notes_tech notes_technician,
                                             erd.notes_cancel,
                                             er.id_patient,
                                             v.id_visit,
                                             er.id_episode,
                                             er.id_episode_origin,
                                             er.id_prev_episode
                                        FROM exam e,
                                             exam_req er,
                                             (SELECT /*+opt_estimate (table erd rows=1)*/
                                               *
                                                FROM exam_req_det erd
                                               WHERE erd.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                    *
                                                                     FROM TABLE(l_rowids) t)
                                                 AND erd.flg_status != pk_exam_constant.g_exam_predefined) erd,
                                             (SELECT *
                                                FROM exam_result er
                                               WHERE er.flg_status != pk_exam_constant.g_exam_cancel) eres,
                                             result_status rs,
                                             episode ep,
                                             episode ep_origin,
                                             visit v
                                       WHERE erd.id_exam_req_det = eres.id_exam_req_det(+)
                                         AND eres.id_result_status = rs.id_result_status(+)
                                         AND erd.id_exam = e.id_exam
                                         AND erd.id_exam_req = er.id_exam_req
                                         AND er.id_episode = ep.id_episode(+)
                                         AND er.id_episode_origin = ep_origin.id_episode(+)
                                         AND ep.id_visit = v.id_visit(+))
                               WHERE rn = 1)
                LOOP
                    IF r_cur.flg_status_det = pk_exam_constant.g_exam_result
                    THEN
                        IF r_cur.priority != pk_exam_constant.g_exam_normal
                        THEN
                            l_flg_result := r_cur.flg_status_result || pk_exam_constant.g_exam_urgent;
                        ELSE
                            IF r_cur.id_abnormality IS NOT NULL
                               AND r_cur.id_abnormality != 7
                            THEN
                                l_flg_result := r_cur.flg_status_result || pk_exam_constant.g_exam_urgent;
                            ELSE
                                l_flg_result := r_cur.flg_status_result;
                            END IF;
                        END IF;
                    ELSE
                        l_flg_result := r_cur.flg_status_result;
                    END IF;
                
                    g_error := 'GET EXAM STATUS REQ';
                    pk_ea_logic_exams.get_exam_status_req(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_episode        => r_cur.id_episode,
                                                          i_flg_time       => r_cur.flg_time,
                                                          i_flg_status_req => CASE
                                                                                  WHEN r_cur.flg_status_det =
                                                                                       pk_exam_constant.g_exam_result
                                                                                       AND
                                                                                       r_cur.priority != pk_exam_constant.g_exam_normal THEN
                                                                                   r_cur.flg_status_req || pk_exam_constant.g_exam_urgent
                                                                                  ELSE
                                                                                   r_cur.flg_status_req
                                                                              END,
                                                          i_dt_req         => r_cur.dt_req,
                                                          i_dt_begin       => r_cur.dt_begin,
                                                          o_status_str     => l_new_rec_row.status_str_req,
                                                          o_status_msg     => l_new_rec_row.status_msg_req,
                                                          o_status_icon    => l_new_rec_row.status_icon_req,
                                                          o_status_flg     => l_new_rec_row.status_flg_req);
                
                    g_error := 'GET EXAM STATUS DET';
                    pk_ea_logic_exams.get_exam_status_det(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_episode           => r_cur.id_episode,
                                                          i_flg_time          => r_cur.flg_time,
                                                          i_flg_status_det    => r_cur.flg_status_det,
                                                          i_flg_referral      => r_cur.flg_referral,
                                                          i_flg_status_result => l_flg_result,
                                                          i_dt_req            => r_cur.dt_req,
                                                          i_dt_pend_req       => r_cur.dt_pend_req,
                                                          i_dt_begin          => r_cur.dt_begin,
                                                          o_status_str        => l_new_rec_row.status_str,
                                                          o_status_msg        => l_new_rec_row.status_msg,
                                                          o_status_icon       => l_new_rec_row.status_icon,
                                                          o_status_flg        => l_new_rec_row.status_flg);
                
                    g_error                             := 'DEFINE new record for EXAMS_EA';
                    l_new_rec_row.id_exam_req           := r_cur.id_exam_req;
                    l_new_rec_row.id_exam_req_det       := r_cur.id_exam_req_det;
                    l_new_rec_row.id_exam_result        := r_cur.id_exam_result;
                    l_new_rec_row.id_exam               := r_cur.id_exam;
                    l_new_rec_row.id_exam_group         := r_cur.id_exam_group;
                    l_new_rec_row.dt_req                := r_cur.dt_req;
                    l_new_rec_row.dt_begin              := r_cur.dt_begin;
                    l_new_rec_row.dt_pend_req           := r_cur.dt_pend_req;
                    l_new_rec_row.dt_result             := r_cur.dt_result;
                    l_new_rec_row.priority              := r_cur.priority;
                    l_new_rec_row.flg_type              := r_cur.flg_type;
                    l_new_rec_row.id_exam_cat           := r_cur.id_exam_cat;
                    l_new_rec_row.flg_available         := r_cur.flg_available;
                    l_new_rec_row.flg_notes             := r_cur.flg_notes;
                    l_new_rec_row.flg_doc               := r_cur.flg_doc;
                    l_new_rec_row.flg_time              := r_cur.flg_time;
                    l_new_rec_row.flg_status_req        := r_cur.flg_status_req;
                    l_new_rec_row.flg_status_det        := r_cur.flg_status_det;
                    l_new_rec_row.flg_referral          := r_cur.flg_referral;
                    l_new_rec_row.id_prof_req           := r_cur.id_prof_req;
                    l_new_rec_row.id_prof_performed     := r_cur.id_prof_performed;
                    l_new_rec_row.start_time            := r_cur.start_time;
                    l_new_rec_row.end_time              := r_cur.end_time;
                    l_new_rec_row.id_epis_doc_perform   := r_cur.id_epis_doc_perform;
                    l_new_rec_row.desc_perform_notes    := r_cur.desc_perform_notes;
                    l_new_rec_row.id_epis_doc_result    := r_cur.id_epis_doc_result;
                    l_new_rec_row.desc_result           := r_cur.desc_result;
                    l_new_rec_row.flg_status_result     := r_cur.flg_status_result;
                    l_new_rec_row.flg_relevant          := r_cur.flg_relevant;
                    l_new_rec_row.id_exam_codification  := r_cur.id_exam_codification;
                    l_new_rec_row.id_room               := r_cur.id_room;
                    l_new_rec_row.id_movement           := r_cur.id_movement;
                    l_new_rec_row.notes                 := r_cur.notes;
                    l_new_rec_row.notes_scheduler       := r_cur.notes_scheduler;
                    l_new_rec_row.notes_technician      := r_cur.notes_technician;
                    l_new_rec_row.notes_patient         := r_cur.notes_patient;
                    l_new_rec_row.notes_cancel          := r_cur.notes_cancel;
                    l_new_rec_row.id_patient            := r_cur.id_patient;
                    l_new_rec_row.id_visit              := r_cur.id_visit;
                    l_new_rec_row.id_episode            := r_cur.id_episode;
                    l_new_rec_row.id_episode_origin     := r_cur.id_episode_origin;
                    l_new_rec_row.id_prev_episode       := r_cur.id_prev_episode;
                    l_new_rec_row.id_task_dependency    := r_cur.id_task_dependency;
                    l_new_rec_row.flg_req_origin_module := r_cur.flg_req_origin_module;
                
                    g_error := 'TS_EXAMS_EA.UPD';
                    IF i_source_table_name = 'EXAM_REQ_DET'
                       AND i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        ts_exams_ea.ins(rec_in => l_new_rec_row, rows_out => l_rows_out);
                    ELSE
                        ts_exams_ea.upd(id_exam_req_det_in       => l_new_rec_row.id_exam_req_det,
                                        id_exam_req_in           => l_new_rec_row.id_exam_req,
                                        id_exam_result_in        => l_new_rec_row.id_exam_result,
                                        id_exam_in               => l_new_rec_row.id_exam,
                                        id_exam_group_in         => l_new_rec_row.id_exam_group,
                                        dt_req_in                => l_new_rec_row.dt_req,
                                        dt_begin_in              => l_new_rec_row.dt_begin,
                                        dt_pend_req_in           => l_new_rec_row.dt_pend_req,
                                        dt_result_in             => l_new_rec_row.dt_result,
                                        priority_in              => l_new_rec_row.priority,
                                        flg_type_in              => l_new_rec_row.flg_type,
                                        id_exam_cat_in           => l_new_rec_row.id_exam_cat,
                                        flg_available_in         => l_new_rec_row.flg_available,
                                        flg_notes_in             => l_new_rec_row.flg_notes,
                                        flg_doc_in               => l_new_rec_row.flg_doc,
                                        flg_time_in              => l_new_rec_row.flg_time,
                                        flg_status_req_in        => l_new_rec_row.flg_status_req,
                                        flg_status_det_in        => l_new_rec_row.flg_status_det,
                                        flg_referral_in          => l_new_rec_row.flg_referral,
                                        id_prof_req_in           => l_new_rec_row.id_prof_req,
                                        id_prof_performed_in     => l_new_rec_row.id_prof_performed,
                                        id_prof_performed_nin    => FALSE,
                                        start_time_in            => l_new_rec_row.start_time,
                                        start_time_nin           => FALSE,
                                        end_time_in              => l_new_rec_row.end_time,
                                        end_time_nin             => FALSE,
                                        id_epis_doc_perform_in   => l_new_rec_row.id_epis_doc_perform,
                                        id_epis_doc_perform_nin  => FALSE,
                                        id_epis_doc_result_in    => l_new_rec_row.id_epis_doc_result,
                                        id_epis_doc_result_nin   => FALSE,
                                        desc_perform_notes_in    => l_new_rec_row.desc_perform_notes,
                                        desc_perform_notes_nin   => FALSE,
                                        desc_result_in           => l_new_rec_row.desc_result,
                                        desc_result_nin          => FALSE,
                                        flg_status_result_in     => l_new_rec_row.flg_status_result,
                                        flg_relevant_in          => l_new_rec_row.flg_relevant,
                                        id_exam_codification_in  => l_new_rec_row.id_exam_codification,
                                        id_room_in               => l_new_rec_row.id_room,
                                        id_movement_in           => l_new_rec_row.id_movement,
                                        notes_in                 => l_new_rec_row.notes,
                                        notes_technician_in      => l_new_rec_row.notes_technician,
                                        notes_patient_in         => l_new_rec_row.notes_patient,
                                        notes_cancel_in          => l_new_rec_row.notes_cancel,
                                        id_patient_in            => l_new_rec_row.id_patient,
                                        id_visit_in              => l_new_rec_row.id_visit,
                                        id_episode_in            => l_new_rec_row.id_episode,
                                        id_episode_origin_in     => l_new_rec_row.id_episode_origin,
                                        id_prev_episode_in       => l_new_rec_row.id_prev_episode,
                                        id_task_dependency_in    => l_new_rec_row.id_task_dependency,
                                        flg_req_origin_module_in => l_new_rec_row.flg_req_origin_module,
                                        status_str_req_in        => l_new_rec_row.status_str_req,
                                        status_msg_req_in        => l_new_rec_row.status_msg_req,
                                        status_icon_req_in       => l_new_rec_row.status_icon_req,
                                        status_flg_req_in        => l_new_rec_row.status_flg_req,
                                        status_str_in            => l_new_rec_row.status_str,
                                        status_msg_in            => l_new_rec_row.status_msg,
                                        status_icon_in           => l_new_rec_row.status_icon,
                                        status_flg_in            => l_new_rec_row.status_flg,
                                        rows_out                 => l_rows_out);
                    
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_exams;

    PROCEDURE set_grid_task_exams
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_grid_task grid_task%ROWTYPE;
        l_rowids    table_varchar;
    
        l_mess1_d VARCHAR2(200 CHAR);
        l_mess1_n VARCHAR2(200 CHAR);
    
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    
        l_dt_str_1 VARCHAR2(200 CHAR);
        l_dt_str_2 VARCHAR2(200 CHAR);
    
        l_dt_1 VARCHAR2(200 CHAR);
        l_dt_2 VARCHAR2(200 CHAR);
    
        l_workflow                sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_WORKFLOW', i_prof);
        l_ref                     sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_AVAILABILITY', i_prof);
        l_status_in_patient_grids sys_config.value%TYPE := pk_sysconfig.get_config('EXAMS_STATUS_IN_PATIENT_GRIDS',
                                                                                   i_prof);
    
        l_status table_varchar := table_varchar();
    
        l_error_out t_error_out;
    
    BEGIN
    
        g_error := 'GET EXAMS ROWIDS';
        get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'GRID_TASK',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process update event
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- Loop through changed records
            g_error := 'LOOP UPDATED';
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
                IF l_workflow = pk_exam_constant.g_yes
                THEN
                    SELECT pk_utils.str_split_c(l_status_in_patient_grids, '|')
                      INTO l_status
                      FROM dual;
                
                    FOR r_cur IN (SELECT *
                                    FROM (SELECT nvl(er.id_episode, er.id_episode_origin) id_episode,
                                                 er.id_patient,
                                                 e.flg_type
                                            FROM (SELECT /*+opt_estimate (table erd rows=1)*/
                                                   *
                                                    FROM exam_req_det erd
                                                   WHERE erd.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                        *
                                                                         FROM TABLE(l_rowids) t)
                                                     AND erd.flg_status NOT IN
                                                         (pk_exam_constant.g_exam_predefined,
                                                          pk_exam_constant.g_exam_draft)) erd,
                                                 exam_req er,
                                                 exam e
                                           WHERE erd.id_exam_req = er.id_exam_req
                                             AND erd.id_exam = e.id_exam))
                    LOOP
                        SELECT MAX(status_string_med) status_string_med, MAX(status_string_enf) status_string_enf
                          INTO l_mess1_d, l_mess1_n
                          FROM (SELECT decode(rank_med,
                                              1,
                                              pk_utils.get_status_string(i_lang,
                                                                         i_prof,
                                                                         pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   id_episode,
                                                                                                                   flg_time,
                                                                                                                   flg_status,
                                                                                                                   flg_referral,
                                                                                                                   flg_status_result,
                                                                                                                   dt_req_tstz,
                                                                                                                   dt_pend_req_tstz,
                                                                                                                   dt_begin_tstz),
                                                                         pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   id_episode,
                                                                                                                   flg_time,
                                                                                                                   flg_status,
                                                                                                                   flg_referral,
                                                                                                                   flg_status_result,
                                                                                                                   dt_req_tstz,
                                                                                                                   dt_pend_req_tstz,
                                                                                                                   dt_begin_tstz),
                                                                         pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                                                    i_prof,
                                                                                                                    id_episode,
                                                                                                                    flg_time,
                                                                                                                    flg_status,
                                                                                                                    flg_referral,
                                                                                                                    flg_status_result,
                                                                                                                    dt_req_tstz,
                                                                                                                    dt_pend_req_tstz,
                                                                                                                    dt_begin_tstz),
                                                                         pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   id_episode,
                                                                                                                   flg_time,
                                                                                                                   flg_status,
                                                                                                                   flg_referral,
                                                                                                                   flg_status_result,
                                                                                                                   dt_req_tstz,
                                                                                                                   dt_pend_req_tstz,
                                                                                                                   dt_begin_tstz)),
                                              NULL) status_string_med,
                                       decode(rank_enf,
                                              1,
                                              pk_utils.get_status_string(i_lang,
                                                                         i_prof,
                                                                         pk_ea_logic_exams.get_exam_status_str_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   id_episode,
                                                                                                                   flg_time,
                                                                                                                   flg_status,
                                                                                                                   flg_referral,
                                                                                                                   flg_status_result,
                                                                                                                   dt_req_tstz,
                                                                                                                   dt_pend_req_tstz,
                                                                                                                   dt_begin_tstz),
                                                                         pk_ea_logic_exams.get_exam_status_msg_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   id_episode,
                                                                                                                   flg_time,
                                                                                                                   flg_status,
                                                                                                                   flg_referral,
                                                                                                                   flg_status_result,
                                                                                                                   dt_req_tstz,
                                                                                                                   dt_pend_req_tstz,
                                                                                                                   dt_begin_tstz),
                                                                         pk_ea_logic_exams.get_exam_status_icon_det(i_lang,
                                                                                                                    i_prof,
                                                                                                                    id_episode,
                                                                                                                    flg_time,
                                                                                                                    flg_status,
                                                                                                                    flg_referral,
                                                                                                                    flg_status_result,
                                                                                                                    dt_req_tstz,
                                                                                                                    dt_pend_req_tstz,
                                                                                                                    dt_begin_tstz),
                                                                         pk_ea_logic_exams.get_exam_status_flg_det(i_lang,
                                                                                                                   i_prof,
                                                                                                                   id_episode,
                                                                                                                   flg_time,
                                                                                                                   flg_status,
                                                                                                                   flg_referral,
                                                                                                                   flg_status_result,
                                                                                                                   dt_req_tstz,
                                                                                                                   dt_pend_req_tstz,
                                                                                                                   dt_begin_tstz)),
                                              NULL) status_string_enf
                                  FROM (SELECT t.id_exam_req_det,
                                               t.id_episode,
                                               t.flg_time,
                                               t.flg_status,
                                               t.flg_referral,
                                               t.flg_status_result,
                                               t.dt_req_tstz,
                                               t.dt_pend_req_tstz,
                                               t.dt_begin_tstz,
                                               row_number() over(ORDER BY t.rank_med) rank_med,
                                               row_number() over(ORDER BY t.rank_enf) rank_enf
                                          FROM (SELECT t.*,
                                                       decode(t.flg_status,
                                                              'F',
                                                              row_number() over(ORDER BY t.rank DESC),
                                                              'R',
                                                              row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)) + 10000,
                                                              row_number() over(ORDER BY t.rank,
                                                                   coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)) + 20000) rank_med,
                                                       decode(t.flg_status,
                                                              'R',
                                                              row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)),
                                                              row_number() over(ORDER BY t.rank,
                                                                   coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)) + 20000) rank_enf
                                                  FROM (SELECT t.*,
                                                               decode(flg_urgent,
                                                                      pk_exam_constant.g_yes,
                                                                      (SELECT pk_sysdomain.get_rank(i_lang,
                                                                                                    'EXAM_REQ_DET.FLG_STATUS.URGENT',
                                                                                                    t.flg_status)
                                                                         FROM dual) + 1000,
                                                                      (SELECT pk_sysdomain.get_rank(i_lang,
                                                                                                    'EXAM_REQ_DET.FLG_STATUS',
                                                                                                    t.flg_status)
                                                                         FROM dual)) rank
                                                          FROM (SELECT erd.id_exam_req_det,
                                                                       er.id_episode,
                                                                       er.flg_time,
                                                                       erd.flg_status,
                                                                       erd.flg_referral,
                                                                       erd.dt_target_tstz,
                                                                       CASE
                                                                            WHEN erd.flg_status =
                                                                                 pk_exam_constant.g_exam_result THEN
                                                                             CASE
                                                                                 WHEN er.priority != pk_exam_constant.g_exam_normal
                                                                                      OR (eres.id_abnormality IS NOT NULL AND
                                                                                      eres.id_abnormality != 7) THEN
                                                                                  rs.value || pk_exam_constant.g_exam_urgent
                                                                                 ELSE
                                                                                  rs.value
                                                                             END
                                                                            ELSE
                                                                             rs.value
                                                                        END flg_status_result,
                                                                       er.dt_req_tstz,
                                                                       er.dt_pend_req_tstz,
                                                                       erd.dt_target_tstz dt_begin_tstz,
                                                                       CASE
                                                                            WHEN er.priority != pk_exam_constant.g_exam_normal
                                                                                 OR (eres.id_abnormality IS NOT NULL AND
                                                                                 eres.id_abnormality != 7) THEN
                                                                             pk_exam_constant.g_yes
                                                                            ELSE
                                                                             pk_exam_constant.g_no
                                                                        END flg_urgent
                                                                  FROM exam_req      er,
                                                                       exam_req_det  erd,
                                                                       exam          e,
                                                                       exam_result   eres,
                                                                       result_status rs
                                                                 WHERE (er.id_episode = r_cur.id_episode OR
                                                                       er.id_prev_episode = r_cur.id_episode OR
                                                                       er.id_episode_origin = r_cur.id_episode)
                                                                   AND er.id_exam_req = erd.id_exam_req
                                                                   AND erd.flg_status IN
                                                                       (SELECT /*+opt_estimate (table s rows=1)*/
                                                                         column_value
                                                                          FROM TABLE(l_status) s)
                                                                   AND (erd.flg_referral NOT IN
                                                                       (pk_exam_constant.g_flg_referral_r,
                                                                         pk_exam_constant.g_flg_referral_s,
                                                                         pk_exam_constant.g_flg_referral_i) OR
                                                                       erd.flg_referral IS NULL)
                                                                   AND erd.id_exam = e.id_exam
                                                                   AND e.flg_type = r_cur.flg_type
                                                                   AND erd.id_exam_req_det = eres.id_exam_req_det(+)
                                                                   AND eres.id_result_status = rs.id_result_status(+)
                                                                UNION ALL
                                                                SELECT erd.id_exam_req_det,
                                                                       er.id_episode,
                                                                       er.flg_time,
                                                                       erd.flg_status,
                                                                       erd.flg_referral,
                                                                       erd.dt_target_tstz,
                                                                       CASE
                                                                           WHEN er.priority != pk_exam_constant.g_exam_normal
                                                                                OR (eres.id_abnormality IS NOT NULL AND
                                                                                eres.id_abnormality != 7) THEN
                                                                            rs.value || pk_exam_constant.g_exam_urgent
                                                                           ELSE
                                                                            rs.value
                                                                       END flg_status_result,
                                                                       er.dt_req_tstz,
                                                                       er.dt_pend_req_tstz,
                                                                       erd.dt_target_tstz dt_begin_tstz,
                                                                       CASE
                                                                           WHEN er.priority != pk_exam_constant.g_exam_normal
                                                                                OR (eres.id_abnormality IS NOT NULL AND
                                                                                eres.id_abnormality != 7) THEN
                                                                            pk_exam_constant.g_yes
                                                                           ELSE
                                                                            pk_exam_constant.g_no
                                                                       END flg_urgent
                                                                  FROM exam_req      er,
                                                                       exam_req_det  erd,
                                                                       exam          e,
                                                                       exam_result   eres,
                                                                       result_status rs,
                                                                       episode       epis
                                                                 WHERE er.id_patient = r_cur.id_patient
                                                                   AND er.id_episode != r_cur.id_episode
                                                                   AND er.id_exam_req = erd.id_exam_req
                                                                   AND (erd.flg_referral NOT IN
                                                                       (pk_exam_constant.g_flg_referral_r,
                                                                         pk_exam_constant.g_flg_referral_s,
                                                                         pk_exam_constant.g_flg_referral_i) OR
                                                                       erd.flg_referral IS NULL)
                                                                   AND er.flg_status = pk_exam_constant.g_exam_result
                                                                   AND erd.id_exam = e.id_exam
                                                                   AND e.flg_type = r_cur.flg_type
                                                                   AND erd.id_exam_req_det = eres.id_exam_req_det
                                                                   AND eres.id_result_status = rs.id_result_status(+)
                                                                   AND (er.id_episode = epis.id_episode OR
                                                                       er.id_prev_episode = epis.id_episode OR
                                                                       er.id_episode_origin = epis.id_episode)
                                                                   AND epis.id_epis_type NOT IN
                                                                       (pk_alert_constant.g_epis_type_emergency,
                                                                        pk_alert_constant.g_epis_type_inpatient,
                                                                        pk_alert_constant.g_epis_type_operating)) t
                                                         WHERE l_ref = pk_exam_constant.g_yes
                                                            OR (l_ref = pk_exam_constant.g_no AND
                                                               t.flg_status != pk_exam_constant.g_exam_exterior)) t) t)
                                 WHERE rank_med = 1
                                    OR rank_enf = 1);
                    
                        IF r_cur.flg_type = pk_exam_constant.g_type_img
                        THEN
                            IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_intern_name => 'GRID_IMAGE',
                                                             o_id_shortcut => l_shortcut,
                                                             o_error       => l_error_out)
                            THEN
                                l_shortcut := 0;
                            END IF;
                        ELSE
                            IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_intern_name => 'GRID_OTH_EXAM',
                                                             o_id_shortcut => l_shortcut,
                                                             o_error       => l_error_out)
                            THEN
                                l_shortcut := 0;
                            END IF;
                        END IF;
                    
                        g_error := 'GET SHORTCUT - DOCTOR';
                        IF l_mess1_d IS NOT NULL
                        THEN
                            IF regexp_like(l_mess1_d, '^\|D')
                            THEN
                                l_dt_str_1 := regexp_replace(l_mess1_d, '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*', '\1');
                                l_dt_str_2 := regexp_replace(l_mess1_d, '^\|D\w{0,1}\|\d{14}\|.*\|(\d{14})\|.*', '\1');
                            
                                l_dt_1 := pk_date_utils.to_char_insttimezone(i_prof,
                                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           l_dt_str_1,
                                                                                                           NULL),
                                                                             'YYYYMMDDHH24MISS TZR');
                            
                                l_dt_2 := pk_date_utils.to_char_insttimezone(i_prof,
                                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           l_dt_str_2,
                                                                                                           NULL),
                                                                             'YYYYMMDDHH24MISS TZR');
                            
                                IF l_dt_str_1 = l_dt_str_2
                                THEN
                                    l_mess1_d := regexp_replace(l_mess1_d, l_dt_str_1, l_dt_1);
                                ELSE
                                    l_mess1_d := regexp_replace(l_mess1_d, l_dt_str_1, l_dt_1);
                                    l_mess1_d := regexp_replace(l_mess1_d, l_dt_str_2, l_dt_2);
                                END IF;
                            ELSE
                                l_dt_str_2 := regexp_replace(l_mess1_d, '^\|\w{0,2}\|.*\|(\d{14})\|.*', '\1');
                                l_dt_2     := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                 pk_date_utils.get_string_tstz(i_lang,
                                                                                                               i_prof,
                                                                                                               l_dt_str_2,
                                                                                                               NULL),
                                                                                 'YYYYMMDDHH24MISS TZR');
                                l_mess1_d  := regexp_replace(l_mess1_d, l_dt_str_2, l_dt_2);
                            END IF;
                        
                            IF r_cur.flg_type = pk_exam_constant.g_type_img
                            THEN
                                l_grid_task.img_exam_d := l_shortcut || l_mess1_d;
                            ELSE
                                l_grid_task.oth_exam_d := l_shortcut || l_mess1_d;
                            END IF;
                        END IF;
                    
                        g_error := 'GET SHORTCUT - NURSE';
                        IF l_mess1_n IS NOT NULL
                        THEN
                            IF regexp_like(l_mess1_n, '^\|D')
                            THEN
                                l_dt_str_1 := regexp_replace(l_mess1_n, '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*', '\1');
                                l_dt_str_2 := regexp_replace(l_mess1_n, '^\|D\w{0,1}\|\d{14}\|.*\|(\d{14})\|.*', '\1');
                            
                                l_dt_1 := pk_date_utils.to_char_insttimezone(i_prof,
                                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           l_dt_str_1,
                                                                                                           NULL),
                                                                             'YYYYMMDDHH24MISS TZR');
                            
                                l_dt_2 := pk_date_utils.to_char_insttimezone(i_prof,
                                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                                           i_prof,
                                                                                                           l_dt_str_2,
                                                                                                           NULL),
                                                                             'YYYYMMDDHH24MISS TZR');
                            
                                IF l_dt_str_1 = l_dt_str_2
                                THEN
                                    l_mess1_n := regexp_replace(l_mess1_n, l_dt_str_1, l_dt_1);
                                ELSE
                                    l_mess1_n := regexp_replace(l_mess1_n, l_dt_str_1, l_dt_1);
                                    l_mess1_n := regexp_replace(l_mess1_n, l_dt_str_2, l_dt_2);
                                END IF;
                            ELSE
                                l_dt_str_2 := regexp_replace(l_mess1_n, '^\|\w{0,2}\|.*\|(\d{14})\|.*', '\1');
                                l_dt_2     := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                 pk_date_utils.get_string_tstz(i_lang,
                                                                                                               i_prof,
                                                                                                               l_dt_str_2,
                                                                                                               NULL),
                                                                                 'YYYYMMDDHH24MISS TZR');
                                l_mess1_n  := regexp_replace(l_mess1_n, l_dt_str_2, l_dt_2);
                            END IF;
                        
                            IF r_cur.flg_type = pk_exam_constant.g_type_img
                            THEN
                                l_grid_task.img_exam_n := l_shortcut || l_mess1_n;
                            ELSE
                                l_grid_task.oth_exam_n := l_shortcut || l_mess1_n;
                            END IF;
                        END IF;
                    
                        l_grid_task.id_episode := r_cur.id_episode;
                    
                        IF l_grid_task.id_episode IS NOT NULL
                        THEN
                            IF r_cur.flg_type = pk_exam_constant.g_type_img
                            THEN
                                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode (I)';
                                IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_episode      => l_grid_task.id_episode,
                                                                img_exam_d_in  => l_grid_task.img_exam_d,
                                                                img_exam_d_nin => FALSE,
                                                                img_exam_n_in  => l_grid_task.img_exam_n,
                                                                img_exam_n_nin => FALSE,
                                                                o_error        => l_error_out)
                                THEN
                                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                END IF;
                            ELSE
                                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode (E)';
                                IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_episode      => l_grid_task.id_episode,
                                                                oth_exam_d_in  => l_grid_task.oth_exam_d,
                                                                oth_exam_d_nin => FALSE,
                                                                oth_exam_n_in  => l_grid_task.oth_exam_n,
                                                                oth_exam_n_nin => FALSE,
                                                                o_error        => l_error_out)
                                THEN
                                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                END IF;
                            END IF;
                        
                            IF l_grid_task.img_exam_d IS NULL
                               AND l_grid_task.img_exam_n IS NULL
                               AND l_grid_task.oth_exam_d IS NULL
                               AND l_grid_task.oth_exam_n IS NULL
                            THEN
                                g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode';
                                IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                                     i_episode => l_grid_task.id_episode,
                                                                     o_error   => l_error_out)
                                THEN
                                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                END IF;
                            END IF;
                        END IF;
                    
                        BEGIN
                            g_error := 'SELECT ID_PREV_EPISODE';
                            SELECT e.id_prev_episode
                              INTO l_grid_task.id_episode
                              FROM episode e
                             WHERE e.id_episode = r_cur.id_episode;
                        
                            IF l_grid_task.id_episode IS NOT NULL
                            THEN
                                IF r_cur.flg_type = pk_exam_constant.g_type_img
                                THEN
                                    g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_prev_episode (I)';
                                    IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_episode      => l_grid_task.id_episode,
                                                                    img_exam_d_in  => l_grid_task.img_exam_d,
                                                                    img_exam_d_nin => FALSE,
                                                                    img_exam_n_in  => l_grid_task.img_exam_n,
                                                                    img_exam_n_nin => FALSE,
                                                                    o_error        => l_error_out)
                                    THEN
                                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                    END IF;
                                ELSE
                                    g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_prev_episode (E)';
                                    IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_episode      => l_grid_task.id_episode,
                                                                    oth_exam_d_in  => l_grid_task.oth_exam_d,
                                                                    oth_exam_d_nin => FALSE,
                                                                    oth_exam_n_in  => l_grid_task.oth_exam_n,
                                                                    oth_exam_n_nin => FALSE,
                                                                    o_error        => l_error_out)
                                    THEN
                                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                    END IF;
                                END IF;
                            
                                IF l_grid_task.img_exam_d IS NULL
                                   AND l_grid_task.img_exam_n IS NULL
                                   AND l_grid_task.oth_exam_d IS NULL
                                   AND l_grid_task.oth_exam_n IS NULL
                                THEN
                                    g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode';
                                    IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                                         i_episode => l_grid_task.id_episode,
                                                                         o_error   => l_error_out)
                                    THEN
                                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                    END IF;
                                END IF;
                            END IF;
                        EXCEPTION
                            WHEN no_data_found THEN
                                NULL;
                        END;
                    
                        BEGIN
                            g_error := 'SELECT ID_EPISODE_ORIGIN';
                            SELECT DISTINCT er.id_episode_origin
                              INTO l_grid_task.id_episode
                              FROM exam_req er
                             WHERE er.id_episode_origin IS NOT NULL
                               AND er.id_episode = r_cur.id_episode;
                        
                            IF l_grid_task.id_episode IS NOT NULL
                            THEN
                                IF r_cur.flg_type = pk_exam_constant.g_type_img
                                THEN
                                    g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode_origin (I)';
                                    IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_episode      => l_grid_task.id_episode,
                                                                    img_exam_d_in  => l_grid_task.img_exam_d,
                                                                    img_exam_d_nin => FALSE,
                                                                    img_exam_n_in  => l_grid_task.img_exam_n,
                                                                    img_exam_n_nin => FALSE,
                                                                    o_error        => l_error_out)
                                    THEN
                                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                    END IF;
                                ELSE
                                    g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode_origin (E)';
                                    IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_episode      => l_grid_task.id_episode,
                                                                    oth_exam_d_in  => l_grid_task.oth_exam_d,
                                                                    oth_exam_d_nin => FALSE,
                                                                    oth_exam_n_in  => l_grid_task.oth_exam_n,
                                                                    oth_exam_n_nin => FALSE,
                                                                    o_error        => l_error_out)
                                    THEN
                                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                    END IF;
                                END IF;
                            
                                IF l_grid_task.img_exam_d IS NULL
                                   AND l_grid_task.img_exam_n IS NULL
                                   AND l_grid_task.oth_exam_d IS NULL
                                   AND l_grid_task.oth_exam_n IS NULL
                                THEN
                                    g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode_origin';
                                    IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                                         i_episode => l_grid_task.id_episode,
                                                                         o_error   => l_error_out)
                                    THEN
                                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                    END IF;
                                END IF;
                            END IF;
                        EXCEPTION
                            WHEN no_data_found THEN
                                NULL;
                        END;
                    END LOOP;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_exams;

    PROCEDURE set_task_timeline_exams
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row      task_timeline_ea%ROWTYPE;
        l_func_proc_name   VARCHAR2(30) := 'SET_TASK_TIMELINE_EXAMS';
        l_name_table_ea    VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_rowids           table_varchar;
        l_process_name     VARCHAR2(30);
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
        l_flg_status_prn   exam_req_det.flg_status%TYPE := 'S';
    
        o_rowids    table_varchar;
        l_error_out t_error_out;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(g_error);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => l_name_table_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert and update event
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
        
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                g_error := 'GET EXAMS ROWIDS';
                pk_alertlog.log_debug(g_error);
                get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                FOR r_cur IN (SELECT *
                                FROM (SELECT /*+opt_estimate (table erd rows=1)*/
                                       row_number() over(PARTITION BY eres.id_exam_req_det ORDER BY eres.dt_exam_result_tstz DESC) rn,
                                       erd.id_exam_req_det,
                                       er.dt_req_tstz dt_req,
                                       nvl(er.dt_pend_req_tstz, er.dt_begin_tstz) dt_begin,
                                       NULL dt_end,
                                       er.flg_time,
                                       erd.flg_status flg_status_det,
                                       erd.flg_referral,
                                       er.id_prof_req,
                                       er.id_episode_origin,
                                       er.dt_pend_req_tstz dt_pend_req,
                                       v.id_patient,
                                       er.id_episode,
                                       v.id_visit,
                                       --
                                       pk_alert_constant.g_flg_type_viewer_exams flg_type_viewer,
                                       er.id_institution,
                                       nvl(pk_exams_external_api_db.get_alias_code_translation(i_lang,
                                                                                               i_prof,
                                                                                               e.code_exam,
                                                                                               NULL),
                                           e.code_exam) code_description,
                                       NULL universal_desc_clob,
                                       erd.id_task_dependency,
                                       decode(erd.flg_status,
                                              pk_exam_constant.g_exam_req,
                                              row_number()
                                              over(ORDER BY decode(erd.flg_referral,
                                                          NULL,
                                                          pk_sysdomain.get_rank(i_lang,
                                                                                'EXAM_REQ_DET.FLG_STATUS',
                                                                                erd.flg_status),
                                                          pk_sysdomain.get_rank(i_lang,
                                                                                'EXAM_REQ_DET.FLG_REFERRAL',
                                                                                erd.flg_referral)),
                                                   coalesce(er.dt_pend_req_tstz, er.dt_begin_tstz, er.dt_req_tstz)),
                                              row_number()
                                              over(ORDER BY decode(erd.flg_referral,
                                                          NULL,
                                                          pk_sysdomain.get_rank(i_lang,
                                                                                'EXAM_REQ_DET.FLG_STATUS',
                                                                                erd.flg_status),
                                                          pk_sysdomain.get_rank(i_lang,
                                                                                'EXAM_REQ_DET.FLG_REFERRAL',
                                                                                erd.flg_referral)),
                                                   coalesce(er.dt_pend_req_tstz, er.dt_begin_tstz, er.dt_req_tstz) DESC)) rank,
                                       e.id_exam_cat,
                                       'EXAM_CAT.CODE_EXAM_CAT.' || e.id_exam_cat code_group,
                                       nvl(erd.flg_prn, pk_alert_constant.g_no) flg_sos,
                                       erd.id_exam,
                                       'EXAM.CODE_EXAM.' || erd.id_exam code_desc_sub_group,
                                       decode(erd.id_order_recurrence, NULL, NULL, erd.id_exam) id_ref_group,
                                       decode(erd.flg_status,
                                              pk_exam_constant.g_exam_result,
                                              l_flg_outdated,
                                              pk_exam_constant.g_exam_read,
                                              l_flg_outdated,
                                              pk_alert_constant.g_exam_det_pend, -- pendent ('D')
                                              l_flg_outdated,
                                              pk_alert_constant.g_exam_det_tosched, -- not yet schedule ('PA')
                                              l_flg_outdated,
                                              l_flg_not_outdated) flg_outdated,
                                       erd.id_order_recurrence id_task_aggregator,
                                       ep.flg_status flg_status_epis,
                                       CASE
                                            WHEN erd.flg_status IN
                                                 (pk_exam_constant.g_exam_result, pk_exam_constant.g_exam_read) THEN
                                             pk_prog_notes_constants.g_task_finalized_f
                                            WHEN erd.flg_status IN (pk_grid.g_exam_req_tosched, pk_grid.g_exam_req_sched) THEN
                                             pk_prog_notes_constants.g_task_pending_d
                                            WHEN erd.flg_status = pk_alert_constant.g_exam_det_pend THEN
                                             CASE
                                                 WHEN er.flg_time = pk_alert_constant.g_flg_time_e THEN
                                                  pk_prog_notes_constants.g_task_ongoing_o
                                                 ELSE
                                                  pk_prog_notes_constants.g_task_pending_d
                                             END
                                            ELSE
                                             pk_prog_notes_constants.g_task_ongoing_o
                                        END flg_ongoing,
                                       pk_alert_constant.g_yes flg_normal,
                                       decode(erd.id_order_recurrence, NULL, erd.id_prof_performed, NULL) id_prof_exec,
                                       e.flg_type,
                                       coalesce(eres.dt_exam_result_tstz,
                                                erd.dt_performed_reg,
                                                erd.dt_last_update_tstz,
                                                er.dt_req_tstz) dt_last_update,
                                       e.flg_technical,
                                       erd.dt_performed_reg dt_execution,
                                       erd.flg_priority flg_priority
                                        FROM exam_req_det erd
                                        LEFT JOIN exam_result eres
                                          ON (erd.id_exam_req_det = eres.id_exam_req_det)
                                       INNER JOIN exam e
                                          ON (erd.id_exam = e.id_exam)
                                       INNER JOIN exam_req er
                                          ON (erd.id_exam_req = er.id_exam_req)
                                       INNER JOIN episode ep
                                          ON (nvl(er.id_episode, nvl(er.id_episode_origin, er.id_episode_destination)) =
                                             ep.id_episode)
                                       INNER JOIN visit v
                                          ON (ep.id_visit = v.id_visit)
                                       WHERE erd.flg_status != pk_exam_constant.g_exam_predefined
                                         AND erd.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                            *
                                                             FROM TABLE(l_rowids) t))
                               WHERE rn = 1)
                LOOP
                
                    g_error := 'GET EXAM STATUS';
                    pk_ea_logic_exams.get_exam_status_det(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_episode           => r_cur.id_episode,
                                                          i_flg_time          => r_cur.flg_time,
                                                          i_flg_status_det    => r_cur.flg_status_det,
                                                          i_flg_referral      => r_cur.flg_referral,
                                                          i_flg_status_result => NULL,
                                                          i_dt_req            => r_cur.dt_req,
                                                          i_dt_pend_req       => r_cur.dt_pend_req,
                                                          i_dt_begin          => r_cur.dt_begin,
                                                          o_status_str        => l_new_rec_row.status_str,
                                                          o_status_msg        => l_new_rec_row.status_msg,
                                                          o_status_icon       => l_new_rec_row.status_icon,
                                                          o_status_flg        => l_new_rec_row.status_flg);
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task := CASE
                                                    WHEN r_cur.flg_type = pk_exam_constant.g_type_img THEN --imaging exams                                                    
                                                     pk_prog_notes_constants.g_task_img_exams_req
                                                    ELSE
                                                     pk_prog_notes_constants.g_task_other_exams_req
                                                END;
                    l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_exams;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid  := r_cur.id_exam_req_det;
                    l_new_rec_row.dt_req         := r_cur.dt_req;
                    l_new_rec_row.dt_begin       := nvl(r_cur.dt_pend_req, r_cur.dt_begin);
                    l_new_rec_row.dt_end         := r_cur.dt_end;
                    l_new_rec_row.flg_status_req := r_cur.flg_status_det;
                    --
                    l_new_rec_row.flg_type_viewer     := r_cur.flg_type_viewer;
                    l_new_rec_row.id_prof_req         := r_cur.id_prof_req;
                    l_new_rec_row.id_patient          := r_cur.id_patient;
                    l_new_rec_row.id_episode          := nvl(r_cur.id_episode, r_cur.id_episode_origin);
                    l_new_rec_row.id_visit            := r_cur.id_visit;
                    l_new_rec_row.id_institution      := r_cur.id_institution;
                    l_new_rec_row.code_description    := r_cur.code_description;
                    l_new_rec_row.universal_desc_clob := r_cur.universal_desc_clob;
                    l_new_rec_row.flg_outdated        := r_cur.flg_outdated;
                    l_new_rec_row.rank                := r_cur.rank;
                    l_new_rec_row.id_group_import     := r_cur.id_exam_cat;
                    l_new_rec_row.code_desc_group     := r_cur.code_group;
                    l_new_rec_row.flg_sos             := r_cur.flg_sos;
                
                    l_new_rec_row.id_ref_group       := r_cur.id_ref_group;
                    l_new_rec_row.id_task_aggregator := r_cur.id_task_aggregator;
                    l_new_rec_row.flg_ongoing        := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal         := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec       := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments   := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update     := r_cur.dt_last_update;
                    l_new_rec_row.flg_technical      := r_cur.flg_technical;
                    l_new_rec_row.dt_execution       := r_cur.dt_execution;
                    l_new_rec_row.id_task_related    := r_cur.id_exam_req_det;
                    l_new_rec_row.flg_stat           := r_cur.flg_priority;
                
                    --
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    --
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF l_new_rec_row.flg_status_req IN (pk_alert_constant.g_exam_req_req, -- Required ('R')
                                                        pk_alert_constant.g_exam_det_pend, -- pendent ('D')
                                                        pk_alert_constant.g_exam_req_sched, -- schedule ('A')
                                                        pk_alert_constant.g_exam_det_tosched, -- not yet schedule ('PA')
                                                        pk_alert_constant.g_exam_req_partial, -- Partial results ('P')
                                                        pk_alert_constant.g_exam_req_result, -- with Result ('F')
                                                        pk_alert_constant.g_exam_det_ext, -- Exterior ('X')
                                                        l_flg_status_prn) --PRN/SOS
                       AND r_cur.flg_status_epis != pk_alert_constant.g_cancelled
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = pk_alert_constant.g_tl_table_name_exams
                           AND tte.id_tl_task IN (pk_prog_notes_constants.g_task_img_exams_req,
                                                  pk_prog_notes_constants.g_task_other_exams_req);
                    
                        -- IF exists one registrie, information should be UPDATED in TASK_TIMELINE_EA table for this registrie
                        IF l_update_reg > 0
                        THEN
                            l_process_name  := 'UPDATE';
                            l_event_into_ea := 'U';
                        ELSE
                            -- IF information doesn't exist in TASK_TIMELINE_EA table, it is necessary insert that registrie
                            l_process_name  := 'INSERT';
                            l_event_into_ea := 'I';
                        END IF;
                    ELSE
                        --
                        -- Information in states that are not relevant are DELETED
                        IF r_cur.flg_status_epis IN
                           (pk_alert_constant.g_cancelled, pk_alert_constant.g_exam_deq_not_done)
                           OR l_new_rec_row.flg_status_req IN
                           (pk_alert_constant.g_exam_det_canc, pk_exam_constant.g_exam_predefined) -- Canceled ('C')
                        THEN
                            l_process_name  := 'DELETE';
                            l_event_into_ea := 'D';
                        ELSE
                            l_process_name             := 'UPDATE';
                            l_event_into_ea            := 'U';
                            l_new_rec_row.flg_outdated := l_flg_outdated;
                        END IF;
                    END IF;
                
                    /*
                    * Opera絥s a executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE: 
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(g_error);
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => TRUE,
                                                id_institution_in  => l_new_rec_row.id_institution,
                                                --
                                                dt_req_nin          => TRUE,
                                                dt_req_in           => l_new_rec_row.dt_req,
                                                id_prof_req_nin     => TRUE,
                                                id_prof_req_in      => l_new_rec_row.id_prof_req,
                                                flg_type_viewer_nin => TRUE,
                                                flg_type_viewer_in  => l_new_rec_row.flg_type_viewer,
                                                --
                                                dt_begin_nin => TRUE,
                                                dt_begin_in  => l_new_rec_row.dt_begin,
                                                dt_end_nin   => TRUE,
                                                dt_end_in    => l_new_rec_row.dt_end,
                                                --
                                                flg_status_req_nin => FALSE,
                                                flg_status_req_in  => l_new_rec_row.flg_status_req,
                                                status_str_nin     => FALSE,
                                                status_str_in      => l_new_rec_row.status_str,
                                                status_msg_nin     => FALSE,
                                                status_msg_in      => l_new_rec_row.status_msg,
                                                status_icon_nin    => FALSE,
                                                status_icon_in     => l_new_rec_row.status_icon,
                                                status_flg_nin     => FALSE,
                                                status_flg_in      => l_new_rec_row.status_flg,
                                                --
                                                table_name_nin          => FALSE,
                                                table_name_in           => l_new_rec_row.table_name,
                                                flg_show_method_nin     => FALSE,
                                                flg_show_method_in      => l_new_rec_row.flg_show_method,
                                                code_description_nin    => FALSE,
                                                code_description_in     => l_new_rec_row.code_description,
                                                universal_desc_clob_nin => TRUE,
                                                universal_desc_clob_in  => l_new_rec_row.universal_desc_clob,
                                                rank_nin                => TRUE,
                                                rank_in                 => l_new_rec_row.rank,
                                                id_group_import_nin     => TRUE,
                                                id_group_import_in      => l_new_rec_row.id_group_import,
                                                code_desc_group_nin     => TRUE,
                                                code_desc_group_in      => l_new_rec_row.code_desc_group,
                                                dt_execution_nin        => TRUE,
                                                dt_execution_in         => l_new_rec_row.dt_execution,
                                                flg_sos_nin             => FALSE,
                                                flg_sos_in              => l_new_rec_row.flg_sos,
                                                --
                                                flg_outdated_nin => TRUE,
                                                flg_outdated_in  => l_new_rec_row.flg_outdated,
                                                
                                                id_ref_group_nin       => TRUE,
                                                id_ref_group_in        => r_cur.id_ref_group,
                                                id_task_aggregator_nin => TRUE,
                                                id_task_aggregator_in  => r_cur.id_task_aggregator,
                                                flg_ongoing_nin        => TRUE,
                                                flg_ongoing_in         => r_cur.flg_ongoing,
                                                flg_normal_nin         => TRUE,
                                                flg_normal_in          => r_cur.flg_normal,
                                                id_prof_exec_nin       => TRUE,
                                                id_prof_exec_in        => r_cur.id_prof_exec,
                                                flg_has_comments_nin   => TRUE,
                                                flg_has_comments_in    => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in      => l_new_rec_row.dt_last_update,
                                                flg_technical_in       => l_new_rec_row.flg_technical,
                                                id_task_related_in     => l_new_rec_row.id_task_related,
                                                id_task_related_nin    => TRUE,
                                                flg_stat_in            => l_new_rec_row.flg_stat,
                                                flg_stat_nin           => TRUE,
                                                --
                                                rows_out => o_rowids);
                        IF o_rowids.count = 0
                        THEN
                            g_error := 'TS_TASK_TIMELINE_EA.INS';
                            pk_alertlog.log_debug(g_error);
                            ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                        END IF;
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE g_excp_invalid_event_type;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_proc_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_task_timeline_exams;

    /*******************************************************************************************************************************************
    * Name:                           SET_TASK_TIMELINE_EXAM_RES
    * Description:                    Function that updates exam results information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.2.0.7
    * @since                          08/Feb/2012
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_exam_res
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row    task_timeline_ea%ROWTYPE;
        l_func_proc_name VARCHAR2(30) := 'SET_TASK_TIMELINE_EXAM_RES';
        l_name_table_ea  VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name   VARCHAR2(30);
        l_event_into_ea  VARCHAR2(1);
        l_update_reg     NUMBER(24);
    
        l_res_status_final_f CONSTANT result_status.value%TYPE := 'F';
    
        o_rowids    table_varchar;
        l_error_out t_error_out;
    
        l_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
        CURSOR exam_cur(i_rowids IN table_varchar) IS
            SELECT *
              FROM (SELECT /*+opt_estimate (table er rows=1)*/
                     row_number() over(PARTITION BY er.id_exam_result ORDER BY er.dt_exam_result_tstz DESC) rn,
                     er.id_exam_result,
                     er.dt_exam_result_tstz,
                     rs.value flg_status_res,
                     nvl(er.id_prof_read, er.id_professional) id_professional,
                     decode(rs.value,
                            l_res_status_final_f,
                            pk_ea_logic_tasktimeline.g_flg_outdated,
                            pk_exam_constant.g_exam_result_cancel,
                            pk_ea_logic_tasktimeline.g_flg_outdated,
                            pk_ea_logic_tasktimeline.g_flg_not_outdated) flg_outdated,
                     er.id_prof_cancel,
                     nvl(er.flg_relevant, 'N') flg_relevant,
                     ep.id_patient,
                     ep.id_episode,
                     ep.id_visit,
                     --
                     pk_alert_constant.g_flg_type_viewer_exams flg_type_viewer,
                     er.id_institution,
                     e.id_exam_cat,
                     'EXAM_CAT.CODE_EXAM_CAT.' || e.id_exam_cat code_group,
                     e.id_exam,
                     'EXAM.CODE_EXAM.' || e.id_exam code_desc_sub_group,
                     erd.start_time,
                     decode(nvl(er.flg_status, pk_exam_constant.g_exam_result_active),
                            pk_exam_constant.g_exam_result_active,
                            decode(rs.value,
                                   l_res_status_final_f,
                                   pk_prog_notes_constants.g_task_finalized_f,
                                   pk_exam_constant.g_exam_result_cancel,
                                   pk_prog_notes_constants.g_task_finalized_f,
                                   pk_prog_notes_constants.g_task_ongoing_o),
                            pk_prog_notes_constants.g_task_finalized_f) flg_ongoing,
                     pk_alert_constant.g_yes flg_normal,
                     er.id_professional id_prof_exec,
                     CASE
                          WHEN er.notes_result IS NULL
                               OR dbms_lob.compare(er.notes_result, empty_clob()) = 0 THEN
                           pk_alert_constant.g_no
                          ELSE
                           pk_alert_constant.g_yes
                      END flg_has_comments,
                     er.notes_result universal_desc_clob,
                     ep.flg_status flg_status_epis,
                     nvl(er.dt_prof_read_tstz, er.dt_exam_result_tstz) dt_last_update,
                     e.code_exam,
                     e.flg_type,
                     e.flg_technical,
                     er.id_exam_req_det
                      FROM exam_result er
                     INNER JOIN exam e
                        ON (er.id_exam = e.id_exam)
                     INNER JOIN exam_req_det erd
                        ON erd.id_exam_req_det = er.id_exam_req_det
                     INNER JOIN exam_req erq
                        ON erd.id_exam_req = erq.id_exam_req
                      LEFT JOIN result_status rs
                        ON rs.id_result_status = er.id_result_status
                     INNER JOIN episode ep
                        ON nvl(erq.id_episode_origin, erq.id_episode) = ep.id_episode
                     INNER JOIN visit v
                        ON (ep.id_visit = v.id_visit)
                     WHERE er.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                         *
                                          FROM TABLE(i_rowids) t))
             WHERE rn = 1;
    
        TYPE cur_type IS TABLE OF exam_cur%ROWTYPE;
        my_tbl cur_type;
    
        -- ***************************************************
        PROCEDURE process_exam_task
        (
            i_verify_task IN VARCHAR2,
            r_cur         IN exam_cur%ROWTYPE
        ) IS
            l_xx      NUMBER;
            l_tl_task task_timeline_ea.id_tl_task%TYPE;
        BEGIN
        
            IF i_verify_task = 'N'
            THEN
                l_tl_task := pk_prog_notes_constants.g_task_exam_results;
            ELSE
                IF r_cur.flg_type = pk_exam_constant.g_type_img
                THEN
                    l_tl_task := pk_prog_notes_constants.g_task_img_exam_results;
                ELSE
                    l_tl_task := pk_prog_notes_constants.g_task_oth_exam_results;
                END IF;
            END IF;
        
            l_new_rec_row.id_tl_task        := l_tl_task;
            l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_exams_res;
            l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
            l_new_rec_row.dt_dg_last_update := l_timestamp;
            --
            l_new_rec_row.id_task_refid  := r_cur.id_exam_result;
            l_new_rec_row.dt_req         := r_cur.dt_exam_result_tstz;
            l_new_rec_row.dt_begin       := NULL;
            l_new_rec_row.dt_end         := NULL;
            l_new_rec_row.flg_status_req := r_cur.flg_status_res;
            --
            l_new_rec_row.flg_type_viewer     := r_cur.flg_type_viewer;
            l_new_rec_row.id_prof_req         := r_cur.id_professional;
            l_new_rec_row.id_patient          := r_cur.id_patient;
            l_new_rec_row.id_episode          := r_cur.id_episode;
            l_new_rec_row.id_visit            := r_cur.id_visit;
            l_new_rec_row.id_institution      := r_cur.id_institution;
            l_new_rec_row.code_description    := NULL;
            l_new_rec_row.universal_desc_clob := r_cur.universal_desc_clob;
            l_new_rec_row.flg_outdated        := r_cur.flg_outdated;
            l_new_rec_row.rank                := NULL;
            l_new_rec_row.id_group_import     := r_cur.id_exam_cat;
            l_new_rec_row.code_desc_group     := r_cur.code_group;
            l_new_rec_row.flg_sos             := pk_alert_constant.g_no;
            l_new_rec_row.dt_execution        := r_cur.start_time;
            l_new_rec_row.flg_ongoing         := r_cur.flg_ongoing;
            l_new_rec_row.flg_normal          := r_cur.flg_normal;
            l_new_rec_row.id_prof_exec        := r_cur.id_prof_exec;
            l_new_rec_row.flg_has_comments    := r_cur.flg_has_comments;
            l_new_rec_row.dt_last_update      := l_timestamp;
            l_new_rec_row.code_description    := r_cur.code_exam;
            l_new_rec_row.flg_technical       := r_cur.flg_technical;
            l_new_rec_row.flg_relevant        := r_cur.flg_relevant;
            l_new_rec_row.id_task_related     := r_cur.id_exam_req_det;
            l_new_rec_row.dt_result           := r_cur.dt_exam_result_tstz;
        
            IF ((r_cur.flg_status_res = pk_exam_constant.g_exam_result_active OR r_cur.flg_status_res IS NULL) OR
               (r_cur.flg_status_res IS NOT NULL AND
               l_tl_task IN
               (pk_prog_notes_constants.g_task_img_exam_results, pk_prog_notes_constants.g_task_oth_exam_results)))
               AND r_cur.id_prof_cancel IS NULL
               AND r_cur.flg_status_epis != pk_alert_constant.g_cancelled
            THEN
            
                -- Search for updated registrie
                SELECT COUNT(0)
                  INTO l_update_reg
                  FROM task_timeline_ea tte
                 WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                   AND tte.table_name = pk_alert_constant.g_tl_table_name_exams_res
                   AND tte.id_tl_task = l_tl_task;
            
                -- IF exists one registrie, information should be UPDATED in TASK_TIMELINE_EA table for this registrie
                IF l_update_reg > 0
                THEN
                    l_process_name  := 'UPDATE';
                    l_event_into_ea := 'U';
                ELSE
                    l_process_name  := 'INSERT';
                    l_event_into_ea := 'I';
                END IF;
            ELSE
                -- Information in states that are not relevant are DELETED
                IF ((r_cur.flg_status_res = pk_exam_constant.g_exam_result_cancel OR r_cur.flg_status_res IS NULL) AND
                   r_cur.id_prof_cancel IS NOT NULL)
                   OR r_cur.flg_status_epis = pk_alert_constant.g_cancelled
                THEN
                    l_process_name  := 'DELETE';
                    l_event_into_ea := 'D';
                ELSE
                    l_process_name             := 'UPDATE';
                    l_event_into_ea            := 'U';
                    l_new_rec_row.flg_outdated := pk_ea_logic_tasktimeline.g_flg_outdated;
                END IF;
            END IF;
        
            /*
            * Opera絥s a executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
            *  -> INSERT;
            *  -> DELETE;
            *  -> UPDATE.
            */
            IF l_event_into_ea = t_data_gov_mnt.g_event_insert
            -- INSERT
            THEN
                g_error := 'Results TS_TASK_TIMELINE_EA.INS';
                pk_alertlog.log_debug(g_error);
                ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
            
            ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
            -- DELETE: 
            THEN
                g_error := 'Results TS_TASK_TIMELINE_EA.DEL_BY';
                pk_alertlog.log_debug(g_error);
                ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                              ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                           rows_out        => o_rowids);
            
            ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
            -- UPDATE
            THEN
                g_error := 'Results TS_TASK_TIMELINE_EA.UPD';
                pk_alertlog.log_debug(g_error);
                ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                        id_tl_task_in    => l_new_rec_row.id_tl_task,
                                        --
                                        id_patient_nin     => FALSE,
                                        id_patient_in      => l_new_rec_row.id_patient,
                                        id_episode_nin     => FALSE,
                                        id_episode_in      => l_new_rec_row.id_episode,
                                        id_visit_nin       => FALSE,
                                        id_visit_in        => l_new_rec_row.id_visit,
                                        id_institution_nin => TRUE,
                                        id_institution_in  => l_new_rec_row.id_institution,
                                        --
                                        dt_req_nin          => TRUE,
                                        dt_req_in           => l_new_rec_row.dt_req,
                                        id_prof_req_nin     => TRUE,
                                        id_prof_req_in      => l_new_rec_row.id_prof_req,
                                        flg_type_viewer_nin => TRUE,
                                        flg_type_viewer_in  => l_new_rec_row.flg_type_viewer,
                                        --
                                        dt_begin_nin => TRUE,
                                        dt_begin_in  => l_new_rec_row.dt_begin,
                                        dt_end_nin   => TRUE,
                                        dt_end_in    => l_new_rec_row.dt_end,
                                        --
                                        flg_status_req_nin => FALSE,
                                        flg_status_req_in  => l_new_rec_row.flg_status_req,
                                        status_str_nin     => FALSE,
                                        status_str_in      => l_new_rec_row.status_str,
                                        status_msg_nin     => FALSE,
                                        status_msg_in      => l_new_rec_row.status_msg,
                                        status_icon_nin    => FALSE,
                                        status_icon_in     => l_new_rec_row.status_icon,
                                        status_flg_nin     => FALSE,
                                        status_flg_in      => l_new_rec_row.status_flg,
                                        --
                                        table_name_nin          => FALSE,
                                        table_name_in           => l_new_rec_row.table_name,
                                        flg_show_method_nin     => FALSE,
                                        flg_show_method_in      => l_new_rec_row.flg_show_method,
                                        code_description_nin    => FALSE,
                                        code_description_in     => l_new_rec_row.code_description,
                                        universal_desc_clob_nin => TRUE,
                                        universal_desc_clob_in  => l_new_rec_row.universal_desc_clob,
                                        rank_nin                => TRUE,
                                        rank_in                 => l_new_rec_row.rank,
                                        id_group_import_nin     => TRUE,
                                        id_group_import_in      => l_new_rec_row.id_group_import,
                                        code_desc_group_nin     => TRUE,
                                        code_desc_group_in      => l_new_rec_row.code_desc_group,
                                        dt_execution_nin        => TRUE,
                                        dt_execution_in         => l_new_rec_row.dt_execution,
                                        flg_sos_nin             => FALSE,
                                        flg_sos_in              => l_new_rec_row.flg_sos,
                                        --
                                        flg_outdated_nin     => TRUE,
                                        flg_outdated_in      => l_new_rec_row.flg_outdated,
                                        flg_ongoing_nin      => TRUE,
                                        flg_ongoing_in       => r_cur.flg_ongoing,
                                        flg_normal_nin       => TRUE,
                                        flg_normal_in        => r_cur.flg_normal,
                                        id_prof_exec_nin     => TRUE,
                                        id_prof_exec_in      => r_cur.id_prof_exec,
                                        flg_has_comments_nin => TRUE,
                                        flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                        dt_last_update_in    => l_new_rec_row.dt_last_update,
                                        flg_technical_in     => l_new_rec_row.flg_technical,
                                        flg_relevant_in      => l_new_rec_row.flg_relevant,
                                        id_task_related_in   => l_new_rec_row.id_task_related,
                                        id_task_related_nin  => TRUE,
                                        dt_result_in         => l_new_rec_row.dt_result,
                                        dt_result_nin        => TRUE,
                                        --
                                        rows_out => o_rowids);
            
                IF o_rowids.count = 0
                THEN
                    g_error := 'Results TS_TASK_TIMELINE_EA.INS';
                    pk_alertlog.log_debug(g_error);
                    ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                END IF;
            
            ELSE
                -- EXCEPTION: Unexpected event type
                RAISE g_excp_invalid_event_type;
            END IF;
        
        END process_exam_task;
    BEGIN
    
        -- Validate arguments
        g_error := 'Exam Results VALIDATE ARGUMENTS. i_event_type : ' || i_event_type;
        pk_alertlog.log_debug(g_error);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => l_name_table_ea,
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert and update event
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
        
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                l_process_name  := 'INSERT';
                l_event_into_ea := 'I';
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
            THEN
                l_process_name  := 'UNDEFINED';
                l_event_into_ea := '';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Results Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                  l_name_table_ea || ')',
                                  g_package_name,
                                  l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                g_error := 'inside loop 1';
                pk_alertlog.log_debug(g_error);
            
                OPEN exam_cur(i_rowids);
                FETCH exam_cur BULK COLLECT
                    INTO my_tbl;
                CLOSE exam_cur;
            
                FOR i IN 1 .. my_tbl.count
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    pk_alertlog.log_debug(g_error);
                
                    process_exam_task(i_verify_task => 'N', r_cur => my_tbl(i));
                    process_exam_task(i_verify_task => 'Y', r_cur => my_tbl(i));
                
                END LOOP;
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_proc_name,
                                              l_error_out);
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_exam_res;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_exams;
/
