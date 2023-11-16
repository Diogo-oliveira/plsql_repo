/*-- Last Change Revision: $Rev: 2028999 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:12 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sup_status IS

    TYPE t_ibt_status_n IS TABLE OF wf_status.id_status%TYPE INDEX BY VARCHAR2(2);
    TYPE t_ibt_status_v IS TABLE OF VARCHAR2(2) INDEX BY BINARY_INTEGER;

    /**
    * Converts supplies status number into a varchar
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_status        Referral status to be converted
    */
    FUNCTION convert_status_v
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN wf_status.id_status%TYPE
        
    ) RETURN VARCHAR2;

    /**
    * Converts supplies status varchar into a number
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_status        Referral status to be converted
    */
    FUNCTION convert_status_n
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN supply_workflow.flg_status%TYPE
        
    ) RETURN NUMBER;

    /**
    * Returns the icon display type of an icon
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_status        Supply Status
    */
    FUNCTION get_icon_disp_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_status      IN supply_workflow.flg_status%TYPE,
        i_id_category IN supplies_wf_status.id_category%TYPE
        
    ) RETURN VARCHAR2;
    /**
    * Get status information without evaluating function
    *
    * @param   i_lang                 Language associated to the professional executing the request
    * @param   i_prof                 Id professional, institution and software
    * @param   i_id_workflow          Workflow identification  
    * @param   i_id_status            Status identification
    * @param   id_category            Professional category
    * @param   o_status_config_info   WF_STATUS_CONFIG data
    * @param   o_error                An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   20-03-2009
    */
    FUNCTION get_status_config
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_workflow        IN wf_status_workflow.id_workflow%TYPE,
        i_id_status          IN wf_status_workflow.id_status%TYPE,
        i_id_category        IN wf_status_config.id_category%TYPE,
        o_status_config_info OUT NOCOPY t_rec_wf_status_info,
        o_error              OUT NOCOPY t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the icon display type of an icon
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_status             Supply Status
    * @param   i_id_episode         Episode ID
    * @param   i_phar_main_grid     (Y) - function called by pharmacist main grids; (N) otherwise 
    */
    FUNCTION get_sup_status_string
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_status         IN supply_workflow.flg_status%TYPE,
        i_shortcut       IN sys_shortcut.id_sys_shortcut%TYPE,
        i_id_workflow    IN wf_workflow.id_workflow%TYPE,
        i_id_category    IN wf_status_config.id_category%TYPE,
        i_date           IN supply_workflow.dt_request%TYPE,
        i_id_episode     IN supply_workflow.id_episode%TYPE DEFAULT NULL,
        i_phar_main_grid IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_icon_mismatch  IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets status configuration depending on software, institution, profile and professional functionality
    * for example, if there no exists surgery date, is another icon to show
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID
    * @param i_id_category      Category identifier
    * @param i_id_profile_template   Profile template identification
    * @param   i_id_functionality               Functionality identification
    * @param   i_status_info        Status information configured in table WF_STATUS_CONFIG
    * @param   i_param              ORIS information: 
    *                                        i_param(1) = surgery date
    *
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Filipe Silva
    * @since                    2010/10/25
    ********************************************************************************************/

    FUNCTION get_wf_status_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_category         IN wf_status_config.id_category%TYPE,
        i_id_profile_template IN wf_status_config.id_profile_template%TYPE,
        i_id_functionality    IN wf_status_config.id_functionality%TYPE,
        i_status_info         IN t_rec_wf_status_info,
        i_param               IN table_varchar
    ) RETURN t_rec_wf_status_info;

    g_error         VARCHAR2(4000);
    g_sysdate       TIMESTAMP WITH TIME ZONE;
    g_package_name  VARCHAR2(50);
    g_package_owner VARCHAR2(50);
    g_exception EXCEPTION;
    g_retval BOOLEAN;
    g_found  BOOLEAN;

    g_null CONSTANT VARCHAR2(1) := NULL;

    g_tab_status_v t_ibt_status_v;

    g_tab_status_n t_ibt_status_n;

END pk_sup_status;
/
