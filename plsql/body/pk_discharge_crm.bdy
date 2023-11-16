/*-- Last Change Revision: $Rev: 1877368 $*/
/*-- Last Change by: $Author: adriano.ferreira $*/
/*-- Date of last change: $Date: 2018-11-12 15:39:19 +0000 (seg, 12 nov 2018) $*/
CREATE OR REPLACE PACKAGE BODY pk_discharge_crm IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_retval BOOLEAN;
    g_exception_np EXCEPTION;
    g_exception EXCEPTION;

    FUNCTION get_ws_body
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_ws_int_name   IN VARCHAR2,
        i_discharge_msg IN pk_edis_types.rec_disch_message,
        o_ws_body       OUT pk_webservices.table_ws_attr,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT pk_rcm_constant.t_low_char := 'GET_WS_BODY';
        l_string VARCHAR2(1000 CHAR);
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_ws_int_name=' || i_ws_int_name;
    
        -- builds data to be sent to the crm services
        -- RemoteServiceContext 
        l_string := 'executionRequestSetObject.context';
        o_ws_body(l_string || '.institution') := anydata.convertnumber(i_prof.institution);
        o_ws_body(l_string || '.language') := anydata.convertnumber(i_lang);
        o_ws_body(l_string || '.professional') := anydata.convertnumber(i_prof.id);
        o_ws_body(l_string || '.software') := anydata.convertnumber(i_prof.software);
        o_ws_body(l_string || '.instalationId') := anydata.convertnumber(0);
    
        --     RequestContentAttribute
        -- email messafe
        l_string := 'executionRequestSetObject.requestContents[1].requestContent.requestContentAttributeList[1].requestContentAttribute';
        --gp_NAME
        o_ws_body(l_string || '[1].description') := anydata.convertvarchar2(g_gp_name);
        o_ws_body(l_string || '[1].id') := anydata.convertvarchar2(g_gp_name);
        o_ws_body(l_string || '[1].value') := anydata.convertvarchar2(nvl(i_discharge_msg.gp_name,' '));
    
        --EPISODE DATE
        o_ws_body(l_string || '[2].description') := anydata.convertvarchar2(g_episode_date);
        o_ws_body(l_string || '[2].id') := anydata.convertvarchar2(g_episode_date);
        o_ws_body(l_string || '[2].value') := anydata.convertvarchar2(i_discharge_msg.episode_date);
    
        --EPISODE time
        o_ws_body(l_string || '[3].description') := anydata.convertvarchar2(g_episode_time);
        o_ws_body(l_string || '[3].id') := anydata.convertvarchar2(g_episode_time);
        o_ws_body(l_string || '[3].value') := anydata.convertvarchar2(i_discharge_msg.episode_time);
    
        --EPISODE FINAL DIAGMOSIES
        o_ws_body(l_string || '[4].description') := anydata.convertvarchar2(g_episode_prof_name);
        o_ws_body(l_string || '[4].id') := anydata.convertvarchar2(g_episode_prof_name);
        o_ws_body(l_string || '[4].value') := anydata.convertvarchar2(nvl(i_discharge_msg.episode_prof_name, ' ' ));
    
        --EPISODE professional name
        o_ws_body(l_string || '[5].description') := anydata.convertvarchar2(g_episode_finaldiagnoses);
        o_ws_body(l_string || '[5].id') := anydata.convertvarchar2(g_episode_finaldiagnoses);
        o_ws_body(l_string || '[5].value') := anydata.convertvarchar2(nvl(i_discharge_msg.episode_final_diagnoses, ' '));
    
        --patient name
        o_ws_body(l_string || '[6].description') := anydata.convertvarchar2(g_patient_name);
        o_ws_body(l_string || '[6].id') := anydata.convertvarchar2(g_patient_name);
        o_ws_body(l_string || '[6].value') := anydata.convertvarchar2(i_discharge_msg.patient_name);
    
        --patient nhs
        o_ws_body(l_string || '[7].description') := anydata.convertvarchar2(g_patient_nhs);
        o_ws_body(l_string || '[7].id') := anydata.convertvarchar2(g_patient_nhs);
        o_ws_body(l_string || '[7].value') := anydata.convertvarchar2(nvl(i_discharge_msg.patient_nhs, ' '));
    
        --address_1
        o_ws_body(l_string || '[8].description') := anydata.convertvarchar2(g_address_1);
        o_ws_body(l_string || '[8].id') := anydata.convertvarchar2(g_address_1);
        o_ws_body(l_string || '[8].value') := anydata.convertvarchar2(nvl(i_discharge_msg.address_1,' ' ));
    
        --address_2
        o_ws_body(l_string || '[9].description') := anydata.convertvarchar2(g_address_2);
        o_ws_body(l_string || '[9].id') := anydata.convertvarchar2(g_address_2);
        o_ws_body(l_string || '[9].value') := anydata.convertvarchar2(nvl(i_discharge_msg.address_2,' '));
    
        --address_3
        o_ws_body(l_string || '[10].description') := anydata.convertvarchar2(g_address_3);
        o_ws_body(l_string || '[10].id') := anydata.convertvarchar2(g_address_3);
        o_ws_body(l_string || '[10].value') := anydata.convertvarchar2(nvl(i_discharge_msg.address_3,' ' ));
    
        --address_4
        o_ws_body(l_string || '[11].description') := anydata.convertvarchar2(g_address_4);
        o_ws_body(l_string || '[11].id') := anydata.convertvarchar2(g_address_4);
        o_ws_body(l_string || '[11].value') := anydata.convertvarchar2(nvl(i_discharge_msg.address_4,' '));
    
        --address_5
        o_ws_body(l_string || '[12].description') := anydata.convertvarchar2(g_address_5);
        o_ws_body(l_string || '[12].id') := anydata.convertvarchar2(g_address_5);
        o_ws_body(l_string || '[12].value') := anydata.convertvarchar2(nvl(i_discharge_msg.address_5,' '));
    
        -- RequestContent - 1 position filled 
        --     RequestRecipient
        l_string := 'executionRequestSetObject.requestContents[1].requestContent.requestRecipient';
        o_ws_body(l_string || '.code') := anydata.convertvarchar2(i_discharge_msg.gp_id); -- id
        o_ws_body(l_string || '.value') := anydata.convertvarchar2(i_discharge_msg.gp_email); --go_email
        o_ws_body(l_string || '.description') := anydata.convertvarchar2(i_discharge_msg.gp_name); -- gp name
    
        l_string := 'executionRequestSetObject.requestContents[1].requestContent.from';
        o_ws_body(l_string) := anydata.convertvarchar2(i_discharge_msg.professional_email); -- from email
    
        -- RequestDetails
        l_string := 'executionRequestSetObject.requestDetails';
        o_ws_body(l_string || '.executionType') := anydata.convertvarchar2('AUTO'); -- send from template
        o_ws_body(l_string || '.messageDefinition') := anydata.convertvarchar2(g_discharge_message);
    
        -- file attacha
        l_string := 'executionRequestSetObject.fileAttachments[1].fileAttachment';
        o_ws_body(l_string || '.fileName') := anydata.convertvarchar2(i_discharge_msg.attach_name); -- send from template
        o_ws_body(l_string || '.fileExtension') := anydata.convertvarchar2('PDF');
        o_ws_body(l_string || '.fileObject') := anydata.convertblob(i_discharge_msg.attachfile);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_ws_body;

    /**********************************************************************************************
    * Send Message to CRM 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_ws_name               Web service name
    * @param i_id_diet               ID Diet to be resumed
    * @param i_notes                 Resume Notes 
    * @param i_dt_initial            Initial date for resume
    * @param i_dt_end                End date for resume
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.3
    * @since                         2013/09/18
    **********************************************************************************************/
    FUNCTION send_message_to_crm
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_ws_name       IN VARCHAR2,
        i_discharge_msg IN pk_edis_types.rec_disch_message,
        o_ws_response   OUT CLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'SEND_MESSAGE_TO_CRM';
        l_ws_body pk_webservices.table_ws_attr;
        l_key     VARCHAR2(32767);
    BEGIN
        g_error := 'Init ' || l_func_name || ' / i_ws_name=' || i_ws_name;
    
        -- builds webservice data
        g_retval := get_ws_body(i_lang          => i_lang,
                                i_prof          => i_prof,
                                i_ws_int_name   => i_ws_name,
                                i_discharge_msg => i_discharge_msg,
                                o_ws_body       => l_ws_body,
                                o_error         => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        /*        --iterate all keys and add member to JSON object
        dbms_output.put_line('iterator');
        l_key := l_ws_body.first;
        LOOP
            EXIT WHEN l_key IS NULL;
            dbms_output.put_line(anydata.accessvarchar2(l_ws_body(l_key)));
            --1  pk_alertlog.log_debug(l_key || ': ' || json_ext.get_string(l_json, l_key));
            l_key := l_ws_body.next(l_key);
        END LOOP;*/
    
        --      dbms_output.put_line(pk_webservices.to_json(l_ws_body));
    
        -- call CRM web service
        g_error       := l_func_name || ': Call pk_webservices.call_ws / i_ws_int_name=' || i_ws_name;
        o_ws_response := pk_webservices.call_ws(i_ws_int_name => i_ws_name, i_table_table_ws => l_ws_body);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END send_message_to_crm;

    /**************************************************************************
    * Set a discharge_report configuration.                                   *
    *                                                                         *
    * @param i_id_report                Report to be generated                *
    * @param i_flg_send                 Send report on discharge?             *
    *                                        Y - yes; N - otherwise           *
    * @param i_flg_send_by_crm          Send report to crm?                   *
    *                                        Y - yes; N - otherwise           *
    * @param i_generation_rank          Rank for report sending               *
    *                                                                         *
    * @author   Nuno Alves                                                    *
    * @version  2.6.3.8.2                                                     *
    * @since    14-05-2015                                                    *
    **************************************************************************/
    PROCEDURE set_discharge_rep_cfg
    (
        i_software        IN software.id_software%TYPE,
        i_market          IN market.id_market%TYPE DEFAULT 0,
        i_institution     IN institution.id_institution%TYPE DEFAULT 0,
        i_id_report       IN reports.id_reports%TYPE, -- id_record
        i_flg_send        IN VARCHAR2, -- FIELD_01
        i_flg_send_to_crm IN VARCHAR2, -- FIELD_02
        i_generation_rank IN VARCHAR2, -- FIELD_03
        i_id_inst_owner   IN NUMBER DEFAULT 0,
        i_flg_add_remove  IN VARCHAR2 DEFAULT 'A'
    ) IS
        l_proc_name VARCHAR2(30 CHAR) := 'SET_DISCHARGE_REP_CFG';
        l_id_config NUMBER;
    BEGIN
        g_error := 'VALIDATE CONFIGURATION DATA';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        IF i_flg_send IS NOT NULL
           AND i_flg_send NOT IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
        THEN
            raise_application_error(-20003,
                                    'I_FLG_SEND POSSIBLE VALUES ARE: "' || pk_alert_constant.g_yes || '", "' ||
                                    pk_alert_constant.g_no || '"');
        END IF;
    
        IF i_flg_send_to_crm IS NOT NULL
           AND i_flg_send_to_crm NOT IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
        THEN
            raise_application_error(-20004,
                                    'I_FLG_SEND_BY_CRM POSSIBLE VALUES ARE: "' || pk_alert_constant.g_yes || '", "' ||
                                    pk_alert_constant.g_no || '"');
        END IF;
    
        g_error := 'CALL pk_core_config.INSERT_INTO_CONFIG';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        l_id_config := pk_core_config.insert_into_config(i_software    => i_software,
                                                         i_market      => i_market,
                                                         i_institution => i_institution);
    
        g_error := 'CALL pk_core_config.INSERT_INTO_CONFIG_TABLE';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        pk_core_config.insert_into_config_table(i_config_table   => g_discharge_reports_ct,
                                                i_id_record      => i_id_report,
                                                i_id_inst_owner  => i_id_inst_owner,
                                                i_id_config      => l_id_config,
                                                i_flg_add_remove => i_flg_add_remove,
                                                i_field_01       => i_flg_send,
                                                i_field_02       => i_flg_send_to_crm,
                                                i_field_03       => i_generation_rank);
    
    END set_discharge_rep_cfg;

    /**************************************************************************
    * return configurations for discharge reports                             *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    *                                                                         *
    * @return                         return list of configs                  *
    *                                                                         *
    * @author                         Nuno Alves                              *
    * @version                        2.6.3.8.2                               *
    * @since                          2015/05/14                              *
    **************************************************************************/
    FUNCTION tf_discharge_report_cfg
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_report IN reports.id_reports%TYPE DEFAULT NULL
    ) RETURN t_table_disch_rep_cfg
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(32) := 'TF_DISCHARGE_REPORT_CFG';
        --
        l_tbl_ret t_table_disch_rep_cfg;
    BEGIN
        g_error := 'CALL pk_core_config.TF_CONFIG';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        SELECT t.id_record AS id_report,
               t.field_01  AS flg_send,
               t.field_02  AS flg_send_to_crm,
               t.field_03  AS generation_rank BULK COLLECT
          INTO l_tbl_ret
          FROM TABLE(pk_core_config.tf_config(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_config_table => g_discharge_reports_ct)) t
         WHERE t.id_record = nvl(i_id_report, t.id_record)
         ORDER BY to_number(generation_rank) ASC;
    
        FOR i IN 1 .. l_tbl_ret.count
        LOOP
            PIPE ROW(l_tbl_ret(i));
        END LOOP;
    
        RETURN;
    END tf_discharge_report_cfg;

    /**************************************************************************
    * Check if report is to be sent to crm                                    *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    * @param i_id_report              Report ID                               *
    *                                                                         *
    * @return                         'Y' or 'N'                              *
    *                                                                         *
    * @author                         Nuno Alves                              *
    * @version                        2.6.3.8.2                               *
    * @since                          2015/05/14                              *
    **************************************************************************/
    FUNCTION check_send_to_crm
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_report IN reports.id_reports%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(32) := 'CHECK_SEND_TO_CRM';
        l_rec_disch_rep_cfg t_rec_disch_rep_cfg;
    BEGIN
        g_error := 'CALL PK_DISCHARGE_CRM.TF_DISCHARGE_REPORT_CFG';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        BEGIN
            SELECT *
              INTO l_rec_disch_rep_cfg
              FROM TABLE(pk_discharge_crm.tf_discharge_report_cfg(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_id_report => i_id_report)) t;
        EXCEPTION
            WHEN no_data_found THEN
                l_rec_disch_rep_cfg.flg_send_to_crm := pk_alert_constant.g_no;
        END;
    
        RETURN l_rec_disch_rep_cfg.flg_send_to_crm;
    END check_send_to_crm;

    /**************************************************************************
    * Get report generation rank                                              *
    *                                                                         *
    * @param i_lang                   The language ID                         *
    * @param i_prof                   Object (professional ID, institution ID,*
    * @param i_id_report              Report ID                               *
    *                                                                         *
    * @return                         Rank                                    *
    *                                                                         *
    * @author                         Nuno Alves                              *
    * @version                        2.6.3.8.2                               *
    * @since                          2015/05/14                              *
    **************************************************************************/
    FUNCTION get_report_rank
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_report IN reports.id_reports%TYPE
    ) RETURN NUMBER IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_REPORT_RANK';
        l_rec_disch_rep_cfg t_rec_disch_rep_cfg;
    BEGIN
        g_error := 'CALL PK_DISCHARGE_CRM.TF_DISCHARGE_REPORT_CFG';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        BEGIN
            SELECT *
              INTO l_rec_disch_rep_cfg
              FROM TABLE(pk_discharge_crm.tf_discharge_report_cfg(i_lang      => i_lang,
                                                                  i_prof      => i_prof,
                                                                  i_id_report => i_id_report)) t;
        EXCEPTION
            WHEN no_data_found THEN
                l_rec_disch_rep_cfg.generation_rank := NULL;
        END;
    
        RETURN l_rec_disch_rep_cfg.generation_rank;
    END get_report_rank;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_discharge_crm;
/
