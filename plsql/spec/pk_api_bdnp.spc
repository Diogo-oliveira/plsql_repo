/*-- Last Change Revision: $Rev: 1976403 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2021-01-15 12:10:51 +0000 (sex, 15 jan 2021) $*/
CREATE OR REPLACE PACKAGE pk_api_bdnp IS

    -- Author  : JOANA.BARROSO
    -- Created : 10-07-2012 16:27:03
    -- Purpose : 

    -- Public type declarations
    -- Public constant declarations
    -- Public variable declarations
    -- Public function and procedure declarations

    g_referral_type   CONSTANT VARCHAR2(1) := 'R';
    g_medication_type CONSTANT VARCHAR2(1) := 'M';

    g_bdnp_event_type_i  CONSTANT bdnp_presc_tracking.flg_event_type%TYPE := 'I'; -- insert request into bdnp
    g_bdnp_event_type_c  CONSTANT bdnp_presc_tracking.flg_event_type%TYPE := 'C'; -- cancel request in bdnp
    g_bdnp_event_type_ri CONSTANT bdnp_presc_tracking.flg_event_type%TYPE := 'RI'; -- resent insert request into bdnp
    g_bdnp_event_type_rc CONSTANT bdnp_presc_tracking.flg_event_type%TYPE := 'RC'; -- resent cancel request into bdnp
    -- Public variable declarations
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);

    g_retval BOOLEAN;
    g_error  VARCHAR2(4000);
    g_exception EXCEPTION;
    g_found BOOLEAN;

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
    ) RETURN BOOLEAN;

END pk_api_bdnp;
/
