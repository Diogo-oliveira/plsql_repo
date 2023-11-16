/*-- Last Change Revision: $Rev: 1421075 $*/
/*-- Last Change by: $Author: rui.gomes $*/
/*-- Date of last change: $Date: 2012-12-07 15:15:11 +0000 (sex, 07 dez 2012) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_alert IS

    -- Author  : RUI.GOMES
    -- Created : 05-11-2012 10:57:45
    -- Purpose : Backoffice logics when managing alerts

    -- public methods
    /********************************************************************************************
    * Get Alert List Service configuration
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional array
    * @param i_service             Service ID
    * @param i_dept                Department ID
    * @param o_info                Cursor with alerts configuration information
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.3
    * @since                       2012/10/25
    ********************************************************************************************/
    FUNCTION get_service_alert_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_service IN department.id_department%TYPE,
        i_dept    IN dept.id_dept%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Alert List Service configuration
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param i_id_software         Software ID
    * @param i_id_profile_template Profile template ID            
    * @param i_id_service          Service ID
    * @param o_list                Cursor with alerts configuration information
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.3
    * @since                       2012/10/25
    ********************************************************************************************/
    FUNCTION get_serv_sys_alert_pt
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_service          IN professional.id_professional%TYPE,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Saves Service Alerts Configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution           Institution ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/08/29
    **********************************************************************************************/
    FUNCTION set_serv_alert_conf
    (
        i_lang          IN language.id_language%TYPE,
        i_service       IN department.id_department%TYPE,
        i_institution   IN department.id_institution%TYPE,
        i_template_list IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set temporary alert configuration before saving service complete information
    *
    * @param i_lang                Prefered language ID
    * @param i_institution         Institution ID
    * @param i_service             Service ID
    * @param i_profile_list        List of profiles to save
    * @param i_alert_list          List of alerts to save (synch with profiles list)
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      RMMG
    * @version                     2.6.3
    * @since                       2012/11/05
    ********************************************************************************************/
    FUNCTION set_alert_by_serv
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_service      IN department.id_department%TYPE,
        i_profile_list IN table_number,
        i_alert_list   IN table_number,
        i_flg_alert    IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * reset all professional alert configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/08/29
    **********************************************************************************************/
    FUNCTION reset_all_prof_alert
    (
        i_lang          IN language.id_language%TYPE,
        i_service       IN department.id_department%TYPE,
        i_institution   IN department.id_institution%TYPE,
        i_template_list IN table_number
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * delete service alert configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION reset_default_alerts
    (
        i_lang        IN language.id_language%TYPE,
        i_service     IN department.id_department%TYPE,
        i_institution IN department.id_institution%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get prof alert current possible configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    * @param i_id_prof                Professional ID
    * @param o_list                   Output structured Information List
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/07
    **********************************************************************************************/
    FUNCTION get_prof_serv_alert
    (
        i_lang        IN language.id_language%TYPE,
        i_service     IN table_number,
        i_institution IN department.id_institution%TYPE,
        i_id_prof     IN professional.id_professional%TYPE,
        i_flg_change  IN table_varchar,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set prof alert current possible configuration
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    * @param i_id_prof                Professional ID
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/07
    **********************************************************************************************/
    FUNCTION set_prof_serv_alert
    (
        i_lang            IN language.id_language%TYPE,
        i_service         IN table_number,
        i_institution     IN department.id_institution%TYPE,
        i_id_prof         IN professional.id_professional%TYPE,
        i_flg_change      IN table_varchar,
        i_flg_change_prof IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set prof alert current possible configuration
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_institution            Institution ID
    * @param i_id_prof                Professional ID
    * @param o_result_count           Number of profiles count
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/07
    **********************************************************************************************/
    FUNCTION check_prof_profile
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN department.id_institution%TYPE,
        i_id_prof      IN professional.id_professional%TYPE,
        i_service      IN table_number,
        i_flg_change   IN table_varchar,
        o_result_count OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Delete temporary Alerts config for the service
    *
    * @param i_lang                   Language ID
    * @param i_service                Service ID   
    * @param i_institution            Institution ID
    * @param o_error                  Error ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/19
    **********************************************************************************************/
    FUNCTION delete_service_temp_alert
    (
        i_lang        IN language.id_language%TYPE,
        i_service     IN department.id_department%TYPE,
        i_institution IN department.id_institution%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Check if professioanl associations have permissions to choose alerts
    *
    * @param i_lang                   Language ID
    * @param i_id_profissional        Professional ID   
    * @param i_institution            Institution ID
    * @param o_result                 Number of Results availabel (0 list not available, > 0 list ok)
    * @param o_error                  Error ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/20
    **********************************************************************************************/
    FUNCTION validate_alerts
    (
        i_lang            IN language.id_language%TYPE,
        i_id_profissional IN professional.id_professional%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        o_result          OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Check if professioanl associations have permissions to choose functionalities
    *
    * @param i_lang                   Language ID
    * @param i_id_profissional        Professional ID   
    * @param i_institution            Institution ID
    * @param o_result                 Number of Results availabel (0 list not available, > 0 list ok)
    * @param o_error                  Error ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2012/11/20
    **********************************************************************************************/
    FUNCTION validate_functs
    (
        i_lang            IN language.id_language%TYPE,
        i_id_profissional IN professional.id_professional%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        o_result          OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    g_flg_available VARCHAR2(1);

END pk_backoffice_alert;
/
