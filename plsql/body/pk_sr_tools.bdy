/*-- Last Change Revision: $Rev: 2027749 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_tools AS

    /********************************************************************************************
    * Obtem  a lista de equipas a que um profissional pertence numa dada instituição
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_search           String de pesquisa
    * 
    * @param o_list             Array com as equipas do profissional
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/13
       ********************************************************************************************/

    FUNCTION get_prof_teams
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_search IN VARCHAR2,
        o_list   OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_software_oris software.id_software%TYPE;
    
    BEGIN
    
        g_error := 'GET SYSCONFIG SOFTWARE_ID_ORIS';
        pk_alertlog.log_debug(g_error);
        l_software_oris := pk_sysconfig.get_config('SOFTWARE_ID_ORIS', i_prof);
        --Abre array com a lista de equipas
        g_error := 'GET TEAM ARRAY';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT DISTINCT (t.id_prof_team),
                            t.prof_team_name,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_leader_name,
                            t.prof_team_desc
              FROM prof_team t, prof_team_det d, professional p
             WHERE d.id_prof_team = t.id_prof_team
               AND t.id_software = l_software_oris
               AND t.id_institution IN (i_prof.institution, 0)
               AND t.flg_available = g_flg_available
               AND (t.flg_type = 'O' OR t.flg_type IS NULL)
               AND p.id_professional = t.id_prof_team_leader
               AND translate(upper(t.prof_team_name), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_search), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
             ORDER BY t.prof_team_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_TEAMS',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem  a lista de profissionais pertencentes a uma equipa
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_prof_team        ID da equipa de profissionais
    * 
    * @param o_list             Array com as equipas do profissional
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/13
       ********************************************************************************************/

    FUNCTION get_prof_team_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Abre array com a lista de equipas
        g_error := 'GET TEAM ARRAY';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT d.id_prof_team_det,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) professional_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   pk_translation.get_translation(i_lang, c.code_category_sub) cat_desc
              FROM prof_team_det d, category_sub c, professional p
             WHERE d.id_prof_team = i_prof_team
               AND d.flg_available = g_flg_available
               AND d.flg_status != g_status_cancel
               AND p.id_professional = d.id_professional
               AND c.id_category_sub(+) = d.id_category_sub
             ORDER BY c.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_TEAM_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem  a lista de profissionais pertencentes a uma equipa
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_prof_team        ID da equipa de profissionais
    * 
    * @param o_team_name        Nome da equipa
    * @param o_team_desc        Descrição da equipa
    * @param o_list             Array com as equipas do profissional
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/13
       ********************************************************************************************/

    FUNCTION get_prof_team_det
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_team IN prof_team.id_prof_team%TYPE,
        o_team_name OUT VARCHAR2,
        o_team_desc OUT VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtem o nome e descrição da equipa
        g_error := 'GET TEAM NAME AND DESCRIPTION';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT prof_team_name, prof_team_desc
              INTO o_team_name, o_team_desc
              FROM prof_team
             WHERE id_prof_team = i_prof_team;
        
        EXCEPTION
            WHEN no_data_found THEN
                o_team_name := NULL;
                o_team_desc := NULL;
        END;
    
        --Obtem array de profissionais da equipa
        g_error := 'GET PROF LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT d.id_prof_team_det,
                   p.id_professional,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) professional_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   -- p.nick_name prof_name
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) spec_desc,
                   -- pk_translation.get_translation(i_lang, s.code_speciality) spec_desc,
                   pi.num_mecan,
                   d.id_category_sub,
                   pk_translation.get_translation(i_lang, c.code_category_sub) cat_desc,
                   decode(c.id_category_sub, g_catg_resp, 'N', 'Y') flg_update,
                   d.flg_status,
                   ct.flg_type
              FROM prof_team_det d,
                   category_sub c,
                   professional p, /*speciality s,*/
                   (SELECT id_institution, num_mecan, id_professional
                      FROM prof_institution
                     WHERE flg_state = pk_alert_constant.g_active
                       AND dt_end_tstz IS NULL) pi,
                   category ct
             WHERE d.id_prof_team = i_prof_team
               AND d.flg_available = g_flg_available
               AND p.id_professional = d.id_professional
               AND c.id_category_sub(+) = d.id_category_sub
                  --AND s.id_speciality(+) = p.id_speciality
               AND pi.id_professional(+) = p.id_professional
               AND pi.id_institution(+) = i_prof.institution
               AND ct.id_category = c.id_category
             ORDER BY c.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_TEAM_DET',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Procura um dado profissional, de acordo com os critérios de pesquisa definidos, para adicionar 
    *  à equipa de profissionais. Não mostra os profissionais já seleccionados para esta equipa.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_prof_team        ID da equipa de profissionais
    * @param i_search_prof      Critério de pesquisa do profissional
    * @param i_search_spec      Critério de pesquisa da especialidade 
    * @param i_search_num       Critério de pesquisa do nº mecanográfico
    * @param i_excl_prof        Array com os IDs dos profissionais a excluir do resultado da pesquisa (Para situações
    *                           em que no ecrã já foram adicionados profissionais à equipa mas esta ainda não foi gravada).
    * 
    * @param o_list             Array com as equipas do profissional
    * @param o_icon             Nome do icone a mostrar para identificar os profissionais seleccionados
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/13
       ********************************************************************************************/

    FUNCTION get_prof_team_search
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_team   IN prof_team.id_prof_team%TYPE,
        i_search_prof IN VARCHAR2,
        i_search_spec IN VARCHAR2,
        i_search_num  IN VARCHAR2,
        i_excl_prof   IN table_number,
        o_list        OUT pk_types.cursor_type,
        o_icon        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Indica qual o icon a mostrar para representar o profissional seleccionado
        o_icon         := g_handsel_icon;
        g_sysdate_tstz := current_timestamp;
    
        --Obtem array de profissionais da equipa de acordo com os critérios de pesquisa
        g_error := 'GET PROF LIST SEARCH';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT p.id_professional,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) professional_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   pi.num_mecan,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) spec_desc,
                   c.flg_type
              FROM professional p, prof_institution pi, prof_cat pc, category c
             WHERE p.id_professional NOT IN (SELECT 1
                                               FROM prof_team_det d
                                              WHERE d.id_prof_team = i_prof_team
                                                AND d.id_professional = p.id_professional)
               AND pi.id_professional(+) = p.id_professional
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state(+) = pk_alert_constant.g_active
               AND pc.id_professional = p.id_professional
               AND pc.id_institution(+) = i_prof.institution
               AND p.id_professional NOT IN (SELECT id_professional
                                               FROM prof_team_det d1
                                              WHERE d1.id_prof_team = i_prof_team
                                                AND d1.flg_status != g_cancel)
               AND p.id_professional NOT IN (SELECT *
                                               FROM TABLE(CAST(i_excl_prof AS table_number)))
               AND c.id_category = pc.id_category
               AND c.flg_type IN (g_cat_doctor, g_cat_nurse)
               AND (pi.dt_end_tstz IS NULL OR pi.dt_end_tstz > g_sysdate_tstz)
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
               AND (((translate(upper(pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)),
                                'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_search_prof), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_search_prof IS NOT NULL) OR
                   (translate(upper(pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL)),
                                'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_search_spec), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_search_spec IS NOT NULL) OR
                   (translate(upper(pi.num_mecan), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_search_num), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                   i_search_num IS NOT NULL)) OR
                   (i_search_prof IS NULL AND i_search_spec IS NULL AND i_search_num IS NULL))
             ORDER BY pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_TEAM_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Mostra a lista de categorias que podem ser atribuídas ao profissional
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_list             Array com as equipas do profissional
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/13
       ********************************************************************************************/

    FUNCTION get_prof_catg_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtem a lista de categorias que podem ser atribuídas ao profissional
        g_error := 'GET CATEGORY LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT id_category_sub data, pk_translation.get_translation(i_lang, code_category_sub) label, c.flg_type
              FROM category_sub s, category c
             WHERE s.flg_available = g_flg_available
               AND s.id_category = c.id_category
            --                        and c.flg_type = G_FLG_TYPE_DOCTOR
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_CATG_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Cria/actualiza a informação relativa a uma equipa.
    *     Validações:             
    *        - A equipa tem que ter um e apenas um responsável
    *        - A equipa não pode ter profissionais sem categoria associada                
    *        - Valida o número de profissionais por categoria (se I_TEST=Y) e apresenta mensagem
    *           com os limites excedidos para que o utilizador confirme.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_prof_team        ID da equipa na PROF_TEAM que deu origem à equipa de cirurgia
    * @param i_name             Nome da equipa
    * @param i_desc             Descrição da equipa
    * @param i_tbl_prof         Array com os ids dos profissionais na equipa
    * @param i_tbl_catg         Array com as categorias para cada um dos profissionais em I_TBL_PROF
    * @param i_tbl_status       Array com o estado de actualização para cada profissional em I_TBL_PROF. Valores possíveis:
                                    'N' - Novo registo
                                    'C' - Actualização registo
                                    'D' - Remover registo
    * @param i_test             Indica se deve validar o número de profissionais por categoria
    * 
    * @param o_flg_show         Indica se deve ser mostrada uma mensagem (Y / N) 
    * @param o_msg_title        Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y 
    * @param o_msg_text         Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y 
    * @param o_button           Botões a mostrar: N - não, R - lido, C - confirmado 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/16
       ********************************************************************************************/

    FUNCTION set_prof_team
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_prof_team    IN prof_team.id_prof_team%TYPE,
        i_name         IN prof_team.prof_team_name%TYPE,
        i_desc         IN prof_team.prof_team_desc%TYPE,
        i_tbl_prof     IN table_number,
        i_tbl_catg     IN table_number,
        i_tbl_status   IN table_varchar,
        i_test         IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out,
        o_id_prof_team OUT prof_team.id_prof_team%TYPE
    ) RETURN BOOLEAN IS
    
        CURSOR c_tot_prof_catg IS
            SELECT id_category_sub, num_prof, pk_translation.get_translation(i_lang, code_category_sub) desc_category
              FROM category_sub
             WHERE num_prof IS NOT NULL
               AND id_category_sub != g_catg_resp
             ORDER BY rank;
    
        TYPE t_count_categ IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(24);
        l_count            PLS_INTEGER;
        l_count_categ      t_count_categ;
        l_id_prof_resp     professional.id_professional%TYPE;
        l_prof_no_categ    BOOLEAN;
        l_max_prof_exc     BOOLEAN := FALSE;
        l_num_prof         PLS_INTEGER;
        l_catg_resp_desc   pk_translation.t_desc_translation;
        l_old_name         prof_team.prof_team_name%TYPE;
        l_old_desc         prof_team.prof_team_desc%TYPE;
        l_old_prof_leader  prof_team.id_prof_team_leader%TYPE;
        l_id_prof_team     prof_team.id_prof_team%TYPE;
        l_curr_count_categ PLS_INTEGER;
    BEGIN
        -- Obtém a descrição de responsável da equipa.
        g_error := 'GET RESP DESCRIPTION';
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, code_category_sub)
          INTO l_catg_resp_desc
          FROM category_sub
         WHERE id_category_sub = g_catg_resp;
    
        -- Preenche o array com o número de elementos por categoria.
        g_error := 'COUNT PROF CATG';
        pk_alertlog.log_debug(g_error);
        FOR i IN 1 .. i_tbl_prof.count
        LOOP
            -- Apenas conta se a linha não for para remover
            IF nvl(i_tbl_status(i), g_status_chg) != g_status_del
            THEN
                IF i_tbl_catg(i) IS NULL
                THEN
                    l_prof_no_categ := TRUE;
                ELSE
                    BEGIN
                        l_curr_count_categ := l_count_categ(to_char(i_tbl_catg(i)));
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_curr_count_categ := 0;
                    END;
                    l_count_categ(to_char(i_tbl_catg(i))) := l_curr_count_categ + 1;
                    -- Se a categoria for a de cirurgião responsável, guarda o id para usar mais tarde.
                    IF i_tbl_catg(i) = g_catg_resp
                    THEN
                        l_id_prof_resp := i_tbl_prof(i);
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        -- Se existirem profissionais sem categoria, envia mensagem
        g_error := 'CHECK PROF NO CATG';
        pk_alertlog.log_debug(g_error);
        IF l_prof_no_categ
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
            o_msg_text  := pk_message.get_message(i_lang, 'SURGERY_ROOM_M024');
            o_button    := 'C';
            RETURN TRUE;
        END IF;
    
        -- Tem que existir 1 e apenas 1 cirurgião responsável
        g_error := 'CHECK RESP PROF';
        pk_alertlog.log_debug(g_error);
        BEGIN
            l_count := nvl(l_count_categ(to_char(g_catg_resp)), 0);
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
        END;
        IF l_count != 1
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
            IF l_count = 0
            THEN
                o_msg_text := REPLACE(pk_message.get_message(i_lang, 'SURGERY_ROOM_M025'), '&catg', l_catg_resp_desc);
            ELSE
                o_msg_text := REPLACE(pk_message.get_message(i_lang, 'SURGERY_ROOM_M026'), '&catg', l_catg_resp_desc);
            END IF;
            o_button := 'C';
            RETURN TRUE;
        END IF;
    
        IF i_test = 'Y'
        THEN
            g_error := 'CHECK NUM PROF CATG';
            pk_alertlog.log_debug(g_error);
            -- Valida o número de profissionais por categoria.        
            FOR r IN c_tot_prof_catg
            LOOP
                BEGIN
                    l_num_prof := l_count_categ(to_char(r.id_category_sub));
                EXCEPTION
                    WHEN no_data_found THEN
                        l_num_prof := 0;
                END;
                IF nvl(l_num_prof, 0) > r.num_prof
                THEN
                    -- Para esta categoria existem mais profissionais do que o indicado.
                    IF NOT l_max_prof_exc
                    THEN
                        -- Primeiro encontrado
                        l_max_prof_exc := TRUE;
                        o_msg_text     := REPLACE(REPLACE(pk_message.get_message(i_lang, 'SR_LABEL_T257'),
                                                          '&num_prof',
                                                          to_char(l_num_prof)),
                                                  '&catg',
                                                  r.desc_category);
                    ELSE
                        o_msg_text := o_msg_text || chr(13) ||
                                      REPLACE(REPLACE(pk_message.get_message(i_lang, 'SR_LABEL_T257'),
                                                      '&num_prof',
                                                      to_char(l_num_prof)),
                                              '&catg',
                                              r.desc_category);
                    END IF;
                END IF;
            END LOOP;
            IF l_max_prof_exc
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
                o_button    := 'NC';
                RETURN TRUE;
            END IF;
        END IF;
    
        -- Verifica se se trata da inserção de uma nova equipa ou actualização.
        IF i_prof_team IS NULL
        THEN
            -- Inserção
            g_error := 'INSERT PROF TEAM';
            pk_alertlog.log_debug(g_error);
            SELECT seq_prof_team.nextval
              INTO l_id_prof_team
              FROM dual;
            INSERT INTO prof_team
                (id_prof_team,
                 id_prof_team_leader,
                 prof_team_name,
                 prof_team_desc,
                 flg_available,
                 flg_status,
                 id_software,
                 id_institution,
                 flg_type)
            VALUES
                (l_id_prof_team,
                 l_id_prof_resp,
                 i_name,
                 i_desc,
                 g_flg_available,
                 g_flg_active,
                 pk_alert_constant.g_soft_oris,
                 i_prof.institution,
                 'O');
        ELSE
            -- Actualização
            SELECT prof_team_name, prof_team_desc, id_prof_team_leader
              INTO l_old_name, l_old_desc, l_old_prof_leader
              FROM prof_team
             WHERE id_prof_team = i_prof_team;
        
            -- Verifica se o nome e a descrição mudaram.
            IF nvl(l_old_name, '@') != nvl(i_name, '@')
               OR nvl(l_old_desc, '@') != nvl(i_desc, '@')
            THEN
                g_error := 'UPDATE (1)';
                pk_alertlog.log_debug(g_error);
                UPDATE prof_team
                   SET prof_team_name = i_name, prof_team_desc = i_desc
                 WHERE id_prof_team = i_prof_team;
            END IF;
        
            -- Verifica se o líder da equipa mudou
            IF l_old_prof_leader != l_id_prof_resp
            THEN
                g_error := 'UPDATE (2)';
                pk_alertlog.log_debug(g_error);
                UPDATE prof_team
                   SET id_prof_team_leader = l_id_prof_resp
                 WHERE id_prof_team = i_prof_team;
            END IF;
        
            l_id_prof_team := i_prof_team;
        END IF;
    
        o_id_prof_team := l_id_prof_team;
    
        -- Actualiza a equipa
        FOR i IN 1 .. i_tbl_prof.count
        LOOP
            IF i_tbl_status(i) = g_status_new
            THEN
                -- Novo registo
                g_error := 'INSERT PROF_TEAM_DET';
                pk_alertlog.log_debug(g_error);
                INSERT INTO prof_team_det
                    (id_prof_team_det, id_prof_team, id_professional, id_category_sub, flg_available, flg_status)
                VALUES
                    (seq_prof_team_det.nextval,
                     l_id_prof_team,
                     i_tbl_prof(i),
                     i_tbl_catg(i),
                     g_flg_available,
                     g_flg_active);
            ELSE
                IF i_tbl_status(i) = g_status_chg
                THEN
                    -- Actualização registo
                    g_error := 'UPDATE PROF_TEAM_DET';
                    pk_alertlog.log_debug(g_error);
                    UPDATE prof_team_det
                       SET id_category_sub = i_tbl_catg(i)
                     WHERE id_prof_team = l_id_prof_team
                       AND id_professional = i_tbl_prof(i);
                ELSE
                    IF i_tbl_status(i) = g_status_del
                    THEN
                        -- Cancelar registo
                        g_error := 'CANCEL PROF_TEAM_DET';
                        pk_alertlog.log_debug(g_error);
                        UPDATE prof_team_det
                           SET flg_status = g_cancel, dt_cancel_tstz = g_sysdate_tstz, id_prof_cancel = i_prof.id
                         WHERE id_prof_team = l_id_prof_team
                           AND id_professional = i_tbl_prof(i);
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROF_TEAM_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter listagem das escolhas de: departamento, salas
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_list             Array com as equipas do profissional
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/30
       ********************************************************************************************/

    FUNCTION get_prof_room_nurse
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sr_dept department.id_department%TYPE;
    
    BEGIN
        g_error := 'GET SR DEPT';
        pk_alertlog.log_debug(g_error);
        l_sr_dept := pk_sysconfig.get_config('SURGERY_ROOM_DEPT', i_prof);
    
        g_error := 'GET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT d.id_department,
                   pk_translation.get_translation(i_lang, d.code_department) desc_dep,
                   r.id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                   decode(det.id_prof_room, NULL, NULL, 'Y') flg_pref,
                   pk_translation.get_translation(i_lang, det.code_category_sub) desc_catg,
                   det.id_sr_prof_shift,
                   decode(det.hour_start,
                          '',
                          pk_translation.get_translation(i_lang, det.code_sr_prof_shift),
                          (det.hour_start || pk_message.get_message(i_lang, 'HOURS_SIGN') || ' - ' || det.hour_end ||
                          pk_message.get_message(i_lang, 'HOURS_SIGN'))) desc_shift,
                   det.id_category_sub,
                   det.id_sr_prof_shift
              FROM department d,
                   room r,
                   (SELECT pr.id_prof_room,
                           pr.id_room,
                           s.id_category_sub,
                           s.code_category_sub,
                           h.id_sr_prof_shift,
                           h.code_sr_prof_shift,
                           h.hour_start,
                           h.hour_end
                      FROM prof_room pr, category_sub s, sr_prof_shift h
                     WHERE pr.id_professional = i_prof.id
                       AND s.id_category_sub(+) = pr.id_category_sub
                       AND h.id_sr_prof_shift(+) = pr.id_sr_prof_shift) det
             WHERE r.id_room = det.id_room(+)
               AND r.id_department = d.id_department
               AND r.flg_available = g_flg_available
               AND d.id_department = l_sr_dept
               AND d.id_institution = i_prof.institution
             ORDER BY desc_room;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_ROOM_NURSE',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Alterar a sala preferencial e a sub categoria dos enfermeiros do bloco
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_room             String de pesquisa
    * @param i_catg             Array de categorias profissionais. Apenas pode ser preenchida na linha da sala preferencial 
    * @param i_shift            ID do turno
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/30 
       ********************************************************************************************/

    FUNCTION set_prof_room_nurse
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        i_catg  IN category_sub.id_category_sub%TYPE,
        i_shift IN sr_prof_shift.id_sr_prof_shift%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exists(i_dep IN department.id_department%TYPE) IS
            SELECT id_prof_room
              FROM prof_room pr, room r, department d
             WHERE pr.id_professional = i_prof.id
               AND r.id_room = pr.id_room
               AND d.id_department = r.id_department
               AND d.id_department = nvl(i_dep, -1);
    
        l_dep          room.id_department%TYPE;
        l_id_prof_room prof_room.id_prof_room%TYPE;
    
    BEGIN
    
        --Obter o departamento correspondente ao bloco operatório.
        g_error := 'GET SR DEPT';
        pk_alertlog.log_debug(g_error);
        l_dep := pk_sysconfig.get_config('SURGERY_ROOM_DEPT', i_prof);
    
        -- Verifica se já existe registo para o profissional/sala
        g_error := 'OPEN C_EXISTS';
        pk_alertlog.log_debug(g_error);
        OPEN c_exists(l_dep);
        FETCH c_exists
            INTO l_id_prof_room;
        g_found := c_exists%FOUND;
        CLOSE c_exists;
    
        IF g_found
        THEN
            --O enfermeiro só pode estar alocado a uma sala do bloco.
            --Elimina salas que tenha a mais
            g_error := 'DELETE PROF_ROOM';
            pk_alertlog.log_debug(g_error);
            DELETE FROM prof_room
             WHERE id_prof_room IN (SELECT id_prof_room
                                      FROM prof_room pr, room r, department d
                                     WHERE pr.id_professional = i_prof.id
                                       AND r.id_room = pr.id_room
                                       AND d.id_department = r.id_department
                                       AND d.id_department = nvl(l_dep, -1))
               AND id_prof_room != l_id_prof_room;
        
            --Actualiza a sala preferencial a a sub-categoria do profissional                        
            g_error := 'UPDATE PROF_ROOM';
            pk_alertlog.log_debug(g_error);
            UPDATE prof_room
               SET id_room = i_room, id_category_sub = i_catg, id_sr_prof_shift = i_shift
             WHERE id_professional = i_prof.id
               AND id_prof_room = l_id_prof_room;
        
        ELSE
            -- Insere registo
            g_error := 'INSERT';
            pk_alertlog.log_debug(g_error);
            INSERT INTO prof_room
                (id_prof_room, id_professional, id_room, flg_pref, id_category_sub, id_sr_prof_shift)
            VALUES
                (seq_prof_room.nextval, i_prof.id, i_room, g_prof_room_npref, i_catg, i_shift);
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PROF_ROOM_NURSE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem a lista de sub-categorias de enfermagem do bloco operatório
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_list             Array com as sub-categorias de enfermagem 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/30 
       ********************************************************************************************/

    FUNCTION get_nurse_catg_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Abre array de sub-categorias de enfermeiros
        g_error := 'OPEN O_LIST ARRAY';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT s.id_category_sub, pk_translation.get_translation(i_lang, s.code_category_sub) desc_catg
              FROM category_sub s, category c
             WHERE s.id_category = c.id_category
               AND c.flg_type = g_flg_type_nurse
               AND c.flg_available = g_flg_available
             ORDER BY s.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NURSE_CATG_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem a lista de turnos de enfermagem do bloco operatório
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_list             Array com as sub-categorias de enfermagem 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/30 
       ********************************************************************************************/

    FUNCTION get_nurse_shift_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_institution institution.id_institution%TYPE;
    BEGIN
        --
        SELECT decode(COUNT(1), 0, 0, i_prof.institution)
          INTO l_institution
          FROM sr_prof_shift sp
         WHERE sp.id_software = i_prof.software
           AND sp.id_institution = i_prof.institution;
    
        --Abre array de turnos de enfermeiros do bloco
        g_error := 'OPEN O_LIST ARRAY';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT sps.id_sr_prof_shift,
                   decode(sps.hour_start,
                          '',
                          pk_translation.get_translation(i_lang, sps.code_sr_prof_shift),
                          (sps.hour_start || pk_message.get_message(i_lang, 'HOURS_SIGN') || ' - ' || sps.hour_end ||
                          pk_message.get_message(i_lang, 'HOURS_SIGN'))) desc_shift
              FROM sr_prof_shift sps
             WHERE sps.flg_available = pk_alert_constant.g_yes
               AND sps.id_software = i_prof.software
               AND sps.id_institution = l_institution
             ORDER BY sps.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NURSE_SHIFT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    FUNCTION get_sr_prof_team_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_type           IN VARCHAR2,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_id_prof_team   OUT sr_prof_team_det.id_prof_team%TYPE,
        o_team_name      OUT VARCHAR2,
        o_team_desc      OUT VARCHAR2,
        o_list           OUT pk_types.cursor_type,
        o_status         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'GET get_sr_prof_team_det';
        pk_alertlog.log_debug(g_error);
        IF NOT get_sr_prof_team_det(i_lang            => i_lang,
                                    i_prof            => i_prof,
                                    i_episode         => i_episode,
                                    i_type            => i_type,
                                    i_sr_epis_interv  => i_sr_epis_interv,
                                    i_flg_report_type => g_report_complete_c,
                                    o_id_prof_team    => o_id_prof_team,
                                    o_team_name       => o_team_name,
                                    o_team_desc       => o_team_desc,
                                    o_list            => o_list,
                                    o_status          => o_status,
                                    o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_PROF_TEAM_DET',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END;

    /*******************************************************************************************************************************************
    * Obtem  a lista de equipas a que um profissional pertence numa dada instituição
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_TYPE                   Type of access (P-Cirurgia Proposta; R-Registo de Intervenção)
    *
    * @param O_ID_PROF_TEAM           ID da equipa de profissionais
    * @param O_TEAM_NAME              Team Name
    * @param O_TEAM_DESC              Team Description  
    * @param O_LIST                   Array com as equipas associadas ao episódio
    * @param O_STATUS                 Cursor com informação acerca da última actualização da equipa.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Rui Campos 
    * @version                        0.1
    * @since                          2006/11/14
    *******************************************************************************************************************************************/
    FUNCTION get_sr_prof_team_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        o_id_prof_team OUT sr_prof_team_det.id_prof_team%TYPE,
        o_team_name    OUT VARCHAR2,
        o_team_desc    OUT VARCHAR2,
        o_list         OUT pk_types.cursor_type,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'GET get_sr_prof_team_det';
        pk_alertlog.log_debug(g_error);
        IF NOT get_sr_prof_team_det(i_lang            => i_lang,
                                    i_prof            => i_prof,
                                    i_episode         => i_episode,
                                    i_type            => i_type,
                                    i_flg_report_type => g_report_complete_c,
                                    o_id_prof_team    => o_id_prof_team,
                                    o_team_name       => o_team_name,
                                    o_team_desc       => o_team_desc,
                                    o_list            => o_list,
                                    o_status          => o_status,
                                    o_error           => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_PROF_TEAM_DET',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END;

    /*******************************************************************************************************************************************
    * Obtem  a lista de equipas a que um profissional pertence numa dada instituição
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE identifier
    * @param I_TYPE                   Type of access (P-Cirurgia Proposta; R-Registo de Intervenção)
    * @param I_FLG_REPORT_TYPE        Report type: C-complete; D-detailed    
    *
    * @param O_ID_PROF_TEAM           ID da equipa de profissionais
    * @param O_TEAM_NAME              Team Name
    * @param O_TEAM_DESC              Team Description  
    * @param O_LIST                   Array com as equipas associadas ao episódio
    * @param O_STATUS                 Cursor com informação acerca da última actualização da equipa.
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Rui Campos 
    * @version                        0.1
    * @since                          2006/11/14
    *******************************************************************************************************************************************/
    FUNCTION get_sr_prof_team_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_type            IN VARCHAR2,
        i_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE DEFAULT NULL,
        i_flg_report_type IN VARCHAR2, --C-complete; D-detailed
        o_id_prof_team    OUT sr_prof_team_det.id_prof_team%TYPE,
        o_team_name       OUT VARCHAR2,
        o_team_desc       OUT VARCHAR2,
        o_list            OUT pk_types.cursor_type,
        o_status          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_prof_team sr_prof_team_det.id_prof_team%TYPE;
    
        CURSOR c_get_id_team IS
            SELECT id_prof_team
              FROM sr_prof_team_det
             WHERE id_episode_context = i_episode
               AND id_prof_team IS NOT NULL
               AND flg_status = g_status_active;
    
        -- Cursor para obter o profissional e datas de alterações respectivas (para obter a última alteração) 
        CURSOR c_changes IS
            SELECT id_prof_reg id_prof,
                   pk_date_utils.date_send_tsz(i_lang, dt_reg_tstz, i_prof) dt_reg,
                   pk_date_utils.date_char_tsz(i_lang, dt_reg_tstz, i_prof.institution, i_prof.software) dt_last_change,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   --
                   CASE
                        WHEN pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) IS NOT NULL THEN
                         '(' || pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ')'
                        ELSE
                         NULL
                    END speciality,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) spec
              FROM sr_prof_team_det sptd, professional p
             WHERE id_episode_context = i_episode
               AND id_sr_epis_interv = i_sr_epis_interv
               AND dt_reg_tstz = (SELECT MAX(dt_reg_tstz)
                                    FROM sr_prof_team_det
                                   WHERE id_episode_context = i_episode)
               AND p.id_professional(+) = sptd.id_prof_reg
            UNION
            SELECT id_prof_cancel id_prof,
                   pk_date_utils.date_send_tsz(i_lang, dt_cancel_tstz, i_prof) dt_cancel,
                   pk_date_utils.date_char_tsz(i_lang, dt_cancel_tstz, i_prof.institution, i_prof.software) dt_last_change,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   --
                   '(' || pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) || ')' speciality,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) spec
              FROM sr_prof_team_det sptd, professional p
             WHERE id_episode_context = i_episode
               AND id_sr_epis_interv = i_sr_epis_interv
               AND dt_cancel_tstz = (SELECT MAX(dt_cancel_tstz)
                                       FROM sr_prof_team_det
                                      WHERE id_episode_context = i_episode)
               AND p.id_professional(+) = sptd.id_prof_cancel
             ORDER BY 2 DESC;
    
        l_upd_id_prof    professional.id_professional%TYPE;
        l_upd_dt         VARCHAR2(50);
        l_upd_fmt_date   VARCHAR2(20);
        l_upd_prof_name  professional.nick_name%TYPE;
        l_upd_speciality pk_translation.t_desc_translation;
        l_upd_spec       pk_translation.t_desc_translation;
    
    BEGIN
    
        --Obtem o nome e descrição da equipa
        g_error := 'GET TEAM NAME AND DESCRIPTION';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_id_team;
        FETCH c_get_id_team
            INTO l_id_prof_team;
        g_found := c_get_id_team%FOUND;
        CLOSE c_get_id_team;
    
        IF g_found
           AND l_id_prof_team IS NOT NULL
        THEN
            BEGIN
                o_id_prof_team := l_id_prof_team;
                g_error        := 'GET TEAM_NAME_DESC';
                pk_alertlog.log_debug(g_error);
                SELECT prof_team_name, prof_team_desc
                  INTO o_team_name, o_team_desc
                  FROM prof_team
                 WHERE id_prof_team = l_id_prof_team;
            
            EXCEPTION
                WHEN no_data_found THEN
                    o_team_name := NULL;
                    o_team_desc := NULL;
            END;
        ELSE
            o_team_name := NULL;
            o_team_desc := NULL;
        END IF;
    
        --Obtem array de profissionais da equipa
        g_error := 'GET PROF LIST';
        pk_alertlog.log_debug(g_error);
        -- Se o pedido por feito a partir dos registos de intervenção e não existirem enfermeiros na equipa,
        -- acrescenta os profissonais que neste momento estão na sala.
    
        OPEN o_list FOR
            SELECT 0 id_sr_prof_team, -- For later use
                   d.id_sr_prof_team_det,
                   p.id_professional,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) professional_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) spec_desc,
                   pi.num_mecan,
                   d.id_category_sub,
                   pk_translation.get_translation(i_lang, c.code_category_sub) cat_desc,
                   decode(d.flg_status, g_cancel, 'N', decode(c.id_category_sub, g_catg_resp, 'N', 'Y')) flg_update,
                   ct.flg_type,
                   d.flg_status
              FROM sr_prof_team_det d,
                   category_sub     c,
                   professional     p,
                   /*BEGIN ALERT-39196*/
                   (SELECT id_institution, num_mecan, id_professional, flg_state
                      FROM prof_institution
                     WHERE flg_state = pk_alert_constant.g_active
                       AND dt_end_tstz IS NULL) pi,
                   /*END ALERT-39196*/
                   category ct
             WHERE d.id_episode_context = i_episode
               AND d.id_sr_epis_interv = i_sr_epis_interv
               AND p.id_professional = d.id_professional
               AND c.id_category_sub(+) = d.id_category_sub
               AND pi.id_professional(+) = p.id_professional
               AND pi.id_institution(+) = i_prof.institution
               AND pi.flg_state(+) = pk_alert_constant.g_active
               AND ct.id_category = c.id_category
               AND (i_flg_report_type = g_report_detail_d OR
                   (i_flg_report_type = g_report_complete_c AND d.flg_status = g_status_active))
             ORDER BY d.flg_status, c.rank;
        --  end if;
    
        -- Obtém última alteração
        g_error := 'OPEN C_CHANGES';
        pk_alertlog.log_debug(g_error);
        OPEN c_changes;
        FETCH c_changes
            INTO l_upd_id_prof, l_upd_dt, l_upd_fmt_date, l_upd_prof_name, l_upd_speciality, l_upd_spec;
        g_found := c_changes%FOUND;
        CLOSE c_changes;
    
        IF g_found
        THEN
            OPEN o_status FOR
                SELECT 0                id_sr_prof_team, -- For later use
                       l_upd_id_prof    id_prof,
                       l_upd_dt         dt_last_change,
                       l_upd_fmt_date   dt_last_change_char,
                       l_upd_prof_name  prof_name,
                       l_upd_speciality speciality,
                       l_upd_spec       spec
                  FROM dual;
        ELSE
            pk_types.open_my_cursor(o_status);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_PROF_TEAM_DET',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Cria/actualiza a informação relativa à equipa associada ao episódio de cirurgia. 
    *       Validações:             
    *           - A equipa tem que ter um e apenas um responsável
    *           - A equipa não pode ter profissionais sem categoria associada 
    *           - Valida o número de profissionais por categoria (se I_TEST=Y) e apresenta mensagem
    *              com os limites excedidos para que o utilizador confirme.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_surgery_record   ID do registo de intervenção (Opcional)
    * @param i_episode          ID do episódio
    * @param i_episode_context  ID do episódio de contexto, onde a info poderá ser visivel
    * @param i_prof_team        ID da equipa na PROF_TEAM que deu origem à equipa de cirurgia
    * @param i_tbl_prof         Array com os ids dos profissionais na equipa
    * @param i_tbl_catg         Array com as categorias para cada um dos profissionais em I_TBL_PROF
    * @param i_tbl_status       Array com o estado de actualização para cada profissional em I_TBL_PROF. Valores possíveis:
                                  NULL - Novo registo a partir de equipa escolhida pelo utilizador (sem alteração)
                                  'N' - Novo registo
                                  'C' - Actualização registo
                                  'D' - Remover registo
    * @param i_test             Indica se deve validar o número de profissionais por categoria
    * @param i_dt_reg           Data de registo da equipa (migração)
    * 
    * @param o_flg_show         Indica se deve ser mostrada uma mensagem (Y / N) 
    * @param o_msg_title        Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y 
    * @param o_msg_text         Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y 
    * @param o_button           Botões a mostrar: N - não, R - lido, C - confirmado 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/16
       ********************************************************************************************/

    FUNCTION set_sr_prof_team_det
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_surgery_record  IN sr_surgery_record.id_surgery_record%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_episode_context IN episode.id_episode%TYPE,
        i_prof_team       IN prof_team.id_prof_team%TYPE,
        i_tbl_prof        IN table_number,
        i_tbl_catg        IN table_number,
        i_tbl_status      IN table_varchar,
        i_test            IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_msg_text        OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL SET_SR_PROF_TEAM_DET_NO_COMMIT';
        pk_alertlog.log_debug(g_error);
        IF NOT set_sr_prof_team_det_no_commit(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_surgery_record  => i_surgery_record,
                                              i_episode         => i_episode,
                                              i_episode_context => i_episode_context,
                                              i_prof_team       => i_prof_team,
                                              i_tbl_prof        => i_tbl_prof,
                                              i_tbl_catg        => i_tbl_catg,
                                              i_tbl_status      => i_tbl_status,
                                              i_test            => i_test,
                                              i_dt_reg          => NULL,
                                              o_flg_show        => o_flg_show,
                                              o_msg_title       => o_msg_title,
                                              o_msg_text        => o_msg_text,
                                              o_button          => o_button,
                                              o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SR_PROF_TEAM_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Procura um dado profissional, de acordo com os critérios de pesquisa definidos, para adicionar 
    *  à equipa de profissionais. Não mostra os profissionais já seleccionados para esta equipa.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_episode          ID do episódio
    * @param i_search_prof      Critério de pesquisa do profissional
    * @param i_search_spec      Critério de pesquisa da especialidade 
    * @param i_search_num       Critério de pesquisa do nº mecanográfico
    * @param i_excl_prof        Array com os IDs dos profissionais a excluir do resultado da pesquisa (Para situações
    *                             em que no ecrã já foram adicionados profissionais à equipa mas esta ainda não foi gravada).
    * @param i_type             Tipo de acesso (P-Cirurgia Proposta; R-Registo de Intervenção)   
    * 
    * @param o_list             Array com as equipas do profissional
    * @param o_icon             Nome do icone a mostrar para identificar os profissionais seleccionados
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/23
       ********************************************************************************************/

    FUNCTION get_sr_prof_team_search
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_search_prof IN VARCHAR2,
        i_search_spec IN VARCHAR2,
        i_search_num  IN VARCHAR2,
        i_excl_prof   IN table_number,
        i_type        IN VARCHAR2,
        o_list        OUT pk_types.cursor_type,
        o_icon        OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Indica qual o icon a mostrar para representar o profissional seleccionado
        o_icon         := g_handsel_icon;
        g_sysdate_tstz := current_timestamp;
    
        --Obtem array de profissionais da equipa de acordo com os critérios de pesquisa
        g_error := 'GET SR PROF LIST SEARCH';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT p.id_professional,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) professional_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   pi.num_mecan,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) spec_desc,
                   1 p_order,
                   c.flg_type
              FROM professional p, prof_institution pi, prof_cat pc, category c
             WHERE pi.id_professional(+) = p.id_professional
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state(+) = pk_alert_constant.g_active
               AND pc.id_professional = p.id_professional
                  /*               AND p.id_professional NOT IN (SELECT id_professional
                   FROM sr_prof_team_det d1
                  WHERE d1.id_episode_context = i_episode
                    AND d1.flg_status != g_cancel)*/
               AND p.id_professional NOT IN (SELECT *
                                               FROM TABLE(CAST(i_excl_prof AS table_number)))
               AND c.id_category = pc.id_category
               AND c.flg_type IN (g_cat_doctor, g_cat_nurse)
               AND (pi.dt_end_tstz IS NULL OR pi.dt_end_tstz > g_sysdate_tstz)
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
               AND (((translate(upper(pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)),
                                'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                    '%' || translate(upper(i_search_prof), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                    i_search_prof IS NOT NULL) OR
                    (translate(upper(pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL)),
                                'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                                'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                    '%' || translate(upper(i_search_spec), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                    i_search_spec IS NOT NULL) OR
                    (translate(upper(pi.num_mecan), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                    '%' || translate(upper(i_search_num), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%' AND
                    i_search_num IS NOT NULL)))
            -- Profissionais que estejam associados à sala onde se encontra o paciente
            UNION
            SELECT p.id_professional,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) professional_photo,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) prof_name,
                   pi.num_mecan,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, p.id_professional, NULL, NULL) spec_desc,
                   2 p_order,
                   c.flg_type
              FROM professional p, prof_cat pc, category c, prof_institution pi, prof_room pr, epis_info ei
             WHERE i_type = flg_type_surg_record
               AND p.id_professional = pc.id_professional
               AND p.id_professional NOT IN (SELECT *
                                               FROM TABLE(CAST(i_excl_prof AS table_number)))
               AND pc.id_category = c.id_category
               AND pc.id_institution = i_prof.institution
               AND c.flg_type = g_flg_type_nurse
               AND pi.id_professional(+) = p.id_professional
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state(+) = pk_alert_constant.g_active
               AND p.id_professional = pr.id_professional
               AND ei.id_episode = i_episode
               AND ei.id_room = pr.id_room
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, i_prof.institution) =
                   pk_alert_constant.g_yes
             ORDER BY 6, 3;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_PROF_TEAM_SEARCH',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem  a lista de equipas a que um profissional pertence numa dada instituição
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_professional     ID do profissional
    * 
    * @param o_list             Array com as categorias do profissional
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/10/13
       ********************************************************************************************/

    FUNCTION get_prof_category_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_professional IN professional.id_professional%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtem a lista de categorias que podem ser atribuídas ao profissional
        g_error := 'GET CATEGORY LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT s.id_category_sub data, pk_translation.get_translation(i_lang, code_category_sub) label
              FROM category_sub s, category c, prof_cat pc
             WHERE (pc.id_professional = i_professional OR i_professional IS NULL)
               AND s.flg_available = g_flg_available
               AND s.id_category = c.id_category
               AND c.id_category = pc.id_category
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PROF_CATG_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Alterar a sala preferencial e/ou cancelar  
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_room             ID da sala cancelada  
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2007/02/01
       ********************************************************************************************/

    FUNCTION cancel_prof_room
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_room IS
            SELECT id_prof_room
              FROM prof_room
             WHERE id_professional = i_prof.id
               AND id_room = i_room;
    
    BEGIN
    
        --Elimina a sala preferencial do enfermeiro do bloco
        FOR i IN c_room
        LOOP
            g_error := 'DELETE PROF_ROOM';
            pk_alertlog.log_debug(g_error);
            DELETE FROM prof_room
             WHERE id_prof_room = i.id_prof_room;
        
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PROF_ROOM',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns yes or not if the professional is on the surgical team 
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_id_episode               Episode ID
    *                        
    * @return  Yes or no 
    * 
    * @author                         Filipe Silva
    * @version                        2.6
    * @since                          26-01-2010
    **********************************************************************************************/

    FUNCTION get_sr_prof_team
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN PLS_INTEGER IS
    
        l_func_name   VARCHAR2(32) := 'GET_SR_PROF_TEAM';
        err_exception EXCEPTION;
        o_error       t_error_out;
        l_count_prof  NUMBER;
    
    BEGIN
    
        g_error := 'CHECK IF THERE ARE PROFESSIONALS IN SURGERY TEAM';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(*)
          INTO l_count_prof
          FROM sr_prof_team_det sptd
         WHERE sptd.flg_status = pk_alert_constant.g_active
           AND (sptd.id_episode_context = i_id_episode OR sptd.id_episode = i_id_episode)
           AND sptd.id_professional = i_prof.id;
    
        IF l_count_prof > 0
        THEN
            RETURN pk_adt.g_true;
        ELSE
            RETURN pk_adt.g_false;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN pk_alert_constant.g_no;
    END get_sr_prof_team;

    /******************************************************************************
       OBJECTIVE:   CALL SET_SR_PROF_TEAM_DET without commit in the end
       PARAMETERS:  ENTRADA: I_LANG - Language ID
                             I_PROF - Professional object
                             I_SURGERY_RECORD - Surgery Record ID
                             I_EPISODE - Episode ID
                             I_PROF_TEAM - Team ID
                             I_TBL_PROF - Team professionals table
                             I_TBL_CATG - Professionals category table
                             I_TBL_STATUS - Professional status table
                                          NULL - new record
                                          'N' - new record
                                          'C' - update
                                          'D' - delete
                             I_TEST - Validate team?
                    SAIDA:   O_FLG_SHOW - Display message?
                             O_MSG_TITLE - Message title
                             O_MSG_TEXT - Message Text
                             O_BUTTON - Displayed buttons N - no, R - read, C - confirm
                             O_ERROR - error returned
    
      CREATED: Sergio Dias 2010/09/14
      NOTES: ALERT-116342
    *********************************************************************************/
    FUNCTION set_sr_prof_team_det_no_commit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_surgery_record    IN sr_surgery_record.id_surgery_record%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_episode_context   IN episode.id_episode%TYPE,
        i_prof_team         IN prof_team.id_prof_team%TYPE,
        i_tbl_prof          IN table_number,
        i_tbl_catg          IN table_number,
        i_tbl_status        IN table_varchar,
        i_test              IN VARCHAR2,
        i_dt_reg            IN sr_prof_team_det.dt_reg_tstz%TYPE DEFAULT NULL,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE DEFAULT NULL,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_text          OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_tot_prof_catg IS
            SELECT id_category_sub, num_prof, pk_translation.get_translation(i_lang, code_category_sub) desc_category
              FROM category_sub
             WHERE num_prof IS NOT NULL
               AND id_category_sub != g_catg_resp
             ORDER BY rank;
    
        CURSOR c_get_prof_team IS
            SELECT id_prof_team
              FROM sr_prof_team_det
             WHERE id_episode = i_episode
               AND id_category_sub = g_catg_resp
               AND flg_status = g_status_active;
    
        TYPE t_count_categ IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(24);
        l_count               PLS_INTEGER;
        l_count_categ         t_count_categ;
        l_id_prof_resp        professional.id_professional%TYPE;
        l_prof_no_categ       BOOLEAN;
        l_max_prof_exc        BOOLEAN := FALSE;
        l_num_prof            PLS_INTEGER;
        l_catg_resp_desc      pk_translation.t_desc_translation;
        l_curr_count_categ    PLS_INTEGER;
        l_update_prof_leader  BOOLEAN := FALSE;
        l_cur_id_prof_team    sr_prof_team_det.id_prof_team%TYPE;
        l_team_has_changed    BOOLEAN := FALSE;
        l_update_id_prof_team BOOLEAN := FALSE;
    
        l_error VARCHAR2(2000);
    
        l_count_team NUMBER;
    
        l_sr_prof_team_det sr_prof_team_det.id_sr_prof_team_det%TYPE;
    
        l_except EXCEPTION;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        IF i_prof_team = -1
        THEN
            SELECT COUNT(*)
              INTO l_count_team
              FROM sr_prof_team_det sptd
             WHERE sptd.id_sr_epis_interv = i_id_sr_epis_interv
               AND sptd.id_episode = i_episode
               AND sptd.flg_status != 'C';
        
            IF l_count_team > 0
            THEN
                -- Cancela todos os elementos que estão na equipa
                IF NOT update_sr_prof_team_det_hist(i_lang, i_prof, i_id_sr_epis_interv, o_error)
                THEN
                    RAISE l_except;
                END IF;
            
                IF NOT cancel_sr_prof_team_det_hist(i_lang, i_prof, i_id_sr_epis_interv, o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                -- Cancela todos os elementos que estão na equipa
                UPDATE sr_prof_team_det
                   SET flg_status = g_status_cancel, id_prof_cancel = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
                 WHERE id_episode = i_episode
                   AND flg_status != g_status_cancel
                   AND id_sr_epis_interv = i_id_sr_epis_interv;
            END IF;
        
            RETURN TRUE;
        
        END IF;
    
        -- Obtém a descrição de responsável da equipa.
        g_error := 'GET RESP DESCRIPTION';
        pk_alertlog.log_debug(g_error);
        SELECT pk_translation.get_translation(i_lang, code_category_sub)
          INTO l_catg_resp_desc
          FROM category_sub
         WHERE id_category_sub = g_catg_resp;
    
        -- Obtém o id de prof team anterior
        g_error := 'OPEN C_GET_PROF_TEAM';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_prof_team;
        FETCH c_get_prof_team
            INTO l_cur_id_prof_team;
        CLOSE c_get_prof_team;
    
        IF nvl(l_cur_id_prof_team, -1) != nvl(i_prof_team, -1)
        THEN
            l_team_has_changed := TRUE;
        END IF;
    
        -- Preenche o array com o número de elementos por categoria.
        g_error := 'COUNT PROF CATG';
        pk_alertlog.log_debug(g_error);
        FOR i IN 1 .. i_tbl_prof.count
        LOOP
            -- Apenas conta se a linha não for para remover
            IF nvl(i_tbl_status(i), g_status_chg) != g_status_del
            THEN
                IF i_tbl_catg(i) IS NULL
                THEN
                    l_prof_no_categ := TRUE;
                ELSE
                    BEGIN
                        l_curr_count_categ := l_count_categ(to_char(i_tbl_catg(i)));
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_curr_count_categ := 0;
                    END;
                    l_count_categ(to_char(i_tbl_catg(i))) := l_curr_count_categ + 1;
                    -- Se a categoria for a de cirurgião responsável, guarda o id para usar mais tarde.
                    IF i_tbl_catg(i) = g_catg_resp
                    THEN
                        l_id_prof_resp := i_tbl_prof(i);
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        -- Se existirem profissionais sem categoria, envia mensagem
        g_error := 'CHECK PROF NO CATG';
        pk_alertlog.log_debug(g_error);
        IF l_prof_no_categ
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
            o_msg_text  := pk_message.get_message(i_lang, 'SURGERY_ROOM_M024');
            o_button    := 'C';
            RETURN TRUE;
        END IF;
    
        -- Tem que existir pelo menos 1 cirurgião responsável
        g_error := 'CHECK RESP PROF';
        pk_alertlog.log_debug(g_error);
        BEGIN
            l_count := l_count_categ(to_char(g_catg_resp));
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
        END;
    
        IF l_count < 1
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
            o_msg_text  := REPLACE(pk_message.get_message(i_lang, 'SURGERY_ROOM_M025'), '&catg', l_catg_resp_desc);
            o_button    := 'C';
            RETURN TRUE;
        END IF;
    
        IF i_test = 'Y'
        THEN
            g_error := 'CHECK NUM PROF CATG';
            pk_alertlog.log_debug(g_error);
            -- Valida o número de profissionais por categoria.        
            FOR r IN c_tot_prof_catg
            LOOP
                BEGIN
                    l_num_prof := l_count_categ(to_char(r.id_category_sub));
                EXCEPTION
                    WHEN no_data_found THEN
                        l_num_prof := 0;
                END;
                IF nvl(l_num_prof, 0) > r.num_prof
                THEN
                    -- Para esta categoria existem mais profissionais do que o indicado.
                    IF NOT l_max_prof_exc
                    THEN
                        -- Primeiro encontrado
                        l_max_prof_exc := TRUE;
                        o_msg_text     := REPLACE(REPLACE(pk_message.get_message(i_lang, 'SR_LABEL_T257'),
                                                          '&num_prof',
                                                          to_char(l_num_prof)),
                                                  '&catg',
                                                  r.desc_category);
                    ELSE
                        o_msg_text := o_msg_text || chr(13) ||
                                      REPLACE(REPLACE(pk_message.get_message(i_lang, 'SR_LABEL_T257'),
                                                      '&num_prof',
                                                      to_char(l_num_prof)),
                                              '&catg',
                                              r.desc_category);
                    END IF;
                END IF;
            END LOOP;
            IF l_max_prof_exc
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
                o_button    := 'NC';
                RETURN TRUE;
            END IF;
        
            RETURN TRUE;
        END IF;
    
        -- Actualiza a equipa
        IF i_id_sr_epis_interv IS NOT NULL
        THEN
            -- Cancela todos os elementos que estão na equipa
            UPDATE sr_prof_team_det
               SET flg_status = g_status_cancel, id_prof_cancel = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
             WHERE id_episode = i_episode
               AND flg_status != g_status_cancel
               AND id_sr_epis_interv = i_id_sr_epis_interv;
        
            IF NOT update_sr_prof_team_det_hist(i_lang, i_prof, i_id_sr_epis_interv, o_error)
            THEN
                RAISE l_except;
            END IF;
        
        END IF;
    
        l_error := 'ANTES DO FOR i_tbl_prof';
    
        FOR i IN 1 .. i_tbl_prof.count
        LOOP
            -- Insere:
            --    - Caso seja um novo elemento: STATUS='N'
            --    - A equipa (ID_PROF_TEAM) mudou. Neste caso é feito um reset à equipa e toda a informação tem que ser inserida
            IF i_tbl_status(i) = g_status_new
               OR (l_team_has_changed AND nvl(i_tbl_status(i), g_status_new) != g_status_del)
            THEN
                SELECT seq_sr_prof_team_det.nextval
                  INTO l_sr_prof_team_det
                  FROM dual;
                -- Novo registo
                g_error := 'INSERT SR_PROF_TEAM_DET';
                pk_alertlog.log_debug(g_error);
            
                g_error := 'INSERT SR_PROF_TEAM_DET';
            
                INSERT INTO sr_prof_team_det
                    (id_sr_prof_team_det,
                     id_surgery_record,
                     id_episode,
                     id_prof_team_leader,
                     id_professional,
                     id_category_sub,
                     id_prof_team,
                     flg_status,
                     id_prof_reg,
                     dt_reg_tstz,
                     id_episode_context,
                     id_sr_epis_interv)
                VALUES
                    (l_sr_prof_team_det,
                     i_surgery_record,
                     i_episode,
                     l_id_prof_resp,
                     i_tbl_prof(i),
                     i_tbl_catg(i),
                     i_prof_team,
                     g_status_active,
                     i_prof.id,
                     nvl(i_dt_reg, g_sysdate_tstz),
                     --g_sysdate_tstz,
                     nvl(i_episode_context, i_episode),
                     i_id_sr_epis_interv);
            
                g_error := 'CATEGORIA';
                IF i_tbl_catg(i) = g_catg_resp
                THEN
                    l_update_prof_leader := TRUE;
                END IF;
            
                g_error := 'INSERT HIST';
                IF NOT insert_sr_prof_team_det_hist(i_lang, i_prof, i_id_sr_epis_interv, l_sr_prof_team_det, o_error)
                THEN
                    RAISE l_except;
                END IF;
            
                -- Caso o status seja diferente de NULL, significa que houve uma alteração por parte do utilizador e deve ser feito o reset do ID_PROF_TEAM
                --                IF nvl(i_tbl_status(i), '@') != '@'
                --                THEN
                --                    l_update_id_prof_team := TRUE;
                --                END IF;
            ELSE
                IF i_tbl_status(i) = g_status_chg
                THEN
                    -- Actualização registo
                    g_error := 'UPDATE SR_PROF_TEAM_DET';
                    pk_alertlog.log_debug(g_error);
                    UPDATE sr_prof_team_det
                       SET id_category_sub = i_tbl_catg(i), id_prof_reg = i_prof.id, dt_reg_tstz = g_sysdate_tstz
                     WHERE id_episode = i_episode
                       AND (i_surgery_record IS NULL OR
                           (i_surgery_record IS NOT NULL AND id_surgery_record = i_surgery_record))
                       AND id_professional = i_tbl_prof(i)
                       AND id_sr_epis_interv = i_id_sr_epis_interv;
                    IF i_tbl_catg(i) = g_catg_resp
                    THEN
                        l_update_prof_leader := TRUE;
                    END IF;
                    l_update_id_prof_team := TRUE;
                ELSE
                    IF i_tbl_status(i) = g_status_del
                    THEN
                        -- Remover registo
                        g_error := 'CANCEL SR_PROF_TEAM_DET';
                        pk_alertlog.log_debug(g_error);
                        UPDATE sr_prof_team_det
                           SET flg_status     = g_status_cancel,
                               id_prof_cancel = i_prof.id,
                               dt_cancel_tstz = g_sysdate_tstz
                         WHERE id_episode = i_episode
                           AND flg_status != g_status_cancel
                           AND (i_surgery_record IS NULL OR
                               (i_surgery_record IS NOT NULL AND id_surgery_record = i_surgery_record))
                           AND id_professional = i_tbl_prof(i)
                           AND id_sr_epis_interv = i_id_sr_epis_interv;
                    
                        IF NOT update_sr_prof_team_det_hist(i_lang, i_prof, i_id_sr_epis_interv, o_error)
                        THEN
                            RAISE l_except;
                        END IF;
                    
                        l_update_id_prof_team := TRUE;
                    END IF;
                END IF;
            END IF;
        END LOOP;
    
        -- Verifica se tem que actualizar o prof_team_leader
        IF l_update_prof_leader
        THEN
            g_error := 'UPDATE ID_PROF_TEAM_LEADER';
            pk_alertlog.log_debug(g_error);
            UPDATE sr_prof_team_det
               SET id_prof_team_leader = l_id_prof_resp
             WHERE (i_surgery_record IS NULL OR (i_surgery_record IS NOT NULL AND id_surgery_record = i_surgery_record))
               AND id_episode = i_episode
               AND flg_status = g_status_active
               AND id_sr_epis_interv = i_id_sr_epis_interv;
        END IF;
    
        -- Verifica se tem que fazer reset ao ID_PROF_TEAM (caso tenha havido uma alteração ou remoção de um profissional  
        IF l_update_id_prof_team
        THEN
            g_error := 'UPDATE ID_PROF_TEAM';
            pk_alertlog.log_debug(g_error);
            UPDATE sr_prof_team_det
               SET id_prof_team = NULL
             WHERE (i_surgery_record IS NULL OR (i_surgery_record IS NOT NULL AND id_surgery_record = i_surgery_record))
               AND id_episode = i_episode
               AND flg_status = g_status_active
               AND id_sr_epis_interv = i_id_sr_epis_interv;
        END IF;
    
        --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
        IF nvl(i_episode, 0) != 0
           AND i_prof.id IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_PROF_REC';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                              i_prof     => i_prof,
                                              i_episode  => i_episode,
                                              i_patient  => NULL,
                                              i_flg_type => g_flg_type_rec,
                                              o_error    => o_error)
            THEN
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL TO SET_FIRST_OBS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => g_flg_type_doctor,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_except THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SR_PROF_TEAM_DET_NO_COMMIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SR_PROF_TEAM_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    FUNCTION get_sr_interv_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN sr_epis_interv.id_episode_context%TYPE,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error          OUT t_error_out
    ) RETURN VARCHAR2 IS
    
        l_team_name prof_team.prof_team_name%TYPE;
    
        l_team VARCHAR2(4000);
    
        l_team_desc sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'SR_LABEL_T400');
        l_count     NUMBER;
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[:i_sr_epis_interv' || i_sr_epis_interv || ']',
                                       g_package_name,
                                       'GET_SR_INTERV_TEAM');
        g_sysdate_tstz := current_timestamp;
    
        IF i_sr_epis_interv IS NOT NULL
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM sr_prof_team_det sptd
             WHERE sptd.id_sr_epis_interv = i_sr_epis_interv
               AND sptd.flg_status != 'C';
            IF l_count = 0
            THEN
                RETURN NULL;
            END IF;
            --Obtem o nome e descrição da equipa
            g_error := 'GET TEAM NAME AND DESCRIPTION';
            BEGIN
                SELECT nvl(prof_team_name, prof_team_desc)
                  INTO l_team_name
                  FROM prof_team pt, sr_prof_team_det sptd
                 WHERE sptd.id_prof_team = pt.id_prof_team
                   AND sptd.id_sr_epis_interv = i_sr_epis_interv
                   AND sptd.flg_status != 'C'
                   AND rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_team_name := REPLACE(REPLACE(l_team_desc, '(', ''), ')', '');
            END;
        
            l_team := '(' || l_team_name || ') ' ||
                      pk_utils.query_to_string('
                                         select pk_prof_utils.get_name_signature(' ||
                                               i_lang || ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                               i_prof.software ||
                                               '), sptd.id_professional) || '' - '' || pk_translation.get_translation(' ||
                                               i_lang ||
                                               ', c.code_category_sub)
                                             from sr_prof_team_det sptd, category_sub     c  
                                          where sptd.id_sr_epis_interv =' ||
                                               i_sr_epis_interv ||
                                               ' and sptd.id_category_sub = c.id_category_sub(+) and sptd.flg_status != ''C'' ',
                                               '; ');
        
        ELSE
            l_team := pk_utils.query_to_string('SELECT distinct decode(nvl(prof_team_name, prof_team_desc), 
                                                                  null,''' ||
                                               l_team_desc ||
                                               ''',nvl(prof_team_name, prof_team_desc))
                                           FROM prof_team pt, sr_prof_team_det sptd
                                           WHERE sptd.id_prof_team = pt.id_prof_team(+) and sptd.id_episode_context = ' ||
                                               i_episode || ' and sptd.flg_status != ''C'' ',
                                               ';');
        
        END IF;
    
        RETURN l_team;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIVE_DIET',
                                              o_error);
            RETURN NULL;
    END get_sr_interv_team;

    FUNCTION get_sr_interv_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN sr_epis_interv.id_episode_context%TYPE,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN VARCHAR2 IS
        l_team  VARCHAR2(4000);
        l_error t_error_out;
    BEGIN
        l_team := pk_sr_tools.get_sr_interv_team(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_episode        => i_episode,
                                                 i_sr_epis_interv => i_sr_epis_interv,
                                                 o_error          => l_error);
    
        RETURN l_team;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_sr_interv_team;

    FUNCTION get_epis_team_number
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN sr_prof_team_det.id_episode_context%TYPE
    )
    
     RETURN NUMBER IS
    
        n_team NUMBER;
    
    BEGIN
    
        SELECT COUNT(DISTINCT nvl(sptd.id_prof_team, sptd.id_sr_epis_interv))
          INTO n_team
          FROM sr_prof_team_det sptd
         WHERE sptd.id_episode_context = i_episode
           AND sptd.flg_status = g_flg_active;
    
        RETURN n_team;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_epis_team_number;

    FUNCTION get_principal_team
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN sr_prof_team_det.id_episode_context%TYPE
    )
    
     RETURN VARCHAR2 IS
    
        l_sr_epis_interv sr_epis_interv.id_sr_epis_interv%TYPE;
    
        l_team_name VARCHAR2(4000);
        l_team      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'SR_LABEL_T400');
    
        l_count NUMBER;
    BEGIN
    
        BEGIN
            SELECT sei.id_sr_epis_interv
              INTO l_sr_epis_interv
              FROM sr_epis_interv sei
             WHERE sei.id_episode_context = i_episode
               AND sei.flg_status != g_cancel
               AND sei.flg_type = 'P';
        EXCEPTION
            WHEN no_data_found THEN
                l_sr_epis_interv := NULL;
        END;
    
        IF l_sr_epis_interv IS NOT NULL
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM sr_prof_team_det sptd
             WHERE sptd.id_sr_epis_interv = l_sr_epis_interv
               AND sptd.flg_status != 'C';
            IF l_count = 0
            THEN
                RETURN NULL;
            END IF;
        
            BEGIN
                SELECT nvl(prof_team_name, prof_team_desc)
                  INTO l_team_name
                  FROM prof_team pt, sr_prof_team_det sptd
                 WHERE sptd.id_prof_team = pt.id_prof_team(+)
                   AND sptd.id_sr_epis_interv = l_sr_epis_interv
                   AND sptd.flg_status != 'C'
                   AND rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_team_name := l_team;
            END;
        
        ELSE
            -- Verificar se existem secundários 
            l_team_name := get_sr_interv_team(i_lang, i_prof, i_episode, NULL);
        END IF;
    
        IF l_team_name IS NULL
           AND l_sr_epis_interv IS NOT NULL
        THEN
            RETURN l_team;
        ELSE
            RETURN l_team_name;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_principal_team;

    FUNCTION get_team_grid_tooltip
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN sr_prof_team_det.id_episode_context%TYPE
    )
    
     RETURN VARCHAR2 IS
    
        l_team sys_message.desc_message%TYPE := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SR_LABEL_T298');
    
        l_team_desc sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'SR_LABEL_T400');
    
        l_prof_resp sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'SR_LABEL_T233');
    
        l_team_name VARCHAR2(2000);
    
    BEGIN
    
        l_team_name := pk_utils.query_to_string('SELECT distinct ''<b>'' || ''' || l_team ||
                                                ''' || ''</b>'' || chr(13) || decode(nvl(prof_team_name, prof_team_desc), 
                                                                  null,''' ||
                                                l_team_desc ||
                                                ''', nvl(prof_team_name, prof_team_desc)) || '': '' ||  
                                                  pk_sr_tools.get_sr_prof_team_member(' ||
                                                i_lang || ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                                i_prof.software || '),' || i_episode ||
                                                ',sptd.id_sr_epis_interv) 
                                                                   || chr(13) || 
                                                                  ''<b>'' || ''' ||
                                                l_prof_resp ||
                                                ''' || ''</b>'' || chr(13) ||
                                                                  pk_prof_utils.get_name_signature(' ||
                                                i_lang || ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                                i_prof.software ||
                                                '), sptd.id_prof_team_leader)
                                           FROM prof_team pt, sr_prof_team_det sptd
                                           WHERE sptd.id_prof_team = pt.id_prof_team(+) and sptd.id_episode_context = ' ||
                                                i_episode || ' and sptd.flg_status != ''C'' ',
                                                chr(13));
    
        RETURN l_team_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_team_grid_tooltip;

    FUNCTION get_team_profissional
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN sr_prof_team_det.id_episode_context%TYPE
    )
    
     RETURN VARCHAR2 IS
    
        l_sr_epis_interv sr_epis_interv.id_sr_epis_interv%TYPE;
    
        l_team_prof VARCHAR2(4000);
    
    BEGIN
    
        BEGIN
            SELECT sei.id_sr_epis_interv
              INTO l_sr_epis_interv
              FROM sr_epis_interv sei, sr_prof_team_det sptd
             WHERE sei.id_episode_context = i_episode
               AND sei.flg_status != g_cancel
               AND sei.flg_type = 'P'
               AND sei.id_sr_epis_interv = sptd.id_sr_epis_interv
               AND sptd.flg_status != g_cancel
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_sr_epis_interv := NULL;
        END;
    
        IF l_sr_epis_interv IS NOT NULL
        THEN
            BEGIN
                SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, sptd.id_prof_team_leader)
                  INTO l_team_prof
                  FROM sr_prof_team_det sptd
                 WHERE sptd.id_sr_epis_interv = l_sr_epis_interv
                   AND sptd.flg_status != 'C'
                   AND rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_team_prof := NULL;
            END;
        
        ELSE
            -- Verificar se existem secundários 
            l_team_prof := pk_utils.query_to_string('Select distinct pk_prof_utils.get_name_signature(' || i_lang ||
                                                    ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                                    i_prof.software ||
                                                    '), sptd.id_prof_team_leader)
                                           FROM sr_prof_team_det sptd
                                           WHERE sptd.id_episode_context = ' ||
                                                    i_episode || ' and sptd.flg_status != ''C'' ',
                                                    ';');
        END IF;
    
        RETURN l_team_prof;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_team_profissional;

    FUNCTION get_sr_interv_team_name
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN VARCHAR2 IS
    
        l_team_name VARCHAR2(4000);
    
        l_team_desc sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'SR_LABEL_T400');
    
        l_count NUMBER;
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[:i_sr_epis_interv' || i_sr_epis_interv || ']',
                                       g_package_name,
                                       'GET_SR_INTERV_TEAM');
        g_sysdate_tstz := current_timestamp;
    
        IF i_sr_epis_interv IS NOT NULL
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM sr_prof_team_det sptd
             WHERE sptd.id_sr_epis_interv = i_sr_epis_interv
               AND sptd.flg_status != 'C';
            IF l_count = 0
            THEN
                RETURN NULL;
            END IF;
        
            --Obtem o nome e descrição da equipa
            g_error := 'GET TEAM NAME AND DESCRIPTION';
            BEGIN
                SELECT decode(nvl(prof_team_name, prof_team_desc),
                              NULL,
                              l_team_desc,
                              nvl(prof_team_name, prof_team_desc))
                  INTO l_team_name
                  FROM prof_team pt, sr_prof_team_det sptd
                 WHERE sptd.id_prof_team = pt.id_prof_team(+)
                   AND sptd.id_sr_epis_interv = i_sr_epis_interv
                   AND sptd.flg_status != 'C'
                   AND rownum = 1;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_team_name := l_team_desc;
            END;
        ELSE
            l_team_name := NULL;
        END IF;
    
        RETURN l_team_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_sr_interv_team_name;

    FUNCTION get_prof_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN NUMBER IS
    
        l_prof_team prof_team.id_prof_team%TYPE;
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[:i_sr_epis_interv' || i_sr_epis_interv || ']',
                                       g_package_name,
                                       'GET_SR_INTERV_TEAM');
        g_sysdate_tstz := current_timestamp;
    
        IF i_sr_epis_interv IS NOT NULL
        THEN
            --Obtem o nome e descrição da equipa
            g_error := 'GET TEAM NAME AND DESCRIPTION';
            BEGIN
                SELECT DISTINCT sptd.id_prof_team
                  INTO l_prof_team
                  FROM sr_prof_team_det sptd
                 WHERE sptd.id_sr_epis_interv = i_sr_epis_interv
                   AND sptd.flg_status != 'C';
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_prof_team := NULL;
            END;
        ELSE
            l_prof_team := NULL;
        END IF;
    
        RETURN l_prof_team;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prof_team;

    /********************************************************************************************
    * Cancelar a equipa de um procedimento cirurgico
    *
    * @param i_lang           Id do idioma
    * @param i_sr_epis_interv Dados do registo a actualizar
    *
    * @param o_error          Mensagem de erro
    *
    * @return                 TRUE/FALSE
    *
    * @author                 Rita Lopes
    * @since                  2011/10/27
       ********************************************************************************************/

    FUNCTION cancel_sr_prof_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_sysdate_tstz := current_timestamp;
        g_error        := 'UPDATE SR_PROF_TEAM_HIST';
        IF NOT cancel_sr_prof_team_det_hist(i_lang, i_prof, i_sr_epis_interv, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'UPDATE SR_PROF_TEAM';
        UPDATE sr_prof_team_det
           SET flg_status = g_status_cancel, id_prof_cancel = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
         WHERE id_episode = i_episode
           AND flg_status != g_status_cancel
           AND id_sr_epis_interv = i_sr_epis_interv;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_SR_PROF_TEAM',
                                              o_error);
            RETURN FALSE;
    END cancel_sr_prof_team;

    FUNCTION insert_sr_prof_team_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_id_prof_team_det  IN sr_prof_team_det.id_sr_prof_team_det%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_update                   VARCHAR2(1) := 'Y';
        l_rows                     table_varchar;
        l_id_sr_prof_team_det_hist sr_prof_team_det_hist.id_sr_prof_team_det_hist%TYPE;
        l_sr_prof_team_det         sr_prof_team_det%ROWTYPE;
        l_id_sr_epis_interv_hist   sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT sptd.*
              INTO l_sr_prof_team_det
              FROM sr_prof_team_det sptd
             WHERE sptd.id_sr_prof_team_det = i_id_prof_team_det;
        EXCEPTION
            WHEN no_data_found THEN
                l_sr_prof_team_det := NULL;
        END;
    
        BEGIN
            SELECT id_sr_epis_interv_hist
              INTO l_id_sr_epis_interv_hist
              FROM sr_epis_interv_hist
             WHERE id_sr_epis_interv = i_id_sr_epis_interv
               AND flg_status_hist = 'A';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_sr_epis_interv_hist := NULL;
        END;
    
        IF l_sr_prof_team_det.id_sr_prof_team_det IS NOT NULL
           AND l_sr_prof_team_det.id_episode IS NOT NULL
           AND l_sr_prof_team_det.id_prof_team_leader IS NOT NULL
           AND l_sr_prof_team_det.id_professional IS NOT NULL
           AND l_sr_prof_team_det.id_category_sub IS NOT NULL
           AND l_id_sr_epis_interv_hist IS NOT NULL
        THEN
            ts_sr_prof_team_det_hist.ins(id_sr_prof_team_det_in       => l_sr_prof_team_det.id_sr_prof_team_det,
                                         flg_status_hist_in           => 'A',
                                         id_sr_epis_interv_hist_in    => l_id_sr_epis_interv_hist,
                                         id_surgery_record_in         => l_sr_prof_team_det.id_surgery_record,
                                         id_episode_in                => l_sr_prof_team_det.id_episode,
                                         id_prof_team_leader_in       => l_sr_prof_team_det.id_prof_team_leader,
                                         id_professional_in           => l_sr_prof_team_det.id_professional,
                                         id_category_sub_in           => l_sr_prof_team_det.id_category_sub,
                                         id_prof_team_in              => l_sr_prof_team_det.id_prof_team,
                                         flg_status_in                => g_status_active,
                                         id_prof_reg_in               => l_sr_prof_team_det.id_prof_reg,
                                         dt_reg_tstz_in               => l_sr_prof_team_det.dt_reg_tstz,
                                         id_episode_context_in        => l_sr_prof_team_det.id_episode_context,
                                         id_sr_prof_team_det_hist_out => l_id_sr_prof_team_det_hist,
                                         rows_out                     => l_rows);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_SR_PROF_TEAM_DET_HIST',
                                              o_error);
            RETURN FALSE;
    END insert_sr_prof_team_det_hist;

    FUNCTION update_sr_prof_team_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_update                 VARCHAR2(1) := 'Y';
        l_rows                   table_varchar;
        l_sr_prof_team_det_hist  sr_prof_team_det_hist%ROWTYPE;
        l_id_sr_epis_interv_hist sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE;
    
    BEGIN
    
        g_error := 'GET ID For update';
    
        BEGIN
            SELECT MAX(sptdh.id_sr_epis_interv_hist)
              INTO l_id_sr_epis_interv_hist
              FROM sr_prof_team_det_hist sptdh, sr_epis_interv_hist seih
             WHERE sptdh.id_sr_epis_interv_hist = seih.id_sr_epis_interv_hist
               AND seih.id_sr_epis_interv = i_id_sr_epis_interv
               AND sptdh.flg_status_hist = 'A';
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END;
    
        IF l_id_sr_epis_interv_hist IS NOT NULL
        THEN
            g_error := 'UPDATE SR_PROF_TEAM_DET_HIST';
            ts_sr_prof_team_det_hist.upd(flg_status_hist_in  => 'O',
                                         flg_status_hist_nin => FALSE,
                                         where_in            => ' id_sr_epis_interv_hist = ' || l_id_sr_epis_interv_hist,
                                         rows_out            => l_rows);
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_SR_PROF_TEAM_DET_HIST',
                                              o_error);
            RETURN FALSE;
    END update_sr_prof_team_det_hist;

    FUNCTION get_sr_interv_team_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN sr_epis_interv.id_episode_context%TYPE,
        i_sr_epis_interv_hist IN sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE
    ) RETURN VARCHAR2 IS
        l_team_name prof_team.prof_team_name%TYPE;
    
        l_team VARCHAR2(4000);
    
        l_team_desc  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => 'SR_LABEL_T400');
        l_count      NUMBER;
        l_count_hist NUMBER;
    
        l_id_sr_epis_interv_hist sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE;
    
        l_test_team_name VARCHAR2(1) := 'Y';
        l_count_h        NUMBER;
    
        l_id_sr_intervention intervention.id_intervention%TYPE;
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_sr_epis_interv' || i_sr_epis_interv_hist || ']',
                                       g_package_name,
                                       'GET_SR_INTERV_TEAM');
        g_sysdate_tstz := current_timestamp;
    
        IF i_sr_epis_interv_hist IS NOT NULL
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM sr_prof_team_det_hist sptd
             WHERE sptd.id_sr_epis_interv_hist = i_sr_epis_interv_hist;
        
            IF l_count = 0
            THEN
                SELECT id_sr_intervention
                  INTO l_id_sr_intervention
                  FROM sr_epis_interv_hist seih
                 WHERE seih.id_sr_epis_interv_hist = i_sr_epis_interv_hist;
            
                SELECT COUNT(*)
                  INTO l_count_hist
                  FROM sr_prof_team_det_hist sptd, sr_prof_team_det sp, sr_epis_interv sei
                 WHERE sptd.id_sr_epis_interv_hist <= i_sr_epis_interv_hist
                   AND sptd.flg_status != 'C'
                   AND sptd.flg_status_hist != 'O'
                   AND sptd.id_episode = i_episode
                   AND sptd.id_sr_prof_team_det = sp.id_sr_prof_team_det
                   AND sp.id_sr_epis_interv = sei.id_sr_epis_interv
                   AND sei.id_sr_intervention = l_id_sr_intervention;
            
                IF l_count_hist = 0
                THEN
                    SELECT MAX(id_sr_epis_interv_hist)
                      INTO l_id_sr_epis_interv_hist
                      FROM sr_prof_team_det_hist sptd, sr_prof_team_det sp, sr_epis_interv sei
                     WHERE sptd.id_sr_epis_interv_hist <= i_sr_epis_interv_hist
                       AND sptd.id_episode = i_episode
                       AND sptd.flg_status_hist = 'O'
                       AND sptd.id_sr_prof_team_det = sp.id_sr_prof_team_det
                       AND sp.id_sr_epis_interv = sei.id_sr_epis_interv
                       AND sei.id_sr_intervention = l_id_sr_intervention;
                
                    IF l_id_sr_epis_interv_hist IS NULL
                    THEN
                        RETURN NULL;
                    END IF;
                END IF;
            
            END IF;
        
            IF l_count > 0
               OR l_id_sr_epis_interv_hist IS NOT NULL
            THEN
                IF l_id_sr_epis_interv_hist IS NULL
                THEN
                    l_id_sr_epis_interv_hist := i_sr_epis_interv_hist;
                END IF;
                --Obtem o nome e descrição da equipa
                g_error := 'GET TEAM NAME AND DESCRIPTION';
                BEGIN
                    SELECT nvl(prof_team_name, prof_team_desc)
                      INTO l_team_name
                      FROM prof_team pt, sr_prof_team_det_hist sptd
                     WHERE sptd.id_prof_team = pt.id_prof_team
                       AND sptd.id_sr_epis_interv_hist = l_id_sr_epis_interv_hist
                       AND sptd.id_episode = i_episode
                       AND sptd.flg_status != 'C'
                       AND rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_test_team_name := 'N';
                END;
            
                IF l_test_team_name = 'N'
                THEN
                    SELECT COUNT(sptd.id_sr_prof_team_det_hist)
                      INTO l_count_h
                      FROM prof_team pt, sr_prof_team_det_hist sptd
                     WHERE sptd.id_prof_team = pt.id_prof_team
                       AND sptd.id_sr_epis_interv_hist = l_id_sr_epis_interv_hist
                       AND sptd.id_episode = i_episode
                       AND sptd.flg_status = 'C'
                       AND rownum = 1;
                
                    IF l_count_h = 0
                    THEN
                        l_team_name := REPLACE(REPLACE(l_team_desc, '(', ''), ')', '');
                    ELSE
                        RETURN NULL;
                    END IF;
                
                END IF;
            
                l_team := '(' || l_team_name || ') ' ||
                          pk_utils.query_to_string('
                                         select pk_prof_utils.get_name_signature(' ||
                                                   i_lang || ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                                   i_prof.software ||
                                                   '), sptd.id_professional) || '' - '' || pk_translation.get_translation(' ||
                                                   i_lang ||
                                                   ', c.code_category_sub)
                                             from sr_prof_team_det_hist sptd, category_sub     c  
                                          where sptd.id_sr_epis_interv_hist =' ||
                                                   l_id_sr_epis_interv_hist || ' and sptd.id_category_sub = c.id_category_sub(+) and sptd.flg_status != ''C'' 
 ',
                                                   '; ');
            
            ELSE
                g_error := 'GET TEAM NAME AND DESCRIPTION';
                BEGIN
                    SELECT nvl(prof_team_name, prof_team_desc)
                      INTO l_team_name
                      FROM prof_team pt, sr_prof_team_det_hist sptd
                     WHERE sptd.id_prof_team = pt.id_prof_team
                       AND sptd.id_sr_epis_interv_hist <= i_sr_epis_interv_hist
                       AND sptd.id_episode = i_episode
                       AND sptd.flg_status != 'C'
                       AND rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_team_name := REPLACE(REPLACE(l_team_desc, '(', ''), ')', '');
                END;
            
                l_team := '(' || l_team_name || ') ' ||
                          pk_utils.query_to_string('
                                         select pk_prof_utils.get_name_signature(' ||
                                                   i_lang || ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                                   i_prof.software ||
                                                   '), sptd.id_professional) || '' - '' || pk_translation.get_translation(' ||
                                                   i_lang ||
                                                   ', c.code_category_sub)
                                             from sr_prof_team_det_hist sptd, category_sub     c  
                                          where sptd.id_sr_epis_interv_hist <=' ||
                                                   i_sr_epis_interv_hist ||
                                                   ' and sptd.id_category_sub = c.id_category_sub(+) and sptd.flg_status != ''C'' 
                                                  and sptd.id_episode = ' ||
                                                   i_episode || '  and sptd.flg_status_hist = ''A'' 
 ',
                                                   '; ');
            
            END IF;
        ELSE
            l_team := NULL;
        
        END IF;
    
        RETURN l_team;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
    END get_sr_interv_team_hist;

    /********************************************************************************************
    * Cancelar registos da equipa na tabela SR_PROF_TEAM_DET_HIST
    *
    * @param i_lang             Id do idioma
    * @param i_sr_epis_interv   Id sr_epis_interv
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/04/24
       ********************************************************************************************/

    FUNCTION cancel_sr_prof_team_det_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_update                   VARCHAR2(1) := 'Y';
        l_rows                     table_varchar;
        l_id_sr_prof_team_det_hist sr_prof_team_det_hist.id_sr_prof_team_det_hist%TYPE;
        l_sr_prof_team_det         sr_prof_team_det%ROWTYPE;
        l_id_sr_epis_interv_hist   sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE;
    
        CURSOR c_prof_team IS
            SELECT sptd.*
              FROM sr_prof_team_det sptd
             WHERE flg_status != g_status_cancel
               AND id_sr_epis_interv = i_id_sr_epis_interv;
    
        r_prof_team c_prof_team%ROWTYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        BEGIN
            SELECT id_sr_epis_interv_hist
              INTO l_id_sr_epis_interv_hist
              FROM sr_epis_interv_hist
             WHERE id_sr_epis_interv = i_id_sr_epis_interv
               AND flg_status_hist = 'A';
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    
        FOR r_prof_team IN c_prof_team
        LOOP
        
            g_error := 'INSERT SR_PROF_TEAM_DET_HIST - registos cancelados';
            ts_sr_prof_team_det_hist.ins(id_sr_prof_team_det_in       => r_prof_team.id_sr_prof_team_det,
                                         flg_status_hist_in           => 'A',
                                         id_sr_epis_interv_hist_in    => l_id_sr_epis_interv_hist,
                                         id_surgery_record_in         => r_prof_team.id_surgery_record,
                                         id_episode_in                => r_prof_team.id_episode,
                                         id_prof_team_leader_in       => r_prof_team.id_prof_team_leader,
                                         id_professional_in           => r_prof_team.id_professional,
                                         id_category_sub_in           => r_prof_team.id_category_sub,
                                         id_prof_team_in              => r_prof_team.id_prof_team,
                                         flg_status_in                => 'C',
                                         id_prof_reg_in               => r_prof_team.id_prof_reg,
                                         dt_reg_tstz_in               => r_prof_team.dt_reg_tstz,
                                         id_episode_context_in        => r_prof_team.id_episode_context,
                                         id_prof_cancel_in            => i_prof.id,
                                         dt_cancel_tstz_in            => g_sysdate_tstz,
                                         id_sr_prof_team_det_hist_out => l_id_sr_prof_team_det_hist,
                                         rows_out                     => l_rows);
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_SR_PROF_TEAM_DET_HIST',
                                              o_error);
            RETURN FALSE;
    END cancel_sr_prof_team_det_hist;

    FUNCTION get_sr_prof_team_member
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN sr_epis_interv.id_episode_context%TYPE,
        i_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN VARCHAR2 IS
    
        l_team VARCHAR2(4000);
    BEGIN
    
        l_team := pk_utils.query_to_string('
                                         select pk_prof_utils.get_name_signature(' ||
                                           i_lang || ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                                           i_prof.software ||
                                           '), sptd.id_professional) || '' - '' || pk_translation.get_translation(' ||
                                           i_lang ||
                                           ', c.code_category_sub)
                                             from sr_prof_team_det sptd, category_sub     c  
                                          where sptd.id_sr_epis_interv =' ||
                                           i_sr_epis_interv ||
                                           ' and sptd.id_category_sub = c.id_category_sub(+) and sptd.flg_status != ''C'' ',
                                           '; ');
    
        RETURN l_team;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN NULL;
    END get_sr_prof_team_member;

    FUNCTION set_sr_prof_team_det_interface
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_surgery_record    IN sr_surgery_record.id_surgery_record%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_episode_context   IN episode.id_episode%TYPE,
        i_prof_team         IN prof_team.id_prof_team%TYPE,
        i_tbl_prof          IN table_number,
        i_tbl_catg          IN table_number,
        i_tbl_status        IN table_varchar,
        i_test              IN VARCHAR2,
        i_id_sr_epis_interv IN sr_prof_team_det.id_sr_epis_interv%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_text          OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL SET_SR_PROF_TEAM_DET_NO_COMMIT';
        pk_alertlog.log_debug(g_error);
        IF NOT set_sr_prof_team_det_no_commit(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_surgery_record    => i_surgery_record,
                                              i_episode           => i_episode,
                                              i_episode_context   => i_episode_context,
                                              i_prof_team         => i_prof_team,
                                              i_tbl_prof          => i_tbl_prof,
                                              i_tbl_catg          => i_tbl_catg,
                                              i_tbl_status        => i_tbl_status,
                                              i_test              => i_test,
                                              i_dt_reg            => NULL,
                                              i_id_sr_epis_interv => i_id_sr_epis_interv,
                                              o_flg_show          => o_flg_show,
                                              o_msg_title         => o_msg_title,
                                              o_msg_text          => o_msg_text,
                                              o_button            => o_button,
                                              o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SR_PROF_TEAM_DET',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_sr_prof_team_det_interface;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_sr_tools;
/
