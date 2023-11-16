/*-- Last Change Revision: $Rev: 2014249 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-05-13 15:49:50 +0100 (sex, 13 mai 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_logic_nurse_tea_req IS

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
    
        IF i_table_name = 'NURSE_TEA_REQ'
        THEN
            SELECT /*+rule*/
             ntd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM nurse_tea_det ntd
             WHERE ntd.id_nurse_tea_req IN (SELECT ntr.id_nurse_tea_req
                                              FROM nurse_tea_req ntr
                                             WHERE ntr.rowid IN (SELECT column_value
                                                                   FROM TABLE(i_rowids)));
        
        ELSIF i_table_name = 'NURSE_TEA_DET'
        THEN
            o_rowids := i_rowids;
        
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

    PROCEDURE get_nurse_tea_req_status
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE,
        o_status_str    OUT nurse_tea_req.status_str%TYPE,
        o_status_msg    OUT nurse_tea_req.status_msg%TYPE,
        o_status_icon   OUT nurse_tea_req.status_icon%TYPE,
        o_status_flg    OUT nurse_tea_req.status_flg%TYPE
    ) IS
    
        l_display_type VARCHAR2(30);
        l_back_color   VARCHAR2(30);
        l_icon_color   VARCHAR2(30);
    
        -- text || date || icon
        l_aux VARCHAR2(200);
    
    BEGIN
    
        SELECT
        -- DESC_STATUS
         decode(i_flg_status,
                pk_patient_education_constant.g_nurse_tea_req_not_ord_reas,
                'NURSE_TEA_REQ.FLG_STATUS',
                pk_patient_education_cpoe.g_nurse_tea_req_draft,
                'NURSE_TEA_REQ.FLG_STATUS',
                pk_patient_education_constant.g_nurse_tea_req_fin,
                'NURSE_TEA_REQ.FLG_STATUS',
                pk_patient_education_constant.g_nurse_tea_req_canc,
                'NURSE_TEA_REQ.FLG_STATUS',
                pk_patient_education_constant.g_nurse_tea_req_expired,
                'NURSE_TEA_REQ.FLG_STATUS',
                pk_patient_education_constant.g_nurse_tea_req_sug,
                'NURSE_TEA_REQ.FLG_STATUS',
                pk_patient_education_constant.g_nurse_tea_req_ign,
                'NURSE_TEA_REQ.FLG_STATUS',
                pk_patient_education_constant.g_nurse_tea_req_descontinued,
                'NURSE_TEA_REQ.FLG_STATUS',
                pk_patient_education_constant.g_nurse_tea_req_act,
                decode(i_flg_time,
                       'N',
                       pk_patient_education_constant.g_sys_domain_req_status_flg,
                       pk_date_utils.to_char_insttimezone(i_prof,
                                                          i_dt_begin_tstz,
                                                          pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)),
                pk_patient_education_constant.g_nurse_tea_req_pend,
                decode(i_flg_time,
                       'N',
                       pk_patient_education_constant.g_sys_domain_req_status_flg,
                       pk_date_utils.to_char_insttimezone(i_prof,
                                                          i_dt_begin_tstz,
                                                          pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)),
                pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin_tstz, pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)) desc_status,
         
         -- FLG_TEXT
         decode(i_flg_status,
                pk_patient_education_constant.g_nurse_tea_req_not_ord_reas,
                pk_alert_constant.g_display_type_icon,
                pk_patient_education_cpoe.g_nurse_tea_req_draft,
                pk_alert_constant.g_display_type_icon,
                pk_patient_education_constant.g_nurse_tea_req_fin,
                pk_alert_constant.g_display_type_icon,
                pk_patient_education_constant.g_nurse_tea_req_canc,
                pk_alert_constant.g_display_type_icon,
                pk_patient_education_constant.g_nurse_tea_req_canc,
                pk_alert_constant.g_display_type_icon,
                pk_patient_education_constant.g_nurse_tea_req_descontinued,
                pk_alert_constant.g_display_type_icon,
                pk_patient_education_constant.g_nurse_tea_req_sug,
                pk_alert_constant.g_display_type_icon,
                pk_patient_education_constant.g_nurse_tea_req_expired,
                pk_alert_constant.g_display_type_icon,
                pk_patient_education_constant.g_nurse_tea_req_ign,
                pk_alert_constant.g_display_type_icon,
                pk_patient_education_constant.g_nurse_tea_req_act,
                decode(i_flg_time, 'N', pk_alert_constant.g_display_type_icon, pk_alert_constant.g_display_type_date),
                pk_patient_education_constant.g_nurse_tea_req_pend,
                decode(i_flg_time, 'N', pk_alert_constant.g_display_type_icon, pk_alert_constant.g_display_type_date),
                pk_alert_constant.g_display_type_date) flg_text,
         
         -- COLOR_STATUS
         decode(i_flg_status,
                pk_patient_education_constant.g_nurse_tea_req_not_ord_reas,
                NULL,
                pk_patient_education_constant.g_nurse_tea_req_draft,
                NULL,
                pk_patient_education_constant.g_nurse_tea_req_fin,
                NULL,
                pk_patient_education_constant.g_nurse_tea_req_canc,
                NULL,
                pk_patient_education_constant.g_nurse_tea_req_descontinued,
                NULL,
                pk_patient_education_constant.g_nurse_tea_req_expired,
                NULL,
                pk_patient_education_constant.g_nurse_tea_req_sug,
                pk_alert_constant.g_color_red,
                pk_patient_education_constant.g_nurse_tea_req_pend,
                decode(i_flg_time, 'N', pk_alert_constant.g_color_green, NULL),
                NULL) color_status
        
          INTO l_aux, l_display_type, l_back_color
          FROM dual;
    
        IF l_display_type IN (pk_alert_constant.g_display_type_icon, pk_alert_constant.g_display_type_date_icon)
        THEN
            IF l_back_color IN (pk_alert_constant.g_color_red, pk_alert_constant.g_color_green)
            THEN
                l_icon_color := pk_alert_constant.g_color_icon_light_grey;
            END IF;
        ELSE
            l_icon_color := NULL;
        END IF;
    
        pk_utils.build_status_string(i_display_type => l_display_type,
                                     i_flg_state    => i_flg_status,
                                     i_value_text   => l_aux,
                                     i_value_date   => l_aux,
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
    END get_nurse_tea_req_status;

    FUNCTION get_nurse_tea_req_status_str
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_logic_nurse_tea_req.get_nurse_tea_req_status(i_prof          => i_prof,
                                                        i_flg_time      => i_flg_time,
                                                        i_flg_status    => i_flg_status,
                                                        i_dt_begin_tstz => i_dt_begin_tstz,
                                                        o_status_str    => l_status_str,
                                                        o_status_msg    => l_status_msg,
                                                        o_status_icon   => l_status_icon,
                                                        o_status_flg    => l_status_flg);
    
        RETURN l_status_str;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_nurse_tea_req_status_str;

    FUNCTION get_nurse_tea_req_status_msg
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_logic_nurse_tea_req.get_nurse_tea_req_status(i_prof          => i_prof,
                                                        i_flg_time      => i_flg_time,
                                                        i_flg_status    => i_flg_status,
                                                        i_dt_begin_tstz => i_dt_begin_tstz,
                                                        o_status_str    => l_status_str,
                                                        o_status_msg    => l_status_msg,
                                                        o_status_icon   => l_status_icon,
                                                        o_status_flg    => l_status_flg);
    
        RETURN l_status_msg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_nurse_tea_req_status_msg;

    FUNCTION get_nurse_tea_req_status_icon
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_logic_nurse_tea_req.get_nurse_tea_req_status(i_prof          => i_prof,
                                                        i_flg_time      => i_flg_time,
                                                        i_flg_status    => i_flg_status,
                                                        i_dt_begin_tstz => i_dt_begin_tstz,
                                                        o_status_str    => l_status_str,
                                                        o_status_msg    => l_status_msg,
                                                        o_status_icon   => l_status_icon,
                                                        o_status_flg    => l_status_flg);
    
        RETURN l_status_icon;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_nurse_tea_req_status_icon;

    FUNCTION get_nurse_tea_req_status_flg
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_logic_nurse_tea_req.get_nurse_tea_req_status(i_prof          => i_prof,
                                                        i_flg_time      => i_flg_time,
                                                        i_flg_status    => i_flg_status,
                                                        i_dt_begin_tstz => i_dt_begin_tstz,
                                                        o_status_str    => l_status_str,
                                                        o_status_msg    => l_status_msg,
                                                        o_status_icon   => l_status_icon,
                                                        o_status_flg    => l_status_flg);
    
        RETURN l_status_flg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_nurse_tea_req_status_flg;

    PROCEDURE set_nurse_tea_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_func_proc_name VARCHAR2(30);
        o_rowids         table_varchar;
    
        o_status_str  nurse_tea_req.status_str%TYPE;
        o_status_msg  nurse_tea_req.status_msg%TYPE;
        o_status_icon nurse_tea_req.status_icon%TYPE;
        o_status_flg  nurse_tea_req.status_flg%TYPE;
    
    BEGIN
    
        l_func_proc_name := 'SET_NURSE_TEA_REQ';
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'NURSE_TEA_REQ',
                                                 i_expected_dg_table_name => 'NURSE_TEA_REQ',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF ((i_event_type = t_data_gov_mnt.g_event_insert) OR (i_event_type = t_data_gov_mnt.g_event_update))
        THEN
            -- insert/update
            g_error := 'GET INSER/UPDATE';
            pk_alertlog.log_debug('Processing INSERT/UPDATE on SET_NURSE_TEA_REQ', g_package_name, l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP INSERT/UPDATE';
        
            IF (i_rowids.count > 0)
            THEN
            
                FOR r_nurse_tea_req IN (SELECT *
                                          FROM nurse_tea_req ntr
                                         WHERE ntr.rowid IN (SELECT *
                                                               FROM TABLE(i_rowids)))
                LOOP
                
                    g_error := 'GET nurse_tea_req STATUS';
                    get_nurse_tea_req_status(i_prof,
                                             r_nurse_tea_req.flg_time,
                                             r_nurse_tea_req.flg_status,
                                             r_nurse_tea_req.dt_begin_tstz,
                                             o_status_str,
                                             o_status_msg,
                                             o_status_icon,
                                             o_status_flg);
                
                    g_error := 'TS_NURSE_TEA_REQ.UPD';
                    pk_alertlog.log_debug('Processing update on NURSE_TEA_REQ: ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    ts_nurse_tea_req.upd(id_nurse_tea_req_in => r_nurse_tea_req.id_nurse_tea_req,
                                         status_str_in       => o_status_str,
                                         status_msg_in       => o_status_msg,
                                         status_icon_in      => o_status_icon,
                                         status_flg_in       => o_status_flg,
                                         rows_out            => o_rowids);
                
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_nurse_tea_req;

    PROCEDURE set_nurse_tea_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_func_proc_name VARCHAR2(30);
        o_rowids         table_varchar;
    
        o_status_str  nurse_tea_req.status_str%TYPE;
        o_status_msg  nurse_tea_req.status_msg%TYPE;
        o_status_icon nurse_tea_req.status_icon%TYPE;
        o_status_flg  nurse_tea_req.status_flg%TYPE;
    
        l_flg_time         nurse_tea_req.flg_time%TYPE;
        l_flg_status       nurse_tea_req.flg_status%TYPE;
        l_id_nurse_tea_req nurse_tea_req.id_nurse_tea_req%TYPE;
    
        l_id_episode    episode.id_episode%TYPE;
        l_status_string nurse_tea_req.status_str%TYPE;
        l_shortcut      sys_shortcut.id_sys_shortcut%TYPE;
        l_dt_str_1      VARCHAR2(200 CHAR);
        l_dt_str_2      VARCHAR2(200 CHAR);
        l_dt_1          VARCHAR2(200 CHAR);
        l_dt_2          VARCHAR2(200 CHAR);
        l_error         t_error_out;
    
        l_dt_start      nurse_tea_det.dt_start%TYPE;
        l_num_order     nurse_tea_det.num_order%TYPE;
        l_num_order_max nurse_tea_det.num_order%TYPE;
    
    BEGIN
    
        l_func_proc_name := 'SET_NURSE_TEA_REQ';
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'NURSE_TEA_DET',
                                                 i_expected_dg_table_name => 'NURSE_TEA_DET',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF ( /*(i_event_type = t_data_gov_mnt.g_event_insert) OR*/
            (i_event_type = t_data_gov_mnt.g_event_update))
        THEN
            -- insert/update
            g_error := 'GET INSER/UPDATE';
            pk_alertlog.log_debug('Processing INSERT/UPDATE on SET_NURSE_TEA_REQ', g_package_name, l_func_proc_name);
        
            -- Loop through changed records
            g_error := 'LOOP INSERT/UPDATE';
        
            IF (i_rowids.count > 0)
            THEN
            
                FOR r_nurse_tea_det IN (SELECT *
                                          FROM nurse_tea_det ntd
                                         WHERE ntd.rowid IN (SELECT *
                                                               FROM TABLE(i_rowids)))
                LOOP
                
                    g_error := 'num_order=' || r_nurse_tea_det.num_order || ' id_nurse_tea_req=' ||
                               r_nurse_tea_det.id_nurse_tea_req || ' id_nurse_tea_det=' ||
                               r_nurse_tea_det.id_nurse_tea_det;
                
                    l_id_nurse_tea_req := r_nurse_tea_det.id_nurse_tea_req;
                
                    SELECT flg_time, flg_status
                      INTO l_flg_time, l_flg_status
                      FROM nurse_tea_req ntr
                     WHERE ntr.id_nurse_tea_req = r_nurse_tea_det.id_nurse_tea_req;
                
                    l_num_order := r_nurse_tea_det.num_order;
                
                    SELECT MAX(ntd.num_order)
                      INTO l_num_order_max
                      FROM nurse_tea_det ntd
                     WHERE ntd.id_nurse_tea_req = r_nurse_tea_det.id_nurse_tea_req;
                
                    l_num_order := l_num_order + 1;
                
                    IF l_num_order_max >= l_num_order
                    THEN
                    
                        g_error := 'num_order=' || l_num_order || ' id_nurse_tea_req=' || l_id_nurse_tea_req ||
                                   ' l_num_order_max=' || l_num_order_max;
                        BEGIN
                            SELECT ntd.dt_start
                              INTO l_dt_start
                              FROM nurse_tea_det ntd
                             WHERE ntd.num_order = l_num_order
                               AND ntd.id_nurse_tea_req = l_id_nurse_tea_req
                               AND rownum = 1;
                        
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_dt_start := NULL;
                        END;
                    
                        g_error := 'GET nurse_tea_det STATUS';
                        get_nurse_tea_req_status(i_prof,
                                                 l_flg_time,
                                                 l_flg_status,
                                                 l_dt_start,
                                                 o_status_str,
                                                 o_status_msg,
                                                 o_status_icon,
                                                 o_status_flg);
                    
                        g_error := 'TS_NURSE_TEA_DET.UPD';
                        pk_alertlog.log_debug('Processing update on NURSE_TEA_REQ: ' || g_error,
                                              g_package_name,
                                              l_func_proc_name);
                    
                        ts_nurse_tea_req.upd(id_nurse_tea_req_in => l_id_nurse_tea_req,
                                             status_str_in       => o_status_str,
                                             status_msg_in       => o_status_msg,
                                             status_icon_in      => o_status_icon,
                                             status_flg_in       => o_status_flg,
                                             rows_out            => o_rowids);
                    
                        BEGIN
                            SELECT ntr.id_episode
                              INTO l_id_episode
                              FROM nurse_tea_req ntr
                             WHERE ntr.id_nurse_tea_req = l_id_nurse_tea_req;
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_id_episode := NULL;
                        END;
                    
                        IF l_id_episode IS NOT NULL
                        THEN
                        
                            IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_intern_name => 'GRID_PAT_EDUCATION',
                                                             o_id_shortcut => l_shortcut,
                                                             o_error       => l_error)
                            THEN
                                l_shortcut := 0;
                            END IF;
                        
                            l_status_string := pk_utils.get_status_string(i_lang,
                                                                          i_prof,
                                                                          o_status_str,
                                                                          o_status_msg,
                                                                          o_status_icon,
                                                                          o_status_flg);
                        
                            IF regexp_like(l_status_string, '^\|D')
                            THEN
                                l_dt_str_1 := regexp_replace(l_status_string,
                                                             '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*',
                                                             '\1');
                                l_dt_str_2 := regexp_replace(l_status_string,
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
                                    l_status_string := regexp_replace(l_status_string, l_dt_str_1, l_dt_1);
                                ELSE
                                    l_status_string := regexp_replace(l_status_string, l_dt_str_1, l_dt_1);
                                    l_status_string := regexp_replace(l_status_string, l_dt_str_2, l_dt_2);
                                END IF;
                            ELSE
                                l_dt_str_2      := regexp_replace(l_status_string, '^\|\w{0,2}\|.*\|(\d{14})\|.*', '\1');
                                l_dt_2          := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                      pk_date_utils.get_string_tstz(i_lang,
                                                                                                                    i_prof,
                                                                                                                    l_dt_str_2,
                                                                                                                    NULL),
                                                                                      'YYYYMMDDHH24MISS TZR');
                                l_status_string := regexp_replace(l_status_string, l_dt_str_2, l_dt_2);
                            END IF;
                        
                            l_status_string := l_shortcut || l_status_string;
                        
                            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                            IF NOT pk_grid.update_grid_task(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_episode     => l_id_episode,
                                                            teach_req_in  => l_status_string,
                                                            teach_req_nin => FALSE,
                                                            o_error       => l_error)
                            THEN
                                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                            END IF;
                        END IF;
                    
                    END IF;
                END LOOP;
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_nurse_tea_det;

    PROCEDURE set_grid_task_pat_education
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
    
        l_rowids table_varchar;
    
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    
        l_dt_str_1 VARCHAR2(200 CHAR);
        l_dt_str_2 VARCHAR2(200 CHAR);
    
        l_dt_1 VARCHAR2(200 CHAR);
        l_dt_2 VARCHAR2(200 CHAR);
    
        l_epis_type    epis_type.id_epis_type%TYPE;
        l_i_id_hhc_req epis_hhc_req.id_epis_hhc_req%TYPE;
        l_id_episode   table_number;
    
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
           AND i_source_table_name = 'NURSE_TEA_REQ'
           OR i_event_type = t_data_gov_mnt.g_event_insert
        THEN
            -- Loop through changed records
            g_error := 'LOOP UPDATED';
            IF i_rowids IS NOT NULL
               AND i_rowids.count > 0
            THEN
                FOR r_cur IN (SELECT *
                                FROM (SELECT ntr.id_episode, ntr.id_patient
                                        FROM (SELECT /*+opt_estimate (table ntd rows=1)*/
                                               *
                                                FROM nurse_tea_det ntd
                                               WHERE ntd.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                    *
                                                                     FROM TABLE(l_rowids) t)) ntd,
                                             nurse_tea_req ntr
                                       WHERE ntd.id_nurse_tea_req = ntr.id_nurse_tea_req
                                         AND ntr.flg_status NOT IN (pk_patient_education_constant.g_nurse_tea_req_draft)))
                LOOP
                
                    l_i_id_hhc_req := pk_hhc_core.get_id_req_by_epis_hhc(i_lang       => i_lang,
                                                                         i_id_episode => r_cur.id_episode);
                
                    IF l_i_id_hhc_req IS NULL
                    THEN
                        SELECT id_episode
                          BULK COLLECT
                          INTO l_id_episode
                          FROM episode
                         WHERE id_visit = pk_episode.get_id_visit(r_cur.id_episode);
                    ELSE
                    
                        SELECT t.id_episode
                          BULK COLLECT
                          INTO l_id_episode
                          FROM (SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_visit = pk_episode.get_id_visit(r_cur.id_episode)
                                UNION
                                SELECT e.id_episode
                                  FROM episode e
                                 WHERE e.id_prev_episode IN
                                       (SELECT ehr.id_epis_hhc
                                          FROM alert.epis_hhc_req ehr
                                         WHERE ehr.id_episode = r_cur.id_episode
                                            OR ehr.id_epis_hhc_req = l_i_id_hhc_req)
                                UNION
                                SELECT ehr.id_epis_hhc
                                  FROM alert.epis_hhc_req ehr
                                 WHERE ehr.id_episode = r_cur.id_episode
                                    OR ehr.id_epis_hhc_req = l_i_id_hhc_req) t;
                    END IF;
                
                    SELECT MAX(status_string) status_string
                      INTO l_grid_task.teach_req
                      FROM (SELECT decode(rank,
                                          1,
                                          pk_utils.get_status_string(i_lang,
                                                                     i_prof,
                                                                     pk_logic_nurse_tea_req.get_nurse_tea_req_status_str(i_prof,
                                                                                                                         flg_time,
                                                                                                                         flg_status,
                                                                                                                         dt_begin_tstz),
                                                                     pk_logic_nurse_tea_req.get_nurse_tea_req_status_msg(i_prof,
                                                                                                                         flg_time,
                                                                                                                         flg_status,
                                                                                                                         dt_begin_tstz),
                                                                     pk_logic_nurse_tea_req.get_nurse_tea_req_status_icon(i_prof,
                                                                                                                          flg_time,
                                                                                                                          flg_status,
                                                                                                                          dt_begin_tstz),
                                                                     pk_logic_nurse_tea_req.get_nurse_tea_req_status_flg(i_prof,
                                                                                                                         flg_time,
                                                                                                                         flg_status,
                                                                                                                         dt_begin_tstz)),
                                          NULL) status_string
                              FROM (SELECT t.id_nurse_tea_req,
                                           t.id_episode,
                                           t.flg_time,
                                           t.flg_status,
                                           t.dt_req_tstz,
                                           t.dt_begin_tstz,
                                           row_number() over(ORDER BY t.rank) rank
                                      FROM (SELECT t.*,
                                                   decode(t.flg_status,
                                                          pk_patient_education_constant.g_nurse_tea_req_pend,
                                                          row_number() over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                                     'NURSE_TEA_REQ.FLG_STATUS',
                                                                                     t.flg_status),
                                                               coalesce(t.dt_begin_tstz, t.dt_req_tstz)),
                                                          row_number()
                                                          over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                                     'NURSE_TEA_REQ.FLG_STATUS',
                                                                                     t.flg_status),
                                                               coalesce(t.dt_begin_tstz, t.dt_req_tstz) DESC) + 20000) rank
                                              FROM (SELECT ntr.id_nurse_tea_req,
                                                           ntr.id_episode,
                                                           ntr.flg_time,
                                                           ntr.flg_status,
                                                           ntr.dt_nurse_tea_req_tstz dt_req_tstz,
                                                           ntr.dt_begin_tstz
                                                      FROM nurse_tea_req ntr
                                                     WHERE ntr.id_episode IN
                                                           (SELECT *
                                                              FROM (TABLE(l_id_episode) x))
                                                       AND ntr.flg_status IN
                                                           (pk_patient_education_constant.g_nurse_tea_req_pend,
                                                            pk_patient_education_constant.g_nurse_tea_req_act)) t) t)
                             WHERE rank = 1) t;
                
                    IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_intern_name => 'GRID_PAT_EDUCATION',
                                                     o_id_shortcut => l_shortcut,
                                                     o_error       => l_error_out)
                    THEN
                        l_shortcut := 0;
                    END IF;
                
                    g_error := 'GET SHORTCUT - DOCTOR';
                    IF l_grid_task.teach_req IS NOT NULL
                    THEN
                        IF regexp_like(l_grid_task.teach_req, '^\|D')
                        THEN
                            l_dt_str_1 := regexp_replace(l_grid_task.teach_req,
                                                         '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*',
                                                         '\1');
                            l_dt_str_2 := regexp_replace(l_grid_task.teach_req,
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
                                l_grid_task.teach_req := regexp_replace(l_grid_task.teach_req, l_dt_str_1, l_dt_1);
                            ELSE
                                l_grid_task.teach_req := regexp_replace(l_grid_task.teach_req, l_dt_str_1, l_dt_1);
                                l_grid_task.teach_req := regexp_replace(l_grid_task.teach_req, l_dt_str_2, l_dt_2);
                            END IF;
                        ELSE
                            l_dt_str_2            := regexp_replace(l_grid_task.teach_req,
                                                                    '^\|\w{0,2}\|.*\|(\d{14})\|.*',
                                                                    '\1');
                            l_dt_2                := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                        pk_date_utils.get_string_tstz(i_lang,
                                                                                                                      i_prof,
                                                                                                                      l_dt_str_2,
                                                                                                                      NULL),
                                                                                        'YYYYMMDDHH24MISS TZR');
                            l_grid_task.teach_req := regexp_replace(l_grid_task.teach_req, l_dt_str_2, l_dt_2);
                        END IF;
                    
                        l_grid_task.teach_req := l_shortcut || l_grid_task.teach_req;
                    END IF;
                
                    l_grid_task.id_episode := r_cur.id_episode;
                
                    IF l_grid_task.id_episode IS NOT NULL
                    THEN
                        g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                        IF NOT pk_grid.update_grid_task(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_episode     => l_grid_task.id_episode,
                                                        teach_req_in  => l_grid_task.teach_req,
                                                        teach_req_nin => FALSE,
                                                        o_error       => l_error_out)
                        THEN
                            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                        END IF;
                    
                        IF l_grid_task.teach_req IS NULL
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
                            IF NOT pk_grid.update_grid_task(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_episode     => l_grid_task.id_episode,
                                                            teach_req_in  => l_grid_task.teach_req,
                                                            teach_req_nin => FALSE,
                                                            o_error       => l_error_out)
                            THEN
                                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                            END IF;
                        
                            IF l_grid_task.teach_req IS NULL
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
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_pat_education;

BEGIN

    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_logic_nurse_tea_req;
/
