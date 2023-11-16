/*-- Last Change Revision: $Rev: 1714849 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2015-11-06 14:39:15 +0000 (sex, 06 nov 2015) $*/

CREATE OR REPLACE PACKAGE pk_logic_nurse_tea_req IS

    -- Author  : THIAGO.BRITO
    -- Created : 13-10-2008 14:24:58
    -- Purpose : 

    /*
     * This procedure was created to calculate the status of a certain opinion
     * status. Instead of doing this at SELECT time this function is suppose to
     * be used at INSERT and UPDATE time.
     *
     * @param     i_prof               Professional type
     * @param     i_flg_status         Opinion status
     * @param     i_dt_begin_tstz      Begin date
     * @param     o_status_str         Request's status (in specific format)
     * @param     o_status_msg         Request's status message code
     * @param     o_status_icon        Request's status icon
     * @param     o_status_flg         Request's status flag (to return the icon)
     * 
     * @author Thiago Brito
     * @since  2008-Oct-08
    */

    PROCEDURE get_nurse_tea_req_status
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE,
        o_status_str    OUT nurse_tea_req.status_str%TYPE,
        o_status_msg    OUT nurse_tea_req.status_msg%TYPE,
        o_status_icon   OUT nurse_tea_req.status_icon%TYPE,
        o_status_flg    OUT nurse_tea_req.status_flg%TYPE
    );

    FUNCTION get_nurse_tea_req_status_str
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_nurse_tea_req_status_msg
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_nurse_tea_req_status_icon
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_nurse_tea_req_status_flg
    (
        i_prof          IN profissional,
        i_flg_time      IN nurse_tea_req.flg_time%TYPE,
        i_flg_status    IN nurse_tea_req.flg_status%TYPE,
        i_dt_begin_tstz IN nurse_tea_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    /*
     * This procedure is used to centralize the DML's manipulation
     * over NURSE_TEA_REQ's table
     *
     * @param     i_lang               Language ID
     * @param     i_prof               Professional type
     * @param     i_event_type         Event type
     * @param     i_rowids             Rowids
     * @param     i_source_table_name  Source table name
     * @param     i_list_columns       List of the columns affected by the DML operations
     * @param     i_dg_table_name      Table name
     * 
     * @author Thiago Brito
     * @since  2008-Oct-08
    */

    PROCEDURE set_nurse_tea_req
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*
     * This procedure is used to centralize the DML's manipulation
     * over NURSE_TEA_DET's table
     *
     * @param     i_lang               Language ID
     * @param     i_prof               Professional type
     * @param     i_event_type         Event type
     * @param     i_rowids             Rowids
     * @param     i_source_table_name  Source table name
     * @param     i_list_columns       List of the columns affected by the DML operations
     * @param     i_dg_table_name      Table name
     * 
     * @author Nuno Neves
     * @since  2011-05-30
    */

    PROCEDURE set_nurse_tea_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE set_grid_task_pat_education
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_logic_nurse_tea_req;
/
