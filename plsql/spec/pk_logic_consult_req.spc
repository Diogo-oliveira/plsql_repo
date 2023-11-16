/*-- Last Change Revision: $Rev: 2028779 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_logic_consult_req IS

    -- Author  : THIAGO.BRITO
    -- Created : 13-10-2008 14:25:16
    PROCEDURE get_consult_req_status
    (
        i_prof                IN profissional,
        i_flg_status          IN consult_req.flg_status%TYPE,
        i_dt_consult_req_tstz IN consult_req.dt_consult_req_tstz%TYPE,
        o_status_str          OUT exams_ea.status_str%TYPE,
        o_status_msg          OUT exams_ea.status_msg%TYPE,
        o_status_icon         OUT exams_ea.status_icon%TYPE,
        o_status_flg          OUT exams_ea.status_flg%TYPE
    );

    /**
    * This function uses the status flags returned by the get_consult_req_status, and creates the string that is to be read by FLASH in order to create an icon.
    *
    * @param i_lang                 Language.
    * @param i_prof                 Logged professional.
    * @param i_flg_status           The current value of flag_status    
    * @param i_dt_consult_req_tstz  The timestamp of the last requisition
    *
    * @author Ricardo Nuno Almeida
    * @version 2.4.3.d
    * @since 2008-Oct-17
    */
    FUNCTION get_consult_req_status_string
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status          IN consult_req.flg_status%TYPE,
        i_dt_consult_req_tstz IN consult_req.dt_consult_req_tstz%TYPE
    ) RETURN VARCHAR2;

    /**
    * Consult Req Logic entry funtion
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author Pedro Teixeira
    * @version 2.4.3.d
    * @since 2008-Oct-14
    */
    PROCEDURE set_consult_req
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /* Error tracking */
    g_error         VARCHAR2(4000);
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

END pk_logic_consult_req;
/
