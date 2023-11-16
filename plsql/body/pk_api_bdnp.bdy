/*-- Last Change Revision: $Rev: 1976409 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2021-01-15 12:20:58 +0000 (sex, 15 jan 2021) $*/
CREATE OR REPLACE PACKAGE BODY pk_api_bdnp IS

    -- Private type declarations

    -- Private constant declarations

    -- Function and procedure implementations

    /*********************************************************************************************
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_presc_type             Prescription type               
    * @param i_presc                  Referral Id or Medication Id                        
    * @param i_message_type           Message type 
    * @param i_dt_event               Date of the event that originated the detail
    * @param i_flg_event              Type of event
    * @param o_id_sys_alert_event
    * @param o_error                  Error Type
    * 
    * @value i_presc_type             {*} 'M' Medication {*} 'R' Referral
    * @value i_message_type           {*} 'S' Success {*} 'E' Error {*} 'W' Warnig
    * @value i_flg_event              {*} 'I' Insert request {*} 'C' Cancel_request {*} 'RI' Resent insert {*} 'RC' Resent cancel
    *
    * @return                         true or false on success or error
    *
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2011/11/16    
    **********************************************************************************************/

    FUNCTION set_bdnp_events
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_presc_type                IN VARCHAR2,
        i_presc                     IN NUMBER,
        i_message_type              IN bdnp_message.flg_type%TYPE,
        i_id_message                IN bdnp_message.id_bdnp_message%TYPE,
        i_intef_message             IN VARCHAR2,
        i_dt_event                  IN VARCHAR2,
        i_flg_event                 IN bdnp_presc_tracking.flg_event_type%TYPE,
        o_id_sys_alert_event        OUT sys_alert_event.id_sys_alert_event%TYPE,
        o_id_sys_alert_event_detail OUT sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sys_alert_event   sys_alert_event%ROWTYPE;
        l_desc_detail       sys_alert_event_detail.desc_detail%TYPE;
        l_id_detail_group   sys_alert_event_detail.id_detail_group%TYPE;
        l_desc_detail_group sys_alert_event_detail.desc_detail_group%TYPE;
        l_message           VARCHAR2(4000);
        l_num_req           p1_external_request.num_req%TYPE;
        l_drug_name         VARCHAR2(200 CHAR);
        l_id_episode        episode.id_episode%TYPE;
        l_id_patient        episode.id_patient%TYPE;
    
        CURSOR c_ref_info(x_presc p1_external_request.id_external_request%TYPE) IS
            SELECT epis.id_episode, epis.id_visit, epis.id_patient, per.num_req
              FROM p1_external_request per
              JOIN episode epis
                ON (per.id_episode = epis.id_episode AND per.id_patient = epis.id_patient)
             WHERE per.id_external_request = x_presc;
    
    BEGIN
        g_error                          := 'Init set_bdnp_events';
        l_sys_alert_event.id_software    := i_prof.software;
        l_sys_alert_event.id_institution := i_prof.institution;
        l_sys_alert_event.id_record      := i_presc;
        l_sys_alert_event.dt_record      := nvl(i_dt_event, current_timestamp);
        l_sys_alert_event.flg_visible    := pk_alert_constant.g_yes;
    
        IF i_presc_type = g_referral_type
        THEN
            l_sys_alert_event.id_sys_alert := 202;
            l_sys_alert_event.id_intf_type := 5;
            l_message                      := pk_message.get_message(i_lang, 'BDNP_ALERT_M001');
            l_id_detail_group              := 1;
        
            OPEN c_ref_info(i_presc);
            FETCH c_ref_info
                INTO l_sys_alert_event.id_episode, l_sys_alert_event.id_visit, l_sys_alert_event.id_patient, l_num_req;
            CLOSE c_ref_info;
        
            g_error  := 'Call: pk_api_referral.set_referral_flg_migrated';
            g_retval := pk_ref_api.set_referral_flg_migrated(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_external_request => i_presc,
                                                             i_flg_migrated        => i_message_type,
                                                             o_error               => o_error);
            IF NOT g_retval
            THEN
                pk_alertlog.log_error('Error: ' || g_error);
                RETURN FALSE;
            END IF;
        END IF;
    
        IF i_intef_message IS NOT NULL
           OR i_id_message IS NOT NULL
        THEN
        
            IF i_presc_type = g_referral_type
            THEN
                IF i_message_type = 'E'
                THEN
                    l_desc_detail_group := REPLACE(pk_message.get_message(i_lang, 'V_ALERT_M0103'), '@', l_message);
                    l_desc_detail       := pk_message.get_message(i_lang, 'V_ALERT_M0108') || chr(10) ||
                                           i_intef_message || chr(10) ||
                                           pk_message.get_message(i_lang, 'BDNP_ALERT_M003') || l_num_req || chr(10) ||
                                           pk_message.get_message(i_lang, 'BDNP_ALERT_E_M001');
                
                ELSIF i_message_type = 'W'
                THEN
                    l_desc_detail_group := REPLACE(pk_message.get_message(i_lang, 'V_ALERT_M0104'), '@', l_message);
                    l_desc_detail       := pk_message.get_message(i_lang, 'V_ALERT_M0107') || chr(10) ||
                                           i_intef_message || chr(10) ||
                                           pk_message.get_message(i_lang, 'BDNP_ALERT_M003') || l_num_req || chr(10) ||
                                           pk_message.get_message(i_lang, 'BDNP_ALERT_W_M001');
                
                ELSIF i_message_type = 'S'
                THEN
                    l_desc_detail_group := REPLACE(pk_message.get_message(i_lang, 'V_ALERT_M0105'), '@', l_message);
                    l_desc_detail       := pk_message.get_message(i_lang, 'V_ALERT_M0106') || chr(10) ||
                                           i_intef_message || chr(10) ||
                                           pk_message.get_message(i_lang, 'BDNP_ALERT_M003') || l_num_req;
                END IF;
            END IF;
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RETURN FALSE;
            END IF;
            g_error  := 'Call: pk_api_alerts.intf_ins_sys_alert_detail';
            g_retval := pk_api_alerts.intf_ins_sys_alert_detail(i_lang                      => i_lang,
                                                                i_prof                      => i_prof,
                                                                i_sys_alert_event           => l_sys_alert_event,
                                                                i_flg_type_dest             => NULL,
                                                                i_dt_event                  => i_dt_event,
                                                                i_desc_detail               => l_desc_detail,
                                                                i_id_detail_group           => l_id_detail_group,
                                                                i_desc_detail_group         => l_desc_detail_group,
                                                                o_id_sys_alert_event        => o_id_sys_alert_event,
                                                                o_id_sys_alert_event_detail => o_id_sys_alert_event_detail,
                                                                o_error                     => o_error);
            IF NOT g_retval
            THEN
                pk_alertlog.log_error('Error: ' || g_error);
                RETURN FALSE;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => 'ALERT',
                                                     i_package  => 'PK_API_BDNP',
                                                     i_function => 'SET_BDNP_EVENTS',
                                                     o_error    => o_error);
        
    END set_bdnp_events;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_api_bdnp;
/
