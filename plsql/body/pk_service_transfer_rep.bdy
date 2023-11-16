/*-- Last Change Revision: $Rev: 2027709 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:04 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_service_transfer_rep AS

    /**************************************************************************
    * get the service transfer detail for reports
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID
    * @param i_id_epis_prof_resp      Epis prof resp ID (service transfer ID)
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_flg_report_type        Report type: C-complete report; D-forensic report
    * @param i_start_date             Start date to be considered
    * @param i_end_date               End date to be considered
    *
    * @param o_data                   Data cursor. Labels, format types and status
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.1                                 
    * @since                          2011/05/24                                 
    **************************************************************************/

    FUNCTION get_rep_service_transfer
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prof_resp IN epis_prof_resp.id_epis_prof_resp%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2,
        i_flg_report_type   IN VARCHAR2,
        i_start_date        IN VARCHAR2,
        i_end_date          IN VARCHAR2,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    
        l_id_patient        patient.id_patient%TYPE;
        l_id_visit          visit.id_visit%TYPE;
        l_id_episode        episode.id_episode%TYPE;
        l_id_epis_prof_resp table_number := table_number();
        l_function_name     VARCHAR2(30 CHAR) := 'GET_REP_SERVICE_TRANSFER';
    
    BEGIN
    
        IF (i_id_epis_prof_resp IS NULL)
        THEN
            g_error := 'ANALYSING SCOPE TYPE: i_flg_scope: ' || i_scope || '; i_scope: ' || i_scope_type;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_scope      => i_scope,
                                                  i_scope_type => i_scope_type,
                                                  o_patient    => l_id_patient,
                                                  o_visit      => l_id_visit,
                                                  o_episode    => l_id_episode,
                                                  o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Convert start date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Convert end date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --the end day should also be included in the filter
            g_error := 'CALL pk_date_utils.add_days_to_tstz';
            pk_alertlog.log_debug(g_error);
            l_end_date := pk_date_utils.add_days_to_tstz(i_timestamp => l_end_date, i_days => 1);
        
            g_error := 'GET ID_EPIS_PROF_RESP THAT MATCH WITH FILTERS';
            pk_alertlog.log_debug(g_error);
            SELECT epr.id_epis_prof_resp
              BULK COLLECT
              INTO l_id_epis_prof_resp
              FROM epis_prof_resp epr
             INNER JOIN episode e
                ON e.id_episode = epr.id_episode
             WHERE (epr.id_episode = l_id_episode OR l_id_episode IS NULL)
               AND (e.id_visit = l_id_visit OR l_id_visit IS NULL)
               AND (e.id_patient = l_id_patient OR l_id_patient IS NULL)
               AND epr.dt_request_tstz >= nvl(l_start_date, epr.dt_request_tstz)
               AND epr.dt_request_tstz <= nvl(l_end_date, epr.dt_request_tstz)
               AND epr.flg_transf_type = pk_service_transfer.g_transfer_flg_service_s;
        
        ELSE
            l_id_epis_prof_resp.extend;
            l_id_epis_prof_resp(l_id_epis_prof_resp.count) := i_id_epis_prof_resp;
        END IF;
    
        IF l_id_epis_prof_resp IS NOT NULL
           AND l_id_epis_prof_resp.count > 0
        THEN
            g_error := 'CALL GET_SERV_TRANS_DET_HIST FUNCTION';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_service_transfer.get_serv_trans_det_hist(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_id_epis_prof_resp => l_id_epis_prof_resp,
                                                               i_flg_screen        => CASE i_flg_report_type
                                                                                          WHEN g_report_complete_c THEN
                                                                                           pk_service_transfer.g_detail_d
                                                                                          WHEN g_report_detailed_d THEN
                                                                                           pk_service_transfer.g_history_h
                                                                                      END,
                                                               o_data              => o_data,
                                                               o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
            pk_types.open_my_cursor(i_cursor => o_data);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rep_service_transfer;

    /**************************************************************************
    * get all transfer from given institution and patient.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_prof                   Profissional ID         
    *
    * @param o_flag_my_service        
    * @param o_list                   Data cursor           
    * @param o_error                  Error message
    *                                                                         
    * @author                         CARLOS FERREIRA                            
    * @since                          2007/01/27                                 
    **************************************************************************/
    FUNCTION get_pat_transfer_list
    (
        i_lang            IN NUMBER,
        i_id_episode      IN NUMBER,
        i_id_patient      IN NUMBER,
        i_prof            IN profissional,
        o_flag_my_service OUT NUMBER,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_PAT_TRANSFER_LIST';
    
    BEGIN
    
        g_error := 'CALL  PK_SERVICE_TRANSFER.GET_PAT_TRANSFER_LIST FUNCTION WITH ID_EPISODE: ' || i_id_episode ||
                   ' AND ID_PATIENT: ' || i_id_patient;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_service_transfer.get_pat_transfer_list(i_lang            => i_lang,
                                                         i_id_episode      => i_id_episode,
                                                         i_id_patient      => i_id_patient,
                                                         i_prof            => i_prof,
                                                         o_flag_my_service => o_flag_my_service,
                                                         o_list            => o_list,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pat_transfer_list;

    FUNCTION get_transfer_detail
    (
        i_lang              IN NUMBER,
        i_area              IN VARCHAR2, --- A, B,C
        i_prof              IN profissional,
        i_id_epis_prof_resp IN NUMBER,
        o_title             OUT pk_types.cursor_type,
        o_data              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_TRANSFER_DETAIL';
    
    BEGIN
    
        g_error := 'CALL  PK_SERVICE_TRANSFER.get_transfer_detail FUNCTION WITH I_ID_EPIS_PROF_RESP: ' ||
                   i_id_epis_prof_resp;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_service_transfer.get_transfer_detail(i_lang              => i_lang,
                                                       i_area              => i_area,
                                                       i_prof              => i_prof,
                                                       i_id_epis_prof_resp => i_id_epis_prof_resp,
                                                       o_title             => o_title,
                                                       o_data              => o_data,
                                                       o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_title);
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_transfer_detail;

BEGIN
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_service_transfer_rep;
/
