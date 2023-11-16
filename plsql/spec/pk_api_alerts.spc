/*-- Last Change Revision: $Rev: 2028459 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_alerts IS

    -- Author  : Paulo Almeida
    -- Created : 2008/08/08
    -- Purpose : API for INTER_ALERT

    FUNCTION intf_insert_sys_alert_event
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_sys_alert_event IN sys_alert_event%ROWTYPE,
        i_flg_type_dest   IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION intf_get_sys_alert_event_det
    (
        i_id_language             IN language.id_language%TYPE,
        i_id_sys_alert_event      IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        o_sys_alert_event_details OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION intf_delete_sys_alert_event
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_id_sys_alert_event IN sys_alert_event.id_sys_alert_event%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION intf_ins_sys_alert_event_det
    (
        i_id_language        IN language.id_language%TYPE,
        i_id_sys_alert_event IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        i_dt_event           IN sys_alert_event_detail.dt_event%TYPE,
        i_id_professional    IN sys_alert_event_detail.id_professional%TYPE,
        i_prof_nick_name     IN sys_alert_event_detail.prof_nick_name%TYPE,
        i_desc_detail        IN sys_alert_event_detail.desc_detail%TYPE,
        i_id_detail_group    IN sys_alert_event_detail.id_detail_group%TYPE,
        i_desc_detail_group  IN sys_alert_event_detail.desc_detail_group%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function allows to create interface alerts with 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_sys_alert_event        ROWTYPE of table sys_alert_event
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2011/11/16
    **********************************************************************************************/

    FUNCTION intf_ins_sys_alert_detail
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_sys_alert_event           IN sys_alert_event%ROWTYPE,
        i_flg_type_dest             IN VARCHAR2,
        i_dt_event                  IN sys_alert_event_detail.dt_event%TYPE,
        i_desc_detail               IN sys_alert_event_detail.desc_detail%TYPE,
        i_id_detail_group           IN sys_alert_event_detail.id_detail_group%TYPE,
        i_desc_detail_group         IN sys_alert_event_detail.desc_detail_group%TYPE,
        o_id_sys_alert_event        OUT sys_alert_event.id_sys_alert_event%TYPE,
        o_id_sys_alert_event_detail OUT sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function allows to create interface alerts with INTERALERT-2879 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                         Joana Barroso
    * @version                        0.1
    * @since                          2013/06/14
    **********************************************************************************************/

    FUNCTION intf_ins_sys_alert_detail
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_id_sys_alert              IN sys_alert_event.id_sys_alert%TYPE,
        i_id_patient                IN patient.id_patient%TYPE,
        i_id_visit                  IN visit.id_visit%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_record                 IN sys_alert_event.id_record%TYPE,
        i_dt_record                 IN sys_alert_event.dt_record%TYPE,
        i_id_room                   IN sys_alert_event.id_room%TYPE,
        i_id_clinical_service       IN clinical_service.id_clinical_service%TYPE,
        i_flg_visible               IN sys_alert_event.flg_visible%TYPE,
        i_replace1                  IN sys_alert_event.replace1%TYPE,
        i_replace2                  IN sys_alert_event.replace2%TYPE,
        i_id_dep_clin_serv          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_intf_type              IN intf_type.id_intf_type%TYPE,
        i_flg_type_dest             IN VARCHAR2,
        i_dt_event                  IN sys_alert_event_detail.dt_event%TYPE,
        i_desc_detail               IN sys_alert_event_detail.desc_detail%TYPE,
        i_id_detail_group           IN sys_alert_event_detail.id_detail_group%TYPE,
        i_desc_detail_group         IN sys_alert_event_detail.desc_detail_group%TYPE,
        o_id_sys_alert_event        OUT sys_alert_event.id_sys_alert_event%TYPE,
        o_id_sys_alert_event_detail OUT sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION intf_ins_sys_alert_detail
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_id_sys_alert              IN sys_alert_event.id_sys_alert%TYPE,
        i_id_patient                IN patient.id_patient%TYPE,
        i_id_visit                  IN visit.id_visit%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_record                 IN sys_alert_event.id_record%TYPE,
        i_dt_record                 IN sys_alert_event.dt_record%TYPE,
        i_id_room                   IN sys_alert_event.id_room%TYPE,
        i_id_clinical_service       IN clinical_service.id_clinical_service%TYPE,
        i_flg_visible               IN sys_alert_event.flg_visible%TYPE,
        i_replace1                  IN sys_alert_event.replace1%TYPE,
        i_replace2                  IN sys_alert_event.replace2%TYPE,
        i_id_dep_clin_serv          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_intf_type              IN intf_type.id_intf_type%TYPE,
        i_flg_type_dest             IN VARCHAR2,
        i_dt_event                  IN sys_alert_event_detail.dt_event%TYPE,
        i_desc_detail               IN sys_alert_event_detail.desc_detail%TYPE,
        i_id_detail_group           IN sys_alert_event_detail.id_detail_group%TYPE,
        i_desc_detail_group         IN sys_alert_event_detail.desc_detail_group%TYPE,
        i_id_prof_order             IN sys_alert_event.id_prof_order%TYPE,
        o_id_sys_alert_event        OUT sys_alert_event.id_sys_alert_event%TYPE,
        o_id_sys_alert_event_detail OUT sys_alert_event_detail.id_sys_alert_event_detail%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;
    /* Stores log error messages. */

    /* Stores the package name. */

    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

END pk_api_alerts;
/
