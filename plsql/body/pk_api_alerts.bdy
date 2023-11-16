/*-- Last Change Revision: $Rev: 2026656 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_alerts IS

    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);

    g_retval BOOLEAN;
    g_error  VARCHAR2(4000);
    g_exception EXCEPTION;
    g_found BOOLEAN;

    /**
    * @headcom
    * Function to call pk_alerts.insert_sys_alert_event function
    *
    * @author   Paulo Almeida
    * @since    2008/08/08
    */
    FUNCTION intf_insert_sys_alert_event
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_sys_alert_event IN sys_alert_event%ROWTYPE,
        i_flg_type_dest   IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL TO PK_ALERTS.INSERT_SYS_ALERT_EVENT USING INTERFACE';
        IF NOT pk_alerts.insert_sys_alert_event(i_lang, i_prof, i_sys_alert_event, i_flg_type_dest, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'INTF_INSERT_SYS_ALERT_EVENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_insert_sys_alert_event;

    /**
    * @headcom
    * Function to call t_alerts.get_sys_alert_event_details function
    *
    * @author   Paulo Almeida
    * @since    2008/08/08
    */
    FUNCTION intf_get_sys_alert_event_det
    (
        i_id_language             IN language.id_language%TYPE,
        i_id_sys_alert_event      IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        o_sys_alert_event_details OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof profissional;
    BEGIN
        l_prof  := profissional(NULL, 0, 0);
        g_error := 'CALL TO T_ALERTS.GET_SYS_ALERT_EVENT_DETAILS USING INTERFACE';
        IF NOT pk_alerts.get_sys_alert_event_details(i_id_language,
                                                     l_prof,
                                                     i_id_sys_alert_event,
                                                     o_sys_alert_event_details,
                                                     o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_id_language,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     'ALERT',
                                                     g_package_name,
                                                     'INTF_GET_SYS_ALERT_EVENT_DET',
                                                     o_error);
    END intf_get_sys_alert_event_det;

    /********************************************************************************************
    * Deletes record from the event table.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional
    * @param i_id_sys_alert_event  ID of the record to delete
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Paulo Almeida
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION intf_delete_sys_alert_event
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_id_sys_alert_event IN sys_alert_event.id_sys_alert_event%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sys_alert_event sys_alert_event%ROWTYPE;
    BEGIN
    
        g_error := 'GET SYS_ALERT_EVENT RECORD';
        SELECT a.*
          INTO l_id_sys_alert_event
          FROM sys_alert_event a
         WHERE a.id_sys_alert_event = i_id_sys_alert_event;
    
        g_error := 'CALL TO PK_ALERTS.DELETE_SYS_ALERT_EVENT USING INTERFACE';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang, i_prof, l_id_sys_alert_event, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'INTF_DELETE_SYS_ALERT_EVENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_delete_sys_alert_event;

    /**
    * @headcom
    * Function to call t_alerts.ins_sys_alert_event_detail function
    *
    * @author   Paulo Almeida
    * @since    2008/08/08
    */
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
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL TO T_ALERTS.INS_SYS_ALERT_EVENT_DETAIL USING INTERFACE';
        IF NOT t_alerts.ins_sys_alert_event_detail(i_id_language,
                                                   i_id_sys_alert_event,
                                                   i_dt_event,
                                                   i_id_professional,
                                                   i_prof_nick_name,
                                                   i_desc_detail,
                                                   i_id_detail_group,
                                                   i_desc_detail_group,
                                                   o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_id_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'INTF_INS_SYS_ALERT_EVENT_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_ins_sys_alert_event_det;

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
    ) RETURN BOOLEAN IS
        l_prof_nick_name professional.nick_name%TYPE;
    BEGIN
    
        g_error  := 'CALL TO PK_ALERTS.INSERT_SYS_ALERT_EVENT USING INTERFACE';
        g_retval := pk_alerts.insert_sys_alert_event(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_sys_alert_event    => i_sys_alert_event,
                                                     i_flg_type_dest      => i_flg_type_dest,
                                                     o_id_sys_alert_event => o_id_sys_alert_event,
                                                     o_error              => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_error('ERROR:' || g_error);
            RETURN FALSE;
        END IF;
    
        g_error          := 'CALL TO pk_prof_utils.get_nickname';
        l_prof_nick_name := pk_prof_utils.get_nickname(i_lang => i_lang, i_prof_id => i_prof.id);
    
        g_error  := 'CALL TO T_ALERTS.INS_SYS_ALERT_EVENT_DETAIL USING INTERFACE';
        g_retval := t_alerts.ins_sys_alert_event_detail(i_id_language               => i_lang,
                                                        i_id_sys_alert_event        => o_id_sys_alert_event,
                                                        i_dt_event                  => i_dt_event,
                                                        i_id_professional           => i_prof.id,
                                                        i_prof_nick_name            => l_prof_nick_name,
                                                        i_desc_detail               => i_desc_detail,
                                                        i_id_detail_group           => i_id_detail_group,
                                                        i_desc_detail_group         => i_desc_detail_group,
                                                        o_id_sys_alert_event_detail => o_id_sys_alert_event_detail,
                                                        o_error                     => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_error('ERROR:' || g_error);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'INTF_INS_SYS_ALERT_DETAIL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_ins_sys_alert_detail;

    /********************************************************************************************
    * This function allows to create interface alerts with  INTERALERT-2879 
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
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT intf_ins_sys_alert_detail(i_lang                      => i_lang,
                                         i_prof                      => i_prof,
                                         i_id_sys_alert              => i_id_sys_alert,
                                         i_id_patient                => i_id_patient,
                                         i_id_visit                  => i_id_visit,
                                         i_id_episode                => i_id_episode,
                                         i_id_record                 => i_id_record,
                                         i_dt_record                 => i_dt_record,
                                         i_id_room                   => i_id_room,
                                         i_id_clinical_service       => i_id_clinical_service,
                                         i_flg_visible               => i_flg_visible,
                                         i_replace1                  => i_replace1,
                                         i_replace2                  => i_replace2,
                                         i_id_dep_clin_serv          => i_id_dep_clin_serv,
                                         i_id_intf_type              => i_id_intf_type,
                                         i_flg_type_dest             => i_flg_type_dest,
                                         i_dt_event                  => i_dt_event,
                                         i_desc_detail               => i_desc_detail,
                                         i_id_detail_group           => i_id_detail_group,
                                         i_desc_detail_group         => i_desc_detail_group,
                                         i_id_prof_order             => NULL,
                                         o_id_sys_alert_event        => o_id_sys_alert_event,
                                         o_id_sys_alert_event_detail => o_id_sys_alert_event_detail,
                                         o_error                     => o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'INTF_INS_SYS_ALERT_DETAIL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

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
    ) RETURN BOOLEAN IS
        l_sys_alert_event sys_alert_event%ROWTYPE;
    BEGIN
    
        l_sys_alert_event.id_sys_alert        := i_id_sys_alert;
        l_sys_alert_event.id_software         := i_prof.software;
        l_sys_alert_event.id_institution      := i_prof.institution;
        l_sys_alert_event.id_patient          := i_id_patient;
        l_sys_alert_event.id_visit            := i_id_visit;
        l_sys_alert_event.id_episode          := i_id_episode;
        l_sys_alert_event.id_record           := i_id_record;
        l_sys_alert_event.dt_record           := i_dt_record;
        l_sys_alert_event.id_professional     := i_prof.id;
        l_sys_alert_event.id_room             := i_id_room;
        l_sys_alert_event.id_clinical_service := i_id_clinical_service;
        l_sys_alert_event.flg_visible         := i_flg_visible;
        l_sys_alert_event.replace1            := i_replace1;
        l_sys_alert_event.replace2            := i_replace2;
        l_sys_alert_event.id_dep_clin_serv    := i_id_dep_clin_serv;
        l_sys_alert_event.id_intf_type        := i_id_intf_type;
        l_sys_alert_event.id_prof_order       := i_id_prof_order;
    
        g_error  := 'CALL PK_ALERTS.INTF_INS_SYS_ALERT_DETAIL USING INTERFACE';
        g_retval := pk_api_alerts.intf_ins_sys_alert_detail(i_lang                      => i_lang,
                                                            i_prof                      => i_prof,
                                                            i_sys_alert_event           => l_sys_alert_event,
                                                            i_flg_type_dest             => i_flg_type_dest,
                                                            i_dt_event                  => i_dt_event,
                                                            i_desc_detail               => i_desc_detail,
                                                            i_id_detail_group           => i_id_detail_group,
                                                            i_desc_detail_group         => i_desc_detail_group,
                                                            o_id_sys_alert_event        => o_id_sys_alert_event,
                                                            o_id_sys_alert_event_detail => o_id_sys_alert_event_detail,
                                                            o_error                     => o_error);
    
        IF NOT g_retval
        THEN
            pk_alertlog.log_error('ERROR:' || g_error);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'INTF_INS_SYS_ALERT_DETAIL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END intf_ins_sys_alert_detail;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_api_alerts;
/
