CREATE OR REPLACE PACKAGE BODY pk_access_cfg IS

    PROCEDURE ins_sbp(i_row IN sys_button_prop%ROWTYPE) IS
    BEGIN
    
        INSERT INTO sys_button_prop
            (id_sys_button_prop,
             id_sys_button,
             screen_name,
             id_sys_application_area,
             id_sys_screen_area,
             flg_visible,
             rank,
             id_sys_application_type,
             id_btn_prp_parent,
             action,
             flg_enabled,
             code_title_help,
             code_desc_help,
             sub_rank,
             flg_reset_context,
             position,
             toolbar_level,
             code_msg_copyright,
             code_tooltip_title,
             code_tooltip_desc,
             flg_screen_mode,
             code_button_text)
        VALUES
            (i_row.id_sys_button_prop,
             i_row.id_sys_button,
             i_row.screen_name,
             i_row.id_sys_application_area,
             i_row.id_sys_screen_area,
             i_row.flg_visible,
             i_row.rank,
             i_row.id_sys_application_type,
             i_row.id_btn_prp_parent,
             i_row.action,
             i_row.flg_enabled,
             i_row.code_title_help,
             i_row.code_desc_help,
             i_row.sub_rank,
             i_row.flg_reset_context,
             i_row.position,
             i_row.toolbar_level,
             i_row.code_msg_copyright,
             i_row.code_tooltip_title,
             i_row.code_tooltip_desc,
             i_row.flg_screen_mode,
             i_row.code_button_text);
    
    END ins_sbp;

    --*****************************
    PROCEDURE ins_btn(i_row IN sys_button%ROWTYPE) IS
        l_row sys_button%ROWTYPE;
    
        k_code_button CONSTANT VARCHAR2(0200 CHAR) := 'SYS_BUTTON.CODE_BUTTON.';
        k_code_icon   CONSTANT VARCHAR2(0200 CHAR) := 'SYS_BUTTON.CODE_ICON.';
        k_code_title  CONSTANT VARCHAR2(0200 CHAR) := 'SYS_BUTTON.CODE_TOOLTIP_TITLE.';
        k_code_desc   CONSTANT VARCHAR2(0200 CHAR) := 'SYS_BUTTON.CODE_TOOLTIP_DESC.';
    
    BEGIN
    
        l_row.code_button        := coalesce(l_row.code_button, k_code_button || i_row.id_sys_button);
        l_row.code_icon          := coalesce(l_row.code_icon, k_code_icon || i_row.id_sys_button);
        l_row.code_tooltip_title := coalesce(l_row.code_tooltip_title, k_code_title || i_row.id_sys_button);
        l_row.code_tooltip_desc  := coalesce(l_row.code_tooltip_desc, k_code_desc || i_row.id_sys_button);
    
        INSERT INTO sys_button
            (id_sys_button,
             intern_name_button,
             code_button,
             icon,
             skin,
             flg_type,
             code_icon,
             code_intern_name,
             code_tooltip_title,
             code_tooltip_desc)
        VALUES
            (i_row.id_sys_button,
             i_row.intern_name_button,
             l_row.code_button,
             i_row.icon,
             i_row.skin,
             i_row.flg_type,
             l_row.code_icon,
             i_row.code_intern_name,
             l_row.code_tooltip_title,
             l_row.code_tooltip_desc);
    
    END ins_btn;

    PROCEDURE ins_pta(i_row IN profile_templ_access%ROWTYPE) IS
    BEGIN
    
        INSERT INTO profile_templ_access
            (id_profile_templ_access,
             id_profile_template,
             rank,
             id_sys_button_prop,
             flg_create,
             flg_cancel,
             flg_search,
             flg_print,
             flg_ok,
             flg_detail,
             flg_content,
             flg_help,
             id_sys_shortcut,
             id_software,
             id_shortcut_pk,
             id_software_context,
             flg_freq,
             flg_no,
             position,
             toolbar_level,
             flg_action,
             flg_view,
             flg_add_remove,
             flg_global_shortcut,
             age_min,
             gender,
             id_epis_type,
             age_max)
        VALUES
            (i_row.id_profile_templ_access,
             i_row.id_profile_template,
             i_row.rank,
             i_row.id_sys_button_prop,
             i_row.flg_create,
             i_row.flg_cancel,
             i_row.flg_search,
             i_row.flg_print,
             i_row.flg_ok,
             i_row.flg_detail,
             i_row.flg_content,
             i_row.flg_help,
             i_row.id_sys_shortcut,
             i_row.id_software,
             i_row.id_shortcut_pk,
             i_row.id_software_context,
             i_row.flg_freq,
             i_row.flg_no,
             i_row.position,
             i_row.toolbar_level,
             i_row.flg_action,
             i_row.flg_view,
             i_row.flg_add_remove,
             i_row.flg_global_shortcut,
             i_row.age_min,
             i_row.gender,
             i_row.id_epis_type,
             i_row.age_max);
    
    END ins_pta;

END pk_access_cfg;
