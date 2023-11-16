/*-- Last Change Revision: $Rev: 2027322 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_logic_consult_req IS

    /*
     * This procedure was created to calculate the status of a certain exam_req_det
     * status. Insted of doing this at SELECT time this function is suppose to
     * be used at INSERT and UPDATE time.
     *
     * @param     i_prof                            Professional type
     * @param     i_flg_status                      
     * @param     i_dt_consult_req_tstz             
     * @param     o_status_str                      Request's status (in specific format)
     * @param     o_status_msg                      Request's status message code
     * @param     o_status_icon                     Request's status icon
     * @param     o_status_flg                      Request's status flag (to return the icon)
     * 
     * @author Thiago Brito
     * @since  2008-Oct-08
    */
    PROCEDURE get_consult_req_status
    (
        i_prof                IN profissional,
        i_flg_status          IN consult_req.flg_status%TYPE,
        i_dt_consult_req_tstz IN consult_req.dt_consult_req_tstz%TYPE,
        o_status_str          OUT exams_ea.status_str%TYPE,
        o_status_msg          OUT exams_ea.status_msg%TYPE,
        o_status_icon         OUT exams_ea.status_icon%TYPE,
        o_status_flg          OUT exams_ea.status_flg%TYPE
    ) IS
    
        l_display_type VARCHAR2(30);
        l_status_flg   VARCHAR2(30);
        l_back_color   VARCHAR2(30);
        l_icon_color   VARCHAR2(30);
    
        l_aux_date VARCHAR2(200) := '';
        l_aux_icon VARCHAR2(200) := '';
    
    BEGIN
    
        SELECT decode(i_flg_status,
                      pk_consult_req.g_consult_req_stat_reply,
                      pk_date_utils.to_char_insttimezone(i_prof,
                                                         i_dt_consult_req_tstz,
                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                      pk_consult_req.g_consult_req_stat_req,
                      pk_date_utils.to_char_insttimezone(i_prof,
                                                         i_dt_consult_req_tstz,
                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                      pk_consult_req.g_consult_req_stat_read,
                      pk_date_utils.to_char_insttimezone(i_prof,
                                                         i_dt_consult_req_tstz,
                                                         pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                      NULL) aux_date,
               
               decode(i_flg_status,
                      pk_consult_req.g_consult_req_stat_sched,
                      'CONSULT_REQ.FLG_STATUS',
                      pk_consult_req.g_consult_req_stat_reply,
                      'CONSULT_REQ.FLG_STATUS',
                      pk_consult_req.g_consult_req_stat_cancel,
                      'CONSULT_REQ.FLG_STATUS',
                      pk_consult_req.g_consult_req_stat_req,
                      'CONSULT_REQ.FLG_STATUS',
                      pk_consult_req.g_consult_req_stat_read,
                      'CONSULT_REQ.FLG_STATUS',
                      pk_consult_req.g_consult_req_stat_rejected,
                      'CONSULT_REQ.FLG_STATUS',
                      pk_consult_req.g_consult_req_stat_proc,
                      'CONSULT_REQ.FLG_STATUS',
                      NULL) aux_icon,
               
               decode(i_flg_status,
                      pk_consult_req.g_consult_req_stat_sched,
                      pk_alert_constant.g_display_type_icon,
                      pk_consult_req.g_consult_req_stat_reply,
                      pk_alert_constant.g_display_type_date_icon,
                      pk_consult_req.g_consult_req_stat_cancel,
                      pk_alert_constant.g_display_type_icon,
                      pk_consult_req.g_consult_req_stat_req,
                      pk_alert_constant.g_display_type_date,
                      pk_consult_req.g_consult_req_stat_read,
                      pk_alert_constant.g_display_type_date,
                      pk_consult_req.g_consult_req_stat_rejected,
                      pk_alert_constant.g_display_type_icon,
                      pk_consult_req.g_consult_req_stat_proc,
                      pk_alert_constant.g_display_type_icon) display_type,
               
               decode(i_flg_status,
                      pk_consult_req.g_consult_req_stat_sched,
                      pk_alert_constant.g_color_green,
                      pk_consult_req.g_consult_req_stat_reply,
                      pk_alert_constant.g_color_red,
                      pk_consult_req.g_consult_req_stat_cancel,
                      NULL,
                      pk_consult_req.g_consult_req_stat_req,
                      NULL,
                      pk_consult_req.g_consult_req_stat_read,
                      NULL,
                      pk_consult_req.g_consult_req_stat_rejected,
                      NULL,
                      pk_consult_req.g_consult_req_stat_proc,
                      pk_alert_constant.g_color_green) back_color,
               i_flg_status
          INTO l_aux_date, l_aux_icon, l_display_type, l_back_color, l_status_flg
          FROM dual;
    
        IF l_display_type IN (pk_alert_constant.g_display_type_icon, pk_alert_constant.g_display_type_date_icon)
        THEN
            IF i_flg_status IN (pk_consult_req.g_consult_req_stat_cancel)
            THEN
                l_icon_color := pk_alert_constant.g_color_icon_medium_grey;
            ELSE
                l_icon_color := pk_alert_constant.g_color_icon_dark_grey;
            END IF;
        ELSE
            l_icon_color := NULL;
        END IF;
    
        -- The function pk_utils.build_status_str is being called by get_opinion_status.
        pk_utils.build_status_string(i_display_type => l_display_type,
                                     i_flg_state    => l_status_flg,
                                     i_value_text   => l_aux_date,
                                     i_value_date   => l_aux_date,
                                     i_value_icon   => l_aux_icon,
                                     i_back_color   => l_back_color,
                                     i_icon_color   => l_icon_color,
                                     o_status_str   => o_status_str,
                                     o_status_msg   => o_status_msg,
                                     o_status_icon  => o_status_icon,
                                     o_status_flg   => o_status_flg);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
                l_lang  NUMBER := to_number(pk_login_sysconfig.get_config('LANGUAGE'));
            BEGIN
                pk_alert_exceptions.process_error(l_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'GET_CONSULT_REQ_STATUS',
                                                  l_error);
            
                pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            END;
    END get_consult_req_status;

    /**
    * This function uses the status flags returned by the get_consult_req_status, and creates the string that is to be read by FLASH in order to create an icon.
    *
    * @param i_lang                 Language.
    * @param i_prof                 Logged professional.
    * @param i_flg_status           The current value of flag_status    
    * @param i_dt_consult_req_tstz  The timestamp of the last requisition
    *
    * @author Ricardo Nuno Almeida
    * @version 2.4.3.d
    * @since 2008-Oct-17
    */
    FUNCTION get_consult_req_status_string
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status          IN consult_req.flg_status%TYPE,
        i_dt_consult_req_tstz IN consult_req.dt_consult_req_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_status_string VARCHAR2(200) := '';
        l_status_str    VARCHAR2(200);
        l_status_msg    VARCHAR2(200);
        l_status_icon   VARCHAR2(200);
        l_status_flg    VARCHAR2(1);
    BEGIN
    
        pk_logic_consult_req.get_consult_req_status(i_prof                => i_prof,
                                                    i_flg_status          => i_flg_status,
                                                    i_dt_consult_req_tstz => i_dt_consult_req_tstz,
                                                    o_status_str          => l_status_str,
                                                    o_status_msg          => l_status_msg,
                                                    o_status_icon         => l_status_icon,
                                                    o_status_flg          => l_status_flg);
    
        l_status_string := pk_utils.get_status_string(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_status_str  => l_status_str,
                                                      i_status_msg  => l_status_msg,
                                                      i_status_icon => l_status_icon,
                                                      i_status_flg  => l_status_flg);
    
        RETURN l_status_string;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'GET_CONSULT_REQ_STATUS_STRING',
                                                  l_error);
            
                --Do a reset_state just-in-case to retain previous behavior, because I don't know if the following raise_error is currently used
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            END;
        
    END get_consult_req_status_string;

    /**
    * Consult Req Logic entry funtion
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Pedro Teixeira
    * @version 2.4.3.d
    * @since 2008-Oct-14
    */
    PROCEDURE set_consult_req
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
        l_status_str  interv_icnp_ea.status_str%TYPE;
        l_status_msg  interv_icnp_ea.status_msg%TYPE;
        l_status_icon interv_icnp_ea.status_icon%TYPE;
        l_status_flg  interv_icnp_ea.status_flg%TYPE;
    
    BEGIN
        -- Validate arguments
        g_error := 'VALIDATE ARGUMENTS';
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'CONSULT_REQ',
                                                 i_expected_dg_table_name => 'CONSULT_REQ',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => NULL)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        -- Update status for insert and update events
        IF i_event_type = t_data_gov_mnt.g_event_insert
           OR i_event_type = t_data_gov_mnt.g_event_update
        THEN
            g_error := 'Loop consult_req records';
            IF i_rowids IS NOT NULL
               AND i_rowids.COUNT > 0
            THEN
                FOR r_cur IN (SELECT cr.flg_status          AS flg_status,
                                     cr.dt_consult_req_tstz AS dt_consult_req_tstz,
                                     cr.id_consult_req      AS id_consult_req
                                FROM consult_req cr
                               WHERE cr.ROWID IN (SELECT *
                                                    FROM TABLE(i_rowids)))
                LOOP
                    g_error := 'GET opinion status';
                    get_consult_req_status(i_prof                => i_prof,
                                           i_flg_status          => r_cur.flg_status,
                                           i_dt_consult_req_tstz => r_cur.dt_consult_req_tstz,
                                           o_status_str          => l_status_str,
                                           o_status_msg          => l_status_msg,
                                           o_status_icon         => l_status_icon,
                                           o_status_flg          => l_status_flg);
                
                    g_error := 'Update opinion status';
                    ts_consult_req.upd(id_consult_req_in => r_cur.id_consult_req,
                                       status_str_in     => l_status_str,
                                       status_msg_in     => l_status_msg,
                                       status_icon_in    => l_status_icon,
                                       status_flg_in     => l_status_flg);
                END LOOP;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_CONSULT_REQ',
                                                  l_error);
            
                --Do a reset_state just-in-case to retain previous behavior, because I don't know if the following raise_error is currently used
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
            END;
        WHEN OTHERS THEN
            DECLARE
                l_error t_error_out;
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_CONSULT_REQ',
                                                  l_error);
            
                --Do a reset_state just-in-case to retain previous behavior, because I don't know if the following raise_error is currently used
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
            END;
        
    END set_consult_req;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_logic_consult_req;
/
