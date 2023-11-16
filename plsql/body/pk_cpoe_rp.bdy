/*-- Last Change Revision: $Rev: 2026917 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_cpoe_rp IS

    -- Purpose : Computerized Prescription Order Entry (CPOE) REPORTS API database package

    -- logging variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    /********************************************************************************************
    * get a patient's prescription tasks report
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 internal id of the patient 
    * @param       i_episode                 internal id of the episode 
    * @param       i_process                 internal id of the cpoe process 
    * @param       o_cpoe_info               cursor containing information about prescription information
    * @param       o_cpoe_task               cursor containing information about prescription's tasks 
    * @param       o_error                   error message
    *
    * @value       i_process                 {*} <ID>   cursors will have given process information
    *                                        {*} <NULL> cursors will have last/current process information 
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 2009/12/04
    ********************************************************************************************/
    FUNCTION get_cpoe_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_process       IN cpoe_process.id_cpoe_process%TYPE,
        i_task_ids      IN table_number,
        i_task_type_ids IN table_number,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_cpoe_info     OUT pk_types.cursor_type,
        o_cpoe_task     OUT pk_types.cursor_type,
        o_execution     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_dummy pk_types.cursor_type;
    BEGIN
        -- call pk_cpoe.get_cpoe_report function
        IF NOT pk_cpoe.get_cpoe_report(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_patient       => i_patient,
                                       i_episode       => i_episode,
                                       i_process       => i_process,
                                       i_task_ids      => i_task_ids,
                                       i_task_type_ids => i_task_type_ids,
                                       i_dt_start      => i_dt_start,
                                       i_dt_end        => i_dt_end,
                                       o_cpoe_info     => o_cpoe_info,
                                       o_cpoe_task     => o_cpoe_task,
                                       o_execution     => o_execution,
                                       o_med_admin     => l_dummy,
                                       o_proc_plan     => l_dummy,
                                       o_error         => o_error)
        THEN
            g_error := 'error found while calling pk_cpoe.get_cpoe_report function';
            RAISE l_exception;
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
                                              'GET_CPOE_REPORT',
                                              o_error);
            pk_types.open_my_cursor(o_cpoe_info);
            pk_types.open_my_cursor(o_cpoe_task);
            RETURN FALSE;
    END get_cpoe_report;

    FUNCTION get_professional_br_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        o_prof    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
    
        IF NOT pk_backoffice.get_professional_br_report(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_id_prof => i_id_prof,
                                                        o_prof    => o_prof,
                                                        o_error   => o_error)
        THEN
            RAISE l_exception;
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
                                              'GET_PROFESSIONAL_BR_REPORT',
                                              o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
        
    END get_professional_br_report;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
END pk_cpoe_rp;
/
