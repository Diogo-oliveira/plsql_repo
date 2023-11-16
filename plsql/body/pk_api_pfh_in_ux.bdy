/*-- Last Change Revision: $Rev: 2026715 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:40 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pfh_in_ux IS

    FUNCTION create_presc_exterior
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN r_presc.id_patient%TYPE,
        i_id_episode            IN r_presc.id_epis_create%TYPE,
        i_id_product_serialized IN VARCHAR2,
        i_id_task_dependency    IN r_presc.id_task_dependency%TYPE,
        i_flg_req_origin_module IN r_presc.flg_req_origin_module%TYPE,
        i_id_presc_directions   IN r_presc.id_presc_directions%TYPE DEFAULT NULL,
        i_flg_confirm           IN VARCHAR2 DEFAULT 'Y',
        o_id_presc              OUT r_presc.id_presc%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'CREATE_PRESC_EXTERIOR';
    
    BEGIN
    
        g_error := 'PK_API_PFH_IN.CREATE_PRESC_EXTERIOR';
        IF NOT pk_api_pfh_in.create_presc_exterior(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_id_patient            => i_id_patient,
                                                   i_id_episode            => i_id_episode,
                                                   i_id_product_serialized => i_id_product_serialized,
                                                   i_id_task_dependency    => i_id_task_dependency,
                                                   i_flg_req_origin_module => i_flg_req_origin_module,
                                                   i_id_presc_directions   => i_id_presc_directions,
                                                   i_flg_confirm           => i_flg_confirm,
                                                   o_id_presc              => o_id_presc,
                                                   o_error                 => o_error)
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
                                              l_db_object_name,
                                              o_error);
        
            RETURN FALSE;
    END create_presc_exterior;

    FUNCTION create_presc_local
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN r_presc.id_patient%TYPE,
        i_id_episode            IN r_presc.id_epis_create%TYPE,
        i_id_product_serialized IN VARCHAR2,
        i_id_task_dependency    IN r_presc.id_task_dependency%TYPE,
        i_flg_req_origin_module IN r_presc.flg_req_origin_module%TYPE,
        i_id_presc_directions   IN r_presc.id_presc_directions%TYPE DEFAULT NULL,
        i_flg_confirm           IN VARCHAR2 DEFAULT 'Y',
        o_id_presc              OUT r_presc.id_presc%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'CREATE_PRESC_LOCAL';
    
    BEGIN
    
        g_error := 'PK_API_PFH_IN.CREATE_PRESC_LOCAL';
        IF NOT pk_api_pfh_in.create_presc_local(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_id_patient            => i_id_patient,
                                                i_id_episode            => i_id_episode,
                                                i_id_product_serialized => i_id_product_serialized,
                                                i_id_task_dependency    => i_id_task_dependency,
                                                i_flg_req_origin_module => i_flg_req_origin_module,
                                                i_id_presc_directions   => i_id_presc_directions,
                                                i_flg_confirm           => i_flg_confirm,
                                                o_id_presc              => o_id_presc,
                                                o_error                 => o_error)
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
                                              l_db_object_name,
                                              o_error);
        
            RETURN FALSE;
    END create_presc_local;

    /******************************************************************************************
    * This function returns builded medication unique ID - Supplier + ..._id
    * based on the product/ingred/... AND supplier 
    *
    * @author                Pedro Teixeira
    * @since                 2011/11/25
    ********************************************************************************************/
    FUNCTION get_unique_id_by_id_and_supp
    (
        i_lang        IN NUMBER,
        i_id          IN VARCHAR2,
        i_id_supplier IN VARCHAR2,
        o_id_unique   OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_api_pfh_in.get_unique_id_by_id_and_supp(i_lang, i_id, i_id_supplier, o_id_unique, o_error)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'GET_UNIQUE_ID_BY_ID_AND_SUPP',
                                              o_error);
        
            RETURN FALSE;
    END get_unique_id_by_id_and_supp;

    /******************************************************************************************
    * This function returns builded medication unique ID - Supplier + ..._id
    * based on the product/ingred/... AND supplier                 
    *
    * @author                Pedro Teixeira
    * @since                 2011/11/25
    ********************************************************************************************/
    FUNCTION get_unique_ids_by_id_and_supp
    (
        i_lang        IN NUMBER,
        i_id          IN table_varchar,
        i_id_supplier IN table_varchar,
        o_id_unique   OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_api_pfh_in.get_unique_ids_by_id_and_supp(i_lang, i_id, i_id_supplier, o_id_unique, o_error)
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UTILS',
                                              'GET_UNIQUE_IDS_BY_ID_AND_SUPP',
                                              o_error);
        
            RETURN FALSE;
    END get_unique_ids_by_id_and_supp;

    /********************************************************************************************
    * This function returns information of Home and Local medication to reports
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_EPISODE    The Episode
    * @param  i_flg_reconciliantion  Show reconciliantion
    * @param  i_flg_review           Show revision
    * @param  i_flg_home_medication  Show home medication
    * @param  i_flg_local_medication Show local medication and tasks    
    *
    * @author  Alexis Nascimento
    * @since   2013-07-22 
    *
    ********************************************************************************************/

    FUNCTION get_medication_info_4report
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_flg_reconciliantion  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_review           IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_home_medication  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_local_medication IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_presc_administ   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_presc_stat_hist  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_presc_revisions  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_local_presc_dirs IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_direction_config IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_hm_revision          OUT pk_types.cursor_type,
        o_hm_reports           OUT pk_types.cursor_type,
        o_reconciliantion_info OUT pk_types.cursor_type,
        o_local_presc          OUT pk_types.cursor_type,
        o_local_admin          OUT pk_types.cursor_type,
        o_local_admin_detail   OUT pk_types.cursor_type,
        o_presc_stat_hist      OUT pk_types.cursor_type,
        o_list_revisions       OUT pk_types.cursor_type,
        o_list_prod_revisions  OUT pk_types.cursor_type,
        o_local_presc_dirs     OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        RESULT BOOLEAN;
        l_db_object_name CONSTANT user_procedures.procedure_name%TYPE := 'GET_MEDICATION_INFO_4REPORT';
    BEGIN
        g_error := 'pk_rt_med_pfh.get_medication_info_4report';
    
        RESULT := pk_api_pfh_in.get_medication_info_4report(i_lang                 => i_lang,
                                                            i_prof                 => i_prof,
                                                            i_id_episode           => i_id_episode,
                                                            i_flg_reconciliantion  => i_flg_reconciliantion,
                                                            i_flg_review           => i_flg_review,
                                                            i_flg_home_medication  => i_flg_home_medication,
                                                            i_flg_local_medication => i_flg_local_medication,
                                                            i_flg_presc_administ   => i_flg_presc_administ,
                                                            i_flg_presc_stat_hist  => i_flg_presc_stat_hist,
                                                            i_flg_presc_revisions  => i_flg_presc_revisions,
                                                            i_flg_local_presc_dirs => i_flg_local_presc_dirs,
                                                            i_flg_direction_config => i_flg_direction_config,
                                                            o_hm_revision          => o_hm_revision,
                                                            o_hm_reports           => o_hm_reports,
                                                            o_reconciliantion_info => o_reconciliantion_info,
                                                            o_local_presc          => o_local_presc,
                                                            o_local_admin          => o_local_admin,
                                                            o_local_admin_detail   => o_local_admin_detail,
                                                            o_presc_stat_hist      => o_presc_stat_hist,
                                                            o_list_revisions       => o_list_revisions,
                                                            o_list_prod_revisions  => o_list_prod_revisions,
                                                            o_local_presc_dirs     => o_local_presc_dirs,
                                                            o_error                => o_error);
    
        RETURN RESULT;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
        
            RETURN FALSE;
            RAISE;
    END get_medication_info_4report;

    /*********************************************************************************************
    * This function returns regarding prescription pharm requests for reports
    *
    * @param  i_lang          The language id
    * @param  i_lang          The profissional
    * @param  i_id_episode    data episode
    * @param  i_id_visit      data visit
    *
    * @author  Pedro Teixeira
    * @since   2014-07-23
    *
    *********************************************************************************************/
    FUNCTION get_presc_pharm_req_report
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_visit        IN episode.id_visit%TYPE,
        o_pharm_request   OUT pk_types.cursor_type,
        o_pharm_request_h OUT pk_types.cursor_type,
        o_pharm_reply     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PRESC_PHARM_REQ_REPORT';
    
    BEGIN
        -- get pharm_request prescriptions data
        g_error := 'pk_rt_med_pfh.get_presc_pharm_req_report';
        RETURN pk_rt_med_pfh.get_presc_pharm_req_report(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_episode      => i_id_episode,
                                                        i_id_visit        => i_id_visit,
                                                        o_pharm_request   => o_pharm_request,
                                                        o_pharm_request_h => o_pharm_request_h,
                                                        o_pharm_reply     => o_pharm_reply);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RAISE;
    END;

    /********************************************************************************************
    * This function obtain the task_type_id and context for a given prescription
    *
    * @param  i_lang                     The language ID
    * @param  i_prof                     The professional array
    * @param  i_id_presc                 Prescription ID
    *
    * @param  o_lst_task_type            list of id_task_type        
    * @param  o_lst_context              list of context
    * @param  o_error                    error info      
      
    * @return                            True ou False
    *
    * @author                            CRISTINA.OLIVEIRA
    * @since                             06/07/2016
    ********************************************************************************************/
    FUNCTION get_report_data_by_presc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_presc      IN NUMBER,
        o_lst_task_type OUT table_number,
        o_lst_context   OUT table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        pk_alertlog.log_debug('INIT pk_rt_med_pfh.get_report_data_by_presc called with:' || ' i_id_presc=' ||
                              i_id_presc,
                              g_package_name);
        RETURN pk_rt_med_pfh.get_report_data_by_presc(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_id_presc      => i_id_presc,
                                                      o_lst_task_type => o_lst_task_type,
                                                      o_lst_context   => o_lst_context,
                                                      o_error         => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REPORT_DATA_BY_PRESC',
                                              o_error);
            RETURN NULL;
    END get_report_data_by_presc;

BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_pfh_in_ux;
/
