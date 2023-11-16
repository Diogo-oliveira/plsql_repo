/*-- Last Change Revision: $Rev: 2028550 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_care_plans_api_db IS

    TYPE t_rec_care_plan IS RECORD(
        name           care_plan.name%TYPE,
        dt_begin       care_plan.dt_begin%TYPE,
        id_prof        care_plan.id_prof%TYPE,
        dt_care_plan   care_plan.dt_care_plan%TYPE,
        id_care_plan   care_plan.id_care_plan%TYPE,
        dt_last_update care_plan.dt_care_plan%TYPE);

    TYPE t_cur_care_plan IS REF CURSOR RETURN t_rec_care_plan;
    TYPE t_tbl_care_plan IS TABLE OF t_rec_care_plan;

    TYPE t_rec_care_plan_tasks IS RECORD(
        name              care_plan.name%TYPE,
        dt_begin          VARCHAR2(50 CHAR),
        goals             care_plan.goals%TYPE,
        id_prof           care_plan.id_prof%TYPE,
        dt_care_plan      care_plan.dt_care_plan%TYPE,
        task_name         pk_translation.t_desc_translation,
        task_instructions VARCHAR2(4000),
        notes             care_plan_task.notes%TYPE);

    TYPE t_cur_care_plan_tasks IS REF CURSOR RETURN t_rec_care_plan_tasks;
    TYPE t_tbl_care_plan_tasks IS TABLE OF t_rec_care_plan_tasks;

    /*
    * Returns the care plan summary details
    *
    * @param     i_lang        Language id
    * @param     i_prof        Professional
    * @param     i_patient     Patient id
    * @param     o_care_plan   Cursor
    * @param     o_error       Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/06/05
    */

    FUNCTION get_care_plan_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN care_plan.id_patient%TYPE,
        o_care_plan OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the care plan for a patient
    *                                                                         
    * @param     i_lang         Language id
    * @param     i_prof         Professional
    * @param     i_id_patient   Patient id
    * @param     i_flg_status   Care plan status
    * @param     o_care_plan    Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *                                                                         
    * @author    Filipe Silva                            
    * @version   2.6.0.5                                 
    * @since     2011/02/14
    */

    FUNCTION get_care_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_status IN guideline_process.flg_status%TYPE,
        o_care_plan  OUT t_cur_care_plan,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the care plan's tasks
    *                                                                         
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_id_patient        Patient id
    * @param     o_care_plan_tasks   Cursor
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *                                                                         
    * @author    Filipe Silva                            
    * @version   2.6.0.5                                 
    * @since     2011/02/14
    */

    FUNCTION get_care_plan_tasks
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_care_plan    IN care_plan.id_care_plan%TYPE,
        o_care_plan_tasks OUT t_cur_care_plan_tasks,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Resets care_plan info by patient and /or episode
    *     
    * @param    i_lang      Language id
    * @param    i_prof      Professional
    * @param    i_patient   Patient id
    * @param    i_episode   Episode id
    * @param    o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Carlos Nogueira
    * @version   2.6.0.5
    * @since     2011/02/18
    */

    FUNCTION reset_care_plans
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN table_number,
        i_episode IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

END pk_care_plans_api_db;
/
