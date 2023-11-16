/*-- Last Change Revision: $Rev: 1839948 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2018-05-09 09:17:31 +0100 (qua, 09 mai 2018) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_exams IS

    -- Author  : Ana Matos
    -- Created : 01/10/2008 12:00:00 AM
    -- Purpose : Easy access for exams

    -- Public type declarations
    TYPE t_coll_exams_ea IS TABLE OF ts_exams_ea.exams_ea_tc;

    /**
     * This procedure was created to calculate the status of a certain exam_req_det
     * status. Instead of doing this at SELECT time this function is suppose to
     * be used at INSERT and UPDATE time.
     *
     * @param     i_prof               Professional type
     * @param     i_exam_req_det       ID of the exam_req_det
     * @param     i_episode            Episode id
     * @param     i_flg_time           Execution type: in the (E)pisode, (B)etween episodes, (N)ext episode
     * @param     i_flg_status_det     Request's detail satus
     * @param     i_flg_referral       Indication of wether the request was added to a referral: (A)vailable, (R)eserved, (S)ent
     * @param     i_dt_req_tstz        Request's registry date
     * @param     i_dt_begin_tstz      Begin date
     * @param     i_dt_pend_req_tstz   Change from pending to requested status date
     * @param     o_status_str         Request's status (in specific format)
     * @param     o_status_msg         Request's status message code
     * @param     o_status_icon        Request's status icon
     * @param     o_status_flg         Request's status flag (to return the icon)
     * 
     * @author Thiago Brito
     * @since  2008-Oct-08
    */

    PROCEDURE get_exam_status_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE,
        o_status_str        OUT exams_ea.status_str%TYPE,
        o_status_msg        OUT exams_ea.status_msg%TYPE,
        o_status_icon       OUT exams_ea.status_icon%TYPE,
        o_status_flg        OUT exams_ea.status_flg%TYPE
    );

    FUNCTION get_exam_status_str_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exam_status_msg_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exam_status_icon_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exam_status_flg_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN exam_req.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    /**
    * This procedure was created to calculate the status of a certain exam_req
    * status. Instead of doing this at SELECT time this function is suppose to
    * be used at INSERT and UPDATE time.
    *
    * @param     i_prof             Professional type
    * @param     i_episode          Episode id
    * @param     i_dt_req           Request's registry date
    * @param     i_dt_begin         Begin date
    * @param     i_flg_status_req   Request's detail satus
    * @param     i_flg_time         Execution type: in the (E)pisode, (B)etween episodes, (N)ext episode
    * @param     o_status_str       Request's status (in specific format)
    * @param     o_status_msg       Request's status message code
    * @param     o_status_icon      Request's status icon
    * @param     o_status_flg       Request's status flag (to return the icon)
    * 
    * @author Ana Matos
    * @version 2.5
    * @since  2009/03/27
    */

    PROCEDURE get_exam_status_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE,
        o_status_str     OUT exams_ea.status_str_req%TYPE,
        o_status_msg     OUT exams_ea.status_msg_req%TYPE,
        o_status_icon    OUT exams_ea.status_icon_req%TYPE,
        o_status_flg     OUT exams_ea.status_flg_req%TYPE
    );

    FUNCTION get_exam_status_str_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exam_status_msg_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exam_status_icon_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exam_status_flg_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;
    
    FUNCTION get_exam_status_det_all
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_flg_time          IN exam_req.flg_time%TYPE,
        i_flg_status_det    IN exam_req_det.flg_status%TYPE,
        i_flg_referral      IN exam_req_det.flg_referral%TYPE,
        i_flg_status_result IN VARCHAR2,
        i_dt_req            IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req       IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin          IN exam_req.dt_begin_tstz%TYPE
    ) RETURN table_ea_struct;

    FUNCTION get_exam_status_req_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN exam_req.id_episode%TYPE,
        i_flg_time       IN exam_req.flg_time%TYPE,
        i_flg_status_req IN exam_req.flg_status%TYPE,
        i_dt_req         IN exam_req.dt_req_tstz%TYPE,
        i_dt_begin       IN exam_req.dt_begin_tstz%TYPE
    ) RETURN table_ea_struct;    

    /**
    * Updates the Easy Access table for exams
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
    * @version 2.4.3-Denormalized
    * @since 2008/01/01
    */

    PROCEDURE set_exams
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
    * Updates the grid task for exams columns
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
    * @since 2015/02/010
    */

    PROCEDURE set_grid_task_exams
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
    * Name:                           SET_TASK_TIMELINE_EXAMS
    * Description:                    Function that updates exams information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @since                          2009/04/20
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_exams
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
    * Name:                           SET_TASK_TIMELINE_EXAM_RES
    * Description:                    Function that updates exam results information in the Task Timeline Easy Access table (task_timeline_ea)
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
    * @author                         Sofia Mendes
    * @version                        2.6.2.0.7
    * @since                          08/Feb/2012
    *******************************************************************************************************************************************/
    PROCEDURE set_task_timeline_exam_res
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
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Current timestamp */
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

    g_flg_n VARCHAR2(1) := 'N';
    g_flg_y VARCHAR2(1) := 'Y';

END pk_ea_logic_exams;
/
