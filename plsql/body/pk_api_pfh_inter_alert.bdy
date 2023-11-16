/*-- Last Change Revision: $Rev: 2026713 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:40 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY PK_API_PFH_INTER_ALERT IS
    -- Private type declarations
    -- Private constant declarations
    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /*******************************************************************************************************************************************
    * Name:                           GET_CONSULT_REQ_STATUS
    * Description:                    In a AUTONOMOUS_TRANSACTION give the status for a id_consult_req
    *
    *
    * @author                         Mário Mineiro
    * @version                        2.6.3.8.4
    * @since                          2013/11/06
    *******************************************************************************************************************************************/
    FUNCTION get_consult_req_status(i_id_consult_req IN consult_req.id_consult_req%TYPE) RETURN VARCHAR2 IS
    
        PRAGMA AUTONOMOUS_TRANSACTION;
        l_flg_status consult_req.flg_status%TYPE;
    BEGIN
    
        BEGIN
            SELECT cr.flg_status
              INTO l_flg_status
              FROM consult_req cr
             WHERE cr.id_consult_req = i_id_consult_req;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_flg_status := 'ERROR';
        END;
    
        RETURN l_flg_status;
    END get_consult_req_status;

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
    ) IS
        l_error_out  t_error_out;
        l_flg_status consult_req.flg_status%TYPE;
    
    BEGIN
        ------------------------------------------------------------------------------------------------------------------------            
        -- BEGIN CONSULT REQUEST
        ------------------------------------------------------------------------------------------------------------------------        
        IF i_dg_table_name = 'CONSULT_REQ'
        THEN
            -- Validate arguments
            g_error := 'VALIDATE ARGUMENTS';
            IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                     i_source_table_name      => i_source_table_name,
                                                     i_dg_table_name          => i_dg_table_name,
                                                     i_expected_table_name    => 'CONSULT_REQ',
                                                     i_expected_dg_table_name => 'CONSULT_REQ',
                                                     i_list_columns           => i_list_columns,
                                                     i_expected_columns       => NULL)
            THEN
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        
            IF ((i_rowids IS NOT NULL) AND (i_rowids.count > 0))
            THEN
            
                -- Insert i_rowids into table tbl_temp to increase performance
                DELETE FROM tbl_temp;
                insert_tbl_temp(i_vc_1 => i_rowids);
            
                FOR r_cur IN (SELECT cr.id_consult_req, cr.id_instit_requests, cr.flg_status
                                FROM consult_req cr
                               WHERE cr.rowid IN (SELECT vc_1
                                                    FROM tbl_temp))
                
                LOOP
                    -- just in case clear the flg status
                    l_flg_status := NULL;
                    -- all states: Estado: R - requisitado, F - pedido lido, P - respondido, A - resposta lida, C - cancelado, T - autorizado, V - aprovado, S - processado                
                    --  Inserts the event CONSULT_REQUEST_NEW         
                    IF i_event_type = t_data_gov_mnt.g_event_insert
                    THEN
                    
                        alert_inter.pk_ia_event_schedule.consult_request_new(i_id_institution => r_cur.id_instit_requests,
                                                                             i_id_consult_req => r_cur.id_consult_req);
                    
                    END IF;
                    -- Inserts the event CONSULT_REQUEST_UPDATE 
                    IF i_event_type = t_data_gov_mnt.g_event_update
                    THEN
                        -- just in case clear the flg status
                        l_flg_status := get_consult_req_status(r_cur.id_consult_req);
                        IF r_cur.flg_status = 'C'
                        THEN
                            alert_inter.pk_ia_event_schedule.consult_request_cancel(i_id_institution => r_cur.id_instit_requests,
                                                                                    i_id_consult_req => r_cur.id_consult_req,
                                                                                    i_flg_old_status => l_flg_status);
                        ELSE
                            alert_inter.pk_ia_event_schedule.consult_request_update(i_id_institution => r_cur.id_instit_requests,
                                                                                    i_id_consult_req => r_cur.id_consult_req,
                                                                                    i_flg_old_status => l_flg_status);
                        END IF;
                    
                    END IF;
                
                END LOOP;
            
            END IF;
        
        END IF;
        ------------------------------------------------------------------------------------------------------------------------            
        -- END CONSULT REQUEST
        ------------------------------------------------------------------------------------------------------------------------    
        -- U may add here or case!
    
    EXCEPTION
        WHEN t_data_gov_mnt.g_excp_invalid_arguments THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_ARGUMENTS');
        WHEN g_excp_invalid_event_type THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INVALID_EVENT_TYPE');
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SEND_TO_INTER_ALERT',
                                              l_error_out);
        
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END send_to_inter_alert;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);

END PK_API_PFH_INTER_ALERT;
/