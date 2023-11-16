/*-- Last Change Revision: $Rev: 1911182 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2019-08-05 14:46:25 +0100 (seg, 05 ago 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_dyn_search IS

    g_package_name VARCHAR2(1000 CHAR);
    --k_lp CONSTANT VARCHAR2(0010 CHAR) := chr(10);
    k_config_table CONSTANT VARCHAR2(0200 CHAR) := 'SEARCH_NEXT_SCREEN';

    -- ***********************************************
    PROCEDURE process_error
    (
        i_lang     IN NUMBER,
        i_err_text IN VARCHAR2,
        i_function IN VARCHAR2,
        o_error    OUT t_error_out
    ) IS
    BEGIN
    
        pk_alert_exceptions.process_error(i_lang     => i_lang,
                                          i_sqlcode  => SQLCODE,
                                          i_sqlerrm  => SQLERRM,
                                          i_message  => i_err_text,
                                          i_owner    => 'ALERT',
                                          i_package  => g_package_name,
                                          i_function => i_function,
                                          o_error    => o_error);
    
        pk_utils.undo_changes;
    
    END process_error;

    --***********************************
    FUNCTION get_id_criteria(i_tbl_ds_cmp IN table_number) RETURN table_number IS
        tbl_return table_number;
    BEGIN
    
        SELECT cdc.id_criteria
          BULK COLLECT
          INTO tbl_return
          FROM criteria_ds_cmpt_mkt cdc
          JOIN (SELECT /*+ opt_estimate (table xarray rows=1) */
                 column_value id_cmpt_mkt_rel, rownum rn
                  FROM TABLE(i_tbl_ds_cmp) xarray) xa
            ON xa.id_cmpt_mkt_rel = cdc.id_ds_cmpt_mkt_rel
         ORDER BY xa.rn;
    
        RETURN tbl_return;
    
    END get_id_criteria;

    --*****************************************
    FUNCTION map_ds_cmp_to_criteria
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_ds_cmp      IN table_number,
        o_tbl_id_criteria OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_criterias table_number := table_number();
    BEGIN
    
        tbl_criterias := get_id_criteria(i_tbl_ds_cmp => i_tbl_ds_cmp);
    
        o_tbl_id_criteria := tbl_criterias;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_err_text => SQLERRM,
                          i_function => 'MAP_DS_CMP_TO_CRITERIA',
                          o_error    => o_error);
            RETURN FALSE;
    END map_ds_cmp_to_criteria;

    --************************************
    FUNCTION get_search_next_screen_config
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_config IS
        t_cfg                 t_config;
        l_profile             profile_template%ROWTYPE;
        l_id_profile_template NUMBER;
        l_id_category         NUMBER;
        l_id_market           NUMBER;
    
        --****************************
        PROCEDURE in_inicialize IS
        BEGIN
            l_profile             := pk_access.get_profile(i_prof => i_prof);
            l_id_profile_template := l_profile.id_profile_template;
            l_id_category         := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
            l_id_market           := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        END in_inicialize;
    
        --***************************
        PROCEDURE in_get_config IS
        BEGIN
            -- obtain configuration
            t_cfg := pk_core_config.get_config(i_area             => k_config_table,
                                               i_prof             => i_prof,
                                               i_market           => l_id_market,
                                               i_category         => l_id_category,
                                               i_profile_template => l_id_profile_template,
                                               i_prof_dcs         => NULL,
                                               i_episode_dcs      => NULL);
        END in_get_config;
    
    BEGIN
        in_inicialize();
    
        in_get_config();
    
        RETURN t_cfg;
    
    END get_search_next_screen_config;

    -- ************************************************
    FUNCTION get_search_next_screen
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_id_sys_button_prop IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return   VARCHAR2(0200 CHAR);
        t_cfg      t_config;
        tbl_return table_varchar;
    
        --**********************************
        PROCEDURE in_get_next_screen IS
            k_param_name CONSTANT VARCHAR2(0200 CHAR) := 'SEARCH_NEXT_SCREEN';
        BEGIN
        
            SELECT next_screen
              BULK COLLECT
              INTO tbl_return
              FROM v_search_next_screen_cfg sns
             WHERE sns.config_table = k_config_table
               AND sns.id_config = t_cfg.id_config
               AND sns.id_inst_owner = t_cfg.id_inst_owner
               AND sns.id_sys_button_prop = i_id_sys_button_prop;
        
            IF tbl_return.count > 0
            THEN
                l_return := tbl_return(1);
            ELSE
            
                SELECT sbpp.param_value
                  BULK COLLECT
                  INTO tbl_return
                  FROM sys_button_prop_param sbpp
                 WHERE sbpp.id_sys_button_prop = i_id_sys_button_prop
                   AND sbpp.param_name = k_param_name;
            
                IF tbl_return.count > 0
                THEN
                    l_return := tbl_return(1);
                END IF;
            
            END IF;
        
        END in_get_next_screen;
    
    BEGIN
    
        t_cfg := get_search_next_screen_config(i_lang => i_lang, i_prof => i_prof);
    
        in_get_next_screen();
    
        RETURN l_return;
    
    END get_search_next_screen;

    -- SYS_BUTTON_PROP_PARAM by default if no config set
    --
    --
    FUNCTION get_search_next_screen
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_id_sys_button_prop IN NUMBER,
        o_screen_name        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        o_screen_name := get_search_next_screen(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_sys_button_prop => i_id_sys_button_prop);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_lang     => i_lang,
                          i_err_text => SQLERRM,
                          i_function => 'GET_SEARCH_NEXT_SCREEN',
                          o_error    => o_error);
            RETURN FALSE;
    END get_search_next_screen;

    -- ***************************
    PROCEDURE ins_search_next_screen_cfg
    (
        i_id_sys_button_prop IN NUMBER,
        i_next_screen        IN VARCHAR2,
        i_id_config          IN NUMBER,
        i_id_inst_owner      IN NUMBER
    ) IS
    BEGIN
    
        pk_core_config.insert_into_config_table(i_config_table  => k_config_table,
                                                i_id_record     => i_id_sys_button_prop,
                                                i_id_config     => i_id_config,
                                                i_id_inst_owner => i_id_inst_owner,
                                                i_field_01      => i_next_screen);
    
    END ins_search_next_screen_cfg;

    -- **********************************
    PROCEDURE ins_search_next_screen_cfg
    (
        i_prof                IN profissional,
        i_id_market           IN NUMBER,
        i_id_category         IN NUMBER,
        i_id_profile_template IN NUMBER,
        i_id_sys_button_prop  IN NUMBER,
        i_next_screen         IN VARCHAR2
    ) IS
        t_cfg t_config;
    BEGIN
    
        t_cfg := pk_core_config.get_config(i_area             => k_config_table,
                                           i_prof             => i_prof,
                                           i_market           => i_id_market,
                                           i_category         => i_id_category,
                                           i_profile_template => i_id_profile_template,
                                           i_prof_dcs         => NULL,
                                           i_episode_dcs      => NULL);
    
        ins_search_next_screen_cfg(i_id_sys_button_prop => i_id_sys_button_prop,
                                   i_next_screen        => i_next_screen,
                                   i_id_config          => t_cfg.id_config,
                                   i_id_inst_owner      => t_cfg.id_inst_owner);
    
    END ins_search_next_screen_cfg;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END pk_dyn_search;
/
