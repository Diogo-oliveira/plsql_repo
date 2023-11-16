/*-- Last Change Revision: $Rev: 1356745 $*/
/*-- Last Change by: $Author: joana.barroso $*/
/*-- Date of last change: $Date: 2012-07-26 12:32:51 +0100 (qui, 26 jul 2012) $*/

CREATE OR REPLACE PACKAGE BODY t_alerts IS

    g_package_name VARCHAR2(32);
    g_error        VARCHAR2(4000);
    g_retval       BOOLEAN;

    FUNCTION next_id_sys_alert_event_detail(i_id_sys_alert_event IN NUMBER) RETURN NUMBER IS
        l_next NUMBER;
    BEGIN
        SELECT MAX(a.id_sys_alert_event_detail) + 1
          INTO l_next
          FROM sys_alert_event_detail a
         WHERE a.id_sys_alert_event = i_id_sys_alert_event;
    
        RETURN l_next;
    END next_id_sys_alert_event_detail;

    /**************************************************************************
    * Inserts a record in table SYS_ALERT_EVENT_DETAIL
    *
    * @author  Paulo Almeida
    * @since   2008/08/08
    **************************************************************************/
    FUNCTION ins_sys_alert_event_detail
    (
        i_id_language        IN language.id_language%TYPE,
        i_id_sys_alert_event IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        i_dt_event           IN sys_alert_event_detail.dt_event%TYPE,
        i_id_professional    IN sys_alert_event_detail.id_professional%TYPE,
        i_prof_nick_name     IN sys_alert_event_detail.prof_nick_name%TYPE,
        i_desc_detail        IN sys_alert_event_detail.desc_detail%TYPE,
        i_id_detail_group    IN sys_alert_event_detail.id_detail_group%TYPE,
        i_desc_detail_group  IN sys_alert_event_detail.desc_detail_group%TYPE,
        o_id_sys_alert_event_detail OUT sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sys_alert_event_detail sys_alert_event_detail.id_sys_alert_event_detail%TYPE;
    BEGIN
        -- get the next id_sys_alert_detail
        l_id_sys_alert_event_detail := next_id_sys_alert_event_detail(i_id_sys_alert_event);
    
        INSERT INTO sys_alert_event_detail
            (id_sys_alert_event,
             id_sys_alert_event_detail,
             dt_sys_alert_event_detail_tstz,
             dt_event,
             id_professional,
             prof_nick_name,
             desc_detail,
             id_detail_group,
             desc_detail_group)
        VALUES
            (i_id_sys_alert_event,
             nvl(l_id_sys_alert_event_detail, 1),
             current_timestamp,
             i_dt_event,
             i_id_professional,
             i_prof_nick_name,
             i_desc_detail,
             i_id_detail_group,
             i_desc_detail_group);
    
        o_id_sys_alert_event_detail := l_id_sys_alert_event_detail;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              'ALERT',
                                              'T_ALERTS',
                                              'INS_SYS_ALERT_DETAIL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_sys_alert_event_detail;

    FUNCTION ins_sys_alert_event_detail
    (
        i_id_language        IN language.id_language%TYPE,
        i_id_sys_alert_event IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        i_dt_event           IN sys_alert_event_detail.dt_event%TYPE,
        i_id_professional    IN sys_alert_event_detail.id_professional%TYPE,
        i_prof_nick_name     IN sys_alert_event_detail.prof_nick_name%TYPE,
        i_desc_detail        IN sys_alert_event_detail.desc_detail%TYPE,
        i_id_detail_group    IN sys_alert_event_detail.id_detail_group%TYPE,
        i_desc_detail_group  IN sys_alert_event_detail.desc_detail_group%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_sys_alert_event_detail sys_alert_event_detail.id_sys_alert_event_detail%TYPE;
    BEGIN
    
        g_error  := 'CALL  t_alerts.ins_sys_alert_event_detail';
        g_retval := t_alerts.ins_sys_alert_event_detail(i_id_language               => i_id_language,
                                                        i_id_sys_alert_event        => i_id_sys_alert_event,
                                                        i_dt_event                  => i_dt_event,
                                                        i_id_professional           => i_id_professional,
                                                        i_prof_nick_name            => i_prof_nick_name,
                                                        i_desc_detail               => i_desc_detail,
                                                        i_id_detail_group           => i_id_detail_group,
                                                        i_desc_detail_group         => i_desc_detail_group,
                                                        o_id_sys_alert_event_detail => l_id_sys_alert_event_detail,
                                                        o_error                     => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_error('ERROR: ' || g_error);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              '',
                                              'ALERT',
                                              'T_ALERTS',
                                              'INS_SYS_ALERT_DETAIL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_sys_alert_event_detail;

    /**************************************************************************
    * Updates a record in table SYS_ALERT_EVENT_DETAIL
    *
    * @author  Paulo Almeida
    * @since   2008/08/08
    **************************************************************************/
    FUNCTION update_sys_alert_event_detail
    (
        i_id_language               IN language.id_language%TYPE,
        i_id_sys_alert_event        IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        i_id_sys_alert_event_detail IN sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        i_dt_event                  IN sys_alert_event_detail.dt_event%TYPE,
        i_id_professional           IN sys_alert_event_detail.id_professional%TYPE,
        i_prof_nick_name            IN sys_alert_event_detail.prof_nick_name%TYPE,
        i_desc_detail               IN sys_alert_event_detail.desc_detail%TYPE,
        i_id_detail_group           IN sys_alert_event_detail.id_detail_group%TYPE,
        i_desc_detail_group         IN sys_alert_event_detail.desc_detail_group%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error VARCHAR2(4000) := 'UPDATE_SYS_ALERT_EVENT_DETAIL';
    
    BEGIN
    
        UPDATE sys_alert_event_detail
           SET dt_event          = i_dt_event,
               id_professional   = i_id_professional,
               prof_nick_name    = i_prof_nick_name,
               desc_detail       = i_desc_detail,
               id_detail_group   = i_id_detail_group,
               desc_detail_group = i_desc_detail_group
         WHERE id_sys_alert_event = i_id_sys_alert_event
           AND id_sys_alert_event_detail = i_id_sys_alert_event_detail;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              'ALERT',
                                              'T_ALERTS',
                                              'UPDATE_SYS_ALERT_EVENT_DETAIL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_sys_alert_event_detail;

    /**************************************************************************
    * Deletes a record in table SYS_ALERT_EVENT_DETAIL
    *
    * @author  Paulo Almeida
    * @since   2008/08/08
    **************************************************************************/
    FUNCTION delete_sys_alert_event_detail
    (
        i_id_language               IN language.id_language%TYPE,
        i_id_sys_alert_event        IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        i_id_sys_alert_event_detail IN sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error VARCHAR2(4000) := 'DELETE_SYS_ALERT_EVENT_DETAIL';
    
    BEGIN
        DELETE sys_alert_event_detail
         WHERE id_sys_alert_event = i_id_sys_alert_event
           AND id_sys_alert_event_detail = i_id_sys_alert_event_detail;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              'ALERT',
                                              'T_ALERTS',
                                              'DELETE_SYS_ALERT_EVENT_DETAIL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END delete_sys_alert_event_detail;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END t_alerts;
/
