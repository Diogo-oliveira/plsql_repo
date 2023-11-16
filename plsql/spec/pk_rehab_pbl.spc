/*-- Last Change Revision: $Rev: 2028923 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_rehab_pbl IS

    /********************************************************************************************
    * Retrieve all patient rehabilitation procedures ongoing
    *
    * %param i_lang         language id
    * %param i_prof         profissional
    * %param i_id_patient   patient id
    *
    * @return               list of tasks
    *
    ********************************************************************************************/
    FUNCTION get_ongoing_tasks_rehab
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list;

    /********************************************************************************************
    * Suspend a rehabilitation procedure
    *
    * %param i_lang                   language id
    * %param i_prof                   profissional
    * %param i_id_rehab_presc         procedure id to suspend
    * %param i_flg_reason           what is the suspension reason
    * %param o_msg_error              error message when cancel wasn't possible
    * %param o_error                  error object in case of exception
    *
    * @return    TRUE on success, FALSE otherwise
    ********************************************************************************************/
    FUNCTION suspend_task_rehab
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_flg_reason     IN VARCHAR2,
        o_msg_error      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Reactivate a supended rehabilitation procedure
    *
    * %param i_lang                   language id
    * %param i_prof                   profissional
    * %param i_id_rehab_presc         dressing id to suspend
    * %param o_msg_error              error message when cancel wasn't possible
    * %param o_error                  error object in case of exception
    *
    * @return    TRUE on success, FALSE otherwise
    ********************************************************************************************/
    FUNCTION reactivate_task_rehab
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        o_msg_error      OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehb_diag_viewer_checklit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_rehb_sess_viewer_checklit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2;

	
    -- GLOBALS
    g_sysdate       DATE;
    g_sysdate_tstz  TIMESTAMP
        WITH TIME ZONE;
    g_error         VARCHAR2(2000);
    g_package_owner VARCHAR2(32);
    g_package_name  VARCHAR2(32);
    g_exception EXCEPTION;

END pk_rehab_pbl;
/
