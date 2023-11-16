/*-- Last Change Revision: $Rev: 2027013 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_analysis IS

    -- This package provides Easy Access logic procedures to maintain the Analysis's EA table.
    -- @version 2.4.3-Denormalized

    PROCEDURE get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar
    ) IS
    
        l_error_out t_error_out;
    
    BEGIN
    
        IF i_table_name = 'ANALYSIS_REQ'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req IN (SELECT ar.id_analysis_req
                                             FROM analysis_req ar
                                            WHERE ar.rowid IN (SELECT column_value
                                                                 FROM TABLE(i_rowids)));
        
        ELSIF i_table_name = 'ANALYSIS_REQ_DET'
        THEN
            o_rowids := i_rowids;
        
        ELSIF i_table_name = 'ANALYSIS_HARVEST'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN (SELECT ah.id_analysis_req_det
                                                 FROM analysis_harvest ah
                                                WHERE ah.rowid IN (SELECT column_value
                                                                     FROM TABLE(i_rowids)));
        ELSIF i_table_name = 'HARVEST'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN (SELECT ah.id_analysis_req_det
                                                 FROM analysis_harvest ah, harvest h
                                                WHERE ah.id_harvest = h.id_harvest
                                                  AND h.rowid IN (SELECT column_value
                                                                    FROM TABLE(i_rowids)));
        ELSIF i_table_name = 'ANALYSIS_RESULT'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN
                   (SELECT ares.id_analysis_req_det
                      FROM analysis_result ares
                     WHERE ares.rowid IN (SELECT column_value
                                            FROM TABLE(i_rowids)));
        
        ELSIF i_table_name = 'ANALYSIS_RESULT_PAR'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN (SELECT ares.id_analysis_req_det
                                                 FROM analysis_result ares, analysis_result_par arp
                                                WHERE ares.id_analysis_result = arp.id_analysis_result
                                                  AND arp.rowid IN (SELECT column_value
                                                                      FROM TABLE(i_rowids)));
        
        ELSIF i_table_name = 'ANALYSIS_MEDIA_ARCHIVE'
        THEN
            SELECT /*+rule*/
             ard.rowid
              BULK COLLECT
              INTO o_rowids
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det IN (SELECT ama.id_analysis_req_det
                                                 FROM analysis_media_archive ama
                                                WHERE ama.rowid IN (SELECT column_value
                                                                      FROM TABLE(i_rowids)));
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATA_ROWID',
                                              l_error_out);
        
            o_rowids := table_varchar();
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_data_rowid;

    PROCEDURE get_analysis_status_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE,
        o_status_str         OUT VARCHAR2,
        o_status_msg         OUT VARCHAR2,
        o_status_icon        OUT VARCHAR2,
        o_status_flg         OUT VARCHAR2
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
    
        --l_date_begin
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
    
        --l_aux
        IF i_flg_referral IN (pk_lab_tests_constant.g_flg_referral_r,
                              pk_lab_tests_constant.g_flg_referral_s,
                              pk_lab_tests_constant.g_flg_referral_i)
        THEN
            l_aux := 'ANALYSIS_REQ_DET.FLG_REFERRAL';
        ELSE
            IF i_flg_status_det = pk_lab_tests_constant.g_analysis_sos
            THEN
                l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS';
            ELSIF i_flg_status_det IN (pk_lab_tests_constant.g_analysis_wtg_tde,
                                       pk_lab_tests_constant.g_analysis_tosched,
                                       pk_lab_tests_constant.g_analysis_sched,
                                       pk_lab_tests_constant.g_analysis_oncollection,
                                       pk_lab_tests_constant.g_analysis_read,
                                       pk_lab_tests_constant.g_analysis_draft,
                                       pk_lab_tests_constant.g_analysis_review,
                                       pk_lab_tests_constant.g_analysis_nr,
                                       pk_lab_tests_constant.g_analysis_cancel)
            THEN
                l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS';
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_exterior
            THEN
                -- Application without Referral Software exception
                IF l_ref = pk_lab_tests_constant.g_yes
                THEN
                    l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS';
                ELSE
                    l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS.PP';
                END IF;
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_result
            THEN
                IF instr(i_flg_status_result, pk_lab_tests_constant.g_analysis_urgent) != 0
                THEN
                    l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS.URGENT';
                ELSE
                    IF instr(i_flg_status_result, pk_lab_tests_constant.g_analysis_result_partial) != 0
                       OR instr(i_flg_status_result, pk_lab_tests_constant.g_analysis_result_preliminary) != 0
                    THEN
                    
                        IF instr(i_flg_status_result, 'E') != 0
                        THEN
                            l_aux := 'RESULT_STATUS.VALUE.EDIT';
                        ELSE
                            l_aux := 'RESULT_STATUS.VALUE';
                        END IF;
                    ELSE
                        IF instr(i_flg_status_result, 'E') != 0
                        THEN
                            l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS.EDIT';
                        ELSE
                            l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS';
                        END IF;
                    END IF;
                END IF;
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_toexec
            THEN
                IF i_flg_status_harvest IN
                   (pk_lab_tests_constant.g_harvest_collected, pk_lab_tests_constant.g_harvest_transp)
                THEN
                    l_aux := 'HARVEST.FLG_STATUS';
                ELSE
                    l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS';
                END IF;
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_req
            THEN
                l_aux := NULL;
            ELSE
                IF i_flg_time = pk_lab_tests_constant.g_flg_time_n
                THEN
                    l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS';
                ELSE
                    IF i_dt_begin IS NULL
                    THEN
                        l_aux := 'ANALYSIS_REQ_DET.FLG_STATUS';
                    ELSE
                        l_aux := NULL;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        --l_text
        IF i_flg_status_det IN (pk_lab_tests_constant.g_analysis_result, pk_lab_tests_constant.g_analysis_read)
        THEN
            IF i_result IS NOT NULL
            THEN
                l_text := i_result;
            ELSE
                l_text := l_aux;
            END IF;
        ELSE
            l_text := l_aux;
        END IF;
    
        --l_display_type
        IF i_flg_referral IN (pk_lab_tests_constant.g_flg_referral_r,
                              pk_lab_tests_constant.g_flg_referral_s,
                              pk_lab_tests_constant.g_flg_referral_i)
        THEN
            l_display_type := pk_alert_constant.g_display_type_icon;
        ELSE
            IF i_flg_status_det = pk_lab_tests_constant.g_analysis_sos
            THEN
                l_display_type := pk_alert_constant.g_display_type_icon;
            ELSIF i_flg_status_det IN (pk_lab_tests_constant.g_analysis_wtg_tde,
                                       pk_lab_tests_constant.g_analysis_tosched,
                                       pk_lab_tests_constant.g_analysis_sched,
                                       pk_lab_tests_constant.g_analysis_oncollection,
                                       pk_lab_tests_constant.g_analysis_toexec,
                                       pk_lab_tests_constant.g_analysis_review,
                                       pk_lab_tests_constant.g_analysis_draft,
                                       pk_lab_tests_constant.g_analysis_nr,
                                       pk_lab_tests_constant.g_analysis_cancel)
            THEN
                l_display_type := pk_alert_constant.g_display_type_icon;
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_exterior
            THEN
                -- Application without Referral Software exception
                IF l_ref = pk_lab_tests_constant.g_yes
                THEN
                    l_display_type := pk_alert_constant.g_display_type_date_icon;
                ELSE
                    l_display_type := pk_alert_constant.g_display_type_icon;
                END IF;
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_req
            THEN
                l_display_type := pk_alert_constant.g_display_type_date;
            ELSIF i_flg_status_det IN (pk_lab_tests_constant.g_analysis_result, pk_lab_tests_constant.g_analysis_read)
            THEN
                IF i_result IS NOT NULL
                THEN
                    l_display_type := pk_alert_constant.g_display_type_text_icon;
                ELSE
                    l_display_type := pk_alert_constant.g_display_type_icon;
                END IF;
            ELSE
                IF i_flg_time = pk_lab_tests_constant.g_flg_time_n
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
    
        --l_back_color
        IF i_flg_referral IN (pk_lab_tests_constant.g_flg_referral_r,
                              pk_lab_tests_constant.g_flg_referral_s,
                              pk_lab_tests_constant.g_flg_referral_i)
        THEN
            l_back_color := pk_alert_constant.g_color_null;
        ELSE
            IF i_flg_status_det IN (pk_lab_tests_constant.g_analysis_sos,
                                    pk_lab_tests_constant.g_analysis_tosched,
                                    pk_lab_tests_constant.g_analysis_sched,
                                    pk_lab_tests_constant.g_analysis_req,
                                    pk_lab_tests_constant.g_analysis_oncollection,
                                    pk_lab_tests_constant.g_analysis_toexec,
                                    pk_lab_tests_constant.g_analysis_draft,
                                    pk_lab_tests_constant.g_analysis_result,
                                    pk_lab_tests_constant.g_analysis_read,
                                    pk_lab_tests_constant.g_analysis_review,
                                    pk_lab_tests_constant.g_analysis_nr,
                                    pk_lab_tests_constant.g_analysis_cancel,
                                    pk_lab_tests_constant.g_analysis_sos)
            THEN
                l_back_color := pk_alert_constant.g_color_null;
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_wtg_tde
            THEN
                l_back_color := pk_alert_constant.g_color_icon_dark_grey;
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_exterior
            THEN
                -- Application without Referral Software exception
                IF l_ref = pk_lab_tests_constant.g_yes
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
                        IF i_flg_time IN (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d)
                        THEN
                            l_back_color := NULL;
                        ELSE
                            l_back_color := pk_alert_constant.g_color_green;
                        END IF;
                    ELSE
                        l_back_color := NULL;
                    END IF;
                ELSE
                    IF i_dt_begin IS NULL
                    THEN
                        IF i_flg_time IN (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d)
                        THEN
                            l_back_color := NULL;
                        ELSE
                            l_back_color := pk_alert_constant.g_color_red;
                        END IF;
                    ELSE
                        l_back_color := NULL;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        --l_status_flg
        IF i_flg_referral IN (pk_lab_tests_constant.g_flg_referral_r,
                              pk_lab_tests_constant.g_flg_referral_s,
                              pk_lab_tests_constant.g_flg_referral_i)
        THEN
            l_status_flg := i_flg_referral;
        ELSE
            IF i_flg_status_det IN (pk_lab_tests_constant.g_analysis_sos,
                                    pk_lab_tests_constant.g_analysis_wtg_tde,
                                    pk_lab_tests_constant.g_analysis_exterior,
                                    pk_lab_tests_constant.g_analysis_tosched,
                                    pk_lab_tests_constant.g_analysis_sched,
                                    pk_lab_tests_constant.g_analysis_oncollection,
                                    pk_lab_tests_constant.g_analysis_read,
                                    pk_lab_tests_constant.g_analysis_draft,
                                    pk_lab_tests_constant.g_analysis_review,
                                    pk_lab_tests_constant.g_analysis_nr,
                                    pk_lab_tests_constant.g_analysis_cancel)
            THEN
                l_status_flg := i_flg_status_det;
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_toexec
            THEN
                IF i_flg_status_harvest IN
                   (pk_lab_tests_constant.g_harvest_collected, pk_lab_tests_constant.g_harvest_transp)
                THEN
                    l_status_flg := i_flg_status_harvest;
                ELSE
                    l_status_flg := i_flg_status_det;
                END IF;
            ELSIF i_flg_status_det = pk_lab_tests_constant.g_analysis_result
            THEN
                IF instr(i_flg_status_result, pk_lab_tests_constant.g_analysis_result_partial) != 0
                THEN
                    l_status_flg := pk_lab_tests_constant.g_analysis_result_partial;
                ELSIF instr(i_flg_status_result, pk_lab_tests_constant.g_analysis_result_preliminary) != 0
                THEN
                    l_status_flg := pk_lab_tests_constant.g_analysis_result_preliminary;
                ELSE
                    l_status_flg := pk_lab_tests_constant.g_analysis_result;
                END IF;
            ELSE
                IF i_episode IS NULL
                THEN
                    IF i_flg_time = pk_lab_tests_constant.g_flg_time_n
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
        IF i_flg_status_det = pk_lab_tests_constant.g_analysis_result
           AND instr(i_flg_status_result, pk_lab_tests_constant.g_analysis_urgent) != 0
        THEN
            l_default_color := pk_lab_tests_constant.g_yes;
        ELSE
            l_default_color := pk_lab_tests_constant.g_no;
        END IF;
    
        --l_icon_color
        IF i_flg_status_det = pk_exam_constant.g_exam_sos
        THEN
            l_icon_color := pk_alert_constant.g_color_icon_dark_grey;
        END IF;
    
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_status_flg,
                                     i_value_text    => l_text,
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
    END get_analysis_status_det;

    FUNCTION get_analysis_status_str_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_det(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_flg_time           => i_flg_time,
                                                     i_flg_status_det     => i_flg_status_det,
                                                     i_flg_status_harvest => i_flg_status_harvest,
                                                     i_flg_referral       => i_flg_referral,
                                                     i_flg_status_result  => i_flg_status_result,
                                                     i_result             => i_result,
                                                     i_dt_req             => i_dt_req,
                                                     i_dt_pend_req        => i_dt_pend_req,
                                                     i_dt_begin           => i_dt_begin,
                                                     o_status_str         => l_status_str,
                                                     o_status_msg         => l_status_msg,
                                                     o_status_icon        => l_status_icon,
                                                     o_status_flg         => l_status_flg);
    
        RETURN l_status_str;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_analysis_status_str_det;

    FUNCTION get_analysis_status_msg_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_det(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_flg_time           => i_flg_time,
                                                     i_flg_status_det     => i_flg_status_det,
                                                     i_flg_status_harvest => i_flg_status_harvest,
                                                     i_flg_referral       => i_flg_referral,
                                                     i_flg_status_result  => i_flg_status_result,
                                                     i_result             => i_result,
                                                     i_dt_req             => i_dt_req,
                                                     i_dt_pend_req        => i_dt_pend_req,
                                                     i_dt_begin           => i_dt_begin,
                                                     o_status_str         => l_status_str,
                                                     o_status_msg         => l_status_msg,
                                                     o_status_icon        => l_status_icon,
                                                     o_status_flg         => l_status_flg);
    
        RETURN l_status_msg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_analysis_status_msg_det;

    FUNCTION get_analysis_status_icon_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_det(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_flg_time           => i_flg_time,
                                                     i_flg_status_det     => i_flg_status_det,
                                                     i_flg_status_harvest => i_flg_status_harvest,
                                                     i_flg_referral       => i_flg_referral,
                                                     i_flg_status_result  => i_flg_status_result,
                                                     i_result             => i_result,
                                                     i_dt_req             => i_dt_req,
                                                     i_dt_pend_req        => i_dt_pend_req,
                                                     i_dt_begin           => i_dt_begin,
                                                     o_status_str         => l_status_str,
                                                     o_status_msg         => l_status_msg,
                                                     o_status_icon        => l_status_icon,
                                                     o_status_flg         => l_status_flg);
    
        RETURN l_status_icon;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_analysis_status_icon_det;

    FUNCTION get_analysis_status_flg_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_det(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_flg_time           => i_flg_time,
                                                     i_flg_status_det     => i_flg_status_det,
                                                     i_flg_status_harvest => i_flg_status_harvest,
                                                     i_flg_referral       => i_flg_referral,
                                                     i_flg_status_result  => i_flg_status_result,
                                                     i_result             => i_result,
                                                     i_dt_req             => i_dt_req,
                                                     i_dt_pend_req        => i_dt_pend_req,
                                                     i_dt_begin           => i_dt_begin,
                                                     o_status_str         => l_status_str,
                                                     o_status_msg         => l_status_msg,
                                                     o_status_icon        => l_status_icon,
                                                     o_status_flg         => l_status_flg);
    
        RETURN l_status_flg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_analysis_status_flg_det;

    PROCEDURE get_analysis_status_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE,
        o_status_str     OUT VARCHAR2,
        o_status_msg     OUT VARCHAR2,
        o_status_icon    OUT VARCHAR2,
        o_status_flg     OUT VARCHAR2
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
    
        --l_date_begin
        l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                           nvl(i_dt_begin, i_dt_req),
                                                           pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
    
        --l_aux
        IF i_flg_status_req = pk_lab_tests_constant.g_analysis_sos
        THEN
            l_aux := 'ANALYSIS_REQ.FLG_STATUS';
        ELSIF i_flg_status_req IN (pk_lab_tests_constant.g_analysis_tosched,
                                   pk_lab_tests_constant.g_analysis_sched,
                                   pk_lab_tests_constant.g_analysis_ongoing,
                                   pk_lab_tests_constant.g_analysis_partial,
                                   pk_lab_tests_constant.g_analysis_result,
                                   pk_lab_tests_constant.g_analysis_read_partial,
                                   pk_lab_tests_constant.g_analysis_read,
                                   pk_lab_tests_constant.g_analysis_nr,
                                   pk_lab_tests_constant.g_analysis_cancel)
        THEN
            l_aux := 'ANALYSIS_REQ.FLG_STATUS';
        ELSIF i_flg_status_req = pk_lab_tests_constant.g_analysis_result || pk_lab_tests_constant.g_analysis_urgent
        THEN
            l_aux := 'ANALYSIS_REQ.FLG_STATUS.URGENT';
        ELSIF i_flg_status_req = pk_lab_tests_constant.g_analysis_exterior
        THEN
            -- Application without Referral Software exception
            IF l_ref = pk_lab_tests_constant.g_yes
            THEN
                l_aux := 'ANALYSIS_REQ.FLG_STATUS';
            ELSE
                l_aux := 'ANALYSIS_REQ.FLG_STATUS.PP';
            END IF;
        ELSIF i_flg_status_req = pk_lab_tests_constant.g_analysis_req
        THEN
            l_aux := NULL;
        ELSE
            IF i_flg_time = pk_lab_tests_constant.g_flg_time_n
            THEN
                l_aux := 'ANALYSIS_REQ.FLG_STATUS';
            ELSE
                IF i_dt_begin IS NULL
                THEN
                    l_aux := 'ANALYSIS_REQ.FLG_STATUS';
                ELSE
                    l_aux := NULL;
                END IF;
            END IF;
        END IF;
    
        --l_text
        l_text := l_aux;
    
        --l_display_type
        IF i_flg_status_req = pk_lab_tests_constant.g_analysis_sos
        THEN
            l_display_type := pk_alert_constant.g_display_type_icon;
        ELSIF i_flg_status_req IN (pk_lab_tests_constant.g_analysis_tosched,
                                   pk_lab_tests_constant.g_analysis_sched,
                                   pk_lab_tests_constant.g_analysis_ongoing,
                                   pk_lab_tests_constant.g_analysis_partial,
                                   pk_lab_tests_constant.g_analysis_result,
                                   pk_lab_tests_constant.g_analysis_read_partial,
                                   pk_lab_tests_constant.g_analysis_read,
                                   pk_lab_tests_constant.g_analysis_nr,
                                   pk_lab_tests_constant.g_analysis_cancel)
        THEN
            l_display_type := pk_alert_constant.g_display_type_icon;
        ELSIF i_flg_status_req = pk_lab_tests_constant.g_analysis_exterior
        THEN
            -- Application without Referral Software exception
            IF l_ref = pk_lab_tests_constant.g_yes
            THEN
                l_display_type := pk_alert_constant.g_display_type_date_icon;
            ELSE
                l_display_type := pk_alert_constant.g_display_type_icon;
            END IF;
        ELSIF i_flg_status_req = pk_lab_tests_constant.g_analysis_req
        THEN
            l_display_type := pk_alert_constant.g_display_type_date;
        ELSE
            IF i_flg_time = pk_lab_tests_constant.g_flg_time_n
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
    
        --l_back_color
        IF i_flg_status_req IN (pk_lab_tests_constant.g_analysis_tosched,
                                pk_lab_tests_constant.g_analysis_sched,
                                pk_lab_tests_constant.g_analysis_ongoing,
                                pk_lab_tests_constant.g_analysis_partial,
                                pk_lab_tests_constant.g_analysis_result,
                                pk_lab_tests_constant.g_analysis_read_partial,
                                pk_lab_tests_constant.g_analysis_read,
                                pk_lab_tests_constant.g_analysis_nr,
                                pk_lab_tests_constant.g_analysis_cancel,
                                pk_lab_tests_constant.g_analysis_sos)
        THEN
            l_back_color := pk_alert_constant.g_color_null;
        ELSIF i_flg_status_req = pk_lab_tests_constant.g_analysis_exterior
        THEN
            -- Application without Referral Software exception
            IF l_ref = pk_lab_tests_constant.g_yes
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
                    IF i_flg_time IN (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d)
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
                    IF i_flg_time IN (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d)
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
    
        --l_status_flg
        IF i_flg_status_req IN (pk_lab_tests_constant.g_analysis_exterior,
                                pk_lab_tests_constant.g_analysis_tosched,
                                pk_lab_tests_constant.g_analysis_sched,
                                pk_lab_tests_constant.g_analysis_ongoing,
                                pk_lab_tests_constant.g_analysis_partial,
                                pk_lab_tests_constant.g_analysis_result,
                                pk_lab_tests_constant.g_analysis_read_partial,
                                pk_lab_tests_constant.g_analysis_read,
                                pk_lab_tests_constant.g_analysis_nr,
                                pk_lab_tests_constant.g_analysis_cancel,
                                pk_lab_tests_constant.g_analysis_sos)
        THEN
            l_status_flg := i_flg_status_req;
        ELSE
            IF i_episode IS NULL
            THEN
                IF i_flg_time = pk_lab_tests_constant.g_flg_time_n
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
    
        -- l_default_color
        IF i_flg_status_req = pk_lab_tests_constant.g_analysis_result || pk_lab_tests_constant.g_analysis_urgent
        THEN
            l_default_color := pk_lab_tests_constant.g_yes;
        ELSE
            l_default_color := pk_lab_tests_constant.g_no;
        END IF;
    
        --l_icon_color
        IF i_flg_status_req = pk_exam_constant.g_exam_sos
        THEN
            l_icon_color := pk_alert_constant.g_color_icon_dark_grey;
        END IF;
    
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_status_flg,
                                     i_value_text    => l_text,
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
    END get_analysis_status_req;

    FUNCTION get_analysis_status_str_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_req(i_lang           => i_lang,
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
    END get_analysis_status_str_req;

    FUNCTION get_analysis_status_msg_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_req(i_lang           => i_lang,
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
    END get_analysis_status_msg_req;

    FUNCTION get_analysis_status_icon_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_req(i_lang           => i_lang,
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
    END get_analysis_status_icon_req;

    FUNCTION get_analysis_status_flg_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_req(i_lang           => i_lang,
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
    END get_analysis_status_flg_req;

    PROCEDURE get_harvest_status
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2,
        o_status_str       OUT VARCHAR2,
        o_status_msg       OUT VARCHAR2,
        o_status_icon      OUT VARCHAR2,
        o_status_flg       OUT VARCHAR2
    ) IS
    
        l_display_type VARCHAR2(200) := '';
        l_back_color   VARCHAR2(200) := '';
        l_status_flg   VARCHAR2(200) := '';
        l_icon_color   VARCHAR2(200) := '';
    
        -- text || icon
        l_aux VARCHAR2(200);
        -- date
        l_date_begin VARCHAR2(200);
        -- current timestamp
        l_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        --l_date_begin
        IF i_dt_pend_req IS NULL
        THEN
            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                               nvl(i_dt_target, i_dt_req),
                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        ELSE
            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                               i_dt_pend_req,
                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        END IF;
    
        --l_aux
        l_aux := 'HARVEST.FLG_STATUS';
    
        --l_display_type
        IF i_flg_status = pk_lab_tests_constant.g_harvest_pending
        THEN
            l_display_type := pk_alert_constant.g_display_type_date_icon;
        ELSIF i_flg_status = pk_lab_tests_constant.g_harvest_collected
              AND i_flg_type = 'T'
        THEN
            l_display_type := pk_alert_constant.g_display_type_date_icon;
        ELSE
            l_display_type := pk_alert_constant.g_display_type_icon;
        END IF;
    
        --l_back_color
        IF i_flg_status = pk_lab_tests_constant.g_harvest_pending
        THEN
            IF i_dt_target IS NULL
            THEN
                l_back_color := pk_alert_constant.g_color_green;
            ELSE
                IF pk_date_utils.compare_dates_tsz(i_prof, nvl(i_dt_pend_req, i_dt_target), l_sysdate_tstz) = 'G'
                THEN
                    l_back_color := pk_alert_constant.g_color_green;
                ELSIF pk_date_utils.compare_dates_tsz(i_prof, nvl(i_dt_pend_req, i_dt_target), l_sysdate_tstz) = 'L'
                THEN
                    l_back_color := pk_alert_constant.g_color_red;
                ELSE
                    l_back_color := pk_alert_constant.g_color_red;
                END IF;
            END IF;
        ELSIF i_flg_status = pk_lab_tests_constant.g_harvest_collected
              AND i_flg_type = 'T'
        THEN
            IF i_dt_target IS NULL
            THEN
                l_back_color := pk_alert_constant.g_color_green;
            ELSE
                IF i_flg_time_harvest IN (pk_lab_tests_constant.g_flg_time_e,
                                          pk_lab_tests_constant.g_flg_time_b,
                                          pk_lab_tests_constant.g_flg_time_d)
                THEN
                    IF pk_date_utils.compare_dates_tsz(i_prof, i_dt_target, l_sysdate_tstz) = 'G'
                    THEN
                        l_back_color := pk_alert_constant.g_color_green;
                    ELSIF pk_date_utils.compare_dates_tsz(i_prof, i_dt_target, l_sysdate_tstz) = 'L'
                    THEN
                        l_back_color := pk_alert_constant.g_color_red;
                    ELSE
                        l_back_color := pk_alert_constant.g_color_red;
                    END IF;
                ELSE
                    l_back_color := pk_alert_constant.g_color_green;
                END IF;
            END IF;
        ELSE
            l_back_color := pk_alert_constant.g_color_null;
        END IF;
    
        --l_status_flg
        l_status_flg := i_flg_status;
    
        pk_utils.build_status_string(i_display_type => l_display_type,
                                     i_flg_state    => l_status_flg,
                                     i_value_text   => l_aux,
                                     i_value_date   => l_date_begin,
                                     i_value_icon   => l_aux,
                                     i_back_color   => l_back_color,
                                     i_icon_color   => l_icon_color,
                                     o_status_str   => o_status_str,
                                     o_status_msg   => o_status_msg,
                                     o_status_icon  => o_status_icon,
                                     o_status_flg   => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_harvest_status;

    FUNCTION get_harvest_status_str
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(1);
    
    BEGIN
    
        pk_ea_logic_analysis.get_harvest_status(i_prof             => i_prof,
                                                i_flg_time_harvest => i_flg_time_harvest,
                                                i_flg_status       => i_flg_status,
                                                i_dt_req           => i_dt_req,
                                                i_dt_pend_req      => i_dt_pend_req,
                                                i_dt_target        => i_dt_target,
                                                i_flg_type         => i_flg_type,
                                                o_status_str       => l_status_str,
                                                o_status_msg       => l_status_msg,
                                                o_status_icon      => l_status_icon,
                                                o_status_flg       => l_status_flg);
    
        RETURN l_status_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_harvest_status_str;

    FUNCTION get_harvest_status_msg
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(1);
    
    BEGIN
    
        pk_ea_logic_analysis.get_harvest_status(i_prof             => i_prof,
                                                i_flg_time_harvest => i_flg_time_harvest,
                                                i_flg_status       => i_flg_status,
                                                i_dt_req           => i_dt_req,
                                                i_dt_pend_req      => i_dt_pend_req,
                                                i_dt_target        => i_dt_target,
                                                i_flg_type         => i_flg_type,
                                                o_status_str       => l_status_str,
                                                o_status_msg       => l_status_msg,
                                                o_status_icon      => l_status_icon,
                                                o_status_flg       => l_status_flg);
    
        RETURN l_status_msg;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_harvest_status_msg;

    FUNCTION get_harvest_status_icon
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(1);
    
    BEGIN
    
        pk_ea_logic_analysis.get_harvest_status(i_prof             => i_prof,
                                                i_flg_time_harvest => i_flg_time_harvest,
                                                i_flg_status       => i_flg_status,
                                                i_dt_req           => i_dt_req,
                                                i_dt_pend_req      => i_dt_pend_req,
                                                i_dt_target        => i_dt_target,
                                                i_flg_type         => i_flg_type,
                                                o_status_str       => l_status_str,
                                                o_status_msg       => l_status_msg,
                                                o_status_icon      => l_status_icon,
                                                o_status_flg       => l_status_flg);
    
        RETURN l_status_icon;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_harvest_status_icon;

    FUNCTION get_harvest_status_flg
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(1);
    
    BEGIN
    
        pk_ea_logic_analysis.get_harvest_status(i_prof             => i_prof,
                                                i_flg_time_harvest => i_flg_time_harvest,
                                                i_flg_status       => i_flg_status,
                                                i_dt_req           => i_dt_req,
                                                i_dt_pend_req      => i_dt_pend_req,
                                                i_dt_target        => i_dt_target,
                                                i_flg_type         => i_flg_type,
                                                o_status_str       => l_status_str,
                                                o_status_msg       => l_status_msg,
                                                o_status_icon      => l_status_icon,
                                                o_status_flg       => l_status_flg);
    
        RETURN l_status_flg;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_harvest_status_flg;

    FUNCTION get_analysis_status_req_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN table_ea_struct IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
        l_table_ea_struct table_ea_struct := table_ea_struct(NULL);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_req(i_lang           => i_lang,
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
    END get_analysis_status_req_all;

    FUNCTION get_analysis_status_det_all
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN table_ea_struct IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
        l_table_ea_struct table_ea_struct := table_ea_struct(NULL);
    
    BEGIN
    
        pk_ea_logic_analysis.get_analysis_status_det(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_episode,
                                                     i_flg_time           => i_flg_time,
                                                     i_flg_status_det     => i_flg_status_det,
                                                     i_flg_referral       => i_flg_referral,
                                                     i_flg_status_harvest => i_flg_status_harvest,
                                                     i_flg_status_result  => i_flg_status_result,
                                                     i_result             => i_result,
                                                     i_dt_req             => i_dt_req,
                                                     i_dt_pend_req        => i_dt_pend_req,
                                                     i_dt_begin           => i_dt_begin,
                                                     o_status_str         => l_status_str,
                                                     o_status_msg         => l_status_msg,
                                                     o_status_icon        => l_status_icon,
                                                     o_status_flg         => l_status_flg);
    
        SELECT t_ea_struct(l_status_str, l_status_msg, l_status_icon, l_status_flg)
          BULK COLLECT
          INTO l_table_ea_struct
          FROM (SELECT l_status_str, l_status_msg, l_status_icon, l_status_flg
                  FROM dual);
    
        RETURN l_table_ea_struct;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_analysis_status_det_all;

    PROCEDURE set_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row lab_tests_ea%ROWTYPE;
        l_rowids      table_varchar;
        o_rowids      table_varchar;
    
        l_show_result sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('LAB_TESTS_PARTIAL_RESULT_SHOW', i_prof);
        l_design_mode sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULT_TABLE_DESIGN', i_prof);
    
        l_result     VARCHAR2(200);
        l_flg_result VARCHAR2(3 CHAR);
    
    BEGIN
    
        g_error := 'GET ANALYSIS ROWIDS';
        get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'LAB_TESTS_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert and update event
        IF i_event_type IN
           (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_delete)
        THEN
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
                FOR r_cur IN (SELECT id_analysis_req,
                                     id_analysis_req_det,
                                     id_ard_parent,
                                     id_analysis_result,
                                     id_analysis,
                                     dt_req,
                                     dt_begin,
                                     dt_pend_req,
                                     dt_harvest,
                                     dt_analysis_result,
                                     id_sample_type,
                                     id_exam_cat,
                                     flg_notes,
                                     flg_doc,
                                     flg_time,
                                     flg_status_req,
                                     flg_status_det,
                                     flg_status_harvest,
                                     flg_status_result,
                                     flg_priority,
                                     flg_col_inst,
                                     flg_referral,
                                     id_prof_writes,
                                     id_prof_order,
                                     dt_order,
                                     id_order_type,
                                     id_analysis_codification,
                                     flg_abnormality,
                                     flg_relevant,
                                     id_room_req,
                                     id_institution,
                                     id_movement,
                                     id_task_dependency,
                                     id_exec_institution,
                                     flg_req_origin_module,
                                     flg_orig_analysis,
                                     notes,
                                     notes_scheduler,
                                     notes_technician,
                                     notes_patient,
                                     notes_cancel,
                                     id_patient,
                                     id_visit,
                                     id_episode,
                                     id_episode_origin,
                                     id_episode_destination,
                                     id_prev_episode
                                FROM (SELECT t.*,
                                             dense_rank() over(PARTITION BY t.id_analysis_result ORDER BY t.dt_analysis_result DESC) rn_ar,
                                             dense_rank() over(PARTITION BY t.id_analysis_req_det ORDER BY t.id_harvest) rn_h,
                                             dense_rank() over(PARTITION BY t.id_harvest ORDER BY t.dt_harvest DESC) rn_ah
                                        FROM (SELECT /*+ opt_estimate(table ard rows=1) opt_param('_optimizer_use_feedback' 'false')*/
                                               ar.id_analysis_req id_analysis_req,
                                               ard.id_analysis_req_det id_analysis_req_det,
                                               ard.id_ard_parent id_ard_parent,
                                               ares.id_analysis_result id_analysis_result,
                                               ard.id_analysis id_analysis,
                                               ah.id_harvest,
                                               ar.dt_req_tstz dt_req,
                                               ard.dt_target_tstz dt_begin,
                                               ard.dt_pend_req_tstz dt_pend_req,
                                               h.dt_harvest_tstz dt_harvest,
                                               ares.dt_analysis_result_tstz dt_analysis_result,
                                               ard.id_sample_type id_sample_type,
                                               ard.id_exam_cat id_exam_cat,
                                               decode(ard.notes || ard.notes_tech ||
                                                      dbms_lob.substr(ard.notes_patient, 3800),
                                                      NULL,
                                                      pk_lab_tests_constant.g_no,
                                                      pk_lab_tests_constant.g_yes) flg_notes,
                                               decode((SELECT 1
                                                        FROM analysis_media_archive ama
                                                       WHERE ama.id_analysis_req_det = ard.id_analysis_req_det
                                                         AND ama.flg_type =
                                                             pk_lab_tests_constant.g_media_archive_analysis_doc
                                                         AND ama.flg_status = pk_lab_tests_constant.g_active
                                                         AND rownum = 1),
                                                      1,
                                                      pk_lab_tests_constant.g_yes,
                                                      pk_lab_tests_constant.g_no) flg_doc,
                                               ard.flg_time_harvest flg_time,
                                               ar.flg_status flg_status_req,
                                               ard.flg_status flg_status_det,
                                               h.flg_status flg_status_harvest,
                                               rs.value flg_status_result,
                                               ard.flg_urgency flg_priority,
                                               ard.flg_col_inst flg_col_inst,
                                               ard.flg_referral flg_referral,
                                               ar.id_prof_writes id_prof_writes,
                                               cs.id_prof_ordered_by id_prof_order,
                                               cs.dt_ordered_by dt_order,
                                               cs.id_order_type id_order_type,
                                               ard.id_analysis_codification,
                                               arp.id_abnormality,
                                               decode(arp.id_abnormality,
                                                      NULL,
                                                      pk_lab_tests_constant.g_no,
                                                      pk_lab_tests_constant.g_yes) flg_abnormality,
                                               arp.flg_relevant,
                                               ard.id_room_req id_room_req,
                                               ar.id_institution id_institution,
                                               ard.id_movement id_movement,
                                               ard.id_task_dependency,
                                               ard.id_exec_institution,
                                               ard.flg_req_origin_module,
                                               ares.flg_orig_analysis flg_orig_analysis,
                                               ard.notes,
                                               ard.notes_scheduler,
                                               ard.notes_tech notes_technician,
                                               ard.notes_patient,
                                               ard.notes_cancel,
                                               ar.id_patient id_patient,
                                               e.id_visit id_visit,
                                               ar.id_episode id_episode,
                                               ar.id_episode_origin id_episode_origin,
                                               ar.id_episode_destination id_episode_destination,
                                               ar.id_prev_episode id_prev_episode
                                                FROM analysis_req_det ard
                                                JOIN analysis a
                                                  ON a.id_analysis = ard.id_analysis
                                                JOIN analysis_req ar
                                                  ON ar.id_analysis_req = ard.id_analysis_req
                                                LEFT OUTER JOIN (SELECT ah.id_analysis_req_det, ah.id_harvest
                                                                  FROM analysis_harvest ah, harvest h
                                                                 WHERE ah.flg_status = pk_lab_tests_constant.g_active
                                                                   AND ah.id_harvest = h.id_harvest) ah
                                                  ON ah.id_analysis_req_det = ard.id_analysis_req_det
                                                LEFT OUTER JOIN (SELECT h.id_harvest, h.flg_status, h.dt_harvest_tstz
                                                                  FROM harvest h) h
                                                  ON h.id_harvest = ah.id_harvest
                                                LEFT OUTER JOIN analysis_result ares
                                                  ON ares.id_analysis_req_det = ard.id_analysis_req_det
                                                LEFT OUTER JOIN (SELECT id_analysis_result,
                                                                       MAX(id_abnormality) id_abnormality,
                                                                       MAX(flg_relevant) flg_relevant
                                                                  FROM (SELECT /*+ opt_estimate(table ard rows=1) */
                                                                         arp.id_analysis_result,
                                                                         arp.id_abnormality,
                                                                         NULL flg_relevant
                                                                          FROM analysis_result_par arp
                                                                          JOIN analysis_result ar
                                                                            ON arp.id_analysis_result =
                                                                               ar.id_analysis_result
                                                                          JOIN analysis_req_det ard
                                                                            ON ar.id_analysis_req_det =
                                                                               ard.id_analysis_req_det
                                                                         WHERE ard.rowid IN
                                                                               (SELECT *
                                                                                  FROM TABLE(l_rowids))
                                                                           AND ard.flg_status !=
                                                                               pk_lab_tests_constant.g_analysis_predefined
                                                                           AND arp.id_abnormality IS NOT NULL
                                                                           AND arp.id_abnormality != 7
                                                                        UNION ALL
                                                                        SELECT /*+ opt_estimate(table ard rows=1) */
                                                                         arp.id_analysis_result,
                                                                         NULL id_abnormality,
                                                                         arp.flg_relevant
                                                                          FROM analysis_result_par arp
                                                                          JOIN analysis_result ar
                                                                            ON arp.id_analysis_result =
                                                                               ar.id_analysis_result
                                                                          JOIN analysis_req_det ard
                                                                            ON ar.id_analysis_req_det =
                                                                               ard.id_analysis_req_det
                                                                         WHERE ard.rowid IN
                                                                               (SELECT *
                                                                                  FROM TABLE(l_rowids))
                                                                           AND ard.flg_status !=
                                                                               pk_lab_tests_constant.g_analysis_predefined
                                                                           AND arp.flg_relevant IS NOT NULL)
                                                                 GROUP BY id_analysis_result) arp
                                                  ON arp.id_analysis_result = ares.id_analysis_result
                                                LEFT OUTER JOIN co_sign_hist cs
                                                  ON cs.id_co_sign_hist = ard.id_co_sign_order
                                                LEFT OUTER JOIN episode e
                                                  ON e.id_episode = ar.id_episode
                                                LEFT OUTER JOIN result_status rs
                                                  ON rs.id_result_status = ares.id_result_status
                                               WHERE ard.rowid IN (SELECT *
                                                                     FROM TABLE(l_rowids))
                                                 AND ard.flg_status != pk_lab_tests_constant.g_analysis_predefined) t)
                               WHERE rn_ar = 1
                                 AND rn_h = 1
                                 AND rn_ah = 1
                               ORDER BY id_analysis_req_det)
                LOOP
                
                    IF r_cur.flg_status_det IN
                       (pk_lab_tests_constant.g_analysis_result, pk_lab_tests_constant.g_analysis_read)
                    THEN
                        IF l_show_result = pk_lab_tests_constant.g_yes
                        THEN
                            BEGIN
                                SELECT CASE
                                            WHEN b.count_result = a.count_req THEN
                                             ''
                                            ELSE
                                             b.count_result || '/' || a.count_req
                                        END RESULT
                                  INTO l_result
                                  FROM (SELECT COUNT(*) count_req
                                          FROM analysis_req_par arp
                                         WHERE arp.id_analysis_req_det = r_cur.id_analysis_req_det) a,
                                       (SELECT COUNT(*) count_result
                                          FROM (SELECT aresp.*,
                                                       row_number() over(PARTITION BY aresp.id_analysis_req_par ORDER BY aresp.dt_analysis_result_par_tstz) rn
                                                  FROM analysis_result_par aresp, analysis_req_par arp
                                                 WHERE arp.id_analysis_req_det = r_cur.id_analysis_req_det
                                                   AND aresp.id_analysis_req_par = arp.id_analysis_req_par)
                                         WHERE rn = 1) b
                                 WHERE b.count_result > 0
                                   AND a.count_req > b.count_result;
                            EXCEPTION
                                WHEN no_data_found THEN
                                    l_result := NULL;
                            END;
                        END IF;
                    
                        IF l_design_mode != 'D'
                        THEN
                            BEGIN
                                SELECT decode(arp.dt_analysis_result_par_upd,
                                              arp.dt_analysis_result_par_tstz,
                                              r_cur.flg_status_result,
                                              r_cur.flg_status_result || 'E')
                                  INTO l_flg_result
                                  FROM (SELECT arp.*,
                                               row_number() over(PARTITION BY arp.id_analysis_result ORDER BY nvl(arp.dt_analysis_result_par_upd, arp.dt_analysis_result_par_tstz) DESC) rn
                                          FROM analysis_result_par arp, analysis_result ar
                                         WHERE ar.id_analysis_req_det = r_cur.id_analysis_req_det
                                           AND ar.id_analysis_result = arp.id_analysis_result) arp
                                 WHERE rn = 1;
                            EXCEPTION
                                WHEN no_data_found THEN
                                    l_flg_result := r_cur.flg_status_result;
                                WHEN too_many_rows THEN
                                    l_flg_result := r_cur.flg_status_result;
                            END;
                        ELSE
                            IF r_cur.flg_priority != pk_lab_tests_constant.g_analysis_normal
                            THEN
                                l_flg_result := r_cur.flg_status_result || pk_lab_tests_constant.g_analysis_urgent;
                            ELSE
                                BEGIN
                                    SELECT CASE
                                               WHEN pk_utils.is_number(dbms_lob.substr(arp.desc_analysis_result, 3800)) =
                                                    pk_lab_tests_constant.g_yes
                                                    AND arp.id_abnormality IS NULL
                                                    AND arp.analysis_result_value_2 IS NULL THEN
                                                CASE
                                                    WHEN arp.analysis_result_value_1 < arp.ref_val_min THEN
                                                     r_cur.flg_status_result || pk_lab_tests_constant.g_analysis_urgent
                                                    WHEN arp.analysis_result_value_1 > arp.ref_val_max THEN
                                                     r_cur.flg_status_result || pk_lab_tests_constant.g_analysis_urgent
                                                    ELSE
                                                     r_cur.flg_status_result
                                                END
                                               ELSE
                                                CASE
                                                    WHEN arp.id_abnormality IS NOT NULL
                                                         AND arp.id_abnormality != 7 THEN
                                                     r_cur.flg_status_result || pk_lab_tests_constant.g_analysis_urgent
                                                    ELSE
                                                     r_cur.flg_status_result
                                                END
                                           END
                                      INTO l_flg_result
                                      FROM (SELECT t.*,
                                                   row_number() over(PARTITION BY t.id_analysis_result ORDER BY coalesce(CASE
                                                       WHEN t.id_abnormality = 7 THEN
                                                        NULL
                                                       ELSE
                                                        t.id_abnormality
                                                   END, abnormality) DESC NULLS LAST) rn
                                            
                                              FROM (SELECT arp.*,
                                                           CASE
                                                                WHEN arp.analysis_result_value_1 < arp.ref_val_min THEN
                                                                 1
                                                                WHEN arp.analysis_result_value_1 > arp.ref_val_max THEN
                                                                 1
                                                                ELSE
                                                                 0
                                                            END abnormality
                                                      FROM analysis_result_par arp, analysis_result ar
                                                     WHERE ar.id_analysis_req_det = r_cur.id_analysis_req_det
                                                          
                                                       AND ar.id_analysis_result = arp.id_analysis_result) t) arp
                                     WHERE rn = 1;
                                EXCEPTION
                                    WHEN no_data_found THEN
                                        l_flg_result := r_cur.flg_status_result;
                                    WHEN too_many_rows THEN
                                        l_flg_result := r_cur.flg_status_result;
                                END;
                            END IF;
                        END IF;
                    ELSE
                        l_result     := NULL;
                        l_flg_result := r_cur.flg_status_result;
                    END IF;
                
                    g_error := 'GET ANALYSIS STATUS REQ';
                    pk_ea_logic_analysis.get_analysis_status_req(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_episode        => r_cur.id_episode,
                                                                 i_flg_time       => r_cur.flg_time,
                                                                 i_flg_status_req => CASE
                                                                                         WHEN r_cur.flg_status_det =
                                                                                              pk_lab_tests_constant.g_analysis_result
                                                                                              AND r_cur.flg_priority !=
                                                                                              pk_lab_tests_constant.g_analysis_normal THEN
                                                                                          r_cur.flg_status_req ||
                                                                                          pk_lab_tests_constant.g_analysis_urgent
                                                                                         ELSE
                                                                                          r_cur.flg_status_req
                                                                                     END,
                                                                 i_dt_req         => r_cur.dt_req,
                                                                 i_dt_begin       => nvl(r_cur.dt_pend_req, r_cur.dt_begin),
                                                                 o_status_str     => l_new_rec_row.status_str_req,
                                                                 o_status_msg     => l_new_rec_row.status_msg_req,
                                                                 o_status_icon    => l_new_rec_row.status_icon_req,
                                                                 o_status_flg     => l_new_rec_row.status_flg_req);
                
                    g_error := 'GET ANALYSIS STATUS DET';
                    pk_ea_logic_analysis.get_analysis_status_det(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_episode            => r_cur.id_episode,
                                                                 i_flg_time           => r_cur.flg_time,
                                                                 i_flg_status_det     => r_cur.flg_status_det,
                                                                 i_flg_referral       => r_cur.flg_referral,
                                                                 i_flg_status_harvest => r_cur.flg_status_harvest,
                                                                 i_flg_status_result  => l_flg_result,
                                                                 i_result             => l_result,
                                                                 i_dt_req             => r_cur.dt_req,
                                                                 i_dt_pend_req        => r_cur.dt_pend_req,
                                                                 i_dt_begin           => r_cur.dt_begin,
                                                                 o_status_str         => l_new_rec_row.status_str,
                                                                 o_status_msg         => l_new_rec_row.status_msg,
                                                                 o_status_icon        => l_new_rec_row.status_icon,
                                                                 o_status_flg         => l_new_rec_row.status_flg);
                
                    g_error                                := 'DEFINE NEW RECORD FOR LAB_TESTS_EA';
                    l_new_rec_row.id_analysis_req          := r_cur.id_analysis_req;
                    l_new_rec_row.id_analysis_req_det      := r_cur.id_analysis_req_det;
                    l_new_rec_row.id_ard_parent            := r_cur.id_ard_parent;
                    l_new_rec_row.id_analysis_result       := r_cur.id_analysis_result;
                    l_new_rec_row.id_analysis              := r_cur.id_analysis;
                    l_new_rec_row.dt_req                   := r_cur.dt_req;
                    l_new_rec_row.dt_target                := r_cur.dt_begin;
                    l_new_rec_row.dt_pend_req              := r_cur.dt_pend_req;
                    l_new_rec_row.dt_harvest               := r_cur.dt_harvest;
                    l_new_rec_row.dt_analysis_result       := r_cur.dt_analysis_result;
                    l_new_rec_row.id_sample_type           := r_cur.id_sample_type;
                    l_new_rec_row.id_exam_cat              := r_cur.id_exam_cat;
                    l_new_rec_row.flg_notes                := r_cur.flg_notes;
                    l_new_rec_row.flg_doc                  := r_cur.flg_doc;
                    l_new_rec_row.flg_time_harvest         := r_cur.flg_time;
                    l_new_rec_row.flg_status_req           := r_cur.flg_status_req;
                    l_new_rec_row.flg_status_det           := r_cur.flg_status_det;
                    l_new_rec_row.flg_status_harvest       := r_cur.flg_status_harvest;
                    l_new_rec_row.flg_status_result        := r_cur.flg_status_result;
                    l_new_rec_row.flg_priority             := r_cur.flg_priority;
                    l_new_rec_row.flg_col_inst             := r_cur.flg_col_inst;
                    l_new_rec_row.flg_referral             := r_cur.flg_referral;
                    l_new_rec_row.id_prof_writes           := r_cur.id_prof_writes;
                    l_new_rec_row.id_prof_order            := r_cur.id_prof_order;
                    l_new_rec_row.dt_order                 := r_cur.dt_order;
                    l_new_rec_row.id_order_type            := r_cur.id_order_type;
                    l_new_rec_row.id_analysis_codification := r_cur.id_analysis_codification;
                    l_new_rec_row.flg_abnormality          := r_cur.flg_abnormality;
                    l_new_rec_row.flg_relevant             := r_cur.flg_relevant;
                    l_new_rec_row.id_room_req              := r_cur.id_room_req;
                    l_new_rec_row.id_institution           := r_cur.id_institution;
                    l_new_rec_row.id_movement              := r_cur.id_movement;
                    l_new_rec_row.id_task_dependency       := r_cur.id_task_dependency;
                    l_new_rec_row.id_exec_institution      := r_cur.id_exec_institution;
                    l_new_rec_row.flg_req_origin_module    := r_cur.flg_req_origin_module;
                    l_new_rec_row.flg_orig_analysis        := r_cur.flg_orig_analysis;
                    l_new_rec_row.notes                    := r_cur.notes;
                    l_new_rec_row.notes_scheduler          := r_cur.notes_scheduler;
                    l_new_rec_row.notes_technician         := r_cur.notes_technician;
                    l_new_rec_row.notes_patient            := r_cur.notes_patient;
                    l_new_rec_row.notes_cancel             := r_cur.notes_cancel;
                    l_new_rec_row.id_patient               := r_cur.id_patient;
                    l_new_rec_row.id_visit                 := r_cur.id_visit;
                    l_new_rec_row.id_episode               := r_cur.id_episode;
                    l_new_rec_row.id_episode_origin        := r_cur.id_episode_origin;
                    l_new_rec_row.id_episode_destination   := r_cur.id_episode_destination;
                    l_new_rec_row.id_prev_episode          := r_cur.id_prev_episode;
                
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                       AND i_source_table_name NOT IN ('ANALYSIS_RESULT',
                                                       'ANALYSIS_RESULT_PAR',
                                                       'HARVEST',
                                                       'ANALYSIS_HARVEST',
                                                       'ANALYSIS_MEDIA_ARCHIVE')
                    THEN
                        g_error := 'TS_LAB_TESTS_EA.INS';
                        ts_lab_tests_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    ELSE
                        g_error := 'TS_LAB_TESTS_EA.UPD';
                        ts_lab_tests_ea.upd(rec_in => l_new_rec_row, rows_out => o_rowids);
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_analysis;

    PROCEDURE set_grid_task_analysis
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
    
        l_status_d VARCHAR2(2 CHAR);
        l_status_n VARCHAR2(2 CHAR);
    
        l_short_analysis sys_shortcut.id_sys_shortcut%TYPE;
        l_short_harvest  sys_shortcut.id_sys_shortcut%TYPE;
        l_short_result   sys_shortcut.id_sys_shortcut%TYPE;
    
        l_dt_str_1 VARCHAR2(200 CHAR);
        l_dt_str_2 VARCHAR2(200 CHAR);
    
        l_dt_1 VARCHAR2(200 CHAR);
        l_dt_2 VARCHAR2(200 CHAR);
    
        l_workflow                sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_WORKFLOW', i_prof);
        l_ref                     sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_AVAILABILITY', i_prof);
        l_status_in_patient_grids sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_STATUS_IN_PATIENT_GRIDS',
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
                IF l_workflow = pk_lab_tests_constant.g_yes
                THEN
                    SELECT pk_utils.str_split_c(l_status_in_patient_grids, '|')
                      INTO l_status
                      FROM dual;
                
                    FOR r_cur IN (SELECT /*+ opt_estimate (table ard rows=1)*/
                                   nvl(ar.id_episode, ar.id_episode_origin) id_episode,
                                   ar.id_patient,
                                   ar.id_analysis_req
                                    FROM analysis_req_det ard
                                    JOIN analysis_req ar
                                      ON ard.id_analysis_req = ar.id_analysis_req
                                   WHERE ard.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                        *
                                                         FROM TABLE(l_rowids) t)
                                     AND ard.flg_status NOT IN
                                         (pk_lab_tests_constant.g_analysis_predefined,
                                          pk_lab_tests_constant.g_analysis_draft))
                    LOOP
                        SELECT MAX(status_string_med) status_string_med,
                               MAX(flg_status_med) flg_status_med,
                               MAX(status_string_enf) status_string_enf,
                               MAX(flg_status_enf) flg_status_enf
                          INTO l_mess1_d, l_status_d, l_mess1_n, l_status_n
                          FROM (SELECT decode(rank_med,
                                              1,
                                              pk_utils.get_status_string(i_lang,
                                                                         i_prof,
                                                                         pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                                          i_prof,
                                                                                                                          id_episode,
                                                                                                                          flg_time,
                                                                                                                          flg_status,
                                                                                                                          flg_referral,
                                                                                                                          flg_status_harvest,
                                                                                                                          flg_status_result,
                                                                                                                          NULL,
                                                                                                                          dt_req_tstz,
                                                                                                                          dt_pend_req_tstz,
                                                                                                                          dt_begin_tstz),
                                                                         pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                                          i_prof,
                                                                                                                          id_episode,
                                                                                                                          flg_time,
                                                                                                                          flg_status,
                                                                                                                          flg_referral,
                                                                                                                          flg_status_harvest,
                                                                                                                          flg_status_result,
                                                                                                                          NULL,
                                                                                                                          dt_req_tstz,
                                                                                                                          dt_pend_req_tstz,
                                                                                                                          dt_begin_tstz),
                                                                         pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                                           i_prof,
                                                                                                                           id_episode,
                                                                                                                           flg_time,
                                                                                                                           flg_status,
                                                                                                                           flg_referral,
                                                                                                                           flg_status_harvest,
                                                                                                                           flg_status_result,
                                                                                                                           NULL,
                                                                                                                           dt_req_tstz,
                                                                                                                           dt_pend_req_tstz,
                                                                                                                           dt_begin_tstz),
                                                                         pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                                          i_prof,
                                                                                                                          id_episode,
                                                                                                                          flg_time,
                                                                                                                          flg_status,
                                                                                                                          flg_referral,
                                                                                                                          flg_status_harvest,
                                                                                                                          flg_status_result,
                                                                                                                          NULL,
                                                                                                                          dt_req_tstz,
                                                                                                                          dt_pend_req_tstz,
                                                                                                                          dt_begin_tstz)),
                                              NULL) status_string_med,
                                       decode(rank_med, 1, flg_status, NULL) flg_status_med,
                                       decode(rank_enf,
                                              1,
                                              pk_utils.get_status_string(i_lang,
                                                                         i_prof,
                                                                         pk_ea_logic_analysis.get_analysis_status_str_det(i_lang,
                                                                                                                          i_prof,
                                                                                                                          id_episode,
                                                                                                                          flg_time,
                                                                                                                          flg_status,
                                                                                                                          flg_referral,
                                                                                                                          flg_status_harvest,
                                                                                                                          flg_status_result,
                                                                                                                          NULL,
                                                                                                                          dt_req_tstz,
                                                                                                                          dt_pend_req_tstz,
                                                                                                                          dt_begin_tstz),
                                                                         pk_ea_logic_analysis.get_analysis_status_msg_det(i_lang,
                                                                                                                          i_prof,
                                                                                                                          id_episode,
                                                                                                                          flg_time,
                                                                                                                          flg_status,
                                                                                                                          flg_referral,
                                                                                                                          flg_status_harvest,
                                                                                                                          flg_status_result,
                                                                                                                          NULL,
                                                                                                                          dt_req_tstz,
                                                                                                                          dt_pend_req_tstz,
                                                                                                                          dt_begin_tstz),
                                                                         pk_ea_logic_analysis.get_analysis_status_icon_det(i_lang,
                                                                                                                           i_prof,
                                                                                                                           id_episode,
                                                                                                                           flg_time,
                                                                                                                           flg_status,
                                                                                                                           flg_referral,
                                                                                                                           flg_status_harvest,
                                                                                                                           flg_status_result,
                                                                                                                           NULL,
                                                                                                                           dt_req_tstz,
                                                                                                                           dt_pend_req_tstz,
                                                                                                                           dt_begin_tstz),
                                                                         pk_ea_logic_analysis.get_analysis_status_flg_det(i_lang,
                                                                                                                          i_prof,
                                                                                                                          id_episode,
                                                                                                                          flg_time,
                                                                                                                          flg_status,
                                                                                                                          flg_referral,
                                                                                                                          flg_status_harvest,
                                                                                                                          flg_status_result,
                                                                                                                          NULL,
                                                                                                                          dt_req_tstz,
                                                                                                                          dt_pend_req_tstz,
                                                                                                                          dt_begin_tstz)),
                                              NULL) status_string_enf,
                                       decode(rank_enf, 1, flg_status, NULL) flg_status_enf
                                  FROM (SELECT t.id_analysis_req_det,
                                               t.id_episode,
                                               t.flg_time,
                                               t.flg_status,
                                               t.flg_referral,
                                               t.flg_status_harvest,
                                               t.flg_status_result,
                                               t.dt_req_tstz,
                                               t.dt_pend_req_tstz,
                                               t.dt_begin_tstz,
                                               row_number() over(ORDER BY t.rank_med) rank_med,
                                               row_number() over(ORDER BY t.rank_enf) rank_enf
                                          FROM (SELECT t.*,
                                                       decode(t.flg_status,
                                                              pk_lab_tests_constant.g_analysis_result,
                                                              row_number() over(ORDER BY t.rank DESC),
                                                              pk_lab_tests_constant.g_analysis_req,
                                                              row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)) + 10000,
                                                              pk_lab_tests_constant.g_analysis_pending,
                                                              row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)) + 10000,
                                                              row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)) + 20000) rank_med,
                                                       decode(t.flg_status,
                                                              pk_lab_tests_constant.g_analysis_req,
                                                              row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)),
                                                              pk_lab_tests_constant.g_analysis_pending,
                                                              row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)),
                                                              row_number() over(ORDER BY coalesce(t.dt_pend_req_tstz,
                                                                            t.dt_begin_tstz,
                                                                            t.dt_req_tstz)) + 20000) rank_enf
                                                  FROM (SELECT t.*,
                                                               decode(flg_urgent,
                                                                      pk_lab_tests_constant.g_yes,
                                                                      (SELECT pk_sysdomain.get_rank(i_lang,
                                                                                                    'ANALYSIS_REQ_DET.FLG_STATUS.URGENT',
                                                                                                    t.flg_status)
                                                                         FROM dual) + 1000,
                                                                      (SELECT pk_sysdomain.get_rank(i_lang,
                                                                                                    'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                                                    t.flg_status)
                                                                         FROM dual)) rank
                                                          FROM (SELECT /*+ leading(ar) use_nl(ar ard)*/
                                                                 ard.id_analysis_req_det,
                                                                 ar.id_episode,
                                                                 ard.flg_time_harvest flg_time,
                                                                 ard.flg_status,
                                                                 ard.flg_status flg_status_harvest,
                                                                 ard.flg_referral,
                                                                 CASE
                                                                      WHEN ard.flg_status =
                                                                           pk_lab_tests_constant.g_analysis_result THEN
                                                                       CASE
                                                                           WHEN ard.flg_urgency !=
                                                                                pk_lab_tests_constant.g_analysis_normal
                                                                                OR ares.flg_urgent = pk_lab_tests_constant.g_yes THEN
                                                                            rs.value || pk_lab_tests_constant.g_analysis_urgent
                                                                           ELSE
                                                                            rs.value
                                                                       END
                                                                      ELSE
                                                                       rs.value
                                                                  END flg_status_result,
                                                                 ar.dt_req_tstz,
                                                                 ard.dt_pend_req_tstz,
                                                                 ard.dt_target_tstz dt_begin_tstz,
                                                                 CASE
                                                                      WHEN ard.flg_urgency !=
                                                                           pk_lab_tests_constant.g_analysis_normal
                                                                           OR ares.flg_urgent = pk_lab_tests_constant.g_yes THEN
                                                                       pk_lab_tests_constant.g_yes
                                                                      ELSE
                                                                       pk_lab_tests_constant.g_no
                                                                  END flg_urgent
                                                                  FROM (SELECT ar.*
                                                                          FROM analysis_req ar
                                                                          JOIN episode e
                                                                            ON ar.id_episode = e.id_episode
                                                                           AND ar.id_episode = r_cur.id_episode
                                                                        UNION ALL
                                                                        SELECT ar.*
                                                                          FROM analysis_req ar
                                                                          JOIN episode e
                                                                            ON ar.id_episode = e.id_episode
                                                                           AND ar.id_prev_episode = r_cur.id_episode
                                                                        UNION ALL
                                                                        SELECT ar.*
                                                                          FROM analysis_req ar
                                                                          JOIN episode e
                                                                            ON ar.id_episode = e.id_episode
                                                                           AND ar.id_episode_origin = r_cur.id_episode
                                                                        UNION ALL
                                                                        SELECT ar.*
                                                                          FROM analysis_req ar
                                                                         WHERE ar.id_episode IS NULL
                                                                           AND ar.id_episode_origin IS NULL
                                                                           AND ar.id_analysis_req = r_cur.id_analysis_req) ar,
                                                                       analysis_req_det ard,
                                                                       (SELECT ar.id_analysis_req_det,
                                                                               ar.id_result_status,
                                                                               CASE
                                                                                    WHEN pk_utils.is_number(dbms_lob.substr(ar.desc_analysis_result,
                                                                                                                            3800)) =
                                                                                         pk_lab_tests_constant.g_yes
                                                                                         AND ar.analysis_result_value_2 IS NULL THEN
                                                                                     CASE
                                                                                         WHEN ar.analysis_result_value_1 <
                                                                                              ar.ref_val_min THEN
                                                                                          pk_lab_tests_constant.g_yes
                                                                                         WHEN ar.analysis_result_value_1 >
                                                                                              ar.ref_val_max THEN
                                                                                          pk_lab_tests_constant.g_yes
                                                                                         ELSE
                                                                                          pk_lab_tests_constant.g_no
                                                                                     END
                                                                                    ELSE
                                                                                     CASE
                                                                                         WHEN ar.id_abnormality IS NOT NULL
                                                                                              AND ar.id_abnormality != 7 THEN
                                                                                          pk_lab_tests_constant.g_yes
                                                                                         ELSE
                                                                                          pk_lab_tests_constant.g_no
                                                                                     END
                                                                                END flg_urgent
                                                                          FROM (SELECT ar.id_analysis_req_det,
                                                                                       ar.id_result_status,
                                                                                       arp.desc_analysis_result,
                                                                                       arp.analysis_result_value_1,
                                                                                       arp.analysis_result_value_2,
                                                                                       arp.ref_val_min,
                                                                                       arp.ref_val_max,
                                                                                       arp.id_abnormality,
                                                                                       row_number() over(PARTITION BY id_harvest, id_analysis_req_par ORDER BY dt_ins_result_tstz DESC) rn
                                                                                  FROM analysis_result     ar,
                                                                                       analysis_result_par arp
                                                                                 WHERE ar.id_episode_orig = r_cur.id_episode
                                                                                   AND ar.id_analysis_result =
                                                                                       arp.id_analysis_result) ar
                                                                         WHERE ar.rn = 1) ares,
                                                                       result_status rs
                                                                 WHERE ar.id_analysis_req = ard.id_analysis_req
                                                                   AND ard.flg_status IN
                                                                       (SELECT /*+opt_estimate (table s rows=1)*/
                                                                         column_value
                                                                          FROM TABLE(l_status) s)
                                                                   AND (ard.flg_referral NOT IN
                                                                       (pk_lab_tests_constant.g_flg_referral_r,
                                                                         pk_lab_tests_constant.g_flg_referral_s,
                                                                         pk_lab_tests_constant.g_flg_referral_i) OR
                                                                       ard.flg_referral IS NULL)
                                                                   AND ard.id_analysis_req_det = ares.id_analysis_req_det(+)
                                                                   AND ares.id_result_status = rs.id_result_status(+)
                                                                UNION ALL
                                                                SELECT ard.id_analysis_req_det,
                                                                       ar.id_episode,
                                                                       ard.flg_time_harvest flg_time,
                                                                       ard.flg_status,
                                                                       ard.flg_status flg_status_harvest,
                                                                       ard.flg_referral,
                                                                       CASE
                                                                           WHEN ard.flg_urgency !=
                                                                                pk_lab_tests_constant.g_analysis_normal
                                                                                OR
                                                                                ares.flg_urgent = pk_lab_tests_constant.g_yes THEN
                                                                            rs.value ||
                                                                            pk_lab_tests_constant.g_analysis_urgent
                                                                           ELSE
                                                                            rs.value
                                                                       END flg_status_result,
                                                                       ar.dt_req_tstz,
                                                                       ard.dt_pend_req_tstz,
                                                                       ard.dt_target_tstz dt_begin_tstz,
                                                                       CASE
                                                                           WHEN ard.flg_urgency !=
                                                                                pk_lab_tests_constant.g_analysis_normal
                                                                                OR
                                                                                ares.flg_urgent = pk_lab_tests_constant.g_yes THEN
                                                                            pk_lab_tests_constant.g_yes
                                                                           ELSE
                                                                            pk_lab_tests_constant.g_no
                                                                       END flg_urgent
                                                                  FROM analysis_req ar,
                                                                       analysis_req_det ard,
                                                                       (SELECT ar.id_analysis_req_det,
                                                                               ar.id_result_status,
                                                                               CASE
                                                                                    WHEN pk_utils.is_number(dbms_lob.substr(ar.desc_analysis_result,
                                                                                                                            3800)) =
                                                                                         pk_lab_tests_constant.g_yes
                                                                                         AND ar.analysis_result_value_2 IS NULL THEN
                                                                                     CASE
                                                                                         WHEN ar.analysis_result_value_1 <
                                                                                              ar.ref_val_min THEN
                                                                                          pk_lab_tests_constant.g_yes
                                                                                         WHEN ar.analysis_result_value_1 >
                                                                                              ar.ref_val_max THEN
                                                                                          pk_lab_tests_constant.g_yes
                                                                                         ELSE
                                                                                          pk_lab_tests_constant.g_no
                                                                                     END
                                                                                    ELSE
                                                                                     CASE
                                                                                         WHEN ar.id_abnormality IS NOT NULL
                                                                                              AND ar.id_abnormality != 7 THEN
                                                                                          pk_lab_tests_constant.g_yes
                                                                                         ELSE
                                                                                          pk_lab_tests_constant.g_no
                                                                                     END
                                                                                END flg_urgent
                                                                          FROM (SELECT ar.id_analysis_req_det,
                                                                                       ar.id_result_status,
                                                                                       arp.desc_analysis_result,
                                                                                       arp.analysis_result_value_1,
                                                                                       arp.analysis_result_value_2,
                                                                                       arp.ref_val_min,
                                                                                       arp.ref_val_max,
                                                                                       arp.id_abnormality,
                                                                                       row_number() over(PARTITION BY id_harvest, id_analysis_req_par ORDER BY dt_ins_result_tstz DESC) rn
                                                                                  FROM analysis_result     ar,
                                                                                       analysis_result_par arp
                                                                                 WHERE ar.id_patient = r_cur.id_patient
                                                                                   AND ar.id_episode_orig != r_cur.id_episode
                                                                                   AND ar.id_analysis_result =
                                                                                       arp.id_analysis_result) ar
                                                                         WHERE ar.rn = 1) ares,
                                                                       result_status rs,
                                                                       episode e
                                                                 WHERE ar.id_patient = r_cur.id_patient
                                                                   AND ar.id_episode != r_cur.id_episode
                                                                   AND ar.id_analysis_req = ard.id_analysis_req
                                                                   AND (ard.flg_referral NOT IN
                                                                       (pk_lab_tests_constant.g_flg_referral_r,
                                                                         pk_lab_tests_constant.g_flg_referral_s,
                                                                         pk_lab_tests_constant.g_flg_referral_i) OR
                                                                       ard.flg_referral IS NULL)
                                                                   AND ard.flg_status =
                                                                       pk_lab_tests_constant.g_analysis_result
                                                                   AND ard.id_analysis_req_det = ares.id_analysis_req_det
                                                                   AND ares.id_result_status = rs.id_result_status(+)
                                                                   AND (ar.id_episode = e.id_episode OR
                                                                       ar.id_prev_episode = e.id_episode OR
                                                                       ar.id_episode_origin = e.id_episode)
                                                                   AND e.id_epis_type NOT IN
                                                                       (pk_alert_constant.g_epis_type_emergency,
                                                                        pk_alert_constant.g_epis_type_inpatient,
                                                                        pk_alert_constant.g_epis_type_operating)) t
                                                         WHERE l_ref = pk_lab_tests_constant.g_yes
                                                            OR (l_ref = pk_lab_tests_constant.g_no AND
                                                               t.flg_status != pk_lab_tests_constant.g_analysis_exterior)) t) t)
                                 WHERE rank_med = 1
                                    OR rank_enf = 1) t;
                    
                        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_intern_name => 'GRID_ANALYSIS',
                                                         o_id_shortcut => l_short_analysis,
                                                         o_error       => l_error_out)
                        THEN
                            l_short_analysis := 0;
                        END IF;
                    
                        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_intern_name => 'GRID_HARVEST',
                                                         o_id_shortcut => l_short_harvest,
                                                         o_error       => l_error_out)
                        THEN
                            l_short_harvest := 0;
                        END IF;
                    
                        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_intern_name => 'GRID_ANALYSIS_RESULTS',
                                                         o_id_shortcut => l_short_result,
                                                         o_error       => l_error_out)
                        THEN
                            l_short_result := 0;
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
                        
                            IF l_status_d = pk_lab_tests_constant.g_analysis_req
                            THEN
                                l_grid_task.analysis_d := l_short_harvest || l_mess1_d;
                            ELSIF l_status_d = pk_lab_tests_constant.g_analysis_result
                            THEN
                                l_grid_task.analysis_d := l_short_result || l_mess1_d;
                            ELSE
                                l_grid_task.analysis_d := l_short_analysis || l_mess1_d;
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
                        
                            IF l_status_n = pk_lab_tests_constant.g_analysis_req
                            THEN
                                l_grid_task.analysis_n := l_short_harvest || l_mess1_n;
                            ELSIF l_status_n = pk_lab_tests_constant.g_analysis_result
                            THEN
                                l_grid_task.analysis_n := l_short_result || l_mess1_n;
                            ELSE
                                l_grid_task.analysis_n := l_short_analysis || l_mess1_n;
                            END IF;
                        END IF;
                    
                        l_grid_task.id_episode := r_cur.id_episode;
                    
                        IF l_grid_task.id_episode IS NOT NULL
                        THEN
                            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                            IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                                            i_prof         => i_prof,
                                                            i_episode      => l_grid_task.id_episode,
                                                            analysis_d_in  => l_grid_task.analysis_d,
                                                            analysis_d_nin => FALSE,
                                                            analysis_n_in  => l_grid_task.analysis_n,
                                                            analysis_n_nin => FALSE,
                                                            o_error        => l_error_out)
                            THEN
                                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                            END IF;
                        
                            IF l_grid_task.analysis_d IS NULL
                               AND l_grid_task.analysis_n IS NULL
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
                                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_prev_episode';
                                IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_episode      => l_grid_task.id_episode,
                                                                analysis_d_in  => l_grid_task.analysis_d,
                                                                analysis_d_nin => FALSE,
                                                                analysis_n_in  => l_grid_task.analysis_n,
                                                                analysis_n_nin => FALSE,
                                                                o_error        => l_error_out)
                                THEN
                                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                END IF;
                            
                                IF l_grid_task.analysis_d IS NULL
                                   AND l_grid_task.analysis_n IS NULL
                                THEN
                                    g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_prev_episode';
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
                            SELECT DISTINCT ar.id_episode_origin
                              INTO l_grid_task.id_episode
                              FROM analysis_req ar
                             WHERE ar.id_episode_origin IS NOT NULL
                               AND ar.id_episode = r_cur.id_episode;
                        
                            IF l_grid_task.id_episode IS NOT NULL
                            THEN
                                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode_origin';
                                IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_episode      => l_grid_task.id_episode,
                                                                analysis_d_in  => l_grid_task.analysis_d,
                                                                analysis_d_nin => FALSE,
                                                                analysis_n_in  => l_grid_task.analysis_n,
                                                                analysis_n_nin => FALSE,
                                                                o_error        => l_error_out)
                                THEN
                                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                                END IF;
                            
                                IF l_grid_task.analysis_d IS NULL
                                   AND l_grid_task.analysis_n IS NULL
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
    END set_grid_task_analysis;

    PROCEDURE set_grid_task_harvest
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
    
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    
        l_dt_str_1 VARCHAR2(200 CHAR);
        l_dt_str_2 VARCHAR2(200 CHAR);
    
        l_dt_1 VARCHAR2(200 CHAR);
        l_dt_2 VARCHAR2(200 CHAR);
    
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
                FOR r_cur IN (SELECT *
                                FROM (SELECT h.id_episode, h.id_patient
                                        FROM (SELECT /*+opt_estimate (table ard rows=1)*/
                                               *
                                                FROM analysis_req_det ard
                                               WHERE ard.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                    *
                                                                     FROM TABLE(l_rowids) t)
                                                 AND ard.flg_status NOT IN
                                                     (pk_lab_tests_constant.g_analysis_predefined,
                                                      pk_lab_tests_constant.g_analysis_draft)) ard,
                                             analysis_harvest ah,
                                             harvest h
                                       WHERE ard.id_analysis_req_det = ah.id_analysis_req_det
                                         AND ah.id_harvest = h.id_harvest))
                LOOP
                    SELECT MAX(status_string) status_string
                      INTO l_grid_task.harvest
                      FROM (SELECT decode(rank,
                                          1,
                                          pk_utils.get_status_string(i_lang,
                                                                     i_prof,
                                                                     pk_ea_logic_analysis.get_harvest_status_str(i_prof,
                                                                                                                 flg_time,
                                                                                                                 flg_status,
                                                                                                                 dt_req_tstz,
                                                                                                                 dt_pend_req_tstz,
                                                                                                                 dt_begin_tstz,
                                                                                                                 'T'),
                                                                     pk_ea_logic_analysis.get_harvest_status_msg(i_prof,
                                                                                                                 flg_time,
                                                                                                                 flg_status,
                                                                                                                 dt_req_tstz,
                                                                                                                 dt_pend_req_tstz,
                                                                                                                 dt_begin_tstz,
                                                                                                                 'T'),
                                                                     pk_ea_logic_analysis.get_harvest_status_icon(i_prof,
                                                                                                                  flg_time,
                                                                                                                  flg_status,
                                                                                                                  dt_req_tstz,
                                                                                                                  dt_pend_req_tstz,
                                                                                                                  dt_begin_tstz,
                                                                                                                  'T'),
                                                                     pk_ea_logic_analysis.get_harvest_status_flg(i_prof,
                                                                                                                 flg_time,
                                                                                                                 flg_status,
                                                                                                                 dt_req_tstz,
                                                                                                                 dt_pend_req_tstz,
                                                                                                                 dt_begin_tstz,
                                                                                                                 'T')),
                                          NULL) status_string
                              FROM (SELECT t.*,
                                           row_number() over(ORDER BY pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', t.flg_status), coalesce(t.dt_pend_req_tstz, t.dt_begin_tstz, t.dt_req_tstz)) rank
                                      FROM (SELECT h.id_harvest,
                                                   h.id_episode,
                                                   ard.flg_time_harvest flg_time,
                                                   h.flg_status,
                                                   ar.dt_req_tstz,
                                                   ard.dt_pend_req_tstz,
                                                   ard.dt_target_tstz   dt_begin_tstz
                                              FROM harvest h, analysis_harvest ah, analysis_req_det ard, analysis_req ar
                                             WHERE h.id_episode = r_cur.id_episode
                                               AND h.flg_status = pk_lab_tests_constant.g_harvest_collected
                                               AND h.id_harvest = ah.id_harvest
                                               AND ah.flg_status != pk_lab_tests_constant.g_harvest_inactive
                                               AND ah.id_analysis_req_det = ard.id_analysis_req_det
                                               AND ard.flg_status != pk_lab_tests_constant.g_analysis_exterior
                                               AND ard.id_analysis_req = ar.id_analysis_req
                                               AND ar.id_episode = r_cur.id_episode) t)
                             WHERE rank = 1) t;
                
                    IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_intern_name => 'GRID_TUBE',
                                                     o_id_shortcut => l_shortcut,
                                                     o_error       => l_error_out)
                    THEN
                        l_shortcut := 0;
                    END IF;
                
                    g_error := 'GET SHORTCUT - DOCTOR';
                    IF l_grid_task.harvest IS NOT NULL
                    THEN
                        IF regexp_like(l_grid_task.harvest, '^\|D')
                        THEN
                            l_dt_str_1 := regexp_replace(l_grid_task.harvest,
                                                         '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*',
                                                         '\1');
                            l_dt_str_2 := regexp_replace(l_grid_task.harvest,
                                                         '^\|D\w{0,1}\|\d{14}\|.*\|(\d{14})\|.*',
                                                         '\1');
                        
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
                                l_grid_task.harvest := regexp_replace(l_grid_task.harvest, l_dt_str_1, l_dt_1);
                            ELSE
                                l_grid_task.harvest := regexp_replace(l_grid_task.harvest, l_dt_str_1, l_dt_1);
                                l_grid_task.harvest := regexp_replace(l_grid_task.harvest, l_dt_str_2, l_dt_2);
                            END IF;
                        ELSE
                            l_dt_str_2          := regexp_replace(l_grid_task.harvest,
                                                                  '^\|\w{0,2}\|.*/|(\d{14})\|.*',
                                                                  '\1');
                            l_dt_2              := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                      pk_date_utils.get_string_tstz(i_lang,
                                                                                                                    i_prof,
                                                                                                                    l_dt_str_2,
                                                                                                                    NULL),
                                                                                      'YYYYMMDDHH24MISS TZR');
                            l_grid_task.harvest := regexp_replace(l_grid_task.harvest, l_dt_str_2, l_dt_2);
                        END IF;
                    
                        l_grid_task.harvest := l_shortcut || l_grid_task.harvest;
                    END IF;
                
                    l_grid_task.id_episode := r_cur.id_episode;
                
                    IF l_grid_task.id_episode IS NOT NULL
                    THEN
                        g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                        IF NOT pk_grid.update_grid_task(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_episode   => l_grid_task.id_episode,
                                                        harvest_in  => l_grid_task.harvest,
                                                        harvest_nin => FALSE,
                                                        o_error     => l_error_out)
                        THEN
                            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                        END IF;
                    
                        IF l_grid_task.harvest IS NULL
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
                            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_prev_episode';
                            IF NOT pk_grid.update_grid_task(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_episode   => l_grid_task.id_episode,
                                                            harvest_in  => l_grid_task.harvest,
                                                            harvest_nin => FALSE,
                                                            o_error     => l_error_out)
                            THEN
                                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                            END IF;
                        
                            IF l_grid_task.harvest IS NULL
                            THEN
                                g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_prev_episode';
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
                        SELECT DISTINCT ar.id_episode_origin
                          INTO l_grid_task.id_episode
                          FROM analysis_req ar
                         WHERE ar.id_episode_origin IS NOT NULL
                           AND ar.id_episode = r_cur.id_episode;
                    
                        IF l_grid_task.id_episode IS NOT NULL
                        THEN
                            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode_origin';
                            IF NOT pk_grid.update_grid_task(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_episode   => l_grid_task.id_episode,
                                                            harvest_in  => l_grid_task.harvest,
                                                            harvest_nin => FALSE,
                                                            o_error     => l_error_out)
                            THEN
                                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                            END IF;
                        
                            IF l_grid_task.harvest IS NULL
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
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_harvest;

    PROCEDURE set_task_timeline_analysis
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
        l_process_name     VARCHAR2(30);
        l_rowids           table_varchar;
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
    
        l_flg_harv_collect_h   CONSTANT VARCHAR2(1 CHAR) := 'H';
        l_flg_harv_final_f     CONSTANT VARCHAR2(1 CHAR) := 'F';
        l_flg_harv_recollect_r CONSTANT VARCHAR2(1 CHAR) := 'R';
        l_flg_harv_transport_t CONSTANT VARCHAR2(1 CHAR) := 'T';
    
        l_tab_epis             table_number;
        l_tab_analysis_req_det table_number;
    
        l_rows_out  table_varchar;
        l_error_out t_error_out;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'TASK_TIMELINE_EA',
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
                                  'TASK_TIMELINE_EA' || ')',
                                  g_package_name,
                                  'SET_TASK_TIMELINE_ANALYSIS');
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                g_error := 'GET ANALYSIS_REQ_DET ROWIDS';
                get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                SELECT /*+opt_estimate (table ard rows=1)*/
                DISTINCT ar.id_episode, ard.id_analysis_req_det
                  BULK COLLECT
                  INTO l_tab_epis, l_tab_analysis_req_det
                  FROM analysis_req_det ard
                  JOIN analysis_req ar
                    ON ard.id_analysis_req = ar.id_analysis_req
                 WHERE ard.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                      *
                                       FROM TABLE(l_rowids) t);
            
                FOR r_cur IN (WITH epis_table AS
                                   (SELECT /*+opt_estimate(table t rows=1)*/
                                    column_value id_episode
                                     FROM TABLE(l_tab_epis) t),
                                  cso_table AS
                                   (SELECT /*+ materialize opt_estimate(table t1 rows=1) opt_estimate(table t2 rows=1)*/
                                    t1.*
                                     FROM epis_table t2
                                     JOIN TABLE(alert.pk_co_sign_api.tf_co_sign_task_hist_info(i_lang => i_lang, i_prof => i_prof, i_episode => t2.id_episode, i_id_co_sign => NULL, i_id_co_sign_hist => NULL, i_task_type => pk_alert_constant.g_task_lab_tests, i_id_task_group => NULL, i_tbl_id_task => l_tab_analysis_req_det)) t1
                                       ON 1 = 1)
                                  SELECT id_analysis_req,
                                         id_analysis_req_det,
                                         id_analysis,
                                         dt_req,
                                         dt_target,
                                         dt_pend_req,
                                         flg_status_req,
                                         flg_status_det,
                                         flg_status_harvest,
                                         dt_harvest,
                                         flg_time_harvest,
                                         id_prof_order,
                                         dt_order,
                                         id_patient,
                                         id_episode,
                                         id_visit,
                                         id_institution,
                                         flg_referral,
                                         code_analysis,
                                         id_room_req,
                                         flg_col_inst,
                                         id_order_type,
                                         id_prev_episode,
                                         flg_type_viewer,
                                         id_prof_writes,
                                         universal_desc_clob,
                                         rank,
                                         id_exam_cat,
                                         code_group,
                                         id_ref_group,
                                         flg_sos,
                                         flg_outdated,
                                         flg_status_epis,
                                         id_task_aggregator,
                                         flg_ongoing,
                                         flg_normal,
                                         id_prof_exec,
                                         dt_last_update,
                                         id_sample_type,
                                         code_desc_sample_type,
                                         flg_category_type,
                                         flg_priority,
                                         code_desc_group_parent,
                                         instructions_hash
                                    FROM (SELECT t.*,
                                                 dense_rank() over(PARTITION BY t.id_analysis_req_det ORDER BY t.id_harvest) rn_h,
                                                 dense_rank() over(PARTITION BY t.id_harvest ORDER BY t.dt_harvest DESC) rn_ah
                                            FROM (SELECT /*+opt_estimate (table ard rows=1)*/
                                                   ar.id_analysis_req,
                                                   ard.id_analysis_req_det,
                                                   ard.id_analysis,
                                                   ar.dt_req_tstz dt_req,
                                                   nvl(ard.dt_pend_req_tstz, ard.dt_target_tstz) dt_target,
                                                   ard.dt_pend_req_tstz dt_pend_req,
                                                   ar.flg_status flg_status_req,
                                                   ard.flg_status flg_status_det,
                                                   h.id_harvest,
                                                   h.flg_status flg_status_harvest,
                                                   h.dt_harvest_tstz dt_harvest,
                                                   ard.flg_time_harvest,
                                                   cso.id_prof_ordered_by id_prof_order,
                                                   cso.dt_ordered_by dt_order,
                                                   ar.id_patient,
                                                   nvl(ar.id_episode, ar.id_episode_origin) id_episode,
                                                   ar.id_visit,
                                                   ar.id_institution,
                                                   ard.flg_referral,
                                                   a.code_analysis code_analysis,
                                                   ard.id_room_req id_room_req,
                                                   ard.flg_col_inst flg_col_inst,
                                                   cso.id_order_type id_order_type,
                                                   ar.id_prev_episode id_prev_episode,
                                                   decode(ard.flg_status,
                                                          pk_lab_tests_constant.g_analysis_result,
                                                          pk_alert_constant.g_flg_type_viewer_analysis_res,
                                                          pk_lab_tests_constant.g_analysis_read,
                                                          pk_alert_constant.g_flg_type_viewer_analysis_res,
                                                          pk_alert_constant.g_flg_type_viewer_analysis) flg_type_viewer,
                                                   ar.id_prof_writes id_prof_writes,
                                                   NULL universal_desc_clob,
                                                   decode(ard.flg_referral,
                                                          NULL,
                                                          decode(ard.flg_status,
                                                                 pk_lab_tests_constant.g_analysis_toexec,
                                                                 pk_sysdomain.get_rank(i_lang,
                                                                                       'HARVEST.FLG_STATUS',
                                                                                       h.flg_status),
                                                                 pk_sysdomain.get_rank(i_lang,
                                                                                       'ANALYSIS_REQ_DET.FLG_STATUS',
                                                                                       ard.flg_status)),
                                                          pk_sysdomain.get_rank(i_lang,
                                                                                'ANALYSIS_REQ_DET.FLG_REFERRAL',
                                                                                ard.flg_referral)) rank,
                                                   ard.id_exam_cat,
                                                   'EXAM_CAT.CODE_EXAM_CAT.' || ard.id_exam_cat code_group,
                                                   decode(ard.id_order_recurrence, NULL, NULL, ard.id_analysis) id_ref_group,
                                                   nvl(ard.flg_prn, pk_alert_constant.g_no) flg_sos,
                                                   decode(ard.flg_status,
                                                          pk_lab_tests_constant.g_analysis_result,
                                                          l_flg_outdated,
                                                          pk_lab_tests_constant.g_analysis_read,
                                                          l_flg_outdated,
                                                          l_flg_not_outdated) flg_outdated,
                                                   epis.flg_status flg_status_epis,
                                                   ard.id_order_recurrence id_task_aggregator,
                                                   decode(ard.flg_status,
                                                          pk_lab_tests_constant.g_analysis_exec,
                                                          pk_prog_notes_constants.g_task_finalized_f,
                                                          pk_lab_tests_constant.g_analysis_result,
                                                          pk_prog_notes_constants.g_task_finalized_f,
                                                          pk_lab_tests_constant.g_analysis_read,
                                                          pk_prog_notes_constants.g_task_finalized_f,
                                                          pk_prog_notes_constants.g_task_ongoing_o) flg_ongoing,
                                                   pk_alert_constant.g_yes flg_normal,
                                                   decode(ard.id_order_recurrence,
                                                          NULL,
                                                          coalesce(h.id_prof_harvest,
                                                                   cso.id_prof_ordered_by,
                                                                   ar.id_prof_writes),
                                                          NULL) id_prof_exec,
                                                   nvl(ard.dt_last_update_tstz, ar.dt_req_tstz) dt_last_update,
                                                   ard.id_sample_type id_sample_type,
                                                   'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ard.id_sample_type code_desc_sample_type,
                                                   ais.flg_category_type,
                                                   ar.flg_priority flg_priority,
                                                   CASE
                                                        WHEN pk_lab_tests_utils.get_lab_test_category(i_lang,
                                                                                                      i_prof,
                                                                                                      ard.id_exam_cat) IS NOT NULL THEN
                                                         'EXAM_CAT.CODE_EXAM_CAT.' ||
                                                         pk_lab_tests_utils.get_lab_test_category(i_lang,
                                                                                                  i_prof,
                                                                                                  ard.id_exam_cat)
                                                        ELSE
                                                         NULL
                                                    END code_desc_group_parent,
                                                   standard_hash(ard.flg_urgency || '|' || ard.flg_time_harvest || '|' ||
                                                                 ard.dt_target_tstz || '|' || ard.flg_prn --|| '|' ||
                                                                 --ard.id_order_recurrence 
                                                                ,
                                                                 'MD5') instructions_hash
                                                    FROM analysis_req_det ard
                                                   INNER JOIN analysis_req ar
                                                      ON (ard.id_analysis_req = ar.id_analysis_req)
                                                   INNER JOIN analysis a
                                                      ON (ard.id_analysis = a.id_analysis)
                                                    LEFT OUTER JOIN (SELECT ah.id_analysis_req_det, ah.id_harvest
                                                                      FROM analysis_harvest ah, harvest h
                                                                     WHERE ah.flg_status = pk_lab_tests_constant.g_active
                                                                       AND ah.id_harvest = h.id_harvest) ah
                                                      ON ah.id_analysis_req_det = ard.id_analysis_req_det
                                                    LEFT OUTER JOIN (SELECT h.id_harvest,
                                                                           h.flg_status,
                                                                           h.dt_harvest_tstz,
                                                                           h.id_prof_harvest
                                                                      FROM harvest h) h
                                                      ON h.id_harvest = ah.id_harvest
                                                     AND h.flg_status IN (l_flg_harv_collect_h,
                                                                          l_flg_harv_final_f,
                                                                          l_flg_harv_recollect_r,
                                                                          l_flg_harv_transport_t)
                                                    LEFT JOIN cso_table cso
                                                      ON (ard.id_co_sign_order = cso.id_co_sign_hist)
                                                   INNER JOIN episode epis
                                                      ON (nvl(ar.id_episode,
                                                              nvl(ar.id_episode_origin, ar.id_episode_destination)) =
                                                         epis.id_episode)
                                                    LEFT JOIN analysis_instit_soft ais
                                                      ON ais.id_analysis = ard.id_analysis
                                                     AND ais.id_sample_type = ard.id_sample_type
                                                     AND ais.flg_available = pk_lab_tests_constant.g_available
                                                     AND ais.flg_type = pk_lab_tests_constant.g_analysis_can_req
                                                     AND ais.id_institution = i_prof.institution
                                                     AND ais.id_software = i_prof.software
                                                    LEFT JOIN (SELECT DISTINCT gar.id_record id_analysis
                                                                FROM group_access ga
                                                               INNER JOIN group_access_prof gaf
                                                                  ON gaf.id_group_access = ga.id_group_access
                                                               INNER JOIN group_access_record gar
                                                                  ON gar.id_group_access = ga.id_group_access
                                                               WHERE ga.id_institution = i_prof.institution
                                                                 AND ga.id_software = i_prof.software
                                                                 AND ga.flg_type =
                                                                     pk_lab_tests_constant.g_infectious_diseases_orders
                                                                 AND gar.flg_type = 'A'
                                                                 AND ga.flg_available = pk_lab_tests_constant.g_available
                                                                 AND gaf.flg_available = pk_lab_tests_constant.g_available
                                                                 AND gar.flg_available = pk_lab_tests_constant.g_available) a_infect
                                                      ON a_infect.id_analysis = ard.id_analysis
                                                   WHERE ard.flg_status != pk_lab_tests_constant.g_analysis_predefined
                                                     AND (a_infect.id_analysis IS NULL OR
                                                         i_event_type NOT IN
                                                         (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update))
                                                     AND ard.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                        *
                                                                         FROM TABLE(l_rowids) t)) t)
                                   WHERE rn_h = 1
                                     AND rn_ah = 1)
                LOOP
                
                    g_error := 'GET ANALYSIS STATUS';
                    pk_ea_logic_analysis.get_analysis_status_det(i_lang               => i_lang,
                                                                 i_prof               => i_prof,
                                                                 i_episode            => r_cur.id_episode,
                                                                 i_flg_time           => r_cur.flg_time_harvest,
                                                                 i_flg_status_det     => r_cur.flg_status_det,
                                                                 i_flg_referral       => r_cur.flg_referral,
                                                                 i_flg_status_harvest => r_cur.flg_status_harvest,
                                                                 i_flg_status_result  => NULL,
                                                                 i_result             => NULL,
                                                                 i_dt_req             => r_cur.dt_req,
                                                                 i_dt_pend_req        => r_cur.dt_pend_req,
                                                                 i_dt_begin           => r_cur.dt_target,
                                                                 o_status_str         => l_new_rec_row.status_str,
                                                                 o_status_msg         => l_new_rec_row.status_msg,
                                                                 o_status_icon        => l_new_rec_row.status_icon,
                                                                 o_status_flg         => l_new_rec_row.status_flg);
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_lab;
                    l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_analysis;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid          := r_cur.id_analysis_req_det;
                    l_new_rec_row.dt_begin               := nvl(r_cur.dt_pend_req, r_cur.dt_target);
                    l_new_rec_row.flg_status_req         := r_cur.flg_status_det;
                    l_new_rec_row.flg_type_viewer        := r_cur.flg_type_viewer;
                    l_new_rec_row.id_prof_req            := r_cur.id_prof_writes;
                    l_new_rec_row.dt_req                 := r_cur.dt_req;
                    l_new_rec_row.id_patient             := r_cur.id_patient;
                    l_new_rec_row.id_episode             := r_cur.id_episode;
                    l_new_rec_row.id_visit               := r_cur.id_visit;
                    l_new_rec_row.id_institution         := r_cur.id_institution;
                    l_new_rec_row.code_description       := r_cur.code_analysis;
                    l_new_rec_row.flg_outdated           := l_flg_not_outdated;
                    l_new_rec_row.rank                   := r_cur.rank;
                    l_new_rec_row.id_group_import        := r_cur.id_exam_cat;
                    l_new_rec_row.code_desc_group        := r_cur.code_group;
                    l_new_rec_row.id_ref_group           := r_cur.id_ref_group;
                    l_new_rec_row.flg_sos                := r_cur.flg_sos;
                    l_new_rec_row.id_task_aggregator     := r_cur.id_task_aggregator;
                    l_new_rec_row.flg_ongoing            := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal             := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec           := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments       := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update         := r_cur.dt_last_update;
                    l_new_rec_row.id_sample_type         := r_cur.id_sample_type;
                    l_new_rec_row.code_desc_sample_type  := r_cur.code_desc_sample_type;
                    l_new_rec_row.id_task_related        := r_cur.id_analysis_req_det;
                    l_new_rec_row.flg_type               := r_cur.flg_category_type;
                    l_new_rec_row.flg_stat               := r_cur.flg_priority;
                    l_new_rec_row.code_desc_group_parent := r_cur.code_desc_group_parent;
                    l_new_rec_row.instructions_hash      := r_cur.instructions_hash;
                
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          'TASK_TIMELINE_EA' || '): ' || g_error,
                                          g_package_name,
                                          'SET_TASK_TIMELINE_ANALYSIS');
                
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable                    
                    IF ((l_new_rec_row.flg_status_req IN
                       (pk_lab_tests_constant.g_analysis_req,
                          pk_lab_tests_constant.g_analysis_pending,
                          pk_lab_tests_constant.g_analysis_result,
                          pk_lab_tests_constant.g_analysis_exterior,
                          pk_lab_tests_constant.g_analysis_tosched)) OR
                       (l_new_rec_row.flg_status_req = pk_lab_tests_constant.g_analysis_sos AND
                       r_cur.flg_sos = pk_alert_constant.g_yes))
                       AND r_cur.flg_status_epis != pk_alert_constant.g_epis_status_cancel
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = pk_alert_constant.g_tl_table_name_analysis
                           AND tte.id_tl_task = pk_prog_notes_constants.g_task_lab;
                    
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
                        IF l_new_rec_row.flg_status_req IN
                           (pk_lab_tests_constant.g_analysis_cancel, pk_lab_tests_constant.g_analysis_predefined) -- Cancelled ('C')
                           OR r_cur.flg_status_epis = pk_alert_constant.g_epis_status_cancel
                        THEN
                            -- Information in states that are not relevant are DELETED
                            l_process_name  := 'DELETE';
                            l_event_into_ea := 'D';
                        ELSE
                            l_process_name             := 'UPDATE';
                            l_event_into_ea            := 'U';
                            l_new_rec_row.flg_outdated := l_flg_outdated;
                        END IF;
                    END IF;
                
                    /*
                    * Operações a executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => l_rows_out);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE: Apenas poderá ocorrer DELETE's nas tabelas ANALYSIS_REQ e ANALYSIS_REQ_DET
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => l_rows_out);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
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
                                                dt_end_in    => NULL,
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
                                                --
                                                flg_outdated_nin       => TRUE,
                                                flg_outdated_in        => l_new_rec_row.flg_outdated,
                                                id_ref_group_nin       => TRUE,
                                                id_ref_group_in        => l_new_rec_row.id_ref_group,
                                                flg_sos_nin            => TRUE,
                                                flg_sos_in             => l_new_rec_row.flg_sos,
                                                id_task_aggregator_nin => TRUE,
                                                id_task_aggregator_in  => l_new_rec_row.id_task_aggregator,
                                                flg_ongoing_nin        => TRUE,
                                                flg_ongoing_in         => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin         => TRUE,
                                                flg_normal_in          => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin       => TRUE,
                                                id_prof_exec_in        => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin   => TRUE,
                                                flg_has_comments_in    => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in      => l_new_rec_row.dt_last_update,
                                                --
                                                id_sample_type_in          => l_new_rec_row.id_sample_type,
                                                id_sample_type_nin         => FALSE,
                                                id_sub_group_import_in     => l_new_rec_row.id_sub_group_import,
                                                id_sub_group_import_nin    => FALSE,
                                                code_desc_sample_type_in   => l_new_rec_row.code_desc_sample_type,
                                                code_desc_sample_type_nin  => FALSE,
                                                code_desc_sub_group_in     => l_new_rec_row.code_desc_sub_group,
                                                code_desc_sub_group_nin    => FALSE,
                                                id_task_related_in         => l_new_rec_row.id_task_related,
                                                id_task_related_nin        => TRUE,
                                                flg_type_in                => l_new_rec_row.flg_type,
                                                flg_type_nin               => TRUE,
                                                code_desc_group_parent_in  => l_new_rec_row.code_desc_group_parent,
                                                code_desc_group_parent_nin => TRUE,
                                                instructions_hash_in       => l_new_rec_row.instructions_hash,
                                                instructions_hash_nin      => TRUE,
                                                
                                                --
                                                rows_out => l_rows_out);
                    
                        IF l_rows_out.count = 0
                        THEN
                            g_error := 'TS_TASK_TIMELINE_EA.INS';
                            ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => l_rows_out);
                        END IF;
                    
                    ELSE
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_TIMELINE_ANALYSIS',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_analysis;

    PROCEDURE set_task_timeline_analysis_res
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row task_timeline_ea%ROWTYPE;
    
        l_top_result CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_RESULTS_ON_TOP', i_prof);
    
        l_process_name  VARCHAR2(30);
        l_rowids        table_varchar;
        l_event_into_ea VARCHAR2(1);
        l_update_reg    NUMBER(24);
    
        l_flg_outdated                 CONSTANT task_timeline_ea.flg_outdated%TYPE := 1;
        l_flg_not_outdated             CONSTANT task_timeline_ea.flg_outdated%TYPE := 0;
        l_analy_res_status_final_f     CONSTANT result_status.value%TYPE := 'F';
        l_analy_res_status_fix_final_c CONSTANT result_status.value%TYPE := 'C';
        l_analysis_res_active_a        CONSTANT analysis_result.flg_status%TYPE := 'A';
    
        l_rows_out  table_varchar;
        l_error_out t_error_out;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'TASK_TIMELINE_EA',
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
                                  'TASK_TIMELINE_EA' || ')',
                                  g_package_name,
                                  'SET_TASK_TIMELINE_ANALYSIS');
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                IF i_source_table_name = 'ANALYSIS_RESULT'
                THEN
                    SELECT arp.rowid
                      BULK COLLECT
                      INTO l_rowids
                      FROM analysis_result_par arp
                     WHERE arp.id_analysis_result IN
                           (SELECT /*+ opt_estimate(table ares rows=1)*/
                             ares.id_analysis_result
                              FROM analysis_result ares
                             WHERE ares.rowid IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                   column_value
                                                    FROM TABLE(i_rowids) t));
                
                ELSIF i_source_table_name = 'ANALYSIS_RESULT_PAR'
                THEN
                    l_rowids := i_rowids;
                END IF;
            
                FOR r_cur IN (SELECT /*+opt_estimate (table arp rows=1)*/
                               arp.id_analysis_result_par id_task_refid,
                               epis.id_patient,
                               epis.id_episode,
                               epis.id_visit,
                               ares.id_institution,
                               coalesce(h.dt_harvest_tstz, ares.dt_sample, ares.dt_analysis_result_tstz) dt_req,
                               nvl(arp.id_professional_upd, arp.id_professional) id_prof_req,
                               'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' || arp.id_analysis_parameter code_description,
                               decode(nvl(ares.flg_status, l_analysis_res_active_a),
                                      l_analysis_res_active_a,
                                      decode(rs.value,
                                             l_analy_res_status_final_f,
                                             l_flg_outdated,
                                             l_analy_res_status_fix_final_c,
                                             l_flg_outdated,
                                             l_flg_not_outdated),
                                      l_flg_outdated) flg_outdated,
                               ares.id_exam_cat id_group_import,
                               'EXAM_CAT.CODE_EXAM_CAT.' || ares.id_exam_cat code_desc_group,
                               h.dt_harvest_tstz dt_execution,
                               h.flg_status flg_status_harvest,
                               nvl(ares.flg_status, l_analysis_res_active_a) flg_status_res,
                               rs.value flg_status_res_arp,
                               decode(l_top_result,
                                      pk_alert_constant.g_yes,
                                      0,
                                      row_number()
                                      over(ORDER BY pk_sysdomain.get_rank(i_lang, rs.code_result_status, rs.value),
                                           nvl(arp.dt_analysis_result_par_upd, arp.dt_analysis_result_par_tstz) DESC)) rank,
                               arp.id_professional_cancel id_prof_cancel,
                               epis.flg_status flg_status_epis,
                               decode(nvl(ares.flg_status, l_analysis_res_active_a),
                                      l_analysis_res_active_a,
                                      decode(rs.value,
                                             l_analy_res_status_final_f,
                                             pk_prog_notes_constants.g_task_finalized_f,
                                             l_analy_res_status_fix_final_c,
                                             pk_prog_notes_constants.g_task_finalized_f,
                                             pk_prog_notes_constants.g_task_ongoing_o),
                                      pk_prog_notes_constants.g_task_finalized_f) flg_ongoing,
                               CASE
                                    WHEN dbms_lob.getlength(arp.desc_analysis_result) < 4000
                                         AND pk_utils.is_number(arp.desc_analysis_result) = pk_lab_tests_constant.g_yes THEN
                                     CASE
                                         WHEN pk_lab_tests_external_api_db.is_lab_result_outside_params(i_lang,
                                                                                                        i_prof,
                                                                                                        'I',
                                                                                                        arp.desc_analysis_result,
                                                                                                        arp.analysis_result_value_1,
                                                                                                        arp.ref_val_min) =
                                              pk_alert_constant.g_yes THEN
                                          pk_alert_constant.g_no
                                         WHEN pk_lab_tests_external_api_db.is_lab_result_outside_params(i_lang,
                                                                                                        i_prof,
                                                                                                        'A',
                                                                                                        arp.desc_analysis_result,
                                                                                                        arp.analysis_result_value_1,
                                                                                                        arp.ref_val_max) =
                                              pk_alert_constant.g_yes THEN
                                          pk_alert_constant.g_no
                                         ELSE
                                          pk_alert_constant.g_yes
                                     END
                                    ELSE
                                     pk_alert_constant.g_yes
                                END flg_normal,
                               coalesce(arp.id_professional_upd, arp.id_professional, ares.id_professional) id_prof_exec,
                               CASE
                                    WHEN arp.notes_doctor_registry IS NULL
                                         OR dbms_lob.compare(arp.notes_doctor_registry, empty_clob()) = 0 THEN
                                     pk_alert_constant.g_no
                                    ELSE
                                     pk_alert_constant.g_yes
                                END flg_has_comments,
                               arp.notes_doctor_registry universal_desc_clob,
                               coalesce(arp.dt_doctor_registry_tstz,
                                        arp.dt_analysis_result_par_upd,
                                        ares.dt_analysis_result_tstz) dt_last_update,
                               ares.id_sample_type id_sample_type,
                               'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || ares.id_sample_type code_desc_sample_type,
                               ares.id_analysis id_sub_group_import,
                               'ANALYSIS.CODE_ANALYSIS.' || ares.id_analysis code_desc_sub_group,
                               arp.flg_relevant,
                               ares.id_analysis_req_det,
                               coalesce(arp.dt_analysis_result_par_upd,
                                        arp.dt_analysis_result_par_tstz,
                                        ares.dt_analysis_result_tstz) dt_result,
                               CASE
                                    WHEN pk_lab_tests_utils.get_lab_test_category(i_lang, i_prof, ares.id_exam_cat) IS NOT NULL THEN
                                     'EXAM_CAT.CODE_EXAM_CAT.' ||
                                     pk_lab_tests_utils.get_lab_test_category(i_lang, i_prof, ares.id_exam_cat)
                                    ELSE
                                     NULL
                                END code_desc_group_parent,
                               (SELECT ais.flg_category_type
                                  FROM analysis_instit_soft ais
                                 WHERE ais.id_analysis = ares.id_analysis
                                   AND ais.id_sample_type = ares.id_sample_type
                                   AND ais.flg_available = pk_lab_tests_constant.g_available
                                   AND ais.flg_type = pk_lab_tests_constant.g_analysis_can_req
                                   AND ais.id_institution = i_prof.institution
                                   AND ais.id_software = i_prof.software) flg_category_type
                                FROM analysis_result_par arp
                               INNER JOIN analysis_result ares
                                  ON ares.id_analysis_result = arp.id_analysis_result
                               INNER JOIN result_status rs
                                  ON arp.id_result_status = rs.id_result_status
                                LEFT OUTER JOIN harvest h
                                  ON ares.id_harvest = h.id_harvest
                               INNER JOIN episode epis
                                  ON ares.id_episode_orig = epis.id_episode
                                LEFT JOIN (SELECT DISTINCT gar.id_record id_analysis
                                            FROM group_access ga
                                           INNER JOIN group_access_prof gaf
                                              ON gaf.id_group_access = ga.id_group_access
                                           INNER JOIN group_access_record gar
                                              ON gar.id_group_access = ga.id_group_access
                                           WHERE ga.id_institution = i_prof.institution
                                             AND ga.id_software = i_prof.software
                                             AND ga.flg_type = pk_lab_tests_constant.g_infectious_diseases_results
                                             AND gar.flg_type = 'A'
                                             AND ga.flg_available = pk_lab_tests_constant.g_available
                                             AND gaf.flg_available = pk_lab_tests_constant.g_available
                                             AND gar.flg_available = pk_lab_tests_constant.g_available) a_infect
                                  ON a_infect.id_analysis = ares.id_analysis
                               WHERE arp.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                    *
                                                     FROM TABLE(l_rowids) t)
                                 AND (a_infect.id_analysis IS NULL OR
                                     i_event_type NOT IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)))
                LOOP
                
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    --
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_lab_results;
                    l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_analysis_res;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                    --
                    l_new_rec_row.id_task_refid       := r_cur.id_task_refid;
                    l_new_rec_row.dt_begin            := NULL;
                    l_new_rec_row.flg_status_req      := r_cur.flg_status_res_arp;
                    l_new_rec_row.flg_type_viewer     := NULL;
                    l_new_rec_row.id_prof_req         := r_cur.id_prof_req;
                    l_new_rec_row.dt_req              := r_cur.dt_req;
                    l_new_rec_row.id_patient          := r_cur.id_patient;
                    l_new_rec_row.id_episode          := r_cur.id_episode;
                    l_new_rec_row.id_visit            := r_cur.id_visit;
                    l_new_rec_row.id_institution      := r_cur.id_institution;
                    l_new_rec_row.code_description    := r_cur.code_description;
                    l_new_rec_row.flg_outdated        := r_cur.flg_outdated;
                    l_new_rec_row.rank                := r_cur.rank;
                    l_new_rec_row.id_group_import     := r_cur.id_group_import;
                    l_new_rec_row.code_desc_group     := r_cur.code_desc_group;
                    l_new_rec_row.dt_execution        := r_cur.dt_execution;
                    l_new_rec_row.flg_sos             := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing         := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal          := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec        := r_cur.id_prof_exec;
                    l_new_rec_row.flg_has_comments    := r_cur.flg_has_comments;
                    l_new_rec_row.universal_desc_clob := r_cur.universal_desc_clob;
                    l_new_rec_row.dt_last_update      := r_cur.dt_last_update;
                
                    l_new_rec_row.id_sample_type         := r_cur.id_sample_type;
                    l_new_rec_row.id_sub_group_import    := r_cur.id_sub_group_import;
                    l_new_rec_row.code_desc_sample_type  := r_cur.code_desc_sample_type;
                    l_new_rec_row.code_desc_sub_group    := r_cur.code_desc_sub_group;
                    l_new_rec_row.flg_relevant           := r_cur.flg_relevant;
                    l_new_rec_row.id_task_related        := r_cur.id_analysis_req_det;
                    l_new_rec_row.dt_result              := r_cur.dt_result;
                    l_new_rec_row.code_desc_group_parent := r_cur.code_desc_group_parent;
                    l_new_rec_row.flg_type               := r_cur.flg_category_type;
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          'TASK_TIMELINE_EA' || '): ' || g_error,
                                          g_package_name,
                                          'SET_TASK_TIMELINE_ANALYSIS');
                
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF r_cur.flg_status_res = pk_alert_constant.g_active
                       AND r_cur.id_prof_cancel IS NULL
                       AND r_cur.flg_status_epis != pk_alert_constant.g_epis_status_cancel
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = pk_alert_constant.g_tl_table_name_analysis_res
                           AND tte.id_tl_task = pk_prog_notes_constants.g_task_lab_results;
                    
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
                        IF r_cur.flg_status_res = pk_alert_constant.g_cancelled
                           OR r_cur.id_prof_cancel IS NOT NULL
                           OR r_cur.flg_status_epis = pk_alert_constant.g_epis_status_cancel
                        THEN
                            -- Information in states that are not relevant are DELETED
                            l_process_name  := 'DELETE';
                            l_event_into_ea := 'D';
                        ELSE
                            l_process_name             := 'UPDATE';
                            l_event_into_ea            := 'U';
                            l_new_rec_row.flg_outdated := l_flg_outdated;
                        END IF;
                    END IF;
                
                    /*
                    * Operações a executar sobre a tabela de Easy Access TASK_TIMELINE_EA:
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    -- INSERT
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => l_rows_out);
                    
                        -- DELETE: Apenas poderá ocorrer DELETE's nas tabelas ANALYSIS_REQ e ANALYSIS_REQ_DET
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => l_rows_out);
                    
                        -- UPDATE
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.UPD';
                        ts_task_timeline_ea.upd(id_task_refid_in => l_new_rec_row.id_task_refid,
                                                id_tl_task_in    => l_new_rec_row.id_tl_task,
                                                --
                                                id_patient_nin     => FALSE,
                                                id_patient_in      => l_new_rec_row.id_patient,
                                                id_episode_nin     => FALSE,
                                                id_episode_in      => l_new_rec_row.id_episode,
                                                id_visit_nin       => FALSE,
                                                id_visit_in        => l_new_rec_row.id_visit,
                                                id_institution_nin => FALSE,
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
                                                dt_end_in    => NULL,
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
                                                --
                                                flg_outdated_nin     => TRUE,
                                                flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                flg_sos_nin          => FALSE,
                                                flg_sos_in           => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin      => TRUE,
                                                flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin       => TRUE,
                                                flg_normal_in        => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin     => TRUE,
                                                id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin => TRUE,
                                                flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                dt_last_update_nin   => TRUE,
                                                dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                --
                                                id_sample_type_in          => l_new_rec_row.id_sample_type,
                                                id_sample_type_nin         => FALSE,
                                                id_sub_group_import_in     => l_new_rec_row.id_sub_group_import,
                                                id_sub_group_import_nin    => FALSE,
                                                code_desc_sample_type_in   => l_new_rec_row.code_desc_sample_type,
                                                code_desc_sample_type_nin  => FALSE,
                                                code_desc_sub_group_in     => l_new_rec_row.code_desc_sub_group,
                                                code_desc_sub_group_nin    => FALSE,
                                                flg_relevant_in            => l_new_rec_row.flg_relevant,
                                                flg_relevant_nin           => FALSE,
                                                id_task_related_in         => l_new_rec_row.id_task_related,
                                                id_task_related_nin        => TRUE,
                                                dt_result_in               => l_new_rec_row.dt_result,
                                                dt_result_nin              => TRUE,
                                                code_desc_group_parent_in  => l_new_rec_row.code_desc_group_parent,
                                                code_desc_group_parent_nin => TRUE,
                                                flg_type_in                => l_new_rec_row.flg_type,
                                                flg_type_nin               => TRUE,
                                                
                                                --
                                                rows_out => l_rows_out);
                    
                        IF l_rows_out.count = 0
                        THEN
                            g_error := 'TS_TASK_TIMELINE_EA.INS';
                            ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => l_rows_out);
                        END IF;
                    ELSE
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_TIMELINE_ANALYSIS_RES',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_task_timeline_analysis_res;

    PROCEDURE set_order_recurr_control
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
    
        l_status_d VARCHAR2(2 CHAR);
        l_status_n VARCHAR2(2 CHAR);
    
        l_short_analysis sys_shortcut.id_sys_shortcut%TYPE;
        l_short_harvest  sys_shortcut.id_sys_shortcut%TYPE;
        l_short_result   sys_shortcut.id_sys_shortcut%TYPE;
    
        l_dt_str_1 VARCHAR2(200 CHAR);
        l_dt_str_2 VARCHAR2(200 CHAR);
    
        l_dt_1 VARCHAR2(200 CHAR);
        l_dt_2 VARCHAR2(200 CHAR);
    
        l_workflow                sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_WORKFLOW', i_prof);
        l_ref                     sys_config.value%TYPE := pk_sysconfig.get_config('REFERRAL_AVAILABILITY', i_prof);
        l_status_in_patient_grids sys_config.value%TYPE := pk_sysconfig.get_config('LAB_TESTS_STATUS_IN_PATIENT_GRIDS',
                                                                                   i_prof);
    
        l_status table_varchar := table_varchar();
    
        l_error_out t_error_out;
    
        l_tbl_order_recurrence table_number;
        l_count                PLS_INTEGER;
    
    BEGIN
    
        g_error := 'GET EXAMS ROWIDS';
        get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'ORDER_RECURR_CONTROL',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process update event
        IF i_event_type IN (t_data_gov_mnt.g_event_update)
        THEN
            -- Loop through changed records
            g_error := 'LOOP UPDATED';
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
                SELECT DISTINCT ard.id_order_recurrence
                  BULK COLLECT
                  INTO l_tbl_order_recurrence
                  FROM analysis_req ar
                  JOIN analysis_req_det ard
                    ON ard.id_analysis_req = ar.id_analysis_req
                 WHERE ar.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                     *
                                      FROM TABLE(l_rowids) t)
                   AND ar.flg_status IN (pk_lab_tests_constant.g_analysis_result,
                                         pk_lab_tests_constant.g_analysis_read,
                                         pk_lab_tests_constant.g_analysis_cancel);
            
                FOR i IN l_tbl_order_recurrence.first .. l_tbl_order_recurrence.last
                LOOP
                    SELECT COUNT(1)
                      INTO l_count
                      FROM analysis_req ar
                      JOIN analysis_req_det ard
                        ON ard.id_analysis_req = ar.id_analysis_req
                     WHERE ard.id_order_recurrence = l_tbl_order_recurrence(i)
                       AND ar.flg_status NOT IN (pk_lab_tests_constant.g_analysis_result,
                                                 pk_lab_tests_constant.g_analysis_read,
                                                 pk_lab_tests_constant.g_analysis_cancel);
                
                    IF l_count = 0
                    THEN
                        UPDATE order_recurr_control orc
                           SET orc.flg_status = pk_order_recurrence_core.g_flg_status_control_finished
                         WHERE orc.id_order_recurr_plan = l_tbl_order_recurrence(i);
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_order_recurr_control;

BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_analysis;
/
