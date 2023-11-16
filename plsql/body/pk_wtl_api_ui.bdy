/*-- Last Change Revision: $Rev: 2015021 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-05-25 10:17:40 +0100 (qua, 25 mai 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_wtl_api_ui IS

    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
    g_error         VARCHAR2(4000);

    /******************************************************************************
    *  waiting list search for surgery entries. Market indepedent
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_args              all search criteria are contained here. for their specific indexes, see pk_wtl_prv_core
    *  @param  o_wtlist            output
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      24-04-2009
    ******************************************************************************/
    FUNCTION get_wtlist_search_surgery
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_args   IN table_varchar,
        o_wtlist OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_WTLIST_SEARCH_SURGERY';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET PK_WTL_PBL_CORE.GET_WTLIST_SEARCH_SURGERY';
        IF NOT pk_wtl_pbl_core.get_wtlist_search_surgery(i_lang, i_prof, i_args, o_wtlist, o_error)
        THEN
            RAISE l_exception;
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
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_wtlist);
            RETURN FALSE;
    END get_wtlist_search_surgery;

    /******************************************************************************
    *  universal waiting list search. Market indepedent
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_args              all search criteria are contained here. for their specific indexes, see pk_wtl_prv_core
    *  @param  o_wtlist            output
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      24-04-2009
    ******************************************************************************/
    FUNCTION get_wtlist_search
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_args    IN table_varchar,
        i_wl_type IN VARCHAR2,
        o_wtlist  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_WTLIST_SEARCH';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET PK_WTL_PBL_CORE.GET_WTLIST_SEARCH';
        IF NOT pk_wtl_pbl_core.get_wtlist_search(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_args    => i_args,
                                                 i_wl_type => i_wl_type,
                                                 o_wtlist  => o_wtlist,
                                                 o_error   => o_error)
        THEN
            RAISE l_exception;
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
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_wtlist);
            RETURN FALSE;
    END get_wtlist_search;

    /***************************************************************************************************************
    * 
    * If all required conditions are met, the provided WTList is cancelled, and so are all of its related 
    * episodes and schedules.
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT Professional
    * @param      i_wtl_id            ID of the WL entry to cancel.
    * @param      i_id_cancel_reason  code of CANCEL_REASON.
    * @param      i_notes_cancel      Free text
    * @param      o_error             output in case of error
    *
    * @RETURN  true or false
    * @author  Ricardo Nuno Almeida
    * @version 1.0
    * @since   27-04-2009
    *
    ****************************************************************************************************/
    FUNCTION cancel_wtlist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_wtl_id           IN waiting_list.id_waiting_list%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel     IN waiting_list.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CANCEL_WTLIST';
        l_msg_error sys_message.desc_message%TYPE;
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET PK_WTL_PBL_CORE.CANCEL_WTLIST';
        IF NOT pk_wtl_pbl_core.cancel_wtlist(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_wtl_id           => i_wtl_id,
                                             i_id_cancel_reason => i_id_cancel_reason,
                                             i_notes_cancel     => i_notes_cancel,
                                             i_flg_rolback      => pk_alert_constant.g_yes,
                                             o_msg_error        => l_msg_error,
                                             o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              o_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_wtlist;

    /******************************************************************************
    *  Returns the Waiting List summary for multiple entries. 
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting List IDs
    *  @param  o_data              data
    *  @param  o_error             error info
    *
    *  @return                     boolean
    *
    *  @author                     Telmo
    *  @version                    2.5
    *  @since                      27-04-2009
    ******************************************************************************/
    FUNCTION get_wtlist_summary_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_wtlist IN table_number,
        o_data      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_WTLIST_SUMMARY_ALL';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET PK_WTL_PBL_CORE.GET_WTLIST_SUMMARY_ALL';
        IF NOT pk_wtl_pbl_core.get_wtlist_summary_all(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_id_wtlist => i_id_wtlist,
                                                      o_data      => o_data,
                                                      o_error     => o_error)
        THEN
            RAISE l_exception;
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
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_wtlist_summary_all;
    /******************************************************************************
    *  
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_id_wtlist         Waiting List ID
    *  @param  o_list              viewer list
    *  @param  o_error               
    *
    *  @return                     boolean
    *
    *  @author                     Fábio
    *  @version                    2.5.0.2
    *  @since                      2009/04/27
    *
    ******************************************************************************/
    FUNCTION get_viewer_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_waiting_list IN waiting_list.id_waiting_list%TYPE,
        i_screen       IN VARCHAR2 DEFAULT 'I',
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_VIEWER_LIST';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET PK_WTL_PBL_CORE.GET_VIEWER_LIST';
        IF NOT pk_wtl_pbl_core.get_viewer_list(i_lang, i_prof, i_waiting_list, i_screen, o_list, o_error)
        THEN
            RAISE l_exception;
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
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_viewer_list;

    /********************************************************************************************
    * Returns all data for Admission and Surgery Request for a given waiting list.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_episode       Surgical Episode ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_adm_request      Admission request data       
    * @param o_diag             Diagnoses
    * @param o_surg_specs       Surgery Speciality(ies)       
    * @param o_pref_surg        Preferred surgeons
    * @param o_procedures       Surgical procedures
    * @param o_ext_disc         External disciplines
    * @param o_danger_cont      Danger of contamination
    * @param o_preferred_time   Preferred time
    * @param o_pref_time_reason Preferred time reason(s)
    * @param o_pos              POS decision
    * @param o_surg_request     Remaining info. about the surgery request  
    * @param o_waiting_list     Remaining info. about the waiting list
    * @param o_unavailabilities List of unavailability periods
    * @param o_sched_period     Scheduling period
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/04
    *********************************************************************************************/
    FUNCTION get_adm_surg_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_waiting_list   IN waiting_list.id_waiting_list%TYPE,
        o_adm_request       OUT pk_types.cursor_type,
        o_diag              OUT pk_types.cursor_type,
        o_surg_specs        OUT pk_types.cursor_type,
        o_pref_surg         OUT pk_types.cursor_type,
        o_procedures        OUT pk_types.cursor_type,
        o_ext_disc          OUT pk_types.cursor_type,
        o_danger_cont       OUT pk_types.cursor_type,
        o_preferred_time    OUT pk_types.cursor_type,
        o_pref_time_reason  OUT pk_types.cursor_type,
        o_pos               OUT pk_types.cursor_type,
        o_surg_request      OUT pk_types.cursor_type,
        o_waiting_list      OUT pk_types.cursor_type,
        o_unavailabilities  OUT pk_types.cursor_type,
        o_sched_period      OUT pk_types.cursor_type,
        o_referral          OUT pk_types.cursor_type,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_doc_scales        OUT pk_types.cursor_type,
        o_pos_validation    OUT pk_types.cursor_type,
        -- Clinical Questions
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cancel_info pk_types.cursor_type;
    BEGIN
    
        RETURN get_adm_surg_request(i_lang                      => i_lang,
                                    i_prof                      => i_prof,
                                    i_id_episode                => i_id_episode,
                                    i_id_waiting_list           => i_id_waiting_list,
                                    o_adm_request               => o_adm_request,
                                    o_diag                      => o_diag,
                                    o_surg_specs                => o_surg_specs,
                                    o_pref_surg                 => o_pref_surg,
                                    o_procedures                => o_procedures,
                                    o_ext_disc                  => o_ext_disc,
                                    o_danger_cont               => o_danger_cont,
                                    o_preferred_time            => o_preferred_time,
                                    o_pref_time_reason          => o_pref_time_reason,
                                    o_pos                       => o_pos,
                                    o_surg_request              => o_surg_request,
                                    o_waiting_list              => o_waiting_list,
                                    o_unavailabilities          => o_unavailabilities,
                                    o_sched_period              => o_sched_period,
                                    o_referral                  => o_referral,
                                    o_doc_area_register         => o_doc_area_register,
                                    o_doc_area_val              => o_doc_area_val,
                                    o_doc_scales                => o_doc_scales,
                                    o_pos_validation            => o_pos_validation,
                                    o_cancel_info               => l_cancel_info,
                                    o_interv_clinical_questions => o_interv_clinical_questions,
                                    o_error                     => o_error);
    END;

    /********************************************************************************************
    * Returns all data for Admission and Surgery Request for a given waiting list.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_episode       Surgical Episode ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_adm_request      Admission request data       
    * @param o_diag             Diagnoses
    * @param o_surg_specs       Surgery Speciality(ies)       
    * @param o_pref_surg        Preferred surgeons
    * @param o_procedures       Surgical procedures
    * @param o_ext_disc         External disciplines
    * @param o_danger_cont      Danger of contamination
    * @param o_preferred_time   Preferred time
    * @param o_pref_time_reason Preferred time reason(s)
    * @param o_pos              POS decision
    * @param o_surg_request     Remaining info. about the surgery request  
    * @param o_waiting_list     Remaining info. about the waiting list
    * @param o_unavailabilities List of unavailability periods
    * @param o_sched_period     Scheduling period
    * @param o_cancel_info      Cancelation Info
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/04
    *********************************************************************************************/
    FUNCTION get_adm_surg_request
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_waiting_list           IN waiting_list.id_waiting_list%TYPE,
        o_adm_request               OUT pk_types.cursor_type,
        o_diag                      OUT pk_types.cursor_type,
        o_surg_specs                OUT pk_types.cursor_type,
        o_pref_surg                 OUT pk_types.cursor_type,
        o_procedures                OUT pk_types.cursor_type,
        o_ext_disc                  OUT pk_types.cursor_type,
        o_danger_cont               OUT pk_types.cursor_type,
        o_preferred_time            OUT pk_types.cursor_type,
        o_pref_time_reason          OUT pk_types.cursor_type,
        o_pos                       OUT pk_types.cursor_type,
        o_surg_request              OUT pk_types.cursor_type,
        o_waiting_list              OUT pk_types.cursor_type,
        o_unavailabilities          OUT pk_types.cursor_type,
        o_sched_period              OUT pk_types.cursor_type,
        o_referral                  OUT pk_types.cursor_type,
        o_doc_area_register         OUT pk_types.cursor_type,
        o_doc_area_val              OUT pk_types.cursor_type,
        o_doc_scales                OUT pk_types.cursor_type,
        o_pos_validation            OUT pk_types.cursor_type,
        o_cancel_info               OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
        l_func_name VARCHAR2(200) := 'GET_ADM_SURG_REQUEST';
    
    BEGIN
    
        IF NOT pk_wtl_pbl_core.get_adm_surg_request(i_lang                      => i_lang,
                                                    i_prof                      => i_prof,
                                                    i_id_episode                => i_id_episode,
                                                    i_id_waiting_list           => i_id_waiting_list,
                                                    o_adm_request               => o_adm_request,
                                                    o_diag                      => o_diag,
                                                    o_surg_specs                => o_surg_specs,
                                                    o_pref_surg                 => o_pref_surg,
                                                    o_procedures                => o_procedures,
                                                    o_ext_disc                  => o_ext_disc,
                                                    o_danger_cont               => o_danger_cont,
                                                    o_preferred_time            => o_preferred_time,
                                                    o_pref_time_reason          => o_pref_time_reason,
                                                    o_pos                       => o_pos,
                                                    o_surg_request              => o_surg_request,
                                                    o_waiting_list              => o_waiting_list,
                                                    o_unavailabilities          => o_unavailabilities,
                                                    o_sched_period              => o_sched_period,
                                                    o_referral                  => o_referral,
                                                    o_doc_area_register         => o_doc_area_register,
                                                    o_doc_area_val              => o_doc_area_val,
                                                    o_doc_scales                => o_doc_scales,
                                                    o_pos_validation            => o_pos_validation,
                                                    o_cancel_info               => o_cancel_info,
                                                    o_interv_clinical_questions => o_interv_clinical_questions,
                                                    o_error                     => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.reset_error_state();
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            --
            pk_types.open_my_cursor(o_adm_request);
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_surg_specs);
            pk_types.open_my_cursor(o_pref_surg);
            pk_types.open_my_cursor(o_procedures);
            pk_types.open_my_cursor(o_ext_disc);
            pk_types.open_my_cursor(o_danger_cont);
            pk_types.open_my_cursor(o_preferred_time);
            pk_types.open_my_cursor(o_pref_time_reason);
            pk_types.open_my_cursor(o_pos);
            pk_types.open_my_cursor(o_surg_request);
            pk_types.open_my_cursor(o_waiting_list);
            pk_types.open_my_cursor(o_unavailabilities);
            pk_types.open_my_cursor(o_sched_period);
            pk_types.open_my_cursor(o_referral);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_scales);
            pk_types.open_my_cursor(o_cancel_info);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state();
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            --
            pk_utils.undo_changes;
            --
            pk_types.open_my_cursor(o_adm_request);
            pk_types.open_my_cursor(o_diag);
            pk_types.open_my_cursor(o_surg_specs);
            pk_types.open_my_cursor(o_pref_surg);
            pk_types.open_my_cursor(o_procedures);
            pk_types.open_my_cursor(o_ext_disc);
            pk_types.open_my_cursor(o_danger_cont);
            pk_types.open_my_cursor(o_preferred_time);
            pk_types.open_my_cursor(o_pref_time_reason);
            pk_types.open_my_cursor(o_pos);
            pk_types.open_my_cursor(o_surg_request);
            pk_types.open_my_cursor(o_waiting_list);
            pk_types.open_my_cursor(o_unavailabilities);
            pk_types.open_my_cursor(o_sched_period);
            pk_types.open_my_cursor(o_referral);
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_scales);
            pk_types.open_my_cursor(o_cancel_info);
            RETURN FALSE;
    END get_adm_surg_request;

    /********************************************************************************************
    * Checks if the patient's order in the waiting list may be changed, and returns a message.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, Institution ID, Software ID
    * @param i_id_waiting_list  Waiting list ID
    * @param o_flg_show         Show message: (Y) Yes (N) No
    * @param o_msg_title        Message title
    * @param o_msg_text         Message text
    * @param o_button           Button type
    * @param o_error            Error
    *
    * @author    José Brito
    * @version   2.5.0.2
    * @since     2009/05/06
    *********************************************************************************************/
    FUNCTION check_waiting_list_order
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_waiting_list     IN waiting_list.id_waiting_list%TYPE,
        i_dt_sched_period_end IN VARCHAR2,
        i_wtl_urg_level       IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_func_eval_modified  IN VARCHAR2,
        i_id_patient          IN patient.id_patient%TYPE,
        o_flg_show            OUT VARCHAR2,
        o_msg_title           OUT VARCHAR2,
        o_msg_text            OUT VARCHAR2,
        o_button              OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(200) := 'CHECK_WAITING_LIST_ORDER';
        l_exception EXCEPTION;
    
    BEGIN
    
        IF NOT pk_wtl_pbl_core.check_waiting_list_order(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_waiting_list     => i_id_waiting_list,
                                                        i_dt_sched_period_end => i_dt_sched_period_end,
                                                        i_wtl_urg_level       => i_wtl_urg_level,
                                                        i_func_eval_modified  => i_func_eval_modified,
                                                        i_id_patient          => i_id_patient,
                                                        o_flg_show            => o_flg_show,
                                                        o_msg_title           => o_msg_title,
                                                        o_msg_text            => o_msg_text,
                                                        o_button              => o_button,
                                                        o_error               => o_error)
        
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_waiting_list_order;

    /******************************************************************************
    *  Universal waiting list search for inpatient entries. Market independent
    *
    *  @param  i_lang              Language ID
    *  @param  i_prof              Professional ID/Institution ID/Software ID
    *  @param  i_args              all search criteria are contained here. for their specific indexes, see pk_wtl_prv_core
    *  @param  o_wtlist            output
    *  @param  o_error             error info  
    *
    *  @return                     boolean
    *
    *  @author                     Sérgio Cunha
    *  @version                    2.5.0.3
    *  @since                      22-05-2009
    ******************************************************************************/
    FUNCTION get_wtlist_search_inpatient
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_args   IN table_varchar,
        o_wtlist OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_WTLIST_SEARCH_INPATIENT';
        l_exception EXCEPTION;
    BEGIN
        g_error := 'GET PK_WTL_PBL_CORE.GET_WTLIST_SEARCH_INPATIENT';
        IF NOT pk_wtl_pbl_core.get_wtlist_search_inpatient(i_lang, i_prof, i_args, o_wtlist, o_error)
        THEN
            RAISE l_exception;
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
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_wtlist);
            RETURN FALSE;
    END get_wtlist_search_inpatient;

    FUNCTION undelete_wtlist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_wtl  IN waiting_list.id_waiting_list%TYPE,
        i_id_epis IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(30) := 'UNDELETE_WTLIST';
        l_exception      EXCEPTION;
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'GET PK_WTL_PBL_CORE.UNDELETE_WTLIST';
        IF NOT pk_wtl_pbl_core.undelete_wtlist(i_lang, i_prof, i_id_wtl, i_id_epis, l_transaction_id, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
    END undelete_wtlist;

    FUNCTION get_value_from_time_pref(i_val IN NUMBER) RETURN VARCHAR2 AS
        l_ret VARCHAR2(2 CHAR);
    BEGIN
    
        CASE i_val
            WHEN 1 THEN
                l_ret := 'M';
            WHEN 2 THEN
                l_ret := 'A';
            WHEN 3 THEN
                l_ret := 'N';
            WHEN 4 THEN
                l_ret := 'O';
            ELSE
                l_ret := '';
        END CASE;
    
        RETURN l_ret;
    END get_value_from_time_pref;

    /******************************************************************************
    *  Adds Admission or Surgery Requests to the Waiting List.
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Professional ID/Institution ID/Software ID
    * @param i_id_patient                Patient ID
    * @param i_id_episode                Current episode ID
    * @param io_id_episode_sr             Surgical episode ID (if exists)
    * @param io_id_episode_inp            Inpatient episode ID (if exists)
    * @param io_id_waiting_list           Waiting list ID (if exists)     
    * @param i_flg_type                  Type of request: (B) Bed - admission request (S) Surgery request (A) All
    * @param i_id_wtl_urg_level          Urgency level ID
    * @param i_dt_sched_period_start     Scheduling period start date
    * @param i_dt_sched_period_end       Scheduling period end date
    * @param i_min_inform_time           Minimum time to inform
    * @param i_dt_surgery                Suggested surgery date
    * @param i_unav_period_start         Unavailability period: start date(s)
    * @param i_unav_period_end           Unavailability period: end date(s)    
    * @param i_pref_surgeons              Array of preferred surgeons
    * @param i_external_dcs               Array of external disciplines
    * @param i_dep_clin_serv_sr           Array of specialities (for the surgical procedure)
    * @param i_flg_pref_time              Array for preferred time: (M) Morning (A) Afternoon (N) Night (O) Any
    * @param i_reason_pref_time           Array of reasons for preferred time
    * @param i_id_sr_intervention         Array of surgical procedures ID
    * @param i_flg_laterality             Array of laterality for each procedure
    * @param i_duration                   Expected duration of the surgical procedure
    * @param i_icu                        Intensive care unit: (Y) Yes (N) No
    * @param i_notes_surg                 Scheduling notes
    * @param i_adm_needed                 Admission needed: (Y) Yes (N) No
    * @param i_id_sr_pos_status           POS Decision   
    * @param i_surg_needed                Surgery needed: (Y) Yes (N) No
    * @param i_adm_indication             Indication for admission ID
    * @param i_dest_inst                  Location requested
    * @param i_adm_type                   Admission type
    * @param i_department                 Department requested
    * @param i_room_type                  Room type
    * @param i_dep_clin_serv              Specialty requested
    * @param i_pref_room                  Preferred room
    * @param i_mixed_nursing              Mixed nursing preference
    * @param i_bed_type                   Bed type
    * @param i_dest_prof                  Professional requested to take the admission
    * @param i_adm_preparation            Admission preparation
    * @param i_dt_admission               Date of admission (final)
    * @param i_expect_duration            Admission's expected duration
    * @param i_notes                      Entered notes
    * @param i_nit_flg                    Flag indicating need for a nurse intake
    * @param i_nit_dt_suggested           Date suggested for the nurse intake
    * @param i_nit_dcs                    Dep_clin_serv for nurse intake
    * @param i_supply                     Supply ID
    * @param i_supply_set                 Parent supply set (if applicable)
    * @param i_supply_qty                 Supply quantity
    * @param i_supply_loc                 Supply location
    * @param i_dt_return                  Estimated date of of return
    * @param i_supply_soft_inst           list
    * @param i_flg_cons_type              flag of consumption type
    * @param i_description_sp             Table varchar with surgical procedures' description
    * @param i_id_sr_epis_interv          Table number with id_sr_epis_interv
    * @param i_id_req_reason              Reasons for each supply
    * @param i_supply_notes               Supply Request notes
    * @param i_flg_add_problem_sp         The surgical procedure's diagnosis should be associated with problems list? 
    * @param i_flg_add_problem_doc        The danger of contamination's diagnosis should be associated with problems list?
    * @param i_flg_add_problem            The diagnosis should be associated with problems list?
    * @param i_id_cdr_call                Rule event identifier.
    * @param i_diagnosis_adm_req          Admission request diagnosis info
    * @param i_diagnosis_surg_proc        Surgical procedure diagnosis info
    * @param i_diagnosis_contam           Contamination diagnosis info
    * @param o_error                     Error
    *
    *  @return                     TRUE if successful, FALSE otherwise
    *
    *  @author                     José Brito
    *  @version                    1.0
    *  @since                      2009/05/04
    *
    ******************************************************************************/

    FUNCTION set_adm_surg_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE, -- Current episode
        io_id_episode_sr  IN OUT episode.id_episode%TYPE, -- Surgical episode -- 5
        io_id_episode_inp IN OUT episode.id_episode%TYPE, -- Inpatient episode
        -- Waiting List / Common
        io_id_waiting_list IN OUT waiting_list.id_waiting_list%TYPE,
        i_data             CLOB,
        i_profs_alert      IN table_number DEFAULT NULL,
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL,
        i_order_set        IN VARCHAR2,
        o_adm_request      OUT adm_request.id_adm_request%TYPE,
        o_msg_error        OUT VARCHAR2,
        o_title_error      OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_exception EXCEPTION;
        l_func_name VARCHAR2(200) := 'SET_ADM_SURG_REQUEST';
    
        l_p   xmlparser.parser;
        l_doc xmldom.domdocument; -- represents the entire XML document 
    
        l_nl   xmldom.domnodelist; -- interface provides the abstraction of an ordered collection of nodes
        l_n    xmldom.domnode; -- primary datatype for the entire Document Object Model
        l_e    xmldom.domelement;
        l_e1   xmldom.domelement;
        l_nlen NUMBER;
    
        l_ri_reason_admission NUMBER(24);
        l_rs_sur_need         VARCHAR2(200 CHAR);
        l_ri_diagnoses        CLOB;
        l_ri_loc_int          NUMBER(24);
        l_ri_serv_adm         NUMBER(24);
        l_ri_esp_int          NUMBER(24);
        l_ri_prof_spec        NUMBER(24);
        l_ri_phys_adm         NUMBER(24);
        l_rs_type_int         NUMBER(24);
        l_ri_durantion        NUMBER(24);
        l_ri_prepar           NUMBER(24);
        l_ri_type_room        NUMBER(24);
        l_ri_regimen          VARCHAR2(200 CHAR);
        l_ri_beneficiario     VARCHAR2(200 CHAR);
        l_ri_precauciones     VARCHAR2(200 CHAR);
        l_ri_contactado       VARCHAR2(200 CHAR);
        l_ri_regimen_l        VARCHAR2(200 CHAR);
        l_ri_beneficiario_l   VARCHAR2(200 CHAR);
        l_ri_precauciones_l   VARCHAR2(200 CHAR);
        l_ri_contactado_l     VARCHAR2(200 CHAR);
        l_ri_mix_room         VARCHAR2(200 CHAR);
        l_ri_compulsory       VARCHAR2(200 CHAR);
        l_ri_compulsory_l     VARCHAR2(200 CHAR);
        l_ri_compulsory_id    NUMBER(24);
        l_ri_compulsory_desc  VARCHAR2(4000 CHAR);
        l_rs_type_bed         NUMBER(24);
        l_ri_pref_room        NUMBER(24);
        l_ri_need_nurse_cons  VARCHAR2(200 CHAR);
        l_ri_loc_nurse_cons   NUMBER(24);
        l_ri_date_nurse_cons  VARCHAR2(200 CHAR);
        l_ri_notes            VARCHAR2(1000 CHAR);
        l_rs_loc_surgery      VARCHAR2(200 CHAR);
        l_rs_spec_surgery     NUMBER(24);
        l_rs_department       NUMBER(24);
        l_rs_clin_service     NUMBER(24);
        l_rs_pref_surg        NUMBER(24);
        l_rs_proc_surg        VARCHAR2(200 CHAR);
        l_rs_prev_duration    NUMBER(6);
        l_rs_uci              VARCHAR2(200 CHAR);
        l_rs_uci_pos          VARCHAR2(200 CHAR);
        l_rs_ext_spec         NUMBER(24);
        l_rs_cont_danger      CLOB;
        l_rs_pref_time        VARCHAR2(200 CHAR);
        l_rs_mot_pref_time    NUMBER(24);
        l_rs_notes            VARCHAR2(1000 CHAR);
        l_rv_request          VARCHAR2(200 CHAR);
        l_rv_dt_verif         VARCHAR2(200 CHAR);
        l_rv_notes_req        VARCHAR2(1000 CHAR);
        l_rv_decision         VARCHAR2(200 CHAR);
        l_rv_valid            VARCHAR2(200 CHAR);
        l_rv_notes_decis      VARCHAR2(1000 CHAR);
        l_rsp_lvl_urg         NUMBER(24);
        l_rsp_begin_sched     VARCHAR2(200 CHAR);
        l_rsp_end_sched       VARCHAR2(200 CHAR);
        l_rsp_time_min        NUMBER(6);
        l_rsp_sugg_dt_surg    VARCHAR2(200 CHAR);
        l_rsp_sugg_dt_int     VARCHAR2(200 CHAR);
        l_rip_begin_per       VARCHAR2(200 CHAR);
        l_rip_duration        VARCHAR2(200 CHAR);
        l_rip_end_per         VARCHAR2(200 CHAR);
    
        l_ri_reason_admission_l    NUMBER(24);
        l_ri_reason_admission_desc adm_request.adm_indication_ft%TYPE;
        l_rs_sur_need_l            VARCHAR2(200 CHAR);
        l_ri_diagnoses_l           CLOB;
        l_ri_loc_int_l             NUMBER(24);
        l_ri_serv_adm_l            NUMBER(24);
        l_ri_esp_int_l             NUMBER(24);
        l_ri_phys_adm_l            NUMBER(24);
        l_rs_type_int_l            NUMBER(24);
        l_ri_durantion_l           NUMBER(24);
        l_ri_prepar_l              NUMBER(24);
        l_ri_type_room_l           NUMBER(24);
        l_ri_mix_room_l            VARCHAR2(200 CHAR);
        l_rs_type_bed_l            NUMBER(24);
        l_ri_pref_room_l           NUMBER(24);
        l_ri_need_nurse_cons_l     VARCHAR2(200 CHAR);
        l_ri_loc_nurse_cons_l      NUMBER(24);
        l_ri_date_nurse_cons_l     VARCHAR2(200 CHAR);
        l_ri_notes_l               VARCHAR2(1000 CHAR);
        l_rs_loc_surgery_l         VARCHAR2(200 CHAR);
        l_rs_spec_surgery_l        NUMBER(24);
        l_rs_pref_surg_l           NUMBER(24);
        l_rs_proc_surg_l           VARCHAR2(200 CHAR);
        l_rs_prev_duration_l       NUMBER(6);
        l_rs_uci_l                 VARCHAR2(200 CHAR);
        l_rs_uci_pos_l             VARCHAR2(200 CHAR);
        l_rs_ext_spec_l            NUMBER(24);
        l_rs_cont_danger_l         VARCHAR2(200 CHAR);
        l_rs_pref_time_l           VARCHAR2(200 CHAR);
        l_rs_mot_pref_time_l       NUMBER(24);
        l_rs_notes_l               VARCHAR2(1000 CHAR);
        l_rs_glb_anesth            VARCHAR2(10 CHAR);
        l_rs_glb_anesth_l          VARCHAR2(10 CHAR);
        l_rs_lcl_anesth            VARCHAR2(10 CHAR);
        l_rs_lcl_anesth_l          VARCHAR2(10 CHAR);
        l_rv_request_l             VARCHAR2(200 CHAR);
        l_rv_dt_verif_l            VARCHAR2(200 CHAR);
        l_rv_notes_req_l           VARCHAR2(1000 CHAR);
        l_rv_decision_l            VARCHAR2(200 CHAR);
        l_rv_valid_l               VARCHAR2(200 CHAR);
        l_rv_notes_decis_l         VARCHAR2(1000 CHAR);
        l_rsp_lvl_urg_l            NUMBER(24);
        l_rsp_begin_sched_l        VARCHAR2(200 CHAR);
        l_rsp_end_sched_l          VARCHAR2(200 CHAR);
        l_rsp_time_min_l           NUMBER(6);
        l_rsp_sugg_dt_surg_l       VARCHAR2(200 CHAR);
        l_rsp_sugg_dt_int_l        VARCHAR2(200 CHAR);
        l_rip_begin_per_l          VARCHAR2(200 CHAR);
        l_rip_duration_l           VARCHAR2(200 CHAR);
        l_rip_end_per_l            VARCHAR2(200 CHAR);
    
        l_cs_type    NUMBER;
        l_cs_prof_id NUMBER;
        l_cs_date    VARCHAR2(200 CHAR);
    
        l_sr_proc_notes        VARCHAR2(4000 CHAR);
        l_sr_proc_team         NUMBER(24);
        l_sr_proc_diag         CLOB;
        l_sr_proc_type         VARCHAR2(10 CHAR);
        l_sr_proc_codification NUMBER(24);
        l_sr_proc_laterality   VARCHAR2(10 CHAR);
        l_sr_proc_ss           VARCHAR2(4000 CHAR);
        l_sr_proc_value        NUMBER(24);
    
        parent_node xmldom.domnode;
        childnodes  xmldom.domnodelist;
    
        l_tbl_prof   table_table_number := table_table_number();
        l_tbl_catg   table_table_number := table_table_number();
        l_tbl_status table_table_varchar := table_table_varchar();
    
        tbl_pref_surgeons table_number := table_number();
        tbl_ext_serv      table_number := table_number();
        tbl_pref_time     table_varchar := table_varchar();
    
        r_tbl_prof   table_number;
        r_tbl_catg   table_number;
        r_tbl_status table_varchar;
    
        l_team_status VARCHAR2(10 CHAR);
        l_team_task   NUMBER(24);
        l_team_id     NUMBER(24);
        len           NUMBER(24);
        n             xmldom.domnode;
    
        childnodes1 xmldom.domnodelist;
        len1        NUMBER(24);
        len_tb_d    NUMBER(24);
        n1          xmldom.domnode;
        teste       VARCHAR2(100 CHAR);
    
        len_tbl  NUMBER(24);
        len_ttbl NUMBER(24);
    
        l_sr_proc_diagnoses CLOB;
        l_tbl_sr_proc_diag  table_clob;
    
        l_epis_type_sr  epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_operating;
        l_epis_type_inp epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_inpatient;
    
        l_clinical_question table_table_number := table_table_number();
        r_clinical_question table_number;
    
        l_response table_table_varchar := table_table_varchar();
        r_response table_varchar;
    
        l_clinical_question_notes table_table_clob := table_table_clob();
        r_clinical_question_notes table_clob;
    
        l_ttbl_supply table_table_number := table_table_number();
        l_tbl_supply  table_number;
        l_bl_supply   NUMBER(24);
    
        l_ttbl_supply_qty table_table_number := table_table_number();
        l_tbl_supply_qty  table_number;
        l_bl_supply_qty   NUMBER(24);
    
        l_ttbl_supply_soft table_table_number := table_table_number();
        l_tbl_supply_soft  table_number;
        l_bl_supply_soft   NUMBER(24);
    
        l_ttbl_supply_loc table_table_number := table_table_number();
        l_tbl_supply_loc  table_number;
        l_bl_supply_loc   NUMBER(24);
    
        l_ttbl_supply_set table_table_number := table_table_number();
        l_tbl_supply_set  table_number;
        l_bl_supply_set   NUMBER(24);
    
        l_ttbl_supply_dtr table_table_varchar := table_table_varchar();
        l_tbl_supply_dtr  table_varchar;
        l_bl_supply_dtr   VARCHAR2(200 CHAR);
    
        l_ttbl_supply_fct table_table_varchar := table_table_varchar();
        l_tbl_supply_fct  table_varchar;
        l_bl_supply_fct   VARCHAR2(200 CHAR);
    
        l_ttbl_supply_not table_table_varchar := table_table_varchar();
        l_tbl_supply_not  table_varchar;
        l_bl_supply_not   VARCHAR2(200 CHAR);
    
        l_ttbl_supply_irr table_table_number := table_table_number();
        l_tbl_supply_irr  table_number;
        l_bl_supply_irr   NUMBER(24);
    
        v_response                VARCHAR2(32767);
        v_clinical_question       VARCHAR2(32767);
        v_clinical_question_notes CLOB;
    
        l_id_diagnosis_prev   CLOB;
        l_rs_cont_danger_prev CLOB;
        l_diag_epis_type      pk_edis_types.rec_in_epis_diagnosis;
        l_diag_epis_type_cont pk_edis_types.rec_in_epis_diagnosis;
    
        tbl_sr_proc_value        table_number := table_number();
        tbl_sr_proc_type         table_varchar := table_varchar();
        tbl_sr_proc_codification table_number := table_number();
        tbl_sr_proc_laterality   table_varchar := table_varchar();
        tbl_sr_proc_ss           table_varchar := table_varchar();
        tbl_sr_proc_notes        table_varchar := table_varchar();
        tbl_sr_proc_team         table_number := table_number();
        tbl_sr_proc_diag         table_clob := table_clob();
    
        idx                    NUMBER;
        tbl_sr_epis_interv     table_number := table_number();
        tbl_sr_epis_interv_int table_number := table_number();
        tbl_sr_intervention    table_number := table_number();
        tbl_description_sp     table_varchar := table_varchar();
        tbl_ct_io              table_table_varchar := table_table_varchar();
        tbl_surgery_record     table_number := table_number();
    
        tbl_rip_begin table_varchar := table_varchar();
        tbl_rip_end   table_varchar := table_varchar();
    
        l_id_co_sign      co_sign.id_co_sign%TYPE;
        l_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    
        l_rows_upd table_varchar;
    
        g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_id_market     market.id_market%TYPE := pk_prof_utils.get_prof_market(i_prof => i_prof);
        l_id_mrp        NUMBER(24);
        l_id_written_by NUMBER(24);
    
        FUNCTION get_previous_diagnosis
        (
            i_lang           IN language.id_language%TYPE,
            i_prof           IN profissional,
            i_ri_diagnosis   IN CLOB,
            i_id_diag_prev   IN CLOB,
            i_diag_epis_type IN OUT pk_edis_types.rec_in_epis_diagnosis
        ) RETURN BOOLEAN IS
        
            l_tbl_diag   table_varchar := table_varchar();
            l_diags_form table_number := table_number();
            l_count_diag INTEGER;
        
            PROCEDURE set_diag_info
            (
                i_id_diag      IN diagnosis.id_diagnosis%TYPE,
                i_diag_ep_type IN OUT pk_edis_types.rec_in_epis_diagnosis
            ) IS
            
            BEGIN
                SELECT d.id_diagnosis,
                       ad.id_alert_diagnosis,
                       ed.desc_epis_diagnosis,
                       'D',
                       ed.flg_final_type,
                       ed.flg_status,
                       ed.flg_add_problem,
                       ed.notes,
                       ed.id_diagnosis_condition,
                       ed.id_sub_analysis,
                       ed.id_anatomical_area,
                       ed.id_anatomical_side,
                       ed.id_lesion_location,
                       ed.id_lesion_type,
                       ed.dt_initial_diag,
                       ed.id_diag_basis,
                       ed.diag_basis_spec,
                       ed.flg_recurrence,
                       ed.flg_mult_tumors,
                       ed.num_primary_tumors
                  INTO i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diagnosis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_alert_diagnosis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).desc_diagnosis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_diag_type,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_final_type,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_status,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_add_problem,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).notes,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diagnosis_condition,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_sub_analysis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_anatomical_area,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_anatomical_side,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_lesion_location,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_lesion_type,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).dt_initial_diag,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diag_basis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).diag_basis_spec,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_recurrence,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_mult_tumors,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).num_primary_tumors
                  FROM diagnosis d
                  JOIN alert_diagnosis ad
                    ON ad.id_diagnosis = d.id_diagnosis
                  JOIN epis_diagnosis ed
                    ON ed.id_diagnosis = d.id_diagnosis
                   AND ed.id_episode = i_id_episode
                   AND ed.id_alert_diagnosis = ad.id_alert_diagnosis
                 WHERE d.id_diagnosis = i_id_diag
                   AND ed.flg_status != pk_diagnosis.g_epis_status_c
                   AND rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                
                    SELECT d.id_diagnosis,
                           ad.id_alert_diagnosis,
                           ed.desc_epis_diagnosis,
                           'D',
                           ed.flg_final_type,
                           ed.flg_status,
                           ed.flg_add_problem,
                           ed.notes,
                           ed.id_diagnosis_condition,
                           ed.id_sub_analysis,
                           ed.id_anatomical_area,
                           ed.id_anatomical_side,
                           ed.id_lesion_location,
                           ed.id_lesion_type,
                           ed.dt_initial_diag,
                           ed.id_diag_basis,
                           ed.diag_basis_spec,
                           ed.flg_recurrence,
                           ed.flg_mult_tumors,
                           ed.num_primary_tumors
                      INTO i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diagnosis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_alert_diagnosis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).desc_diagnosis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_diag_type,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_final_type,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_status,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_add_problem,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).notes,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diagnosis_condition,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_sub_analysis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_anatomical_area,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_anatomical_side,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_lesion_location,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_lesion_type,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).dt_initial_diag,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diag_basis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).diag_basis_spec,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_recurrence,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_mult_tumors,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).num_primary_tumors
                      FROM diagnosis d
                      JOIN alert_diagnosis ad
                        ON ad.id_diagnosis = d.id_diagnosis
                      JOIN epis_diagnosis ed
                        ON ed.id_diagnosis = d.id_diagnosis
                       AND ed.id_episode IN (SELECT e.id_episode
                                               FROM episode e
                                              WHERE e.id_patient IN (SELECT e.id_patient
                                                                       FROM episode e
                                                                      WHERE e.id_episode = i_id_episode)
                                                AND e.id_epis_type = 5)
                     WHERE d.id_diagnosis = i_id_diag
                       AND ed.flg_status != pk_diagnosis.g_epis_status_c
                       AND rownum = 1
                     ORDER BY dt_initial_diag DESC;
                
            END set_diag_info;
        
        BEGIN
        
            --Obtain the diagnosis inserted on the form
            IF i_ri_diagnosis IS NOT NULL
            THEN
                i_diag_epis_type := pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                              i_prof   => i_prof,
                                                              i_params => i_ri_diagnosis);
            
                --Obtain the diagnosis from the episode    
                SELECT pk_string_utils.str_split(i_id_diag_prev) COLLECT
                  INTO l_tbl_diag
                  FROM dual;
            
                FOR i IN i_diag_epis_type.tbl_diagnosis.first .. i_diag_epis_type.tbl_diagnosis.last
                LOOP
                    l_diags_form.extend();
                    l_diags_form(i) := i_diag_epis_type.tbl_diagnosis(i).id_diagnosis;
                
                END LOOP;
            
                --Check if the diagnosis from the episode were also inserted in the form
                FOR i IN 1 .. l_tbl_diag.count()
                LOOP
                
                    l_count_diag := 0;
                
                    SELECT COUNT(1)
                      INTO l_count_diag
                      FROM dual
                     WHERE to_number(l_tbl_diag(i)) IN (SELECT *
                                                          FROM TABLE(l_diags_form));
                
                    IF l_count_diag = 0
                    THEN
                    
                        i_diag_epis_type.tbl_diagnosis.extend();
                        set_diag_info(i_id_diag => l_tbl_diag(i), i_diag_ep_type => i_diag_epis_type);
                    
                    END IF;
                END LOOP;
            
            ELSE
                --IF THERE IS NO DIAGNOSIS DOCUMENTED ON THE FORM            
                SELECT pk_string_utils.str_split(i_id_diag_prev) COLLECT
                  INTO l_tbl_diag
                  FROM dual;
            
                i_diag_epis_type.tbl_diagnosis := pk_edis_types.table_in_diagnosis();
            
                FOR i IN 1 .. l_tbl_diag.count()
                LOOP
                
                    i_diag_epis_type.tbl_diagnosis.extend();
                    set_diag_info(i_id_diag => l_tbl_diag(i), i_diag_ep_type => i_diag_epis_type);
                
                END LOOP;
            END IF;
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END get_previous_diagnosis;
    
    BEGIN
        l_p := xmlparser.newparser;
        xmlparser.parsebuffer(l_p, i_data);
        l_doc := xmlparser.getdocument(l_p);
    
        l_nl   := xmldom.getelementsbytagname(l_doc, '*');
        l_nlen := xmldom.getlength(l_nl);
    
        r_tbl_prof         := table_number();
        r_tbl_catg         := table_number();
        r_tbl_status       := table_varchar();
        l_tbl_sr_proc_diag := table_clob();
    
        r_clinical_question       := table_number();
        r_response                := table_varchar();
        r_clinical_question_notes := table_clob();
    
        l_tbl_supply      := table_number();
        l_tbl_supply_qty  := table_number();
        l_tbl_supply_soft := table_number();
        l_tbl_supply_loc  := table_number();
        l_tbl_supply_set  := table_number();
        l_tbl_supply_dtr  := table_varchar();
        l_tbl_supply_fct  := table_varchar();
        l_tbl_supply_not  := table_varchar();
        l_tbl_supply_irr  := table_number();
    
        FOR j IN 0 .. l_nlen - 1
        LOOP
        
            l_n := xmldom.item(l_nl, j); -- define node
        
            parent_node := xmldom.getparentnode(l_n);
            teste       := xmldom.getnodename(parent_node);
            IF xmldom.getnodename(parent_node) = g_xml_additional_info
            THEN
            
                IF xmldom.getnodename(l_n) = g_xml_component_leaf
                THEN
                
                    l_e := xmldom.makeelement(l_n);
                    CASE xmldom.getattribute(l_e, g_xml_internal_name)
                        WHEN pk_admission_request.g_ri_diagnoses THEN
                        
                            childnodes := xmldom.getchildnodes(l_n);
                            n          := dbms_xmldom.item(childnodes, 0);
                            dbms_lob.createtemporary(l_ri_diagnoses, TRUE);
                            dbms_xmldom.writetoclob(n, l_ri_diagnoses);
                        WHEN pk_admission_request.g_rs_cont_danger THEN
                            childnodes := xmldom.getchildnodes(l_n);
                            n          := dbms_xmldom.item(childnodes, 0);
                            dbms_lob.createtemporary(l_rs_cont_danger, TRUE);
                            dbms_xmldom.writetoclob(n, l_rs_cont_danger);
                        
                        WHEN pk_admission_request.g_rs_proc_surg THEN
                            l_sr_proc_notes        := xmldom.getattribute(l_e, 'FIELD_NOTES');
                            l_sr_proc_team         := xmldom.getattribute(l_e, 'FIELD_SURGERY_TEAM');
                            l_sr_proc_diag         := xmldom.getattribute(l_e, 'FIELD_ASSOC_DIAG');
                            l_sr_proc_type         := xmldom.getattribute(l_e, 'FIELD_SURGERY_TYPE');
                            l_sr_proc_value        := xmldom.getattribute(l_e, g_xml_value);
                            l_sr_proc_codification := xmldom.getattribute(l_e, 'FIELD_CODIFICATION');
                            l_sr_proc_laterality   := xmldom.getattribute(l_e, 'FIELD_LATERALITY');
                            l_sr_proc_ss           := xmldom.getattribute(l_e, 'FIELD_SURGICAL_SITE');
                        
                            tbl_sr_proc_value.extend();
                            tbl_sr_proc_value(tbl_sr_proc_value.count) := l_sr_proc_value;
                        
                            tbl_sr_proc_type.extend();
                            tbl_sr_proc_type(tbl_sr_proc_type.count) := l_sr_proc_type;
                        
                            tbl_sr_proc_codification.extend();
                            tbl_sr_proc_codification(tbl_sr_proc_codification.count()) := l_sr_proc_codification;
                        
                            tbl_sr_proc_laterality.extend();
                            tbl_sr_proc_laterality(tbl_sr_proc_laterality.count()) := l_sr_proc_laterality;
                        
                            tbl_sr_proc_ss.extend();
                            tbl_sr_proc_ss(tbl_sr_proc_ss.count()) := l_sr_proc_ss;
                        
                            tbl_sr_proc_notes.extend();
                            tbl_sr_proc_notes(tbl_sr_proc_notes.count) := l_sr_proc_notes;
                        
                            tbl_sr_proc_team.extend();
                            tbl_sr_proc_team(tbl_sr_proc_team.count) := l_sr_proc_team;
                        
                            tbl_sr_epis_interv.extend();
                            tbl_sr_epis_interv(tbl_sr_epis_interv.count) := NULL;
                        
                            tbl_description_sp.extend();
                            tbl_description_sp(tbl_description_sp.count) := NULL;
                        
                            tbl_ct_io.extend();
                            tbl_ct_io(tbl_ct_io.count) := table_varchar(NULL);
                        
                            tbl_surgery_record.extend();
                            tbl_surgery_record(tbl_surgery_record.count) := NULL;
                        
                            childnodes := xmldom.getchildnodes(l_n);
                        
                            len := dbms_xmldom.getlength(childnodes);
                        
                            FOR i IN 0 .. len - 1
                            LOOP
                            
                                n           := dbms_xmldom.item(childnodes, i);
                                teste       := xmldom.getnodename(n);
                                childnodes1 := dbms_xmldom.getchildnodes(n);
                                len1        := xmldom.getlength(childnodes1);
                                l_e1        := xmldom.makeelement(n);
                            
                                CASE xmldom.getnodename(n)
                                    WHEN 'PROCEDURE_SUPPLIES' THEN
                                        FOR j IN 0 .. len1 - 1
                                        LOOP
                                        
                                            n1               := dbms_xmldom.item(childnodes1, j);
                                            l_e              := xmldom.makeelement(n1);
                                            l_bl_supply      := xmldom.getattribute(l_e, 'ID_SUPPLY');
                                            l_bl_supply_qty  := xmldom.getattribute(l_e, 'QUANTITY');
                                            l_bl_supply_soft := xmldom.getattribute(l_e, 'ID_SOFT_INST');
                                            l_bl_supply_fct  := xmldom.getattribute(l_e, 'FLG_CONS_TYPE');
                                            l_bl_supply_set  := xmldom.getattribute(l_e, 'ID_PARENT_SUPPLY');
                                            l_bl_supply_dtr  := xmldom.getattribute(l_e, 'DT_RETURN');
                                            l_bl_supply_loc  := xmldom.getattribute(l_e, 'LOCATION');
                                            l_bl_supply_not  := xmldom.getattribute(l_e, 'NOTES');
                                            l_bl_supply_irr  := xmldom.getattribute(l_e, 'REASON');
                                        
                                            len_tbl := l_tbl_supply.count;
                                            l_tbl_supply.extend;
                                            l_tbl_supply_qty.extend;
                                            l_tbl_supply_soft.extend;
                                            l_tbl_supply_loc.extend;
                                            l_tbl_supply_set.extend;
                                            l_tbl_supply_dtr.extend;
                                            l_tbl_supply_fct.extend;
                                            l_tbl_supply_not.extend;
                                            l_tbl_supply_irr.extend;
                                            l_tbl_supply(len_tbl + 1) := l_bl_supply;
                                            l_tbl_supply_qty(len_tbl + 1) := l_bl_supply_qty;
                                            l_tbl_supply_soft(len_tbl + 1) := l_bl_supply_soft;
                                            l_tbl_supply_loc(len_tbl + 1) := l_bl_supply_loc;
                                            l_tbl_supply_set(len_tbl + 1) := l_bl_supply_set;
                                            l_tbl_supply_dtr(len_tbl + 1) := l_bl_supply_dtr;
                                            l_tbl_supply_fct(len_tbl + 1) := l_bl_supply_fct;
                                            l_tbl_supply_not(len_tbl + 1) := l_bl_supply_not;
                                            l_tbl_supply_irr(len_tbl + 1) := l_bl_supply_irr;
                                        END LOOP;
                                    
                                    WHEN 'PROCEDURE_TEAM' THEN
                                        FOR j IN 0 .. len1 - 1
                                        LOOP
                                        
                                            n1            := dbms_xmldom.item(childnodes1, j);
                                            l_e           := xmldom.makeelement(n1);
                                            teste         := dbms_xmldom.getnodename(n1);
                                            l_team_status := xmldom.getattribute(l_e, 'STATUS');
                                            l_team_task   := xmldom.getattribute(l_e, 'TASK');
                                            l_team_id     := xmldom.getattribute(l_e, 'ID');
                                        
                                            len_tbl := r_tbl_prof.count;
                                            r_tbl_prof.extend;
                                        
                                            r_tbl_catg.extend;
                                        
                                            r_tbl_status.extend;
                                        
                                            r_tbl_prof(len_tbl + 1) := l_team_id;
                                            r_tbl_catg(len_tbl + 1) := l_team_task;
                                            r_tbl_status(len_tbl + 1) := l_team_status;
                                        
                                        END LOOP;
                                    
                                    WHEN 'PROCEDURE_DIAG' THEN
                                        dbms_lob.createtemporary(l_sr_proc_diagnoses, TRUE);
                                        dbms_xmldom.writetoclob(dbms_xmldom.item(childnodes1, 0), l_sr_proc_diagnoses);
                                    
                                        len_tb_d := l_tbl_sr_proc_diag.count;
                                        l_tbl_sr_proc_diag.extend;
                                        l_tbl_sr_proc_diag(len_tb_d + 1) := l_sr_proc_diagnoses;
                                    
                                    WHEN 'CLINICAL_QUESTIONS' THEN
                                    
                                        IF len1 > 0
                                        THEN
                                            r_clinical_question_notes := table_clob();
                                            r_response                := table_varchar();
                                            r_clinical_question       := table_number();
                                            FOR j IN 0 .. len1 - 1
                                            LOOP
                                            
                                                n1                        := dbms_xmldom.item(childnodes1, j);
                                                l_e                       := xmldom.makeelement(n1);
                                                teste                     := dbms_xmldom.getnodename(n1);
                                                v_clinical_question_notes := xmldom.getattribute(l_e, 'NOTES');
                                                v_response                := xmldom.getattribute(l_e, 'RESPONSE');
                                                v_clinical_question       := xmldom.getattribute(l_e, 'ID_QUESTION');
                                            
                                                --r_clinical_question_notes := table_varchar();
                                                len_tbl := r_clinical_question_notes.count;
                                                r_clinical_question_notes.extend;
                                                --r_response := table_varchar();
                                                r_response.extend;
                                                --r_clinical_question := table_number();
                                                r_clinical_question.extend;
                                            
                                                r_clinical_question_notes(len_tbl + 1) := v_clinical_question_notes;
                                                r_response(len_tbl + 1) := v_response;
                                                r_clinical_question(len_tbl + 1) := v_clinical_question;
                                            
                                            END LOOP;
                                        
                                            len_ttbl := l_clinical_question.count;
                                            l_clinical_question.extend;
                                            l_clinical_question(len_ttbl + 1) := r_clinical_question;
                                            l_response.extend;
                                            l_response(len_ttbl + 1) := r_response;
                                            l_clinical_question_notes.extend;
                                            l_clinical_question_notes(len_ttbl + 1) := r_clinical_question_notes;
                                        ELSE
                                            len_ttbl := l_clinical_question.count;
                                            l_clinical_question.extend;
                                            l_clinical_question(len_ttbl + 1) := table_number();
                                            l_response.extend;
                                            l_response(len_ttbl + 1) := table_varchar();
                                            l_clinical_question_notes.extend;
                                            l_clinical_question_notes(len_ttbl + 1) := table_clob();
                                        END IF;
                                    
                                    ELSE
                                        NULL;
                                END CASE;
                            END LOOP;
                        
                            len_ttbl := l_tbl_prof.count;
                            l_tbl_prof.extend;
                            l_tbl_prof(len_ttbl + 1) := r_tbl_prof;
                            l_tbl_catg.extend;
                            l_tbl_catg(len_ttbl + 1) := r_tbl_catg;
                            l_tbl_status.extend;
                            l_tbl_status(len_ttbl + 1) := r_tbl_status;
                        
                            len_ttbl := l_ttbl_supply.count;
                            l_ttbl_supply.extend;
                            l_ttbl_supply_qty.extend;
                            l_ttbl_supply_soft.extend;
                            l_ttbl_supply_loc.extend;
                            l_ttbl_supply_set.extend;
                            l_ttbl_supply_dtr.extend;
                            l_ttbl_supply_fct.extend;
                            l_ttbl_supply_not.extend;
                            l_ttbl_supply_irr.extend;
                            l_ttbl_supply(len_ttbl + 1) := l_tbl_supply;
                            l_ttbl_supply_qty(len_ttbl + 1) := l_tbl_supply_qty;
                            l_ttbl_supply_soft(len_ttbl + 1) := l_tbl_supply_soft;
                            l_ttbl_supply_loc(len_ttbl + 1) := l_tbl_supply_loc;
                            l_ttbl_supply_set(len_ttbl + 1) := l_tbl_supply_set;
                            l_ttbl_supply_dtr(len_ttbl + 1) := l_tbl_supply_dtr;
                            l_ttbl_supply_fct(len_ttbl + 1) := l_tbl_supply_fct;
                            l_ttbl_supply_not(len_ttbl + 1) := l_tbl_supply_not;
                            l_ttbl_supply_irr(len_ttbl + 1) := l_tbl_supply_irr;
                        
                        ELSE
                            NULL;
                    END CASE;
                ELSIF xmldom.getnodename(l_n) = g_xml_epis_diagnoses
                THEN
                
                    dbms_lob.createtemporary(l_ri_diagnoses, TRUE);
                    dbms_xmldom.writetoclob(l_n, l_ri_diagnoses);
                END IF;
            
            ELSIF xmldom.getnodename(l_n) = g_xml_component_leaf
            THEN
            
                l_e := xmldom.makeelement(l_n);
                CASE
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_diagnoses THEN
                        l_id_diagnosis_prev := xmldom.getattribute(l_e, g_xml_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_reason_admission THEN
                        l_ri_reason_admission   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_reason_admission_l := xmldom.getattribute(l_e, g_xml_alt_value);
                        IF l_ri_reason_admission = pk_admission_request.g_reason_admission_ft
                        THEN
                            l_ri_reason_admission_desc := pk_string_utils.str_split(i_list  => xmldom.getattribute(l_e,
                                                                                                                   'DESC_VALUE'),
                                                                                    i_delim => '(') (1);
                        END IF;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_sur_need THEN
                        l_rs_sur_need   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_sur_need_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_loc_int THEN
                        l_ri_loc_int   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_loc_int_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_serv_adm THEN
                        l_ri_serv_adm   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_serv_adm_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_esp_int THEN
                        l_ri_esp_int   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_esp_int_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RI_PROF_SPECIALITY' THEN
                        l_ri_prof_spec := xmldom.getattribute(l_e, g_xml_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_phys_adm THEN
                        l_ri_phys_adm   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_phys_adm_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_type_int THEN
                        l_rs_type_int   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_type_int_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RI_COMPULSORY' THEN
                        l_ri_compulsory   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_compulsory_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RI_COMPULSORY_REASON' THEN
                        BEGIN
                            l_ri_compulsory_id := xmldom.getattribute(l_e, g_xml_value);
                        EXCEPTION
                            WHEN OTHERS THEN
                                l_ri_compulsory_id := -1;
                        END;
                    
                        CASE l_ri_compulsory_id
                            WHEN -1 THEN
                                l_ri_compulsory_desc := xmldom.getattribute(l_e, g_xml_desc_value);
                            ELSE
                                l_ri_compulsory_desc := NULL;
                        END CASE;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_durantion THEN
                        l_ri_durantion   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_durantion_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                        CASE l_ri_durantion_l
                            WHEN 1039 THEN
                                l_ri_durantion := l_ri_durantion * 24;
                            WHEN 10375 THEN
                                l_ri_durantion := l_ri_durantion * 24 * 7;
                            WHEN 10373 THEN
                                l_ri_durantion := l_ri_durantion * 24 * 365;
                            ELSE
                                l_ri_durantion := l_ri_durantion;
                        END CASE;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_prepar THEN
                        l_ri_prepar   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_prepar_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_type_room THEN
                        l_ri_type_room   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_type_room_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_regimen THEN
                        l_ri_regimen   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_regimen_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_beneficiario THEN
                        l_ri_beneficiario   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_beneficiario_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_precauciones THEN
                        l_ri_precauciones   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_precauciones_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_contactado THEN
                        l_ri_contactado   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_contactado_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_mix_room THEN
                        l_ri_mix_room   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_mix_room_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_type_bed THEN
                        l_rs_type_bed   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_type_bed_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_pref_room THEN
                        l_ri_pref_room   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_pref_room_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_need_nurse_cons THEN
                        l_ri_need_nurse_cons   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_need_nurse_cons_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_loc_nurse_cons THEN
                        l_ri_loc_nurse_cons   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_loc_nurse_cons_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_date_nurse_cons THEN
                        l_ri_date_nurse_cons   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_date_nurse_cons_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_ri_notes THEN
                        l_ri_notes   := xmldom.getattribute(l_e, g_xml_value);
                        l_ri_notes_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_loc_surgery THEN
                        l_rs_loc_surgery   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_loc_surgery_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_spec_surgery THEN
                        l_rs_spec_surgery   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_spec_surgery_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_DEPARTMENT' THEN
                        l_rs_department := xmldom.getattribute(l_e, g_xml_value);
                        --                        l_rs_spec_surgery_l := xmldom.getattribute(l_e, g_xml_alt_value);
                
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_CLIN_SERVICE' THEN
                        l_rs_clin_service := xmldom.getattribute(l_e, g_xml_value);
                        -- l_rs_spec_surgery_l := xmldom.getattribute(l_e, g_xml_alt_value);
                
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_global_anesth THEN
                        l_rs_glb_anesth   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_glb_anesth_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_local_anesth THEN
                        l_rs_lcl_anesth   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_lcl_anesth_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_pref_surg THEN
                        l_rs_pref_surg := xmldom.getattribute(l_e, g_xml_value);
                    
                        tbl_pref_surgeons.extend;
                        tbl_pref_surgeons(1) := l_rs_pref_surg;
                    
                        childnodes := xmldom.getchildnodes(l_n);
                    
                        len := dbms_xmldom.getlength(childnodes);
                    
                        FOR i IN 0 .. len - 1
                        LOOP
                        
                            n              := dbms_xmldom.item(childnodes, i);
                            l_e1           := xmldom.makeelement(n);
                            l_rs_pref_surg := xmldom.getattribute(l_e1, g_xml_value);
                        
                            tbl_pref_surgeons.extend;
                            tbl_pref_surgeons(i + 2) := l_rs_pref_surg;
                        
                        END LOOP;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_proc_surg THEN
                        l_rs_proc_surg   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_proc_surg_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_prev_duration THEN
                        l_rs_prev_duration   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_prev_duration_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                        CASE l_rs_prev_duration_l
                            WHEN 1039 THEN
                                --Day
                                l_rs_prev_duration := l_rs_prev_duration * 24 * 60;
                            WHEN 10374 THEN
                                l_rs_prev_duration := l_rs_prev_duration;
                            ELSE
                                l_rs_prev_duration := l_rs_prev_duration * 60;
                        END CASE;
                    
                        l_rs_prev_duration_l := pk_sr_planning.g_unit_measure_hours;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_uci THEN
                        l_rs_uci   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_uci_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_UCI_POS' THEN
                        l_rs_uci_pos   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_uci_pos_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_ext_spec THEN
                        l_rs_ext_spec := xmldom.getattribute(l_e, g_xml_value);
                    
                        tbl_ext_serv.extend;
                        tbl_ext_serv(1) := l_rs_ext_spec;
                    
                        childnodes := xmldom.getchildnodes(l_n);
                    
                        len := dbms_xmldom.getlength(childnodes);
                    
                        FOR i IN 0 .. len - 1
                        LOOP
                        
                            n             := dbms_xmldom.item(childnodes, i);
                            l_e1          := xmldom.makeelement(n);
                            l_rs_ext_spec := xmldom.getattribute(l_e1, g_xml_value);
                        
                            tbl_ext_serv.extend;
                            tbl_ext_serv(i + 2) := l_rs_ext_spec;
                        
                        END LOOP;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_cont_danger THEN
                        l_rs_cont_danger_prev := xmldom.getattribute(l_e, g_xml_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_pref_time THEN
                        l_rs_pref_time := xmldom.getattribute(l_e, g_xml_value);
                    
                        tbl_pref_time.extend;
                        IF pk_utils.is_number(char_in => l_rs_pref_time) = pk_alert_constant.g_yes
                        THEN
                            tbl_pref_time(1) := get_value_from_time_pref(l_rs_pref_time);
                        ELSE
                            tbl_pref_time(1) := l_rs_pref_time;
                        END IF;
                    
                        childnodes := xmldom.getchildnodes(l_n);
                    
                        len := dbms_xmldom.getlength(childnodes);
                    
                        FOR i IN 0 .. len - 1
                        LOOP
                        
                            n              := dbms_xmldom.item(childnodes, i);
                            l_e1           := xmldom.makeelement(n);
                            l_rs_pref_time := xmldom.getattribute(l_e1, g_xml_value);
                        
                            tbl_pref_time.extend;
                            IF pk_utils.is_number(char_in => l_rs_pref_time) = pk_alert_constant.g_yes
                            THEN
                                tbl_pref_time(i + 2) := get_value_from_time_pref(l_rs_pref_time);
                            ELSE
                                tbl_pref_time(i + 2) := l_rs_pref_time;
                            END IF;
                        
                        --l_rs_pref_time := get_value_from_time_pref(xmldom.getattribute(l_e1, g_xml_value));
                        
                        END LOOP;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_mot_pref_time THEN
                        l_rs_mot_pref_time   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_mot_pref_time_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rs_notes THEN
                        l_rs_notes   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_notes_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rv_request THEN
                        l_rv_request   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_request_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rv_dt_verif THEN
                        l_rv_dt_verif   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_dt_verif_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rv_notes_req THEN
                        l_rv_notes_req   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_notes_req_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rv_decision THEN
                        l_rv_decision   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_decision_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rv_valid THEN
                        l_rv_valid   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_valid_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rv_notes_decis THEN
                        l_rv_notes_decis   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_notes_decis_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rsp_lvl_urg THEN
                        l_rsp_lvl_urg   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_lvl_urg_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rsp_begin_sched THEN
                        l_rsp_begin_sched   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_begin_sched_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rsp_end_sched THEN
                        l_rsp_end_sched   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_end_sched_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rsp_time_min THEN
                        l_rsp_time_min   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_time_min_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                        IF l_rsp_time_min_l = 10373 --YEAR
                        THEN
                        
                            l_rsp_time_min   := l_rsp_time_min * 365;
                            l_rsp_time_min_l := 1039;
                        
                        ELSIF l_rsp_time_min_l = 1127 --MONTH
                        THEN
                        
                            l_rsp_time_min   := l_rsp_time_min * 30;
                            l_rsp_time_min_l := 1039;
                        
                        ELSIF l_rsp_time_min_l = 10375 --WEEK
                        THEN
                        
                            l_rsp_time_min   := l_rsp_time_min * 7;
                            l_rsp_time_min_l := 1039;
                        
                        END IF;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rsp_sugg_dt_surg THEN
                        l_rsp_sugg_dt_surg   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_sugg_dt_surg_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = pk_admission_request.g_rsp_sugg_dt_int THEN
                        l_rsp_sugg_dt_int   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_sugg_dt_int_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) LIKE 'RIP_BEGIN_PER%' THEN
                        l_rip_begin_per   := xmldom.getattribute(l_e, g_xml_value);
                        l_rip_begin_per_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                        tbl_rip_begin.extend;
                        tbl_rip_begin(tbl_rip_begin.count) := l_rip_begin_per;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) LIKE 'RIP_END_PER%' THEN
                        l_rip_end_per   := xmldom.getattribute(l_e, g_xml_value);
                        l_rip_end_per_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                        tbl_rip_end.extend;
                        tbl_rip_end(tbl_rip_begin.count) := l_rip_end_per;
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) LIKE 'RC_TYPE%' THEN
                        l_cs_type := xmldom.getattribute(l_e, g_xml_value);
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) LIKE 'RC_BY%' THEN
                        l_cs_prof_id := xmldom.getattribute(l_e, g_xml_value);
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) LIKE 'RC_AT%' THEN
                        l_cs_date := xmldom.getattribute(l_e, g_xml_value);
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) LIKE 'RI_MRP%' THEN
                        l_id_mrp := xmldom.getattribute(l_e, g_xml_value);
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) LIKE 'RI_WRITTEN_BY%' THEN
                        l_id_written_by := xmldom.getattribute(l_e, g_xml_value);
                    ELSE
                        NULL;
                END CASE;
            END IF;
        
            --Different procedures may have different teams.        
            r_tbl_prof   := table_number();
            r_tbl_catg   := table_number();
            r_tbl_status := table_varchar();
        
        END LOOP;
    
        IF l_id_diagnosis_prev IS NOT NULL
        THEN
            IF NOT get_previous_diagnosis(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_ri_diagnosis   => nvl(l_ri_diagnoses, l_ri_diagnoses_l),
                                          i_id_diag_prev   => l_id_diagnosis_prev,
                                          i_diag_epis_type => l_diag_epis_type)
            THEN
                g_error := 'CALL PK_WTL_API_UI.SET_ADM_SURG_REQUEST';
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
            END IF;
        END IF;
    
        IF l_rs_cont_danger_prev IS NOT NULL
        THEN
            IF NOT get_previous_diagnosis(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_ri_diagnosis   => nvl(l_rs_cont_danger, l_rs_cont_danger_l),
                                          i_id_diag_prev   => l_rs_cont_danger_prev,
                                          i_diag_epis_type => l_diag_epis_type_cont)
            THEN
                g_error := 'CALL PK_WTL_API_UI.SET_ADM_SURG_REQUEST';
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
            END IF;
        END IF;
    
        IF io_id_waiting_list IS NOT NULL
        THEN
        
            BEGIN
                SELECT wtle.id_episode
                  INTO io_id_episode_sr
                  FROM wtl_epis wtle
                 WHERE wtle.id_waiting_list = io_id_waiting_list
                   AND wtle.id_epis_type = l_epis_type_sr;
            EXCEPTION
                WHEN no_data_found THEN
                    io_id_episode_sr := NULL;
            END;
        
            IF io_id_episode_sr IS NOT NULL
            THEN
                SELECT sei.id_sr_epis_interv, sei.id_sr_intervention
                  BULK COLLECT
                  INTO tbl_sr_epis_interv_int, tbl_sr_intervention
                  FROM sr_epis_interv sei
                 WHERE sei.id_episode_context = io_id_episode_sr;
            
                --tbl_sr_proc_value
                tbl_sr_epis_interv := table_number();
                FOR i IN 1 .. tbl_sr_proc_value.count
                LOOP
                    tbl_sr_epis_interv.extend;
                    idx := pk_utils.search_table_number(i_table  => tbl_sr_intervention,
                                                        i_search => tbl_sr_proc_value(i));
                    IF idx > 0
                    THEN
                        tbl_sr_epis_interv(i) := tbl_sr_epis_interv_int(idx);
                    ELSE
                        tbl_sr_epis_interv(i) := NULL;
                    END IF;
                END LOOP;
            END IF;
        
            BEGIN
                SELECT wtle.id_episode
                  INTO io_id_episode_inp
                  FROM wtl_epis wtle
                 WHERE wtle.id_waiting_list = io_id_waiting_list
                   AND wtle.id_epis_type = l_epis_type_inp;
            EXCEPTION
                WHEN no_data_found THEN
                    io_id_episode_inp := NULL;
            END;
        END IF;
    
        IF NOT pk_wtl_pbl_core.set_adm_surg_request(i_lang                    => i_lang,
                                               i_prof                    => i_prof,
                                               i_id_patient              => i_id_patient,
                                               i_id_episode              => i_id_episode,
                                               io_id_episode_sr          => io_id_episode_sr,
                                               io_id_episode_inp         => io_id_episode_inp,
                                               io_id_waiting_list        => io_id_waiting_list,
                                               i_flg_type                => CASE
                                                                                WHEN l_rs_sur_need_l = pk_alert_constant.g_yes THEN
                                                                                 'A'
                                                                                ELSE
                                                                                 'B'
                                                                            END,
                                               i_id_wtl_urg_level        => nvl(l_rsp_lvl_urg, l_rsp_lvl_urg_l),
                                               i_dt_sched_period_start   => nvl(l_rsp_begin_sched, l_rsp_begin_sched_l),
                                               i_dt_sched_period_end     => nvl(l_rsp_end_sched, l_rsp_end_sched_l),
                                               i_min_inform_time         => l_rsp_time_min,
                                               i_dt_surgery              => nvl(l_rsp_sugg_dt_surg, l_rsp_sugg_dt_surg_l),
                                               i_unav_period_start       => tbl_rip_begin,
                                               i_unav_period_end         => tbl_rip_end,
                                               i_pref_surgeons           => tbl_pref_surgeons,
                                               i_external_dcs            => tbl_ext_serv,
                                               i_dep_clin_serv_sr        => table_number(l_rs_clin_service),
                                               i_speciality_sr           => table_number(l_rs_spec_surgery),
                                               i_department_sr           => table_number(l_rs_department),
                                               i_flg_pref_time           => tbl_pref_time,
                                               i_reason_pref_time        => table_number(nvl(l_rs_mot_pref_time,
                                                                                             l_rs_mot_pref_time_l)),
                                               i_id_sr_intervention      => tbl_sr_proc_value,
                                               i_flg_principal           => tbl_sr_proc_type,
                                               i_codification            => tbl_sr_proc_codification,
                                               i_flg_laterality          => tbl_sr_proc_laterality,
                                               i_surgical_site           => tbl_sr_proc_ss,
                                               i_sp_notes                => tbl_sr_proc_notes,
                                               i_duration                => l_rs_prev_duration,
                                               i_icu                     => l_rs_uci_l,
                                               i_icu_pos                 => l_rs_uci_pos_l,
                                               i_notes_surg              => nvl(l_rs_notes, l_rs_notes_l),
                                               i_adm_needed              => 'Y',
                                               i_id_sr_pos_status        => NULL,
                                               i_surg_needed             => nvl(l_rs_sur_need, l_rs_sur_need_l),
                                               i_adm_indication          => nvl(l_ri_reason_admission, l_ri_reason_admission_l),
                                               i_adm_ind_desc            => l_ri_reason_admission_desc,
                                               i_dest_inst               => nvl(l_ri_loc_int, l_ri_loc_int_l),
                                               i_adm_type                => nvl(l_rs_type_int, l_rs_type_int_l),
                                               i_department              => nvl(l_ri_serv_adm, l_ri_serv_adm_l),
                                               i_room_type               => nvl(l_ri_type_room, l_ri_type_room_l),
                                               i_dep_clin_serv_adm       => nvl(l_ri_esp_int, l_ri_esp_int_l),
                                               i_pref_room               => nvl(l_ri_pref_room, l_ri_pref_room_l),
                                               i_mixed_nursing           => nvl(l_ri_mix_room, l_ri_mix_room_l),
                                               i_bed_type                => nvl(l_rs_type_bed, l_rs_type_bed_l),
                                               i_dest_prof               => CASE
                                                                                WHEN l_id_market = pk_alert_constant.g_id_market_sa THEN
                                                                                 l_id_mrp
                                                                                ELSE
                                                                                 l_ri_phys_adm
                                                                            END,
                                               i_adm_preparation         => nvl(l_ri_prepar, l_ri_prepar_l),
                                               i_dt_admission            => nvl(l_rsp_sugg_dt_int, l_rsp_sugg_dt_int_l),
                                               i_expect_duration         => nvl(l_ri_durantion, l_ri_durantion_l),
                                               i_notes_adm               => nvl(l_ri_notes, l_ri_notes_l),
                                               i_nit_flg                 => nvl(l_ri_need_nurse_cons, l_ri_need_nurse_cons_l),
                                               i_nit_dt_suggested        => nvl(l_ri_date_nurse_cons, l_ri_date_nurse_cons_l),
                                               i_nit_dcs                 => nvl(l_ri_loc_nurse_cons, l_ri_loc_nurse_cons_l),
                                               i_external_request        => NULL,
                                               i_func_eval_score         => NULL,
                                               i_notes_edit              => NULL,
                                               i_prof_cat_type           => 'D',
                                               i_doc_area                => NULL,
                                               i_doc_template            => NULL,
                                               i_epis_documentation      => NULL,
                                               i_doc_flg_type            => NULL,
                                               i_id_documentation        => NULL,
                                               i_id_doc_element          => NULL,
                                               i_id_doc_element_crit     => NULL,
                                               i_value                   => NULL,
                                               i_notes                   => NULL,
                                               i_id_doc_element_qualif   => NULL,
                                               i_epis_context            => NULL,
                                               i_summary_and_notes       => NULL,
                                               i_wtl_change              => 'N',
                                               i_profs_alert             => i_profs_alert,
                                               i_sr_pos_schedule         => NULL,
                                               i_dt_pos_suggested        => nvl(l_rv_dt_verif, l_rv_dt_verif_l),
                                               i_pos_req_notes           => nvl(l_rv_notes_req, l_rv_notes_req_l),
                                               i_decision_notes          => nvl(l_rv_notes_decis, l_rv_notes_decis_l),
                                               i_supply                  => l_ttbl_supply,
                                               i_supply_set              => l_ttbl_supply_set,
                                               i_supply_qty              => l_ttbl_supply_qty,
                                               i_supply_loc              => l_ttbl_supply_loc,
                                               i_dt_return               => l_ttbl_supply_dtr,
                                               i_supply_soft_inst        => l_ttbl_supply_soft,
                                               i_flg_cons_type           => l_ttbl_supply_fct,
                                               i_description_sp          => tbl_description_sp,
                                               i_id_sr_epis_interv       => tbl_sr_epis_interv,
                                               i_id_req_reason           => l_ttbl_supply_irr,
                                               i_supply_notes            => l_ttbl_supply_not,
                                               i_surgery_record          => tbl_surgery_record,
                                               i_prof_team               => tbl_sr_proc_team,
                                               i_tbl_prof                => l_tbl_prof,
                                               i_tbl_catg                => l_tbl_catg,
                                               i_tbl_status              => l_tbl_status,
                                               i_test                    => NULL,
                                               i_diagnosis_adm_req       => CASE
                                                                                WHEN l_id_diagnosis_prev IS NULL THEN
                                                                                 pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                           i_prof   => i_prof,
                                                                                                           i_params => nvl(l_ri_diagnoses,
                                                                                                                           l_ri_diagnoses_l))
                                                                                ELSE
                                                                                 l_diag_epis_type
                                                                            END,
                                               i_diagnosis_surg_proc     => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                      i_prof   => i_prof,
                                                                                                      i_params => l_tbl_sr_proc_diag),
                                               i_diagnosis_contam        => CASE
                                                                                WHEN l_rs_cont_danger_prev IS NULL THEN
                                                                                 pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                           i_prof   => i_prof,
                                                                                                           i_params => nvl(l_rs_cont_danger,
                                                                                                                           l_rs_cont_danger_l))
                                                                                ELSE
                                                                                 l_diag_epis_type_cont
                                                                            END,
                                               i_id_cdr_call             => NULL,
                                               i_id_ct_io                => tbl_ct_io,
                                               i_regimen                 => l_ri_regimen_l,
                                               i_beneficiario            => l_ri_beneficiario_l,
                                               i_precauciones            => l_ri_precauciones_l,
                                               i_contactado              => l_ri_contactado_l,
                                               i_clinical_question       => l_clinical_question,
                                               i_response                => l_response,
                                               i_clinical_question_notes => l_clinical_question_notes,
                                               i_id_inst_dest            => i_id_inst_dest,
                                               i_order_set               => i_order_set,
                                               i_global_anesth           => nvl(l_rs_glb_anesth, l_rs_glb_anesth_l),
                                               i_local_anesth            => nvl(l_rs_lcl_anesth, l_rs_lcl_anesth_l),
                                               i_id_mrp                  => CASE
                                                                                WHEN l_id_market = pk_alert_constant.g_id_market_sa THEN
                                                                                 l_ri_phys_adm
                                                                                ELSE
                                                                                 l_id_mrp
                                                                            END,
                                               i_id_written_by           => l_id_written_by,
                                               i_ri_prof_spec            => l_ri_prof_spec,
                                               i_flg_compulsory          => l_ri_compulsory,
                                               i_id_compulsory_reason    => l_ri_compulsory_id,
                                               i_compulsory_reason       => l_ri_compulsory_desc,
                                               o_adm_request             => o_adm_request,
                                               o_msg_error               => o_msg_error,
                                               o_title_error             => o_title_error,
                                               o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_cs_type IS NOT NULL
        THEN
            g_error := 'CALL PK_CO_SIGN_API.SET_PENDING_CO_SIGN_TASK';
            IF NOT pk_co_sign_api.set_pending_co_sign_task(i_lang                   => i_lang,
                                                           i_prof                   => i_prof,
                                                           i_episode                => i_id_episode,
                                                           i_id_co_sign             => NULL,
                                                           i_id_task_type           => 35,
                                                           i_cosign_def_action_type => pk_co_sign_api.g_cosign_action_def_add,
                                                           i_id_task                => o_adm_request,
                                                           i_id_task_group          => o_adm_request,
                                                           i_id_order_type          => l_cs_type,
                                                           i_id_prof_created        => i_prof.id,
                                                           i_id_prof_ordered_by     => l_cs_prof_id,
                                                           i_dt_created             => g_sysdate_tstz,
                                                           i_dt_ordered_by          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                     i_prof,
                                                                                                                     l_cs_date,
                                                                                                                     NULL),
                                                           o_id_co_sign             => l_id_co_sign,
                                                           o_id_co_sign_hist        => l_id_co_sign_hist,
                                                           o_error                  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        ts_adm_request.upd(id_adm_request_in   => o_adm_request,
                           id_co_sign_order_in => l_id_co_sign,
                           rows_out            => l_rows_upd);
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'ADM_REQUEST', l_rows_upd, o_error);
    
        COMMIT;
    
        RETURN TRUE;
    
    END set_adm_surg_request;

    FUNCTION set_adm_surg_request
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE, -- Current episode
        io_id_episode_sr  IN OUT episode.id_episode%TYPE, -- Surgical episode -- 5
        io_id_episode_inp IN OUT episode.id_episode%TYPE, -- Inpatient episode
        -- Waiting List / Common
        io_id_waiting_list      IN OUT waiting_list.id_waiting_list%TYPE,
        i_flg_type              IN waiting_list.flg_type%TYPE,
        i_id_wtl_urg_level      IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_dt_sched_period_start IN VARCHAR2, -- 10
        i_dt_sched_period_end   IN VARCHAR2,
        i_min_inform_time       IN waiting_list.min_inform_time%TYPE,
        i_dt_surgery            IN VARCHAR2,
        i_unav_period_start     IN table_varchar,
        i_unav_period_end       IN table_varchar, -- 15
        -- Surgery Request
        i_pref_surgeons      IN table_number,
        i_external_dcs       IN table_number,
        i_dep_clin_serv_sr   IN table_number,
        i_flg_pref_time      IN table_varchar,
        i_reason_pref_time   IN table_number, -- 20
        i_id_sr_intervention IN table_number,
        i_flg_principal      IN table_varchar,
        i_codification       IN table_number,
        i_flg_laterality     IN table_varchar,
        i_sp_notes           IN table_varchar, --25
        i_duration           IN schedule_sr.duration%TYPE,
        i_icu                IN schedule_sr.icu%TYPE,
        i_notes_surg         IN schedule_sr.notes%TYPE,
        i_adm_needed         IN schedule_sr.adm_needed%TYPE,
        i_id_sr_pos_status   IN sr_pos_status.id_sr_pos_status%TYPE, --30
        -- Admission Request
        i_surg_needed       IN VARCHAR2,
        i_adm_indication    IN adm_request.id_adm_indication%TYPE,
        i_dest_inst         IN adm_request.id_dest_inst%TYPE,
        i_adm_type          IN adm_request.id_admission_type%TYPE,
        i_department        IN adm_request.id_department%TYPE, --35
        i_room_type         IN adm_request.id_room_type%TYPE,
        i_dep_clin_serv_adm IN adm_request.id_dep_clin_serv%TYPE,
        i_pref_room         IN adm_request.id_pref_room%TYPE,
        i_mixed_nursing     IN adm_request.flg_mixed_nursing%TYPE,
        i_bed_type          IN adm_request.id_bed_type%TYPE, --40
        i_dest_prof         IN adm_request.id_dest_prof%TYPE,
        i_adm_preparation   IN adm_request.id_adm_preparation%TYPE,
        i_dt_admission      IN VARCHAR2,
        i_expect_duration   IN adm_request.expected_duration%TYPE,
        i_notes_adm         IN adm_request.notes%TYPE, --45
        i_nit_flg           IN adm_request.flg_nit%TYPE,
        i_nit_dt_suggested  IN VARCHAR2,
        i_nit_dcs           IN adm_request.id_nit_dcs%TYPE,
        i_external_request  IN p1_external_request.id_external_request%TYPE,
        i_func_eval_score   IN waiting_list.func_eval_score%TYPE DEFAULT NULL, --50
        i_notes_edit        IN waiting_list.notes_edit%TYPE DEFAULT NULL,
        --Barthel Index Template
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE, --55
        i_doc_flg_type          IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar, --60
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_wtl_change            IN VARCHAR2, --65
        i_profs_alert           IN table_number DEFAULT NULL,
        i_sr_pos_schedule       IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_dt_pos_suggested      IN VARCHAR2,
        i_pos_req_notes         IN sr_pos_schedule.req_notes%TYPE,
        --supplies
        i_supply           IN table_table_number, --70
        i_supply_set       IN table_table_number,
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number, --75
        i_flg_cons_type    IN table_table_varchar,
        --
        i_description_sp    IN table_varchar,
        i_id_sr_epis_interv IN table_number,
        i_id_req_reason     IN table_table_number,
        i_supply_notes      IN table_table_varchar, --80
        --Team
        i_surgery_record IN table_number,
        i_prof_team      IN table_number,
        i_tbl_prof       IN table_table_number,
        i_tbl_catg       IN table_table_number,
        i_tbl_status     IN table_table_varchar, --85
        i_test           IN VARCHAR2,
        --Diagnosis XMLs
        i_diagnosis_adm_req   IN CLOB,
        i_diagnosis_surg_proc IN table_clob,
        i_diagnosis_contam    IN CLOB,
        -- clinical decision rules
        i_id_cdr_call IN cdr_call.id_cdr_call%TYPE,
        i_id_ct_io    IN table_table_varchar, --90
        -- Error
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception   EXCEPTION;
        l_func_name   VARCHAR2(200) := 'SET_ADM_SURG_REQUEST';
        l_msg_error   VARCHAR2(200 CHAR);
        l_title_error VARCHAR2(200 CHAR);
        l_adm_request adm_request.id_adm_request%TYPE;
    
    BEGIN
    
        IF NOT pk_wtl_pbl_core.set_adm_surg_request(i_lang                  => i_lang,
                                                    i_prof                  => i_prof,
                                                    i_id_patient            => i_id_patient,
                                                    i_id_episode            => i_id_episode,
                                                    io_id_episode_sr        => io_id_episode_sr,
                                                    io_id_episode_inp       => io_id_episode_inp,
                                                    io_id_waiting_list      => io_id_waiting_list,
                                                    i_flg_type              => i_flg_type,
                                                    i_id_wtl_urg_level      => i_id_wtl_urg_level,
                                                    i_dt_sched_period_start => i_dt_sched_period_start,
                                                    i_dt_sched_period_end   => i_dt_sched_period_end,
                                                    i_min_inform_time       => i_min_inform_time,
                                                    i_dt_surgery            => i_dt_surgery,
                                                    i_unav_period_start     => i_unav_period_start,
                                                    i_unav_period_end       => i_unav_period_end,
                                                    i_pref_surgeons         => i_pref_surgeons,
                                                    i_external_dcs          => i_external_dcs,
                                                    i_dep_clin_serv_sr      => i_dep_clin_serv_sr,
                                                    i_speciality_sr         => NULL,
                                                    i_department_sr         => NULL,
                                                    i_flg_pref_time         => i_flg_pref_time,
                                                    i_reason_pref_time      => i_reason_pref_time,
                                                    i_id_sr_intervention    => i_id_sr_intervention,
                                                    i_flg_principal         => i_flg_principal,
                                                    i_codification          => i_codification,
                                                    i_flg_laterality        => i_flg_laterality,
                                                    i_surgical_site         => NULL,
                                                    i_sp_notes              => i_sp_notes,
                                                    i_duration              => i_duration,
                                                    i_icu                   => i_icu,
                                                    i_icu_pos               => NULL,
                                                    i_notes_surg            => i_notes_surg,
                                                    i_adm_needed            => i_adm_needed,
                                                    i_id_sr_pos_status      => i_id_sr_pos_status,
                                                    i_surg_needed           => i_surg_needed,
                                                    i_adm_indication        => i_adm_indication,
                                                    i_dest_inst             => i_dest_inst,
                                                    i_adm_type              => i_adm_type,
                                                    i_department            => i_department,
                                                    i_room_type             => i_room_type,
                                                    i_dep_clin_serv_adm     => i_dep_clin_serv_adm,
                                                    i_pref_room             => i_pref_room,
                                                    i_mixed_nursing         => i_mixed_nursing,
                                                    i_bed_type              => i_bed_type,
                                                    i_dest_prof             => i_dest_prof,
                                                    i_adm_preparation       => i_adm_preparation,
                                                    i_dt_admission          => i_dt_admission,
                                                    i_expect_duration       => i_expect_duration,
                                                    i_notes_adm             => i_notes_adm,
                                                    i_nit_flg               => i_nit_flg,
                                                    i_nit_dt_suggested      => i_nit_dt_suggested,
                                                    i_nit_dcs               => i_nit_dcs,
                                                    i_external_request      => i_external_request,
                                                    i_func_eval_score       => i_func_eval_score,
                                                    i_notes_edit            => i_notes_edit,
                                                    i_prof_cat_type         => i_prof_cat_type,
                                                    i_doc_area              => i_doc_area,
                                                    i_doc_template          => i_doc_template,
                                                    i_epis_documentation    => i_epis_documentation,
                                                    i_doc_flg_type          => i_doc_flg_type,
                                                    i_id_documentation      => i_id_documentation,
                                                    i_id_doc_element        => i_id_doc_element,
                                                    i_id_doc_element_crit   => i_id_doc_element_crit,
                                                    i_value                 => i_value,
                                                    i_notes                 => i_notes,
                                                    i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                    i_epis_context          => i_epis_context,
                                                    i_summary_and_notes     => i_summary_and_notes,
                                                    i_wtl_change            => i_wtl_change,
                                                    i_profs_alert           => i_profs_alert,
                                                    i_sr_pos_schedule       => i_sr_pos_schedule,
                                                    i_dt_pos_suggested      => i_dt_pos_suggested,
                                                    i_pos_req_notes         => i_pos_req_notes,
                                                    i_decision_notes        => NULL,
                                                    i_supply                => i_supply,
                                                    i_supply_set            => i_supply_set,
                                                    i_supply_qty            => i_supply_qty,
                                                    i_supply_loc            => i_supply_loc,
                                                    i_dt_return             => i_dt_return,
                                                    i_supply_soft_inst      => i_supply_soft_inst,
                                                    i_flg_cons_type         => i_flg_cons_type,
                                                    i_description_sp        => i_description_sp,
                                                    i_id_sr_epis_interv     => i_id_sr_epis_interv,
                                                    i_id_req_reason         => i_id_req_reason,
                                                    i_supply_notes          => i_supply_notes,
                                                    i_surgery_record        => i_surgery_record,
                                                    i_prof_team             => i_prof_team,
                                                    i_tbl_prof              => i_tbl_prof,
                                                    i_tbl_catg              => i_tbl_catg,
                                                    i_tbl_status            => i_tbl_status,
                                                    i_test                  => i_test,
                                                    i_diagnosis_adm_req     => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                         i_prof   => i_prof,
                                                                                                         i_params => i_diagnosis_adm_req),
                                                    i_diagnosis_surg_proc   => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                         i_prof   => i_prof,
                                                                                                         i_params => i_diagnosis_surg_proc),
                                                    i_diagnosis_contam      => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                         i_prof   => i_prof,
                                                                                                         i_params => i_diagnosis_contam),
                                                    i_id_cdr_call           => i_id_cdr_call,
                                                    i_id_ct_io              => i_id_ct_io,
                                                    i_order_set             => pk_alert_constant.g_no,
                                                    o_adm_request           => l_adm_request,
                                                    o_msg_error             => l_msg_error,
                                                    o_title_error           => l_title_error,
                                                    o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_adm_surg_request;

    /******************************************************************************
    *  Verifies if it is necessary to send information to the user in a popup, when creating, 
    *  updating or cancelling the Barthel Index.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_episode               Episode identifier
    *  @param  i_action                   Action that is being taken (A- Add, E-Edit, C-cancel, O-OK)
    *  @param  i_id_epis_documentation    Epis_documentation identifier (Barthel Index identifier)
    *  @param  o_flg_show                 Y - Indicates that a popup should be shown to the user; N - otherwise
    *  @param  o_pop_msgs                 Messages to be shown in the popup (1-title; 1st text; 2nd text,...)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      22-02-2010
    ******************************************************************************/
    FUNCTION check_wtl_func_eval_pop
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_action                IN VARCHAR2,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_pop_msgs              OUT table_table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL PK_WTL_PBL_CORE.CHECK_WTL_FUNC_EVAL_POP';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_pbl_core.check_wtl_func_eval_pop(i_lang                  => i_lang,
                                                       i_prof                  => i_prof,
                                                       i_id_episode            => i_id_episode,
                                                       i_id_patient            => i_id_patient,
                                                       i_action                => i_action,
                                                       i_id_epis_documentation => i_id_epis_documentation,
                                                       o_flg_show              => o_flg_show,
                                                       o_pop_msgs              => o_pop_msgs,
                                                       o_error                 => o_error)
        THEN
            RAISE l_internal_error;
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
                                              'CHECK_WTL_FUNC_EVAL_POP',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_wtl_func_eval_pop;

    /******************************************************************************
    *  Verifies if it is necessary to send information to the user in a popup, when creating, 
    *  updating and admission request.
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_episode               Episode identifier    
    *  @param  i_id_epis_documentation    Epis_documentation identifier (Barthel Index identifier)
    *  @param  o_flg_show                 Y - Indicates that a popup should be shown to the user; N - otherwise
    *  @param  o_pop_msgs                 Messages to be shown in the popup (1-title; 1st text; 2nd text,...)
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     Sofia Mendes
    *  @version                    2.6.0
    *  @since                      01-03-2010
    ******************************************************************************/
    FUNCTION check_adm_req_feval_pop
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_flg_show              OUT VARCHAR2,
        o_pop_msgs              OUT table_table_varchar,
        o_last_epis_doc         OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL PK_WTL_PBL_CORE.CHECK_ADM_REQ_FEVAL_POP';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_wtl_pbl_core.check_adm_req_feval_pop(i_lang                  => i_lang,
                                                       i_prof                  => i_prof,
                                                       i_id_episode            => i_id_episode,
                                                       i_id_patient            => i_id_patient,
                                                       i_id_epis_documentation => i_id_epis_documentation,
                                                       o_flg_show              => o_flg_show,
                                                       o_pop_msgs              => o_pop_msgs,
                                                       o_last_epis_doc         => o_last_epis_doc,
                                                       o_error                 => o_error)
        THEN
            RAISE l_internal_error;
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
                                              'CHECK_ADM_REQ_FEVAL_POP',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_adm_req_feval_pop;

    /******************************************************************************
    *  Function that creates the sys_alert for the planner profiles, in case of an edition to a barthel index
    *
    *  @param  i_lang                     Language ID
    *  @param  i_prof                     Professional ID/Institution ID/Software ID
    *  @param  i_id_patient               Episode identifier
    *  @param  o_error                    error info
    *
    *  @return                     boolean
    *
    *  @author                     RicardoNunoAlmeida
    *  @version                    2.6.0
    *  @since                      23-02-2010
    ******************************************************************************/
    FUNCTION set_wtl_func_eval_alert
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_wtl_pbl_core.set_wtl_func_eval_alert(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_id_patient => i_id_patient,
                                                       o_error      => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              'SET_WTL_FUNC_EVAL_ALERT',
                                              o_error);
            RETURN FALSE;
    END set_wtl_func_eval_alert;
    /**************************************************************************
    * Indica se um profissional fez registos numa dada doc_area num dado      *
    * episódio no caso afirmativo, devolve a última documentation             *
    * IMP: This function is cloned on PK_TOUCH_OPTION.get_prof_doc_area_exists*
    *                                                                         *
    * @param i_lang                id da lingua                               *
    * @param i_prof                utilizador autenticado                     *
    * @param i_episode             id do episódio                             *
    * @param i_doc_area            id da doc_area da qual se verificam se     *
    *                              foram feitos registos                      *
    * @param o_last_prof_epis_doc  Last documentation epis ID to profissional *
    * @param o_date_last_epis      Data do último episódio                    *
    * @param o_flg_data            Y if there are data, F when no date found  *
    * @param o_error               Error message                              *
    *                                                                         *
    * @return                      true or false on success or error          *
    *                                                                         *
    * @autor                                                                  *
    * @version                     1.0                                        *
    * @since                                                                  *
    **************************************************************************/
    FUNCTION get_prof_doc_area_exists
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        o_last_prof_epis_doc OUT epis_documentation.id_epis_documentation%TYPE,
        o_date_last_epis     OUT epis_documentation.dt_creation_tstz%TYPE,
        o_flg_data           OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_func_name VARCHAR2(200) := 'GET_PROF_DOC_AREA_EXISTS';
    BEGIN
    
        IF NOT pk_wtl_pbl_core.get_prof_doc_area_exists(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_episode            => i_episode,
                                                        i_doc_area           => i_doc_area,
                                                        o_last_prof_epis_doc => o_last_prof_epis_doc,
                                                        o_date_last_epis     => o_date_last_epis,
                                                        o_flg_data           => o_flg_data,
                                                        o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_prof_doc_area_exists;

    /**************************************************************************
    * Saves epis_documentation data with wtl_documentation logic (based on    *
    * the PK_TOUCH_OPTION.SET_EPIS_DOCUMENTATION function)                    *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_prof_cat_type                                                  *
    * @param i_epis                                                           *
    * @param i_doc_area                                                       *
    * @param i_doc_template                                                   *
    * @param i_epis_documentation                                             *
    * @param i_flg_type                                                       *
    * @param i_id_documentation                                               *
    * @param i_id_doc_element                                                 *
    * @param i_id_doc_element_crit                                            *
    * @param i_value                                                          *
    * @param i_notes                                                          *
    * @param i_id_doc_element_qualif                                          *
    * @param i_epis_context                                                   *
    * @param i_summary_and_notes                                              *
    * @param i_episode_context                                                *
    * @param i_wtl_change               Flag that states if the new docum.    *
    *                                   will affect waiting list              *
    * @param   i_flags                  List of flags that identify the scope of the score: Scale, Documentation, Group
    * @param   i_ids                    List of ids: Scale, Documentation, Group
    * @param   i_scores                 List of calculated scores    
    * @param   i_id_scales_formulas         Score calculation formulas Ids
    *                                                                         *
    * @param o_epis_documentation       Generated id_epis_documentation       *
    * @param   o_id_epis_scales_score   The epis_scales_score ID created  *    
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/02/22                            *
    **************************************************************************/
    FUNCTION set_wtl_epis_documentation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT pk_touch_option.g_flg_tab_origin_epis_doc,
        i_wtl_change            IN VARCHAR2,
        i_notes_wtl             IN VARCHAR2,
        i_flags                 IN table_varchar,
        i_ids                   IN table_number,
        i_scores                IN table_varchar,
        i_id_scales_formulas    IN table_number,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(30) := 'SET_WTL_EPIS_DOCUMENTATION';
        wtl_exception EXCEPTION;
    
    BEGIN
        g_error := 'Call pk_wtl_pbl_core.set_wtl_epis_documentation';
        IF NOT pk_wtl_pbl_core.set_wtl_epis_documentation(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_prof_cat_type         => i_prof_cat_type,
                                                          i_epis                  => i_epis,
                                                          i_doc_area              => i_doc_area,
                                                          i_doc_template          => i_doc_template,
                                                          i_epis_documentation    => i_epis_documentation,
                                                          i_flg_type              => i_flg_type,
                                                          i_id_documentation      => i_id_documentation,
                                                          i_id_doc_element        => i_id_doc_element,
                                                          i_id_doc_element_crit   => i_id_doc_element_crit,
                                                          i_value                 => i_value,
                                                          i_notes                 => i_notes,
                                                          i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                          i_epis_context          => i_epis_context,
                                                          i_summary_and_notes     => i_summary_and_notes,
                                                          i_episode_context       => i_episode_context,
                                                          i_flg_table_origin      => i_flg_table_origin,
                                                          i_wtl_change            => i_wtl_change,
                                                          i_notes_wtl             => i_notes_wtl,
                                                          i_flags                 => i_flags,
                                                          i_ids                   => i_ids,
                                                          i_scores                => i_scores,
                                                          i_id_scales_formulas    => i_id_scales_formulas,
                                                          i_dt_clinical           => i_dt_clinical,
                                                          o_epis_documentation    => o_epis_documentation,
                                                          o_id_epis_scales_score  => o_id_epis_scales_score,
                                                          o_error                 => o_error)
        THEN
            RAISE wtl_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN wtl_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_wtl_epis_documentation;

    /**************************************************************************
    * Cancels epis_documentation data with wtl_documentation logic (based on    *
    * the PK_TOUCH_OPTION.CANCEL_EPIS_DOCUMENTATION function)                    *
    *                                                                         *
    * @param i_lang                     language id                           *
    * @param i_prof                     professional, software and            *
    *                                   institution ids                       *
    * @param i_id_episode                                                     *
    * @param i_doc_area                                                       *
    * @param i_id_epis_doc                                                    *
    * @param i_wtl_change                                                     *
    * @param i_notes                                                          *
    * @param i_id_cancel_reason
    * @param o_flg_show                                                       *
    * @param o_msg_title                                                      *
    * @param o_msg_text                                                       *
    * @param o_button                                                         *
    * @param o_error                    Error message                         *
    *                                                                         *
    * @return                           Returns boolean                       *
    *                                                                         *
    * @author                           Gustavo Serrano                       *
    * @version                          1.0                                   *
    * @since                            2010/02/22                            *
    **************************************************************************/
    FUNCTION cancel_wtl_scale_epis_doc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_id_epis_doc      IN epis_documentation.id_epis_documentation%TYPE,
        i_wtl_change       IN VARCHAR2,
        i_notes_wtl        IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN VARCHAR2,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(30) := 'CANCEL_WTL_SCALE_EPIS_DOC';
        wtl_exception EXCEPTION;
    
    BEGIN
        g_error := 'Call pk_wtl_pbl_core.cancel_wtl_scale_epis_doc';
        IF NOT pk_wtl_pbl_core.cancel_wtl_scale_epis_doc(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_episode       => i_id_episode,
                                                         i_doc_area         => i_doc_area,
                                                         i_id_epis_doc      => i_id_epis_doc,
                                                         i_wtl_change       => i_wtl_change,
                                                         i_notes_wtl        => i_notes_wtl,
                                                         i_id_cancel_reason => i_id_cancel_reason,
                                                         i_notes            => i_notes,
                                                         o_flg_show         => o_flg_show,
                                                         o_msg_title        => o_msg_title,
                                                         o_msg_text         => o_msg_text,
                                                         o_button           => o_button,
                                                         o_error            => o_error)
        THEN
            RAISE wtl_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN wtl_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_wtl_scale_epis_doc;

    /***************************************************************************
    *  Returns the summary page values for the scale evaluation summary page.  *
    *                                                                          *
    * @param i_lang                    language id                             *
    * @param i_prof                    professional, software and institution  *
    *                                  ids                                     *
    * @param i_doc_area                documentation area ID                   *
    * @param i_id_episode              the episode id                          *
    * @param i_id_patient              the patient id                          *
    * @param o_doc_area_register       Cursor with the doc area info register  *
    * @param o_doc_area_val            Cursor containing the completed info for* 
    *                                  episode                                 *
    * @param o_doc_scales              Cursor containing the association       *
    *                                  between documentation elements and      *
    *                                  scale values                            *
    * @param o_error                   Error message                           *
    * @return                          true (sucess), false (error)            *
    *                                                                          *
    * @author                          Gustavo Serrano                         *
    * @version                         1.0                                     *
    * @since                           24-02-2010                              *
    ***************************************************************************/
    FUNCTION get_wtl_scales_summ_page
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_doc_area          IN NUMBER,
        i_id_episode        IN NUMBER,
        i_id_patient        IN NUMBER DEFAULT NULL,
        o_doc_area_register OUT pk_types.cursor_type,
        o_doc_area_val      OUT pk_types.cursor_type,
        o_doc_scales        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        wtl_exception EXCEPTION;
    BEGIN
        g_error := 'Call pk_wtl_pbl_core.get_wtl_scales_summ_page';
        IF NOT pk_wtl_pbl_core.get_wtl_scales_summ_page(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_doc_area          => i_doc_area,
                                                        i_id_episode        => i_id_episode,
                                                        i_id_patient        => i_id_patient,
                                                        o_doc_area_register => o_doc_area_register,
                                                        o_doc_area_val      => o_doc_area_val,
                                                        o_doc_scales        => o_doc_scales,
                                                        o_error             => o_error)
        THEN
            RAISE wtl_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN wtl_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.err_desc,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WTL_SCALES_SUMM_PAGE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_WTL_SCALES_SUMM_PAGE',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_scales);
            RETURN FALSE;
    END get_wtl_scales_summ_page;

    /********************************************************************************************
    *  Get waiting line ID of an episode
    *
    * @param    I_LANG          Preferred language ID
    * @param    I_PROF          Object (ID of professional, ID of institution, ID of software)
    * @param    I_EPISODE       Episode ID
    * @param    O_WTL           Waiting line ID
    * @param    O_ERROR         Error message
    *
    * @return   BOOLEAN         False in case of error and true otherwise
    * 
    * @author   Tiago Silva
    * @since    2010/08/12
    ********************************************************************************************/
    FUNCTION get_episode_wtl
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_wtl     OUT waiting_list.id_waiting_list%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PK_WTL_PBL_CORE.GET_EPISODE_WTL FUNCTION';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF NOT pk_wtl_pbl_core.get_episode_wtl(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_episode => i_episode,
                                               o_wtl     => o_wtl,
                                               o_error   => o_error)
        THEN
            RAISE l_exception;
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
                                              'GET_EPISODE_WTL',
                                              o_error);
            RETURN FALSE;
    END get_episode_wtl;

    FUNCTION set_surgery_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        -- Logic
        i_id_episode      IN episode.id_episode%TYPE, -- Current episode
        io_id_episode_sr  IN OUT episode.id_episode%TYPE, -- Surgical episode -- 5
        io_id_episode_inp IN OUT episode.id_episode%TYPE, -- Inpatient episode
        -- Waiting List / Common
        io_id_waiting_list IN OUT waiting_list.id_waiting_list%TYPE,
        i_data             CLOB,
        i_profs_alert      IN table_number DEFAULT NULL, --65
        i_id_inst_dest     IN institution.id_institution%TYPE DEFAULT NULL,
        o_msg_error        OUT VARCHAR2,
        o_title_error      OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN AS
    
        l_exception EXCEPTION;
        l_func_name VARCHAR2(200) := 'SET_SURGERY_REQUEST';
    
        l_p   xmlparser.parser;
        l_doc xmldom.domdocument; -- represents the entire XML document 
    
        l_nl   xmldom.domnodelist; -- interface provides the abstraction of an ordered collection of nodes
        l_n    xmldom.domnode; -- primary datatype for the entire Document Object Model
        l_e    xmldom.domelement;
        l_e1   xmldom.domelement;
        l_nlen NUMBER;
    
        l_adm_request adm_request.id_adm_request%TYPE;
    
        l_ri_reason_admission NUMBER(24);
        l_rs_sur_need         VARCHAR2(200 CHAR);
        l_rs_glb_anesth       VARCHAR2(10 CHAR);
        l_rs_glb_anesth_l     VARCHAR2(10 CHAR);
        l_rs_lcl_anesth       VARCHAR2(10 CHAR);
        l_rs_lcl_anesth_l     VARCHAR2(10 CHAR);
        l_ri_diagnoses        CLOB;
        l_ri_loc_int          NUMBER(24);
        l_ri_serv_adm         NUMBER(24);
        l_ri_esp_int          NUMBER(24);
        l_ri_phys_adm         NUMBER(24);
        l_rs_type_int         NUMBER(24);
        l_ri_durantion        NUMBER(24);
        l_ri_prepar           NUMBER(24);
        l_ri_type_room        NUMBER(24);
        l_ri_mix_room         VARCHAR2(200 CHAR);
        l_rs_type_bed         NUMBER(24);
        l_ri_pref_room        NUMBER(24);
        l_ri_need_nurse_cons  VARCHAR2(200 CHAR);
        l_ri_loc_nurse_cons   NUMBER(24);
        l_ri_date_nurse_cons  VARCHAR2(200 CHAR);
        l_ri_notes            VARCHAR2(1000 CHAR);
        l_rs_loc_surgery      VARCHAR2(200 CHAR);
        l_rs_spec_surgery     NUMBER(24);
        l_rs_department       NUMBER(24);
        l_rs_clin_service     NUMBER(24);
        l_rs_pref_surg        NUMBER(24);
        l_rs_proc_surg        VARCHAR2(200 CHAR);
        l_rs_prev_duration    NUMBER(6);
        l_rs_uci              VARCHAR2(200 CHAR);
        l_rs_uci_pos          VARCHAR2(200 CHAR);
        l_rs_ext_spec         NUMBER(24);
        l_rs_cont_danger      CLOB;
        l_rs_pref_time        VARCHAR2(200 CHAR);
        l_rs_mot_pref_time    NUMBER(24);
        l_rs_notes            VARCHAR2(1000 CHAR);
        l_rv_request          VARCHAR2(200 CHAR);
        l_rv_dt_verif         VARCHAR2(200 CHAR);
        l_rv_notes_req        VARCHAR2(1000 CHAR);
        l_rv_decision         VARCHAR2(200 CHAR);
        l_rv_valid            VARCHAR2(200 CHAR);
        l_rv_notes_decis      VARCHAR2(1000 CHAR);
        l_rsp_lvl_urg         NUMBER(24);
        l_rsp_begin_sched     VARCHAR2(200 CHAR);
        l_rsp_end_sched       VARCHAR2(200 CHAR);
        l_rsp_time_min        NUMBER(6);
        l_rsp_sugg_dt_surg    VARCHAR2(200 CHAR);
        l_rsp_sugg_dt_int     VARCHAR2(200 CHAR);
        l_rip_begin_per       VARCHAR2(200 CHAR);
        l_rip_duration        VARCHAR2(200 CHAR);
        l_rip_end_per         VARCHAR2(200 CHAR);
    
        l_ri_reason_admission_l NUMBER(24);
        l_rs_sur_need_l         VARCHAR2(200 CHAR);
        l_ri_diagnoses_l        CLOB;
        l_ri_loc_int_l          NUMBER(24);
        l_ri_serv_adm_l         NUMBER(24);
        l_ri_esp_int_l          NUMBER(24);
        l_ri_phys_adm_l         NUMBER(24);
        l_rs_type_int_l         NUMBER(24);
        l_ri_durantion_l        NUMBER(24);
        l_ri_prepar_l           NUMBER(24);
        l_ri_type_room_l        NUMBER(24);
        l_ri_mix_room_l         VARCHAR2(200 CHAR);
        l_rs_type_bed_l         NUMBER(24);
        l_ri_pref_room_l        NUMBER(24);
        l_ri_need_nurse_cons_l  VARCHAR2(200 CHAR);
        l_ri_loc_nurse_cons_l   NUMBER(24);
        l_ri_date_nurse_cons_l  VARCHAR2(200 CHAR);
        l_ri_notes_l            VARCHAR2(1000 CHAR);
        l_rs_loc_surgery_l      VARCHAR2(200 CHAR);
        l_rs_spec_surgery_l     NUMBER(24);
        l_rs_pref_surg_l        NUMBER(24);
        l_rs_proc_surg_l        VARCHAR2(200 CHAR);
        l_rs_prev_duration_l    NUMBER(6);
        l_rs_uci_l              VARCHAR2(200 CHAR);
        l_rs_uci_pos_l          VARCHAR2(200 CHAR);
        l_rs_ext_spec_l         NUMBER(24);
        l_rs_cont_danger_l      VARCHAR2(200 CHAR);
        l_rs_pref_time_l        VARCHAR2(200 CHAR);
        l_rs_mot_pref_time_l    NUMBER(24);
        l_rs_notes_l            VARCHAR2(1000 CHAR);
        l_rv_request_l          VARCHAR2(200 CHAR);
        l_rv_dt_verif_l         VARCHAR2(200 CHAR);
        l_rv_notes_req_l        VARCHAR2(1000 CHAR);
        l_rv_decision_l         VARCHAR2(200 CHAR);
        l_rv_valid_l            VARCHAR2(200 CHAR);
        l_rv_notes_decis_l      VARCHAR2(1000 CHAR);
        l_rsp_lvl_urg_l         NUMBER(24);
        l_rsp_begin_sched_l     VARCHAR2(200 CHAR);
        l_rsp_end_sched_l       VARCHAR2(200 CHAR);
        l_rsp_time_min_l        NUMBER(6);
        l_rsp_sugg_dt_surg_l    VARCHAR2(200 CHAR);
        l_rsp_sugg_dt_int_l     VARCHAR2(200 CHAR);
        l_rip_begin_per_l       VARCHAR2(200 CHAR);
        l_rip_duration_l        VARCHAR2(200 CHAR);
        l_rip_end_per_l         VARCHAR2(200 CHAR);
    
        l_sr_proc_notes        VARCHAR2(4000 CHAR);
        l_sr_proc_team         NUMBER(24);
        l_sr_proc_diag         CLOB;
        l_sr_proc_type         VARCHAR2(10 CHAR);
        l_sr_proc_codification NUMBER(24);
        l_sr_proc_laterality   VARCHAR2(10 CHAR);
        l_sr_proc_ss           VARCHAR2(4000 CHAR);
        l_sr_proc_value        NUMBER(24);
    
        tbl_sr_proc_notes        table_varchar;
        tbl_sr_proc_team         table_number;
        tbl_sr_proc_diag         table_clob;
        tbl_sr_proc_type         table_varchar;
        tbl_sr_proc_codification table_number;
        tbl_sr_proc_laterality   table_varchar;
        tbl_sr_proc_ss           table_varchar;
        tbl_sr_proc_value        table_number;
    
        parent_node xmldom.domnode;
        childnodes  xmldom.domnodelist;
    
        l_tbl_prof   table_table_number := table_table_number();
        l_tbl_catg   table_table_number := table_table_number();
        l_tbl_status table_table_varchar := table_table_varchar();
    
        tbl_pref_surgeons table_number := table_number();
        tbl_ext_serv      table_number := table_number();
        tbl_pref_time     table_varchar := table_varchar();
    
        r_tbl_prof   table_number;
        r_tbl_catg   table_number;
        r_tbl_status table_varchar;
    
        l_team_status VARCHAR2(10 CHAR);
        l_team_task   NUMBER(24);
        l_team_id     NUMBER(24);
        len           NUMBER(24);
        n             xmldom.domnode;
    
        childnodes1 xmldom.domnodelist;
        len1        NUMBER(24);
        len_tb_d    NUMBER(24);
        n1          xmldom.domnode;
        teste       VARCHAR2(100 CHAR);
    
        len_tbl  NUMBER(24);
        len_ttbl NUMBER(24);
    
        l_sr_proc_diagnoses CLOB;
        l_tbl_sr_proc_diag  table_clob;
    
        l_epis_type_sr  epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_operating;
        l_epis_type_inp epis_type.id_epis_type%TYPE := pk_alert_constant.g_epis_type_inpatient;
    
        l_clinical_question table_table_number := table_table_number();
        r_clinical_question table_number;
    
        l_response table_table_varchar := table_table_varchar();
        r_response table_varchar;
    
        l_clinical_question_notes table_table_clob := table_table_clob();
        r_clinical_question_notes table_clob;
    
        v_response                VARCHAR2(32767);
        v_clinical_question       VARCHAR2(32767);
        v_clinical_question_notes CLOB;
    
        l_rs_cont_danger_prev CLOB;
        l_diag_epis_type_cont pk_edis_types.rec_in_epis_diagnosis;
    
        l_ttbl_supply table_table_number := table_table_number();
        l_tbl_supply  table_number;
        l_bl_supply   NUMBER(24);
    
        l_ttbl_supply_qty table_table_number := table_table_number();
        l_tbl_supply_qty  table_number;
        l_bl_supply_qty   NUMBER(24);
    
        l_ttbl_supply_soft table_table_number := table_table_number();
        l_tbl_supply_soft  table_number;
        l_bl_supply_soft   NUMBER(24);
    
        l_ttbl_supply_loc table_table_number := table_table_number();
        l_tbl_supply_loc  table_number;
        l_bl_supply_loc   NUMBER(24);
    
        l_ttbl_supply_set table_table_number := table_table_number();
        l_tbl_supply_set  table_number;
        l_bl_supply_set   NUMBER(24);
    
        l_ttbl_supply_dtr table_table_varchar := table_table_varchar();
        l_tbl_supply_dtr  table_varchar;
        l_bl_supply_dtr   VARCHAR2(200 CHAR);
    
        l_ttbl_supply_fct table_table_varchar := table_table_varchar();
        l_tbl_supply_fct  table_varchar;
        l_bl_supply_fct   VARCHAR2(200 CHAR);
    
        l_ttbl_supply_not table_table_varchar := table_table_varchar();
        l_tbl_supply_not  table_varchar;
        l_bl_supply_not   VARCHAR2(200 CHAR);
    
        l_ttbl_supply_irr table_table_number := table_table_number();
        l_tbl_supply_irr  table_number;
        l_bl_supply_irr   NUMBER(24);
    
        idx                    NUMBER;
        tbl_sr_epis_interv     table_number := table_number();
        tbl_sr_epis_interv_int table_number := table_number();
        tbl_sr_intervention    table_number := table_number();
        tbl_sr_record          table_number := table_number();
        tbl_description_sp     table_varchar := table_varchar();
        tbl_ct_io              table_table_varchar := table_table_varchar();
    
        tbl_rip_begin table_varchar := table_varchar();
        tbl_rip_end   table_varchar := table_varchar();
    
        FUNCTION get_previous_diagnosis
        (
            i_lang           IN language.id_language%TYPE,
            i_prof           IN profissional,
            i_ri_diagnosis   IN CLOB,
            i_id_diag_prev   IN CLOB,
            i_diag_epis_type IN OUT pk_edis_types.rec_in_epis_diagnosis
        ) RETURN BOOLEAN IS
        
            l_tbl_diag   table_varchar := table_varchar();
            l_diags_form table_number := table_number();
            l_count_diag INTEGER;
        
            PROCEDURE set_diag_info
            (
                i_id_diag      IN diagnosis.id_diagnosis%TYPE,
                i_diag_ep_type IN OUT pk_edis_types.rec_in_epis_diagnosis
            ) IS
            
            BEGIN
                SELECT d.id_diagnosis,
                       ad.id_alert_diagnosis,
                       ed.desc_epis_diagnosis,
                       'D',
                       ed.flg_final_type,
                       ed.flg_status,
                       ed.flg_add_problem,
                       ed.notes,
                       ed.id_diagnosis_condition,
                       ed.id_sub_analysis,
                       ed.id_anatomical_area,
                       ed.id_anatomical_side,
                       ed.id_lesion_location,
                       ed.id_lesion_type,
                       ed.dt_initial_diag,
                       ed.id_diag_basis,
                       ed.diag_basis_spec,
                       ed.flg_recurrence,
                       ed.flg_mult_tumors,
                       ed.num_primary_tumors
                  INTO i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diagnosis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_alert_diagnosis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).desc_diagnosis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_diag_type,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_final_type,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_status,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_add_problem,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).notes,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diagnosis_condition,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_sub_analysis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_anatomical_area,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_anatomical_side,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_lesion_location,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_lesion_type,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).dt_initial_diag,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diag_basis,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).diag_basis_spec,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_recurrence,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_mult_tumors,
                       i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).num_primary_tumors
                  FROM diagnosis d
                  JOIN alert_diagnosis ad
                    ON ad.id_diagnosis = d.id_diagnosis
                  JOIN epis_diagnosis ed
                    ON ed.id_diagnosis = d.id_diagnosis
                   AND ed.id_episode = i_id_episode
                   AND ed.id_alert_diagnosis = ad.id_alert_diagnosis
                 WHERE d.id_diagnosis = i_id_diag
                   AND ed.flg_status != pk_diagnosis.g_epis_status_c
                   AND rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                
                    SELECT d.id_diagnosis,
                           ad.id_alert_diagnosis,
                           ed.desc_epis_diagnosis,
                           'D',
                           ed.flg_final_type,
                           ed.flg_status,
                           ed.flg_add_problem,
                           ed.notes,
                           ed.id_diagnosis_condition,
                           ed.id_sub_analysis,
                           ed.id_anatomical_area,
                           ed.id_anatomical_side,
                           ed.id_lesion_location,
                           ed.id_lesion_type,
                           ed.dt_initial_diag,
                           ed.id_diag_basis,
                           ed.diag_basis_spec,
                           ed.flg_recurrence,
                           ed.flg_mult_tumors,
                           ed.num_primary_tumors
                      INTO i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diagnosis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_alert_diagnosis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).desc_diagnosis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_diag_type,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_final_type,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_status,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_add_problem,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).notes,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diagnosis_condition,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_sub_analysis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_anatomical_area,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_anatomical_side,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_lesion_location,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_lesion_type,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).dt_initial_diag,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).id_diag_basis,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).diag_basis_spec,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_recurrence,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).flg_mult_tumors,
                           i_diag_ep_type.tbl_diagnosis(i_diag_epis_type.tbl_diagnosis.count).num_primary_tumors
                      FROM diagnosis d
                      JOIN alert_diagnosis ad
                        ON ad.id_diagnosis = d.id_diagnosis
                      JOIN epis_diagnosis ed
                        ON ed.id_diagnosis = d.id_diagnosis
                       AND ed.id_episode IN (SELECT e.id_episode
                                               FROM episode e
                                              WHERE e.id_patient IN (SELECT e.id_patient
                                                                       FROM episode e
                                                                      WHERE e.id_episode = i_id_episode)
                                                AND e.id_epis_type = 5)
                     WHERE d.id_diagnosis = i_id_diag
                       AND ed.flg_status != pk_diagnosis.g_epis_status_c
                       AND rownum = 1
                     ORDER BY dt_initial_diag DESC;
                
            END set_diag_info;
        
        BEGIN
        
            --Obtain the diagnosis inserted on the form
            IF i_ri_diagnosis IS NOT NULL
            THEN
                i_diag_epis_type := pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                              i_prof   => i_prof,
                                                              i_params => i_ri_diagnosis);
            
                --Obtain the diagnosis from the episode    
                SELECT pk_string_utils.str_split(i_id_diag_prev) COLLECT
                  INTO l_tbl_diag
                  FROM dual;
            
                FOR i IN i_diag_epis_type.tbl_diagnosis.first .. i_diag_epis_type.tbl_diagnosis.last
                LOOP
                    l_diags_form.extend();
                    l_diags_form(i) := i_diag_epis_type.tbl_diagnosis(i).id_diagnosis;
                
                END LOOP;
            
                --Check if the diagnosis from the episode were also inserted in the form
                FOR i IN 1 .. l_tbl_diag.count()
                LOOP
                
                    l_count_diag := 0;
                
                    SELECT COUNT(1)
                      INTO l_count_diag
                      FROM dual
                     WHERE to_number(l_tbl_diag(i)) IN (SELECT *
                                                          FROM TABLE(l_diags_form));
                
                    IF l_count_diag = 0
                    THEN
                    
                        i_diag_epis_type.tbl_diagnosis.extend();
                        set_diag_info(i_id_diag => l_tbl_diag(i), i_diag_ep_type => i_diag_epis_type);
                    
                    END IF;
                END LOOP;
            
            ELSE
                --IF THERE IS NO DIAGNOSIS DOCUMENTED ON THE FORM            
                SELECT pk_string_utils.str_split(i_id_diag_prev) COLLECT
                  INTO l_tbl_diag
                  FROM dual;
            
                i_diag_epis_type.tbl_diagnosis := pk_edis_types.table_in_diagnosis();
            
                FOR i IN 1 .. l_tbl_diag.count()
                LOOP
                
                    i_diag_epis_type.tbl_diagnosis.extend();
                    set_diag_info(i_id_diag => l_tbl_diag(i), i_diag_ep_type => i_diag_epis_type);
                
                END LOOP;
            END IF;
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END get_previous_diagnosis;
    
    BEGIN
        l_p := xmlparser.newparser;
        xmlparser.parsebuffer(l_p, i_data);
        l_doc := xmlparser.getdocument(l_p);
    
        l_nl   := xmldom.getelementsbytagname(l_doc, '*');
        l_nlen := xmldom.getlength(l_nl);
    
        r_tbl_prof         := table_number();
        r_tbl_catg         := table_number();
        r_tbl_status       := table_varchar();
        l_tbl_sr_proc_diag := table_clob();
    
        r_clinical_question       := table_number();
        r_response                := table_varchar();
        r_clinical_question_notes := table_clob();
    
        tbl_sr_proc_notes        := table_varchar();
        tbl_sr_proc_team         := table_number();
        tbl_sr_proc_diag         := table_clob();
        tbl_sr_proc_type         := table_varchar();
        tbl_sr_proc_codification := table_number();
        tbl_sr_proc_laterality   := table_varchar();
        tbl_sr_proc_value        := table_number();
        tbl_sr_proc_ss           := table_varchar();
    
        l_tbl_supply      := table_number();
        l_tbl_supply_qty  := table_number();
        l_tbl_supply_soft := table_number();
        l_tbl_supply_loc  := table_number();
        l_tbl_supply_set  := table_number();
        l_tbl_supply_dtr  := table_varchar();
        l_tbl_supply_fct  := table_varchar();
        l_tbl_supply_not  := table_varchar();
        l_tbl_supply_irr  := table_number();
    
        FOR j IN 0 .. l_nlen - 1
        LOOP
        
            l_n := xmldom.item(l_nl, j); -- define node
        
            parent_node := xmldom.getparentnode(l_n);
            teste       := xmldom.getnodename(parent_node);
            IF xmldom.getnodename(parent_node) = g_xml_additional_info
            THEN
            
                IF xmldom.getnodename(l_n) = g_xml_component_leaf
                THEN
                
                    l_e := xmldom.makeelement(l_n);
                    CASE xmldom.getattribute(l_e, g_xml_internal_name)
                        WHEN 'RS_CONT_DANGET_P' THEN
                            childnodes := xmldom.getchildnodes(l_n);
                            n          := dbms_xmldom.item(childnodes, 0);
                            dbms_lob.createtemporary(l_rs_cont_danger, TRUE);
                            dbms_xmldom.writetoclob(n, l_rs_cont_danger);
                        WHEN 'RS_PROC_SURG_P' THEN
                            l_sr_proc_notes := xmldom.getattribute(l_e, 'FIELD_NOTES');
                            len_tbl         := tbl_sr_proc_notes.count;
                            tbl_sr_proc_notes.extend;
                        
                            tbl_sr_proc_notes(len_tbl + 1) := l_sr_proc_notes;
                        
                            l_sr_proc_team := xmldom.getattribute(l_e, 'FIELD_SURGERY_TEAM');
                            len_tbl        := tbl_sr_proc_team.count;
                            tbl_sr_proc_team.extend;
                        
                            tbl_sr_proc_team(len_tbl + 1) := l_sr_proc_team;
                        
                            l_sr_proc_diag := xmldom.getattribute(l_e, 'FIELD_ASSOC_DIAG');
                            len_tbl        := tbl_sr_proc_diag.count;
                            tbl_sr_proc_diag.extend;
                        
                            tbl_sr_proc_diag(len_tbl + 1) := l_sr_proc_diag;
                        
                            l_sr_proc_type := xmldom.getattribute(l_e, 'FIELD_SURGERY_TYPE');
                            len_tbl        := tbl_sr_proc_type.count;
                            tbl_sr_proc_type.extend;
                        
                            tbl_sr_proc_type(len_tbl + 1) := l_sr_proc_type;
                        
                            l_sr_proc_value := xmldom.getattribute(l_e, g_xml_value);
                            len_tbl         := tbl_sr_proc_value.count;
                            tbl_sr_proc_value.extend;
                        
                            tbl_sr_proc_value(len_tbl + 1) := l_sr_proc_value;
                        
                            l_sr_proc_codification := xmldom.getattribute(l_e, 'FIELD_CODIFICATION');
                            len_tbl                := tbl_sr_proc_codification.count;
                            tbl_sr_proc_codification.extend;
                        
                            tbl_sr_proc_codification(len_tbl + 1) := l_sr_proc_codification;
                        
                            l_sr_proc_laterality := xmldom.getattribute(l_e, 'FIELD_LATERALITY');
                            len_tbl              := tbl_sr_proc_laterality.count;
                            tbl_sr_proc_laterality.extend;
                        
                            tbl_sr_proc_laterality(len_tbl + 1) := l_sr_proc_laterality;
                        
                            l_sr_proc_ss := xmldom.getattribute(l_e, 'FIELD_SURGICAL_SITE');
                            len_tbl      := tbl_sr_proc_ss.count;
                            tbl_sr_proc_ss.extend;
                        
                            tbl_sr_proc_ss(len_tbl + 1) := l_sr_proc_ss;
                        
                            len_tbl := tbl_sr_epis_interv.count;
                            tbl_sr_epis_interv.extend;
                            tbl_sr_epis_interv(len_tbl + 1) := NULL;
                        
                            len_tbl := tbl_sr_record.count;
                            tbl_sr_record.extend;
                            tbl_sr_record(len_tbl + 1) := NULL;
                        
                            len_tbl := tbl_description_sp.count;
                            tbl_description_sp.extend;
                            tbl_description_sp(len_tbl + 1) := NULL;
                        
                            len_tbl := tbl_ct_io.count;
                            tbl_ct_io.extend;
                            tbl_ct_io(len_tbl + 1) := table_varchar(NULL);
                        
                            childnodes := xmldom.getchildnodes(l_n);
                        
                            len := dbms_xmldom.getlength(childnodes);
                        
                            FOR i IN 0 .. len - 1
                            LOOP
                            
                                n           := dbms_xmldom.item(childnodes, i);
                                teste       := xmldom.getnodename(n);
                                childnodes1 := dbms_xmldom.getchildnodes(n);
                                len1        := xmldom.getlength(childnodes1);
                                l_e1        := xmldom.makeelement(n);
                            
                                CASE xmldom.getnodename(n)
                                    WHEN 'PROCEDURE_SUPPLIES' THEN
                                        FOR j IN 0 .. len1 - 1
                                        LOOP
                                        
                                            n1               := dbms_xmldom.item(childnodes1, j);
                                            l_e              := xmldom.makeelement(n1);
                                            l_bl_supply      := xmldom.getattribute(l_e, 'ID_SUPPLY');
                                            l_bl_supply_qty  := xmldom.getattribute(l_e, 'QUANTITY');
                                            l_bl_supply_soft := xmldom.getattribute(l_e, 'ID_SOFT_INST');
                                            l_bl_supply_fct  := xmldom.getattribute(l_e, 'FLG_CONS_TYPE');
                                            l_bl_supply_set  := xmldom.getattribute(l_e, 'ID_PARENT_SUPPLY');
                                            l_bl_supply_dtr  := xmldom.getattribute(l_e, 'DT_RETURN');
                                            l_bl_supply_loc  := xmldom.getattribute(l_e, 'LOCATION');
                                            l_bl_supply_not  := xmldom.getattribute(l_e, 'NOTES');
                                            l_bl_supply_irr  := xmldom.getattribute(l_e, 'REASON');
                                        
                                            len_tbl := l_tbl_supply.count;
                                        
                                            IF xmldom.getattribute(l_e, 'ID_PARENT_SUPPLY') IS NULL
                                            THEN
                                                l_tbl_supply.extend;
                                                l_tbl_supply_qty.extend;
                                                l_tbl_supply_soft.extend;
                                                l_tbl_supply_loc.extend;
                                                l_tbl_supply_set.extend;
                                                l_tbl_supply_dtr.extend;
                                                l_tbl_supply_fct.extend;
                                                l_tbl_supply_not.extend;
                                                l_tbl_supply_irr.extend;
                                                l_tbl_supply(len_tbl + 1) := l_bl_supply;
                                                l_tbl_supply_qty(len_tbl + 1) := l_bl_supply_qty;
                                                l_tbl_supply_soft(len_tbl + 1) := l_bl_supply_soft;
                                                l_tbl_supply_loc(len_tbl + 1) := l_bl_supply_loc;
                                                l_tbl_supply_set(len_tbl + 1) := l_bl_supply_set;
                                                l_tbl_supply_dtr(len_tbl + 1) := l_bl_supply_dtr;
                                                l_tbl_supply_fct(len_tbl + 1) := l_bl_supply_fct;
                                                l_tbl_supply_not(len_tbl + 1) := l_bl_supply_not;
                                                l_tbl_supply_irr(len_tbl + 1) := l_bl_supply_irr;
                                            ELSE
                                                l_tbl_supply.extend;
                                                l_tbl_supply_qty.extend;
                                                l_tbl_supply_soft.extend;
                                                l_tbl_supply_loc.extend;
                                                l_tbl_supply_set.extend;
                                                l_tbl_supply_dtr.extend;
                                                l_tbl_supply_fct.extend;
                                                l_tbl_supply_not.extend;
                                                l_tbl_supply_irr.extend;
                                                l_tbl_supply(len_tbl + 1) := l_bl_supply;
                                                l_tbl_supply_qty(len_tbl + 1) := l_bl_supply_qty;
                                                l_tbl_supply_soft(len_tbl + 1) := l_bl_supply_soft;
                                                l_tbl_supply_loc(len_tbl + 1) := l_bl_supply_loc;
                                                l_tbl_supply_set(len_tbl + 1) := l_bl_supply_set;
                                                l_tbl_supply_dtr(len_tbl + 1) := l_bl_supply_dtr;
                                                l_tbl_supply_fct(len_tbl + 1) := l_bl_supply_fct;
                                                l_tbl_supply_not(len_tbl + 1) := l_bl_supply_not;
                                                l_tbl_supply_irr(len_tbl + 1) := l_bl_supply_irr;
                                            END IF;
                                        END LOOP;
                                    
                                    WHEN 'PROCEDURE_TEAM' THEN
                                        FOR j IN 0 .. len1 - 1
                                        LOOP
                                        
                                            n1            := dbms_xmldom.item(childnodes1, j);
                                            l_e           := xmldom.makeelement(n1);
                                            teste         := dbms_xmldom.getnodename(n1);
                                            l_team_status := xmldom.getattribute(l_e, 'STATUS');
                                            l_team_task   := xmldom.getattribute(l_e, 'TASK');
                                            l_team_id     := xmldom.getattribute(l_e, 'ID');
                                        
                                            len_tbl := r_tbl_prof.count;
                                            r_tbl_prof.extend;
                                        
                                            r_tbl_catg.extend;
                                        
                                            r_tbl_status.extend;
                                        
                                            r_tbl_prof(len_tbl + 1) := l_team_id;
                                            r_tbl_catg(len_tbl + 1) := l_team_task;
                                            r_tbl_status(len_tbl + 1) := l_team_status;
                                        
                                        END LOOP;
                                    
                                    WHEN 'PROCEDURE_DIAG' THEN
                                        dbms_lob.createtemporary(l_sr_proc_diagnoses, TRUE);
                                        dbms_xmldom.writetoclob(dbms_xmldom.item(childnodes1, 0), l_sr_proc_diagnoses);
                                    
                                        len_tb_d := l_tbl_sr_proc_diag.count;
                                        l_tbl_sr_proc_diag.extend;
                                        l_tbl_sr_proc_diag(len_tb_d + 1) := l_sr_proc_diagnoses;
                                    WHEN 'CLINICAL_QUESTIONS' THEN
                                    
                                        IF len1 > 0
                                        THEN
                                            r_clinical_question_notes := table_clob();
                                            r_response                := table_varchar();
                                            r_clinical_question       := table_number();
                                            FOR j IN 0 .. len1 - 1
                                            LOOP
                                            
                                                n1                        := dbms_xmldom.item(childnodes1, j);
                                                l_e                       := xmldom.makeelement(n1);
                                                teste                     := dbms_xmldom.getnodename(n1);
                                                v_clinical_question_notes := xmldom.getattribute(l_e, 'NOTES');
                                                v_response                := xmldom.getattribute(l_e, 'RESPONSE');
                                                v_clinical_question       := xmldom.getattribute(l_e, 'ID_QUESTION');
                                            
                                                --r_clinical_question_notes := table_varchar();
                                                len_tbl := r_clinical_question_notes.count;
                                                r_clinical_question_notes.extend;
                                                --r_response := table_varchar();
                                                r_response.extend;
                                                --r_clinical_question := table_number();
                                                r_clinical_question.extend;
                                            
                                                r_clinical_question_notes(len_tbl + 1) := v_clinical_question_notes;
                                                r_response(len_tbl + 1) := v_response;
                                                r_clinical_question(len_tbl + 1) := v_clinical_question;
                                            
                                            END LOOP;
                                        
                                            len_ttbl := l_clinical_question.count;
                                            l_clinical_question.extend;
                                            l_clinical_question(len_ttbl + 1) := r_clinical_question;
                                            l_response.extend;
                                            l_response(len_ttbl + 1) := r_response;
                                            l_clinical_question_notes.extend;
                                            l_clinical_question_notes(len_ttbl + 1) := r_clinical_question_notes;
                                        ELSE
                                            len_ttbl := l_clinical_question.count;
                                            l_clinical_question.extend;
                                            l_clinical_question(len_ttbl + 1) := table_number();
                                            l_response.extend;
                                            l_response(len_ttbl + 1) := table_varchar();
                                            l_clinical_question_notes.extend;
                                            l_clinical_question_notes(len_ttbl + 1) := table_clob();
                                        END IF;
                                    
                                    ELSE
                                        NULL;
                                END CASE;
                            
                            END LOOP;
                        
                            len_ttbl := l_tbl_prof.count;
                            l_tbl_prof.extend;
                            l_tbl_prof(len_ttbl + 1) := r_tbl_prof;
                            l_tbl_catg.extend;
                            l_tbl_catg(len_ttbl + 1) := r_tbl_catg;
                            l_tbl_status.extend;
                            l_tbl_status(len_ttbl + 1) := r_tbl_status;
                        
                            len_ttbl := l_ttbl_supply.count;
                            l_ttbl_supply.extend;
                            l_ttbl_supply_qty.extend;
                            l_ttbl_supply_soft.extend;
                            l_ttbl_supply_loc.extend;
                            l_ttbl_supply_set.extend;
                            l_ttbl_supply_dtr.extend;
                            l_ttbl_supply_fct.extend;
                            l_ttbl_supply_not.extend;
                            l_ttbl_supply_irr.extend;
                            l_ttbl_supply(len_ttbl + 1) := l_tbl_supply;
                            l_tbl_supply := table_number();
                            l_ttbl_supply_qty(len_ttbl + 1) := l_tbl_supply_qty;
                            l_tbl_supply_qty := table_number();
                            l_ttbl_supply_soft(len_ttbl + 1) := l_tbl_supply_soft;
                            l_tbl_supply_soft := table_number();
                            l_ttbl_supply_loc(len_ttbl + 1) := l_tbl_supply_loc;
                            l_tbl_supply_loc := table_number();
                            l_ttbl_supply_set(len_ttbl + 1) := l_tbl_supply_set;
                            l_tbl_supply_set := table_number();
                            l_ttbl_supply_dtr(len_ttbl + 1) := l_tbl_supply_dtr;
                            l_tbl_supply_dtr := table_varchar();
                            l_ttbl_supply_fct(len_ttbl + 1) := l_tbl_supply_fct;
                            l_tbl_supply_fct := table_varchar();
                            l_ttbl_supply_not(len_ttbl + 1) := l_tbl_supply_not;
                            l_tbl_supply_not := table_varchar();
                            l_ttbl_supply_irr(len_ttbl + 1) := l_tbl_supply_irr;
                            l_tbl_supply_irr := table_number();
                        
                        ELSE
                            NULL;
                    END CASE;
                ELSIF xmldom.getnodename(l_n) = g_xml_epis_diagnoses
                THEN
                
                    dbms_lob.createtemporary(l_ri_diagnoses, TRUE);
                    dbms_xmldom.writetoclob(l_n, l_ri_diagnoses);
                END IF;
            
            ELSIF xmldom.getnodename(l_n) = g_xml_component_leaf
            THEN
            
                l_e := xmldom.makeelement(l_n);
                CASE
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_SUR_NEED_P' THEN
                        l_rs_sur_need   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_sur_need_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_LOC_SURGERY_P' THEN
                        l_rs_loc_surgery   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_loc_surgery_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_SPEC_SURGERY_P' THEN
                        l_rs_spec_surgery   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_spec_surgery_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_DEPARTMENT_P' THEN
                        l_rs_department := xmldom.getattribute(l_e, g_xml_value);
                        --                        l_rs_spec_surgery_l := xmldom.getattribute(l_e, g_xml_alt_value);
                
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_CLIN_SERVICE_P' THEN
                        l_rs_clin_service := xmldom.getattribute(l_e, g_xml_value);
                        -- l_rs_spec_surgery_l := xmldom.getattribute(l_e, g_xml_alt_value);
                
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_PREF_SURG_P' THEN
                        l_rs_pref_surg := xmldom.getattribute(l_e, g_xml_value);
                    
                        tbl_pref_surgeons.extend;
                        tbl_pref_surgeons(1) := l_rs_pref_surg;
                    
                        childnodes := xmldom.getchildnodes(l_n);
                    
                        len := dbms_xmldom.getlength(childnodes);
                    
                        FOR i IN 0 .. len - 1
                        LOOP
                        
                            n              := dbms_xmldom.item(childnodes, i);
                            l_e1           := xmldom.makeelement(n);
                            l_rs_pref_surg := xmldom.getattribute(l_e1, g_xml_value);
                        
                            tbl_pref_surgeons.extend;
                            tbl_pref_surgeons(i + 2) := l_rs_pref_surg;
                        
                        END LOOP;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_PROC_SURG_P' THEN
                        l_rs_proc_surg   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_proc_surg_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_GLOBAL_ANESTH_P' THEN
                        l_rs_glb_anesth   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_glb_anesth_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_LOCAL_ANESTH_P' THEN
                        l_rs_lcl_anesth   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_lcl_anesth_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_PREV_DURATION_P' THEN
                        l_rs_prev_duration   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_prev_duration_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                        CASE l_rs_prev_duration_l
                            WHEN 1039 THEN
                                l_rs_prev_duration := l_rs_prev_duration * 24 * 60;
                            WHEN 10374 THEN
                                l_rs_prev_duration := l_rs_prev_duration;
                            ELSE
                                l_rs_prev_duration := l_rs_prev_duration * 60;
                        END CASE;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_UCI_P' THEN
                        l_rs_uci   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_uci_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_UCI_POS_P' THEN
                        l_rs_uci_pos   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_uci_pos_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_EXT_SPEC_P' THEN
                        l_rs_ext_spec := xmldom.getattribute(l_e, g_xml_value);
                    
                        tbl_ext_serv.extend;
                        tbl_ext_serv(1) := l_rs_ext_spec;
                    
                        childnodes := xmldom.getchildnodes(l_n);
                    
                        len := dbms_xmldom.getlength(childnodes);
                    
                        FOR i IN 0 .. len - 1
                        LOOP
                        
                            n             := dbms_xmldom.item(childnodes, i);
                            l_e1          := xmldom.makeelement(n);
                            l_rs_ext_spec := xmldom.getattribute(l_e1, g_xml_value);
                        
                            tbl_ext_serv.extend;
                            tbl_ext_serv(i + 2) := l_rs_ext_spec;
                        
                        END LOOP;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_CONT_DANGER_P' THEN
                        l_rs_cont_danger_prev := xmldom.getattribute(l_e, g_xml_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_PREF_TIME_P' THEN
                        l_rs_pref_time := xmldom.getattribute(l_e, g_xml_value);
                    
                        tbl_pref_time.extend;
                        tbl_pref_time(1) := get_value_from_time_pref(l_rs_pref_time);
                    
                        childnodes := xmldom.getchildnodes(l_n);
                    
                        len := dbms_xmldom.getlength(childnodes);
                    
                        FOR i IN 0 .. len - 1
                        LOOP
                        
                            n              := dbms_xmldom.item(childnodes, i);
                            l_e1           := xmldom.makeelement(n);
                            l_rs_pref_time := xmldom.getattribute(l_e1, g_xml_value);
                        
                            tbl_pref_time.extend;
                            tbl_pref_time(i + 2) := get_value_from_time_pref(l_rs_pref_time);
                        
                        END LOOP;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_MOT_PREF_TIME_P' THEN
                        l_rs_mot_pref_time   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_mot_pref_time_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RS_NOTES_P' THEN
                        l_rs_notes   := xmldom.getattribute(l_e, g_xml_value);
                        l_rs_notes_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RV_REQUEST_P' THEN
                        l_rv_request   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_request_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RV_DT_VERIF_P' THEN
                        l_rv_dt_verif   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_dt_verif_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RV_NOTES_REQ_P' THEN
                        l_rv_notes_req   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_notes_req_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RV_DECISION_P' THEN
                        l_rv_decision   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_decision_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RV_VALID_P' THEN
                        l_rv_valid   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_valid_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RV_NOTES_DECIS_P' THEN
                        l_rv_notes_decis   := xmldom.getattribute(l_e, g_xml_value);
                        l_rv_notes_decis_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RSP_LVL_URG_P' THEN
                        l_rsp_lvl_urg   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_lvl_urg_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RSP_BEGIN_SCHED_P' THEN
                        l_rsp_begin_sched   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_begin_sched_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RSP_END_SCHED_P' THEN
                        l_rsp_end_sched   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_end_sched_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RSP_TIME_MIN_P' THEN
                        l_rsp_time_min   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_time_min_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                        IF l_rsp_time_min_l = 10373 --YEAR
                        THEN
                        
                            l_rsp_time_min   := l_rsp_time_min * 365;
                            l_rsp_time_min_l := 1039;
                        
                        ELSIF l_rsp_time_min_l = 1127 --MONTH
                        THEN
                        
                            l_rsp_time_min   := l_rsp_time_min * 30;
                            l_rsp_time_min_l := 1039;
                        
                        ELSIF l_rsp_time_min_l = 10375 --WEEK
                        THEN
                        
                            l_rsp_time_min   := l_rsp_time_min * 7;
                            l_rsp_time_min_l := 1039;
                        
                        END IF;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RSP_SUGG_DT_SURG_P' THEN
                        l_rsp_sugg_dt_surg   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_sugg_dt_surg_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) = 'RSP_SUGG_DT_INT_P' THEN
                        l_rsp_sugg_dt_int   := xmldom.getattribute(l_e, g_xml_value);
                        l_rsp_sugg_dt_int_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) LIKE 'RIP_BEGIN_PER_P%' THEN
                        l_rip_begin_per   := xmldom.getattribute(l_e, g_xml_value);
                        l_rip_begin_per_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                        tbl_rip_begin.extend;
                        tbl_rip_begin(tbl_rip_begin.count) := l_rip_begin_per;
                    
                    WHEN xmldom.getattribute(l_e, g_xml_internal_name) LIKE 'RIP_END_PER_P%' THEN
                        l_rip_end_per   := xmldom.getattribute(l_e, g_xml_value);
                        l_rip_end_per_l := xmldom.getattribute(l_e, g_xml_alt_value);
                    
                        tbl_rip_end.extend;
                        tbl_rip_end(tbl_rip_end.count) := l_rip_end_per;
                    
                    ELSE
                        NULL;
                END CASE;
            
            END IF;
        
            --Different procedures may have different teams.        
            r_tbl_prof   := table_number();
            r_tbl_catg   := table_number();
            r_tbl_status := table_varchar();
        
        END LOOP;
    
        IF l_rs_cont_danger_prev IS NOT NULL
        THEN
        
            IF NOT get_previous_diagnosis(i_lang           => i_lang,
                                          i_prof           => i_prof,
                                          i_ri_diagnosis   => nvl(l_rs_cont_danger, l_rs_cont_danger_l),
                                          i_id_diag_prev   => l_rs_cont_danger_prev,
                                          i_diag_epis_type => l_diag_epis_type_cont)
            THEN
            
                g_error := 'CALL PK_WTL_API_UI.SET_ADM_SURG_REQUEST';
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
            
            END IF;
        END IF;
    
        IF io_id_waiting_list IS NOT NULL
        THEN
        
            BEGIN
                SELECT wtle.id_episode
                  INTO io_id_episode_sr
                  FROM wtl_epis wtle
                 WHERE wtle.id_waiting_list = io_id_waiting_list
                   AND wtle.id_epis_type = l_epis_type_sr;
            EXCEPTION
                WHEN no_data_found THEN
                    io_id_episode_sr := NULL;
            END;
        
            IF io_id_episode_sr IS NOT NULL
            THEN
                SELECT sei.id_sr_epis_interv, sei.id_sr_intervention
                  BULK COLLECT
                  INTO tbl_sr_epis_interv_int, tbl_sr_intervention
                  FROM sr_epis_interv sei
                 WHERE sei.id_episode_context = io_id_episode_sr;
            
                --tbl_sr_proc_value
                tbl_sr_epis_interv := table_number();
                FOR i IN 1 .. tbl_sr_proc_value.count
                LOOP
                    tbl_sr_epis_interv.extend;
                    idx := pk_utils.search_table_number(i_table  => tbl_sr_intervention,
                                                        i_search => tbl_sr_proc_value(i));
                    IF idx > 0
                    THEN
                        tbl_sr_epis_interv(i) := tbl_sr_epis_interv_int(idx);
                    ELSE
                        tbl_sr_epis_interv(i) := NULL;
                    END IF;
                END LOOP;
            
            END IF;
        
            BEGIN
                SELECT wtle.id_episode
                  INTO io_id_episode_inp
                  FROM wtl_epis wtle
                 WHERE wtle.id_waiting_list = io_id_waiting_list
                   AND wtle.id_epis_type = l_epis_type_inp;
            EXCEPTION
                WHEN no_data_found THEN
                    io_id_episode_inp := NULL;
            END;
        END IF;
    
        IF NOT pk_wtl_pbl_core.set_adm_surg_request(i_lang                    => i_lang,
                                               i_prof                    => i_prof,
                                               i_id_patient              => i_id_patient,
                                               i_id_episode              => i_id_episode,
                                               io_id_episode_sr          => io_id_episode_sr,
                                               io_id_episode_inp         => io_id_episode_inp,
                                               io_id_waiting_list        => io_id_waiting_list,
                                               i_flg_type                => 'S',
                                               i_id_wtl_urg_level        => nvl(l_rsp_lvl_urg, l_rsp_lvl_urg_l),
                                               i_dt_sched_period_start   => nvl(l_rsp_begin_sched, l_rsp_begin_sched_l),
                                               i_dt_sched_period_end     => nvl(l_rsp_end_sched, l_rsp_end_sched_l),
                                               i_min_inform_time         => l_rsp_time_min,
                                               i_dt_surgery              => nvl(l_rsp_sugg_dt_surg, l_rsp_sugg_dt_surg_l),
                                               i_unav_period_start       => tbl_rip_begin,
                                               i_unav_period_end         => tbl_rip_end,
                                               i_pref_surgeons           => tbl_pref_surgeons,
                                               i_external_dcs            => tbl_ext_serv,
                                               i_dep_clin_serv_sr        => table_number(l_rs_clin_service),
                                               i_speciality_sr           => table_number(l_rs_spec_surgery),
                                               i_department_sr           => table_number(l_rs_department),
                                               i_flg_pref_time           => tbl_pref_time,
                                               i_reason_pref_time        => table_number(nvl(l_rs_mot_pref_time,
                                                                                             l_rs_mot_pref_time_l)),
                                               i_id_sr_intervention      => tbl_sr_proc_value,
                                               i_flg_principal           => tbl_sr_proc_type,
                                               i_codification            => tbl_sr_proc_codification,
                                               i_flg_laterality          => tbl_sr_proc_laterality,
                                               i_surgical_site           => tbl_sr_proc_ss,
                                               i_sp_notes                => tbl_sr_proc_notes,
                                               i_duration                => l_rs_prev_duration,
                                               i_icu                     => l_rs_uci_l,
                                               i_icu_pos                 => l_rs_uci_pos_l,
                                               i_notes_surg              => nvl(l_rs_notes, l_rs_notes_l),
                                               i_adm_needed              => 'N',
                                               i_id_sr_pos_status        => NULL,
                                               i_surg_needed             => nvl(l_rs_sur_need, l_rs_sur_need_l),
                                               i_adm_indication          => nvl(l_ri_reason_admission, l_ri_reason_admission_l),
                                               i_dest_inst               => nvl(l_rs_loc_surgery, l_rs_loc_surgery_l),
                                               i_adm_type                => nvl(l_rs_type_int, l_rs_type_int_l),
                                               i_department              => nvl(l_ri_serv_adm, l_ri_serv_adm_l),
                                               i_room_type               => nvl(l_ri_type_room, l_ri_type_room_l),
                                               i_dep_clin_serv_adm       => nvl(l_ri_esp_int, l_ri_esp_int_l),
                                               i_pref_room               => nvl(l_ri_pref_room, l_ri_pref_room_l),
                                               i_mixed_nursing           => nvl(l_ri_mix_room, l_ri_mix_room_l),
                                               i_bed_type                => nvl(l_rs_type_bed, l_rs_type_bed_l),
                                               i_dest_prof               => nvl(l_ri_phys_adm, l_ri_phys_adm_l),
                                               i_adm_preparation         => nvl(l_ri_prepar, l_ri_prepar_l),
                                               i_dt_admission            => nvl(l_rsp_sugg_dt_int, l_rsp_sugg_dt_int_l),
                                               i_expect_duration         => nvl(l_ri_durantion, l_ri_durantion_l),
                                               i_notes_adm               => nvl(l_ri_notes, l_ri_notes_l),
                                               i_nit_flg                 => nvl(l_ri_need_nurse_cons, l_ri_need_nurse_cons_l),
                                               i_nit_dt_suggested        => nvl(l_ri_date_nurse_cons, l_ri_date_nurse_cons_l),
                                               i_nit_dcs                 => nvl(l_ri_loc_nurse_cons, l_ri_loc_nurse_cons_l),
                                               i_external_request        => NULL,
                                               i_func_eval_score         => NULL,
                                               i_notes_edit              => NULL,
                                               i_prof_cat_type           => 'D',
                                               i_doc_area                => NULL,
                                               i_doc_template            => NULL,
                                               i_epis_documentation      => NULL,
                                               i_doc_flg_type            => NULL,
                                               i_id_documentation        => NULL,
                                               i_id_doc_element          => NULL,
                                               i_id_doc_element_crit     => NULL,
                                               i_value                   => NULL,
                                               i_notes                   => NULL,
                                               i_id_doc_element_qualif   => NULL,
                                               i_epis_context            => NULL,
                                               i_summary_and_notes       => NULL,
                                               i_wtl_change              => 'N',
                                               i_profs_alert             => i_profs_alert,
                                               i_sr_pos_schedule         => NULL,
                                               i_dt_pos_suggested        => nvl(l_rv_dt_verif, l_rv_dt_verif_l),
                                               i_pos_req_notes           => nvl(l_rv_notes_req, l_rv_notes_req_l),
                                               i_decision_notes          => nvl(l_rv_notes_decis, l_rv_notes_decis_l),
                                               i_supply                  => l_ttbl_supply,
                                               i_supply_set              => l_ttbl_supply_set,
                                               i_supply_qty              => l_ttbl_supply_qty,
                                               i_supply_loc              => l_ttbl_supply_loc,
                                               i_dt_return               => l_ttbl_supply_dtr,
                                               i_supply_soft_inst        => l_ttbl_supply_soft,
                                               i_flg_cons_type           => l_ttbl_supply_fct,
                                               i_description_sp          => tbl_description_sp,
                                               i_id_sr_epis_interv       => tbl_sr_epis_interv,
                                               i_id_req_reason           => l_ttbl_supply_irr,
                                               i_supply_notes            => l_ttbl_supply_not,
                                               i_surgery_record          => tbl_sr_record,
                                               i_prof_team               => tbl_sr_proc_team,
                                               i_tbl_prof                => l_tbl_prof,
                                               i_tbl_catg                => l_tbl_catg,
                                               i_tbl_status              => l_tbl_status,
                                               i_test                    => NULL,
                                               i_diagnosis_adm_req       => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                      i_prof   => i_prof,
                                                                                                      i_params => nvl(l_ri_diagnoses,
                                                                                                                      l_ri_diagnoses_l)),
                                               i_diagnosis_surg_proc     => pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                      i_prof   => i_prof,
                                                                                                      i_params => l_tbl_sr_proc_diag),
                                               i_diagnosis_contam        => CASE
                                                                                WHEN l_rs_cont_danger_prev IS NULL THEN
                                                                                 pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                                                                           i_prof   => i_prof,
                                                                                                           i_params => nvl(l_rs_cont_danger,
                                                                                                                           l_rs_cont_danger_l))
                                                                                ELSE
                                                                                 l_diag_epis_type_cont
                                                                            END,
                                               i_id_cdr_call             => NULL,
                                               i_id_ct_io                => tbl_ct_io,
                                               i_clinical_question       => l_clinical_question,
                                               i_response                => l_response,
                                               i_clinical_question_notes => l_clinical_question_notes,
                                               i_id_inst_dest            => i_id_inst_dest,
                                               i_order_set               => pk_alert_constant.g_no,
                                               i_global_anesth           => nvl(l_rs_glb_anesth, l_rs_glb_anesth_l),
                                               i_local_anesth            => nvl(l_rs_lcl_anesth, l_rs_lcl_anesth_l),
                                               o_adm_request             => l_adm_request,
                                               o_msg_error               => o_msg_error,
                                               o_title_error             => o_title_error,
                                               o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --EDITING SR_EPIS_INTERV
        IF tbl_sr_epis_interv.count = 0
           AND l_sr_proc_value IS NOT NULL
        THEN
            SELECT sei.id_sr_epis_interv
              BULK COLLECT
              INTO tbl_sr_epis_interv
              FROM sr_epis_interv sei
             WHERE sei.id_episode_context = io_id_episode_sr;
        
            FOR i IN 1 .. tbl_sr_epis_interv.count()
            LOOP
                ts_sr_epis_interv.upd(id_sr_epis_interv_in  => tbl_sr_epis_interv(i),
                                      id_episode_in         => i_id_episode,
                                      id_sr_intervention_in => l_sr_proc_value,
                                      id_episode_context_in => io_id_episode_sr);
            END LOOP;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    END set_surgery_request;

    /********************************************************************************************
    *
    ********************************************************************************************/
    FUNCTION set_surgery_request
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_inst_dest      IN institution.id_institution%TYPE,
        io_id_episode_sr IN OUT episode.id_episode%TYPE,
        -- Waiting List
        io_id_waiting_list IN OUT waiting_list.id_waiting_list%TYPE,
        --Scheduling period
        i_id_wtl_urg_level      IN wtl_urg_level.id_wtl_urg_level%TYPE,
        i_dt_sched_period_start IN VARCHAR2,
        i_dt_sched_period_end   IN VARCHAR2,
        i_min_inform_time       IN waiting_list.min_inform_time%TYPE,
        i_dt_surgery            IN VARCHAR2,
        --Unavailability period
        i_unav_period_start IN table_varchar,
        i_unav_period_end   IN table_varchar,
        -- Surgery Request
        i_pref_surgeons      IN table_number,
        i_external_dcs       IN table_number,
        i_dep_clin_serv_sr   IN table_number,
        i_flg_pref_time      IN table_varchar,
        i_reason_pref_time   IN table_number,
        i_id_sr_intervention IN table_number,
        i_flg_principal      IN table_varchar,
        i_codification       IN table_number,
        i_flg_laterality     IN table_varchar,
        i_sp_notes           IN table_varchar,
        i_duration           IN schedule_sr.duration%TYPE,
        i_icu                IN schedule_sr.icu%TYPE,
        i_notes_surg         IN schedule_sr.notes%TYPE,
        i_id_sr_pos_status   IN sr_pos_status.id_sr_pos_status%TYPE,
        --Barthel Index Template
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_flg_type          IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_wtl_change            IN VARCHAR2,
        --Profs alert WTL incomplete
        i_profs_alert IN table_number DEFAULT NULL,
        --POS Validation Request
        i_sr_pos_schedule  IN sr_pos_schedule.id_sr_pos_schedule%TYPE,
        i_dt_pos_suggested IN VARCHAR2,
        i_pos_req_notes    IN sr_pos_schedule.req_notes%TYPE,
        --supplies
        i_supply           IN table_table_number,
        i_supply_set       IN table_table_number,
        i_supply_qty       IN table_table_number,
        i_supply_loc       IN table_table_number,
        i_dt_return        IN table_table_varchar,
        i_supply_soft_inst IN table_table_number,
        i_flg_cons_type    IN table_table_varchar,
        --
        i_description_sp    IN table_varchar,
        i_id_sr_epis_interv IN table_number,
        i_id_req_reason     IN table_table_number,
        i_supply_notes      IN table_table_varchar,
        --Team
        i_surgery_record IN table_number,
        i_prof_team      IN table_number,
        i_tbl_prof       IN table_table_number,
        i_tbl_catg       IN table_table_number,
        i_tbl_status     IN table_table_varchar,
        i_test           IN VARCHAR2,
        --Diagnosis XMLs
        i_diagnosis_surg_proc IN table_clob,
        i_diagnosis_contam    IN CLOB,
        -- clinical decision rules
        i_id_cdr_call IN cdr_call.id_cdr_call%TYPE,
        i_id_ct_io    IN table_table_varchar,
        -- Error
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception      EXCEPTION;
        l_id_episode_inp episode.id_episode%TYPE;
    BEGIN
    
        g_error := 'CALL PK_WTL_API_UI.SET_ADM_SURG_REQUEST';
        pk_alertlog.log_debug(g_error, g_package_name);
        IF NOT pk_wtl_api_ui.set_adm_surg_request(i_lang                  => i_lang,
                                                  i_prof                  => i_prof,
                                                  i_id_patient            => i_id_patient,
                                                  i_id_episode            => i_id_episode,
                                                  io_id_episode_sr        => io_id_episode_sr,
                                                  io_id_episode_inp       => l_id_episode_inp,
                                                  io_id_waiting_list      => io_id_waiting_list,
                                                  i_flg_type              => 'S',
                                                  i_id_wtl_urg_level      => i_id_wtl_urg_level,
                                                  i_dt_sched_period_start => i_dt_sched_period_start,
                                                  i_dt_sched_period_end   => i_dt_sched_period_end,
                                                  i_min_inform_time       => i_min_inform_time,
                                                  i_dt_surgery            => i_dt_surgery,
                                                  i_unav_period_start     => i_unav_period_start,
                                                  i_unav_period_end       => i_unav_period_end,
                                                  i_pref_surgeons         => i_pref_surgeons,
                                                  i_external_dcs          => i_external_dcs,
                                                  i_dep_clin_serv_sr      => i_dep_clin_serv_sr,
                                                  i_flg_pref_time         => i_flg_pref_time,
                                                  i_reason_pref_time      => i_reason_pref_time,
                                                  i_id_sr_intervention    => i_id_sr_intervention,
                                                  i_flg_principal         => i_flg_principal,
                                                  i_codification          => i_codification,
                                                  i_flg_laterality        => i_flg_laterality,
                                                  i_sp_notes              => i_sp_notes,
                                                  i_duration              => i_duration,
                                                  i_icu                   => i_icu,
                                                  i_notes_surg            => i_notes_surg,
                                                  i_adm_needed            => pk_alert_constant.get_no,
                                                  i_id_sr_pos_status      => i_id_sr_pos_status,
                                                  i_surg_needed           => pk_alert_constant.get_yes,
                                                  i_adm_indication        => NULL,
                                                  i_dest_inst             => i_inst_dest,
                                                  i_adm_type              => NULL,
                                                  i_department            => NULL,
                                                  i_room_type             => NULL,
                                                  i_dep_clin_serv_adm     => NULL,
                                                  i_pref_room             => NULL,
                                                  i_mixed_nursing         => NULL,
                                                  i_bed_type              => NULL,
                                                  i_dest_prof             => NULL,
                                                  i_adm_preparation       => NULL,
                                                  i_dt_admission          => NULL,
                                                  i_expect_duration       => NULL,
                                                  i_notes_adm             => NULL,
                                                  i_nit_flg               => NULL,
                                                  i_nit_dt_suggested      => NULL,
                                                  i_nit_dcs               => NULL,
                                                  i_external_request      => NULL,
                                                  i_func_eval_score       => NULL,
                                                  i_notes_edit            => NULL,
                                                  i_prof_cat_type         => i_prof_cat_type,
                                                  i_doc_area              => i_doc_area,
                                                  i_doc_template          => i_doc_template,
                                                  i_epis_documentation    => i_epis_documentation,
                                                  i_doc_flg_type          => i_doc_flg_type,
                                                  i_id_documentation      => i_id_documentation,
                                                  i_id_doc_element        => i_id_doc_element,
                                                  i_id_doc_element_crit   => i_id_doc_element_crit,
                                                  i_value                 => i_value,
                                                  i_notes                 => i_notes,
                                                  i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                  i_epis_context          => i_epis_context,
                                                  i_summary_and_notes     => i_summary_and_notes,
                                                  i_wtl_change            => i_wtl_change,
                                                  i_profs_alert           => i_profs_alert,
                                                  i_sr_pos_schedule       => i_sr_pos_schedule,
                                                  i_dt_pos_suggested      => i_dt_pos_suggested,
                                                  i_pos_req_notes         => i_pos_req_notes,
                                                  i_supply                => i_supply,
                                                  i_supply_set            => i_supply_set,
                                                  i_supply_qty            => i_supply_qty,
                                                  i_supply_loc            => i_supply_loc,
                                                  i_dt_return             => i_dt_return,
                                                  i_supply_soft_inst      => i_supply_soft_inst,
                                                  i_flg_cons_type         => i_flg_cons_type,
                                                  i_description_sp        => i_description_sp,
                                                  i_id_sr_epis_interv     => i_id_sr_epis_interv,
                                                  i_id_req_reason         => i_id_req_reason,
                                                  i_supply_notes          => i_supply_notes,
                                                  i_surgery_record        => i_surgery_record,
                                                  i_prof_team             => i_prof_team,
                                                  i_tbl_prof              => i_tbl_prof,
                                                  i_tbl_catg              => i_tbl_catg,
                                                  i_tbl_status            => i_tbl_status,
                                                  i_test                  => i_test,
                                                  i_diagnosis_adm_req     => NULL,
                                                  i_diagnosis_surg_proc   => i_diagnosis_surg_proc,
                                                  i_diagnosis_contam      => i_diagnosis_contam,
                                                  i_id_cdr_call           => i_id_cdr_call,
                                                  i_id_ct_io              => i_id_ct_io,
                                                  o_error                 => o_error)
        THEN
            RAISE l_exception;
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
                                              'SET_SURGERY_REQUEST',
                                              o_error);
            RETURN FALSE;
    END set_surgery_request;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_wtl_api_ui;
/
