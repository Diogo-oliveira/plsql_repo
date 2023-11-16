/*-- Last Change Revision: $Rev: 2026732 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_rehab IS
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    /**********************************************************************************************
    * This function can be used to edit a given treatment
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_patient             patient
    * %param i_workflow_type          W, S, other
    * %param i_from_state             current status
    * %param i_to_state               destination status
    * %param i_id_rehab_grid          
    * %param i_id_rehab_presc         prescription
    * %param i_id_epis_origin         origin episode
    * %param i_id_rehab_schedule      schedule
    * %param i_id_cancel_reason       cancel reason
    * %param i_cancel_notes           cancel notes
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2013-03-18
    **********************************************************************************************/
    FUNCTION set_rehab_workflow_change
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        --
        i_workflow_type  IN VARCHAR2,
        i_from_state     IN VARCHAR2,
        i_to_state       IN VARCHAR2,
        i_id_rehab_grid  IN NUMBER,
        i_id_rehab_presc IN rehab_sch_need.id_rehab_sch_need%TYPE,
        --create_visit
        i_id_epis_origin    IN episode.id_episode%TYPE,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        --
        i_id_cancel_reason IN rehab_schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN rehab_schedule.notes%TYPE DEFAULT NULL,
        --
        o_id_episode OUT episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_REHAB_WORKFLOW_CHANGE';
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'SET_REHAB_WORKFLOW_CHANGE: i_id_patient = ' || i_id_patient;
        pk_alertlog.log_debug(g_error, g_package, l_func_name);
    
        IF NOT pk_rehab.set_rehab_wf_change_nocommit(i_lang              => i_lang,
                                                     i_prof              => i_prof,
                                                     i_id_patient        => i_id_patient,
                                                     i_workflow_type     => i_workflow_type,
                                                     i_from_state        => i_from_state,
                                                     i_to_state          => i_to_state,
                                                     i_id_rehab_grid     => i_id_rehab_grid,
                                                     i_id_rehab_presc    => i_id_rehab_presc,
                                                     i_id_epis_origin    => i_id_epis_origin,
                                                     i_id_rehab_schedule => i_id_rehab_schedule,
                                                     i_id_schedule       => i_id_schedule,
                                                     i_id_cancel_reason  => i_id_cancel_reason,
                                                     i_cancel_notes      => i_cancel_notes,
                                                     i_transaction_id    => l_transaction_id,
                                                     o_id_episode        => o_id_episode,
                                                     o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('Parameters: i_id_patient=' || i_id_patient || ' @' || g_error,
                                  g_package,
                                  l_func_name);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END set_rehab_workflow_change;

BEGIN
    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);
END pk_api_rehab;
/
