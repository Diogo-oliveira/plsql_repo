/*-- Last Change Revision: $Rev: 2027036 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_monitorizations IS

    FUNCTION get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_table_ea   IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message VARCHAR2(4000);
    BEGIN
    
        IF i_table_name = 'MONITORIZATION'
        THEN
            SELECT /*+rule*/
             mvs.rowid
              BULK COLLECT
              INTO o_rowids
              FROM monitorization_vs mvs
             WHERE (mvs.flg_status != pk_alert_constant.g_monitor_vs_draft OR i_table_ea = 'TASK_TIMELINE_EA')
               AND mvs.id_monitorization IN
                   (SELECT m.id_monitorization
                      FROM monitorization m
                      JOIN TABLE(i_rowids) t
                        ON (t.column_value = m.rowid)
                     WHERE (m.flg_status != pk_alert_constant.g_monitor_vs_draft OR i_table_ea = 'TASK_TIMELINE_EA'));
            RETURN TRUE;
        
        ELSIF i_table_name = 'MONITORIZATION_VS'
        THEN
            o_rowids := i_rowids;
            RETURN TRUE;
        
        ELSIF i_table_name = 'MONITORIZATION_VS_PLAN'
        THEN
            SELECT /*+rule*/
             mvs.rowid
              BULK COLLECT
              INTO o_rowids
              FROM monitorization_vs mvs
             WHERE (mvs.flg_status != pk_alert_constant.g_monitor_vs_draft OR i_table_ea = 'TASK_TIMELINE_EA')
               AND mvs.id_monitorization_vs IN
                   (SELECT mvsp.id_monitorization_vs
                      FROM monitorization_vs_plan mvsp
                     WHERE mvsp.rowid IN (SELECT column_value
                                            FROM TABLE(i_rowids)));
        
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_rowids := table_varchar();
        
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DATA_ROWID',
                                                     o_error);
        
            pk_alert_exceptions.reset_error_state;
        
    END get_data_rowid;

    FUNCTION get_data_rowid_pat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_table_ea   IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error   t_error_out;
        l_message VARCHAR2(4000);
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT get_data_rowid(i_lang       => i_lang,
                              i_prof       => i_prof,
                              i_table_name => i_table_name,
                              i_table_ea   => i_table_ea,
                              i_rowids     => i_rowids,
                              o_rowids     => o_rowids,
                              o_error      => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message || ' / ' || l_error.err_desc,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DATA_ROWID_PAT',
                                                     o_error);
        
            pk_alert_exceptions.reset_error_state;
        
        WHEN OTHERS THEN
            o_rowids := table_varchar();
        
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DATA_ROWID_PAT',
                                                     o_error);
        
            pk_alert_exceptions.reset_error_state;
    END get_data_rowid_pat;

    PROCEDURE get_monitorizations_status
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE,
        o_status_str      OUT monitorizations_ea.status_str%TYPE,
        o_status_msg      OUT monitorizations_ea.status_msg%TYPE,
        o_status_icon     OUT monitorizations_ea.status_icon%TYPE,
        o_status_flg      OUT monitorizations_ea.status_flg%TYPE
    ) IS
    
        l_display_type VARCHAR2(30);
        l_back_color   VARCHAR2(30);
        l_status_flg   VARCHAR2(30);
    
        l_aux VARCHAR2(200);
    BEGIN
    
        SELECT decode(i_episode_origin,
                      NULL,
                      decode(i_flg_status_det,
                             pk_alert_constant.g_monitor_vs_fini,
                             'MONITORIZATION.FLG_STATUS', -- I
                             pk_alert_constant.g_monitor_vs_inte,
                             'MONITORIZATION.FLG_STATUS', -- I
                             pk_alert_constant.g_monitor_vs_canc,
                             decode(i_flg_status_plan,
                                    pk_alert_constant.g_monitor_vs_exec,
                                    'MONITORIZATION.FLG_STATUS', -- I
                                    'MONITORIZATION.FLG_STATUS'), -- I
                             pk_alert_constant.g_monitor_vs_expire,
                             decode(i_flg_status_plan,
                                    pk_alert_constant.g_monitor_vs_expire,
                                    'MONITORIZATION.FLG_STATUS', -- E
                                    'MONITORIZATION.FLG_STATUS'), -- E
                             decode(i_flg_time,
                                    pk_alert_constant.g_flg_time_n,
                                    'ICON_T056', -- T
                                    pk_date_utils.to_char_insttimezone(i_prof,
                                                                       nvl(i_dt_plan, i_dt_begin),
                                                                       pk_alert_constant.g_dt_yyyymmddhh24miss_tzr))),
                      decode(i_flg_status_det,
                             pk_alert_constant.g_monitor_vs_fini,
                             'MONITORIZATION.FLG_STATUS', -- I
                             pk_alert_constant.g_monitor_vs_canc,
                             'MONITORIZATION.FLG_STATUS', -- I
                             pk_alert_constant.g_monitor_vs_expire,
                             'MONITORIZATION.FLG_STATUS', -- E
                             pk_alert_constant.g_monitor_vs_exec,
                             pk_date_utils.to_char_insttimezone(i_prof,
                                                                nvl(i_dt_plan, i_dt_begin),
                                                                pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                             decode(i_flg_time,
                                    pk_alert_constant.g_flg_time_n,
                                    'ICON_T056', -- T
                                    decode(i_flg_status_plan,
                                           pk_alert_constant.g_monitor_vs_exec,
                                           pk_date_utils.to_char_insttimezone(i_prof,
                                                                              nvl(i_dt_plan, i_dt_begin),
                                                                              pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                           'ICON_T056')))) desc_status, -- T
               decode(i_episode_origin,
                      NULL,
                      decode(i_flg_status_det,
                             pk_alert_constant.g_monitor_vs_inte,
                             pk_alert_constant.g_display_type_icon,
                             pk_alert_constant.g_monitor_vs_fini,
                             pk_alert_constant.g_display_type_icon,
                             pk_alert_constant.g_monitor_vs_canc,
                             pk_alert_constant.g_display_type_icon,
                             pk_alert_constant.g_monitor_vs_expire,
                             pk_alert_constant.g_display_type_icon,
                             decode(i_flg_time,
                                    pk_alert_constant.g_flg_time_n,
                                    pk_alert_constant.g_display_type_text,
                                    pk_alert_constant.g_display_type_date)), -- ID
                      decode(i_flg_status_det,
                             pk_alert_constant.g_monitor_vs_inte,
                             pk_alert_constant.g_display_type_icon,
                             pk_alert_constant.g_monitor_vs_fini,
                             pk_alert_constant.g_display_type_icon,
                             pk_alert_constant.g_monitor_vs_canc,
                             pk_alert_constant.g_display_type_icon,
                             pk_alert_constant.g_monitor_vs_expire,
                             pk_alert_constant.g_display_type_icon,
                             pk_alert_constant.g_monitor_vs_exec,
                             pk_alert_constant.g_display_type_date, -- ID
                             decode(i_flg_time,
                                    pk_alert_constant.g_flg_time_n,
                                    pk_alert_constant.g_display_type_text,
                                    decode(i_flg_status_plan,
                                           pk_alert_constant.g_monitor_vs_exec,
                                           pk_alert_constant.g_display_type_date, -- ID
                                           pk_alert_constant.g_display_type_text)))) flg_text,
               decode(i_episode_origin,
                      NULL,
                      decode(i_flg_status_det,
                             pk_alert_constant.g_monitor_vs_fini,
                             pk_alert_constant.g_color_null,
                             pk_alert_constant.g_monitor_vs_canc,
                             pk_alert_constant.g_color_null,
                             pk_alert_constant.g_monitor_vs_inte,
                             pk_alert_constant.g_color_null,
                             decode(i_flg_time,
                                    pk_alert_constant.g_flg_time_n,
                                    pk_alert_constant.g_color_green,
                                    pk_alert_constant.g_color_null)),
                      decode(i_flg_status_det,
                             pk_alert_constant.g_monitor_vs_fini,
                             pk_alert_constant.g_color_null,
                             pk_alert_constant.g_monitor_vs_canc,
                             pk_alert_constant.g_color_null,
                             pk_alert_constant.g_monitor_vs_exec,
                             pk_alert_constant.g_color_null,
                             decode(i_flg_time,
                                    pk_alert_constant.g_flg_time_n,
                                    pk_alert_constant.g_color_green,
                                    decode(i_flg_status_plan,
                                           pk_alert_constant.g_monitor_vs_exec,
                                           pk_alert_constant.g_color_null,
                                           pk_alert_constant.g_color_red)))) color_status,
               decode(i_episode_origin,
                      NULL,
                      decode(i_flg_status_det,
                             pk_alert_constant.g_monitor_vs_fini,
                             pk_alert_constant.g_monitor_vs_fini,
                             pk_alert_constant.g_monitor_vs_inte,
                             pk_alert_constant.g_monitor_vs_inte,
                             pk_alert_constant.g_monitor_vs_expire,
                             pk_alert_constant.g_monitor_vs_expire,
                             pk_alert_constant.g_monitor_vs_canc,
                             decode(i_flg_status_plan,
                                    pk_alert_constant.g_monitor_vs_exec,
                                    pk_alert_constant.g_monitor_vs_inte,
                                    pk_alert_constant.g_monitor_vs_canc,
                                    pk_alert_constant.g_monitor_vs_canc)),
                      decode(i_flg_status_det,
                             pk_alert_constant.g_monitor_vs_fini,
                             pk_alert_constant.g_monitor_vs_fini,
                             pk_alert_constant.g_monitor_vs_canc,
                             pk_alert_constant.g_monitor_vs_canc,
                             pk_alert_constant.g_monitor_vs_expire,
                             pk_alert_constant.g_monitor_vs_expire)) flag_status
          INTO l_aux, l_display_type, l_back_color, l_status_flg
          FROM dual;
    
        pk_utils.build_status_string(i_display_type => l_display_type,
                                     i_flg_state    => l_status_flg,
                                     i_value_text   => l_aux,
                                     i_value_date   => l_aux,
                                     i_value_icon   => l_aux,
                                     i_back_color   => l_back_color,
                                     o_status_str   => o_status_str,
                                     o_status_msg   => o_status_msg,
                                     o_status_icon  => o_status_icon,
                                     o_status_flg   => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_alert_exceptions.reset_error_state;
    END get_monitorizations_status;

    FUNCTION get_monitorization_status_str
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_monitorizations.get_monitorizations_status(i_prof            => i_prof,
                                                               i_episode_origin  => i_episode_origin,
                                                               i_flg_time        => i_flg_time,
                                                               i_dt_begin        => i_dt_begin,
                                                               i_flg_status_det  => i_flg_status_det,
                                                               i_flg_status_plan => i_flg_status_plan,
                                                               i_dt_plan         => i_dt_plan,
                                                               o_status_str      => l_status_str,
                                                               o_status_msg      => l_status_msg,
                                                               o_status_icon     => l_status_icon,
                                                               o_status_flg      => l_status_flg);
    
        RETURN l_status_str;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_monitorization_status_str;

    FUNCTION get_monitorization_status_msg
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_monitorizations.get_monitorizations_status(i_prof            => i_prof,
                                                               i_episode_origin  => i_episode_origin,
                                                               i_flg_time        => i_flg_time,
                                                               i_dt_begin        => i_dt_begin,
                                                               i_flg_status_det  => i_flg_status_det,
                                                               i_flg_status_plan => i_flg_status_plan,
                                                               i_dt_plan         => i_dt_plan,
                                                               o_status_str      => l_status_str,
                                                               o_status_msg      => l_status_msg,
                                                               o_status_icon     => l_status_icon,
                                                               o_status_flg      => l_status_flg);
    
        RETURN l_status_msg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_monitorization_status_msg;

    FUNCTION get_monitorization_status_icon
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_monitorizations.get_monitorizations_status(i_prof            => i_prof,
                                                               i_episode_origin  => i_episode_origin,
                                                               i_flg_time        => i_flg_time,
                                                               i_dt_begin        => i_dt_begin,
                                                               i_flg_status_det  => i_flg_status_det,
                                                               i_flg_status_plan => i_flg_status_plan,
                                                               i_dt_plan         => i_dt_plan,
                                                               o_status_str      => l_status_str,
                                                               o_status_msg      => l_status_msg,
                                                               o_status_icon     => l_status_icon,
                                                               o_status_flg      => l_status_flg);
    
        RETURN l_status_icon;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_monitorization_status_icon;

    FUNCTION get_monitorization_status_flg
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(2);
    
    BEGIN
    
        pk_ea_logic_monitorizations.get_monitorizations_status(i_prof            => i_prof,
                                                               i_episode_origin  => i_episode_origin,
                                                               i_flg_time        => i_flg_time,
                                                               i_dt_begin        => i_dt_begin,
                                                               i_flg_status_det  => i_flg_status_det,
                                                               i_flg_status_plan => i_flg_status_plan,
                                                               i_dt_plan         => i_dt_plan,
                                                               o_status_str      => l_status_str,
                                                               o_status_msg      => l_status_msg,
                                                               o_status_icon     => l_status_icon,
                                                               o_status_flg      => l_status_flg);
    
        RETURN l_status_flg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_monitorization_status_flg;

    PROCEDURE set_monitorization
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_func_proc_name       VARCHAR2(30);
        l_error                t_error_out;
        l_new_rec              ts_monitorizations_ea.monitorizations_ea_tc;
        l_monitorization_vs_tc ts_monitorization_vs.monitorization_vs_tc;
        l_rowids               table_varchar;
        i                      NUMBER := 1;
        l_exception            EXCEPTION;
        l_message              VARCHAR2(4000);
    BEGIN
        l_func_proc_name := 'SET_MONITORIZATION';
    
        l_message := 'Get MONITORIZATION_VS RowIds';
        IF i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            -- Get MONITORIZATION_VS RowIds, for DELETE event
            IF NOT get_data_rowid_pat(i_lang,
                                      i_prof,
                                      i_source_table_name,
                                      'MONITORIZATIONS_EA',
                                      i_rowids,
                                      l_rowids,
                                      l_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            -- Get MONITORIZATION_VS RowIds, for INSERT and UPDATE
            IF NOT
                get_data_rowid(i_lang, i_prof, i_source_table_name, 'MONITORIZATIONS_EA', i_rowids, l_rowids, l_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        -- Validate arguments
        l_message := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => l_rowids,
                                                 i_source_table_name      => 'MONITORIZATION_VS',
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'MONITORIZATION_VS',
                                                 i_expected_dg_table_name => 'MONITORIZATIONS_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        IF l_rowids IS NOT NULL
           AND l_rowids.count > 0
        THEN
        
            -- Process Insert / Update event
            IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
            THEN
                l_message := 'Process Insert / Update event';
            
                SELECT m.id_monitorization,
                       mvs.id_monitorization_vs,
                       mvsp.id_monitorization_vs_plan,
                       mvs.id_vital_sign,
                       m.flg_status,
                       mvs.flg_status flg_status_det,
                       mvsp.flg_status flg_status_plan,
                       m.flg_time,
                       m.dt_monitorization_tstz,
                       mvsp.dt_plan_tstz,
                       m.interval,
                       m.id_episode_origin,
                       m.dt_begin_tstz,
                       m.dt_end_tstz,
                       (SELECT COUNT(1)
                          FROM monitorization_vs_plan mvsp2
                         WHERE mvsp2.id_monitorization_vs = mvs.id_monitorization_vs) num_monit,
                       v.id_visit,
                       NULL status_str,
                       NULL status_msg,
                       NULL status_icon,
                       NULL status_flg,
                       decode(coalesce(m.notes, m.notes_cancel, mvs.notes_cancel), NULL, 'N', 'Y') flg_notes,
                       m.id_episode,
                       m.id_prev_episode,
                       v.id_patient,
                       m.id_professional,
                       current_timestamp dt_dg_last_update,
                       NULL AS create_user,
                       NULL AS create_time,
                       NULL AS create_institution,
                       NULL AS update_user,
                       NULL AS update_time,
                       NULL AS update_institution,
                       mvs.dt_order
                  BULK COLLECT
                  INTO l_new_rec
                  FROM monitorization m,
                       (SELECT *
                          FROM monitorization_vs mvs
                         WHERE mvs.rowid IN (SELECT /*+opt_estimate(table t rows=1)*/
                                              *
                                               FROM TABLE(l_rowids) t)) mvs,
                       monitorization_vs_plan mvsp,
                       visit v,
                       episode e
                 WHERE m.flg_status != pk_alert_constant.g_monitor_vs_draft
                   AND mvs.flg_status != pk_alert_constant.g_monitor_vs_draft
                   AND mvs.id_monitorization = m.id_monitorization
                   AND mvsp.id_monitorization_vs = mvs.id_monitorization_vs
                   AND mvsp.id_monitorization_vs_plan =
                       (SELECT MAX(id_monitorization_vs_plan)
                          FROM monitorization_vs_plan mvp1
                         WHERE mvp1.id_monitorization_vs = mvs.id_monitorization_vs)
                   AND e.id_episode = m.id_episode
                   AND v.id_visit = e.id_visit;
            
                IF (l_new_rec.count > 0)
                THEN
                
                    l_message := 'Processing insert/update on TS_MONITORIZATION_EA';
                    pk_alertlog.log_debug(l_message, g_package_name, l_func_proc_name);
                    FOR i IN l_new_rec.first .. l_new_rec.last
                    LOOP
                    
                        get_monitorizations_status(i_prof            => i_prof,
                                                   i_episode_origin  => l_new_rec(i).id_episode_origin,
                                                   i_flg_time        => l_new_rec(i).flg_time,
                                                   i_dt_begin        => l_new_rec(i).dt_begin,
                                                   i_flg_status_det  => l_new_rec(i).flg_status_det,
                                                   i_flg_status_plan => l_new_rec(i).flg_status_plan,
                                                   i_dt_plan         => l_new_rec(i).dt_plan,
                                                   o_status_str      => l_new_rec(i).status_str,
                                                   o_status_msg      => l_new_rec(i).status_msg,
                                                   o_status_icon     => l_new_rec(i).status_icon,
                                                   o_status_flg      => l_new_rec(i).status_flg);
                    
                        ts_monitorizations_ea.upd_ins(id_monitorization_vs_in      => l_new_rec(i).id_monitorization_vs,
                                                      id_monitorization_in         => l_new_rec(i).id_monitorization,
                                                      id_monitorization_vs_plan_in => l_new_rec(i).id_monitorization_vs_plan,
                                                      id_vital_sign_in             => l_new_rec(i).id_vital_sign,
                                                      flg_status_in                => l_new_rec(i).flg_status,
                                                      flg_status_det_in            => l_new_rec(i).flg_status_det,
                                                      flg_status_plan_in           => l_new_rec(i).flg_status_plan,
                                                      flg_time_in                  => l_new_rec(i).flg_time,
                                                      dt_monitorization_in         => l_new_rec(i).dt_monitorization,
                                                      dt_plan_in                   => l_new_rec(i).dt_plan,
                                                      interval_in                  => l_new_rec(i).interval,
                                                      id_episode_origin_in         => l_new_rec(i).id_episode_origin,
                                                      dt_begin_in                  => l_new_rec(i).dt_begin,
                                                      dt_end_in                    => l_new_rec(i).dt_end,
                                                      num_monit_in                 => l_new_rec(i).num_monit,
                                                      id_visit_in                  => l_new_rec(i).id_visit,
                                                      status_str_in                => l_new_rec(i).status_str,
                                                      status_msg_in                => l_new_rec(i).status_msg,
                                                      status_icon_in               => l_new_rec(i).status_icon,
                                                      status_flg_in                => l_new_rec(i).status_flg,
                                                      flg_notes_in                 => l_new_rec(i).flg_notes,
                                                      id_episode_in                => l_new_rec(i).id_episode,
                                                      id_prev_episode_in           => l_new_rec(i).id_prev_episode,
                                                      id_patient_in                => l_new_rec(i).id_patient,
                                                      id_professional_in           => l_new_rec(i).id_professional,
                                                      dt_dg_last_update_in         => l_new_rec(i).dt_dg_last_update,
                                                      dt_order_in                  => l_new_rec(i).dt_order,
                                                      rows_out                     => l_rowids);
                    
                    END LOOP;
                END IF;
            
                -- Process Delete event
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_message              := 'Process Delete event';
                l_monitorization_vs_tc := ts_monitorization_vs.get_data_rowid_pat(rows_in => l_rowids);
                FOR reg IN l_monitorization_vs_tc.first .. l_monitorization_vs_tc.last
                LOOP
                    ts_monitorizations_ea.del(id_monitorization_vs_in => l_monitorization_vs_tc(reg).id_monitorization_vs);
                END LOOP;
            
            END IF;
        
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
        
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
        WHEN OTHERS THEN
            -- Unexpected error.
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
            pk_utils.undo_changes;
        
            pk_alert_exceptions.reset_error_state;
        
    END set_monitorization;

    PROCEDURE set_grid_task_monitorizations
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_rowids    table_varchar;
        l_error_out t_error_out;
    BEGIN
    
        g_error := 'GET EXAMS ROWIDS';
        IF NOT get_data_rowid(i_lang, i_prof, i_source_table_name, 'GRID_TASK', i_rowids, l_rowids, l_error_out)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
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
                ins_grid_task_monitorizations(i_lang => i_lang, i_prof => i_prof, i_rowids => l_rowids);
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_monitorizations;

    /*******************************************************************************************************************************************
    * Name:                           SET_TASK_TIMELINE_MONIT
    * Description:                    Function that updates monitorizations information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/21
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_monit
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
        l_func_proc_name   VARCHAR2(30) := 'SET_TASK_TIMELINE_MONIT';
        l_name_table_ea    VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name     VARCHAR2(30);
        l_rowids           table_varchar;
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
    
        l_exception               EXCEPTION;
        l_excp_invalid_event_type EXCEPTION;
        l_message                 VARCHAR2(4000);
    
        l_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
    
        -- Validate arguments
        l_message := 'VALIDATE ARGUMENTS';
        pk_alertlog.log_debug(l_message);
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
            l_message := 'LOOP PROCESS';
            pk_alertlog.log_debug(l_message);
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                l_message := 'GET MONITORIZATION_VS ROWIDS';
                pk_alertlog.log_debug(l_message);
                IF i_event_type = t_data_gov_mnt.g_event_delete
                THEN
                    -- Get MONITORIZATION_VS RowIds, for DELETE event
                    IF NOT get_data_rowid_pat(i_lang,
                                              i_prof,
                                              i_source_table_name,
                                              l_name_table_ea,
                                              i_rowids,
                                              l_rowids,
                                              l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                ELSE
                    -- Get MONITORIZATION_VS RowIds, for INSERT and UPDATE
                    IF NOT get_data_rowid(i_lang,
                                          i_prof,
                                          i_source_table_name,
                                          l_name_table_ea,
                                          i_rowids,
                                          l_rowids,
                                          l_error_out)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => l_rowids);
            
                FOR r_cur IN (SELECT mvs.id_monitorization_vs,
                                     mvs.flg_status flg_status_det,
                                     m.flg_time,
                                     m.dt_monitorization_tstz,
                                     m.id_episode_origin,
                                     mvsp.dt_plan_tstz dt_begin_tstz,
                                     m.dt_end_tstz dt_end,
                                     e.id_visit,
                                     m.id_episode,
                                     e.id_patient,
                                     mvsp.flg_status flg_status_plan,
                                     mvsp.dt_plan_tstz,
                                     m.id_professional,
                                     mvs.dt_order,
                                     mvs.dt_monitorization_vs_tstz,
                                     e.id_institution id_institution,
                                     vs.code_vital_sign,
                                     NULL universal_desc_clob,
                                     m.id_monitorization,
                                     CASE mvs.flg_status
                                         WHEN pk_alert_constant.g_monitor_vs_fini THEN
                                          pk_prog_notes_constants.g_task_finalized_f
                                         WHEN pk_alert_constant.g_monitor_vs_pend THEN
                                          pk_prog_notes_constants.g_task_pending_d
                                         ELSE
                                          pk_prog_notes_constants.g_task_ongoing_o
                                     END flg_ongoing,
                                     pk_alert_constant.g_yes flg_normal,
                                     e.flg_status flg_status_epis,
                                     coalesce((SELECT MAX(mvp_tstz.end_time)
                                                FROM monitorization_vs_plan mvp_tstz
                                               WHERE mvp_tstz.id_monitorization_vs = mvs.id_monitorization_vs
                                                 AND mvp_tstz.end_time IS NOT NULL),
                                              mvs.dt_monitorization_vs_tstz,
                                              m.dt_monitorization_tstz) dt_last_update
                                FROM monitorization         m,
                                     monitorization_vs      mvs,
                                     monitorization_vs_plan mvsp,
                                     visit                  v,
                                     episode                e,
                                     vital_sign             vs
                              
                               WHERE mvs.rowid IN (SELECT vc_1
                                                     FROM tbl_temp)
                                 AND mvs.id_monitorization = m.id_monitorization
                                 AND mvsp.id_monitorization_vs = mvs.id_monitorization_vs
                                 AND mvsp.id_monitorization_vs_plan =
                                     (SELECT MAX(id_monitorization_vs_plan)
                                        FROM monitorization_vs_plan mvp1
                                       WHERE mvp1.id_monitorization_vs = mvs.id_monitorization_vs)
                                 AND e.id_episode = m.id_episode
                                 AND v.id_visit = e.id_visit
                                 AND vs.id_vital_sign = mvs.id_vital_sign)
                LOOP
                
                    l_message := 'GET MONITORIZATION STATUS';
                    pk_alertlog.log_debug(l_message);
                    get_monitorizations_status(i_prof            => i_prof,
                                               i_episode_origin  => r_cur.id_episode_origin,
                                               i_flg_time        => r_cur.flg_time,
                                               i_dt_begin        => r_cur.dt_begin_tstz,
                                               i_flg_status_det  => r_cur.flg_status_det,
                                               i_flg_status_plan => r_cur.flg_status_plan,
                                               i_dt_plan         => r_cur.dt_plan_tstz,
                                               o_status_str      => l_new_rec_row.status_str,
                                               o_status_msg      => l_new_rec_row.status_msg,
                                               o_status_icon     => l_new_rec_row.status_icon,
                                               o_status_flg      => l_new_rec_row.status_flg);
                
                    l_message := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    pk_alertlog.log_debug(l_message);
                
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_monitoring;
                    l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_monitor;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := current_timestamp;
                
                    l_new_rec_row.id_task_refid    := r_cur.id_monitorization_vs;
                    l_new_rec_row.dt_begin         := nvl(r_cur.dt_begin_tstz, r_cur.dt_monitorization_tstz);
                    l_new_rec_row.flg_status_req   := r_cur.flg_status_det;
                    l_new_rec_row.id_prof_req      := r_cur.id_professional;
                    l_new_rec_row.dt_req           := nvl(r_cur.dt_order, r_cur.dt_monitorization_vs_tstz);
                    l_new_rec_row.id_patient       := r_cur.id_patient;
                    l_new_rec_row.id_episode       := r_cur.id_episode;
                    l_new_rec_row.id_visit         := r_cur.id_visit;
                    l_new_rec_row.id_institution   := r_cur.id_institution;
                    l_new_rec_row.code_description := r_cur.code_vital_sign;
                    l_new_rec_row.flg_outdated     := l_flg_not_outdated;
                    l_new_rec_row.id_ref_group     := r_cur.id_monitorization;
                    l_new_rec_row.flg_sos          := pk_alert_constant.g_no;
                    l_new_rec_row.flg_ongoing      := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal       := r_cur.flg_normal;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    l_new_rec_row.dt_last_update   := r_cur.dt_last_update;
                
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || l_message,
                                          g_package_name,
                                          l_func_proc_name);
                
                    -- Search for updated registrie
                    IF l_new_rec_row.flg_status_req <> pk_alert_constant.g_epis_status_cancel
                    THEN
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = pk_alert_constant.g_tl_table_name_monitor
                           AND tte.id_tl_task = pk_prog_notes_constants.g_task_monitoring;
                    
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
                    
                        --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_monitor_vs_canc -- Cancelled ('C')
                        --OR l_new_rec_row.flg_status_req = pk_alert_constant.g_monitor_vs_fini -- Final ('F')
                        --OR l_new_rec_row.flg_status_req = pk_alert_constant.g_monitor_vs_inte -- Interrupted ('I')
                    
                        -- Information in states that are not relevant are DELETED
                        l_process_name  := 'DELETE';
                        l_event_into_ea := 'D';
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
                        l_message := 'TS_TASK_TIMELINE_EA.INS';
                        pk_alertlog.log_debug(l_message);
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE: Apenas poderão ocorrer DELETE's nas tabelas ANALYSIS_REQ e ANALYSIS_REQ_DET
                    THEN
                        l_message := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        pk_alertlog.log_debug(l_message);
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    -- UPDATE
                    THEN
                        l_message := 'TS_TASK_TIMELINE_EA.UPD';
                        pk_alertlog.log_debug(l_message);
                        ts_task_timeline_ea.upd(id_task_refid_in        => l_new_rec_row.id_task_refid,
                                                id_tl_task_in           => l_new_rec_row.id_tl_task,
                                                id_patient_nin          => FALSE,
                                                id_patient_in           => l_new_rec_row.id_patient,
                                                id_episode_nin          => FALSE,
                                                id_episode_in           => l_new_rec_row.id_episode,
                                                id_visit_nin            => FALSE,
                                                id_visit_in             => l_new_rec_row.id_visit,
                                                id_institution_nin      => FALSE,
                                                id_institution_in       => l_new_rec_row.id_institution,
                                                dt_req_nin              => TRUE,
                                                dt_req_in               => l_new_rec_row.dt_req,
                                                id_prof_req_nin         => TRUE,
                                                id_prof_req_in          => l_new_rec_row.id_prof_req,
                                                dt_begin_nin            => TRUE,
                                                dt_begin_in             => l_new_rec_row.dt_begin,
                                                dt_end_nin              => TRUE,
                                                dt_end_in               => NULL,
                                                flg_status_req_nin      => FALSE,
                                                flg_status_req_in       => l_new_rec_row.flg_status_req,
                                                status_str_nin          => FALSE,
                                                status_str_in           => l_new_rec_row.status_str,
                                                status_msg_nin          => FALSE,
                                                status_msg_in           => l_new_rec_row.status_msg,
                                                status_icon_nin         => FALSE,
                                                status_icon_in          => l_new_rec_row.status_icon,
                                                status_flg_nin          => FALSE,
                                                status_flg_in           => l_new_rec_row.status_flg,
                                                table_name_nin          => FALSE,
                                                table_name_in           => l_new_rec_row.table_name,
                                                flg_show_method_nin     => FALSE,
                                                flg_show_method_in      => l_new_rec_row.flg_show_method,
                                                code_description_nin    => FALSE,
                                                code_description_in     => l_new_rec_row.code_description,
                                                universal_desc_clob_nin => TRUE,
                                                universal_desc_clob_in  => l_new_rec_row.universal_desc_clob,
                                                flg_outdated_nin        => TRUE,
                                                flg_outdated_in         => l_new_rec_row.flg_outdated,
                                                flg_sos_nin             => FALSE,
                                                flg_sos_in              => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin         => TRUE,
                                                flg_ongoing_in          => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin          => TRUE,
                                                flg_normal_in           => l_new_rec_row.flg_normal,
                                                flg_has_comments_nin    => TRUE,
                                                flg_has_comments_in     => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in       => l_new_rec_row.dt_last_update,
                                                rows_out                => o_rowids);
                    
                    ELSE
                        -- EXCEPTION: Unexpected event type
                        RAISE l_excp_invalid_event_type;
                    END IF;
                
                    IF l_event_into_ea IN (t_data_gov_mnt.g_event_delete, t_data_gov_mnt.g_event_update)
                    THEN
                        --update also the dl_last_update of the monitorization_vs records of the same monitorization
                        ts_task_timeline_ea.upd(where_in          => ' id_ref_group = ' || l_new_rec_row.id_ref_group ||
                                                                     ' and id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                dt_last_update_in => l_new_rec_row.dt_last_update);
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            pk_alert_exceptions.reset_error_state;
        
        WHEN l_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
            pk_alert_exceptions.reset_error_state;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_TIMELINE_ANALYSIS',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_task_timeline_monit;

    PROCEDURE ins_grid_task_monitorizations
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    ) IS
    
        l_grid_task      grid_task%ROWTYPE;
        l_grid_task_betw grid_task_between%ROWTYPE;
        l_shortcut       sys_shortcut.id_sys_shortcut%TYPE;
        l_dt_str_1       VARCHAR2(200 CHAR);
        l_dt_str_2       VARCHAR2(200 CHAR);
        l_dt_1           VARCHAR2(200 CHAR);
        l_dt_2           VARCHAR2(200 CHAR);
        l_prof           profissional := i_prof;
        l_id_institution episode.id_institution%TYPE;
        l_id_software    epis_info.id_software%TYPE;
    
        l_error_out t_error_out;
    
    BEGIN
        -- Loop through changed records            
        FOR r_cur IN (SELECT *
                        FROM (SELECT /*+ opt_estimate(table mv rows=1) */
                               nvl(m.id_episode, m.id_episode_origin) id_episode,
                               nvl(mv.id_prof_order, m.id_professional) id_professional
                                FROM monitorization_vs mv
                                JOIN monitorization m
                                  ON mv.id_monitorization = m.id_monitorization
                               WHERE mv.rowid IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                   *
                                                    FROM TABLE(i_rowids) t)
                                 AND mv.flg_status != pk_alert_constant.g_monitor_vs_draft))
        LOOP
        
            l_grid_task      := NULL;
            l_grid_task_betw := NULL;
        
            IF i_prof IS NULL
            THEN
                BEGIN
                    SELECT e.id_institution, ei.id_software
                      INTO l_id_institution, l_id_software
                      FROM episode e
                      JOIN epis_info ei
                        ON ei.id_episode = e.id_episode
                     WHERE e.id_episode = r_cur.id_episode;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_institution := NULL;
                        l_id_software    := NULL;
                END;
            
                IF r_cur.id_professional IS NULL
                   OR l_id_institution IS NULL
                   OR l_id_software IS NULL
                THEN
                    CONTINUE;
                END IF;
            
                l_prof := profissional(r_cur.id_professional, l_id_institution, l_id_software);
            END IF;
        
            ins_grid_task_monit_epis(i_lang => i_lang, i_prof => l_prof, i_id_episode => r_cur.id_episode);
        END LOOP;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_monitorizations;

    PROCEDURE ins_grid_task_monit_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN grid_task.id_episode%TYPE
    ) IS
    
        l_grid_task      grid_task%ROWTYPE;
        l_grid_task_betw grid_task_between%ROWTYPE;
        l_shortcut       sys_shortcut.id_sys_shortcut%TYPE;
        l_dt_str_1       VARCHAR2(200 CHAR);
        l_dt_str_2       VARCHAR2(200 CHAR);
        l_dt_1           VARCHAR2(200 CHAR);
        l_dt_2           VARCHAR2(200 CHAR);
        l_prof           profissional := i_prof;
        l_id_institution episode.id_institution%TYPE;
        l_id_software    epis_info.id_software%TYPE;
    
        l_error_out t_error_out;
    
    BEGIN
        g_error := 'PK_ACCESS.GET_ID_SHORTCUT for GRID_MONITOR';
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => l_prof,
                                         i_intern_name => 'GRID_MONITOR',
                                         o_id_shortcut => l_shortcut,
                                         o_error       => l_error_out)
        THEN
            l_shortcut := 0;
        END IF;
    
        SELECT MAX(status_string) status_string, MAX(flg_monitor) flg_monitor
          INTO l_grid_task.monitorization, l_grid_task_betw.flg_monitor
          FROM (SELECT decode(rank,
                              1,
                              pk_utils.get_status_string(i_lang,
                                                         l_prof,
                                                         pk_ea_logic_monitorizations.get_monitorization_status_str(l_prof,
                                                                                                                   id_episode_origin,
                                                                                                                   flg_time,
                                                                                                                   dt_begin_tstz,
                                                                                                                   flg_status_det,
                                                                                                                   flg_status_plan,
                                                                                                                   dt_plan_tstz),
                                                         pk_ea_logic_monitorizations.get_monitorization_status_msg(l_prof,
                                                                                                                   id_episode_origin,
                                                                                                                   flg_time,
                                                                                                                   dt_begin_tstz,
                                                                                                                   flg_status_det,
                                                                                                                   flg_status_plan,
                                                                                                                   dt_plan_tstz),
                                                         pk_ea_logic_monitorizations.get_monitorization_status_icon(l_prof,
                                                                                                                    id_episode_origin,
                                                                                                                    flg_time,
                                                                                                                    dt_begin_tstz,
                                                                                                                    flg_status_det,
                                                                                                                    flg_status_plan,
                                                                                                                    dt_plan_tstz),
                                                         pk_ea_logic_monitorizations.get_monitorization_status_flg(l_prof,
                                                                                                                   id_episode_origin,
                                                                                                                   flg_time,
                                                                                                                   dt_begin_tstz,
                                                                                                                   flg_status_det,
                                                                                                                   flg_status_plan,
                                                                                                                   dt_plan_tstz)),
                              NULL) status_string,
                       decode(rank, 1, decode(flg_time, pk_alert_constant.g_flg_time_b, pk_alert_constant.g_yes), NULL) flg_monitor
                  FROM (SELECT t.id_monitorization,
                               t.id_episode_origin,
                               t.flg_time,
                               t.flg_status,
                               t.flg_status_det,
                               t.flg_status_plan,
                               t.dt_begin_tstz,
                               t.dt_plan_tstz,
                               row_number() over(ORDER BY t.rank) rank
                          FROM (SELECT t.*,
                                       decode(t.flg_status_plan,
                                              pk_alert_constant.g_monitor_vs_exec,
                                              row_number() over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                         'MONITORIZATION.FLG_STATUS',
                                                                         t.flg_status_det),
                                                   coalesce(t.dt_plan_tstz, t.dt_begin_tstz)),
                                              row_number() over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                         'MONITORIZATION.FLG_STATUS',
                                                                         t.flg_status_det),
                                                   coalesce(t.dt_plan_tstz, t.dt_begin_tstz) DESC) + 20000) rank
                                  FROM (SELECT m.id_monitorization,
                                               m.id_episode_origin,
                                               m.flg_time,
                                               m.flg_status,
                                               mv.flg_status       flg_status_det,
                                               mvp.flg_status      flg_status_plan,
                                               m.dt_begin_tstz,
                                               mvp.dt_plan_tstz
                                          FROM monitorization         m,
                                               monitorization_vs      mv,
                                               monitorization_vs_plan mvp,
                                               episode                e
                                         WHERE (m.id_episode = i_id_episode OR m.id_prev_episode = i_id_episode)
                                           AND m.id_monitorization = mv.id_monitorization
                                           AND mv.id_monitorization_vs = mvp.id_monitorization_vs
                                           AND mvp.flg_status IN
                                               (pk_alert_constant.g_monitor_vs_pend, pk_alert_constant.g_monitor_vs_exec)
                                           AND m.id_episode = e.id_episode) t) t) t
                 WHERE rank = 1) t;
    
        g_error := 'GET SHORTCUT - DOCTOR';
        IF l_grid_task.monitorization IS NOT NULL
        THEN
            IF regexp_like(l_grid_task.monitorization, '^\|D')
            THEN
                l_dt_str_1 := regexp_replace(l_grid_task.monitorization, '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*', '\1');
                l_dt_str_2 := regexp_replace(l_grid_task.monitorization, '^\|D\w{0,1}\|\d{14}\|.*\|(\d{14})\|.*', '\1');
            
                l_dt_1 := pk_date_utils.to_char_insttimezone(l_prof,
                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                           l_prof,
                                                                                           l_dt_str_1,
                                                                                           NULL),
                                                             'YYYYMMDDHH24MISS TZR');
            
                l_dt_2 := pk_date_utils.to_char_insttimezone(l_prof,
                                                             pk_date_utils.get_string_tstz(i_lang,
                                                                                           l_prof,
                                                                                           l_dt_str_2,
                                                                                           NULL),
                                                             'YYYYMMDDHH24MISS TZR');
            
                IF l_dt_str_1 = l_dt_str_2
                THEN
                    l_grid_task.monitorization := regexp_replace(l_grid_task.monitorization, l_dt_str_1, l_dt_1);
                ELSE
                    l_grid_task.monitorization := regexp_replace(l_grid_task.monitorization, l_dt_str_1, l_dt_1);
                    l_grid_task.monitorization := regexp_replace(l_grid_task.monitorization, l_dt_str_2, l_dt_2);
                END IF;
            ELSE
                l_dt_str_2                 := regexp_replace(l_grid_task.monitorization,
                                                             '^\|\w{0,2}\|.*\|(\d{14})\|.*',
                                                             '\1');
                l_dt_2                     := pk_date_utils.to_char_insttimezone(l_prof,
                                                                                 pk_date_utils.get_string_tstz(i_lang,
                                                                                                               l_prof,
                                                                                                               l_dt_str_2,
                                                                                                               NULL),
                                                                                 'YYYYMMDDHH24MISS TZR');
                l_grid_task.monitorization := regexp_replace(l_grid_task.monitorization, l_dt_str_2, l_dt_2);
            END IF;
        
            l_grid_task.monitorization := l_shortcut || l_grid_task.monitorization;
        END IF;
    
        l_grid_task.id_episode := i_id_episode;
    
        IF l_grid_task.id_episode IS NOT NULL
        THEN
            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
            IF NOT pk_grid.update_grid_task(i_lang             => i_lang,
                                            i_prof             => l_prof,
                                            i_episode          => l_grid_task.id_episode,
                                            monitorization_in  => l_grid_task.monitorization,
                                            monitorization_nin => FALSE,
                                            o_error            => l_error_out)
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        
            IF l_grid_task.monitorization IS NULL
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
             WHERE e.id_episode = i_id_episode
               AND NOT EXISTS (SELECT 1
                      FROM wtl_epis
                     WHERE id_episode = i_id_episode);
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_prev_episode';
                IF NOT pk_grid.update_grid_task(i_lang             => i_lang,
                                                i_prof             => l_prof,
                                                i_episode          => l_grid_task.id_episode,
                                                monitorization_in  => l_grid_task.monitorization,
                                                monitorization_nin => FALSE,
                                                o_error            => l_error_out)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            
                IF l_grid_task.monitorization IS NULL
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
            SELECT DISTINCT m.id_episode_origin
              INTO l_grid_task.id_episode
              FROM monitorization m
             WHERE m.id_episode_origin IS NOT NULL
               AND m.id_episode = i_id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode_origin';
                IF NOT pk_grid.update_grid_task(i_lang             => i_lang,
                                                i_prof             => l_prof,
                                                i_episode          => l_grid_task.id_episode,
                                                monitorization_in  => l_grid_task.monitorization,
                                                monitorization_nin => FALSE,
                                                o_error            => l_error_out)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            
                IF l_grid_task.intervention IS NULL
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
        IF l_grid_task_betw.flg_monitor = pk_alert_constant.g_yes
        THEN
            l_grid_task_betw.id_episode := i_id_episode;
        
            --Actualiza estado da tarefa em GRID_TASK_BETWEEN para o episódio correspondente
            g_error := 'CALL PK_GRID.UPDATE_NURSE_TASK';
            IF NOT pk_grid.update_nurse_task(i_lang => i_lang, i_grid_task => l_grid_task_betw, o_error => l_error_out)
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END ins_grid_task_monit_epis;

BEGIN
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);

END pk_ea_logic_monitorizations;
/
