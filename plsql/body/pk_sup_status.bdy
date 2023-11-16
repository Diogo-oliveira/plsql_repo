/*-- Last Change Revision: $Rev: 2027769 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sup_status IS

    PROCEDURE init_status IS
        CURSOR c_sup_status IS
            SELECT *
              FROM supplies_wf_status;
    BEGIN
    
        -- initializing status ibts
        FOR i IN c_sup_status
        LOOP
            g_error := 'status ' || i.id_status;
            g_tab_status_v(i.id_status) := i.flg_status;
            g_tab_status_n(i.flg_status) := i.id_status;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
    END init_status;
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'INIT o_status_config_info';
        pk_alertlog.log_debug(g_package_name || g_error);
    
        o_status_config_info := t_rec_wf_status_info();
    
        g_error := 'SELECT wf_status_config';
        SELECT id_workflow, id_status, icon, color, rank, pk_translation.get_translation(i_lang, code_status), FUNCTION
          INTO o_status_config_info.id_workflow,
               o_status_config_info.id_status,
               o_status_config_info.icon,
               o_status_config_info.color,
               o_status_config_info.rank,
               o_status_config_info.desc_status,
               o_status_config_info.function
          FROM (SELECT wsc.id_workflow,
                       wsc.id_status,
                       nvl(wsc.icon, s.icon) icon,
                       nvl(wsc.color, s.color) color,
                       nvl(wsc.rank, s.rank) rank,
                       s.code_status code_status,
                       wsc.function
                  FROM wf_status_config wsc
                  JOIN wf_status_workflow ws
                    ON (ws.id_workflow = wsc.id_workflow AND ws.id_status = wsc.id_status)
                  JOIN wf_status s
                    ON (s.id_status = ws.id_status)
                 WHERE wsc.id_software IN (0, i_prof.software)
                   AND wsc.id_institution IN (0, i_prof.institution)
                   AND wsc.id_category = i_id_category
                   AND ws.flg_available = pk_alert_constant.g_yes
                   AND ws.id_status = i_id_status
                   AND ws.id_workflow = i_id_workflow
                   AND s.flg_available = pk_alert_constant.g_yes
                 ORDER BY id_software DESC, id_institution DESC, id_category DESC)
         WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_CONFIG',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_status_config;

    /**
    * Converts supplies status varchar into a number
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_status        Supply status to be converted
    */
    FUNCTION convert_status_n
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN supply_workflow.flg_status%TYPE
        
    ) RETURN NUMBER IS
    BEGIN
        g_error := 'RETURN converting status ' || i_status || ' to number';
        pk_alertlog.log_debug(g_package_name || g_error);
    
        RETURN g_tab_status_n(i_status);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(g_error);
            RETURN g_null;
    END convert_status_n;

    /**
    * Converts supplies status number into a varchar
    *
    * @param   i_lang          Language associated to the professional 
    * @param   i_prof          Professional, institution and software ids
    * @param   i_status        Supply status to be converted
    */
    FUNCTION convert_status_v
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_status IN wf_status.id_status%TYPE
        
    ) RETURN VARCHAR2 IS
    BEGIN
        g_error := 'RETURN converting status ' || i_status || ' to varchar';
        pk_alertlog.log_debug(g_package_name || g_error);
    
        RETURN g_tab_status_v(i_status);
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alertlog.log_error(g_error);
            RETURN g_null;
        
    END convert_status_v;
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
        
    ) RETURN VARCHAR2 IS
    
        l_icon_disp_type supplies_wf_status.flg_display_type%TYPE;
    
    BEGIN
        g_error := 'RETURN icon display_type ' || i_status;
        pk_alertlog.log_debug(g_package_name || g_error);
    
        SELECT sws.flg_display_type
          INTO l_icon_disp_type
          FROM supplies_wf_status sws
         WHERE sws.id_status = convert_status_n(i_lang, i_prof, i_status)
           AND sws.id_category = i_id_category;
    
        RETURN l_icon_disp_type;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alertlog.log_error(g_error);
            RETURN g_null;
        
    END get_icon_disp_type;

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
    ) RETURN VARCHAR2 IS
        l_icon_disp_type supplies_wf_status.flg_display_type%TYPE;
        l_icon_info      t_rec_wf_status_info;
        l_status_n       wf_status.id_status%TYPE;
        l_status_str     VARCHAR2(200);
        l_msg_status     VARCHAR2(200) := 'SUPPLY_WORKFLOW.FLG_STATUS';
        l_surgery_date   schedule_sr.dt_target_tstz%TYPE;
        l_icon_color     VARCHAR2(8 CHAR) := NULL;
        l_tooltip_text   VARCHAR2(4000 CHAR);
    
        t_error t_error_out;
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'RETURN icon display_type ' || i_status;
        pk_alertlog.log_debug(g_package_name || g_error);
        l_status_n := convert_status_n(i_lang => i_lang, i_prof => i_prof, i_status => i_status);
        g_error    := 'get_icon_disp_type';
        pk_alertlog.log_debug(g_package_name || g_error);
        l_icon_disp_type := pk_sup_status.get_icon_disp_type(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_status      => i_status,
                                                             i_id_category => i_id_category);
    
        IF NOT get_status_config(i_lang               => i_lang,
                                 i_prof               => i_prof,
                                 i_id_workflow        => i_id_workflow,
                                 i_id_status          => l_status_n,
                                 i_id_category        => i_id_category,
                                 o_status_config_info => l_icon_info,
                                 o_error              => t_error)
        THEN
        
            RETURN NULL;
        END IF;
        g_error := 'get_status_string_immediate';
        pk_alertlog.log_debug(g_package_name || g_error);
        IF (i_prof.software = pk_act_therap_constant.g_id_software_at AND
           i_id_workflow = pk_supplies_constant.g_id_workflow_at)
        THEN
            IF (i_date IS NOT NULL)
            THEN
                l_icon_disp_type := pk_alert_constant.g_display_type_date_icon;
            ELSE
                l_icon_info.color := NULL;
            END IF;
        END IF;
    
        --if the id_workflow belongs to surgical supplies workflow 
        IF l_icon_info.id_workflow = pk_supplies_constant.g_id_workflow_sr
        THEN
            g_error := 'call pk_supplies_external_api_db.get_sr_status_info for id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_supplies_external_api_db.get_sr_status_info(i_lang           => i_lang,
                                                                  i_prof           => i_prof,
                                                                  i_id_episode     => i_id_episode,
                                                                  i_date           => i_date,
                                                                  i_phar_main_grid => i_phar_main_grid,
                                                                  io_icon_info     => l_icon_info,
                                                                  io_icon_type     => l_icon_disp_type,
                                                                  o_surgery_date   => l_surgery_date,
                                                                  o_icon_color     => l_icon_color,
                                                                  o_error          => t_error)
            THEN
                RAISE l_exception;
            END IF;
        
        END IF;
    
        l_status_str := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_display_type    => l_icon_disp_type,
                                                             i_flg_state       => i_status,
                                                             i_value_text      => NULL,
                                                             i_value_date      => pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                                     nvl(l_surgery_date,
                                                                                                                         i_date),
                                                                                                                     pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                             i_value_icon      => l_msg_status,
                                                             i_shortcut        => i_shortcut,
                                                             i_back_color      => l_icon_info.color,
                                                             i_icon_color      => CASE
                                                                                      WHEN l_icon_disp_type = pk_alert_constant.g_display_type_date_icon
                                                                                           OR l_icon_info.color = pk_alert_constant.g_color_red THEN
                                                                                       pk_alert_constant.g_color_icon_light_grey
                                                                                      ELSE
                                                                                       l_icon_color
                                                                                  END,
                                                             i_message_style   => NULL,
                                                             i_message_color   => NULL,
                                                             i_flg_text_domain => NULL,
                                                             i_dt_server       => current_timestamp,
                                                             i_tooltip_text    => pk_sysdomain.get_domain(i_code_dom => l_msg_status,
                                                                                                          i_val      => i_status,
                                                                                                          i_lang     => i_lang));
    
        IF i_icon_mismatch = pk_alert_constant.g_yes
        THEN
            l_icon_info.icon := pk_supplies_constant.g_icon_supply_mismatch;
        END IF;
    
        RETURN REPLACE(l_status_str, '@', l_icon_info.icon);
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alertlog.log_error(g_error);
            RETURN g_null;
        
    END get_sup_status_string;

    /********************************************************************************************
    * Gets status configuration depending on software, institution, profile and professional functionality
    * for example, if there no exists surgery date, is another icon to show
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional ID
    * @param i_id_category            Category identifier
    * @param i_id_profile_template    Profile template identification
    * @param i_id_functionality       Functionality identification
    * @param i_status_info            Status information configured in table WF_STATUS_CONFIG
    * @param i_param                  ORIS information: 
    *                                        i_param(1) = (Y) there aren't surgery date, otherwise (N)
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
    ) RETURN t_rec_wf_status_info IS
    
        l_rec_wf_status_info t_rec_wf_status_info := t_rec_wf_status_info();
        l_check_surgery_date VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error := 'CHECK I_PARAM :';
        pk_alertlog.log_debug(g_error);
        IF i_param.exists(1)
        THEN
            l_check_surgery_date := i_param(1);
        END IF;
    
        --check if surgery date is null so is necessary change the icon for Waiting requisition
        IF l_check_surgery_date = pk_alert_constant.g_yes
        THEN
            l_rec_wf_status_info.icon  := pk_supplies_constant.g_icon_waiting_req;
            l_rec_wf_status_info.color := '';
            l_rec_wf_status_info.rank  := i_status_info.rank;
        ELSE
            l_rec_wf_status_info.icon  := i_status_info.icon;
            l_rec_wf_status_info.color := i_status_info.color;
            l_rec_wf_status_info.rank  := i_status_info.rank;
        END IF;
    
        g_error := 'PIPE ROW';
        pk_alertlog.log_debug(g_error);
    
        RETURN l_rec_wf_status_info;
    END get_wf_status_info;

BEGIN
    -- Initialization
    init_status;

END pk_sup_status;
/
