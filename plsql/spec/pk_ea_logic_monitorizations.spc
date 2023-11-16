/*-- Last Change Revision: $Rev: 2028640 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_monitorizations IS

    -- Author  : Nuno Miguel Ferreira
    -- Created : 30-Sep-2008
    -- Purpose : Easy access for monitorizations

    TYPE t_coll_monitorization_ea IS TABLE OF ts_monitorizations_ea.monitorizations_ea_tc;

    /*
     * This procedure was created to calculate the status of a certain monitorization
     * status. Insted of doing this at SELECT time this function is suppose to
     * be used at INSERT and UPDATE time.
     *
     * @param     i_prof               Professional type
     * @param     i_episode_origin     When the patient has an episode with an exam request with FLG_TIME = 'N', then the patient comes to another appointment and that request is duplicated to this new episode. In this new request, this column is filled with the episode ID of the first request
     * @param     i_flg_time           Execution type: in the (E)pisode, (B)etween episodes, (N)ext episode
     * @param     i_dt_begin_req       Request's begin date
     * @param     i_flg_status_det     Request's detail status
     * @param     i_dt_plan            Next execution's date
     * @param     i_flg_status_plan    Request's status
     * @param     o_status_str         Request's status (in specific format)
     * @param     o_status_msg         Request's status message code
     * @param     o_status_icon        Request's status icon
     * @param     o_status_flg         Request's status flag (to return the icon)
     * 
     * @author Pedro Teixeira
     * @since  2008-Oct-13
    */
    PROCEDURE get_monitorizations_status
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE,
        o_status_str      OUT monitorizations_ea.status_str%TYPE,
        o_status_msg      OUT monitorizations_ea.status_msg%TYPE,
        o_status_icon     OUT monitorizations_ea.status_icon%TYPE,
        o_status_flg      OUT monitorizations_ea.status_flg%TYPE
    );

    FUNCTION get_monitorization_status_str
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_monitorization_status_msg
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_monitorization_status_icon
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_monitorization_status_flg
    (
        i_prof            IN profissional,
        i_episode_origin  IN monitorizations_ea.id_episode_origin%TYPE,
        i_flg_time        IN monitorizations_ea.flg_time%TYPE,
        i_dt_begin        IN monitorizations_ea.dt_begin%TYPE,
        i_flg_status_det  IN monitorizations_ea.flg_status_det%TYPE,
        i_flg_status_plan IN monitorizations_ea.flg_status_plan%TYPE,
        i_dt_plan         IN monitorizations_ea.dt_plan%TYPE
    ) RETURN VARCHAR2;

    /**
    * Updates the Easy Access table for monitorizations
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Nuno Miguel Ferreira
    * @version 2.4.3-Denormalized
    * @since 30-Sep-2008
    */
    PROCEDURE set_monitorization
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE set_grid_task_monitorizations
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*******************************************************************************************************************************************
    * Name:                           SET_TASK_TIMELINE_MONIT
    * Description:                    Function that updates monitorizations information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param I_EVENT_TYPE             Type of event (UPDATE, INSERT, etc)
    * @param I_ROWIDS                 List of ROWIDs belonging to the changed records.
    * @param I_LIST_COLUMNS           List of columns that were changed
    * @param I_SOURCE_TABLE_NAME      Name of the table that was changed.
    * @param I_DG_TABLE_NAME          Name of the Data Governance table.
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_EVENT_TYPE             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/21
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_monit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );
    PROCEDURE ins_grid_task_monitorizations
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    );
    PROCEDURE ins_grid_task_monit_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN grid_task.id_episode%TYPE
    );
    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_ea_logic_monitorizations;
/
