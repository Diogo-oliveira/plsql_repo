/*-- Last Change Revision: $Rev: 2049185 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-11-04 15:53:00 +0000 (sex, 04 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_func_help IS

    -- VARIAVEIS PRIVADAS
    g_cfg_fh_bck_lang_available CONSTANT VARCHAR2(50 CHAR) := 'FUNC_HELP_USE_BCKUP_LANGUAGE';

    g_default_language NUMBER;

    -- *************************************************************************************************
    FUNCTION get_bckp_fh_lang_available
    (
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_sysconfig.get_config(g_cfg_fh_bck_lang_available, i_id_institution, i_id_software);
    END get_bckp_fh_lang_available;
    -- #################################################################################################

    -- *************************************************************************************************
    PROCEDURE set_default_language
    (
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE
    ) IS
    BEGIN
        g_default_language := pk_utils.get_institution_language(i_id_institution, i_id_software);
    END set_default_language;
    -- #################################################################################################

    -- *************************************************************************************************
    FUNCTION get_default_language
    (
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE
    ) RETURN NUMBER IS
    BEGIN
        IF g_default_language IS NULL
        THEN
            set_default_language(i_id_institution, i_id_software);
        END IF;
    
        RETURN g_default_language;
    END get_default_language;
    -- #################################################################################################

    -- *************************************************************************************************
    FUNCTION get_help_text_internal
    (
        i_lang        IN language.id_language%TYPE,
        i_code        IN functionality_help.code_help%TYPE,
        i_id_software IN software.id_software%TYPE
    ) RETURN functionality_help.desc_help%TYPE IS
        l_return functionality_help.desc_help%TYPE;
    BEGIN
    
        g_func_name := 'GET_HELP_TEXT_INTERNAL';
    
        IF i_lang IS NOT NULL
        THEN
            SELECT pk_utils.replaceclob(desc_help, g_lf, g_lf || g_lf)
              INTO l_return
              FROM (SELECT desc_help, row_number() over(ORDER BY id_software DESC) rn
                      FROM functionality_help
                     WHERE upper(code_help) = upper(i_code)
                       AND id_language = i_lang
                       AND id_software IN (i_id_software, 0)
                       AND flg_available = g_yes)
             WHERE rn = 1;
        
        END IF;
    
        RETURN l_return;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        
    END get_help_text_internal;
    -- #################################################################################################

    /******************************************************************************
       OBJECTIVO: Retornar um texto de ajuda de SYS_MESSAGE, quando se dá entrada do código 
              e da língua 
       PARAMETROS:  Entrada: I_LANG - Língua 
                   I_CODE_HELP - Código da mensagem
              Saida: O_TITLE - título 
                     O_MESG - mensagem 
                     O_ERROR - erro 
      
      CRIAÇÃO: MF 2009-08-19
      NOTAS: 
    *********************************************************************************/
    FUNCTION get_help_text
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code_help IN functionality_help.code_help%TYPE,
        o_text      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_title     sys_message.desc_message%TYPE;
        l_button    sys_message.desc_message%TYPE;
        l_desc_lang functionality_help.desc_help%TYPE;
    BEGIN
    
        g_error := 'GET HELP MESSAGE FROM TABLE CODE:' || i_code_help;
    
        <<get_prefered_language>>
        BEGIN
            l_title     := pk_message.get_message(i_lang, 'COMMON_T007');
            l_button    := pk_message.get_message(i_lang, 'HELP_T001');
            l_desc_lang := get_help_text_internal(i_lang        => i_lang,
                                                  i_code        => i_code_help,
                                                  i_id_software => i_prof.software);
        END get_prefered_language;
    
        <<get_instit_lang_if_null>>
        BEGIN
            IF ((l_desc_lang IS NULL) OR (l_title IS NULL) OR (l_button IS NULL))
            THEN
                IF get_bckp_fh_lang_available(i_prof.institution, i_prof.software) = g_yes
                THEN
                    g_error := 'GET HELP MESSAGE FROM TABLE WITH BACKUP LANGUAGE CODE:' || i_code_help;
                
                    l_title     := pk_message.get_message(get_default_language(i_prof.institution, i_prof.software),
                                                          'COMMON_T007');
                    l_button    := pk_message.get_message(get_default_language(i_prof.institution, i_prof.software),
                                                          'HELP_T001');
                    l_desc_lang := get_help_text_internal(i_lang        => get_default_language(i_prof.institution,
                                                                                                i_prof.software),
                                                          i_code        => i_code_help,
                                                          i_id_software => i_prof.software);
                END IF;
            END IF;
        END get_instit_lang_if_null;
    
        <<return_defaults_if_null>>
        BEGIN
            IF l_desc_lang IS NULL
            THEN
                g_error := 'SETTING DEFAULT HELP MESSAGE WITH CODE: ' || i_code_help;
            
                l_desc_lang := i_code_help;
            END IF;
        
            IF l_button IS NULL
            THEN
                g_error := 'SETTING DEFAULT HELP BUTTON LABEL';
            
                l_button := 'HELP_T001';
            END IF;
        END return_defaults_if_null;
    
        g_error := 'POPULATE FUNCTIONALITY HELP CURSOR WITH DATA';
    
        OPEN o_text FOR
            SELECT l_title o_title, l_button o_button_desc, l_desc_lang o_mesg
              FROM dual;
    
        pk_backoffice_translation.set_read_translation(i_code_help, 'FUNCTIONALITY_HELP');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_FUNC_HELP',
                                              'GET_HELP_TEXT',
                                              o_error);
        
            pk_types.open_my_cursor(o_text);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_help_text;

    /** 
    * Gets reports list for a specific institution/software
    *
    * @param i_lang 
    * @param i_prof 
    * @param i_code_help 
    * @param o_text 
    * @param o_icons 
    * @param o_error 
    *
    * @return     boolean
    *
    * @author     Gustavo Serrano
    * @since      2014/12/11
    * @version    2.6.4.3
    */
    FUNCTION get_help_text_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code_help IN functionality_help.code_help%TYPE,
        o_text      OUT pk_types.cursor_type,
        o_icons     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_title      sys_message.desc_message%TYPE;
        l_button     sys_message.desc_message%TYPE;
        l_title_icon sys_message.desc_message%TYPE;
        l_desc_lang  functionality_help.desc_help%TYPE;
    BEGIN
    
        g_error := 'GET HELP MESSAGE FROM TABLE CODE:' || i_code_help;
    
        <<get_prefered_language>>
        BEGIN
            l_title      := pk_message.get_message(i_lang, 'COMMON_T007');
            l_button     := pk_message.get_message(i_lang, 'HELP_T001');
            l_title_icon := pk_message.get_message(i_lang, 'HELP_T002');
            l_desc_lang  := get_help_text_internal(i_lang        => i_lang,
                                                   i_code        => i_code_help,
                                                   i_id_software => i_prof.software);
        END get_prefered_language;
    
        <<get_instit_lang_if_null>>
        BEGIN
            IF ((l_desc_lang IS NULL) OR (l_title IS NULL) OR (l_button IS NULL))
            THEN
                IF get_bckp_fh_lang_available(i_prof.institution, i_prof.software) = g_yes
                THEN
                    g_error := 'GET HELP MESSAGE FROM TABLE WITH BACKUP LANGUAGE CODE:' || i_code_help;
                
                    l_title      := pk_message.get_message(get_default_language(i_prof.institution, i_prof.software),
                                                           'COMMON_T007');
                    l_button     := pk_message.get_message(get_default_language(i_prof.institution, i_prof.software),
                                                           'HELP_T001');
                    l_title_icon := pk_message.get_message(get_default_language(i_prof.institution, i_prof.software),
                                                           'HELP_T002');
                    l_desc_lang  := get_help_text_internal(i_lang        => get_default_language(i_prof.institution,
                                                                                                 i_prof.software),
                                                           i_code        => i_code_help,
                                                           i_id_software => i_prof.software);
                END IF;
            END IF;
        END get_instit_lang_if_null;
    
        <<return_defaults_if_null>>
        BEGIN
            IF l_desc_lang IS NULL
            THEN
                g_error := 'SETTING DEFAULT HELP MESSAGE WITH CODE: ' || i_code_help;
            
                l_desc_lang := i_code_help;
            END IF;
        
            IF l_button IS NULL
            THEN
                g_error := 'SETTING DEFAULT HELP BUTTON LABEL';
            
                l_button := 'HELP_T001';
            END IF;
        END return_defaults_if_null;
    
        g_error := 'POPULATE FUNCTIONALITY HELP CURSOR WITH DATA';
    
        OPEN o_text FOR
            SELECT l_title o_title, l_button o_button_desc, l_desc_lang o_mesg, l_title_icon o_title_icon
              FROM dual;
    
        OPEN o_icons FOR
            SELECT tbl.icon_name,
                   coalesce(pk_translation.get_translation(i_lang => i_lang, i_code_mess => tbl.code_fh_icon_screen),
                            pk_translation.get_translation(i_lang => i_lang, i_code_mess => tbl.code_func_help_icon)) desc_icon,
                   tbl.id_func_help_icon_group,
                   pk_translation.get_translation(i_lang => i_lang, i_code_mess => tbl.code_fh_icon_group) desc_func_help_icon_group,
                   tbl.fhis_icon_fg_color icon_fg_color,
                   tbl.fhis_icon_bg_color  icon_bg_color,
                   tbl.rank
              FROM (SELECT pk_translation.get_translation(i_lang => i_lang, i_code_mess => fhi.code_icon_name) icon_name,
                           fhis.code_fh_icon_screen,
                           fhi.code_func_help_icon,
                           fhig.id_func_help_icon_group,
                           fhig.code_fh_icon_group,
                           fhis.icon_fg_color fhis_icon_fg_color,
                           fhi.icon_fg_color fhi_icon_fg_color,
                           fhis.icon_bg_color fhis_icon_bg_color,
                           fhi.icon_bg_color fhi_icon_bg_color,
                           fhis.rank,
                           rank() over(PARTITION BY fhis.id_func_help_icon, fhis.id_func_help_icon_group, fhis.screen_name ORDER BY fhis.id_software DESC) rec_rank
                      FROM func_help_icon_screen fhis
                     INNER JOIN func_help_icon_rel fhir
                        ON fhir.id_func_help_icon = fhis.id_func_help_icon
                       AND fhir.id_func_help_icon_group = fhis.id_func_help_icon_group
                     INNER JOIN func_help_icon fhi
                        ON fhi.id_func_help_icon = fhir.id_func_help_icon
                     INNER JOIN func_help_icon_group fhig
                        ON fhig.id_func_help_icon_group = fhir.id_func_help_icon_group
                     WHERE fhis.screen_name = i_code_help
                       AND fhis.id_software IN (0, i_prof.software)
                       AND fhig.flg_available = pk_alert_constant.g_yes
                       AND fhi.flg_available = pk_alert_constant.g_yes
                       AND fhis.flg_available = pk_alert_constant.g_yes) tbl
             WHERE tbl.rec_rank = 1
               AND icon_name IS NOT NULL
             ORDER BY desc_func_help_icon_group, rank;
    
        pk_backoffice_translation.set_read_translation(i_code_help, 'FUNCTIONALITY_HELP');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_FUNC_HELP',
                                              'GET_HELP_TEXT',
                                              o_error);
        
            pk_types.open_my_cursor(o_text);
            pk_types.open_my_cursor(o_icons);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_help_text_icon;

    /******************************************************************************
       OBJECTIVO: inserts/updates new content of given functionality help
    
       PARAMETROS:  Entrada: I_LANG - language
                             I_CODE_HELP - code
                             I_desc_help - description
                             I_software  - software
                             I_id_functionality_help - id of functionality help if it already exists ( for update purpose )
                             I_module                - module
              Saida: N/A 
     
      CRIAÇÃO: CMF 2009-08-27
      NOTAS: 
    *********************************************************************************/
    PROCEDURE insert_into_functionality_help
    (
        i_lang                  language.id_language%TYPE,
        i_code_help             functionality_help.code_help%TYPE,
        i_desc_help             functionality_help.desc_help%TYPE,
        i_software              software.id_software%TYPE DEFAULT 0,
        i_id_functionality_help functionality_help.id_functionality_help%TYPE DEFAULT NULL,
        i_module                functionality_help.module%TYPE DEFAULT NULL
    ) IS
        l_null  VARCHAR2(0050) := 'NULL';
        o_error t_error_out;
    BEGIN
    
        g_func_name := 'INSERT_INTO_FUNCTIONALITY_HELP';
    
        g_error := 'MERGE FUNC';
        g_error := g_error || chr(32) || 'CODE_HELP:' || nvl(i_code_help, l_null);
        g_error := g_error || chr(32) || 'LANG:' || nvl(to_char(i_lang), l_null);
        g_error := g_error || chr(32) || 'ID_FUNC_HELP:' || nvl(to_char(i_id_functionality_help), l_null);
        pk_alertlog.log_debug(g_error, g_package_name, g_func_name);
    
        MERGE INTO functionality_help t
        USING (SELECT i_code_help code_help, --
                      i_desc_help desc_help, --
                      i_lang      id_language,
                      g_yes       flg_available,
                      i_software  id_software,
                      i_module    module
                 FROM dual) args
        ON (t.id_language = args.id_language AND upper(t.code_help) = upper(args.code_help)  --
        AND t.id_software = args.id_software)
        WHEN MATCHED THEN
            UPDATE
               SET t.desc_help = args.desc_help, t.module = nvl(args.module, t.module)
        WHEN NOT MATCHED THEN
            INSERT
                (id_functionality_help, code_help, desc_help, id_language, flg_available, id_software, module)
            VALUES
                ( --SE I_ID_SYS_MESSAGE NÃO É FORNECIDO TEM-SE QUE COLOCAR ALGO
                 nvl(i_id_functionality_help, seq_functionality_help.nextval),
                 args.code_help,
                 args.desc_help,
                 args.id_language,
                 args.flg_available,
                 args.id_software,
                 args.module);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              g_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
    END insert_into_functionality_help;

    PROCEDURE insert_into_fh_icon_screen
    (
        i_lang               language.id_language%TYPE,
        i_fh_icon_group      func_help_icon_group.internal_name%TYPE,
        i_fh_icon_group_desc VARCHAR2 DEFAULT NULL,
        i_fh_icon_name       VARCHAR2,
        i_fh_icon_name_desc  VARCHAR2 DEFAULT NULL,
        i_fh_icon_bg_color   func_help_icon.icon_bg_color%TYPE DEFAULT g_null,
        i_fh_icon_fg_color   func_help_icon.icon_fg_color%TYPE DEFAULT g_null,
        i_fh_screen_name     func_help_icon_screen.screen_name%TYPE DEFAULT NULL,
        i_software           software.id_software%TYPE DEFAULT 0,
        i_rank               func_help_icon_screen.rank%TYPE
    ) IS
        l_func_help_icon_group  func_help_icon_group.id_func_help_icon_group%TYPE;
        l_func_help_icon        func_help_icon.id_func_help_icon%TYPE;
        l_func_help_icon_screen func_help_icon_screen.id_func_help_icon_screen%TYPE;
        l_fhir                  func_help_icon_rel.id_func_help_icon%TYPE;
    
        l_code_fh_icon_group  VARCHAR2(4000);
        l_code_icon_name      VARCHAR2(4000);
        l_code_func_help_icon VARCHAR2(4000);
        l_code_fh_icon_screen VARCHAR2(4000);
        l_func_help_icon_new  BOOLEAN := FALSE;
        o_error               t_error_out;
    BEGIN
    
        g_func_name := 'INSERT_INTO_FH_ICON_SCREEN';
    
        g_error := 'CALL FUNC';
        g_error := g_error || chr(32) || 'I_LANG:' || nvl(to_char(i_lang), g_null);
        g_error := g_error || chr(32) || 'I_FH_ICON_GROUP:' || nvl(i_fh_icon_group, g_null);
        g_error := g_error || chr(32) || 'I_FH_ICON_NAME:' || nvl(i_fh_icon_name, g_null);
        g_error := g_error || chr(32) || 'I_FH_SCREEN_NAME:' || nvl(i_fh_screen_name, g_null);
        g_error := g_error || chr(32) || 'I_RANK:' || nvl(to_char(i_rank), g_null);
        pk_alertlog.log_debug(g_error, g_package_name, g_func_name);
    
        ---------------------------------------
        SELECT MIN(fhig.id_func_help_icon_group), MIN(fhig.code_fh_icon_group)
          INTO l_func_help_icon_group, l_code_fh_icon_group
          FROM func_help_icon_group fhig
         WHERE fhig.internal_name = i_fh_icon_group;
    
        IF (l_func_help_icon_group IS NULL)
        THEN
            l_func_help_icon_group := seq_func_help_icon_group.nextval;
            INSERT INTO func_help_icon_group
                (id_func_help_icon_group, internal_name, flg_available)
            VALUES
                (l_func_help_icon_group, i_fh_icon_group, pk_alert_constant.g_yes)
            RETURNING code_fh_icon_group INTO l_code_fh_icon_group;
        END IF;
    
        IF (i_fh_icon_group_desc IS NOT NULL)
        THEN
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => l_code_fh_icon_group,
                                                   i_desc_trans => i_fh_icon_group_desc);
        END IF;
    
        --------------------------------
    
        SELECT MIN(fhi.id_func_help_icon), MIN(fhi.code_icon_name)
          INTO l_func_help_icon, l_code_icon_name
          FROM func_help_icon fhi
         WHERE EXISTS (SELECT 1
                  FROM translation t
                 WHERE t.code_translation = fhi.code_icon_name
                   AND (t.desc_lang_1 = i_fh_icon_name OR t.desc_lang_2 = i_fh_icon_name OR
                       t.desc_lang_3 = i_fh_icon_name OR t.desc_lang_4 = i_fh_icon_name OR
                       t.desc_lang_5 = i_fh_icon_name OR t.desc_lang_6 = i_fh_icon_name OR
                       t.desc_lang_7 = i_fh_icon_name OR t.desc_lang_8 = i_fh_icon_name OR
                       t.desc_lang_9 = i_fh_icon_name OR t.desc_lang_10 = i_fh_icon_name OR
                       t.desc_lang_11 = i_fh_icon_name OR t.desc_lang_12 = i_fh_icon_name OR
                       t.desc_lang_13 = i_fh_icon_name OR t.desc_lang_14 = i_fh_icon_name OR
                       t.desc_lang_15 = i_fh_icon_name OR t.desc_lang_16 = i_fh_icon_name OR
                       t.desc_lang_17 = i_fh_icon_name OR t.desc_lang_18 = i_fh_icon_name OR
                       t.desc_lang_19 = i_fh_icon_name));
    
        IF (l_func_help_icon IS NULL)
        THEN
            l_func_help_icon_new := TRUE;
            l_func_help_icon     := seq_func_help_icon.nextval;
        
            INSERT INTO func_help_icon
                (id_func_help_icon, flg_available, icon_bg_color, icon_fg_color, code_func_help_icon, code_icon_name)
            VALUES
                (l_func_help_icon,
                 pk_alert_constant.g_yes,
                 decode(i_fh_icon_bg_color, g_null, NULL, i_fh_icon_bg_color),
                 decode(i_fh_icon_fg_color, g_null, NULL, i_fh_icon_fg_color),
                 'FUNC_HELP_ICON.CODE_FUNC_HELP_ICON.' || l_func_help_icon,
                 'FUNC_HELP_ICON.CODE_ICON_NAME.' || l_func_help_icon)
            RETURNING code_icon_name, code_func_help_icon INTO l_code_icon_name, l_code_func_help_icon;
        
        ELSIF (i_fh_screen_name IS NULL)
        THEN
            UPDATE func_help_icon
               SET icon_bg_color = decode(i_fh_icon_bg_color, g_null, icon_bg_color, i_fh_icon_bg_color),
                   icon_fg_color = decode(i_fh_icon_fg_color, g_null, icon_fg_color, i_fh_icon_fg_color)
             WHERE id_func_help_icon = l_func_help_icon
            RETURNING code_func_help_icon INTO l_code_func_help_icon;
        
        END IF;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_code_icon_name,
                                               i_desc_trans => i_fh_icon_name);
    
        IF ((i_fh_screen_name IS NULL AND i_fh_icon_name_desc IS NOT NULL) OR
           (i_fh_screen_name IS NOT NULL AND i_fh_icon_name_desc IS NOT NULL AND l_func_help_icon_new))
        THEN
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => l_code_func_help_icon,
                                                   i_desc_trans => i_fh_icon_name_desc);
        
        END IF;
    
        --------------------------------
    
        SELECT MIN(fhir.id_func_help_icon)
          INTO l_fhir
          FROM func_help_icon_rel fhir
         WHERE fhir.id_func_help_icon = l_func_help_icon
           AND fhir.id_func_help_icon_group = l_func_help_icon_group;
    
        IF (l_fhir IS NULL)
        THEN
            INSERT INTO func_help_icon_rel
                (id_func_help_icon, id_func_help_icon_group)
            VALUES
                (l_func_help_icon, l_func_help_icon_group);
        END IF;
    
        -----------------------------
    
        IF (i_fh_screen_name IS NOT NULL)
        THEN
            SELECT MIN(fhis.id_func_help_icon_screen)
              INTO l_func_help_icon_screen
              FROM func_help_icon_screen fhis
             WHERE fhis.id_func_help_icon = l_func_help_icon
               AND fhis.id_func_help_icon_group = l_func_help_icon_group
               AND fhis.screen_name = i_fh_screen_name
               AND fhis.id_software = i_software;
        
            IF (l_func_help_icon_screen IS NULL)
            THEN
                l_func_help_icon_screen := seq_func_help_icon_screen.nextval;
            
                INSERT INTO func_help_icon_screen
                    (id_func_help_icon_screen,
                     id_func_help_icon,
                     id_func_help_icon_group,
                     screen_name,
                     --code_fh_icon_screen,
                     id_software,
                     rank,
                     flg_available,
                     icon_bg_color,
                     icon_fg_color)
                VALUES
                    (l_func_help_icon_screen,
                     l_func_help_icon,
                     l_func_help_icon_group,
                     i_fh_screen_name,
                     --k_code_func_help_icon_screen || l_func_help_icon_screen,
                     i_software,
                     i_rank,
                     pk_alert_constant.g_yes,
                     decode(i_fh_icon_bg_color, g_null, NULL, i_fh_icon_bg_color),
                     decode(i_fh_icon_fg_color, g_null, NULL, i_fh_icon_fg_color))
                RETURNING code_fh_icon_screen INTO l_code_fh_icon_screen;
            
                IF (i_fh_icon_name_desc IS NOT NULL)
                THEN
                    pk_translation.insert_into_translation(i_lang       => i_lang,
                                                           i_code_trans => l_code_fh_icon_screen,
                                                           i_desc_trans => i_fh_icon_name_desc);
                END IF;
            ELSE
                UPDATE func_help_icon_screen
                   SET rank          = nvl(i_rank, rank),
                       icon_bg_color = decode(i_fh_icon_bg_color, g_null, icon_bg_color, i_fh_icon_bg_color),
                       icon_fg_color = decode(i_fh_icon_fg_color, g_null, icon_fg_color, i_fh_icon_fg_color)
                 WHERE id_func_help_icon_screen = l_func_help_icon_screen
                RETURNING code_fh_icon_screen INTO l_code_fh_icon_screen;
            
                IF (i_fh_icon_name_desc IS NOT NULL)
                THEN
                    pk_translation.insert_into_translation(i_lang       => i_lang,
                                                           i_code_trans => l_code_fh_icon_screen,
                                                           i_desc_trans => i_fh_icon_name_desc);
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
    END insert_into_fh_icon_screen;

    PROCEDURE delete_fh_icon_screen
    (
        i_lang           language.id_language%TYPE,
        i_fh_icon_group  func_help_icon_group.internal_name%TYPE,
        i_fh_icon_name   VARCHAR2,
        i_fh_screen_name func_help_icon_screen.screen_name%TYPE,
        i_software       software.id_software%TYPE
    ) IS
        l_func_help_icon_group  func_help_icon_group.id_func_help_icon_group%TYPE;
        l_func_help_icon        func_help_icon.id_func_help_icon%TYPE;
        l_func_help_icon_screen func_help_icon_screen.id_func_help_icon_screen%TYPE;
        l_code_fh_icon_screen   func_help_icon_screen.code_fh_icon_screen%TYPE;
    
        o_error t_error_out;
    BEGIN
        g_func_name := 'DELETE_FH_ICON_SCREEN';
    
        g_error := 'CALL FUNC';
        g_error := g_error || chr(32) || 'I_FH_ICON_GROUP:' || nvl(i_fh_icon_group, g_null);
        g_error := g_error || chr(32) || 'I_FH_ICON_NAME:' || nvl(i_fh_icon_name, g_null);
        g_error := g_error || chr(32) || 'I_SOFTWARE:' || i_software;
        pk_alertlog.log_debug(g_error, g_package_name, g_func_name);
    
        ---------------------------------------
        SELECT MIN(fhig.id_func_help_icon_group)
          INTO l_func_help_icon_group
          FROM func_help_icon_group fhig
         WHERE fhig.internal_name = i_fh_icon_group;
    
        IF (l_func_help_icon_group IS NOT NULL)
        THEN
            --------------------------------        
            SELECT MIN(fhi.id_func_help_icon)
              INTO l_func_help_icon
              FROM func_help_icon fhi
             WHERE pk_translation.get_translation(i_lang => i_lang, i_code_mess => fhi.code_icon_name) = i_fh_icon_name;
        
            IF (l_func_help_icon IS NOT NULL)
            THEN
                --------------------------------
                SELECT fhis.id_func_help_icon_screen, fhis.code_fh_icon_screen
                  INTO l_func_help_icon_screen, l_code_fh_icon_screen
                  FROM func_help_icon_screen fhis
                 WHERE fhis.id_func_help_icon = l_func_help_icon
                   AND fhis.id_func_help_icon_group = l_func_help_icon_group
                   AND fhis.screen_name = i_fh_screen_name
                   AND fhis.id_software = i_software;
            
                IF (l_func_help_icon_screen IS NOT NULL)
                THEN
                    --------------------------------
                    pk_translation.delete_code_translation(i_code => table_varchar(l_code_fh_icon_screen));
                
                    DELETE FROM func_help_icon_screen fhis
                     WHERE fhis.id_func_help_icon_screen = l_func_help_icon_screen;
                END IF;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(2,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              g_func_name,
                                              o_error);
    END delete_fh_icon_screen;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_func_help;
/
