/*-- Last Change Revision: $Rev: 2028654 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_tasktimeline IS

    /*******************************************************************************************************************************************
    * Name:                           REOPEN_EPIS_TL_TASKS
    * Description:                    Function that populate Task Timeline Easy Access table (task_timeline_ea) with all tasks
    *                                 because episode was reopen from administrative discharge
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             ID_EPISODE of taks that should be inserted in Task_Timeline_EA table
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/02
    *******************************************************************************************************************************************/
    FUNCTION reopen_epis_tl_tasks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN task_timeline_ea.id_episode%TYPE DEFAULT NULL,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Name:                           SET_EPISODE
    * Description:                    Upates tables: task_timeline_ea. To be used on match functionality
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EPISODE_TEMP           ID_EPISODE of the temporary episode
    * @param I_EPISODE                ID_EPISODE of the definitive episode
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.7
    * @since                          2009/11/05
    *******************************************************************************************************************************************/
    FUNCTION set_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN task_timeline_ea.id_task_refid%TYPE,
        i_episode      IN task_timeline_ea.id_task_refid%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Name:                           CLEAN_EPIS_TL_TASKS
    * Description:                    Function that clean Task Timeline tasks (task_timeline_ea) that are episodes references
    *                                 (Inpatient and Oris) with begin date bigger than today.
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        2.5.0.7.6
    * @since                          2009/12/23
    *******************************************************************************************************************************************/
    PROCEDURE clean_epis_tl_tasks;

    /********************************************************************************************
    * Dynamic delete records from task_timeline_ea
    *
    * @param i_patient                Patient identifier
    * @param i_episode                Episode identifier
    * @param i_institution            Institution identifier
    * @param i_start_dt               Start date to be consider to the validation/reconstruction of data
    * @param i_end_dt                 End date to be consider to the validation/reconstruction of data
    * @param i_validate_table         Indicates necessary to validate data existent in easy access table
    * @param i_output_invalid_records Show final (resumed) information about updated statistics
    * @param i_recreate_table         Indicates necessary to rebuild data existent in easy access table
    * @param i_commit_step            Number of registries between commit's
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author   Sofia Mendes
    * @version  2.6.3
    * @since    11-Jul-2013
    ********************************************************************************************/
    FUNCTION delete_task_timeline
    (
        i_patient     IN NUMBER := NULL,
        i_episode     IN NUMBER := NULL,
        i_institution IN NUMBER := NULL,
        i_start_dt    IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_end_dt      IN TIMESTAMP WITH LOCAL TIME ZONE := NULL,
        i_id_tl_task  IN table_number
    ) RETURN BOOLEAN;

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    g_flg_not_outdated CONSTANT task_timeline_ea.flg_outdated%TYPE := 0;
    g_flg_outdated     CONSTANT task_timeline_ea.flg_outdated%TYPE := 1;

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

END pk_ea_logic_tasktimeline;
/
