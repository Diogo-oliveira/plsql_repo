/*-- Last Change Revision: $Rev: 2006458 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-01-21 12:14:34 +0000 (sex, 21 jan 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_viewer_checklist IS

    --k_nothing CONSTANT VARCHAR2(1 CHAR) := '';
    k_checklist_cfg CONSTANT VARCHAR2(4000) := 'MAIN_VWR_CHECKLIST';
    k_config_table  CONSTANT VARCHAR2(0050 CHAR) := 'VIEWER_CHECKLIST';

    TYPE checklist_type IS RECORD(
        h_id          NUMBER,
        h_description VARCHAR2(1000 CHAR),
        h_rank        NUMBER,
        h_title       VARCHAR2(1000 CHAR),
        h_scope       VARCHAR2(1000 CHAR),
        color         VARCHAR2(0050 CHAR),
        tt            VARCHAR2(0050 CHAR),
        code_tt       VARCHAR2(0200 CHAR),
        icon          VARCHAR2(0050 CHAR));

    CURSOR cat_c(i_flag IN VARCHAR2) IS
        SELECT id_category, flg_type
          FROM category
         WHERE flg_type = i_flag;

    -- ********************************************************************************
    FUNCTION set_checklist_h
    (
        i_id            IN NUMBER,
        i_h_description IN VARCHAR2,
        i_h_rank        IN NUMBER,
        i_h_title       IN VARCHAR2,
        i_h_scope       IN VARCHAR2
    ) RETURN checklist_type IS
        l_checklist checklist_type;
    BEGIN
        l_checklist.h_id          := i_id;
        l_checklist.h_description := i_h_description;
        l_checklist.h_rank        := i_h_rank;
        l_checklist.h_title       := i_h_title;
        l_checklist.h_scope       := i_h_scope;
    
        RETURN l_checklist;
    
    END set_checklist_h;

    -- ********************************************************************************
    FUNCTION set_checklist_completed RETURN checklist_type IS
        l_checklist checklist_type;
    BEGIN
        l_checklist.icon    := g_checklist_icon_completed;
        l_checklist.color   := g_checklist_color_white;
        l_checklist.code_tt := g_checklist_tt_completed;
    
        RETURN l_checklist;
    
    END set_checklist_completed;

    -- ********************************************************************************    
    FUNCTION set_checklist_ongoing RETURN checklist_type IS
        l_checklist checklist_type;
    BEGIN
        l_checklist.icon    := g_checklist_icon_ongoing;
        l_checklist.color   := g_checklist_color_red;
        l_checklist.code_tt := g_checklist_tt_ongoing;
    
        RETURN l_checklist;
    
    END set_checklist_ongoing;

    -- ********************************************************************************

    FUNCTION get_icon_color(i_flg_checklist IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        CASE i_flg_checklist
            WHEN pk_viewer_checklist.g_checklist_completed THEN
                RETURN g_checklist_color_white;
            WHEN pk_viewer_checklist.g_checklist_ongoing THEN
                RETURN g_checklist_color_red;
            ELSE
                RETURN NULL;
        END CASE;
    
    END get_icon_color;

    -- ******************************************************************************
    FUNCTION get_icon_name(i_flg_checklist IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
    
        CASE i_flg_checklist
            WHEN pk_viewer_checklist.g_checklist_completed THEN
                RETURN g_checklist_icon_completed;
            WHEN pk_viewer_checklist.g_checklist_ongoing THEN
                RETURN g_checklist_icon_ongoing;
            ELSE
                RETURN NULL;
        END CASE;
    
    END get_icon_name;

    -- ******************************************************************************
    FUNCTION get_icon_tooltip
    (
        i_lang          IN NUMBER,
        i_flg_checklist IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        CASE i_flg_checklist
            WHEN pk_viewer_checklist.g_checklist_completed THEN
                l_return := g_checklist_tt_completed;
            WHEN pk_viewer_checklist.g_checklist_ongoing THEN
                l_return := g_checklist_tt_ongoing;
            ELSE
                l_return := NULL;
        END CASE;
    
        l_return := pk_message.get_message(i_lang, l_return);
    
        RETURN l_return;
    
    END get_icon_tooltip;

    FUNCTION set_checklist_properties
    (
        i_lang          IN NUMBER,
        i_flg_checklist IN VARCHAR2
    ) RETURN checklist_type IS
        l_checklist checklist_type;
        --l_code_msg  VARCHAR2(0200 CHAR);
    BEGIN
    
        CASE i_flg_checklist
            WHEN pk_viewer_checklist.g_checklist_completed THEN
                l_checklist := set_checklist_completed();
            WHEN pk_viewer_checklist.g_checklist_ongoing THEN
                l_checklist := set_checklist_ongoing();
            ELSE
                l_checklist := NULL;
        END CASE;
    
        IF l_checklist.code_tt IS NOT NULL
        THEN
            l_checklist.tt := pk_message.get_message(i_lang, l_checklist.code_tt);
        END IF;
    
        RETURN l_checklist;
    
    END set_checklist_properties;

    FUNCTION get_checklist_title
    (
        i_lang IN NUMBER,
        i_list IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl      table_varchar;
        l_return VARCHAR2(4000);
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang, code_checklist_title)
          BULK COLLECT
          INTO tbl
          FROM viewer_checklist
         WHERE id_viewer_checklist = i_list;
    
        IF tbl.count > 0
        THEN
            l_return := tbl(1);
        END IF;
    
        RETURN l_return;
    
    END get_checklist_title;

    /*
    * Returns value of checklist item for a checklist selected
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         Episode id
    * @param i_id_patient         Patient id
    * @param i_scope              Scope E-Episode, V-Visit, P-Patient
    * @param o_viewer_checklist   All items for the checklist
    * @param o_title              Title of checklist
    *
    * @author                Carlos Ferreira
    * @version               2.7.1
    * @since                 2017/02/**
    */
    -- ****************************
    FUNCTION get_viewer_checklist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_viewer_checklist IN viewer_checklist.id_viewer_checklist%TYPE,
        o_viewer_checklist    OUT pk_types.cursor_type,
        o_title               OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_func_name CONSTANT VARCHAR2(0050 CHAR) := 'GET_VIEWER_CHECKLIST';
        t_cfg                 t_config;
        l_cat                 NUMBER;
        l_id_market           NUMBER;
        l_id_profile_template NUMBER;
    
        CURSOR vwr_c
        (
            i_config IN NUMBER,
            i_owner  IN NUMBER
        ) IS
            SELECT id_viewer_item checklist_id,
                   --coalesce(pk_translation.get_translation(i_lang, code_viewer_item), desc_alt) checklist_description,
                   coalesce(pk_translation.get_translation(i_lang, desc_alt),
                            desc_alt,
                            pk_translation.get_translation(i_lang, code_viewer_item)) checklist_description,
                   to_number(order_rank) rank,
                   execute_api,
                   nvl(flg_scope_type, flg_scope_type_vi) checklist_scope
              FROM (SELECT v.id_viewer_item,
                           vi.code_viewer_item,
                           v.desc_alt,
                           to_number(v.order_rank) order_rank,
                           v.chklist_internal_name,
                           v.execute_api,
                           vc.code_checklist_title,
                           v.flg_scope_type,
                           vi.flg_scope_type flg_scope_type_vi
                      FROM v_viewer_checklist_cfg v
                      JOIN viewer_checklist vc
                        ON vc.id_viewer_checklist = v.id_viewer_checklist
                      JOIN viewer_item vi
                        ON vi.id_viewer_item = v.id_viewer_item
                     WHERE v.id_config = i_config
                       AND v.id_inst_owner = i_owner
                       AND v.id_viewer_checklist = i_id_viewer_checklist
                       AND rownum > 0) x1
             ORDER BY x1.order_rank;
    
        t_checklist_id          table_varchar;
        t_checklist_description table_varchar;
        t_rank                  table_varchar;
        t_execute_api           table_varchar;
        t_checklist_scope       table_varchar;
    
        tbl_exec table_varchar := table_varchar();
    
    BEGIN
    
        l_id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                 i_id_institution => i_prof.institution);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
        l_cat                 := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        -- obtain configuration
        t_cfg := pk_core_config.get_config(i_area             => k_config_table,
                                           i_prof             => i_prof,
                                           i_market           => l_id_market,
                                           i_category         => l_cat,
                                           i_profile_template => l_id_profile_template,
                                           i_prof_dcs         => NULL,
                                           i_episode_dcs      => NULL);
    
        o_title := get_checklist_title(i_lang => i_lang, i_list => i_id_viewer_checklist);
    
        OPEN vwr_c(t_cfg.id_config, t_cfg.id_inst_owner);
    
        FETCH vwr_c BULK COLLECT
            INTO t_checklist_id, t_checklist_description, t_rank, t_execute_api, t_checklist_scope;
        CLOSE vwr_c;
    
        <<lup_thru_checklist>>
        FOR i IN 1 .. t_checklist_id.count
        LOOP
        
            tbl_exec.extend;
            tbl_exec(i) := pk_vwr_checklist_api.execute(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_api_name   => t_execute_api(i),
                                                        i_scope_type => t_checklist_scope(i),
                                                        i_id_episode => i_id_episode,
                                                        i_id_patient => i_id_patient);
        
        END LOOP lup_thru_checklist;
    
        OPEN o_viewer_checklist FOR
            SELECT checklist_id,
                   checklist_description,
                   get_icon_color(checklist_status) checklist_icon_color,
                   get_icon_name(checklist_status) checklist_icon_name,
                   get_icon_tooltip(i_lang, checklist_status) checklist_icon_tooltip,
                   t_cfg.id_config id_config,
                   t_cfg.id_inst_owner id_inst_owner
              FROM (SELECT r11.checklist_id, r22.checklist_description, r44.execute_api checklist_status
                      FROM (SELECT /*+ opt_estimate( table r1 rows=1) */
                             rownum rn, column_value checklist_id
                              FROM TABLE(t_checklist_id) r1) r11
                      JOIN (SELECT /*+ opt_estimate( table r2 rows=1) */
                            rownum rn, column_value checklist_description
                             FROM TABLE(t_checklist_description) r2) r22
                        ON r11.rn = r22.rn
                      JOIN (SELECT /*+ opt_estimate( table r4 rows=1) */
                            rownum rn, column_value execute_api
                             FROM TABLE(tbl_exec) r4) r44
                        ON r11.rn = r44.rn) xmain;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              k_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_viewer_checklist);
            RETURN FALSE;
        
    END get_viewer_checklist;

    FUNCTION get_viewer_checklist_bck
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_viewer_checklist IN viewer_checklist.id_viewer_checklist%TYPE,
        o_viewer_checklist    OUT pk_types.cursor_type,
        o_title               OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        k_func_name CONSTANT VARCHAR2(0050 CHAR) := 'GET_VIEWER_CHECKLIST';
        t_cfg                 t_config;
        l_cat                 NUMBER;
        l_id_market           NUMBER;
        l_id_profile_template NUMBER;
    BEGIN
    
        l_id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                 i_id_institution => i_prof.institution);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
        l_cat                 := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        -- obtain configuração
        t_cfg := pk_core_config.get_config(i_area             => k_config_table,
                                           i_prof             => i_prof,
                                           i_market           => l_id_market,
                                           i_category         => l_cat,
                                           i_profile_template => l_id_profile_template,
                                           i_prof_dcs         => NULL,
                                           i_episode_dcs      => NULL);
    
        o_title := get_checklist_title(i_lang => i_lang, i_list => i_id_viewer_checklist);
    
        -- Return list of items 
        OPEN o_viewer_checklist FOR
            SELECT checklist_id,
                   checklist_description,
                   get_icon_color(checklist_status) checklist_icon_color,
                   get_icon_name(checklist_status) checklist_icon_name,
                   get_icon_tooltip(i_lang, checklist_status) checklist_icon_tooltip
              FROM (SELECT id_viewer_item checklist_id,
                           nvl(pk_translation.get_translation(i_lang, code_viewer_item), desc_alt) checklist_description,
                           to_number(order_rank) rank,
                           pk_vwr_checklist_api.execute(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_api_name   => execute_api,
                                                        i_scope_type => nvl(flg_scope_type, flg_scope_type_vi),
                                                        i_id_episode => i_id_episode,
                                                        i_id_patient => i_id_patient) checklist_status,
                           nvl(flg_scope_type, flg_scope_type_vi) checklist_scope
                      FROM (SELECT v.id_viewer_item,
                                   vi.code_viewer_item,
                                   v.desc_alt,
                                   v.order_rank,
                                   v.chklist_internal_name,
                                   v.execute_api,
                                   vc.code_checklist_title,
                                   v.flg_scope_type,
                                   vi.flg_scope_type flg_scope_type_vi
                              FROM v_viewer_checklist_cfg v
                              JOIN viewer_checklist vc
                                ON vc.id_viewer_checklist = v.id_viewer_checklist
                              JOIN viewer_item vi
                                ON vi.id_viewer_item = v.id_viewer_item
                             WHERE v.id_config = t_cfg.id_config
                               AND v.id_inst_owner = t_cfg.id_inst_owner
                               AND v.id_viewer_checklist = i_id_viewer_checklist) x1) xsql
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              k_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_viewer_checklist);
        
            RETURN FALSE;
        
    END get_viewer_checklist_bck;

    /**
    * Returns all checklist configured
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param o_menu               All checklists
    *
    * @author                Jorge Silva
    * @version               2.6.5
    * @since                 2015/02/06
    */
    FUNCTION get_viewer_checklist_menu
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_menu  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        k_func_name CONSTANT VARCHAR2(0050 CHAR) := 'GET_VIEWER_CHECKLIST_MENU';
        t_cfg                 t_config;
        l_cat                 NUMBER;
        l_id_market           NUMBER;
        l_id_profile_template NUMBER;
        k_cfg_table CONSTANT VARCHAR2(0050 CHAR) := 'MAIN_VWR_CHECKLIST';
    BEGIN
        l_id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                 i_id_institution => i_prof.institution);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
        l_cat                 := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        -- obtain configuração
        t_cfg := pk_core_config.get_config(i_area             => k_cfg_table,
                                           i_prof             => i_prof,
                                           i_market           => l_id_market,
                                           i_category         => l_cat,
                                           i_profile_template => l_id_profile_template,
                                           i_prof_dcs         => NULL,
                                           i_episode_dcs      => NULL);

        OPEN o_menu FOR
            SELECT id_viewer_checklist checklist_menu_id,
                   pk_translation.get_translation(i_lang, code_checklist_title) checklist_menu_description,
                   af.file_name || '.' || af.file_extension checklist_file_name
                   --,'N' checklist_menu_child,
                   --0 checklist_menu_parent_id
                  ,
                   flg_default
              FROM (SELECT vc.id_viewer_checklist,
                           vc.code_checklist_title,
                           vc.id_application_file,
                           to_number(v.order_rank) order_rank,
                           v.flg_default
                      FROM v_main_vwr_checklist_cfg v
                      JOIN viewer_checklist vc
                        ON v.id_record = vc.id_viewer_checklist
                     WHERE v.id_config = t_cfg.id_config
                       AND v.id_inst_owner = t_cfg.id_inst_owner) xsql
              JOIN application_file af
                ON af.id_application_file = xsql.id_application_file
             ORDER BY order_rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              k_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_menu);
            RETURN FALSE;
    END get_viewer_checklist_menu;

    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- **********************************************************
    -- ************************************************************
    FUNCTION get_id_checklist_item
    (
        i_checklist IN NUMBER,
        i_item      IN NUMBER
    ) RETURN table_number IS
        tbl_id table_number;
    BEGIN
    
        SELECT vci.id_viewer_checklist_item
          BULK COLLECT
          INTO tbl_id
          FROM viewer_checklist_item vci
         WHERE vci.id_viewer_checklist = i_checklist
           AND vci.id_viewer_item = i_item;
    
        RETURN tbl_id;
    
    END get_id_checklist_item;

    -- ************************************************************
    FUNCTION insert_checklist_item
    (
        i_checklist IN NUMBER,
        i_item      IN NUMBER
    ) RETURN NUMBER IS
        l_id NUMBER;
    BEGIN
    
        l_id := seq_viewer_checklist_item.nextval;
    
        INSERT INTO viewer_checklist_item
            (id_viewer_checklist_item, id_viewer_item, id_viewer_checklist)
        VALUES
            (l_id, i_item, i_checklist);
    
        RETURN l_id;
    
    END insert_checklist_item;

    -- *************************************************************
    FUNCTION ins_checklist_item
    (
        i_checklist IN NUMBER,
        i_item      IN NUMBER
    ) RETURN NUMBER IS
        tbl_id table_number;
        l_id   NUMBER;
    BEGIN
    
        tbl_id := get_id_checklist_item(i_checklist => i_checklist, i_item => i_item);
    
        IF tbl_id.count = 0
        THEN
        
            l_id := insert_checklist_item(i_checklist => i_checklist, i_item => i_item);
        
        ELSE
        
            l_id := tbl_id(1);
        
        END IF;
    
        RETURN l_id;
    
    END ins_checklist_item;

    -- *************************************************************************************
    -- *************************************************************************************
    PROCEDURE ins_cfg_table
    (
        i_id_checklist   IN NUMBER,
        i_id_item        IN NUMBER,
        i_id_config      IN NUMBER,
        i_flg_scope_type IN VARCHAR2 DEFAULT NULL,
        i_desc_alt       IN VARCHAR2 DEFAULT NULL,
        i_order_rank     IN VARCHAR2,
        i_id_inst_owner  IN NUMBER DEFAULT k_zero_value
    ) IS
        l_id_record NUMBER;
    BEGIN
    
        l_id_record := ins_checklist_item(i_checklist => i_id_checklist, i_item => i_id_item);
    
        pk_core_config.insert_into_config_table(i_config_table  => k_config_table,
                                                i_id_record     => l_id_record,
                                                i_id_inst_owner => i_id_inst_owner,
                                                i_id_config     => i_id_config,
                                                i_field_01      => i_flg_scope_type -- FLG_SCOPE_TYPE
                                               ,
                                                i_field_02      => i_desc_alt -- DESC_ALT
                                               ,
                                                i_field_03      => i_order_rank -- ORDER_RANK
                                                );
    
    END ins_cfg_table;

    FUNCTION insert_into_config_cat
    (
        i_market            IN NUMBER DEFAULT k_zero_value,
        i_id_config         IN NUMBER DEFAULT NULL,
        i_software          IN NUMBER DEFAULT k_zero_value,
        i_category          IN NUMBER DEFAULT k_zero_value,
        i_config_parent     IN NUMBER DEFAULT NULL,
        i_inst_owner_parent IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
    BEGIN
    
        RETURN pk_core_config.insert_into_config(i_market            => i_market,
                                                 i_inst_owner        => k_zero_value,
                                                 i_software          => i_software,
                                                 i_category          => i_category,
                                                 i_config_parent     => i_config_parent,
                                                 i_inst_owner_parent => i_inst_owner_parent,
                                                 i_id_config         => i_id_config);
    
    END insert_into_config_cat;

    FUNCTION get_id_vwr_item(i_name IN VARCHAR2) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT id_viewer_item
          BULK COLLECT
          INTO tbl_id
          FROM viewer_item
         WHERE item_internal_name = i_name;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_id_vwr_item;

    PROCEDURE reset_and_recreate_cfg IS
    BEGIN
    
        pk_core_config.delete_from_config_table(i_where_in => '0=0', i_config_table => 'VIEWER_CHECKLIST');
        pk_core_config.delete_from_config_table(i_where_in => '0=0', i_config_table => 'MAIN_VWR_CHECKLIST');
    
        config_vwr_4_edis_phy();
        config_vwr_4_edis_nur();
        config_vwr_4_inp_phy();
        config_vwr_4_inp_nur();
        config_vwr_4_outp_phy_nur();
        config_vwr_4_oris_phy_nur();
        config_vwr_4_pp_phy_nur();
        config_vwr_4_care_phy_nur();
        config_vwr_4_physio_all();
        config_vwr_4_rt_all();
        config_vwr_4_pha_all();
        config_vwr_4_cm_all();
        config_vwr_4_diet_all();
        config_vwr_4_social_all();
        config_vwr_4_triage_all();
    
        set_cfg_checklist();
    
        pk_core_config.recreate_ea('VIEWER_CHECKLIST');
        pk_core_config.recreate_ea('MAIN_VWR_CHECKLIST');
    
    END reset_and_recreate_cfg;

    PROCEDURE ins_vwr_checklist_cfg
    (
        i_id_vwr_checklist IN NUMBER,
        i_order_rank       IN NUMBER DEFAULT 0,
        i_flg_default      IN VARCHAR2 DEFAULT 'N',
        i_id_config        IN NUMBER,
        i_id_inst_owner    IN NUMBER
    ) IS
    BEGIN
    
        pk_core_config.insert_into_config_table(i_config_table  => k_checklist_cfg,
                                                i_id_record     => i_id_vwr_checklist,
                                                i_id_inst_owner => i_id_inst_owner,
                                                i_id_config     => i_id_config,
                                                i_field_01      => i_order_rank, -- ORDER_RANK
                                                i_field_02      => i_flg_default -- flg_default                                                
                                                );
    
    END ins_vwr_checklist_cfg;

    -- *************************************************************
    PROCEDURE set_cfg_checklist IS
        l_flg_default VARCHAR2(0001 CHAR);
        CURSOR c_rec IS
            SELECT id_viewer_checklist,
                   id_config,
                   id_inst_owner,
                   row_number() over(PARTITION BY id_config, id_inst_owner ORDER BY id_viewer_checklist) rn
              FROM (SELECT DISTINCT v.id_viewer_checklist, v.id_config, v.id_inst_owner
                      FROM v_viewer_checklist_cfg v);
    
    BEGIN
    
        FOR rec IN c_rec
        LOOP
        
            IF rec.rn = 1
            THEN
                l_flg_default := 'Y';
            ELSE
                l_flg_default := 'N';
            END IF;
        
            pk_viewer_checklist.ins_vwr_checklist_cfg(i_id_vwr_checklist => rec.id_viewer_checklist,
                                                      i_order_rank       => rec.rn,
                                                      i_flg_default      => l_flg_default,
                                                      i_id_config        => rec.id_config,
                                                      i_id_inst_owner    => rec.id_inst_owner);
        
            IF rec.rn = 2
            THEN
                pk_viewer_checklist.ins_vwr_checklist_cfg(i_id_vwr_checklist => 3,
                                                          i_order_rank       => 3,
                                                          i_flg_default      => l_flg_default,
                                                          i_id_config        => rec.id_config,
                                                          i_id_inst_owner    => rec.id_inst_owner);
            END IF;
        
        END LOOP;
    
    END set_cfg_checklist;

    -- ******************************************************************
    PROCEDURE config_vwr
    (
        i_id_config IN NUMBER,
        i_list      IN NUMBER,
        i_tbl_item  IN table_number
    ) IS
    BEGIN
    
        <<lup_thru_items>>
        FOR i IN 1 .. i_tbl_item.count
        LOOP
        
            pk_viewer_checklist.ins_cfg_table(i_id_checklist => i_list,
                                              i_id_item      => i_tbl_item(i),
                                              i_id_config    => i_id_config,
                                              i_order_rank   => i * 10);
        
        END LOOP lup_thru_items;
    
    END config_vwr;

    -- ******************************************************************
    PROCEDURE config_vwr_4_edis_phy IS
        k_software CONSTANT NUMBER := 8;
        k_category CONSTANT VARCHAR2(1 CHAR) := 'D';
        tbl_1    table_number := table_number();
        tbl_2    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        <<lup_thru_cat>>
        FOR cat_r IN cat_c(i_flag => k_category)
        LOOP
        
            l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software,
                                                                   i_category => cat_r.id_category);
        
            tbl_1 := table_number();
            tbl_2 := table_number();
        
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('CHIEF_COMPLAINT');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('TRIAGE');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('HISTORY_OF_PRESENT_ILLNESS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('REVIEW_OF_SYSTEMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('FAMILY_HISTORY');
        
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('SOCIAL_HISTORY');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('HOME_MEDICATION');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
        
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICAL_EXAM');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DIFFERENTIAL_DIAGNOSES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PLAN');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('LAB_TESTS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('IMAGING_EXAMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('OTHER_EXAMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('MEDICATIONS');
        
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PROCEDURES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PATIENT_EDUCATION');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('CO_SIGN');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_DIAGNOSIS');
        
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_SUMMARY');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICIAN_DISCHARGE');
        
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_DIAGNOSIS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('CO_SIGN');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('PHYSICIAN_DISCHARGE');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_SUMMARY');
        
            config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
            config_vwr(i_id_config => l_config, i_list => (2), i_tbl_item => tbl_2);
        
        END LOOP lup_thru_cat;
    
    END config_vwr_4_edis_phy;

    -- ******************************************************************
    PROCEDURE config_vwr_4_edis_nur IS
        k_software CONSTANT NUMBER := 8;
        k_category CONSTANT VARCHAR2(1 CHAR) := 'N';
        tbl_1    table_number := table_number();
        tbl_2    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        <<lup_thru_cat>>
        FOR cat_r IN cat_c(i_flag => k_category)
        LOOP
        
            l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software,
                                                                   i_category => cat_r.id_category);
        
            tbl_1 := table_number();
            tbl_2 := table_number();
        
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('CHIEF_COMPLAINT');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('TRIAGE');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('HISTORY_OF_PRESENT_ILLNESS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('REVIEW_OF_SYSTEMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('SOCIAL_HISTORY');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('FAMILY_HISTORY');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICAL_EXAM');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DIFFERENTIAL_DIAGNOSES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PLAN');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('MEDICATIONS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('LAB_TESTS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('IMAGING_EXAMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('OTHER_EXAMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PROCEDURES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PATIENT_EDUCATION');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_DIAGNOSIS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('CO_SIGN');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICIAN_DISCHARGE');
        
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_DIAGNOSIS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('CO_SIGN');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('PHYSICIAN_DISCHARGE');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_SUMMARY');
        
            config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
            config_vwr(i_id_config => l_config, i_list => (2), i_tbl_item => tbl_2);
        
        END LOOP lup_thru_cat;
    
    END config_vwr_4_edis_nur;

    -- ******************************************************************
    PROCEDURE config_vwr_4_inp_nur IS
        k_software CONSTANT NUMBER := 11;
        k_category CONSTANT VARCHAR2(1 CHAR) := 'N';
        tbl_1    table_number := table_number();
        tbl_2    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        <<lup_thru_cat>>
        FOR cat_r IN cat_c(i_flag => k_category)
        LOOP
        
            l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software,
                                                                   i_category => cat_r.id_category);
        
            tbl_1 := table_number();
            tbl_2 := table_number();
        
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('HISTORY_AND_PHYSICAL');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('HOME_MEDICATION');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('INITIAL_NURSING_ASSESSMENT');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DIFFERENTIAL_DIAGNOSES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PLAN');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('LAB_TESTS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('IMAGING_EXAMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('OTHER_EXAMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('MEDICATIONS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DIETS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PROCEDURES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PATIENT_EDUCATION');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_DIAGNOSIS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('CO_SIGN');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICIAN_DISCHARGE');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_SUMMARY');
        
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_DIAGNOSIS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('CO_SIGN');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('PHYSICIAN_DISCHARGE');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_SUMMARY');
        
            config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
            config_vwr(i_id_config => l_config, i_list => (2), i_tbl_item => tbl_2);
        
        END LOOP lup_thru_cat;
    
    END config_vwr_4_inp_nur;

    -- ******************************************************************
    PROCEDURE config_vwr_4_inp_phy IS
        k_software CONSTANT NUMBER := 11;
        k_category CONSTANT VARCHAR2(1 CHAR) := 'D';
        tbl_1    table_number := table_number();
        tbl_2    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        <<lup_thru_cat>>
        FOR cat_r IN cat_c(i_flag => k_category)
        LOOP
        
            l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software,
                                                                   i_category => cat_r.id_category);
        
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('HISTORY_AND_PHYSICAL');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('HOME_MEDICATION');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DIFFERENTIAL_DIAGNOSES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PLAN');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('LAB_TESTS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('IMAGING_EXAMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('OTHER_EXAMS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('MEDICATIONS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DIETS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PROCEDURES');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PATIENT_EDUCATION');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_DIAGNOSIS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('CO_SIGN');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICIAN_DISCHARGE');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
            tbl_1.extend;
            tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_SUMMARY');
        
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_DIAGNOSIS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('CO_SIGN');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('PHYSICIAN_DISCHARGE');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
            tbl_2.extend;
            tbl_2(tbl_2.count) := get_id_vwr_item('DISCHARGE_SUMMARY');
        
            config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
            config_vwr(i_id_config => l_config, i_list => (2), i_tbl_item => tbl_2);
        
        END LOOP lup_thru_cat;
    
    END config_vwr_4_inp_phy;

    -- ******************************************************************
    PROCEDURE config_vwr_4_outp_phy_nur IS
        k_software CONSTANT NUMBER := 1;
        tbl_category table_varchar := table_varchar('D', 'N');
        tbl_1        table_number := table_number();
        l_config     NUMBER;
    BEGIN
    
        <<lup_thru_flags>>
        FOR i IN 1 .. tbl_category.count
        LOOP
        
            <<lup_thru_cat>>
            FOR cat_r IN cat_c(i_flag => tbl_category(i))
            LOOP
            
                l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software,
                                                                       i_category => cat_r.id_category);
            
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('REASON_FOR_VISIT');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('HISTORY_OF_PRESENT_ILLNESS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('REVIEW_OF_SYSTEMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('SOCIAL_HISTORY');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('FAMILY_HISTORY');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('HOME_MEDICATION');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICAL_EXAM');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('DIFFERENTIAL_DIAGNOSES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PLAN');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('MEDICATIONS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('LAB_TESTS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('IMAGING_EXAMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('OTHER_EXAMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PATIENT_EDUCATION');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PROCEDURES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('CO_SIGN');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('VISIT_NOTE');
            
                config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
            
            END LOOP lup_thru_cat;
        
        END LOOP lup_thru_flags;
    
    END config_vwr_4_outp_phy_nur;

    -- ******************************************************************
    PROCEDURE config_vwr_4_oris_phy_nur IS
        k_software CONSTANT NUMBER := 2;
        tbl_category table_varchar := table_varchar('D', 'N');
        tbl_1        table_number := table_number();
        l_config     NUMBER;
    BEGIN
    
        <<lup_thru_flags>>
        FOR i IN 1 .. tbl_category.count
        LOOP
        
            <<lup_thru_cat>>
            FOR cat_r IN cat_c(i_flag => tbl_category(i))
            LOOP
            
                l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software,
                                                                       i_category => cat_r.id_category);
            
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PRE_OPERATIVE');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PROPOSED_SURGERY');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PRE_OPERATIVE_ASSESSMENT');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('POSITIONINGS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('SURGICAL_SUPPLIES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('RESERVES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('INTRA_OPERATIVE_ASSESSMENT');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('INTERVENTION_RECORDS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('POST_OPERATIVE_ASSESSMENT');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICIAN_DISCHARGE');
            
                config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
            
            END LOOP lup_thru_cat;
        
        END LOOP lup_thru_flags;
    
    END config_vwr_4_oris_phy_nur;

    -- ******************************************************************
    PROCEDURE config_vwr_4_pp_phy_nur IS
        k_software CONSTANT NUMBER := 12;
        tbl_category table_varchar := table_varchar('D', 'N');
        tbl_1        table_number := table_number();
        l_config     NUMBER;
    BEGIN
    
        <<lup_thru_flags>>
        FOR i IN 1 .. tbl_category.count
        LOOP
        
            <<lup_thru_cat>>
            FOR cat_r IN cat_c(i_flag => tbl_category(i))
            LOOP
            
                l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software,
                                                                       i_category => cat_r.id_category);
            
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('REASON_FOR_VISIT');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('HISTORY_OF_PRESENT_ILLNESS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('REVIEW_OF_SYSTEMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('SOCIAL_HISTORY');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('FAMILY_HISTORY');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('HOME_MEDICATION');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICAL_EXAM');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('DIFFERENTIAL_DIAGNOSES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PLAN');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('MEDICATIONS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('LAB_TESTS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('IMAGING_EXAMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('OTHER_EXAMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PATIENT_EDUCATION');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PROCEDURES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('CO_SIGN');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('VISIT_NOTE');
            
                config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
            
            END LOOP lup_thru_cat;
        
        END LOOP lup_thru_flags;
    
    END config_vwr_4_pp_phy_nur;

    -- ******************************************************************
    PROCEDURE config_vwr_4_care_phy_nur IS
        k_software CONSTANT NUMBER := 3;
        tbl_category table_varchar := table_varchar('D', 'N');
        tbl_1        table_number := table_number();
        l_config     NUMBER;
    BEGIN
    
        <<lup_thru_flags>>
        FOR i IN 1 .. tbl_category.count
        LOOP
        
            <<lup_thru_cat>>
            FOR cat_r IN cat_c(i_flag => tbl_category(i))
            LOOP
            
                l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software,
                                                                       i_category => cat_r.id_category);
            
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('REASON_FOR_VISIT');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('HISTORY_OF_PRESENT_ILLNESS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('REVIEW_OF_SYSTEMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('SOCIAL_HISTORY');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('FAMILY_HISTORY');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('HOME_MEDICATION');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PHYSICAL_EXAM');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('DIAGNOSES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('IMMUNIZATION_STATUS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PLAN');
            
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('LAB_TEST_REFERRALS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('IMAGING_EXAM_REFERRALS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('OTHER_EXAM_REFERRALS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('PROCEDURES');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_MEDICATIONS');
                tbl_1.extend;
                tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
            
                config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
            
            END LOOP lup_thru_cat;
        
        END LOOP lup_thru_flags;
    
    END config_vwr_4_care_phy_nur;

    -- ******************************************************************
    PROCEDURE config_vwr_4_physio_all IS
        k_software CONSTANT NUMBER := 36;
        tbl_1    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software, i_category => 0);
    
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('CLINICAL_INDICATION_FOR_REHABILITATION');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('TREATMENT_SESSION');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PATIENT_EDUCATION');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
    
        config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
    
    END config_vwr_4_physio_all;

    -- ******************************************************************
    PROCEDURE config_vwr_4_rt_all IS
        k_software CONSTANT NUMBER := 33;
        tbl_1    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software, i_category => 0);
    
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('INITIAL_RESPIRATORY_ASSESSMENT');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('OTHER_EXAMS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('MEDICATIONS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PROCEDURES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('RESPIRATORY_THERAPY_PROGRESS_NOTES');
    
        config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
    
    END config_vwr_4_rt_all;

    -- ******************************************************************
    PROCEDURE config_vwr_4_pha_all IS
        k_software CONSTANT NUMBER := 20;
        tbl_1    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software, i_category => 0);
    
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('HOME_MEDICATION');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('DIAGNOSES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('LAB_TESTS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PHARMACIST_VALIDATION');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PHARMACIST_NOTES');
    
        config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
    
    END config_vwr_4_pha_all;

    -- ******************************************************************
    PROCEDURE config_vwr_4_cm_all IS
        k_software CONSTANT NUMBER := 47;
        tbl_1    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software, i_category => 0);
    
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('CASE_MANAGEMENT_PLAN');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('CASE_MANAGEMENT_FOLLOW-UP');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('END_OF_ENCOUNTER');
    
        config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
    
    END config_vwr_4_cm_all;

    -- ******************************************************************
    PROCEDURE config_vwr_4_diet_all IS
        k_software CONSTANT NUMBER := 43;
        tbl_1    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software, i_category => 0);
    
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('INITIAL_NUTRITION_EVALUATION');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('NUTRITION_PROGRESS_NOTE');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('NUTRITION_DIAGNOSES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PLAN');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('NUTRITION_VISIT_NOTES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('NUTRITION_DISCHARGE');
    
        config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
    
    END config_vwr_4_diet_all;

    -- ******************************************************************
    PROCEDURE config_vwr_4_social_all IS
        k_software CONSTANT NUMBER := 24;
        tbl_1    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software, i_category => 0);
    
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('HOUSING');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('SOCIO_DEMOGRAPHIC_DATA');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('HOUSEHOLD_FINANCIAL_SITUATION');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('SOCIAL_DIAGNOSES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('SOCIAL_INTERVENTION_PLAN');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('FOLLOW_UP_NOTES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('SOCIAL_SERVICES_REPORT');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('SOCIAL_DISCHARGE');
    
        config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
    
    END config_vwr_4_social_all;

    -- ******************************************************************
    PROCEDURE config_vwr_4_triage_all IS
        k_software CONSTANT NUMBER := 35;
        tbl_1    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software, i_category => 0);
    
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('CHIEF_COMPLAINT');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('TRIAGE');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('ALLERGIES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('HOME_MEDICATION');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('VITAL_SIGNS_AND_INDICATORS');
    
        config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
    
    END config_vwr_4_triage_all;

    -- ******************************************************************
    PROCEDURE config_vwr_4_psycho_all IS
        k_software CONSTANT NUMBER := 310;
        tbl_1    table_number := table_number();
        l_config NUMBER;
    BEGIN
    
        l_config := pk_viewer_checklist.insert_into_config_cat(i_software => k_software, i_category => 0);
    
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('INITIAL_PSYCHOLOGY_EVALUATION');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PSYCHOLOGY_PROGRESS_NOTE');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PAST_HISTORY_PROBLEMS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PSYCHOLOGY_DIAGNOSES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PLAN');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PSYCHOLOGY_VISIT_NOTES');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('DISCHARGE_INSTRUCTIONS');
        tbl_1.extend;
        tbl_1(tbl_1.count) := get_id_vwr_item('PSYCHOLOGY_DISCHARGE');
    
        config_vwr(i_id_config => l_config, i_list => (1), i_tbl_item => tbl_1);
        --MAIN_VIEWER_CHECKLIST
        pk_core_config.insert_into_config_table(i_config_table  => k_checklist_cfg,
                                                i_id_record     => 1,
                                                i_id_inst_owner => 0,
                                                i_id_config     => l_config,
                                                i_field_01      => 1,
                                                i_field_03      => 'Y');
        pk_core_config.recreate_ea('VIEWER_CHECKLIST');
        pk_core_config.recreate_ea('MAIN_VWR_CHECKLIST');
    END config_vwr_4_psycho_all;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_viewer_checklist;
/
