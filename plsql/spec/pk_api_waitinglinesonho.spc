/*-- Last Change Revision: $Rev: 372225 $*/
/*-- Last Change by: $Author: claudio.ferreira $*/
/*-- Date of last change: $Date: 2010-01-08 10:42:48 +0000 (sex, 08 jan 2010) $*/

CREATE OR REPLACE PACKAGE pk_api_waitinglinesonho IS

    -- Author  : Rui Spratley
    -- Created : 23-05-2008
    -- Purpose : API for INTER_ALERT

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
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_wl_patient_sonho IN wl_patient_sonho%ROWTYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /* Stores log error messages. */
    g_error VARCHAR2(32000);
    /* Stores the package name. */
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';
    g_ret BOOLEAN;

END pk_api_waitinglinesonho;
/
