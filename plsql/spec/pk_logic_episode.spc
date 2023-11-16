/*-- Last Change Revision: $Rev: 2028781 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_logic_episode IS

    -- Author  : LUIS.MAIA
    -- Created : 22-05-2009 14:41:24
    -- Purpose : Package that has buiseness logic associated with selection of discharge schedule dates

    /********************************************************************************************
    * GET_EPISODE_STATUS               Calculate the status of an episode registry
    *
    * @param    I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param    I_DT_REQ               discharge request date
    * @param    I_DT_BEGIN             Request date for shedule discharge
    * @param    I_FLG_STATUS           Discharge date status flag
    * @param    I_ID_EPIS_TYPE         ID_EPIS_TYPE of current episode
    * @param    O_STATUS_STR           Status string
    * @param    O_STATUS_MSG           Status message
    * @param    O_STATUS_ICON          Status icon
    * @param    O_STATUS_FLG           Status flag
    *
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.3
    * @since                          2009/05/25
    ********************************************************************************************/
    PROCEDURE get_episode_status
    (
        i_prof         IN profissional,
        i_dt_req       IN discharge_schedule.create_time%TYPE,
        i_dt_begin     IN discharge_schedule.dt_discharge_schedule%TYPE,
        i_flg_status   IN episode.flg_status%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        o_status_str   OUT VARCHAR2,
        o_status_msg   OUT VARCHAR2,
        o_status_icon  OUT VARCHAR2,
        o_status_flg   OUT VARCHAR2
    );

    /*******************************************************************************************************************************************
    * Name:                           SET_TASK_TIMELINE_EPISOD
    * Description:                    Function that updates episode information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @version                        2.5.0.3
    * @since                          2009/05/25
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_episod
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
    * Name:                           SET_EPIS_DEP_CLIN_SERV
    * Description:                    Function that updates episode responsable department, dept and clinical service in EPISODE table
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
    * @version                        2.5.0.6
    * @since                          2009/12/17
    *******************************************************************************************************************************************/
    PROCEDURE set_epis_dep_clin_serv
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
    * Name:                           SET_GRID_TASK_EPISOD
    * Description:                    Function that updates ORIS episode information in the grid_task for hemo and material requisitions.
    *                                 When the schedule date's (schedule_sr) changed and exists hemo and/or material requisitions for this episode
    *                                 is necessary update these columns 
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
    * @author                         Filipe Silva
    * @version                        2.5.0.7.7
    * @since                          2010/02/26
    *******************************************************************************************************************************************/
    PROCEDURE set_grid_task_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );
    
    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;
    g_desc_type_s CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_desc_type_l CONSTANT VARCHAR2(1 CHAR) := 'L';
END pk_logic_episode;
/
