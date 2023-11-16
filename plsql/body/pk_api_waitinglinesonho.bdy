/*-- Last Change Revision: $Rev: 790615 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2010-11-30 17:09:28 +0000 (ter, 30 nov 2010) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_waitinglinesonho IS

    /**
    * Process new "efectivação" event.
    * This function is to be used only by the interfaces team.
    * Commit or rollback is controlled by interfaces.
    *
    * Interfaces must call this function with all I_WL_PATIENT_SONHO values set, except  MACHINE_NAME and in some circunstances ID_EPISODE.
    * ID_EPISODE should not be set when the Waiting Room is working alone, without Alert clinical software.
    * The fields PATIENT_ID, CLIN_PROF_ID, CONSULT_ID, PROF_ID, ID_INSTITUTION AND ID_EPISODE represent ALERT IDs and not ADT system IDs.
    * The field NUM_PROC represents the patient process number in the ADT system.
    *
    * CLIN_PROF_ID is the doctor's id
    * CONSULT_ID is the clinical service id
    * PROF_ID is the admin id
    *
    * Others fields names are self explanatory.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_WL_PATIENT_SONHO The patient info
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Luís Gaspar
    * @version 1.0
    * @since   23-11-2006
    */
    FUNCTION intf_efectivar_event
    (
        i_lang             IN language.id_language%TYPE,
        i_wl_patient_sonho IN wl_patient_sonho%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
    
        g_error := 'INSERT INTO WL_PATIENT_SONHO';
        INSERT INTO wl_patient_sonho
        VALUES i_wl_patient_sonho;
    
        g_error := 'CALL pk_wlcore.set_end_line_intf: id_prof: ' || i_wl_patient_sonho.prof_id || ' id_institution: ' ||
                   i_wl_patient_sonho.id_institution || ' id_patient: ' || i_wl_patient_sonho.patient_id;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wlcore.set_end_line_intf(i_lang       => i_lang,
                                           i_prof       => profissional(i_wl_patient_sonho.prof_id,
                                                                        i_wl_patient_sonho.id_institution,
                                                                        0),
                                           i_id_patient => i_wl_patient_sonho.patient_id,
                                           o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INTF_EFECTIVAR_EVENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END intf_efectivar_event;

    /**
    * This procedure performs error handling and is used internally by other functions in this package,
    * especially by those that are used inside SELECT statements.
    * Private procedure.
    *
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    PROCEDURE error_handling
    (
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2
    ) IS
    BEGIN
        pk_alertlog.log_error(i_func_proc_name || ': ' || i_error || ' -- ' || i_sqlerror, g_package_name);
    END error_handling;

    /**
    * This function performs error handling and is used internally by other functions in this package.
    * Private function.
    *
    * @param i_lang                Language identifier.
    * @param i_func_proc_name      Function or procedure name.
    * @param i_error               Error message to log.
    * @param i_sqlerror            SQLERRM.
    * @param o_error               Message to be shown to the user.
    *
    * @return  FALSE (in any case, in order to allow a RETURN error_handling statement in exception
    * handling blocks).
    *
    * @author   Nuno Guerreiro
    * @version  alpha
    * @since    2007/04/23
    */
    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        pk_alert_exceptions.reset_error_state;
        pk_alert_exceptions.process_error(i_lang,
                                          SQLCODE,
                                          i_sqlerror,
                                          i_error,
                                          g_package_owner,
                                          g_package_name,
                                          i_func_proc_name,
                                          o_error);
        pk_utils.undo_changes;
        RETURN FALSE;
    
    END error_handling;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_waitinglinesonho;
/
