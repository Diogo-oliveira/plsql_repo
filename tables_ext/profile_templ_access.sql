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
         flg_graph,
         flg_vision,
         flg_digital,
         flg_freq,
         flg_no,
         position,
         toolbar_level,
         flg_action,
         flg_view,
         flg_add_remove,
         flg_global_shortcut)
        SELECT id_profile_templ_access,
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
               flg_graph,
               flg_vision,
               flg_digital,
               flg_freq,
               flg_no,
               position,
               toolbar_level,
               flg_action,
               flg_view,
               flg_add_remove,
               flg_global_shortcut
          FROM a_profile_templ_access a
         WHERE NOT EXISTS (SELECT 1
                  FROM profile_templ_access pta
                 WHERE pta.id_profile_templ_access = a.id_profile_templ_access);

END;
/


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
         flg_graph,
         flg_vision,
         flg_digital,
         flg_freq,
         flg_no,
         position,
         toolbar_level,
         flg_action,
         flg_view,
         flg_add_remove,
         flg_global_shortcut)
        SELECT id_profile_templ_access,
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
               flg_graph,
               flg_vision,
               flg_digital,
               flg_freq,
               flg_no,
               position,
               toolbar_level,
               flg_action,
               flg_view,
               flg_add_remove,
               flg_global_shortcut
          FROM a_profile_templ_access a
         WHERE NOT EXISTS (SELECT 1
                  FROM profile_templ_access pta
                 WHERE pta.id_profile_templ_access = a.id_profile_templ_access)
           AND a.id_profile_template IN (SELECT id_profile_template
                                           FROM profile_template);

END;
/
