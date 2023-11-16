/*-- Last Change Revision: $Rev: 2028628 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_analysis IS

    /**
    * Calculate the status of an analysis request detail (analysis_req_det)
    *
    * @param    i_lang                 Language id
    * @param    i_prof                 Professional
    * @param    i_episode              Episode id
    * @param    i_dt_req               Analysis request date
    * @param    i_dt_pend_req          Pending request date
    * @param    i_dt_target            Target date
    * @param    i_flg_status_det       Detail status flag
    * @param    i_flg_status_harvest   Harvest status flag
    * @param    i_flg_time_harvest     Execution type flag
    * @param    i_flg_referral         Referral flag
    * @param    o_status_str           Status string
    * @param    o_status_msg           Status message
    * @param    o_status_icon          Status icon
    * @param    o_status_flg           Status flag
    *
    * @author   Tiago Silva
    * @version  2.4.3-Denormalized
    * @since    2008/10/07
    */

    PROCEDURE get_analysis_status_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE,
        o_status_str         OUT VARCHAR2,
        o_status_msg         OUT VARCHAR2,
        o_status_icon        OUT VARCHAR2,
        o_status_flg         OUT VARCHAR2
    );

    FUNCTION get_analysis_status_str_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_analysis_status_msg_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_analysis_status_icon_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_analysis_status_flg_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE get_analysis_status_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE,
        o_status_str     OUT VARCHAR2,
        o_status_msg     OUT VARCHAR2,
        o_status_icon    OUT VARCHAR2,
        o_status_flg     OUT VARCHAR2
    );

    FUNCTION get_analysis_status_str_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_analysis_status_msg_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_analysis_status_icon_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_analysis_status_flg_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE get_harvest_status
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2,
        o_status_str       OUT VARCHAR2,
        o_status_msg       OUT VARCHAR2,
        o_status_icon      OUT VARCHAR2,
        o_status_flg       OUT VARCHAR2
    );

    FUNCTION get_harvest_status_str
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_harvest_status_msg
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_harvest_status_icon
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_harvest_status_flg
    (
        i_prof             IN profissional,
        i_flg_time_harvest IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status       IN harvest.flg_status%TYPE,
        i_dt_req           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req      IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_target        IN analysis_req_det.dt_target_tstz%TYPE,
        i_flg_type         IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_analysis_status_req_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_time       IN analysis_req.flg_time%TYPE,
        i_flg_status_req IN analysis_req.flg_status%TYPE,
        i_dt_req         IN analysis_req.dt_req_tstz%TYPE,
        i_dt_begin       IN analysis_req.dt_begin_tstz%TYPE
    ) RETURN table_ea_struct;

    FUNCTION get_analysis_status_det_all
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_time           IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_det     IN analysis_req_det.flg_status%TYPE,
        i_flg_referral       IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_harvest IN harvest.flg_status%TYPE,
        i_flg_status_result  IN VARCHAR2,
        i_result             IN VARCHAR2,
        i_dt_req             IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req        IN analysis_req_det.dt_pend_req_tstz%TYPE,
        i_dt_begin           IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN table_ea_struct;    

    /**
    * Updates the Easy Access table for ANALYSIS
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Luís Maia
    * @version 2.4.3-Denormalized
    * @since 2008/10/18
    */
    PROCEDURE set_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Updates the grid task for lab_tests columns
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Ana Matos
    * @version 2.6.4.3
    * @since 2015/03/13
    */

    PROCEDURE set_grid_task_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE set_grid_task_harvest
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Name:                           SET_TASK_TIMELINE_ANALYSIS
    * Description:                    Function that updates analysis information in the Task Timeline Easy Access table (task_timeline_ea)
    * 
    * @param i_lang                   Language
    * @param i_prof                   Professional
    * @param i_event_type             Type of event (UPDATE, INSERT, etc)
    * @param i_rowids                 List of ROWIDs belonging to the changed records.
    * @param i_list_columns           List of columns that were changed
    * @param i_source_table_name      Name of the table that was changed.
    * @param i_dg_table_name          Name of the Data Governance table.
    * 
    * @value i_lang                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value i_event_type             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/04/17
    */

    PROCEDURE set_task_timeline_analysis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Function that updates analysis results information in the Task Timeline Easy Access table (task_timeline_ea table)
    * 
    * @param i_lang                   Language
    * @param i_prof                   Professional
    * @param i_event_type             Type of event (UPDATE, INSERT, etc)
    * @param i_rowids                 List of ROWIDs belonging to the changed records.
    * @param i_list_columns           List of columns that were changed
    * @param i_source_table_name      Name of the table that was changed.
    * @param i_dg_table_name          Name of the Data Governance table.
    * 
    * @value i_lang                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value i_event_type             {*} t_data_gov_mnt.g_event_insert {*} t_data_gov_mnt.g_event_update {*} t_data_gov_mnt.g_event_delete
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         António Neto
    * @version                        2.6.2
    * @since                          20-Jan-2012
    */
    PROCEDURE set_task_timeline_analysis_res
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
    -- JC 09/03/2009 ALERT-17261 
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_ea_logic_analysis;
/
