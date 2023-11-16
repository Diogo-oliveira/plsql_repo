/*-- Last Change Revision: $Rev: 2027892 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wlinternal IS

    /**
    * This function contains the common logic for all the GET_NEXT_CALL functions. 
    * It is not actually called by the MW tier, but by other functions in other packages. 
    * Create next call after having a ticket.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_ID_PROF  professional, institution and software ids
    * @param   I_ID_QUEUES The queues to look for tickets.
    * @param   O_ID_WAITING_LINE The ticket id
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   15-11-2006
    */
    FUNCTION get_next_call_queue_internal
    (
        i_lang            IN language.id_language%TYPE,
        i_id_prof         IN profissional,
        i_id_queues       IN table_number,
        i_flg_prior_too   IN NUMBER,
        o_wl_waiting_line OUT wl_waiting_line%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_wl_waiting_line_row wl_waiting_line%ROWTYPE;
        l_rows                table_varchar;
    BEGIN
    
        IF i_id_queues IS NOT NULL
           AND i_id_queues.count > 0
        THEN
        
            g_error := 'GET FIRST WAITING LINE al_status_espera = ' || pk_alert_constant.g_wr_wl_status_e ||
                       ' I_ID_QUEUES.COUNT = ' || i_id_queues.count || ' FLG_PRIOR_TOO = ' || i_flg_prior_too;
            pk_alertlog.log_debug(g_error, g_package_name);
        
            IF i_flg_prior_too = 1
            THEN
                BEGIN
                    SELECT *
                      INTO l_wl_waiting_line_row
                      FROM (SELECT w.*
                              FROM wl_waiting_line w
                             INNER JOIN wl_queue wq
                                ON wq.id_wl_queue = w.id_wl_queue
                             WHERE w.id_wl_queue IN (SELECT *
                                                       FROM TABLE(i_id_queues))
                               AND w.flg_wl_status = pk_alert_constant.g_wr_wl_status_e
                               AND trunc(w.dt_begin_tstz) = trunc(w.dt_begin_tstz)
                             ORDER BY wq.flg_priority DESC, w.dt_begin_tstz ASC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_wl_waiting_line_row := NULL;
                END;
            ELSE
                BEGIN
                    SELECT *
                      INTO l_wl_waiting_line_row
                      FROM (SELECT w.*
                              FROM wl_waiting_line w
                             WHERE w.id_wl_queue IN (SELECT *
                                                       FROM TABLE(i_id_queues))
                               AND w.flg_wl_status = pk_alert_constant.g_wr_wl_status_e
                               AND trunc(w.dt_begin_tstz) = trunc(w.dt_begin_tstz)
                             ORDER BY w.dt_begin_tstz ASC)
                     WHERE rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_wl_waiting_line_row := NULL;
                END;
            END IF;
            IF l_wl_waiting_line_row.id_wl_waiting_line IS NOT NULL
            --IF i_id_queues IS NOT NULL
            THEN
                g_error := 'UPDATE WL_WAITING_LINE.FLG_WL_STATUS';
                pk_alertlog.log_debug(g_error, g_package_name);
                ts_wl_waiting_line.upd(id_wl_waiting_line_in => l_wl_waiting_line_row.id_wl_waiting_line,
                                       dt_call_tstz_in       => current_timestamp,
                                       dt_call_tstz_nin      => FALSE,
                                       flg_wl_status_in      => pk_alert_constant.g_wr_wl_status_x,
                                       flg_wl_status_nin     => FALSE,
                                       id_prof_call_in       => i_id_prof.id,
                                       rows_out              => l_rows);
            
                g_error := 'PROCESS UPDATE';
                pk_alertlog.log_debug(g_error, g_package_name);
                t_data_gov_mnt.process_update(i_lang, i_id_prof, 'WL_WAITING_LINE', l_rows, o_error);
            
                o_wl_waiting_line := l_wl_waiting_line_row;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NEXT_CALL_QUEUE_INTERNAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_next_call_queue_internal;

    /**
    * Get last ticket called by a professional.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_ID_PROF            professional, institution and software ids
    * @param   o_wl_waiting_line    Ticket Info    
    * @param   O_ERROR              error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Sofia Mendes
    * @version 2.5.1.3
    * @since   24-Nov-2010
    *    
    */
    FUNCTION get_last_called_ticket
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        o_wl_waiting_line OUT wl_waiting_line%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        BEGIN
        
            g_error := 'GET LAST CALLED TICKET. id_prof: ' || i_prof.id;
            SELECT *
              INTO o_wl_waiting_line
              FROM (SELECT wwl.*
                      FROM wl_waiting_line wwl
                      JOIN wl_mach_prof_queue wlmpq
                        ON wlmpq.id_wl_queue = wwl.id_wl_queue
                       AND wwl.id_prof_call = wlmpq.id_professional
                     WHERE wwl.id_prof_call = i_prof.id
                       AND wwl.flg_wl_status = pk_alert_constant.g_wr_wl_status_x
                     ORDER BY wwl.dt_call_tstz DESC) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAST_CALLED_TICKET',
                                              o_error);
        
            RETURN FALSE;
    END get_last_called_ticket;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_wlinternal;
/
