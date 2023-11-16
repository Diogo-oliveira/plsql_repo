/*-- Last Change Revision: $Rev: 2028485 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:05 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE PK_API_PFH_INTER_ALERT IS
    /*******************************************************************************************************************************************
    * Name:                           GET_CONSULT_REQ_STATUS
    * Description:                    In a AUTONOMOUS_TRANSACTION give the status for a id_consult_req
    *
    *
    * @author                         Mário Mineiro
    * @version                        2.6.3.8.4
    * @since                          2013/11/06
    *******************************************************************************************************************************************/
    FUNCTION get_consult_req_status(i_id_consult_req IN consult_req.id_consult_req%TYPE) RETURN VARCHAR2;

    /*******************************************************************************************************************************************
    * Name:                           SEND_TO_INTER_ALERT
    * Description:                    Package based on data gov event that sends to inter alert the data requested
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
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Mário Mineiro
    * @version                        2.6.3.8.4
    * @since                          2013/11/06
    *******************************************************************************************************************************************/
    PROCEDURE send_to_inter_alert
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );
    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;
    g_desc_type_s CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_desc_type_l CONSTANT VARCHAR2(1 CHAR) := 'L';

END PK_API_PFH_INTER_ALERT;
/