/*-- Last Change Revision: $Rev: 2028782 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_logic_movements IS

    -- Author  : LUIS.MAIA
    -- Created : 22-04-2009 11:33:35
    -- Purpose : Package that contains all the LOGIC associated to insert's, update's and delete's in transports functionality tables

    /********************************************************************************************
    * Calculate the status of an analysis request detail (movement)
    *
    * @param    I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param    I_FLG_REFERRAL         Referral flag
    * @param    I_DT_REQ               Analysis request date
    * @param    I_DT_PEND_REQ          Pending request date
    * @param    I_DT_TARGET            Target date
    * @param    I_FLG_STATUS_DET       Detail status flag
    * @param    I_FLG_STATUS_HARVEST   Harvest status flag
    * @param    I_FLG_TIME_HARVEST     Execution type flag
    * @param    O_STATUS_STR           Status string
    * @param    O_STATUS_MSG           Status message
    * @param    O_STATUS_ICON          Status icon
    * @param    O_STATUS_FLG           Status flag
    *
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author   Luís Maia
    * @version  2.5.0.2
    * @since    2009/04/23
    ********************************************************************************************/
    PROCEDURE get_movement_status
    (
        i_prof        IN profissional,
        i_dt_req      IN movement.dt_req_tstz%TYPE,
        i_dt_begin    IN movement.dt_begin_tstz%TYPE,
        i_dt_end      IN movement.dt_end_tstz%TYPE,
        i_flg_status  IN movement.flg_status%TYPE,
        o_status_str  OUT VARCHAR2,
        o_status_msg  OUT VARCHAR2,
        o_status_icon OUT VARCHAR2,
        o_status_flg  OUT VARCHAR2
    );

    /*******************************************************************************************************************************************
    * Name:                           SET_TASK_TIMELINE_TRANSP
    * Description:                    Function that updates movements information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @since                          2009/04/22
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_transp
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
    * Name:                           GET_MOVEMENT_STATUS_STR
    * Description:                    Function that calculates the status string for movements
    * 
    * @param I_LANG                   Language ID
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * 
    * @return                         String with the status string
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2015/05/27
    *******************************************************************************************************************************************/

    FUNCTION get_movement_status_str
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Name:                           SET_GRID_TASK_MOVEMENT
    * Description:                    Function that updates movements information in the grid_task table 
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
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2015/05/27
    *******************************************************************************************************************************************/

    PROCEDURE set_grid_task_movement
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );
    ---
    PROCEDURE ins_grid_task_movements
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    );
    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Package name */
    -- JC 09/03/2009 ALERT-17261 
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_logic_movements;
/
