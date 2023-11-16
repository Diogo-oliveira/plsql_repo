/*-- Last Change Revision: $Rev: 2026737 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:44 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_api_sr_supplies AS

    /**********************************************************************************************
    * Get consumption and count supplies detail
    * 
    * @param    i_lang                      Language ID
    * @param    i_prof                      Professional's info
    * @param    i_id_episode                Episode ID
    *
    * @param    o_supply_count_detail       Cursor with list of supplies consumption and count
    * @param    o_error                     t_error_out
    * 
    * @return                               True on success, false on error
    * 
    * @Dependencies  REPORTS 
    *
    * @author  Filipe Silva
    * @version 2.6.0.4
    * @since   2010/11/29
    **********************************************************************************************/
    FUNCTION get_supply_count_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_supply_count_detail OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_SUPPLIES_EXTERNAL_API_DB.GET_SUPPLY_COUNT_DETAIL FUNCTION FOR ID_EPISODE ' || i_id_episode;
        IF NOT pk_supplies_external_api_db.get_supply_count_detail(i_lang                => i_lang,
                                                                   i_prof                => i_prof,
                                                                   i_id_episode          => i_id_episode,
                                                                   i_id_sr_supply_count  => NULL,
                                                                   o_supply_count_detail => o_supply_count_detail,
                                                                   o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUPPLY_COUNT_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_supply_count_detail);
            RETURN FALSE;
    END get_supply_count_detail;

    /**********************************************************************************************
    * Returns a list of all the supply requests and consumptions, grouped by status to REPORTS team.
    * 
    * @param i_lang        Language ID
    * @param i_prof        Professional's info
    * @param i_patient     Patient's id
    * @param i_episode     Current Episode
    *
    * @param o_list        list of all the supply requests and consumptions
    * @param o_error       Error info
    * 
    * @return        True on success, false on error
    *
    * @Dependencies  REPORTS 
    *
    * @author        Jorge Canossa
    * @since         2010/11/29
    **********************************************************************************************/
    FUNCTION get_list_req_cons_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN episode.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_SUPPLIES_API_DB.GET_SUPPLY_LISTVIEW';
        IF NOT pk_supplies_api_db.get_supply_listview(i_lang           => i_lang,
                                                      i_prof           => i_prof,
                                                      i_id_supply_area => pk_supplies_constant.g_area_surgical_supplies,
                                                      i_patient        => i_patient,
                                                      i_episode        => i_episode,
                                                      i_flg_type       => table_varchar(pk_supplies_constant.g_supply_kit_type,
                                                                                        pk_supplies_constant.g_supply_set_type,
                                                                                        pk_supplies_constant.g_supply_type,
                                                                                        pk_supplies_constant.g_supply_equipment_type,
                                                                                        pk_supplies_constant.g_supply_implant_type),
                                                      o_list           => o_list,
                                                      o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_list_req_cons_report;

    /********************************************************************************************** 
    * Supply workflow details for reports.
    *
    * @param i_lang                   Language ID
    * @pram i_prof                    Professional info
    * @param i_id_sup_wf              supply id
    * @param o_register               main cursor. holds all status transitions and their ids and dates
    * @param o_req                    requisition status. holds initial status info. 1 row only
    * @param o_canc                   cursor for all cancel status in the life of this req.
    * @param o_error                  error info, if any
    * 
    * @return  True on success, false on error
    * 
    * @Dependencies  REPORTS 
    *
    * @author  Jorge Canossa
    * @since   29-11-2010
    **********************************************************************************************/
    FUNCTION get_supply_wf_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_sup_wf IN supply_workflow.id_supply_workflow%TYPE,
        o_register  OUT pk_types.cursor_type,
        o_req       OUT pk_types.cursor_type,
        o_canceled  OUT pk_types.cursor_type,
        o_rejected  OUT pk_types.cursor_type,
        o_consumed  OUT pk_types.cursor_type,
        o_others    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL PK_SUPPLIES_API_DB.GET_SUPPLY_WF_DET';
        IF NOT pk_supplies_api_db.get_supply_detail(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_id_sup_wf => i_id_sup_wf,
                                                    o_register  => o_register,
                                                    o_req       => o_req,
                                                    o_canceled  => o_canceled,
                                                    o_rejected  => o_rejected,
                                                    o_consumed  => o_consumed,
                                                    o_others    => o_others,
                                                    o_error     => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END get_supply_wf_det;

    /********************************************************************************************
    *  Get current state of surgical supplies for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_sr_supplies_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_episodes      table_number := table_number();
        l_cnt_ongoing   NUMBER(24);
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error    := 'GET SCOPE EPISODES';
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        -- view returns in status column all items that arent cancelled
        -- and in status_completed returns 0 if items are completed () or 1 if there are any ongoing requests.
        BEGIN
        
            SELECT vsss.status, vsss.status_completed
              INTO l_cnt_completed, l_cnt_ongoing
              FROM v_sr_surgical_supplies vsss
             WHERE vsss.id_episode IN (SELECT *
                                         FROM TABLE(l_episodes));
        
        EXCEPTION
            WHEN no_data_found THEN
                l_cnt_completed := 0;
                l_cnt_ongoing   := 0;
        END;
    
        -- fill in viewer checklist flag
        IF l_cnt_ongoing > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_ongoing;
        ELSIF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    
    END get_sr_supplies_status;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_sr_supplies;
/
