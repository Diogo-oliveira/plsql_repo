/*-- Last Change Revision: $Rev: 2029001 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:13 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_suspended_tasks IS

    /*
    * Get all ongoing tasks from within exams, lab tests, schedules, etc.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_PATIENT         Patient ID
    * @param   O_SYS_LIST           Cursor containing the areas that have to be shown on the UX (e.g. "Exams", "Lab tests", etc)
    * @param   O_TASKS_LIST         Cursor containing all ongoing tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   10-MAY-2010
    *
    */
    FUNCTION get_ongoing_tasks_all
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_sys_list   OUT pk_types.cursor_type,
        o_tasks_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get all reactivatable tasks from within exams, lab tests, schedules, etc.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     SUSP_ACTION ID
    * @param   O_SYS_LIST           Cursor containing the areas that have to be shown on the UX (e.g. "Exams", "Lab tests", etc)
    * @param   O_TASKS_LIST         Cursor containing all ongoing tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   14-MAY-2010
    *
    */

    FUNCTION get_reactivatable_tasks_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_action.id_susp_action%TYPE,
        o_sys_list       OUT pk_types.cursor_type,
        o_tasks_list     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get all tasks associated to the ID_SUSP_ACTION from within exams, lab tests, schedules, etc.
    * Functions for each ALERT area MUST raise exceptions.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     SUSP_ACTION ID
    * @param   O_SYS_LIST           Cursor containing the areas that have to be shown on the UX (e.g. "Exams", "Lab tests", etc)
    * @param   O_SUSP_TASKS_LIST    Cursor containing all suspended tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_NSUSP_TASKS_LIST   Cursor containing all non-suspended tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_REAC_TASKS_LIST    Cursor containing all reactivated tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_NREAC_TASKS_LIST   Cursor containing all non-reactivated tasks and the corresponding area (e.g. "Lab 01" for the area "Lab tests")
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   9-JUN-2010
    *
    */
    FUNCTION get_action_tasks_all
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_susp_action   IN susp_action.id_susp_action%TYPE,
        o_sys_list         OUT pk_types.cursor_type,
        o_susp_tasks_list  OUT pk_types.cursor_type,
        o_nsusp_tasks_list OUT pk_types.cursor_type,
        o_reac_tasks_list  OUT pk_types.cursor_type,
        o_nreac_tasks_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get all tasks from within exams, lab tests, schedules, etc. according to the i_wf_status
    * Functions for each ALERT area MUST raise exceptions.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     SUSP_ACTION ID
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   9-JUN-2010
    *
    */
    FUNCTION get_wfstatus_tasks_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_action.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_wfstatus_list;

    /*
    * Suspend the ongoing tasks selected by the professional from within exams, lab tests, schedules, etc.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_TASK_LIST          Table of IDs from the corresponding task (e.g., for an imaging exam, it is the ID_EXAM_REQ_DET)
    * @param   I_AREA_LIST          Table of Areas from each one of the tasks in I_TASK_LIST
    * @param   I_FLG_REASON         Reason for the WF suspension: 'D' (Death)
    * @param   O_SUSP_ACTION        ID for the SUSPENSION_ACTION created. It is sent to the UX to update the DEATH_REGISTRY table
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   10-MAY-2010
    *
    */
    FUNCTION suspend_tasks_all
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_task_list   IN table_number,
        i_area_list   IN table_varchar,
        i_flg_reason  IN VARCHAR2,
        o_susp_action OUT susp_action.id_susp_action%TYPE,
        o_msg_error   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Reactivate the suspended tasks selected by the professional from within exams, lab tests, schedules, etc.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_SUSP_TASK          Table of IDs from ID_SUSP_TASK
    * @param   I_TASK_LIST          Table of IDs from the corresponding task (e.g., for an imaging exam, it is the ID_EXAM_REQ_DET)
    * @param   I_AREA_LIST          Table of Areas from each one of the tasks in I_TASK_LIST
    * @param   O_MSG_ERROR          Message to send to the UX in case one of the functions has some kind of error
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   21-MAY-2010
    *
    */
    FUNCTION reactivate_tasks_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_susp_task IN table_number,
        i_task_list IN table_number,
        i_area_list IN table_varchar,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Updates the suspension status according to what was returned on each area's specific function
    *
    * @param   I_LANG               language associated to the professional executing the request   
    * @param   I_RETURN_SUSPENSION  Result of each area specific function: TRUE if success, FALSE otherwise
    * @param   I_RETURN_REACTIVATIONResult of each area specific function: TRUE if success, FALSE otherwise   
    * @param   I_MSG_ERROR          Original message
    * @param   I_MSG_ERROR_FUNC     Message returned by the specific funcion (from each area)
    * @param   O_MSG_ERROR          Result message (will only be different from I_MSG_ERROR if I_MSG_ERROR_FUNC is not NULL)
    * @param   O_FLG_STATUS         Return value for the FLG_STATUS
    * @param   O_ERROR              warning/error message
    *
    * @RETURN  TRUE if success, FALSE otherwise
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   10-MAY-2010
    *
    */
    FUNCTION suspension_status
    (
        i_lang                IN language.id_language%TYPE,
        i_return_suspension   IN BOOLEAN DEFAULT NULL,
        i_return_reactivation IN BOOLEAN DEFAULT NULL,
        i_msg_error           IN VARCHAR2,
        i_msg_error_func      IN VARCHAR2,
        o_msg_error           OUT VARCHAR2,
        o_flg_status          OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Provide list of reactivatable MONITORIZATION tasks for the patient death feature. All the monits must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_labs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    /*
    * Provide list of reactivatable MONITORIZATION tasks for the patient death feature. All the monits must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_ioe
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    /*
    * Provide list of reactivatable MONITORIZATION tasks for the patient death feature. All the monits must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_proc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    /*
    * Provide list of reactivatable MONITORIZATION tasks for the patient death feature. All the monits must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_sch
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    /*
    * Provide list of reactivatable HIDRIC tasks for the patient death feature. All the hidrics must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_hidr
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    /*
    * Provide list of reactivatable MONITORIZATION tasks for the patient death feature. All the monits must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_med
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    /*
    * Provide list of reactivatable POSITIONINGS tasks for the patient death feature. All the positionings must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_posit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    /*
    * Provide list of reactivatable PHYSICAL THERAPY tasks for the patient death feature. All the positionings must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param   I_LANG               language associated to the professional executing the request
    * @param   I_PROF               Professional type
    * @param   I_ID_SUSP_ACTION     Corresponding ID_SUSP_ACTION
    * @param   I_WFSTATUS           Pretended WF Status (from the SUSP_TASK table)
    *
    * @RETURN  tf_tasks_list (table of tr_tasks_list)
    * @author  Rui de Sousa Neves
    * @version 2.6.0.3
    * @since   18-MAY-2010
    *
    */
    FUNCTION get_wfstatus_tasks_physio
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list;

    -- Flg_Context configuration per area
    g_flgcontext_labs       CONSTANT sys_list_group_rel.flg_context%TYPE := 'LB'; -- Lab tests       
    g_flgcontext_imaging    CONSTANT sys_list_group_rel.flg_context%TYPE := 'IM'; -- Imaging and Other exams
    g_flgcontext_procedures CONSTANT sys_list_group_rel.flg_context%TYPE := 'PC'; -- Procedures
    g_flgcontext_schedules  CONSTANT sys_list_group_rel.flg_context%TYPE := 'SC'; -- Schedules
    g_flgcontext_medication CONSTANT sys_list_group_rel.flg_context%TYPE := 'MD'; -- Medication
    g_flgcontext_io         CONSTANT sys_list_group_rel.flg_context%TYPE := 'IO'; -- Intake and output
    g_flgcontext_monit      CONSTANT sys_list_group_rel.flg_context%TYPE := 'MN'; -- Monitorizations
    g_flgcontext_transp     CONSTANT sys_list_group_rel.flg_context%TYPE := 'T'; -- Transports
    g_flgcontext_posit      CONSTANT sys_list_group_rel.flg_context%TYPE := 'PS'; -- Positionings
    g_flgcontext_physio     CONSTANT sys_list_group_rel.flg_context%TYPE := 'PH'; -- Physiotherapy
    g_flgcontext_diets      CONSTANT sys_list_group_rel.flg_context%TYPE := 'DI'; -- Diets
    g_flgcontext_guidelines CONSTANT sys_list_group_rel.flg_context%TYPE := 'G'; -- Guidelines
    g_flgcontext_protocols  CONSTANT sys_list_group_rel.flg_context%TYPE := 'PR'; -- Protocols
    g_flgcontext_careplans  CONSTANT sys_list_group_rel.flg_context%TYPE := 'CP'; -- Care plans

    -- Global variables
    g_general_exception EXCEPTION;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(4000 CHAR);
    g_package_owner CONSTANT VARCHAR2(0100 CHAR) := 'ALERT';
    g_package_name     VARCHAR2(0100 CHAR) := 'PK_SUSPENDED_TASKS';
    g_function_name    VARCHAR2(0100 CHAR);
    g_line_break       sys_message.desc_message%TYPE;
    g_error_suspension BOOLEAN;

    -- Constants (flg_status for each SUSP_TASK record)
    c_wfstatus_susp  CONSTANT VARCHAR(1) := 'S';
    c_wfstatus_nsusp CONSTANT VARCHAR(2) := 'NS';
    c_wfstatus_reac  CONSTANT VARCHAR(1) := 'R';
    c_wfstatus_nreac CONSTANT VARCHAR(2) := 'NR';

END pk_suspended_tasks;
/
