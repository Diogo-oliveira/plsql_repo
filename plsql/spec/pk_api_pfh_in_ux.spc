/*-- Last Change Revision: $Rev: 2028486 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:05 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pfh_in_ux IS

    r_presc      pk_rt_med_pfh.r_presc%ROWTYPE;
    r_presc_plan pk_rt_med_pfh.r_presc_plan%ROWTYPE;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns information of Home and Local medication to reports
    *
    * @param  I_LANG          The language id
    * @param  I_PROF          The profissional
    * @param  I_ID_EPISODE    The Episode
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    -- logging variables
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_error         VARCHAR2(4000);

END pk_api_pfh_in_ux;
/
