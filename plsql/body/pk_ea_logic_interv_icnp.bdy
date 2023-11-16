CREATE OR REPLACE PACKAGE BODY pk_ea_logic_interv_icnp IS

    -- Function and procedure implementations

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
    
        IF i_table_name = 'ICNP_EPIS_DIAGNOSIS'
        THEN
            SELECT /*+rule*/
             iei.rowid
              BULK COLLECT
              INTO o_rowids
              FROM icnp_epis_intervention iei
             WHERE iei.id_icnp_epis_interv IN
                   (SELECT iedi.id_icnp_epis_interv
                      FROM icnp_epis_diag_interv iedi, icnp_epis_diagnosis ied
                     WHERE iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                       AND ied.rowid IN (SELECT column_value
                                           FROM TABLE(i_rowids) t));
        
        ELSIF i_table_name = 'ICNP_EPIS_INTERVENTION'
        THEN
            o_rowids := i_rowids;
        
        ELSIF i_table_name = 'ICNP_INTERV_PLAN'
        THEN
            SELECT /*+rule*/
             iei.rowid
              BULK COLLECT
              INTO o_rowids
              FROM icnp_epis_intervention iei
             WHERE iei.id_icnp_epis_interv IN
                   (SELECT ipp.id_icnp_epis_interv
                      FROM icnp_interv_plan ipp
                     WHERE ipp.rowid IN (SELECT column_value
                                           FROM TABLE(i_rowids) t));
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

    PROCEDURE get_icnp_interv_status
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE,
        o_status_str          OUT interv_icnp_ea.status_str%TYPE,
        o_status_msg          OUT interv_icnp_ea.status_msg%TYPE,
        o_status_icon         OUT interv_icnp_ea.status_icon%TYPE,
        o_status_flg          OUT interv_icnp_ea.status_flg%TYPE
    ) IS
        l_display_type  VARCHAR2(200);
        l_value         VARCHAR2(200);
        l_back_color    VARCHAR2(200);
        l_flg_status    VARCHAR2(200);
        l_message_style VARCHAR2(200);
        l_icon_color    VARCHAR2(200);
    
    BEGIN
    
        -- Determine the display type and value
        IF i_flg_status = pk_icnp_constant.g_epis_interv_status_requested
           AND nvl(i_order_recurr_option, 0) != pk_order_recurrence_core.g_order_recurr_option_no_sched
        THEN
            IF i_flg_time = pk_icnp_constant.g_epis_interv_time_next_epis
            THEN
                l_value        := 'ICON_T056';
                l_display_type := pk_alert_constant.g_display_type_text;
            ELSE
                IF i_flg_prn = pk_alert_constant.get_yes
                THEN
                    l_value        := 'CIPE_M007';
                    l_display_type := pk_alert_constant.g_display_type_text;
                ELSE
                    IF i_dt_next IS NOT NULL
                    THEN
                        l_value        := pk_date_utils.to_char_insttimezone(i_prof,
                                                                             i_dt_next,
                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                        l_display_type := pk_alert_constant.g_display_type_date;
                    ELSE
                        l_value        := pk_date_utils.to_char_insttimezone(i_prof,
                                                                             i_dt_plan,
                                                                             pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                        l_display_type := pk_alert_constant.g_display_type_date;
                    END IF;
                END IF;
            END IF;
        
        ELSIF i_flg_status = pk_icnp_constant.g_epis_interv_status_ongoing
              AND nvl(i_order_recurr_option, 0) != pk_order_recurrence_core.g_order_recurr_option_no_sched
        THEN
            IF i_flg_prn = pk_alert_constant.get_yes
            THEN
                l_value        := 'CIPE_M007';
                l_display_type := pk_alert_constant.g_display_type_text;
            ELSE
                IF i_dt_next IS NOT NULL
                THEN
                    l_value        := pk_date_utils.to_char_insttimezone(i_prof,
                                                                         i_dt_next,
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                    l_display_type := pk_alert_constant.g_display_type_date;
                ELSE
                    l_value        := pk_date_utils.to_char_insttimezone(i_prof,
                                                                         i_dt_plan,
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                    l_display_type := pk_alert_constant.g_display_type_date;
                END IF;
            END IF;
        
        ELSE
            l_value        := 'ICNP_EPIS_INTERVENTION.FLG_STATUS';
            l_display_type := pk_alert_constant.g_display_type_icon;
        END IF;
    
        IF nvl(i_order_recurr_option, 0) = pk_order_recurrence_core.g_order_recurr_option_no_sched
        THEN
            l_value        := 'ICNP_EPIS_INTERVENTION.FLG_STATUS';
            l_display_type := pk_alert_constant.g_display_type_icon;
        END IF;
    
        -- Determine the back color
        IF i_flg_status = pk_icnp_constant.g_epis_diag_status_active
           AND i_flg_time = pk_icnp_constant.g_epis_interv_time_next_epis
           OR (nvl(i_order_recurr_option, 0) = pk_order_recurrence_core.g_order_recurr_option_no_sched AND
           i_flg_status = pk_icnp_constant.g_epis_diag_status_active)
        THEN
            l_back_color := pk_alert_constant.g_color_green;
        ELSE
            l_back_color := '';
        END IF;
    
        -- Determine the flag status
        l_flg_status := i_flg_status;
    
        -- Determine the message style
        IF i_flg_prn = pk_alert_constant.get_yes
           AND i_flg_time <> pk_icnp_constant.g_epis_interv_time_next_epis
        THEN
            l_message_style := 'IconRendererMessage';
        ELSE
            l_message_style := NULL;
        END IF;
    
        -- Determine the icon color
        IF l_display_type IN (pk_alert_constant.g_display_type_icon, pk_alert_constant.g_display_type_date_icon)
        THEN
            IF l_back_color IN (pk_alert_constant.g_color_red, pk_alert_constant.g_color_green)
            THEN
                IF nvl(i_order_recurr_option, 0) = pk_order_recurrence_core.g_order_recurr_option_no_sched
                THEN
                    l_icon_color := NULL;
                ELSE
                    l_icon_color := pk_alert_constant.g_color_icon_light_grey;
                END IF;
            ELSIF i_flg_status IN (pk_icnp_constant.g_epis_diag_status_cancelled,
                                   pk_icnp_constant.g_epis_diag_status_resolved,
                                   pk_icnp_constant.g_epis_interv_status_discont)
            THEN
                l_icon_color := pk_alert_constant.g_color_icon_dark_grey;
            ELSE
                l_icon_color := pk_alert_constant.g_color_icon_medium_grey;
            END IF;
        ELSE
            l_icon_color := NULL;
        END IF;
    
        -- Build the status string
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_flg_status,
                                     i_value_text    => l_value,
                                     i_value_date    => l_value,
                                     i_value_icon    => l_value,
                                     i_back_color    => l_back_color,
                                     i_icon_color    => l_icon_color,
                                     i_message_style => l_message_style,
                                     o_status_str    => o_status_str,
                                     o_status_msg    => o_status_msg,
                                     o_status_icon   => o_status_icon,
                                     o_status_flg    => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END;

    FUNCTION get_icnp_interv_status_str
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(1);
    
    BEGIN
    
        pk_ea_logic_interv_icnp.get_icnp_interv_status(i_prof                => i_prof,
                                                       i_flg_status          => i_flg_status,
                                                       i_flg_type            => i_flg_type,
                                                       i_flg_time            => i_flg_time,
                                                       i_dt_next             => i_dt_next,
                                                       i_dt_plan             => i_dt_plan,
                                                       i_flg_prn             => i_flg_prn,
                                                       i_order_recurr_option => NULL,
                                                       o_status_str          => l_status_str,
                                                       o_status_msg          => l_status_msg,
                                                       o_status_icon         => l_status_icon,
                                                       o_status_flg          => l_status_flg);
    
        RETURN l_status_str;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_icnp_interv_status_str;

    FUNCTION get_icnp_interv_status_msg
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(1);
    
    BEGIN
    
        pk_ea_logic_interv_icnp.get_icnp_interv_status(i_prof                => i_prof,
                                                       i_flg_status          => i_flg_status,
                                                       i_flg_type            => i_flg_type,
                                                       i_flg_time            => i_flg_time,
                                                       i_dt_next             => i_dt_next,
                                                       i_dt_plan             => i_dt_plan,
                                                       i_flg_prn             => i_flg_prn,
                                                       i_order_recurr_option => NULL,
                                                       o_status_str          => l_status_str,
                                                       o_status_msg          => l_status_msg,
                                                       o_status_icon         => l_status_icon,
                                                       o_status_flg          => l_status_flg);
    
        RETURN l_status_msg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_icnp_interv_status_msg;

    FUNCTION get_icnp_interv_status_icon
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(1);
    
    BEGIN
    
        pk_ea_logic_interv_icnp.get_icnp_interv_status(i_prof                => i_prof,
                                                       i_flg_status          => i_flg_status,
                                                       i_flg_type            => i_flg_type,
                                                       i_flg_time            => i_flg_time,
                                                       i_dt_next             => i_dt_next,
                                                       i_dt_plan             => i_dt_plan,
                                                       i_flg_prn             => i_flg_prn,
                                                       i_order_recurr_option => NULL,
                                                       o_status_str          => l_status_str,
                                                       o_status_msg          => l_status_msg,
                                                       o_status_icon         => l_status_icon,
                                                       o_status_flg          => l_status_flg);
    
        RETURN l_status_icon;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_icnp_interv_status_icon;

    FUNCTION get_icnp_interv_status_flg
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(1);
    
    BEGIN
    
        pk_ea_logic_interv_icnp.get_icnp_interv_status(i_prof                => i_prof,
                                                       i_flg_status          => i_flg_status,
                                                       i_flg_type            => i_flg_type,
                                                       i_flg_time            => i_flg_time,
                                                       i_dt_next             => i_dt_next,
                                                       i_dt_plan             => i_dt_plan,
                                                       i_flg_prn             => i_flg_prn,
                                                       i_order_recurr_option => NULL,
                                                       o_status_str          => l_status_str,
                                                       o_status_msg          => l_status_msg,
                                                       o_status_icon         => l_status_icon,
                                                       o_status_flg          => l_status_flg);
    
        RETURN l_status_flg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_icnp_interv_status_flg;

    PROCEDURE set_icnp_epis_intervention
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_func_proc_name CONSTANT VARCHAR2(30 CHAR) := 'SET_ICNP_EPIS_INTERVENTION';
        o_rowids table_varchar;
    
        CURSOR c_interv IS
            SELECT itv.id_icnp_epis_interv,
                   itv.id_composition_interv,
                   itv.id_icnp_epis_diag,
                   itv.id_composition_diag,
                   itv.flg_time,
                   itv.flg_status,
                   itv.flg_type,
                   itv.dt_next,
                   itv.dt_plan,
                   itv.id_vs,
                   itv.id_prof_close,
                   itv.dt_close,
                   itv.dt_icnp_epis_interv,
                   itv.id_prof,
                   itv.id_episode_origin,
                   itv.id_episode,
                   itv.id_patient,
                   itv.flg_status_plan,
                   itv.id_prof_take,
                   itv.freq,
                   itv.notes,
                   itv.notes_close,
                   itv.dt_begin,
                   itv.flg_duration_unit,
                   itv.duration,
                   itv.num_take,
                   itv.flg_interval_unit,
                   itv.interval,
                   itv.dt_take_ea,
                   itv.flg_prn,
                   itv.recurr_option
              FROM (SELECT /*+opt_estimate(table iei rows=1)*/
                     iei.id_icnp_epis_interv,
                     iei.id_composition id_composition_interv,
                     ied.id_icnp_epis_diag,
                     ied.id_composition id_composition_diag,
                     iei.flg_time,
                     iei.flg_status,
                     iei.flg_type,
                     iei.dt_next_tstz dt_next,
                     decode((SELECT 1
                              FROM icnp_interv_plan i
                             WHERE i.id_icnp_epis_interv = iei.id_icnp_epis_interv
                               AND rownum = 1
                               AND i.flg_status NOT IN
                                   (pk_icnp_constant.g_epis_interv_status_requested,
                                    pk_icnp_constant.g_epis_interv_status_cancelled,
                                    pk_icnp_constant.g_epis_interv_status_modified)),
                            1,
                            decode(iip.dt_plan_tstz, NULL, iei.dt_icnp_epis_interv_tstz, iip.dt_plan_tstz),
                            iip.dt_plan_tstz) dt_plan,
                     (ici.flg_task || ici.id_vs) id_vs,
                     iei.id_prof_close,
                     iei.dt_close_tstz dt_close,
                     iei.dt_icnp_epis_interv_tstz dt_icnp_epis_interv,
                     iei.id_prof,
                     iei.id_episode_origin,
                     iei.id_episode,
                     iei.id_patient,
                     iip.flg_status flg_status_plan,
                     nvl(iei.id_prof_close, iip.id_prof_take) id_prof_take,
                     iei.freq,
                     iei.notes,
                     iei.notes_close,
                     iei.dt_begin_tstz dt_begin,
                     iei.flg_duration_unit,
                     iei.duration,
                     iei.num_take,
                     iei.flg_interval_unit,
                     iei.interval,
                     nvl(iei.dt_close_tstz, iip.dt_take_tstz) dt_take_ea,
                     iei.flg_prn,
                     orp.id_order_recurr_option recurr_option,
                     row_number() over(PARTITION BY iei.id_icnp_epis_interv ORDER BY --
                     decode(iip.flg_status, pk_icnp_constant.g_interv_plan_status_pending, 1, pk_icnp_constant.g_interv_plan_status_requested, 1, 2), iip.dt_plan_tstz) rn
                      FROM icnp_epis_intervention iei
                      JOIN icnp_composition ici
                        ON iei.id_composition = ici.id_composition
                      LEFT JOIN order_recurr_plan orp
                        ON orp.id_order_recurr_plan = iei.id_order_recurr_plan
                      LEFT JOIN icnp_epis_diag_interv iedi
                        ON iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                      LEFT JOIN icnp_epis_diagnosis ied
                        ON iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                      LEFT JOIN icnp_interv_plan iip
                        ON iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                       AND iip.flg_status IN (pk_icnp_constant.g_interv_plan_status_pending,
                                              pk_icnp_constant.g_interv_plan_status_requested,
                                              pk_icnp_constant.g_interv_plan_status_executed,
                                              pk_icnp_constant.g_interv_plan_status_suspended)
                     WHERE iei.rowid IN (SELECT t.column_value row_id
                                           FROM TABLE(i_rowids) t)
                       AND iei.id_episode_destination IS NULL
                       AND iei.forward_interv IS NULL) itv
             WHERE itv.rn = 1;
    
        TYPE t_coll_icnp IS TABLE OF c_interv%ROWTYPE;
    
        l_icnp_coll t_coll_icnp;
        l_icnp_row  c_interv%ROWTYPE;
        l_iea_coll  ts_interv_icnp_ea.interv_icnp_ea_tc;
        l_iea_row   interv_icnp_ea%ROWTYPE;
    BEGIN
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'ICNP_EPIS_INTERVENTION',
                                                 i_expected_dg_table_name => 'INTERV_ICNP_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            pk_alertlog.log_debug(text            => 'Processing insert/update on ICNP_EPIS_INTERVENTION',
                                  object_name     => g_package_name,
                                  sub_object_name => l_func_proc_name);
        
            -- get applicable records
            g_error := 'OPEN c_interv';
            OPEN c_interv;
            FETCH c_interv BULK COLLECT
                INTO l_icnp_coll;
            CLOSE c_interv;
        
            IF l_icnp_coll IS NOT NULL
               AND l_icnp_coll.count > 0
            THEN
                FOR i IN l_icnp_coll.first .. l_icnp_coll.last
                LOOP
                    l_icnp_row := l_icnp_coll(i);
                
                    -- build ea row
                    g_error := 'CALL get_icnp_interv_status';
                    get_icnp_interv_status(i_prof                => i_prof,
                                           i_flg_status          => l_icnp_row.flg_status,
                                           i_flg_type            => l_icnp_row.flg_type,
                                           i_flg_time            => l_icnp_row.flg_time,
                                           i_dt_next             => l_icnp_row.dt_next,
                                           i_dt_plan             => l_icnp_row.dt_plan,
                                           i_flg_prn             => l_icnp_row.flg_prn,
                                           i_order_recurr_option => l_icnp_row.recurr_option,
                                           o_status_str          => l_iea_row.status_str,
                                           o_status_msg          => l_iea_row.status_msg,
                                           o_status_icon         => l_iea_row.status_icon,
                                           o_status_flg          => l_iea_row.status_flg);
                
                    l_iea_row.id_icnp_epis_interv   := l_icnp_row.id_icnp_epis_interv;
                    l_iea_row.id_composition_interv := l_icnp_row.id_composition_interv;
                    l_iea_row.id_icnp_epis_diag     := l_icnp_row.id_icnp_epis_diag;
                    l_iea_row.id_composition_diag   := l_icnp_row.id_composition_diag;
                    l_iea_row.flg_time              := l_icnp_row.flg_time;
                    l_iea_row.flg_status            := l_icnp_row.flg_status;
                    l_iea_row.flg_type              := l_icnp_row.flg_type;
                    l_iea_row.dt_next               := l_icnp_row.dt_next;
                    l_iea_row.dt_plan               := l_icnp_row.dt_plan;
                    l_iea_row.id_vs                 := l_icnp_row.id_vs;
                    l_iea_row.id_prof_close         := l_icnp_row.id_prof_close;
                    l_iea_row.dt_close              := l_icnp_row.dt_close;
                    l_iea_row.dt_icnp_epis_interv   := l_icnp_row.dt_icnp_epis_interv;
                    l_iea_row.id_prof               := l_icnp_row.id_prof;
                    l_iea_row.id_episode_origin     := l_icnp_row.id_episode_origin;
                    l_iea_row.id_episode            := l_icnp_row.id_episode;
                    l_iea_row.id_patient            := l_icnp_row.id_patient;
                    l_iea_row.flg_status_plan       := l_icnp_row.flg_status_plan;
                    l_iea_row.id_prof_take          := l_icnp_row.id_prof_take;
                    l_iea_row.freq                  := l_icnp_row.freq;
                    l_iea_row.notes                 := l_icnp_row.notes;
                    l_iea_row.notes_close           := l_icnp_row.notes_close;
                    l_iea_row.dt_begin              := l_icnp_row.dt_begin;
                    l_iea_row.flg_duration_unit     := l_icnp_row.flg_duration_unit;
                    l_iea_row.duration              := l_icnp_row.duration;
                    l_iea_row.num_take              := l_icnp_row.num_take;
                    l_iea_row.flg_interval_unit     := l_icnp_row.flg_interval_unit;
                    l_iea_row.interval              := l_icnp_row.interval;
                    l_iea_row.dt_take_ea            := l_icnp_row.dt_take_ea;
                    l_iea_row.flg_prn               := l_icnp_row.flg_prn;
                
                    l_iea_coll(i) := l_iea_row;
                END LOOP;
            
                IF i_event_type = t_data_gov_mnt.g_event_insert
                THEN
                    g_error := 'CALL ts_interv_icnp_ea.ins';
                    ts_interv_icnp_ea.ins(rows_in => l_iea_coll, rows_out => o_rowids);
                ELSIF i_event_type = t_data_gov_mnt.g_event_update
                THEN
                    g_error := 'CALL ts_interv_icnp_ea.upd';
                    ts_interv_icnp_ea.upd(col_in => l_iea_coll, ignore_if_null_in => FALSE, rows_out => o_rowids);
                END IF;
            END IF;
        
        ELSIF i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            NULL;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_icnp_epis_intervention;

    PROCEDURE set_icnp_epis_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name CONSTANT VARCHAR2(30 CHAR) := 'SET_ICNP_EPIS_DIAGNOSIS';
        o_rowids table_varchar;
    
        CURSOR c_diag IS
            SELECT itv.id_icnp_epis_interv,
                   itv.id_composition_interv,
                   itv.id_icnp_epis_diag,
                   itv.id_composition_diag,
                   itv.flg_time,
                   itv.flg_status,
                   itv.flg_type,
                   itv.dt_next,
                   itv.dt_plan,
                   itv.id_vs,
                   itv.id_prof_close,
                   itv.dt_close,
                   itv.dt_icnp_epis_interv,
                   itv.id_prof,
                   itv.id_episode_origin,
                   itv.id_episode,
                   itv.id_patient,
                   itv.flg_status_plan,
                   itv.id_prof_take,
                   itv.freq,
                   itv.notes,
                   itv.notes_close,
                   itv.dt_begin,
                   itv.flg_duration_unit,
                   itv.duration,
                   itv.num_take,
                   itv.flg_interval_unit,
                   itv.interval,
                   itv.dt_take_ea,
                   itv.flg_prn
              FROM (SELECT /*+opt_estimate(table ied rows=1)*/
                     iei.id_icnp_epis_interv,
                     iei.id_composition id_composition_interv,
                     ied.id_icnp_epis_diag,
                     ied.id_composition id_composition_diag,
                     iei.flg_time,
                     iei.flg_status,
                     iei.flg_type,
                     iei.dt_next_tstz dt_next,
                     iip.dt_plan_tstz dt_plan,
                     (ici.flg_task || ici.id_vs) id_vs,
                     iei.id_prof_close,
                     iei.dt_close_tstz dt_close,
                     iei.dt_icnp_epis_interv_tstz dt_icnp_epis_interv,
                     iei.id_prof,
                     iei.id_episode_origin,
                     iei.id_episode,
                     iei.id_patient,
                     iip.flg_status flg_status_plan,
                     nvl(iei.id_prof_close, iip.id_prof_take) id_prof_take,
                     iei.freq,
                     iei.notes,
                     iei.notes_close,
                     iei.dt_begin_tstz dt_begin,
                     iei.flg_duration_unit,
                     iei.duration,
                     iei.num_take,
                     iei.flg_interval_unit,
                     iei.interval,
                     nvl(iei.dt_close_tstz, iip.dt_take_tstz) dt_take_ea,
                     iei.flg_prn,
                     row_number() over(PARTITION BY iei.id_icnp_epis_interv ORDER BY --
                     decode(iip.flg_status, pk_icnp_constant.g_interv_plan_status_pending, 1, pk_icnp_constant.g_interv_plan_status_requested, 1, 2), iip.dt_plan_tstz) rn
                      FROM icnp_epis_intervention iei
                      JOIN icnp_composition ici
                        ON iei.id_composition = ici.id_composition
                      JOIN icnp_epis_diag_interv iedi
                        ON iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                      JOIN icnp_epis_diagnosis ied
                        ON iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                      LEFT JOIN icnp_interv_plan iip
                        ON iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                       AND iip.flg_status IN (pk_icnp_constant.g_interv_plan_status_pending,
                                              pk_icnp_constant.g_interv_plan_status_requested,
                                              pk_icnp_constant.g_interv_plan_status_executed,
                                              pk_icnp_constant.g_interv_plan_status_suspended)
                     WHERE ied.rowid IN (SELECT t.column_value row_id
                                           FROM TABLE(i_rowids) t)
                       AND iei.id_episode_destination IS NULL
                       AND iei.forward_interv IS NULL) itv
             WHERE itv.rn = 1;
    
        TYPE t_coll_icnp IS TABLE OF c_diag%ROWTYPE;
    
        l_icnp_coll t_coll_icnp;
        l_icnp_row  c_diag%ROWTYPE;
        l_iea_coll  ts_interv_icnp_ea.interv_icnp_ea_tc;
        l_iea_row   interv_icnp_ea%ROWTYPE;
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'ICNP_EPIS_DIAGNOSIS',
                                                 i_expected_dg_table_name => 'INTERV_ICNP_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        -- Process INSERT and UPDATE
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            pk_alertlog.log_debug(text            => 'Processing insert/update on ICNP_EPIS_DIAGNOSIS',
                                  object_name     => g_package_name,
                                  sub_object_name => l_func_proc_name);
        
            -- get applicable records
            g_error := 'OPEN c_diag';
            OPEN c_diag;
            FETCH c_diag BULK COLLECT
                INTO l_icnp_coll;
            CLOSE c_diag;
        
            IF l_icnp_coll IS NOT NULL
               AND l_icnp_coll.count > 0
            THEN
                FOR i IN l_icnp_coll.first .. l_icnp_coll.last
                LOOP
                    l_icnp_row := l_icnp_coll(i);
                
                    -- build ea row
                    g_error := 'CALL get_icnp_interv_status';
                    get_icnp_interv_status(i_prof                => i_prof,
                                           i_flg_status          => l_icnp_row.flg_status,
                                           i_flg_type            => l_icnp_row.flg_type,
                                           i_flg_time            => l_icnp_row.flg_time,
                                           i_dt_next             => l_icnp_row.dt_next,
                                           i_dt_plan             => l_icnp_row.dt_plan,
                                           i_flg_prn             => l_icnp_row.flg_prn,
                                           i_order_recurr_option => NULL,
                                           o_status_str          => l_iea_row.status_str,
                                           o_status_msg          => l_iea_row.status_msg,
                                           o_status_icon         => l_iea_row.status_icon,
                                           o_status_flg          => l_iea_row.status_flg);
                
                    l_iea_row.id_icnp_epis_interv   := l_icnp_row.id_icnp_epis_interv;
                    l_iea_row.id_composition_interv := l_icnp_row.id_composition_interv;
                    l_iea_row.id_icnp_epis_diag     := l_icnp_row.id_icnp_epis_diag;
                    l_iea_row.id_composition_diag   := l_icnp_row.id_composition_diag;
                    l_iea_row.flg_time              := l_icnp_row.flg_time;
                    l_iea_row.flg_status            := l_icnp_row.flg_status;
                    l_iea_row.flg_type              := l_icnp_row.flg_type;
                    l_iea_row.dt_next               := l_icnp_row.dt_next;
                    l_iea_row.dt_plan               := l_icnp_row.dt_plan;
                    l_iea_row.id_vs                 := l_icnp_row.id_vs;
                    l_iea_row.id_prof_close         := l_icnp_row.id_prof_close;
                    l_iea_row.dt_close              := l_icnp_row.dt_close;
                    l_iea_row.dt_icnp_epis_interv   := l_icnp_row.dt_icnp_epis_interv;
                    l_iea_row.id_prof               := l_icnp_row.id_prof;
                    l_iea_row.id_episode_origin     := l_icnp_row.id_episode_origin;
                    l_iea_row.id_episode            := l_icnp_row.id_episode;
                    l_iea_row.id_patient            := l_icnp_row.id_patient;
                    l_iea_row.flg_status_plan       := l_icnp_row.flg_status_plan;
                    l_iea_row.id_prof_take          := l_icnp_row.id_prof_take;
                    l_iea_row.freq                  := l_icnp_row.freq;
                    l_iea_row.notes                 := l_icnp_row.notes;
                    l_iea_row.notes_close           := l_icnp_row.notes_close;
                    l_iea_row.dt_begin              := l_icnp_row.dt_begin;
                    l_iea_row.flg_duration_unit     := l_icnp_row.flg_duration_unit;
                    l_iea_row.duration              := l_icnp_row.duration;
                    l_iea_row.num_take              := l_icnp_row.num_take;
                    l_iea_row.flg_interval_unit     := l_icnp_row.flg_interval_unit;
                    l_iea_row.interval              := l_icnp_row.interval;
                    l_iea_row.dt_take_ea            := l_icnp_row.dt_take_ea;
                
                    l_iea_coll(i) := l_iea_row;
                END LOOP;
            
                g_error := 'CALL ts_interv_icnp_ea.upd';
                ts_interv_icnp_ea.upd(col_in => l_iea_coll, ignore_if_null_in => FALSE, rows_out => o_rowids);
            END IF;
        ELSIF i_event_type = t_data_gov_mnt.g_event_delete
        THEN
            NULL;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_icnp_epis_diagnosis;

    PROCEDURE set_icnp_interv_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_func_proc_name CONSTANT VARCHAR2(30 CHAR) := 'SET_ICNP_INTERV_PLAN';
        o_rowids table_varchar;
    
        CURSOR c_exec IS
            SELECT itv.id_icnp_epis_interv,
                   itv.id_composition_interv,
                   itv.id_icnp_epis_diag,
                   itv.id_composition_diag,
                   itv.flg_time,
                   itv.flg_status,
                   itv.flg_type,
                   itv.dt_next,
                   itv.dt_plan,
                   itv.id_vs,
                   itv.id_prof_close,
                   itv.dt_close,
                   itv.dt_icnp_epis_interv,
                   itv.id_prof,
                   itv.id_episode_origin,
                   itv.id_episode,
                   itv.id_patient,
                   itv.flg_status_plan,
                   itv.id_prof_take,
                   itv.freq,
                   itv.notes,
                   itv.notes_close,
                   itv.dt_begin,
                   itv.flg_duration_unit,
                   itv.duration,
                   itv.num_take,
                   itv.flg_interval_unit,
                   itv.interval,
                   itv.dt_take_ea,
                   itv.flg_prn,
                   itv.recurr_option
              FROM (SELECT /*+opt_estimate(table iip rows=1)*/
                     iei.id_icnp_epis_interv,
                     iei.id_composition id_composition_interv,
                     ied.id_icnp_epis_diag,
                     ied.id_composition id_composition_diag,
                     iei.flg_time,
                     iei.flg_status,
                     iei.flg_type,
                     iei.dt_next_tstz dt_next,
                     decode(iip.flg_status, pk_icnp_constant.g_interv_plan_status_freq_alt, NULL, iip.dt_plan_tstz) dt_plan,
                     (ici.flg_task || ici.id_vs) id_vs,
                     iei.id_prof_close,
                     iei.dt_close_tstz dt_close,
                     iei.dt_icnp_epis_interv_tstz dt_icnp_epis_interv,
                     iei.id_prof,
                     iei.id_episode_origin,
                     iei.id_episode,
                     iei.id_patient,
                     decode(iip.flg_status, pk_icnp_constant.g_interv_plan_status_freq_alt, NULL, iip.flg_status) flg_status_plan,
                     nvl(iei.id_prof_close, iip.id_prof_take) id_prof_take,
                     iei.freq,
                     iei.notes,
                     iei.notes_close,
                     iei.dt_begin_tstz dt_begin,
                     iei.flg_duration_unit,
                     iei.duration,
                     iei.num_take,
                     iei.flg_interval_unit,
                     iei.interval,
                     nvl(iei.dt_close_tstz, iip.dt_take_tstz) dt_take_ea,
                     iei.flg_prn,
                     orp.id_order_recurr_option recurr_option,
                     row_number() over(PARTITION BY iei.id_icnp_epis_interv ORDER BY --
                     decode(iip.flg_status, pk_icnp_constant.g_interv_plan_status_pending, 1, pk_icnp_constant.g_interv_plan_status_requested, 1, pk_icnp_constant.g_interv_plan_status_executed, 2, pk_icnp_constant.g_interv_plan_status_suspended, 2, 3), iip.dt_plan_tstz) rn
                      FROM icnp_epis_intervention iei
                      JOIN icnp_composition ici
                        ON iei.id_composition = ici.id_composition
                      LEFT JOIN order_recurr_plan orp
                        ON iei.id_order_recurr_plan = orp.id_order_recurr_plan
                      LEFT JOIN icnp_epis_diag_interv iedi
                        ON iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                      LEFT JOIN icnp_epis_diagnosis ied
                        ON iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                      JOIN icnp_interv_plan iip
                        ON iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                     WHERE iip.rowid IN (SELECT t.column_value row_id
                                           FROM TABLE(i_rowids) t)
                       AND iei.id_episode_destination IS NULL
                       AND iei.forward_interv IS NULL) itv
             WHERE itv.rn = 1;
    
        TYPE t_coll_icnp IS TABLE OF c_exec%ROWTYPE;
    
        l_icnp_coll t_coll_icnp;
        l_icnp_row  c_exec%ROWTYPE;
        l_iea_coll  ts_interv_icnp_ea.interv_icnp_ea_tc;
        l_iea_row   interv_icnp_ea%ROWTYPE;
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'ICNP_INTERV_PLAN',
                                                 i_expected_dg_table_name => 'INTERV_ICNP_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- exit when no rowids are specified
        IF i_rowids IS NULL
           OR i_rowids.count < 1
        THEN
            RETURN;
        END IF;
    
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            pk_alertlog.log_debug(text            => 'Processing insert/update on ICNP_INTERV_PLAN',
                                  object_name     => g_package_name,
                                  sub_object_name => l_func_proc_name);
        
            -- get applicable records
            g_error := 'OPEN c_exec';
            OPEN c_exec;
            FETCH c_exec BULK COLLECT
                INTO l_icnp_coll;
            CLOSE c_exec;
        
            IF l_icnp_coll IS NOT NULL
               AND l_icnp_coll.count > 0
            THEN
                FOR i IN l_icnp_coll.first .. l_icnp_coll.last
                LOOP
                    l_icnp_row := l_icnp_coll(i);
                
                    -- build ea row
                    g_error := 'CALL get_icnp_interv_status';
                    get_icnp_interv_status(i_prof                => i_prof,
                                           i_flg_status          => l_icnp_row.flg_status,
                                           i_flg_type            => l_icnp_row.flg_type,
                                           i_flg_time            => l_icnp_row.flg_time,
                                           i_dt_next             => l_icnp_row.dt_next,
                                           i_dt_plan             => l_icnp_row.dt_plan,
                                           i_flg_prn             => l_icnp_row.flg_prn,
                                           i_order_recurr_option => l_icnp_row.recurr_option,
                                           o_status_str          => l_iea_row.status_str,
                                           o_status_msg          => l_iea_row.status_msg,
                                           o_status_icon         => l_iea_row.status_icon,
                                           o_status_flg          => l_iea_row.status_flg);
                
                    l_iea_row.id_icnp_epis_interv   := l_icnp_row.id_icnp_epis_interv;
                    l_iea_row.id_composition_interv := l_icnp_row.id_composition_interv;
                    l_iea_row.id_icnp_epis_diag     := l_icnp_row.id_icnp_epis_diag;
                    l_iea_row.id_composition_diag   := l_icnp_row.id_composition_diag;
                    l_iea_row.flg_time              := l_icnp_row.flg_time;
                    l_iea_row.flg_status            := l_icnp_row.flg_status;
                    l_iea_row.flg_type              := l_icnp_row.flg_type;
                    l_iea_row.dt_next               := l_icnp_row.dt_next;
                    l_iea_row.dt_plan               := l_icnp_row.dt_plan;
                    l_iea_row.id_vs                 := l_icnp_row.id_vs;
                    l_iea_row.id_prof_close         := l_icnp_row.id_prof_close;
                    l_iea_row.dt_close              := l_icnp_row.dt_close;
                    l_iea_row.dt_icnp_epis_interv   := l_icnp_row.dt_icnp_epis_interv;
                    l_iea_row.id_prof               := l_icnp_row.id_prof;
                    l_iea_row.id_episode_origin     := l_icnp_row.id_episode_origin;
                    l_iea_row.id_episode            := l_icnp_row.id_episode;
                    l_iea_row.id_patient            := l_icnp_row.id_patient;
                    l_iea_row.flg_status_plan       := l_icnp_row.flg_status_plan;
                    l_iea_row.id_prof_take          := l_icnp_row.id_prof_take;
                    l_iea_row.freq                  := l_icnp_row.freq;
                    l_iea_row.notes                 := l_icnp_row.notes;
                    l_iea_row.notes_close           := l_icnp_row.notes_close;
                    l_iea_row.dt_begin              := l_icnp_row.dt_begin;
                    l_iea_row.flg_duration_unit     := l_icnp_row.flg_duration_unit;
                    l_iea_row.duration              := l_icnp_row.duration;
                    l_iea_row.num_take              := l_icnp_row.num_take;
                    l_iea_row.flg_interval_unit     := l_icnp_row.flg_interval_unit;
                    l_iea_row.interval              := l_icnp_row.interval;
                    l_iea_row.dt_take_ea            := l_icnp_row.dt_take_ea;
                
                    l_iea_coll(i) := l_iea_row;
                END LOOP;
            
                g_error := 'CALL ts_interv_icnp_ea.upd';
                ts_interv_icnp_ea.upd(col_in => l_iea_coll, ignore_if_null_in => FALSE, rows_out => o_rowids);
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_icnp_interv_plan;

    PROCEDURE set_grid_task_icnp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_grid_task      grid_task%ROWTYPE;
        l_grid_task_betw grid_task_between%ROWTYPE;
    
        l_rowids table_varchar;
    
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
                                FROM (SELECT iei.id_episode, iei.id_patient
                                        FROM icnp_epis_intervention iei
                                       WHERE iei.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                            *
                                                             FROM TABLE(l_rowids) t)))
                LOOP
                    SELECT MAX(status_string) status_string, MAX(flg_icnp_interv) flg_icnp_interv
                      INTO l_grid_task.icnp_intervention, l_grid_task_betw.flg_icnp_interv
                      FROM (SELECT decode(rank,
                                          1,
                                          pk_utils.get_status_string(i_lang,
                                                                     i_prof,
                                                                     pk_ea_logic_interv_icnp.get_icnp_interv_status_str(i_prof,
                                                                                                                        flg_status,
                                                                                                                        flg_type,
                                                                                                                        flg_time,
                                                                                                                        dt_next_tstz,
                                                                                                                        dt_plan_tstz,
                                                                                                                        flg_prn,
                                                                                                                        id_order_recurr_option),
                                                                     pk_ea_logic_interv_icnp.get_icnp_interv_status_msg(i_prof,
                                                                                                                        flg_status,
                                                                                                                        flg_type,
                                                                                                                        flg_time,
                                                                                                                        dt_next_tstz,
                                                                                                                        dt_plan_tstz,
                                                                                                                        flg_prn,
                                                                                                                        id_order_recurr_option),
                                                                     pk_ea_logic_interv_icnp.get_icnp_interv_status_icon(i_prof,
                                                                                                                         flg_status,
                                                                                                                         flg_type,
                                                                                                                         flg_time,
                                                                                                                         dt_next_tstz,
                                                                                                                         dt_plan_tstz,
                                                                                                                         flg_prn,
                                                                                                                         id_order_recurr_option),
                                                                     pk_ea_logic_interv_icnp.get_icnp_interv_status_flg(i_prof,
                                                                                                                        flg_status,
                                                                                                                        flg_type,
                                                                                                                        flg_time,
                                                                                                                        dt_next_tstz,
                                                                                                                        dt_plan_tstz,
                                                                                                                        flg_prn,
                                                                                                                        id_order_recurr_option)),
                                          NULL) status_string,
                                   decode(rank,
                                          1,
                                          decode(flg_time, pk_alert_constant.g_flg_time_b, pk_alert_constant.g_yes),
                                          NULL) flg_icnp_interv
                              FROM (SELECT t.id_icnp_epis_interv,
                                           t.id_episode,
                                           t.flg_type,
                                           t.flg_time,
                                           t.flg_status,
                                           t.flg_prn,
                                           t.dt_plan_tstz,
                                           t.dt_next_tstz,
                                           t.id_order_recurr_option,
                                           row_number() over(ORDER BY t.rank) rank
                                      FROM (SELECT t.*,
                                                   decode(t.flg_status,
                                                          pk_icnp_constant.g_interv_plan_status_requested,
                                                          row_number() over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                                     'ICNP_EPIS_INTERVENTION.FLG_STATUS',
                                                                                     t.flg_status),
                                                               coalesce(t.dt_next_tstz, t.dt_plan_tstz)),
                                                          row_number()
                                                          over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                                     'ICNP_EPIS_INTERVENTION.FLG_STATUS',
                                                                                     t.flg_status),
                                                               coalesce(t.dt_next_tstz, t.dt_plan_tstz) DESC) + 20000) rank
                                              FROM (SELECT iei.id_icnp_epis_interv,
                                                           iei.id_episode,
                                                           iei.flg_type,
                                                           iei.flg_time,
                                                           iei.flg_status,
                                                           iei.flg_prn,
                                                           decode(iip.dt_plan_tstz,
                                                                  NULL,
                                                                  iei.dt_icnp_epis_interv_tstz,
                                                                  iip.dt_plan_tstz) dt_plan_tstz,
                                                           iei.dt_next_tstz,
                                                           orp.id_order_recurr_option
                                                      FROM icnp_epis_intervention iei,
                                                           (SELECT *
                                                              FROM (SELECT iip.id_icnp_epis_interv,
                                                                           iip.flg_status,
                                                                           iip.dt_plan_tstz,
                                                                           row_number() over(PARTITION BY iip.id_icnp_epis_interv ORDER BY iip.dt_plan_tstz) rn
                                                                      FROM icnp_interv_plan iip
                                                                     WHERE iip.flg_status IN
                                                                           (pk_icnp_constant.g_interv_plan_status_pending,
                                                                            pk_icnp_constant.g_interv_plan_status_requested))
                                                             WHERE rn = 1) iip,
                                                           episode e,
                                                           order_recurr_plan orp
                                                     WHERE iei.id_episode = r_cur.id_episode
                                                       AND iei.flg_status IN
                                                           (pk_icnp_constant.g_epis_interv_status_requested,
                                                            pk_icnp_constant.g_epis_interv_status_ongoing)
                                                       AND iei.flg_prn != pk_alert_constant.g_yes
                                                       AND iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                                                       AND iei.id_episode = e.id_episode
                                                       AND iei.id_order_recurr_plan = orp.id_order_recurr_plan(+)
                                                    UNION
                                                    SELECT iei.id_icnp_epis_interv,
                                                           iei.id_episode,
                                                           iei.flg_type,
                                                           iei.flg_time,
                                                           iei.flg_status,
                                                           iei.flg_prn,
                                                           decode(iip.dt_plan_tstz,
                                                                  NULL,
                                                                  iei.dt_icnp_epis_interv_tstz,
                                                                  iip.dt_plan_tstz) dt_plan_tstz,
                                                           iei.dt_next_tstz,
                                                           orp.id_order_recurr_option
                                                      FROM icnp_epis_intervention iei,
                                                           (SELECT *
                                                              FROM (SELECT iip.id_icnp_epis_interv,
                                                                           iip.flg_status,
                                                                           iip.dt_plan_tstz,
                                                                           row_number() over(PARTITION BY iip.id_icnp_epis_interv ORDER BY iip.dt_plan_tstz) rn
                                                                      FROM icnp_interv_plan iip
                                                                     WHERE iip.flg_status IN
                                                                           (pk_icnp_constant.g_interv_plan_status_pending,
                                                                            pk_icnp_constant.g_interv_plan_status_requested))
                                                             WHERE rn = 1) iip,
                                                           episode e,
                                                           order_recurr_plan orp
                                                     WHERE iei.id_episode = r_cur.id_episode
                                                       AND iei.flg_status IN
                                                           (pk_icnp_constant.g_epis_interv_status_requested,
                                                            pk_icnp_constant.g_epis_interv_status_ongoing)
                                                       AND iei.id_order_recurr_plan = orp.id_order_recurr_plan(+)
                                                       AND iei.flg_prn = pk_alert_constant.g_yes
                                                       AND iei.flg_time = pk_icnp_constant.g_epis_interv_time_next_epis
                                                       AND iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                                                       AND iei.id_episode = e.id_episode) t) t)
                             WHERE rank = 1) t;
                
                    g_error := 'GET SHORTCUT - DOCTOR';
                    IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_intern_name => 'GRID_ICNP_INTERV',
                                                     o_id_shortcut => l_shortcut,
                                                     o_error       => l_error_out)
                    THEN
                        l_shortcut := 0;
                    END IF;
                
                    IF l_grid_task.icnp_intervention IS NOT NULL
                    THEN
                        IF regexp_like(l_grid_task.icnp_intervention, '^\|D')
                        THEN
                            l_dt_str_1 := regexp_replace(l_grid_task.icnp_intervention,
                                                         '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*',
                                                         '\1');
                            l_dt_str_2 := regexp_replace(l_grid_task.icnp_intervention,
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
                                l_grid_task.icnp_intervention := regexp_replace(l_grid_task.icnp_intervention,
                                                                                l_dt_str_1,
                                                                                l_dt_1);
                            ELSE
                                l_grid_task.icnp_intervention := regexp_replace(l_grid_task.icnp_intervention,
                                                                                l_dt_str_1,
                                                                                l_dt_1);
                                l_grid_task.icnp_intervention := regexp_replace(l_grid_task.icnp_intervention,
                                                                                l_dt_str_2,
                                                                                l_dt_2);
                            END IF;
                        ELSE
                            l_dt_str_2                    := regexp_replace(l_grid_task.icnp_intervention,
                                                                            '^\|\w{0,2}\|.*\|(\d{14})\|.*',
                                                                            '\1');
                            l_dt_2                        := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                                                              i_prof,
                                                                                                                              l_dt_str_2,
                                                                                                                              NULL),
                                                                                                'YYYYMMDDHH24MISS TZR');
                            l_grid_task.icnp_intervention := regexp_replace(l_grid_task.icnp_intervention,
                                                                            l_dt_str_2,
                                                                            l_dt_2);
                        END IF;
                    
                        l_grid_task.icnp_intervention := l_shortcut || l_grid_task.icnp_intervention;
                    END IF;
                
                    l_grid_task.id_episode := r_cur.id_episode;
                
                    IF l_grid_task.id_episode IS NOT NULL
                    THEN
                        g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                        IF NOT pk_grid.update_grid_task(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_episode             => l_grid_task.id_episode,
                                                        icnp_intervention_in  => l_grid_task.icnp_intervention,
                                                        icnp_intervention_nin => FALSE,
                                                        o_error               => l_error_out)
                        THEN
                            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                        END IF;
                    
                        IF l_grid_task.icnp_intervention IS NULL
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
                
                    IF l_grid_task_betw.flg_icnp_interv = pk_alert_constant.g_yes
                    THEN
                        l_grid_task_betw.id_episode := r_cur.id_episode;
                    
                        --Actualiza estado da tarefa em GRID_TASK_BETWEEN para o episódio correspondente
                        g_error := 'CALL PK_GRID.UPDATE_NURSE_TASK';
                        IF NOT pk_grid.update_nurse_task(i_lang      => i_lang,
                                                         i_grid_task => l_grid_task_betw,
                                                         o_error     => l_error_out)
                        THEN
                            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => g_error);
    END set_grid_task_icnp;

    PROCEDURE set_task_timeline_interv
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
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
        l_flg_has_comments VARCHAR2(1 CHAR);
        l_timestamp        TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
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
                l_process_name  := 'UPDATE';
                l_event_into_ea := 'U';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' event type=' ||
                                  i_event_type || ' (' || 'INTERV_PRESC_PLAN' || ')',
                                  g_package_name,
                                  'SET_TASK_TIMELINE');
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                g_error := 'GET INTERV_PRESC_PLAN ROWIDS';
                get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => l_rowids);
            
                /*    SELECT \*+opt_estimate (table ipp rows=1)*\
                                               ipp.id_interv_presc_plan,
                                               ipp.start_time dt_begin,
                                               ipp.end_time dt_end,
                                               ipp.flg_status flg_status_det,
                                               ipp.id_prof_take,
                                               'INTERVENTION.CODE_INTERVENTION.' || ipd.id_intervention code_intervention,
                                               v.id_visit,
                                               ip.id_episode,
                                               v.id_patient,
                                               ip.id_institution,
                                               ipd.id_interv_presc_det,
                                               ipp.id_epis_documentation,
                                               ipp.notes,
                                               decode(ipp.flg_status,
                                                      pk_procedures_constant.g_interv_plan_pending,
                                                      pk_prog_notes_constants.g_task_ongoing_o,
                                                      pk_procedures_constant.g_interv_req,
                                                      pk_prog_notes_constants.g_task_ongoing_o,
                                                      pk_prog_notes_constants.g_task_finalized_f) flg_ongoing,
                                               pk_alert_constant.g_yes flg_normal,
                                               nvl((SELECT MAX(ea.dt_dg_last_update)
                                                     FROM procedures_ea ea
                                                    WHERE ea.id_interv_presc_det = ipd.id_interv_presc_det),
                                                   ip.dt_interv_prescription_tstz) dt_last_update,
                                               'INTERV_PRESC_PLAN.FLG_STATUS' code_status,
                                               ipd.flg_prn,
                                               ipp.dt_interv_presc_plan,
                                               ipp.dt_plan_tstz
                                                FROM interv_presc_det    ipd,
                                                     interv_prescription ip,
                                                     interv_presc_plan   ipp,
                                                     visit               v,
                                                     episode             e,
                                                     episode             ep_origin
                                               WHERE ipp.rowid IN (SELECT \*+opt_estimate (table t rows=1)*\
                                                                    *
                                                                     FROM TABLE(i_rowids) t)
                                                 AND ip.id_interv_prescription = ipd.id_interv_prescription
                                                 AND ipp.id_interv_presc_det = ipd.id_interv_presc_det
                                                 AND ip.id_episode = e.id_episode(+)
                                                 AND ip.id_episode_origin = ep_origin.id_episode(+)
                                                 AND e.id_visit = v.id_visit)        
                */
                FOR r_cur IN (
                              
                              SELECT itv.id_icnp_epis_interv,
                                      itv.dt_begin,
                                      itv.dt_close dt_end,
                                      itv.flg_status flg_status_det,
                                      itv.id_prof_take,
                                      'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || itv.id_composition_interv code_intervention,
                                      itv.id_visit,
                                      itv.id_episode,
                                      itv.id_patient,
                                      itv.id_institution,
                                      --ipd.id_interv_presc_det,
                                      --                               ipp.id_epis_documentation,
                                      itv.notes,
                                      pk_alert_constant.g_yes flg_normal,
                                      itv.dt_last_update dt_last_update,
                                      'ICNP_EPIS_INTERVENTION.FLG_STATUS' code_status,
                                      itv.flg_prn,
                                      --  ipp.dt_interv_presc_plan,
                                      itv.id_prof,
                                      itv.dt_plan,
                                      decode(itv.flg_status,
                                             pk_icnp_constant.g_epis_interv_status_ongoing,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_icnp_constant.g_epis_interv_status_requested,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_icnp_constant.g_epis_interv_status_suspended,
                                             pk_prog_notes_constants.g_task_inactive_i,
                                             pk_icnp_constant.g_epis_interv_status_discont,
                                             pk_prog_notes_constants.g_task_inactive_i,
                                             pk_icnp_constant.g_epis_interv_status_executed,
                                             pk_prog_notes_constants.g_task_finalized_f) flg_ongoing
                                FROM (SELECT /*+opt_estimate(table iei rows=1)*/
                                        iei.id_icnp_epis_interv,
                                        iei.id_composition id_composition_interv,
                                        ied.id_icnp_epis_diag,
                                        ied.id_composition id_composition_diag,
                                        iei.flg_time,
                                        iei.flg_status,
                                        iei.flg_type,
                                        iei.dt_next_tstz dt_next,
                                        decode((SELECT 1
                                                 FROM icnp_interv_plan i
                                                WHERE i.id_icnp_epis_interv = iei.id_icnp_epis_interv
                                                  AND rownum = 1
                                                  AND i.flg_status NOT IN
                                                      (pk_icnp_constant.g_epis_interv_status_requested,
                                                       pk_icnp_constant.g_epis_interv_status_cancelled,
                                                       pk_icnp_constant.g_epis_interv_status_modified)),
                                               1,
                                               decode(iip.dt_plan_tstz, NULL, iei.dt_icnp_epis_interv_tstz, iip.dt_plan_tstz),
                                               iip.dt_plan_tstz) dt_plan,
                                        (ici.flg_task || ici.id_vs) id_vs,
                                        iei.id_prof_close,
                                        iei.dt_close_tstz dt_close,
                                        iei.dt_icnp_epis_interv_tstz dt_icnp_epis_interv,
                                        iei.id_prof,
                                        iei.id_episode_origin,
                                        iei.id_episode,
                                        iei.id_patient,
                                        e.id_visit,
                                        e.id_institution,
                                        iip.flg_status flg_status_plan,
                                        nvl(iei.id_prof_close, iip.id_prof_take) id_prof_take,
                                        iei.freq,
                                        iei.notes,
                                        iei.notes_close,
                                        iei.dt_begin_tstz dt_begin,
                                        iei.dt_last_update,
                                        iei.flg_duration_unit,
                                        iei.duration,
                                        iei.num_take,
                                        iei.flg_interval_unit,
                                        iei.interval,
                                        nvl(iei.dt_close_tstz, iip.dt_take_tstz) dt_take_ea,
                                        iei.flg_prn,
                                        orp.id_order_recurr_option recurr_option,
                                        row_number() over(PARTITION BY iei.id_icnp_epis_interv ORDER BY --
                                        decode(iip.flg_status, pk_icnp_constant.g_interv_plan_status_pending, 1, pk_icnp_constant.g_interv_plan_status_requested, 1, 2), iip.dt_plan_tstz) rn
                                         FROM icnp_epis_intervention iei
                                         JOIN icnp_composition ici
                                           ON iei.id_composition = ici.id_composition
                                         JOIN episode e
                                           ON iei.id_episode = e.id_episode
                                         LEFT JOIN order_recurr_plan orp
                                           ON orp.id_order_recurr_plan = iei.id_order_recurr_plan
                                         LEFT JOIN icnp_epis_diag_interv iedi
                                           ON iei.id_icnp_epis_interv = iedi.id_icnp_epis_interv
                                         LEFT JOIN icnp_epis_diagnosis ied
                                           ON iedi.id_icnp_epis_diag = ied.id_icnp_epis_diag
                                         LEFT JOIN icnp_interv_plan iip
                                           ON iei.id_icnp_epis_interv = iip.id_icnp_epis_interv
                                          AND iip.flg_status IN
                                              (pk_icnp_constant.g_interv_plan_status_pending,
                                               pk_icnp_constant.g_interv_plan_status_requested,
                                               pk_icnp_constant.g_interv_plan_status_executed,
                                               pk_icnp_constant.g_interv_plan_status_suspended)
                                        WHERE iei.rowid IN (SELECT t.column_value row_id
                                                              FROM TABLE(i_rowids) t)
                                          AND iei.id_episode_destination IS NULL
                                          AND iei.forward_interv IS NULL) itv
                               WHERE itv.rn = 1)
                
                LOOP
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_nurse_intervention;
                    l_new_rec_row.table_name        := 'ICNP_EPIS_INTERVENTION';
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := l_timestamp;
                    l_new_rec_row.id_task_refid     := r_cur.id_icnp_epis_interv;
                    l_new_rec_row.dt_begin          := r_cur.dt_begin;
                    l_new_rec_row.dt_end            := r_cur.dt_end;
                    l_new_rec_row.flg_status_req    := r_cur.flg_status_det;
                    l_new_rec_row.id_prof_req       := r_cur.id_prof_take;
                    l_new_rec_row.dt_req            := nvl(r_cur.dt_plan, l_timestamp);
                    l_new_rec_row.id_patient        := r_cur.id_patient;
                    l_new_rec_row.id_episode        := r_cur.id_episode;
                    l_new_rec_row.id_visit          := r_cur.id_visit;
                    l_new_rec_row.id_institution    := r_cur.id_institution;
                    l_new_rec_row.code_description  := r_cur.code_intervention;
                    l_new_rec_row.flg_outdated      := l_flg_outdated;
                    --   l_new_rec_row.id_ref_group        := r_cur.id_interv_presc_det;
                    l_new_rec_row.universal_desc_clob := r_cur.notes;
                    --  l_new_rec_row.id_task_notes       := r_cur.id_epis_documentation;
                    l_new_rec_row.code_status    := r_cur.code_status;
                    l_new_rec_row.flg_ongoing    := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal     := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec   := r_cur.id_prof_take;
                    l_new_rec_row.dt_last_update := r_cur.dt_last_update;
                
                    IF r_cur.flg_prn = pk_alert_constant.g_yes
                    THEN
                        l_new_rec_row.flg_sos := pk_alert_constant.g_yes;
                    ELSE
                        l_new_rec_row.flg_sos := pk_alert_constant.g_no;
                    END IF;
                    /*                
                        --check if it has comments
                        BEGIN
                            SELECT pk_alert_constant.g_yes
                              INTO l_flg_has_comments
                              FROM treatment_management tm
                             WHERE tm.id_treatment = r_cur.id_interv_presc_det
                               AND rownum = 1;
                        EXCEPTION
                            WHEN no_data_found THEN
                    
                        END;
                    
                        
                    
                    /*
                    * Executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                    --    l_flg_has_comments := pk_alert_constant.g_no;
                    -- INSERT
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in          => l_new_rec_row,
                                                handle_error_in => FALSE,
                                                rows_out        => o_rowids);
                    
                        -- DELETE: Apenas podem ocorrer DELETE's nas tabelas INTERV_PRESCRIPTION e INTERV_PRESC_DET
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                        -- UPDATE
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    THEN
                        IF l_new_rec_row.flg_status_req IN
                           (pk_icnp_constant.g_epis_interv_status_ongoing,
                            pk_icnp_constant.g_epis_interv_status_requested,
                            pk_icnp_constant.g_epis_interv_status_suspended,
                            pk_icnp_constant.g_epis_interv_status_discont,
                            pk_icnp_constant.g_epis_interv_status_executed)
                        
                        THEN
                        
                            g_error := 'TS_TASK_TIMELINE_EA.UPD';
                            ts_task_timeline_ea.upd_ins(id_task_refid_in       => l_new_rec_row.id_task_refid,
                                                        id_tl_task_in          => l_new_rec_row.id_tl_task,
                                                        id_patient_in          => l_new_rec_row.id_patient,
                                                        id_episode_in          => l_new_rec_row.id_episode,
                                                        id_visit_in            => l_new_rec_row.id_visit,
                                                        id_institution_in      => l_new_rec_row.id_institution,
                                                        dt_dg_last_update_in   => l_new_rec_row.dt_dg_last_update,
                                                        dt_req_in              => l_new_rec_row.dt_req,
                                                        id_prof_req_in         => l_new_rec_row.id_prof_req,
                                                        dt_begin_in            => l_new_rec_row.dt_begin,
                                                        dt_end_in              => l_new_rec_row.dt_end,
                                                        flg_status_req_in      => l_new_rec_row.flg_status_req,
                                                        table_name_in          => l_new_rec_row.table_name,
                                                        flg_show_method_in     => l_new_rec_row.flg_show_method,
                                                        code_description_in    => l_new_rec_row.code_description,
                                                        universal_desc_clob_in => l_new_rec_row.universal_desc_clob,
                                                        flg_ongoing_in         => l_new_rec_row.flg_ongoing,
                                                        flg_normal_in          => l_new_rec_row.flg_normal,
                                                        id_prof_exec_in        => l_new_rec_row.id_prof_exec,
                                                        dt_last_update_in      => l_new_rec_row.dt_last_update,
                                                        flg_outdated_in        => l_new_rec_row.flg_outdated,
                                                        id_ref_group_in        => l_new_rec_row.id_ref_group,
                                                        code_status_in         => l_new_rec_row.code_status,
                                                        id_task_notes_in       => l_new_rec_row.id_task_notes,
                                                        flg_sos_in             => l_new_rec_row.flg_sos,
                                                        flg_has_comments_in    => l_new_rec_row.flg_has_comments,
                                                        rows_out               => o_rowids);
                        ELSE
                            g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                            ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' ||
                                                                          l_new_rec_row.id_task_refid ||
                                                                          ' AND id_tl_task = ' ||
                                                                          l_new_rec_row.id_tl_task,
                                                       rows_out        => o_rowids);
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
                                              'SET_TASK_TIMELINE_INTERV',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_task_timeline_interv;

    PROCEDURE set_task_timeline_diag
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
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
        l_flg_has_comments VARCHAR2(1 CHAR);
        l_timestamp        TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
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
                l_process_name  := 'UPDATE';
                l_event_into_ea := 'U';
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_process_name  := 'DELETE';
                l_event_into_ea := 'D';
            END IF;
        
            pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' event type=' ||
                                  i_event_type || ' (' || 'INTERV_PRESC_PLAN' || ')',
                                  g_package_name,
                                  'SET_TASK_TIMELINE');
        
            -- Loop through changed records
            g_error := 'LOOP PROCESS';
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                g_error := 'GET INTERV_PRESC_PLAN ROWIDS';
            
                FOR r_cur IN (
                              
                              SELECT itv.id_icnp_epis_diag,
                                      itv.dt_icnp_epis_diag,
                                      itv.dt_close dt_end,
                                      itv.flg_status flg_status_det,
                                      itv.id_prof_take,
                                      'ICNP_COMPOSITION.CODE_ICNP_COMPOSITION.' || itv.id_composition_diag code_diagnosis,
                                      itv.id_visit,
                                      itv.id_episode,
                                      itv.id_patient,
                                      itv.id_institution,
                                      --ipd.id_interv_presc_det,
                                      --                               ipp.id_epis_documentation,
                                      itv.notes,
                                      pk_alert_constant.g_yes flg_normal,
                                      itv.dt_last_update dt_last_update,
                                      'ICNP_EPIS_DIAGNOSIS.FLG_STATUS' code_status,
                                      itv.flg_prn,
                                      --  ipp.dt_interv_presc_plan,
                                      itv.id_professional,
                                      --itv.dt_plan,
                                      decode(itv.flg_status,
                                             pk_icnp_constant.g_epis_diag_status_active,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_icnp_constant.g_epis_diag_status_in_progress,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_icnp_constant.g_epis_diag_status_revaluated,
                                             pk_prog_notes_constants.g_task_ongoing_o,
                                             pk_icnp_constant.g_epis_diag_status_suspended,
                                             pk_prog_notes_constants.g_task_inactive_i,
                                             pk_icnp_constant.g_epis_diag_status_discontinue,
                                             pk_prog_notes_constants.g_task_inactive_i,
                                             pk_icnp_constant.g_epis_diag_status_resolved,
                                             pk_prog_notes_constants.g_task_finalized_f) flg_ongoing
                                FROM (SELECT /*+opt_estimate(table ied rows=1)*/
                                        ied.id_icnp_epis_diag,
                                        ied.id_composition id_composition_diag,
                                        --ieD.flg_time,
                                        ied.flg_status,
                                        --ieD.flg_type,
                                        --ieD.dt_next_tstz dt_next,
                                        --iip.dt_plan_tstz dt_plan,
                                        ied.id_prof_close,
                                        ied.dt_close_tstz          dt_close,
                                        ied.dt_icnp_epis_diag_tstz dt_icnp_epis_diag,
                                        ied.id_professional,
                                        --iei.id_episode_origin,
                                        ied.id_episode,
                                        ied.id_patient,
                                        e.id_visit,
                                        e.id_institution,
                                        --                                        iip.flg_status flg_status_plan,
                                        nvl(ied.id_prof_close, ied.id_prof_last_update) id_prof_take,
                                        ied.notes,
                                        ied.notes_close,
                                        --                                        nvl(ieD.dt_close_tstz, iip.dt_take_tstz) dt_take_ea,
                                        pk_alert_constant.g_no flg_prn,
                                        ied.dt_last_update,
                                        row_number() over(PARTITION BY ied.id_icnp_epis_diag ORDER BY --
                                        decode(ied.flg_status, pk_icnp_constant.g_interv_plan_status_pending, 1, pk_icnp_constant.g_interv_plan_status_requested, 1, 2), ied.dt_icnp_epis_diag_tstz) rn
                                         FROM icnp_epis_diagnosis ied
                                         JOIN icnp_composition ici
                                           ON ied.id_composition = ici.id_composition
                                         JOIN episode e
                                           ON ied.id_episode = e.id_episode
                                        WHERE ied.rowid IN (SELECT t.column_value row_id
                                                              FROM TABLE(i_rowids) t)) itv
                               WHERE itv.rn = 1)
                
                LOOP
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_nurse_diagnosis;
                    l_new_rec_row.table_name        := 'ICNP_EPIS_DIAGNOSIS';
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := l_timestamp;
                    l_new_rec_row.id_task_refid     := r_cur.id_icnp_epis_diag;
                    l_new_rec_row.dt_begin          := r_cur.dt_icnp_epis_diag;
                    l_new_rec_row.dt_end            := r_cur.dt_end;
                    l_new_rec_row.flg_status_req    := r_cur.flg_status_det;
                    l_new_rec_row.id_prof_req       := r_cur.id_prof_take;
                    l_new_rec_row.dt_req            := nvl(r_cur.dt_icnp_epis_diag, l_timestamp);
                    l_new_rec_row.id_patient        := r_cur.id_patient;
                    l_new_rec_row.id_episode        := r_cur.id_episode;
                    l_new_rec_row.id_visit          := r_cur.id_visit;
                    l_new_rec_row.id_institution    := r_cur.id_institution;
                    l_new_rec_row.code_description  := r_cur.code_diagnosis;
                    l_new_rec_row.flg_outdated      := l_flg_outdated;
                    --   l_new_rec_row.id_ref_group        := r_cur.id_interv_presc_det;
                    l_new_rec_row.universal_desc_clob := r_cur.notes;
                    --  l_new_rec_row.id_task_notes       := r_cur.id_epis_documentation;
                    l_new_rec_row.code_status    := r_cur.code_status;
                    l_new_rec_row.flg_ongoing    := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal     := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec   := r_cur.id_prof_take;
                    l_new_rec_row.dt_last_update := r_cur.dt_last_update;
                
                    IF r_cur.flg_prn = pk_alert_constant.g_yes
                    THEN
                        l_new_rec_row.flg_sos := pk_alert_constant.g_yes;
                    ELSE
                        l_new_rec_row.flg_sos := pk_alert_constant.g_no;
                    END IF;
                    l_new_rec_row.flg_has_comments := pk_alert_constant.g_no;
                
                    /* Executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    --    l_flg_has_comments := pk_alert_constant.g_no;
                    -- INSERT
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in          => l_new_rec_row,
                                                handle_error_in => FALSE,
                                                rows_out        => o_rowids);
                    
                        -- DELETE: Apenas podem ocorrer DELETE's nas tabelas INTERV_PRESCRIPTION e INTERV_PRESC_DET
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
                        -- UPDATE
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_update
                    THEN
                        IF l_new_rec_row.flg_status_req IN (
                                                            
                                                            pk_icnp_constant.g_epis_interv_status_ongoing,
                                                            pk_icnp_constant.g_epis_interv_status_requested,
                                                            pk_icnp_constant.g_epis_interv_status_suspended,
                                                            pk_icnp_constant.g_epis_interv_status_discont)
                        
                        THEN
                        
                            g_error := 'TS_TASK_TIMELINE_EA.UPD';
                            ts_task_timeline_ea.upd_ins(id_task_refid_in       => l_new_rec_row.id_task_refid,
                                                        id_tl_task_in          => l_new_rec_row.id_tl_task,
                                                        id_patient_in          => l_new_rec_row.id_patient,
                                                        id_episode_in          => l_new_rec_row.id_episode,
                                                        id_visit_in            => l_new_rec_row.id_visit,
                                                        id_institution_in      => l_new_rec_row.id_institution,
                                                        dt_dg_last_update_in   => l_new_rec_row.dt_dg_last_update,
                                                        dt_req_in              => l_new_rec_row.dt_req,
                                                        id_prof_req_in         => l_new_rec_row.id_prof_req,
                                                        dt_begin_in            => l_new_rec_row.dt_begin,
                                                        dt_end_in              => l_new_rec_row.dt_end,
                                                        flg_status_req_in      => l_new_rec_row.flg_status_req,
                                                        table_name_in          => l_new_rec_row.table_name,
                                                        flg_show_method_in     => l_new_rec_row.flg_show_method,
                                                        code_description_in    => l_new_rec_row.code_description,
                                                        universal_desc_clob_in => l_new_rec_row.universal_desc_clob,
                                                        flg_ongoing_in         => l_new_rec_row.flg_ongoing,
                                                        flg_normal_in          => l_new_rec_row.flg_normal,
                                                        id_prof_exec_in        => l_new_rec_row.id_prof_exec,
                                                        dt_last_update_in      => l_new_rec_row.dt_last_update,
                                                        flg_outdated_in        => l_new_rec_row.flg_outdated,
                                                        id_ref_group_in        => l_new_rec_row.id_ref_group,
                                                        code_status_in         => l_new_rec_row.code_status,
                                                        id_task_notes_in       => l_new_rec_row.id_task_notes,
                                                        flg_sos_in             => l_new_rec_row.flg_sos,
                                                        flg_has_comments_in    => l_new_rec_row.flg_has_comments,
                                                        rows_out               => o_rowids);
                        ELSE
                            g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                            ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' ||
                                                                          l_new_rec_row.id_task_refid ||
                                                                          ' AND id_tl_task = ' ||
                                                                          l_new_rec_row.id_tl_task,
                                                       rows_out        => o_rowids);
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
                                              'SET_TASK_TIMELINE_DIAG',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_task_timeline_diag;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_interv_icnp;
/
