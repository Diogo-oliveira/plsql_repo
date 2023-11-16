CREATE OR REPLACE FUNCTION create_new_sys_app_area
(
    i_sys_application_area_old IN sys_application_area.id_sys_application_area%TYPE,
    i_sys_application_area_new IN sys_application_area.id_sys_application_area%TYPE,
    o_error                    OUT VARCHAR2
) RETURN BOOLEAN IS

    CURSOR c_button IS
        SELECT get_button_prop_level(s.id_sys_button_prop) btn_level,
               id_sys_button_prop,
               id_sys_button,
               screen_name,
               id_sys_application_area,
               id_sys_screen_area,
               flg_visible,
               rank,
               border_color,
               alpha,
               back_color,
               id_sys_application_type,
               id_btn_prp_parent,
               action,
               flg_enabled,
               sub_rank,
               code_title_help,
               code_desc_help,
               flg_reset_context,
               position,
               toolbar_level
          FROM sys_button_prop s
         WHERE s.id_sys_application_area = i_sys_application_area_old
        --and s.id_sys_button_prop in (7347, 8862, 7229, 8701)
         ORDER BY btn_level, s.rank, s.id_sys_button_prop;

    CURSOR c_shortcut IS
        SELECT id_sys_shortcut,
               id_sys_button_prop,
               id_software,
               intern_name,
               id_institution,
               id_parent,
               desc_shortcut,
               id_shortcut_pk
          FROM sys_shortcut
         WHERE id_sys_button_prop IN
               (SELECT id_sys_button_prop
                  FROM sys_button_prop s
                 WHERE s.id_sys_application_area = i_sys_application_area_old)
           AND id_software = 2;

    CURSOR c_profile IS
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
               flg_no
          FROM profile_templ_access
         WHERE id_profile_template = 100
           AND id_software = 2;

    g_error                    VARCHAR2(2000);
    l_id_sys_button_prop_new   sys_button_prop.id_sys_button_prop%TYPE;
    l_id_btn_prp_parent_new    sys_button_prop.id_btn_prp_parent%TYPE;
    l_id_shortcut_pk_new       sys_shortcut.id_shortcut_pk%TYPE;
    l_id_sys_shortcut_new      sys_shortcut.id_sys_shortcut%TYPE;
    l_profile_templ_access_new profile_templ_access.id_profile_templ_access%TYPE;

BEGIN

    --Obtém o ID do próximo botão
    SELECT MAX(id_sys_button_prop) + 1
      INTO l_id_sys_button_prop_new
      FROM sys_button_prop;

    FOR i IN c_button
    LOOP
    
        --Se o botão tem botão pai, obtém o novo ID
        IF i.id_btn_prp_parent IS NOT NULL
        THEN
            BEGIN
                g_error := 'GET NEW ID_BTN_PRP_PARENT';
                SELECT id_sys_button_prop_new
                  INTO l_id_btn_prp_parent_new
                  FROM rb_btn_prop
                 WHERE id_sys_button_prop_old = i.id_btn_prp_parent;
            
            EXCEPTION
                WHEN no_data_found THEN
                    o_error := pk_message.get_message(1, 'COMMON_M001') || chr(10) || 'CREATE_NEW_SYS_APP_AREA / ' ||
                               g_error || ' / ' || SQLERRM;
                    ROLLBACK;
                    RETURN FALSE;
                
            END;
        ELSE
            l_id_btn_prp_parent_new := NULL;
        END IF;
    
        --Cria os novos botões  
        g_error := 'INSERT SYS_BUTTON_PROP';
        INSERT INTO sys_button_prop
            (id_sys_button_prop,
             id_sys_button,
             screen_name,
             id_sys_application_area,
             id_sys_screen_area,
             flg_visible,
             rank,
             border_color,
             alpha,
             back_color,
             id_sys_application_type,
             id_btn_prp_parent,
             action,
             flg_enabled,
             sub_rank,
             code_title_help,
             code_desc_help,
             flg_reset_context,
             position,
             toolbar_level)
        VALUES
            (l_id_sys_button_prop_new,
             i.id_sys_button,
             i.screen_name,
             i_sys_application_area_new,
             i.id_sys_screen_area,
             i.flg_visible,
             i.rank,
             i.border_color,
             i.alpha,
             i.back_color,
             i.id_sys_application_type,
             l_id_btn_prp_parent_new,
             i.action,
             i.flg_enabled,
             i.sub_rank,
             i.code_title_help,
             i.code_desc_help,
             i.flg_reset_context,
             i.position,
             i.toolbar_level);
    
        --actualiza a tabela que relaciona os botões novos com os antigos
        g_error := 'INSERT RB_BTN_PROP';
        INSERT INTO rb_btn_prop
            (id_sys_button_prop_old, id_sys_button_prop_new)
        VALUES
            (i.id_sys_button_prop, l_id_sys_button_prop_new);
    
        --Actualiza variáveis
        l_id_sys_button_prop_new := l_id_sys_button_prop_new + 1;
        l_id_btn_prp_parent_new  := NULL;
    
    END LOOP;

    --Obtém próximo ID
    SELECT MAX(id_profile_templ_access) + 1
      INTO l_profile_templ_access_new
      FROM profile_templ_access;

    --Insere acessos ao perfil
    FOR k IN c_profile
    LOOP
        g_error := 'INSERT PROFILE_TEMPL_ACCESS';
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
             flg_no)
        VALUES
            (l_profile_templ_access_new,
             105, --Anestesista
             k.rank,
             nvl((SELECT id_sys_button_prop_new
                   FROM rb_btn_prop
                  WHERE id_sys_button_prop_old = k.id_sys_button_prop),
                 k.id_sys_button_prop),
             k.flg_create,
             k.flg_cancel,
             k.flg_search,
             k.flg_print,
             k.flg_ok,
             k.flg_detail,
             k.flg_content,
             k.flg_help,
             --             (SELECT id_sys_shortcut
             --                FROM sys_shortcut
             --               WHERE id_sys_button_prop = nvl((SELECT id_sys_button_prop_new
             --                                                FROM rb_btn_prop
             --                                               WHERE id_sys_button_prop_old = k.id_sys_button_prop),
             --                                              k.id_sys_button_prop)),
             k.id_sys_shortcut,
             k.id_software,
             --             nvl((SELECT MAX(id_shortcut_pk_new)
             --                   FROM rb_sys_shortcut
             --                  WHERE id_shortcut_pk_old = k.id_shortcut_pk),
             --                 k.id_shortcut_pk),
             --             (SELECT id_shortcut_pk
             --                FROM sys_shortcut
             --               WHERE id_sys_button_prop = nvl((SELECT id_sys_button_prop_new
             --                                                FROM rb_btn_prop
             --                                               WHERE id_sys_button_prop_old = k.id_sys_button_prop),
             --                                              k.id_sys_button_prop)),
             k.id_shortcut_pk,
             k.id_software_context,
             k.flg_graph,
             k.flg_vision,
             k.flg_digital,
             k.flg_freq,
             k.flg_no);
    
        l_profile_templ_access_new := l_profile_templ_access_new + 1;
    
    END LOOP;

    --Obtém o ID do próximo shortcut
    SELECT MAX(id_shortcut_pk) + 1
      INTO l_id_shortcut_pk_new
      FROM sys_shortcut;

    SELECT MAX(id_sys_shortcut) + 1
      INTO l_id_sys_shortcut_new
      FROM sys_shortcut;

    --Cria os novos atalhos
    FOR j IN c_shortcut
    LOOP
    
        --Se o ID_PARENT é null, tem que passar a dois shortcuts com o mesmo pai
        IF j.id_parent IS NULL
        THEN
            --Shortuct já existente mas passa a filho
            g_error := 'INSERT SYS_SHORTCUT -1';
            INSERT INTO sys_shortcut
                (id_sys_shortcut,
                 id_sys_button_prop,
                 id_software,
                 intern_name,
                 id_institution,
                 id_parent,
                 desc_shortcut,
                 id_shortcut_pk)
            VALUES
                (l_id_sys_shortcut_new,
                 j.id_sys_button_prop,
                 j.id_software,
                 j.intern_name,
                 j.id_institution,
                 j.id_sys_shortcut,
                 j.desc_shortcut,
                 l_id_shortcut_pk_new);
        
            --Actualiza perfil com o novo shortcut
            UPDATE profile_templ_access
               SET id_sys_shortcut = l_id_sys_shortcut_new, id_shortcut_pk = l_id_shortcut_pk_new
             WHERE id_sys_button_prop = j.id_sys_button_prop
               AND id_software = 2
               AND id_shortcut_pk = j.id_shortcut_pk
               AND id_profile_template = 100;
        
            --Preenche a tabela de relação
            g_error := 'INSERT RB_SYS_SHORTCUT - 1';
            INSERT INTO rb_sys_shortcut
                (id_shortcut_pk_old, id_shortcut_pk_new)
            VALUES
                (j.id_shortcut_pk, l_id_shortcut_pk_new);
        
            INSERT INTO rb_update_template
            VALUES
                ('update profile_templ_access set id_sys_shortcut = ' || l_id_sys_shortcut_new ||
                 ', id_shortcut_pk = ' || l_id_shortcut_pk_new || ' where id_sys_button_prop = ' ||
                 j.id_sys_button_prop || ' and id_software = 2 and id_shortcut_pk = ' || j.id_shortcut_pk ||
                 ' and id_profile_template = 100;');
        
            l_id_sys_shortcut_new := l_id_sys_shortcut_new + 1;
            l_id_shortcut_pk_new  := l_id_shortcut_pk_new + 1;
        
            --Shortcut para o novo perfil
            g_error := 'INSERT SYS_SHORTCUT -2';
            INSERT INTO sys_shortcut
                (id_sys_shortcut,
                 id_sys_button_prop,
                 id_software,
                 intern_name,
                 id_institution,
                 id_parent,
                 desc_shortcut,
                 id_shortcut_pk)
            VALUES
                (l_id_sys_shortcut_new,
                 (SELECT id_sys_button_prop_new
                    FROM rb_btn_prop
                   WHERE id_sys_button_prop_old = j.id_sys_button_prop),
                 j.id_software,
                 j.intern_name,
                 j.id_institution,
                 j.id_sys_shortcut,
                 j.desc_shortcut,
                 l_id_shortcut_pk_new);
        
            --Actualiza perfil com o novo shortcut
            UPDATE profile_templ_access
               SET id_sys_shortcut = l_id_sys_shortcut_new, id_shortcut_pk = l_id_shortcut_pk_new
             WHERE id_sys_button_prop = (SELECT id_sys_button_prop_new
                                           FROM rb_btn_prop
                                          WHERE id_sys_button_prop_old = j.id_sys_button_prop)
               AND id_software = 2
               AND id_shortcut_pk = j.id_shortcut_pk
               AND id_profile_template = 105;
        
            --Preenche a tabela de relação
            g_error := 'INSERT RB_SYS_SHORTCUT -2';
            INSERT INTO rb_sys_shortcut
                (id_shortcut_pk_old, id_shortcut_pk_new)
            VALUES
                (j.id_shortcut_pk, l_id_shortcut_pk_new);
        
            l_id_sys_shortcut_new := l_id_sys_shortcut_new + 1;
            l_id_shortcut_pk_new  := l_id_shortcut_pk_new + 1;
        
        ELSE
        
            --Se o ID_PARENT não é null, basta inserir mais um registo para esse parent
            --Obtém o novo shortcut
            g_error := 'INSERT SYS_SHORTCUT -3';
            INSERT INTO sys_shortcut
                (id_sys_shortcut,
                 id_sys_button_prop,
                 id_software,
                 intern_name,
                 id_institution,
                 id_parent,
                 desc_shortcut,
                 id_shortcut_pk)
            VALUES
                (l_id_sys_shortcut_new,
                 (SELECT id_sys_button_prop_new
                    FROM rb_btn_prop
                   WHERE id_sys_button_prop_old = j.id_sys_button_prop),
                 j.id_software,
                 j.intern_name,
                 j.id_institution,
                 j.id_parent,
                 j.desc_shortcut,
                 l_id_shortcut_pk_new);
        
            UPDATE profile_templ_access
               SET id_sys_shortcut = l_id_sys_shortcut_new, id_shortcut_pk = l_id_shortcut_pk_new
             WHERE id_sys_button_prop = (SELECT id_sys_button_prop_new
                                           FROM rb_btn_prop
                                          WHERE id_sys_button_prop_old = j.id_sys_button_prop)
               AND id_software = 2
               AND id_shortcut_pk = j.id_shortcut_pk
               AND id_profile_template = 105;
        
            --Preenche a tabela de relação
            g_error := 'INSERT RB_SYS_SHORTCUT-3';
            INSERT INTO rb_sys_shortcut
                (id_shortcut_pk_old, id_shortcut_pk_new)
            VALUES
                (j.id_shortcut_pk, l_id_shortcut_pk_new);
        
            l_id_sys_shortcut_new := l_id_sys_shortcut_new + 1;
            l_id_shortcut_pk_new  := l_id_shortcut_pk_new + 1;
        END IF;
    
    END LOOP;

    COMMIT;
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        o_error := pk_message.get_message(1, 'COMMON_M001') || chr(10) || 'CREATE_NEW_SYS_APP_AREA / ' || g_error ||
                   ' / ' || SQLERRM;
        ROLLBACK;
        RETURN FALSE;
END;
/
