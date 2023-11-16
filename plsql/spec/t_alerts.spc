/*-- Last Change Revision: $Rev: 1356745 $*/
/*-- Last Change by: $Author: joana.barroso $*/
/*-- Date of last change: $Date: 2012-07-26 12:32:51 +0100 (qui, 26 jul 2012) $*/

CREATE OR REPLACE PACKAGE t_alerts IS

    -- Author  : Paulo Almeida
    -- Created : 2008-08-07 18:00:00
    -- Purpose : Functions for DML operations on sys_alert' tables.

    FUNCTION ins_sys_alert_event_detail
    (
        i_id_language        IN LANGUAGE.id_language%TYPE,
        i_id_sys_alert_event IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        i_dt_event           IN sys_alert_event_detail.dt_event%TYPE,
        i_id_professional    IN sys_alert_event_detail.id_professional%TYPE,
        i_prof_nick_name     IN sys_alert_event_detail.prof_nick_name%TYPE,
        i_desc_detail        IN sys_alert_event_detail.desc_detail%TYPE,
        i_id_detail_group    IN sys_alert_event_detail.id_detail_group%TYPE,
        i_desc_detail_group  IN sys_alert_event_detail.desc_detail_group%TYPE,
        o_id_sys_alert_event_detail OUT sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION update_sys_alert_event_detail
    (
        i_id_language               IN LANGUAGE.id_language%TYPE,
        i_id_sys_alert_event        IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        i_id_sys_alert_event_detail IN sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        i_dt_event                  IN sys_alert_event_detail.dt_event%TYPE,
        i_id_professional           IN sys_alert_event_detail.id_professional%TYPE,
        i_prof_nick_name            IN sys_alert_event_detail.prof_nick_name%TYPE,
        i_desc_detail               IN sys_alert_event_detail.desc_detail%TYPE,
        i_id_detail_group           IN sys_alert_event_detail.id_detail_group%TYPE,
        i_desc_detail_group         IN sys_alert_event_detail.desc_detail_group%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION delete_sys_alert_event_detail
    (
        i_id_language               IN LANGUAGE.id_language%TYPE,
        i_id_sys_alert_event        IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        i_id_sys_alert_event_detail IN sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

END t_alerts;
/
