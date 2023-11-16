/*-- Last Change Revision: $Rev: 2046859 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-10-04 14:19:35 +0100 (ter, 04 out 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_procedures IS

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

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
    
        IF i_table_name = 'INTERV_PRESCRIPTION'
        THEN
            SELECT ipd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_prescription IN
                   (SELECT /*+ opt_estimate(table ip rows=1) */
                     ip.id_interv_prescription
                      FROM interv_prescription ip
                     WHERE ip.rowid IN (SELECT /*+ opt_estimate(table t rows=1) */
                                         column_value
                                          FROM TABLE(i_rowids) t));
        
        ELSIF i_table_name = 'INTERV_PRESC_DET'
        THEN
            o_rowids := i_rowids;
        
        ELSIF i_table_name = 'INTERV_PRESC_PLAN'
        THEN
            SELECT ipd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det IN
                   (SELECT /*+ opt_estimate(table ipp rows=1) */
                     ipp.id_interv_presc_det
                      FROM interv_presc_plan ipp
                     WHERE ipp.rowid IN (SELECT /*+ opt_estimate(table t rows=1) */
                                          column_value
                                           FROM TABLE(i_rowids) t));
        
        ELSIF i_table_name = 'INTERV_MEDIA_ARCHIVE'
        THEN
            SELECT ipd.rowid
              BULK COLLECT
              INTO o_rowids
              FROM interv_presc_det ipd
             WHERE ipd.id_interv_presc_det IN
                   (SELECT /*+ opt_estimate (table ima rows=1) */
                     ima.id_interv_presc_det
                      FROM interv_media_archive ima
                     WHERE ima.rowid IN (SELECT /*+ opt_estimate (table t rows=1) */
                                          column_value
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

    PROCEDURE get_procedure_status
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE,
        o_status_str             OUT procedures_ea.status_str%TYPE,
        o_status_msg             OUT procedures_ea.status_msg%TYPE,
        o_status_icon            OUT procedures_ea.status_icon%TYPE,
        o_status_flg             OUT procedures_ea.status_flg%TYPE
    ) IS
    
        l_display_type  VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200) := '';
        l_icon_color    VARCHAR2(200) := '';
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
        IF i_dt_plan IS NULL
        THEN
            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                               nvl(i_dt_begin_req, i_dt_interv_prescription),
                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        ELSE
            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                               i_dt_plan,
                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        END IF;
    
        -- l_aux
        IF i_flg_referral IN (pk_procedures_constant.g_flg_referral_r,
                              pk_procedures_constant.g_flg_referral_s,
                              pk_procedures_constant.g_flg_referral_i)
        THEN
            l_aux := 'INTERV_PRESC_DET.FLG_REFERRAL';
        ELSE
            IF i_flg_prn = pk_procedures_constant.g_yes
            THEN
                l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
            ELSIF i_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_no_sched
                  AND i_flg_status_det = pk_procedures_constant.g_interv_req
            THEN
                l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
            ELSE
                IF i_flg_status_det IN (pk_procedures_constant.g_interv_draft,
                                        pk_procedures_constant.g_interv_finished,
                                        pk_procedures_constant.g_interv_not_ordered,
                                        pk_procedures_constant.g_interv_expired,
                                        pk_procedures_constant.g_interv_interrupted,
                                        pk_procedures_constant.g_interv_cancel)
                THEN
                    l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
                ELSIF i_flg_status_det = pk_procedures_constant.g_interv_exterior
                THEN
                    IF l_ref = pk_procedures_constant.g_yes
                    THEN
                        l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
                    ELSE
                        l_aux := 'INTERV_PRESC_DET.FLG_STATUS.PP';
                    END IF;
                ELSE
                    IF i_episode IS NOT NULL
                    THEN
                        IF i_flg_prn = pk_procedures_constant.g_yes
                        THEN
                            l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
                        ELSE
                            IF i_dt_plan IS NULL
                            THEN
                                l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
                            ELSE
                                l_aux := pk_date_utils.to_char_insttimezone(i_prof,
                                                                            nvl(i_dt_plan, i_dt_interv_prescription),
                                                                            pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                            END IF;
                        END IF;
                    ELSE
                        IF i_flg_status_det = pk_procedures_constant.g_interv_req
                        THEN
                            l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
                        ELSIF i_flg_status_det = pk_procedures_constant.g_interv_pending
                        THEN
                            IF i_dt_begin_req IS NULL
                            THEN
                                l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
                            ELSE
                                l_aux := pk_date_utils.to_char_insttimezone(i_prof,
                                                                            nvl(i_dt_plan, i_dt_interv_prescription),
                                                                            pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                            END IF;
                        ELSE
                            IF i_flg_prn = pk_procedures_constant.g_yes
                            THEN
                                l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
                            ELSE
                                IF i_flg_time = pk_procedures_constant.g_flg_time_n
                                THEN
                                    l_aux := 'INTERV_PRESC_DET.FLG_STATUS';
                                ELSE
                                    l_aux := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                nvl(i_dt_plan, i_dt_interv_prescription),
                                                                                pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- l_text
        l_text := l_aux;
    
        -- l_display_type
        IF i_flg_referral IN (pk_procedures_constant.g_flg_referral_r,
                              pk_procedures_constant.g_flg_referral_s,
                              pk_procedures_constant.g_flg_referral_i)
        THEN
            l_display_type := pk_alert_constant.g_display_type_icon;
        ELSE
            IF i_flg_prn = pk_procedures_constant.g_yes
            THEN
                l_display_type := pk_alert_constant.g_display_type_icon;
            ELSIF i_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_no_sched
                  AND i_flg_status_det = pk_procedures_constant.g_interv_req
            THEN
                l_display_type := pk_alert_constant.g_display_type_icon;
            ELSIF i_flg_status_det IN (pk_procedures_constant.g_interv_draft,
                                       pk_procedures_constant.g_interv_not_ordered,
                                       pk_procedures_constant.g_interv_finished,
                                       pk_procedures_constant.g_interv_expired,
                                       pk_procedures_constant.g_interv_interrupted,
                                       pk_procedures_constant.g_interv_cancel)
            THEN
                l_display_type := pk_alert_constant.g_display_type_icon;
            ELSIF i_flg_status_det = pk_procedures_constant.g_interv_exterior
            THEN
                IF l_ref = pk_procedures_constant.g_yes
                THEN
                    l_display_type := pk_alert_constant.g_display_type_date_icon;
                ELSE
                    l_display_type := pk_alert_constant.g_display_type_icon;
                END IF;
            ELSIF i_flg_status_det = pk_procedures_constant.g_interv_req
            THEN
                l_display_type := pk_alert_constant.g_display_type_date;
            ELSIF i_flg_status_det = pk_procedures_constant.g_interv_exec
            THEN
                IF i_dt_plan IS NOT NULL
                THEN
                    l_display_type := pk_alert_constant.g_display_type_date;
                ELSE
                    l_display_type := pk_alert_constant.g_display_type_icon;
                END IF;
            ELSE
            
                IF i_dt_plan IS NOT NULL
                THEN
                    l_display_type := pk_alert_constant.g_display_type_date;
                ELSE
                    l_display_type := pk_alert_constant.g_display_type_icon;
                END IF;
            END IF;
        END IF;
    
        -- l_back_color
        IF i_flg_referral IN (pk_procedures_constant.g_flg_referral_r,
                              pk_procedures_constant.g_flg_referral_s,
                              pk_procedures_constant.g_flg_referral_i)
        THEN
            l_back_color := pk_alert_constant.g_color_null;
        ELSE
            IF i_flg_prn = pk_procedures_constant.g_yes
            THEN
                l_back_color := pk_alert_constant.g_color_null;
            ELSIF i_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_no_sched
                  AND i_flg_status_det = pk_procedures_constant.g_interv_req
            THEN
                l_back_color := pk_alert_constant.g_color_green;
            ELSIF i_flg_status_det IN (pk_procedures_constant.g_interv_draft,
                                       pk_procedures_constant.g_interv_expired,
                                       pk_procedures_constant.g_interv_not_ordered,
                                       pk_procedures_constant.g_interv_finished,
                                       pk_procedures_constant.g_interv_cancel,
                                       pk_procedures_constant.g_interv_interrupted)
            THEN
                l_back_color := pk_alert_constant.g_color_null;
            ELSIF i_flg_status_det = pk_procedures_constant.g_interv_exterior
            THEN
                IF l_ref = pk_procedures_constant.g_yes
                THEN
                    l_back_color := pk_alert_constant.g_color_red;
                ELSE
                    l_back_color := pk_alert_constant.g_color_null;
                END IF;
            ELSE
                IF i_episode IS NOT NULL
                THEN
                    IF i_dt_begin_req IS NULL
                    THEN
                        IF i_flg_time = pk_procedures_constant.g_flg_time_b
                        THEN
                            l_back_color := pk_alert_constant.g_color_null;
                        ELSE
                            l_back_color := pk_alert_constant.g_color_red;
                        END IF;
                    ELSE
                        l_back_color := pk_alert_constant.g_color_null;
                    END IF;
                ELSE
                    IF i_dt_begin_req IS NULL
                    THEN
                        IF i_flg_time = pk_procedures_constant.g_flg_time_b
                        THEN
                            l_back_color := pk_alert_constant.g_color_null;
                        ELSE
                            l_back_color := pk_alert_constant.g_color_green;
                        END IF;
                    ELSE
                        l_back_color := pk_alert_constant.g_color_null;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- l_status_flg
        IF i_flg_referral IN (pk_procedures_constant.g_flg_referral_r,
                              pk_procedures_constant.g_flg_referral_s,
                              pk_procedures_constant.g_flg_referral_i)
        THEN
            l_status_flg := i_flg_referral;
        ELSE
            IF i_flg_status_det IN (pk_procedures_constant.g_interv_draft,
                                    pk_procedures_constant.g_interv_exterior,
                                    pk_procedures_constant.g_interv_exec,
                                    pk_procedures_constant.g_interv_not_ordered,
                                    pk_procedures_constant.g_interv_finished,
                                    pk_procedures_constant.g_interv_expired,
                                    pk_procedures_constant.g_interv_interrupted,
                                    pk_procedures_constant.g_interv_cancel)
            THEN
                l_status_flg := i_flg_status_det;
            ELSIF i_flg_status_det = pk_procedures_constant.g_interv_req
            THEN
                IF i_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_no_sched
                THEN
                    l_status_flg := i_flg_status_det;
                ELSE
                    l_status_flg := NULL;
                END IF;
            ELSE
                IF i_episode IS NOT NULL
                THEN
                    IF i_flg_prn = pk_procedures_constant.g_yes
                    THEN
                        l_status_flg := i_flg_status_det;
                    ELSE
                        IF i_dt_plan IS NULL
                        THEN
                            l_status_flg := i_flg_status_det;
                        ELSE
                            l_status_flg := NULL;
                        END IF;
                    END IF;
                ELSE
                    IF i_flg_prn = pk_procedures_constant.g_yes
                    THEN
                        l_status_flg := i_flg_status_det;
                    ELSIF i_flg_time = pk_procedures_constant.g_flg_time_n
                    THEN
                        IF i_dt_begin_req IS NULL
                        THEN
                            l_status_flg := i_flg_status_det;
                        ELSE
                            l_status_flg := NULL;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- l_icon_color
        IF i_flg_prn = pk_procedures_constant.g_yes
        THEN
            l_icon_color := pk_alert_constant.g_color_icon_dark_grey;
        ELSIF i_order_recurr_option = pk_order_recurrence_core.g_order_recurr_option_no_sched
              AND i_flg_status_det = pk_procedures_constant.g_interv_req
        THEN
            l_icon_color := pk_alert_constant.g_color_icon_light_grey;
        ELSIF i_flg_time = pk_procedures_constant.g_flg_time_n
        THEN
            l_icon_color := pk_alert_constant.g_color_icon_light_grey;
        ELSE
            l_icon_color := '';
        END IF;
    
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_status_flg,
                                     i_value_text    => l_aux,
                                     i_value_date    => nvl(l_date_begin, l_aux),
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
    END get_procedure_status;

    FUNCTION get_procedure_status_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  procedures_ea.status_str%TYPE;
        l_status_msg  procedures_ea.status_msg%TYPE;
        l_status_icon procedures_ea.status_icon%TYPE;
        l_status_flg  procedures_ea.status_flg%TYPE;
    
    BEGIN
    
        get_procedure_status(i_lang                   => i_lang,
                             i_prof                   => i_prof,
                             i_episode                => i_episode,
                             i_flg_time               => i_flg_time,
                             i_flg_status_det         => i_flg_status_det,
                             i_flg_prn                => i_flg_prn,
                             i_flg_referral           => i_flg_referral,
                             i_dt_interv_prescription => i_dt_interv_prescription,
                             i_dt_begin_req           => i_dt_begin_req,
                             i_dt_plan                => i_dt_plan,
                             i_order_recurr_option    => i_order_recurr_option,
                             o_status_str             => l_status_str,
                             o_status_msg             => l_status_msg,
                             o_status_icon            => l_status_icon,
                             o_status_flg             => l_status_flg);
    
        RETURN l_status_str;
    
    END get_procedure_status_str;

    FUNCTION get_procedure_status_msg
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  procedures_ea.status_str%TYPE;
        l_status_msg  procedures_ea.status_msg%TYPE;
        l_status_icon procedures_ea.status_icon%TYPE;
        l_status_flg  procedures_ea.status_flg%TYPE;
    
    BEGIN
    
        get_procedure_status(i_lang                   => i_lang,
                             i_prof                   => i_prof,
                             i_episode                => i_episode,
                             i_flg_time               => i_flg_time,
                             i_flg_status_det         => i_flg_status_det,
                             i_flg_prn                => i_flg_prn,
                             i_flg_referral           => i_flg_referral,
                             i_dt_interv_prescription => i_dt_interv_prescription,
                             i_dt_begin_req           => i_dt_begin_req,
                             i_dt_plan                => i_dt_plan,
                             i_order_recurr_option    => i_order_recurr_option,
                             o_status_str             => l_status_str,
                             o_status_msg             => l_status_msg,
                             o_status_icon            => l_status_icon,
                             o_status_flg             => l_status_flg);
        RETURN l_status_msg;
    
    END get_procedure_status_msg;

    FUNCTION get_procedure_status_icon
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  procedures_ea.status_str%TYPE;
        l_status_msg  procedures_ea.status_msg%TYPE;
        l_status_icon procedures_ea.status_icon%TYPE;
        l_status_flg  procedures_ea.status_flg%TYPE;
    
    BEGIN
    
        get_procedure_status(i_lang                   => i_lang,
                             i_prof                   => i_prof,
                             i_episode                => i_episode,
                             i_flg_time               => i_flg_time,
                             i_flg_status_det         => i_flg_status_det,
                             i_flg_prn                => i_flg_prn,
                             i_flg_referral           => i_flg_referral,
                             i_dt_interv_prescription => i_dt_interv_prescription,
                             i_dt_begin_req           => i_dt_begin_req,
                             i_dt_plan                => i_dt_plan,
                             i_order_recurr_option    => i_order_recurr_option,
                             o_status_str             => l_status_str,
                             o_status_msg             => l_status_msg,
                             o_status_icon            => l_status_icon,
                             o_status_flg             => l_status_flg);
    
        RETURN l_status_icon;
    
    END get_procedure_status_icon;

    FUNCTION get_procedure_status_flg
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  procedures_ea.status_str%TYPE;
        l_status_msg  procedures_ea.status_msg%TYPE;
        l_status_icon procedures_ea.status_icon%TYPE;
        l_status_flg  procedures_ea.status_flg%TYPE;
    
    BEGIN
    
        get_procedure_status(i_lang                   => i_lang,
                             i_prof                   => i_prof,
                             i_episode                => i_episode,
                             i_flg_time               => i_flg_time,
                             i_flg_status_det         => i_flg_status_det,
                             i_flg_prn                => i_flg_prn,
                             i_flg_referral           => i_flg_referral,
                             i_dt_interv_prescription => i_dt_interv_prescription,
                             i_dt_begin_req           => i_dt_begin_req,
                             i_dt_plan                => i_dt_plan,
                             i_order_recurr_option    => i_order_recurr_option,
                             o_status_str             => l_status_str,
                             o_status_msg             => l_status_msg,
                             o_status_icon            => l_status_icon,
                             o_status_flg             => l_status_flg);
    
        RETURN l_status_flg;
    
    END get_procedure_status_flg;

    PROCEDURE get_procedure_plan_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan     IN interv_presc_plan.dt_plan_tstz%TYPE,
        o_status_str  OUT VARCHAR2,
        o_status_msg  OUT VARCHAR2,
        o_status_icon OUT VARCHAR2,
        o_status_flg  OUT VARCHAR2
    ) IS
    
        l_display_type  VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200) := '';
        l_status_flg    VARCHAR2(200) := '';
        l_message_style VARCHAR2(200) := '';
        l_message_color VARCHAR2(200) := '';
        l_default_color VARCHAR2(200) := '';
        -- icon
        l_aux VARCHAR2(200);
        -- date
        l_date_begin VARCHAR2(200);
    
    BEGIN
    
        -- l_date_begin
        IF i_dt_plan IS NULL
        THEN
            l_date_begin := NULL;
        ELSE
            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                               i_dt_plan,
                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        END IF;
    
        -- l_aux
        IF i_flg_status IN (pk_procedures_constant.g_interv_plan_executed,
                            pk_procedures_constant.g_interv_plan_not_executed,
                            pk_procedures_constant.g_interv_plan_expired,
                            pk_procedures_constant.g_interv_plan_cancel)
           OR i_dt_plan IS NULL
        THEN
            l_aux := 'INTERV_PRESC_PLAN.FLG_STATUS';
        ELSE
            l_aux := pk_date_utils.to_char_insttimezone(i_prof, i_dt_plan, pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        END IF;
    
        -- l_display_type
        IF i_flg_status IN (pk_procedures_constant.g_interv_plan_executed,
                            pk_procedures_constant.g_interv_plan_not_executed,
                            pk_procedures_constant.g_interv_plan_expired,
                            pk_procedures_constant.g_interv_plan_cancel)
           OR i_dt_plan IS NULL
        THEN
            l_display_type := pk_alert_constant.g_display_type_icon;
        ELSE
            l_display_type := pk_alert_constant.g_display_type_date;
        END IF;
    
        -- l_back_color
        l_back_color := pk_alert_constant.g_color_null;
    
        -- l_status_flg
        IF i_flg_status IN (pk_procedures_constant.g_interv_plan_executed,
                            pk_procedures_constant.g_interv_plan_not_executed,
                            pk_procedures_constant.g_interv_plan_expired,
                            pk_procedures_constant.g_interv_plan_cancel)
           OR i_dt_plan IS NULL
        THEN
            l_status_flg := i_flg_status;
        ELSE
            l_status_flg := NULL;
        END IF;
    
        -- l_message_style
        l_message_style := NULL;
    
        pk_utils.build_status_string(i_display_type  => l_display_type,
                                     i_flg_state     => l_status_flg,
                                     i_value_text    => l_aux,
                                     i_value_date    => nvl(l_date_begin, l_aux),
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
    END get_procedure_plan_status;

    FUNCTION get_procedure_plan_status_str
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan    IN interv_presc_plan.dt_plan_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(200);
    
    BEGIN
    
        get_procedure_plan_status(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_flg_status  => i_flg_status,
                                  i_dt_plan     => i_dt_plan,
                                  o_status_str  => l_status_str,
                                  o_status_msg  => l_status_msg,
                                  o_status_icon => l_status_icon,
                                  o_status_flg  => l_status_flg);
    
        RETURN l_status_str;
    
    END get_procedure_plan_status_str;

    FUNCTION get_procedure_plan_status_msg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan    IN interv_presc_plan.dt_plan_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(200);
    
    BEGIN
    
        get_procedure_plan_status(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_flg_status  => i_flg_status,
                                  i_dt_plan     => i_dt_plan,
                                  o_status_str  => l_status_str,
                                  o_status_msg  => l_status_msg,
                                  o_status_icon => l_status_icon,
                                  o_status_flg  => l_status_flg);
        RETURN l_status_msg;
    
    END get_procedure_plan_status_msg;

    FUNCTION get_procedure_plan_status_icon
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan    IN interv_presc_plan.dt_plan_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(200);
    
    BEGIN
    
        get_procedure_plan_status(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_flg_status  => i_flg_status,
                                  i_dt_plan     => i_dt_plan,
                                  o_status_str  => l_status_str,
                                  o_status_msg  => l_status_msg,
                                  o_status_icon => l_status_icon,
                                  o_status_flg  => l_status_flg);
    
        RETURN l_status_icon;
    
    END get_procedure_plan_status_icon;

    FUNCTION get_procedure_plan_status_flg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN interv_presc_plan.flg_status%TYPE,
        i_dt_plan    IN interv_presc_plan.dt_plan_tstz%TYPE
    ) RETURN VARCHAR2 IS
    
        l_status_str  VARCHAR2(200);
        l_status_msg  VARCHAR2(200);
        l_status_icon VARCHAR2(200);
        l_status_flg  VARCHAR2(200);
    
    BEGIN
    
        get_procedure_plan_status(i_lang        => i_lang,
                                  i_prof        => i_prof,
                                  i_flg_status  => i_flg_status,
                                  i_dt_plan     => i_dt_plan,
                                  o_status_str  => l_status_str,
                                  o_status_msg  => l_status_msg,
                                  o_status_icon => l_status_icon,
                                  o_status_flg  => l_status_flg);
    
        RETURN l_status_flg;
    
    END get_procedure_plan_status_flg;

    FUNCTION get_procedure_status_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN procedures_ea.id_episode%TYPE,
        i_flg_time               IN procedures_ea.flg_time%TYPE,
        i_flg_status_det         IN procedures_ea.flg_status_det%TYPE,
        i_flg_prn                IN procedures_ea.flg_prn%TYPE,
        i_flg_referral           IN procedures_ea.flg_referral%TYPE,
        i_dt_interv_prescription IN procedures_ea.dt_interv_prescription%TYPE,
        i_dt_begin_req           IN procedures_ea.dt_begin_req%TYPE,
        i_dt_plan                IN procedures_ea.dt_plan%TYPE,
        i_order_recurr_option    IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN table_ea_struct IS
        l_status_str  procedures_ea.status_str%TYPE;
        l_status_msg  procedures_ea.status_msg%TYPE;
        l_status_icon procedures_ea.status_icon%TYPE;
        l_status_flg  procedures_ea.status_flg%TYPE;
    
        l_table_ea_struct table_ea_struct := table_ea_struct(NULL);
    
    BEGIN
        get_procedure_status(i_lang                   => i_lang,
                             i_prof                   => i_prof,
                             i_episode                => i_episode,
                             i_flg_time               => i_flg_time,
                             i_flg_status_det         => i_flg_status_det,
                             i_flg_prn                => i_flg_prn,
                             i_flg_referral           => i_flg_referral,
                             i_dt_interv_prescription => i_dt_interv_prescription,
                             i_dt_begin_req           => i_dt_begin_req,
                             i_dt_plan                => i_dt_plan,
                             i_order_recurr_option    => i_order_recurr_option,
                             o_status_str             => l_status_str,
                             o_status_msg             => l_status_msg,
                             o_status_icon            => l_status_icon,
                             o_status_flg             => l_status_flg);
    
        SELECT t_ea_struct(l_status_str, l_status_msg, l_status_icon, l_status_flg)
          BULK COLLECT
          INTO l_table_ea_struct
          FROM (SELECT l_status_str, l_status_msg, l_status_icon, l_status_flg
                  FROM dual);
    
        RETURN l_table_ea_struct;
    END get_procedure_status_all;

    PROCEDURE set_procedures
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_new_rec_row procedures_ea%ROWTYPE;
        l_rowids      table_varchar;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_error := 'GET PROCEDURES ROWIDS';
        get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
    
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => l_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => i_source_table_name,
                                                 i_expected_dg_table_name => 'PROCEDURES_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Process insert event
        IF i_event_type IN (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update)
        THEN
            -- Loop through changed records
            g_error := 'LOOP INSERTED';
            IF l_rowids IS NOT NULL
               AND l_rowids.count > 0
            THEN
                FOR r_cur IN (SELECT *
                                FROM (SELECT row_number() over(PARTITION BY ipp.id_interv_presc_det ORDER BY ipp.exec_number DESC, ipp.dt_interv_presc_plan DESC) rn,
                                             ipd.id_interv_prescription,
                                             ipd.id_interv_presc_det,
                                             ipp.id_interv_presc_plan,
                                             ipd.id_intervention,
                                             i.flg_status flg_status_intervention,
                                             ip.flg_status flg_status_req,
                                             ipd.flg_status flg_status_det,
                                             ipp.flg_status flg_status_plan,
                                             ipd.code_intervention_alias,
                                             ipd.id_interv_codification,
                                             ip.flg_time,
                                             ipd.flg_referral,
                                             ipd.flg_prty,
                                             ipd.flg_prn,
                                             ipd.id_order_recurrence,
                                             orp.id_order_recurr_option,
                                             ip.dt_begin_tstz dt_begin_req,
                                             ipd.dt_begin_tstz dt_begin_det,
                                             ip.dt_interv_prescription_tstz,
                                             ipd.dt_interv_presc_det,
                                             ipp.dt_plan_tstz,
                                             ip.id_professional,
                                             decode(ipd.notes,
                                                    NULL,
                                                    pk_procedures_constant.g_no,
                                                    pk_procedures_constant.g_yes) flg_notes,
                                             decode((SELECT 1
                                                      FROM interv_media_archive ima
                                                     WHERE ima.id_interv_presc_det = ipd.id_interv_presc_det
                                                       AND ima.flg_type =
                                                           pk_procedures_constant.g_media_archive_interv_doc
                                                       AND ima.flg_status = pk_procedures_constant.g_active
                                                       AND rownum = 1),
                                                    1,
                                                    pk_procedures_constant.g_yes,
                                                    pk_procedures_constant.g_no) flg_doc,
                                             ipd.id_clinical_purpose,
                                             ipd.clinical_purpose_notes,
                                             ipd.flg_laterality,
                                             cs.id_prof_ordered_by id_prof_order,
                                             nvl(cs.dt_ordered_by, ipd.dt_order_tstz) dt_order,
                                             NULL id_task_dependency,
                                             ipd.flg_req_origin_module,
                                             ipd.notes,
                                             ipd.notes_cancel,
                                             ip.id_patient,
                                             v.id_visit,
                                             ip.id_episode,
                                             ip.id_episode_origin,
                                             ipd.flg_location
                                        FROM intervention i,
                                             interv_prescription ip,
                                             (SELECT /*+opt_estimate (table ipd rows=1)*/
                                               *
                                                FROM interv_presc_det ipd
                                               WHERE ipd.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                    *
                                                                     FROM TABLE(l_rowids) t)
                                                 AND ipd.flg_status != pk_procedures_constant.g_interv_predefined) ipd,
                                             interv_presc_plan ipp,
                                             order_recurr_plan orp,
                                             co_sign_hist cs,
                                             episode e,
                                             episode e_origin,
                                             visit v
                                       WHERE ipd.id_interv_prescription = ip.id_interv_prescription
                                         AND ipd.id_interv_presc_det = ipp.id_interv_presc_det(+)
                                         AND ipd.id_order_recurrence = orp.id_order_recurr_plan(+)
                                         AND ipd.id_co_sign_order = cs.id_co_sign_hist(+)
                                         AND ipd.id_intervention = i.id_intervention
                                         AND ip.id_episode = e.id_episode(+)
                                         AND ip.id_episode_origin = e_origin.id_episode(+)
                                         AND e.id_visit = v.id_visit(+))
                               WHERE rn = 1)
                LOOP
                    g_error := 'GET PROCEDURE STATUS';
                    pk_ea_logic_procedures.get_procedure_status(i_lang                   => i_lang,
                                                                i_prof                   => i_prof,
                                                                i_episode                => r_cur.id_episode,
                                                                i_flg_time               => r_cur.flg_time,
                                                                i_flg_status_det         => r_cur.flg_status_det,
                                                                i_flg_prn                => r_cur.flg_prn,
                                                                i_flg_referral           => r_cur.flg_referral,
                                                                i_dt_interv_prescription => r_cur.dt_interv_prescription_tstz,
                                                                i_dt_begin_req           => r_cur.dt_begin_req,
                                                                i_dt_plan                => r_cur.dt_plan_tstz,
                                                                i_order_recurr_option    => r_cur.id_order_recurr_option,
                                                                o_status_str             => l_new_rec_row.status_str,
                                                                o_status_msg             => l_new_rec_row.status_msg,
                                                                o_status_icon            => l_new_rec_row.status_icon,
                                                                o_status_flg             => l_new_rec_row.status_flg);
                
                    g_error                               := 'DEFINE new record for PROCEDURES_EA';
                    l_new_rec_row.id_interv_prescription  := r_cur.id_interv_prescription;
                    l_new_rec_row.id_interv_presc_det     := r_cur.id_interv_presc_det;
                    l_new_rec_row.id_interv_presc_plan    := r_cur.id_interv_presc_plan;
                    l_new_rec_row.id_intervention         := r_cur.id_intervention;
                    l_new_rec_row.flg_status_intervention := r_cur.flg_status_intervention;
                    l_new_rec_row.flg_status_req          := r_cur.flg_status_req;
                    l_new_rec_row.flg_status_det          := r_cur.flg_status_det;
                    l_new_rec_row.flg_status_plan         := r_cur.flg_status_plan;
                    l_new_rec_row.code_intervention_alias := r_cur.code_intervention_alias;
                    l_new_rec_row.id_interv_codification  := r_cur.id_interv_codification;
                    l_new_rec_row.flg_time                := r_cur.flg_time;
                    l_new_rec_row.flg_referral            := r_cur.flg_referral;
                    l_new_rec_row.flg_prty                := r_cur.flg_prty;
                    l_new_rec_row.flg_prn                 := r_cur.flg_prn;
                    l_new_rec_row.id_order_recurrence     := r_cur.id_order_recurrence;
                    l_new_rec_row.dt_begin_req            := r_cur.dt_begin_req;
                    l_new_rec_row.dt_begin_det            := r_cur.dt_begin_det;
                    l_new_rec_row.dt_interv_prescription  := r_cur.dt_interv_prescription_tstz;
                    l_new_rec_row.dt_interv_presc_det     := r_cur.dt_interv_presc_det;
                    l_new_rec_row.dt_plan                 := r_cur.dt_plan_tstz;
                    l_new_rec_row.id_professional         := r_cur.id_professional;
                    l_new_rec_row.flg_notes               := r_cur.flg_notes;
                    l_new_rec_row.flg_doc                 := r_cur.flg_doc;
                    l_new_rec_row.id_clinical_purpose     := r_cur.id_clinical_purpose;
                    l_new_rec_row.clinical_purpose_notes  := r_cur.clinical_purpose_notes;
                    l_new_rec_row.flg_laterality          := r_cur.flg_laterality;
                    l_new_rec_row.id_prof_order           := r_cur.id_prof_order;
                    l_new_rec_row.dt_order                := r_cur.dt_order;
                    l_new_rec_row.id_task_dependency      := r_cur.id_task_dependency;
                    l_new_rec_row.flg_req_origin_module   := r_cur.flg_req_origin_module;
                    l_new_rec_row.notes                   := r_cur.notes;
                    l_new_rec_row.notes_cancel            := r_cur.notes_cancel;
                    l_new_rec_row.id_patient              := r_cur.id_patient;
                    l_new_rec_row.id_visit                := r_cur.id_visit;
                    l_new_rec_row.id_episode              := r_cur.id_episode;
                    l_new_rec_row.id_episode_origin       := r_cur.id_episode_origin;
                    l_new_rec_row.flg_location            := r_cur.flg_location;
                
                    g_error := 'TS_PROCEDURES_EA.UPD';
                    IF i_source_table_name = 'INTERV_PRESC_DET'
                       AND i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                        ts_procedures_ea.ins(rec_in => l_new_rec_row, rows_out => l_rows_out);
                    ELSE
                        g_error := 'ts_procedures_ea.upd';
                        ts_procedures_ea.upd(id_interv_presc_det_in     => l_new_rec_row.id_interv_presc_det,
                                             id_interv_prescription_in  => l_new_rec_row.id_interv_prescription,
                                             id_interv_presc_plan_in    => l_new_rec_row.id_interv_presc_plan,
                                             id_intervention_in         => l_new_rec_row.id_intervention,
                                             flg_status_intervention_in => l_new_rec_row.flg_status_intervention,
                                             flg_status_req_in          => l_new_rec_row.flg_status_req,
                                             flg_status_det_in          => l_new_rec_row.flg_status_det,
                                             flg_status_plan_in         => l_new_rec_row.flg_status_plan,
                                             code_intervention_alias_in => l_new_rec_row.code_intervention_alias,
                                             id_interv_codification_in  => l_new_rec_row.id_interv_codification,
                                             flg_time_in                => l_new_rec_row.flg_time,
                                             flg_referral_in            => l_new_rec_row.flg_referral,
                                             flg_prty_in                => l_new_rec_row.flg_prty,
                                             id_order_recurrence_in     => l_new_rec_row.id_order_recurrence,
                                             id_order_recurrence_nin    => FALSE,
                                             dt_begin_req_in            => l_new_rec_row.dt_begin_req,
                                             dt_begin_det_in            => l_new_rec_row.dt_begin_det,
                                             dt_interv_prescription_in  => l_new_rec_row.dt_interv_prescription,
                                             dt_interv_presc_det_in     => l_new_rec_row.dt_interv_presc_det,
                                             dt_plan_in                 => l_new_rec_row.dt_plan,
                                             id_professional_in         => l_new_rec_row.id_professional,
                                             flg_notes_in               => l_new_rec_row.flg_notes,
                                             flg_doc_in                 => l_new_rec_row.flg_doc,
                                             id_clinical_purpose_in     => l_new_rec_row.id_clinical_purpose,
                                             id_clinical_purpose_nin    => FALSE,
                                             clinical_purpose_notes_in  => l_new_rec_row.clinical_purpose_notes,
                                             clinical_purpose_notes_nin => FALSE,
                                             flg_laterality_in          => l_new_rec_row.flg_laterality,
                                             flg_laterality_nin         => FALSE,
                                             id_prof_order_in           => l_new_rec_row.id_prof_order,
                                             id_prof_order_nin          => FALSE,
                                             dt_order_in                => l_new_rec_row.dt_order,
                                             dt_order_nin               => FALSE,
                                             id_task_dependency_in      => l_new_rec_row.id_task_dependency,
                                             flg_req_origin_module_in   => l_new_rec_row.flg_req_origin_module,
                                             notes_in                   => l_new_rec_row.notes,
                                             notes_nin                  => FALSE,
                                             notes_cancel_in            => l_new_rec_row.notes_cancel,
                                             notes_cancel_nin           => FALSE,
                                             id_patient_in              => l_new_rec_row.id_patient,
                                             id_visit_in                => l_new_rec_row.id_visit,
                                             id_episode_in              => l_new_rec_row.id_episode,
                                             id_episode_origin_in       => l_new_rec_row.id_episode_origin,
                                             status_str_in              => l_new_rec_row.status_str,
                                             status_str_nin             => FALSE,
                                             status_msg_in              => l_new_rec_row.status_msg,
                                             status_msg_nin             => FALSE,
                                             status_icon_in             => l_new_rec_row.status_icon,
                                             status_icon_nin            => FALSE,
                                             status_flg_in              => l_new_rec_row.status_flg,
                                             status_flg_nin             => FALSE,
                                             flg_location_in            => l_new_rec_row.flg_location,
                                             flg_location_nin           => FALSE,
                                             rows_out                   => l_rows_out);
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            ROLLBACK;
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            -- Unexpected error.
            ROLLBACK;
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
        
    END set_procedures;

    FUNCTION set_grid_task_procedures_across
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_grid_task      grid_task%ROWTYPE;
        l_grid_task_betw grid_task_between%ROWTYPE;
    
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    
        l_dt_str_1 VARCHAR2(200 CHAR);
        l_dt_str_2 VARCHAR2(200 CHAR);
    
        l_dt_1 VARCHAR2(200 CHAR);
        l_dt_2 VARCHAR2(200 CHAR);
    
    BEGIN
    
        FOR r_cur IN (SELECT e.id_episode, e.id_patient
                        FROM episode e
                       WHERE e.id_patient = i_patient
                         AND EXISTS (SELECT 1
                                FROM interv_prescription ip
                               WHERE ip.flg_time IN (pk_procedures_constant.g_flg_time_a,
                                                     pk_procedures_constant.g_flg_time_h)
                                 AND ip.id_patient = i_patient))
        LOOP
            SELECT MAX(status_string) status_string, MAX(flg_interv) flg_interv
              INTO l_grid_task.intervention, l_grid_task_betw.flg_interv
              FROM (SELECT decode(rank,
                                  1,
                                  pk_utils.get_status_string(i_lang,
                                                             i_prof,
                                                             pk_ea_logic_procedures.get_procedure_status_str(i_lang,
                                                                                                             i_prof,
                                                                                                             id_episode,
                                                                                                             flg_time,
                                                                                                             flg_status_det,
                                                                                                             flg_prn,
                                                                                                             flg_referral,
                                                                                                             dt_req_tstz,
                                                                                                             dt_begin_tstz,
                                                                                                             dt_plan_tstz,
                                                                                                             id_order_recurr_option),
                                                             pk_ea_logic_procedures.get_procedure_status_msg(i_lang,
                                                                                                             i_prof,
                                                                                                             id_episode,
                                                                                                             flg_time,
                                                                                                             flg_status_det,
                                                                                                             flg_prn,
                                                                                                             flg_referral,
                                                                                                             dt_req_tstz,
                                                                                                             dt_begin_tstz,
                                                                                                             dt_plan_tstz,
                                                                                                             id_order_recurr_option),
                                                             pk_ea_logic_procedures.get_procedure_status_icon(i_lang,
                                                                                                              i_prof,
                                                                                                              id_episode,
                                                                                                              flg_time,
                                                                                                              flg_status_det,
                                                                                                              flg_prn,
                                                                                                              flg_referral,
                                                                                                              dt_req_tstz,
                                                                                                              dt_begin_tstz,
                                                                                                              dt_plan_tstz,
                                                                                                              id_order_recurr_option),
                                                             pk_ea_logic_procedures.get_procedure_status_flg(i_lang,
                                                                                                             i_prof,
                                                                                                             id_episode,
                                                                                                             flg_time,
                                                                                                             flg_status_det,
                                                                                                             flg_prn,
                                                                                                             flg_referral,
                                                                                                             dt_req_tstz,
                                                                                                             dt_begin_tstz,
                                                                                                             dt_plan_tstz,
                                                                                                             id_order_recurr_option)),
                                  NULL) status_string,
                           decode(rank,
                                  1,
                                  decode(flg_time, pk_procedures_constant.g_flg_time_b, pk_procedures_constant.g_yes),
                                  NULL) flg_interv
                      FROM (SELECT t.id_interv_presc_det,
                                   t.id_episode,
                                   t.flg_time,
                                   t.flg_prn,
                                   t.flg_status_req,
                                   t.flg_status_det,
                                   t.flg_referral,
                                   t.dt_req_tstz,
                                   t.dt_begin_tstz,
                                   t.dt_plan_tstz,
                                   t.id_order_recurr_option,
                                   row_number() over(ORDER BY t.rank) rank
                              FROM (SELECT t.*,
                                           decode(t.flg_status_det,
                                                  pk_procedures_constant.g_interv_req,
                                                  row_number()
                                                  over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                             'INTERV_PRESC_DET.FLG_STATUS',
                                                                             t.flg_status_det),
                                                       coalesce(t.dt_plan_tstz, t.dt_begin_tstz, t.dt_req_tstz)),
                                                  row_number()
                                                  over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                             'INTERV_PRESC_DET.FLG_STATUS',
                                                                             t.flg_status_det),
                                                       coalesce(t.dt_plan_tstz, t.dt_begin_tstz, t.dt_req_tstz)) + 20000) rank
                                      FROM (SELECT ipd.id_interv_presc_det,
                                                   ip.id_episode,
                                                   ip.flg_time,
                                                   ipd.flg_prn,
                                                   ip.flg_status                  flg_status_req,
                                                   ipd.flg_status                 flg_status_det,
                                                   ipd.flg_referral,
                                                   ip.dt_interv_prescription_tstz dt_req_tstz,
                                                   ip.dt_begin_tstz,
                                                   ipp.dt_plan_tstz,
                                                   orp.id_order_recurr_option
                                              FROM (SELECT t.*
                                                      FROM interv_prescription t
                                                     WHERE t.id_episode = r_cur.id_episode
                                                    UNION
                                                    SELECT t.*
                                                      FROM interv_prescription t
                                                     WHERE t.id_prev_episode = r_cur.id_episode
                                                    UNION
                                                    SELECT t.*
                                                      FROM interv_prescription t
                                                     WHERE t.id_episode_origin = r_cur.id_episode
                                                    UNION
                                                    SELECT t.*
                                                      FROM interv_prescription t
                                                     WHERE (t.id_patient = r_cur.id_patient AND
                                                           t.flg_time IN
                                                           (pk_procedures_constant.g_flg_time_a,
                                                             pk_procedures_constant.g_flg_time_h))) ip,
                                                   interv_presc_det ipd,
                                                   interv_presc_plan ipp,
                                                   order_recurr_plan orp,
                                                   episode e
                                             WHERE ip.id_interv_prescription = ipd.id_interv_prescription
                                               AND ipd.flg_status IN
                                                   (pk_procedures_constant.g_interv_sos,
                                                    pk_procedures_constant.g_interv_exterior,
                                                    pk_procedures_constant.g_interv_tosched,
                                                    pk_procedures_constant.g_interv_pending,
                                                    pk_procedures_constant.g_interv_req,
                                                    pk_procedures_constant.g_interv_exec,
                                                    pk_procedures_constant.g_interv_partial)
                                               AND (ipd.flg_referral NOT IN
                                                   (pk_procedures_constant.g_flg_referral_r,
                                                     pk_procedures_constant.g_flg_referral_s,
                                                     pk_procedures_constant.g_flg_referral_i) OR ipd.flg_referral IS NULL)
                                               AND ipd.id_interv_presc_det = ipp.id_interv_presc_det(+)
                                               AND (ipp.flg_status IN
                                                   (pk_procedures_constant.g_interv_plan_pending,
                                                     pk_procedures_constant.g_interv_plan_req) OR ipp.flg_status IS NULL)
                                               AND ipd.id_order_recurrence = orp.id_order_recurr_plan(+)
                                               AND (ip.id_episode = e.id_episode OR ip.id_prev_episode = e.id_episode OR
                                                   ip.id_episode_origin = e.id_episode)) t) t)
                     WHERE rank = 1) t;
        
            IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_intern_name => 'GRID_PROC',
                                             o_id_shortcut => l_shortcut,
                                             o_error       => o_error)
            THEN
                l_shortcut := 0;
            END IF;
        
            g_error := 'GET SHORTCUT - DOCTOR';
            IF l_grid_task.intervention IS NOT NULL
            THEN
                IF regexp_like(l_grid_task.intervention, '^\|D')
                THEN
                    l_dt_str_1 := regexp_replace(l_grid_task.intervention,
                                                 '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*',
                                                 '\1');
                    l_dt_str_2 := regexp_replace(l_grid_task.intervention,
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
                        l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_1, l_dt_1);
                    ELSE
                        l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_1, l_dt_1);
                        l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_2, l_dt_2);
                    END IF;
                ELSE
                    l_dt_str_2               := regexp_replace(l_grid_task.intervention,
                                                               '^\|\w{0,2}\|.*\|(\d{14})\|.*',
                                                               '\1');
                    l_dt_2                   := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                   pk_date_utils.get_string_tstz(i_lang,
                                                                                                                 i_prof,
                                                                                                                 l_dt_str_2,
                                                                                                                 NULL),
                                                                                   'YYYYMMDDHH24MISS TZR');
                    l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_2, l_dt_2);
                END IF;
            
                l_grid_task.intervention := l_shortcut || l_grid_task.intervention;
            END IF;
        
            l_grid_task.id_episode := r_cur.id_episode;
        
            IF l_grid_task.id_episode IS NOT NULL
            THEN
                g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                i_prof           => i_prof,
                                                i_episode        => l_grid_task.id_episode,
                                                intervention_in  => l_grid_task.intervention,
                                                intervention_nin => FALSE,
                                                o_error          => o_error)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            
                IF l_grid_task.intervention IS NULL
                THEN
                    g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode';
                    IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                         i_episode => l_grid_task.id_episode,
                                                         o_error   => o_error)
                    THEN
                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                    END IF;
                END IF;
            END IF;
        
            BEGIN
                g_error := 'SELECT ID_EPISODE_ORIGIN';
                SELECT DISTINCT ip.id_episode_origin
                  INTO l_grid_task.id_episode
                  FROM interv_prescription ip
                 WHERE ip.id_episode_origin IS NOT NULL
                   AND ip.id_episode = r_cur.id_episode;
            
                IF l_grid_task.id_episode IS NOT NULL
                THEN
                    g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode_origin';
                    IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_episode        => l_grid_task.id_episode,
                                                    intervention_in  => l_grid_task.intervention,
                                                    intervention_nin => FALSE,
                                                    o_error          => o_error)
                    THEN
                        RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                    END IF;
                
                    IF l_grid_task.intervention IS NULL
                    THEN
                        g_error := 'CALL PK_GRID.DELETE_EPIS_GRID_TASK - id_episode_origin';
                        IF NOT pk_grid.delete_epis_grid_task(i_lang    => i_lang,
                                                             i_episode => l_grid_task.id_episode,
                                                             o_error   => o_error)
                        THEN
                            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                        END IF;
                    END IF;
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            IF l_grid_task_betw.flg_interv = pk_procedures_constant.g_yes
            THEN
                l_grid_task_betw.id_episode := r_cur.id_episode;
            
                --Actualiza estado da tarefa em GRID_TASK_BETWEEN para o epis? correspondente
                g_error := 'CALL PK_GRID.UPDATE_NURSE_TASK';
                IF NOT pk_grid.update_nurse_task(i_lang => i_lang, i_grid_task => l_grid_task_betw, o_error => o_error)
                THEN
                    RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END set_grid_task_procedures_across;

    PROCEDURE set_grid_task_procedures
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
            IF l_rowids IS NOT NULL
               AND l_rowids.count > 0
            THEN
                FOR r_cur IN (SELECT *
                                FROM (SELECT nvl(ip.id_episode, ip.id_episode_origin) id_episode,
                                             ip.id_patient,
                                             ip.flg_time
                                        FROM (SELECT /*+opt_estimate (table ipd rows=1)*/
                                               *
                                                FROM interv_presc_det ipd
                                               WHERE ipd.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                                    *
                                                                     FROM TABLE(l_rowids) t)
                                                 AND ipd.flg_status != pk_procedures_constant.g_interv_draft) ipd,
                                             interv_prescription ip
                                       WHERE ipd.id_interv_prescription = ip.id_interv_prescription))
                LOOP
                    SELECT MAX(status_string) status_string, MAX(flg_interv) flg_interv
                      INTO l_grid_task.intervention, l_grid_task_betw.flg_interv
                      FROM (SELECT decode(rank,
                                          1,
                                          pk_utils.get_status_string(i_lang,
                                                                     i_prof,
                                                                     pk_ea_logic_procedures.get_procedure_status_str(i_lang,
                                                                                                                     i_prof,
                                                                                                                     id_episode,
                                                                                                                     flg_time,
                                                                                                                     flg_status_det,
                                                                                                                     flg_prn,
                                                                                                                     flg_referral,
                                                                                                                     dt_req_tstz,
                                                                                                                     dt_begin_tstz,
                                                                                                                     dt_plan_tstz,
                                                                                                                     id_order_recurr_option),
                                                                     pk_ea_logic_procedures.get_procedure_status_msg(i_lang,
                                                                                                                     i_prof,
                                                                                                                     id_episode,
                                                                                                                     flg_time,
                                                                                                                     flg_status_det,
                                                                                                                     flg_prn,
                                                                                                                     flg_referral,
                                                                                                                     dt_req_tstz,
                                                                                                                     dt_begin_tstz,
                                                                                                                     dt_plan_tstz,
                                                                                                                     id_order_recurr_option),
                                                                     pk_ea_logic_procedures.get_procedure_status_icon(i_lang,
                                                                                                                      i_prof,
                                                                                                                      id_episode,
                                                                                                                      flg_time,
                                                                                                                      flg_status_det,
                                                                                                                      flg_prn,
                                                                                                                      flg_referral,
                                                                                                                      dt_req_tstz,
                                                                                                                      dt_begin_tstz,
                                                                                                                      dt_plan_tstz,
                                                                                                                      id_order_recurr_option),
                                                                     pk_ea_logic_procedures.get_procedure_status_flg(i_lang,
                                                                                                                     i_prof,
                                                                                                                     id_episode,
                                                                                                                     flg_time,
                                                                                                                     flg_status_det,
                                                                                                                     flg_prn,
                                                                                                                     flg_referral,
                                                                                                                     dt_req_tstz,
                                                                                                                     dt_begin_tstz,
                                                                                                                     dt_plan_tstz,
                                                                                                                     id_order_recurr_option)),
                                          NULL) status_string,
                                   decode(rank,
                                          1,
                                          decode(flg_time,
                                                 pk_procedures_constant.g_flg_time_b,
                                                 pk_procedures_constant.g_yes),
                                          NULL) flg_interv
                              FROM (SELECT t.id_interv_presc_det,
                                           t.id_episode,
                                           t.flg_time,
                                           t.flg_prn,
                                           t.flg_status_req,
                                           t.flg_status_det,
                                           t.flg_referral,
                                           t.dt_req_tstz,
                                           t.dt_begin_tstz,
                                           t.dt_plan_tstz,
                                           t.id_order_recurr_option,
                                           row_number() over(ORDER BY t.rank) rank
                                      FROM (SELECT t.*,
                                                   decode(t.flg_status_det,
                                                          pk_procedures_constant.g_interv_req,
                                                          row_number()
                                                          over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                                     'INTERV_PRESC_DET.FLG_STATUS',
                                                                                     t.flg_status_det),
                                                               coalesce(t.dt_plan_tstz, t.dt_begin_tstz, t.dt_req_tstz)),
                                                          row_number()
                                                          over(ORDER BY pk_sysdomain.get_rank(i_lang,
                                                                                     'INTERV_PRESC_DET.FLG_STATUS',
                                                                                     t.flg_status_det),
                                                               coalesce(t.dt_plan_tstz, t.dt_begin_tstz, t.dt_req_tstz)) +
                                                          20000) rank
                                              FROM (SELECT ipd.id_interv_presc_det,
                                                           ip.id_episode,
                                                           ip.flg_time,
                                                           ipd.flg_prn,
                                                           ip.flg_status                  flg_status_req,
                                                           ipd.flg_status                 flg_status_det,
                                                           ipd.flg_referral,
                                                           ip.dt_interv_prescription_tstz dt_req_tstz,
                                                           ip.dt_begin_tstz,
                                                           ipp.dt_plan_tstz,
                                                           orp.id_order_recurr_option
                                                      FROM (SELECT t.*
                                                              FROM interv_prescription t
                                                             WHERE t.id_episode = r_cur.id_episode
                                                            UNION
                                                            SELECT t.*
                                                              FROM interv_prescription t
                                                             WHERE t.id_prev_episode = r_cur.id_episode
                                                            UNION
                                                            SELECT t.*
                                                              FROM interv_prescription t
                                                             WHERE t.id_episode_origin = r_cur.id_episode
                                                            UNION
                                                            SELECT t.*
                                                              FROM interv_prescription t
                                                             WHERE (t.id_patient = r_cur.id_patient AND
                                                                   t.flg_time IN
                                                                   (pk_procedures_constant.g_flg_time_a,
                                                                     pk_procedures_constant.g_flg_time_h))) ip,
                                                           interv_presc_det ipd,
                                                           interv_presc_plan ipp,
                                                           order_recurr_plan orp,
                                                           episode e
                                                     WHERE ip.id_interv_prescription = ipd.id_interv_prescription
                                                       AND ipd.flg_status IN
                                                           (pk_procedures_constant.g_interv_sos,
                                                            pk_procedures_constant.g_interv_exterior,
                                                            pk_procedures_constant.g_interv_tosched,
                                                            pk_procedures_constant.g_interv_pending,
                                                            pk_procedures_constant.g_interv_req,
                                                            pk_procedures_constant.g_interv_exec,
                                                            pk_procedures_constant.g_interv_partial)
                                                       AND (ipd.flg_referral NOT IN
                                                           (pk_procedures_constant.g_flg_referral_r,
                                                             pk_procedures_constant.g_flg_referral_s,
                                                             pk_procedures_constant.g_flg_referral_i) OR
                                                           ipd.flg_referral IS NULL)
                                                       AND ipd.id_interv_presc_det = ipp.id_interv_presc_det(+)
                                                       AND (ipp.flg_status IN
                                                           (pk_procedures_constant.g_interv_plan_pending,
                                                             pk_procedures_constant.g_interv_plan_req) OR
                                                           ipp.flg_status IS NULL)
                                                       AND ipd.id_order_recurrence = orp.id_order_recurr_plan(+)
                                                       AND (ip.id_episode = e.id_episode OR
                                                           ip.id_prev_episode = e.id_episode OR
                                                           ip.id_episode_origin = e.id_episode)) t) t)
                             WHERE rank = 1) t;
                
                    IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_intern_name => 'GRID_PROC',
                                                     o_id_shortcut => l_shortcut,
                                                     o_error       => l_error_out)
                    THEN
                        l_shortcut := 0;
                    END IF;
                
                    g_error := 'GET SHORTCUT - DOCTOR';
                    IF l_grid_task.intervention IS NOT NULL
                    THEN
                        IF regexp_like(l_grid_task.intervention, '^\|D')
                        THEN
                            l_dt_str_1 := regexp_replace(l_grid_task.intervention,
                                                         '^\|D\w{0,1}\|(\d{14})\|.*\|\d{14}\|.*',
                                                         '\1');
                            l_dt_str_2 := regexp_replace(l_grid_task.intervention,
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
                                l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_1, l_dt_1);
                            ELSE
                                l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_1, l_dt_1);
                                l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_2, l_dt_2);
                            END IF;
                        ELSE
                            l_dt_str_2               := regexp_replace(l_grid_task.intervention,
                                                                       '^\|\w{0,2}\|.*\|(\d{14})\|.*',
                                                                       '\1');
                            l_dt_2                   := pk_date_utils.to_char_insttimezone(i_prof,
                                                                                           pk_date_utils.get_string_tstz(i_lang,
                                                                                                                         i_prof,
                                                                                                                         l_dt_str_2,
                                                                                                                         NULL),
                                                                                           'YYYYMMDDHH24MISS TZR');
                            l_grid_task.intervention := regexp_replace(l_grid_task.intervention, l_dt_str_2, l_dt_2);
                        END IF;
                    
                        l_grid_task.intervention := l_shortcut || l_grid_task.intervention;
                    END IF;
                
                    l_grid_task.id_episode := r_cur.id_episode;
                
                    IF l_grid_task.id_episode IS NOT NULL
                    THEN
                        g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode';
                        IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_episode        => l_grid_task.id_episode,
                                                        intervention_in  => l_grid_task.intervention,
                                                        intervention_nin => FALSE,
                                                        o_error          => l_error_out)
                        THEN
                            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                        END IF;
                    
                        IF l_grid_task.intervention IS NULL
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
                            IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_episode        => l_grid_task.id_episode,
                                                            intervention_in  => l_grid_task.intervention,
                                                            intervention_nin => FALSE,
                                                            o_error          => l_error_out)
                            THEN
                                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
                            END IF;
                        
                            IF l_grid_task.intervention IS NULL
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
                        SELECT DISTINCT ip.id_episode_origin
                          INTO l_grid_task.id_episode
                          FROM interv_prescription ip
                         WHERE ip.id_episode_origin IS NOT NULL
                           AND ip.id_episode = r_cur.id_episode;
                    
                        IF l_grid_task.id_episode IS NOT NULL
                        THEN
                            g_error := 'CALL PK_GRID.UPDATE_GRID_TASK - id_episode_origin';
                            IF NOT pk_grid.update_grid_task(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_episode        => l_grid_task.id_episode,
                                                            intervention_in  => l_grid_task.intervention,
                                                            intervention_nin => FALSE,
                                                            o_error          => l_error_out)
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
                    IF l_grid_task_betw.flg_interv = pk_procedures_constant.g_yes
                    THEN
                        l_grid_task_betw.id_episode := r_cur.id_episode;
                    
                        --Actualiza estado da tarefa em GRID_TASK_BETWEEN para o epis? correspondente
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
    END set_grid_task_procedures;

    PROCEDURE set_task_timeline_proced
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
        l_func_proc_name   VARCHAR2(30) := 'SET_TASK_TIMELINE_PROCED';
        l_name_table_ea    VARCHAR2(30) := 'TASK_TIMELINE_EA';
        l_process_name     VARCHAR2(30);
        l_rowids           table_varchar;
        l_event_into_ea    VARCHAR2(1);
        l_update_reg       NUMBER(24);
        l_flg_outdated     task_timeline_ea.flg_outdated%TYPE := 1;
        l_flg_not_outdated task_timeline_ea.flg_outdated%TYPE := 0;
        o_rowids           table_varchar;
        l_error_out        t_error_out;
    
        l_flg_has_comments VARCHAR2(1 CHAR);
    
        l_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE := current_timestamp;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
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
            
                g_error := 'GET INTERV_PRESC_DET ROWIDS';
                get_data_rowid(i_lang, i_prof, i_source_table_name, i_rowids, l_rowids);
            
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => l_rowids);
            
                FOR r_cur IN (SELECT /*+opt_estimate (table ipd rows=1)*/
                               ip.id_interv_prescription,
                               ipd.id_interv_presc_det,
                               ipd.id_intervention,
                               ip.flg_status flg_status_req,
                               ipd.flg_status flg_status_det,
                               ip.flg_time,
                               ipd.flg_prn,
                               ip.dt_begin_tstz dt_begin_tstz_ip,
                               nvl(ipp.dt_plan_tstz, ipd.dt_begin_tstz) dt_begin_det,
                               ip.dt_interv_prescription_tstz,
                               ip.id_professional id_prof_requested,
                               ipd.code_intervention_alias,
                               ip.id_episode_origin,
                               e.id_visit,
                               ip.id_episode,
                               ip.id_patient,
                               ipd.flg_referral,
                               nvl(cs.dt_ordered_by, ipd.dt_order_tstz) dt_order,
                               --
                               ip.dt_begin_tstz                           dt_begin_req,
                               ipp.dt_plan_tstz,
                               orp.id_order_recurr_option,
                               ipd.dt_interv_presc_det, -- PT
                               pk_alert_constant.g_flg_type_viewer_proced flg_type_viewer,
                               --
                               ip.id_institution,
                               ipd.dt_end_tstz,
                               i.code_intervention,
                               NULL universal_desc_clob,
                               decode(ipd.flg_status,
                                      pk_procedures_constant.g_interv_finished,
                                      pk_prog_notes_constants.g_task_finalized_f,
                                      pk_prog_notes_constants.g_task_ongoing_o) flg_ongoing,
                               pk_alert_constant.g_yes flg_normal,
                               ipp.id_prof_take id_prof_exec,
                               e.flg_status flg_status_epis,
                               nvl((SELECT MAX(ea.dt_dg_last_update)
                                     FROM procedures_ea ea
                                    WHERE ea.id_interv_presc_det = ipd.id_interv_presc_det),
                                   ip.dt_interv_prescription_tstz) dt_last_update,
                               (SELECT MAX(ippp.start_time)
                                  FROM interv_presc_plan ippp
                                 WHERE ippp.flg_status IN (pk_procedures_constant.g_interv_plan_executed,
                                                           pk_procedures_constant.g_interv_finished)
                                   AND ippp.id_interv_presc_det = ipd.id_interv_presc_det) dt_last_execution,
                               i.flg_technical,
                               ipd.dt_end_tstz dt_execution,
                               1 rank,
                               i.flg_category_type
                                FROM interv_presc_det    ipd,
                                     interv_prescription ip,
                                     intervention        i,
                                     interv_presc_plan   ipp,
                                     order_recurr_plan   orp,
                                     co_sign_hist        cs,
                                     episode             e
                               WHERE ipd.rowid IN (SELECT vc_1
                                                     FROM tbl_temp)
                                 AND ip.id_interv_prescription = ipd.id_interv_prescription
                                 AND ipd.id_intervention = i.id_intervention
                                 AND ipp.id_interv_presc_det(+) = ipd.id_interv_presc_det
                                 AND (ipp.id_interv_presc_plan IS NULL OR
                                     ipp.id_interv_presc_plan =
                                     (SELECT MAX(ipp1.id_interv_presc_plan)
                                         FROM interv_presc_plan ipp1
                                        WHERE ipp1.id_interv_presc_det = ipd.id_interv_presc_det))
                                 AND ipd.id_order_recurrence = orp.id_order_recurr_plan(+)
                                 AND ipd.id_co_sign_order = cs.id_co_sign_hist(+)
                                 AND (nvl(ip.id_episode, nvl(ip.id_episode_origin, ip.id_episode_destination)) =
                                     e.id_episode))
                LOOP
                
                    g_error := 'GET ANALYSIS STATUS';
                    get_procedure_status(i_lang                   => i_lang,
                                         i_prof                   => i_prof,
                                         i_episode                => r_cur.id_episode,
                                         i_flg_time               => r_cur.flg_time,
                                         i_flg_status_det         => r_cur.flg_status_det,
                                         i_flg_prn                => r_cur.flg_prn,
                                         i_flg_referral           => r_cur.flg_referral,
                                         i_dt_interv_prescription => r_cur.dt_interv_prescription_tstz,
                                         i_dt_begin_req           => r_cur.dt_begin_req,
                                         i_dt_plan                => r_cur.dt_plan_tstz,
                                         i_order_recurr_option    => r_cur.id_order_recurr_option,
                                         o_status_str             => l_new_rec_row.status_str,
                                         o_status_msg             => l_new_rec_row.status_msg,
                                         o_status_icon            => l_new_rec_row.status_icon,
                                         o_status_flg             => l_new_rec_row.status_flg);
                
                    g_error                         := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                    l_new_rec_row.id_tl_task        := pk_prog_notes_constants.g_task_procedures;
                    l_new_rec_row.table_name        := pk_alert_constant.g_tl_table_name_procedur;
                    l_new_rec_row.flg_show_method   := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update := l_timestamp;
                
                    l_new_rec_row.id_task_refid     := r_cur.id_interv_presc_det;
                    l_new_rec_row.dt_begin          := r_cur.dt_begin_det;
                    l_new_rec_row.dt_end            := r_cur.dt_end_tstz;
                    l_new_rec_row.flg_status_req    := r_cur.flg_status_det;
                    l_new_rec_row.flg_type_viewer   := r_cur.flg_type_viewer;
                    l_new_rec_row.id_prof_req       := r_cur.id_prof_requested;
                    l_new_rec_row.dt_req            := nvl(r_cur.dt_order, r_cur.dt_interv_presc_det);
                    l_new_rec_row.id_patient        := r_cur.id_patient;
                    l_new_rec_row.id_episode        := nvl(r_cur.id_episode, r_cur.id_episode_origin);
                    l_new_rec_row.id_visit          := r_cur.id_visit;
                    l_new_rec_row.id_institution    := r_cur.id_institution;
                    l_new_rec_row.code_description  := r_cur.code_intervention;
                    l_new_rec_row.flg_outdated      := l_flg_not_outdated;
                    l_new_rec_row.dt_last_execution := r_cur.dt_last_execution;
                
                    IF r_cur.flg_prn = pk_alert_constant.g_yes
                    THEN
                        l_new_rec_row.flg_sos := pk_alert_constant.g_yes;
                    ELSE
                        l_new_rec_row.flg_sos := pk_alert_constant.g_no;
                    END IF;
                    l_new_rec_row.flg_ongoing    := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal     := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec   := r_cur.id_prof_exec;
                    l_new_rec_row.dt_last_update := r_cur.dt_last_update;
                    l_new_rec_row.flg_technical  := r_cur.flg_technical;
                    l_new_rec_row.dt_execution   := r_cur.dt_execution;
                    l_new_rec_row.rank           := r_cur.rank;
                    l_new_rec_row.flg_type       := r_cur.flg_category_type;
                
                    --check if it has comments
                    BEGIN
                        SELECT pk_alert_constant.g_yes
                          INTO l_flg_has_comments
                          FROM treatment_management tm
                         WHERE tm.id_treatment = r_cur.id_interv_presc_det
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_flg_has_comments := pk_alert_constant.g_no;
                    END;
                
                    l_new_rec_row.flg_has_comments := l_flg_has_comments;
                
                    pk_alertlog.log_debug('Processing ' || l_process_name || ' on ' || i_source_table_name || ' (' ||
                                          l_name_table_ea || '): ' || g_error,
                                          g_package_name,
                                          l_func_proc_name);
                
                    -- Events in TASK_TIMELINE_EA table is dependent of l_new_rec_row.flg_status_req variable
                    IF l_new_rec_row.flg_status_req IN
                       (pk_procedures_constant.g_interv_req, -- Required ('R')
                        pk_procedures_constant.g_interv_pending, -- pendent ('D')
                        pk_procedures_constant.g_interv_sched, -- schedule ('A')
                        pk_procedures_constant.g_interv_partial, -- Partial results ('P')
                        pk_procedures_constant.g_interv_exec, -- in Execution ('E')
                        pk_procedures_constant.g_interv_exterior) -- Exterior ('X')
                       AND r_cur.flg_status_epis != pk_alert_constant.g_epis_status_cancel
                    
                    THEN
                        -- Search for updated registrie
                        SELECT COUNT(0)
                          INTO l_update_reg
                          FROM task_timeline_ea tte
                         WHERE tte.id_task_refid = l_new_rec_row.id_task_refid
                           AND tte.table_name = pk_alert_constant.g_tl_table_name_procedur
                           AND tte.id_tl_task = pk_prog_notes_constants.g_task_procedures;
                    
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
                        --IF l_new_rec_row.flg_status_req = pk_alert_constant.g_interv_cancelel -- Cancelled ('C')
                        --OR l_new_rec_row.flg_status_req = pk_alert_constant.g_interv_finished -- Concluded ('F')
                        --OR l_new_rec_row.flg_status_req = pk_alert_constant.g_interv_det_inter -- Interrupted ('I')
                        --OR l_new_rec_row.flg_status_req = pk_alert_constant.g_interv_det_propose -- New Proposed intervention ('V')
                        --OR l_new_rec_row.flg_status_req = pk_alert_constant.g_interv_det_rejected -- Rejected ('G')
                        --
                        IF l_new_rec_row.flg_status_req IN
                           (pk_procedures_constant.g_interv_cancel, -- Cancelled ('C')
                            pk_alert_constant.g_interv_det_rejected,
                            pk_procedures_constant.g_interv_expired,
                            pk_procedures_constant.g_interv_draft,
                            pk_procedures_constant.g_interv_not_ordered)
                           OR r_cur.flg_status_epis = pk_alert_constant.g_epis_status_cancel
                        THEN
                            -- Information in states that are not relevant are DELETED
                            l_process_name  := 'DELETE';
                            l_event_into_ea := 'D';
                        ELSE
                            -- Information in states that are not relevant are FLG_OUTDATED = 1
                            l_process_name             := 'UPDATE';
                            l_event_into_ea            := 'U';
                            l_new_rec_row.flg_outdated := l_flg_outdated;
                        END IF;
                    END IF;
                
                    /*
                    * Executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    -- INSERT
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
                    ELSIF l_event_into_ea = t_data_gov_mnt.g_event_delete
                    -- DELETE: Apenas podem ocorrer DELETE's nas tabelas INTERV_PRESCRIPTION e INTERV_PRESC_DET
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.DEL_BY';
                        ts_task_timeline_ea.del_by(where_clause_in => 'id_task_refid = ' || l_new_rec_row.id_task_refid ||
                                                                      ' AND id_tl_task = ' || l_new_rec_row.id_tl_task,
                                                   rows_out        => o_rowids);
                    
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
                                                --
                                                flg_outdated_nin     => TRUE,
                                                flg_outdated_in      => l_new_rec_row.flg_outdated,
                                                flg_sos_nin          => FALSE,
                                                flg_sos_in           => l_new_rec_row.flg_sos,
                                                flg_ongoing_nin      => FALSE,
                                                flg_ongoing_in       => l_new_rec_row.flg_ongoing,
                                                flg_normal_nin       => FALSE,
                                                flg_normal_in        => l_new_rec_row.flg_normal,
                                                id_prof_exec_nin     => FALSE,
                                                id_prof_exec_in      => l_new_rec_row.id_prof_exec,
                                                flg_has_comments_nin => TRUE,
                                                flg_has_comments_in  => l_new_rec_row.flg_has_comments,
                                                dt_last_update_in    => l_new_rec_row.dt_last_update,
                                                dt_execution_in      => l_new_rec_row.dt_execution,
                                                dt_last_execution_in => l_new_rec_row.dt_last_execution,
                                                flg_technical_in     => l_new_rec_row.flg_technical,
                                                rank_in              => l_new_rec_row.rank,
                                                flg_type_in          => l_new_rec_row.flg_type,
                                                rows_out             => o_rowids);
                    
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_TIMELINE_PROCED',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_task_timeline_proced;

    PROCEDURE set_task_timeline_proc_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    ) IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_TASK_TIMELINE_PROC_NOTES';
        l_ea_table  CONSTANT VARCHAR2(30 CHAR) := 'TASK_TIMELINE_EA';
        l_src_table CONSTANT VARCHAR2(30 CHAR) := 'TREATMENT_MANAGEMENT';
        l_ea_row  task_timeline_ea%ROWTYPE;
        l_ea_rows ts_task_timeline_ea.task_timeline_ea_tc;
        l_error   t_error_out;
    
        CURSOR c_notes IS
            SELECT /*+ opt_estimate(table tm rows=1) */
             tm.id_treatment_management,
             coalesce(ip.id_patient, e1.id_patient, e2.id_patient) id_patient,
             nvl(e1.id_episode, e2.id_episode) id_episode,
             nvl(e1.id_visit, e2.id_visit) id_visit,
             nvl(e1.id_institution, e2.id_institution) id_institution,
             tm.dt_creation_tstz,
             tm.id_professional,
             tm.desc_treatment_management,
             ipd.id_interv_presc_det,
             nvl(e1.flg_status, e2.flg_status) flg_status_epis
              FROM treatment_management tm
              JOIN interv_presc_det ipd
                ON tm.id_treatment = ipd.id_interv_presc_det
              JOIN interv_prescription ip
                ON ipd.id_interv_prescription = ip.id_interv_prescription
              LEFT JOIN episode e1
                ON ip.id_episode = e1.id_episode
              LEFT JOIN episode e2
                ON ip.id_episode_origin = e2.id_episode
             WHERE tm.flg_type = pk_medical_decision.g_treat_type_interv
               AND tm.rowid IN (SELECT /*+ opt_estimate(table t rows=1) */
                                 t.column_value row_id
                                  FROM TABLE(i_rowids) t);
    
        TYPE t_coll_notes IS TABLE OF c_notes%ROWTYPE;
        l_notes_data t_coll_notes;
    
        l_idx PLS_INTEGER;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_idx          := 0;
    
        -- validate arguments
        g_error := 'CALL t_data_gov_mnt.validate_arguments';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_src_table,
                                                 i_dg_table_name          => i_dg_table,
                                                 i_expected_table_name    => l_src_table,
                                                 i_expected_dg_table_name => l_ea_table,
                                                 i_list_columns           => i_list_columns)
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
            -- debug event
            g_error := 'processing insert or update event on ' || l_src_table || ' into ' || l_ea_table;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            -- get diet data from rowids
            g_error := 'OPEN c_notes';
            OPEN c_notes;
            FETCH c_notes BULK COLLECT
                INTO l_notes_data;
            CLOSE c_notes;
        
            -- copy diet data into rows collection
            IF l_notes_data IS NOT NULL
               AND l_notes_data.count > 0
            THEN
                -- set constant fields
                l_ea_row.id_tl_task        := pk_prog_notes_constants.g_task_procedures_comments;
                l_ea_row.table_name        := l_src_table;
                l_ea_row.flg_show_method   := pk_alert_constant.g_tl_oriented_episode;
                l_ea_row.dt_dg_last_update := g_sysdate_tstz;
                l_ea_row.flg_outdated      := pk_ea_logic_tasktimeline.g_flg_outdated;
                l_ea_row.flg_sos           := pk_alert_constant.g_no;
                l_ea_row.flg_ongoing       := pk_prog_notes_constants.g_task_ongoing_o;
                l_ea_row.flg_normal        := pk_alert_constant.g_yes;
                l_ea_row.flg_has_comments  := pk_alert_constant.g_no;
            
                -- set variable fields
                FOR i IN l_notes_data.first .. l_notes_data.last
                LOOP
                    l_ea_row.id_task_refid       := l_notes_data(i).id_treatment_management;
                    l_ea_row.id_patient          := l_notes_data(i).id_patient;
                    l_ea_row.id_episode          := l_notes_data(i).id_episode;
                    l_ea_row.id_visit            := l_notes_data(i).id_visit;
                    l_ea_row.id_institution      := l_notes_data(i).id_institution;
                    l_ea_row.dt_req              := l_notes_data(i).dt_creation_tstz;
                    l_ea_row.id_prof_req         := l_notes_data(i).id_professional;
                    l_ea_row.universal_desc_clob := to_clob(l_notes_data(i).desc_treatment_management);
                    l_ea_row.id_parent_comments  := l_notes_data(i).id_interv_presc_det;
                    l_ea_row.dt_last_update      := l_notes_data(i).dt_creation_tstz;
                
                    IF l_notes_data(i).flg_status_epis = pk_alert_constant.g_epis_status_cancel
                    THEN
                        g_error := 'CALL TS_TASK_TIMELINE_EA.DEL';
                        ts_task_timeline_ea.del(id_task_refid_in => l_ea_row.id_task_refid,
                                                id_tl_task_in    => l_ea_row.id_tl_task);
                    ELSE
                        -- add row to rows collection
                        l_idx := l_idx + 1;
                        l_ea_rows(l_idx) := l_ea_row;
                    
                        --update parent task
                        ts_task_timeline_ea.upd(where_in            => 'id_task_refid = ' || l_notes_data(i).id_interv_presc_det ||
                                                                       ' and id_tl_task = ' ||
                                                                       pk_prog_notes_constants.g_task_procedures,
                                                flg_has_comments_in => pk_alert_constant.g_yes);
                    END IF;
                END LOOP;
            
                -- add rows collection to easy access
                IF i_event_type = t_data_gov_mnt.g_event_insert
                THEN
                    g_error := 'CALL ts_task_timeline_ea.ins I';
                    ts_task_timeline_ea.ins(rows_in => l_ea_rows);
                ELSIF i_event_type = t_data_gov_mnt.g_event_update
                THEN
                    g_error := 'CALL ts_task_timeline_ea.upd';
                    ts_task_timeline_ea.upd(col_in => l_ea_rows, ignore_if_null_in => FALSE);
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_TASK_TIMELINE_PROC_NOTES',
                                              l_error);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_task_timeline_proc_notes;

    PROCEDURE set_task_timeline
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
            
                FOR r_cur IN (SELECT /*+opt_estimate (table ipp rows=1)*/
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
                               WHERE ipp.rowid IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                    *
                                                     FROM TABLE(i_rowids) t)
                                 AND ip.id_interv_prescription = ipd.id_interv_prescription
                                 AND ipp.id_interv_presc_det = ipd.id_interv_presc_det
                                 AND ip.id_episode = e.id_episode(+)
                                 AND ip.id_episode_origin = ep_origin.id_episode(+)
                                 AND e.id_visit = v.id_visit)
                
                LOOP
                    g_error := 'DEFINE NEW RECORD FOR TASK_TIMELINE_EA';
                
                    l_new_rec_row.id_tl_task          := pk_prog_notes_constants.g_task_procedures_exec;
                    l_new_rec_row.table_name          := 'INTERV_PRESC_PLAN';
                    l_new_rec_row.flg_show_method     := pk_alert_constant.g_tl_oriented_visit;
                    l_new_rec_row.dt_dg_last_update   := l_timestamp;
                    l_new_rec_row.id_task_refid       := r_cur.id_interv_presc_plan;
                    l_new_rec_row.dt_begin            := r_cur.dt_begin;
                    l_new_rec_row.dt_end              := r_cur.dt_end;
                    l_new_rec_row.flg_status_req      := r_cur.flg_status_det;
                    l_new_rec_row.id_prof_req         := r_cur.id_prof_take;
                    l_new_rec_row.dt_req              := nvl(r_cur.dt_plan_tstz, l_timestamp);
                    l_new_rec_row.id_patient          := r_cur.id_patient;
                    l_new_rec_row.id_episode          := r_cur.id_episode;
                    l_new_rec_row.id_visit            := r_cur.id_visit;
                    l_new_rec_row.id_institution      := r_cur.id_institution;
                    l_new_rec_row.code_description    := r_cur.code_intervention;
                    l_new_rec_row.flg_outdated        := l_flg_outdated;
                    l_new_rec_row.id_ref_group        := r_cur.id_interv_presc_det;
                    l_new_rec_row.universal_desc_clob := r_cur.notes;
                    l_new_rec_row.id_task_notes       := r_cur.id_epis_documentation;
                    l_new_rec_row.code_status         := r_cur.code_status;
                    l_new_rec_row.flg_ongoing         := r_cur.flg_ongoing;
                    l_new_rec_row.flg_normal          := r_cur.flg_normal;
                    l_new_rec_row.id_prof_exec        := r_cur.id_prof_take;
                    l_new_rec_row.dt_last_update      := r_cur.dt_last_update;
                
                    IF r_cur.flg_prn = pk_alert_constant.g_yes
                    THEN
                        l_new_rec_row.flg_sos := pk_alert_constant.g_yes;
                    ELSE
                        l_new_rec_row.flg_sos := pk_alert_constant.g_no;
                    END IF;
                
                    --check if it has comments
                    BEGIN
                        SELECT pk_alert_constant.g_yes
                          INTO l_flg_has_comments
                          FROM treatment_management tm
                         WHERE tm.id_treatment = r_cur.id_interv_presc_det
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_flg_has_comments := pk_alert_constant.g_no;
                    END;
                
                    l_new_rec_row.flg_has_comments := l_flg_has_comments;
                
                    /*
                    * Executar sobre a tabela de Easy Access TASK_TIMELINE_EA: 
                    *  -> INSERT;
                    *  -> DELETE;
                    *  -> UPDATE.
                    */
                
                    -- INSERT
                    IF l_event_into_ea = t_data_gov_mnt.g_event_insert
                    THEN
                        g_error := 'TS_TASK_TIMELINE_EA.INS';
                        ts_task_timeline_ea.ins(rec_in => l_new_rec_row, rows_out => o_rowids);
                    
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
                           (pk_procedures_constant.g_interv_plan_executed,
                            pk_procedures_constant.g_interv_plan_not_executed,
                            pk_procedures_constant.g_interv_plan_req,
                            pk_procedures_constant.g_interv_plan_pending)
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
                                              'SET_TASK_TIMELINE_PROCED',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END set_task_timeline;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ea_logic_procedures;
/
