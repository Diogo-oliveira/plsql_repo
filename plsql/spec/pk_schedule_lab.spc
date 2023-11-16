/*-- Last Change Revision: $Rev: 2028955 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:57 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_schedule_lab AS

    /* returns all LAB appointments for TODAY, scheduled for the given profissional's intitution.
    * Only appointments WITHOUT requisition. That means no row in table schedule_analysis.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    *
    * @RETURN t_table_sch_lab_daily_apps   nested table of t_rec_sch_lab_daily_apps
    *
    * @author  Telmo
    * @version 2.6.3.8
    * @date    03-09-2013
    */
    FUNCTION get_today_lab_appoints
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_day  IN schedule.dt_begin_tstz%TYPE DEFAULT NULL
    ) RETURN t_table_sch_lab_daily_apps;

    /*
    *  ALERT-303513. Details of a lab schedule 
    */
    PROCEDURE get_sch_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type
    );

    FUNCTION get_sch_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    *  ALERT-303513. History of a lab schedule 
    */
    PROCEDURE get_sch_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type
    );

    FUNCTION get_sch_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * ALERT-305894. Cancel schedules connected to a specific req
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_req                      requisition id
    * @param i_id_cancel_reason            common cancel reason to stamp all canceled schedules
    * @param i_cancel_notes                (optional) common cancel notes
    * @param i_transaction_id              sch remote transaction id
    * @param o_error                       error info
    *
    * @RETURN true/false
    *
    * @author  Telmo
    * @version 2.6.4
    * @date    13-01-2015
    */
    FUNCTION cancel_req_schedules
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_req           IN schedule_analysis.id_analysis_req%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE DEFAULT NULL,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    ----------- PUBLIC VARS, CONSTANTS ---------------
    g_error         VARCHAR2(4000);
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);
END pk_schedule_lab;
/
