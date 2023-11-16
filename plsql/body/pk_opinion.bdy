/*-- Last Change Revision: $Rev: 2055299 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-17 10:53:04 +0000 (sex, 17 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_opinion IS

    e_pat_tracking EXCEPTION;
    g_found BOOLEAN;

    /************************************************************************************************************
    * This function returns the specialities for the the professionals that can give a consult (opinion).
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      o_spec            Specialities output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     CRS
    * @version    1.0
    * @since      2005/03/09
    ************************************************************************************************************/
    FUNCTION get_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_spec  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT obj_name := 'GET_SPEC_LIST';
        l_message debug_msg;
    
        l_opt_func_id prof_func.id_functionality%TYPE;
        l_prof_cat    category.flg_type%TYPE;
    
    BEGIN
    
        l_message     := 'GET CONFIG';
        l_opt_func_id := pk_sysconfig.get_config(i_code_cf   => 'FUNCTIONALITY_OPINION',
                                                 i_prof_inst => i_prof.institution,
                                                 i_prof_soft => i_prof.software);
    
        l_message := 'GET PROFESSIONAL CATEGORY';
        IF pk_sysconfig.get_config('SET_OPINION_ONLY_DOC', i_prof) = pk_alert_constant.g_no
        THEN
            l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        ELSE
            l_prof_cat := pk_alert_constant.g_cat_type_doc;
        END IF;
    
        l_message := 'OPEN O_SPEC';
        OPEN o_spec FOR
            SELECT pd.id_speciality identifier,
                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                      FROM speciality s
                     WHERE pd.id_speciality = s.id_speciality) AS description
              FROM (SELECT DISTINCT p.id_speciality
                      FROM professional p
                     INNER JOIN prof_institution pi
                        ON p.id_professional = pi.id_professional
                     INNER JOIN prof_soft_inst psi
                        ON p.id_professional = psi.id_professional
                       AND pi.id_institution = psi.id_institution
                     INNER JOIN prof_func pf
                        ON p.id_professional = pf.id_professional
                       AND pi.id_institution = pf.id_institution
                     INNER JOIN prof_cat pc
                        ON p.id_professional = pc.id_professional
                       AND pi.id_institution = pc.id_institution
                     INNER JOIN category c
                        ON pc.id_category = c.id_category
                     INNER JOIN speciality s
                        ON s.id_speciality = p.id_speciality
                     WHERE p.id_professional != i_prof.id
                       AND p.flg_state = g_prof_active
                       AND p.id_speciality IS NOT NULL
                       AND pi.id_institution = i_prof.institution
                       AND pi.flg_state = g_prof_active
                       AND pi.dt_end_tstz IS NULL
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, pi.id_institution) =
                           pk_alert_constant.g_yes
                       AND s.flg_available = pk_alert_constant.g_yes
                       AND pf.id_functionality = l_opt_func_id
                       AND c.flg_type = l_prof_cat) pd
             ORDER BY description;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_spec);
            RETURN FALSE;
    END get_spec_list;

    FUNCTION tf_get_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
        l_func_name CONSTANT obj_name := 'TF_GET_SPEC_LIST';
        l_message debug_msg;
    
        l_opt_func_id prof_func.id_functionality%TYPE;
        l_prof_cat    category.flg_type%TYPE;
    
        l_list_type sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'OPINION_PROF_LIST_GROUP_BY',
                                                                     i_prof_inst => i_prof.institution,
                                                                     i_prof_soft => i_prof.software);
    
        l_ret t_tbl_core_domain;
    BEGIN
    
        IF l_list_type = 'C'
        THEN
            l_ret := pk_opinion.get_clin_serv_list(i_lang => i_lang, i_prof => i_prof, o_error => o_error);
        ELSE
            l_message     := 'GET CONFIG';
            l_opt_func_id := pk_sysconfig.get_config(i_code_cf   => 'FUNCTIONALITY_OPINION',
                                                     i_prof_inst => i_prof.institution,
                                                     i_prof_soft => i_prof.software);
        
            l_message := 'GET PROFESSIONAL CATEGORY';
            IF pk_sysconfig.get_config('SET_OPINION_ONLY_DOC', i_prof) = pk_alert_constant.g_no
            THEN
                l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
            ELSE
                l_prof_cat := pk_alert_constant.g_cat_type_doc;
            END IF;
        
            l_message := 'OPEN L_RET';
            SELECT *
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t_row_core_domain(internal_name => NULL,
                                             desc_domain   => description,
                                             domain_value  => identifier,
                                             order_rank    => NULL,
                                             img_name      => NULL)
                      FROM (SELECT pd.id_speciality identifier,
                                   (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                                      FROM speciality s
                                     WHERE pd.id_speciality = s.id_speciality) AS description
                              FROM (SELECT DISTINCT p.id_speciality
                                      FROM professional p
                                     INNER JOIN prof_institution pi
                                        ON p.id_professional = pi.id_professional
                                     INNER JOIN prof_soft_inst psi
                                        ON p.id_professional = psi.id_professional
                                       AND pi.id_institution = psi.id_institution
                                     INNER JOIN prof_func pf
                                        ON p.id_professional = pf.id_professional
                                       AND pi.id_institution = pf.id_institution
                                     INNER JOIN prof_cat pc
                                        ON p.id_professional = pc.id_professional
                                       AND pi.id_institution = pc.id_institution
                                     INNER JOIN category c
                                        ON pc.id_category = c.id_category
                                     INNER JOIN speciality s
                                        ON s.id_speciality = p.id_speciality
                                     WHERE p.id_professional != i_prof.id
                                       AND p.flg_state = g_prof_active
                                       AND p.id_speciality IS NOT NULL
                                       AND pi.id_institution = i_prof.institution
                                       AND pi.flg_state = g_prof_active
                                       AND pi.dt_end_tstz IS NULL
                                       AND pk_prof_utils.is_internal_prof(i_lang,
                                                                          i_prof,
                                                                          p.id_professional,
                                                                          pi.id_institution) = pk_alert_constant.g_yes
                                       AND s.flg_available = pk_alert_constant.g_yes
                                       AND pf.id_functionality = l_opt_func_id
                                       AND c.flg_type = l_prof_cat) pd
                             ORDER BY description));
        END IF;
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END tf_get_spec_list;

    FUNCTION get_spec_list_by_config
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain IS
        l_ret t_tbl_core_domain;
    
        l_config sys_config.value%TYPE := pk_sysconfig.get_config('OPINION_PROF_LIST_GROUP_BY', i_prof);
        l_error  t_error_out;
    BEGIN
    
        IF l_config = 'C'
        THEN
            l_ret := pk_opinion.get_clin_serv_list(i_lang => i_lang, i_prof => i_prof, o_error => l_error);
        ELSE
            l_ret := pk_opinion.tf_get_spec_list(i_lang => i_lang, i_prof => i_prof, o_error => l_error);
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SPEC_LIST_BY_CONFIG',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_spec_list_by_config;

    /************************************************************************************************************
    * This function returns the professionals for a speciality that can give a consult (opinion).
    * And excludes the professional that makes the request.
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      i_speciality      Speciality id for the consult
    * @param      o_prof            Professionals output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     CRS
    * @version    1.0
    * @since      2005/03/10
    ************************************************************************************************************/
    FUNCTION get_prof_spec_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_speciality IN speciality.id_speciality%TYPE,
        o_prof       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT obj_name := 'GET_PROF_SPEC_LIST';
        l_message debug_msg;
    
        l_opt_func_id prof_func.id_functionality%TYPE;
        l_prof_cat    category.flg_type%TYPE;
    
    BEGIN
        l_message     := 'GET CONFIG';
        l_opt_func_id := pk_sysconfig.get_config(i_code_cf   => 'FUNCTIONALITY_OPINION',
                                                 i_prof_inst => i_prof.institution,
                                                 i_prof_soft => i_prof.software);
    
        l_message := 'GET PROFESSIONAL CATEGORY';
        IF pk_sysconfig.get_config('SET_OPINION_ONLY_DOC', i_prof) = pk_alert_constant.g_no
        THEN
            l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        ELSE
            l_prof_cat := pk_alert_constant.g_cat_type_doc;
        END IF;
    
        l_message := 'OPEN O_PROF';
        OPEN o_prof FOR
            SELECT DISTINCT p.id_professional,
                            1 AS rank,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS nick_name
              FROM professional p
             INNER JOIN prof_institution pi
                ON p.id_professional = pi.id_professional
             INNER JOIN prof_func pf
                ON p.id_professional = pf.id_professional
               AND pi.id_institution = pi.id_institution
             INNER JOIN prof_cat pc
                ON p.id_professional = pc.id_professional
               AND pi.id_institution = pc.id_institution
             INNER JOIN category c
                ON pc.id_category = c.id_category
             WHERE p.id_professional != i_prof.id
               AND p.id_speciality = i_speciality
               AND p.flg_state = g_prof_active
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state = g_prof_active
               AND pi.dt_end_tstz IS NULL
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, pi.id_institution) =
                   pk_alert_constant.g_yes
               AND pf.id_functionality = l_opt_func_id
               AND c.flg_type = l_prof_cat
            UNION ALL
            SELECT -1 AS id_professional,
                   -1 AS rank,
                   pk_message.get_message(i_lang, i_prof, 'OPINION_M001') AS nick_name
              FROM dual
             WHERE i_speciality IS NOT NULL
             ORDER BY rank, nick_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_prof);
            RETURN FALSE;
    END get_prof_spec_list;

    FUNCTION tf_get_prof_spec_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_speciality IN speciality.id_speciality%TYPE,
        o_error      OUT t_error_out
    ) RETURN t_tbl_core_domain IS
        l_func_name CONSTANT obj_name := 'TF_GET_PROF_SPEC_LIST';
        l_message debug_msg;
    
        l_opt_func_id prof_func.id_functionality%TYPE;
        l_prof_cat    category.flg_type%TYPE;
    
        l_ret t_tbl_core_domain;
    BEGIN
        l_message     := 'GET CONFIG';
        l_opt_func_id := pk_sysconfig.get_config(i_code_cf   => 'FUNCTIONALITY_OPINION',
                                                 i_prof_inst => i_prof.institution,
                                                 i_prof_soft => i_prof.software);
    
        l_message := 'GET PROFESSIONAL CATEGORY';
        IF pk_sysconfig.get_config('SET_OPINION_ONLY_DOC', i_prof) = pk_alert_constant.g_no
        THEN
            l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        ELSE
            l_prof_cat := pk_alert_constant.g_cat_type_doc;
        END IF;
    
        l_message := 'OPEN L_RET';
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => nick_name,
                                         domain_value  => id_professional,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT DISTINCT p.id_professional,
                                        1 AS rank,
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS nick_name
                          FROM professional p
                         INNER JOIN prof_institution pi
                            ON p.id_professional = pi.id_professional
                         INNER JOIN prof_func pf
                            ON p.id_professional = pf.id_professional
                           AND pi.id_institution = pi.id_institution
                         INNER JOIN prof_cat pc
                            ON p.id_professional = pc.id_professional
                           AND pi.id_institution = pc.id_institution
                         INNER JOIN category c
                            ON pc.id_category = c.id_category
                         WHERE p.id_professional != i_prof.id
                           AND (p.id_speciality = i_speciality OR i_speciality IS NULL)
                           AND p.flg_state = g_prof_active
                           AND pi.id_institution = i_prof.institution
                           AND pi.flg_state = g_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, pi.id_institution) =
                               pk_alert_constant.g_yes
                           AND pf.id_functionality = l_opt_func_id
                           AND c.flg_type = l_prof_cat
                        UNION ALL
                        SELECT -1 AS id_professional,
                               -1 AS rank,
                               pk_message.get_message(i_lang, i_prof, 'COMMON_M059') AS nick_name
                          FROM dual
                         WHERE i_speciality IS NOT NULL
                         ORDER BY rank, nick_name));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END tf_get_prof_spec_list;

    FUNCTION get_prof_spec_list_by_config
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_speciality IN speciality.id_speciality%TYPE
    ) RETURN t_tbl_core_domain IS
        l_ret t_tbl_core_domain;
    
        l_config sys_config.value%TYPE := pk_sysconfig.get_config('OPINION_PROF_LIST_GROUP_BY', i_prof);
        l_error  t_error_out;
    BEGIN
    
        IF l_config = 'C'
        THEN
            l_ret := pk_opinion.get_prof_clin_serv_list(i_lang         => i_lang,
                                                        i_prof         => i_prof,
                                                        i_clin_serv_id => i_speciality,
                                                        o_error        => l_error);
        ELSE
            l_ret := pk_opinion.tf_get_prof_spec_list(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_speciality => i_speciality,
                                                      o_error      => l_error);
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_SPEC_LIST_BY_CONFIG',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_prof_spec_list_by_config;

    /********************************************************************************************
    * Get opinion professional description
    *
    * @param    i_lang                preferred language ID
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_opinion_prof        opinion professional ID
    *
    * @return   varchar2              opinion professional description
    *
    * @author                         Tiago Silva
    * @since                          2010/08/06
    ********************************************************************************************/
    FUNCTION get_opinion_prof_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_prof IN professional.id_professional%TYPE
    ) RETURN professional.name%TYPE IS
        l_opinion_prof_desc professional.name%TYPE;
    BEGIN
    
        g_error := 'GET OPINION PROFESSIONAL DESCRIPTION';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT nick_name
          INTO l_opinion_prof_desc
          FROM (SELECT p.id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS nick_name
                  FROM professional p
                 WHERE i_opinion_prof != -1
                UNION ALL
                SELECT -1 AS id_professional, pk_message.get_message(i_lang, i_prof, 'OPINION_M001') AS nick_name
                  FROM dual)
         WHERE id_professional = i_opinion_prof;
    
        RETURN l_opinion_prof_desc;
    
    END get_opinion_prof_desc;

    /********************************************************************************************
    * Esta fun? gera alertas de resposta a pedidos de parecer.
    *
    * @param i_lang          Id do idioma
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Carlos Vieira
    * @version               1.0
    * @since                 2008/03/25
    ********************************************************************************************/
    FUNCTION alert_opinion_request
    (
        i_lang     IN NUMBER,
        i_opinion  IN NUMBER,
        i_flg_type IN opinion.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sys_alert    sys_alert_event.id_sys_alert%TYPE; --OPINION_REQUEST
        l_sys_alert_event sys_alert_event%ROWTYPE;
        l_prof            profissional;
        CURSOR c_get_opinion IS
            SELECT o.flg_state,
                   ep.id_software,
                   e.id_institution,
                   e.id_patient,
                   e.id_visit,
                   o.id_episode,
                   o.id_opinion,
                   o.dt_problem_tstz,
                   o.id_prof_questioned id_professional,
                   ep.id_room,
                   e.id_clinical_service,
                   --pk_prof_utils.get_name_signature(i_lang, i_prof, pf.id_professional) name
                   -- sem categoria n??ossivel obter a estrutura i_prof, n?sendo poss?l utilizar a fun? get_name_signature
                   pf.name name,
                   CASE
                        WHEN o.flg_priority IS NOT NULL THEN
                         ' (' || pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang) || ')'
                        ELSE
                         NULL
                    END priority
              FROM opinion o, episode e, professional pf, epis_info ep
             WHERE o.flg_state IN ('R', 'F', 'C') --REQUISITADO E LIDO PORQUE PODE TER SIDO LIDO POR OUTRO PROFISSIONAL
               AND ep.id_episode = e.id_episode
               AND o.id_opinion = i_opinion
               AND o.dt_problem_tstz >
                   pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                e.id_institution,
                                                                                                NULL),
                                                                                   current_timestamp,
                                                                                   NULL),
                                                  -pk_sysconfig.get_config('ALERT_EXPIRE_OPINION_REQUEST',
                                                                           e.id_institution,
                                                                           ep.id_software))
               AND o.id_prof_questions = pf.id_professional --PODE SER PEDIDO A UM PROFESSIONAL OU A TODOS DE UMA ESPECIALIDADE
               AND ep.id_software = pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
               AND e.id_episode = o.id_episode
               AND e.flg_status IN (pk_alerts.g_epis_active, pk_alerts.g_epis_pend);
    
    BEGIN
        pk_alertlog.log_info('delete_sys_alert_event id_sys_alert' || l_id_sys_alert,
                             g_package_name,
                             'ALERT_OPINION_REQUEST');
    
        IF i_flg_type = g_flg_type_nutritionist
        THEN
            l_id_sys_alert := 60;
        ELSIF i_flg_type = g_flg_type_case_manager
        THEN
            l_id_sys_alert := 81;
        ELSE
            l_id_sys_alert := 8;
        END IF;
    
        IF NOT pk_alerts.is_event_version(l_id_sys_alert)
        THEN
            pk_alertlog.log_info('delete_sys_alert_event id_sys_alert is ' || l_id_sys_alert,
                                 g_package_name,
                                 'ALERT_OPINION_REQUEST');
            RETURN TRUE;
        END IF;
    
        FOR c IN c_get_opinion
        LOOP
            l_sys_alert_event.id_sys_alert        := l_id_sys_alert;
            l_sys_alert_event.id_software         := c.id_software;
            l_sys_alert_event.id_institution      := c.id_institution;
            l_sys_alert_event.id_patient          := c.id_patient;
            l_sys_alert_event.id_visit            := c.id_visit;
            l_sys_alert_event.id_episode          := c.id_episode;
            l_sys_alert_event.id_record           := c.id_opinion;
            l_sys_alert_event.dt_record           := c.dt_problem_tstz;
            l_sys_alert_event.id_professional     := c.id_professional;
            l_sys_alert_event.id_room             := c.id_room;
            l_sys_alert_event.id_clinical_service := c.id_clinical_service;
            l_sys_alert_event.flg_visible         := NULL;
            l_sys_alert_event.replace1            := c.name || c.priority;
            l_sys_alert_event.replace2            := NULL;
            l_prof                                := profissional(c.id_professional, c.id_institution, c.id_software);
            IF c.flg_state IN ('P', 'C')
            THEN
                pk_alertlog.log_info('delete_sys_alert_event id_sys_alert' || l_id_sys_alert || ' ' || 'id_opinion' ||
                                     c.id_opinion,
                                     g_package_name,
                                     'ALERT_OPINION_REQUEST');
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => l_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                pk_alertlog.log_info('insert_sys_alert_event id_sys_alert' || l_id_sys_alert || ' ' || 'id_opinion' ||
                                     c.id_opinion,
                                     g_package_name,
                                     'ALERT_OPINION_REQUEST');
                IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => l_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'ALERT_OPINION_REQUEST',
                                                     o_error);
    END;

    /********************************************************************************************
    * Esta fun? gera alertas de resposta a pedidos de parecer.
    *
    * @param i_lang          Id do idioma
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Carlos Vieira
    * @version               1.0
    * @since                 2008/03/25
    ********************************************************************************************/
    FUNCTION alert_opinion_reply
    (
        i_lang            IN NUMBER,
        i_opinion         IN NUMBER,
        i_flg_type        IN VARCHAR2,
        i_flg_type_opinon IN opinion.flg_type%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sys_alert    sys_alert_event.id_sys_alert%TYPE; --OPINION_REQUEST
        l_sys_alert_event sys_alert_event%ROWTYPE;
        l_prof            profissional;
        CURSOR c_get_opinion IS
            SELECT o.flg_state,
                   ep.id_software,
                   e.id_institution,
                   e.id_patient,
                   e.id_visit,
                   o.id_episode,
                   o.id_opinion,
                   o.dt_problem_tstz,
                   o.id_prof_questions id_professional,
                   ep.id_room,
                   e.id_clinical_service,
                   --pk_prof_utils.get_name_signature(i_lang, i_prof, pf.id_professional) name
                   -- sem categoria n??ossivel obter a estrutura i_prof, n?sendo poss?l utilizar a fun? get_name_signature
                   pf.name name
              FROM opinion o, speciality s, professional pf, episode e, epis_info ep
             WHERE ((o.id_prof_questioned IS NOT NULL AND pf.id_professional = o.id_prof_questioned AND
                   s.id_speciality = pf.id_speciality) OR
                   (o.id_prof_questioned IS NULL AND pf.id_professional = o.id_prof_questions AND
                   s.id_speciality = o.id_speciality))
               AND e.id_episode = o.id_episode
               AND ep.id_software = pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
               AND e.flg_status IN (pk_alerts.g_epis_active, pk_alerts.g_epis_pend)
               AND ep.id_episode = e.id_episode
               AND o.id_opinion = i_opinion;
    
        CURSOR c_get_opinion_nutri IS
            SELECT o.flg_state,
                   ep.id_software,
                   e.id_institution,
                   e.id_patient,
                   e.id_visit,
                   o.id_episode,
                   o.id_opinion,
                   op.dt_opinion_prof_tstz dt_problem_tstz,
                   o.id_prof_questions     id_professional,
                   ep.id_room,
                   e.id_clinical_service,
                   --pk_prof_utils.get_name_signature(i_lang, i_prof, pf.id_professional) name
                   -- sem categoria n??ossivel obter a estrutura i_prof, n?sendo poss?l utilizar a fun? get_name_signature
                   pf.name name
              FROM opinion o, opinion_prof op, professional pf, episode e, epis_info ep
             WHERE o.flg_type = g_flg_type_nutritionist
               AND e.id_episode = o.id_episode
               AND ep.id_software = pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
               AND e.flg_status IN (pk_alerts.g_epis_active, pk_alerts.g_epis_pend)
               AND ep.id_episode = e.id_episode
               AND o.id_opinion = i_opinion
               AND o.id_opinion = op.id_opinion
               AND op.flg_type = 'P'
               AND pf.id_professional = op.id_professional;
    
        CURSOR c_get_opinion_cm IS
            SELECT o.flg_state,
                   ep.id_software,
                   e.id_institution,
                   e.id_patient,
                   e.id_visit,
                   o.id_episode,
                   o.id_opinion,
                   op.dt_opinion_prof_tstz dt_problem_tstz,
                   o.id_prof_questions     id_professional,
                   ep.id_room,
                   e.id_clinical_service,
                   pf.name                 name
              FROM opinion o, opinion_prof op, professional pf, episode e, epis_info ep
             WHERE o.flg_type = g_flg_type_case_manager
               AND e.id_episode = o.id_episode
               AND ep.id_software = pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
               AND e.flg_status IN (pk_alerts.g_epis_active, pk_alerts.g_epis_pend)
               AND ep.id_episode = e.id_episode
               AND o.id_opinion = i_opinion
               AND o.id_opinion = op.id_opinion
               AND op.flg_type = 'P'
               AND pf.id_professional = op.id_professional;
    
    BEGIN
        pk_alertlog.log_info('alert_opinion_reply *1 id_sys_alert' || l_id_sys_alert,
                             g_package_name,
                             'ALERT_OPINION_REPLY');
        IF i_flg_type_opinon = g_flg_type_nutritionist
        THEN
            l_id_sys_alert := 61;
        ELSIF i_flg_type_opinon = g_flg_type_case_manager
        THEN
            l_id_sys_alert := 82;
        ELSE
            l_id_sys_alert := 7;
        END IF;
        IF NOT pk_alerts.is_event_version(l_id_sys_alert)
        THEN
            pk_alertlog.log_info('alert_opinion_reply *2 id_sys_alert is ' || l_id_sys_alert,
                                 g_package_name,
                                 'ALERT_OPINION_REPLY');
            RETURN TRUE;
        END IF;
    
        IF i_flg_type_opinon = g_flg_type_nutritionist
        THEN
            FOR c IN c_get_opinion_nutri
            LOOP
                l_sys_alert_event.id_sys_alert        := l_id_sys_alert;
                l_sys_alert_event.id_software         := c.id_software;
                l_sys_alert_event.id_institution      := c.id_institution;
                l_sys_alert_event.id_patient          := c.id_patient;
                l_sys_alert_event.id_visit            := c.id_visit;
                l_sys_alert_event.id_episode          := c.id_episode;
                l_sys_alert_event.id_record           := c.id_opinion;
                l_sys_alert_event.dt_record           := c.dt_problem_tstz;
                l_sys_alert_event.id_professional     := c.id_professional;
                l_sys_alert_event.id_room             := c.id_room;
                l_sys_alert_event.id_clinical_service := c.id_clinical_service;
                l_sys_alert_event.flg_visible         := NULL;
                l_sys_alert_event.replace1            := c.name;
                l_sys_alert_event.replace2            := NULL;
                l_prof                                := profissional(c.id_professional,
                                                                      c.id_institution,
                                                                      c.id_software);
                IF c.flg_state = 'P'
                THEN
                    --            ELSE
                    pk_alertlog.log_info('alert_opinion_reply *4 id_sys_alert' || l_id_sys_alert || ' ' ||
                                         'id_opinion' || c.id_opinion,
                                         g_package_name,
                                         'ALERT_OPINION_REPLY');
                    IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => l_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
                --
                IF i_flg_type != g_opin_prof_read
                THEN
                    IF i_flg_type_opinon = g_flg_type_nutritionist
                    THEN
                        l_sys_alert_event.id_sys_alert := 60;
                    ELSIF i_flg_type_opinon = g_flg_type_case_manager
                    THEN
                        l_sys_alert_event.id_sys_alert := 81;
                    ELSE
                        l_sys_alert_event.id_sys_alert := 8;
                    END IF;
                    pk_alertlog.log_info('alert_opinion_reply *3 id_sys_alert' || l_id_sys_alert || ' ' ||
                                         'id_opinion' || c.id_opinion,
                                         g_package_name,
                                         'ALERT_OPINION_REPLY');
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => l_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
            END LOOP;
        ELSIF i_flg_type_opinon = g_flg_type_case_manager
        -- case manager requests
        THEN
            FOR c IN c_get_opinion_cm
            LOOP
                l_sys_alert_event.id_sys_alert        := l_id_sys_alert;
                l_sys_alert_event.id_software         := c.id_software;
                l_sys_alert_event.id_institution      := c.id_institution;
                l_sys_alert_event.id_patient          := c.id_patient;
                l_sys_alert_event.id_visit            := c.id_visit;
                l_sys_alert_event.id_episode          := c.id_episode;
                l_sys_alert_event.id_record           := c.id_opinion;
                l_sys_alert_event.dt_record           := c.dt_problem_tstz;
                l_sys_alert_event.id_professional     := c.id_professional;
                l_sys_alert_event.id_room             := c.id_room;
                l_sys_alert_event.id_clinical_service := c.id_clinical_service;
                l_sys_alert_event.flg_visible         := NULL;
                l_sys_alert_event.replace1            := c.name;
                l_sys_alert_event.replace2            := NULL;
                l_prof                                := profissional(c.id_professional,
                                                                      c.id_institution,
                                                                      c.id_software);
                IF c.flg_state = 'R'
                THEN
                    pk_alertlog.log_info('alert_opinion_reply *4 id_sys_alert' || l_id_sys_alert || ' ' ||
                                         'id_opinion' || c.id_opinion,
                                         g_package_name,
                                         'ALERT_OPINION_REPLY');
                    IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => l_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
                --
                IF i_flg_type != g_opin_prof_read
                THEN
                    IF i_flg_type_opinon = g_flg_type_nutritionist
                    THEN
                        l_sys_alert_event.id_sys_alert := 60;
                    ELSIF i_flg_type_opinon = g_flg_type_case_manager
                    THEN
                        l_sys_alert_event.id_sys_alert := 81;
                    ELSE
                        l_sys_alert_event.id_sys_alert := 8;
                    END IF;
                    pk_alertlog.log_info('alert_opinion_reply *3 id_sys_alert' || l_id_sys_alert || ' ' ||
                                         'id_opinion' || c.id_opinion,
                                         g_package_name,
                                         'ALERT_OPINION_REPLY');
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => l_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
            END LOOP;
        ELSE
        
            FOR c IN c_get_opinion
            LOOP
                l_sys_alert_event.id_sys_alert        := l_id_sys_alert;
                l_sys_alert_event.id_software         := c.id_software;
                l_sys_alert_event.id_institution      := c.id_institution;
                l_sys_alert_event.id_patient          := c.id_patient;
                l_sys_alert_event.id_visit            := c.id_visit;
                l_sys_alert_event.id_episode          := c.id_episode;
                l_sys_alert_event.id_record           := c.id_opinion;
                l_sys_alert_event.dt_record           := c.dt_problem_tstz;
                l_sys_alert_event.id_professional     := c.id_professional;
                l_sys_alert_event.id_room             := c.id_room;
                l_sys_alert_event.id_clinical_service := c.id_clinical_service;
                l_sys_alert_event.flg_visible         := NULL;
                l_sys_alert_event.replace1            := c.name;
                l_sys_alert_event.replace2            := NULL;
                l_prof                                := profissional(c.id_professional,
                                                                      c.id_institution,
                                                                      c.id_software);
                IF c.flg_state = 'P'
                THEN
                    --            ELSE
                    pk_alertlog.log_info('alert_opinion_reply *4 id_sys_alert' || l_id_sys_alert || ' ' ||
                                         'id_opinion' || c.id_opinion,
                                         g_package_name,
                                         'ALERT_OPINION_REPLY');
                    IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => l_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
                --
                IF i_flg_type != g_opin_prof_read
                THEN
                    IF i_flg_type_opinon = g_flg_type_nutritionist
                    THEN
                        l_sys_alert_event.id_sys_alert := 60;
                    ELSIF i_flg_type_opinon = g_flg_type_case_manager
                    THEN
                        l_sys_alert_event.id_sys_alert := 81;
                    ELSE
                        l_sys_alert_event.id_sys_alert := 8;
                    END IF;
                    pk_alertlog.log_info('alert_opinion_reply *3 id_sys_alert' || l_id_sys_alert || ' ' ||
                                         'id_opinion' || c.id_opinion,
                                         g_package_name,
                                         'ALERT_OPINION_REPLY');
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => l_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
            END LOOP;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     NULL,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'ALERT_OPINION_REPLY',
                                                     o_error);
    END;
    --

    FUNCTION create_opinion
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_flg_origin_req       IN VARCHAR2 DEFAULT 'D',
        i_flg_update           IN VARCHAR2 DEFAULT 'N',
        i_opinion              IN opinion.id_opinion%TYPE DEFAULT NULL,
        o_opinion              OUT opinion.id_opinion%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_questioned  opinion.id_prof_questioned%TYPE;
        l_speciality       opinion.id_speciality%TYPE;
        l_clinical_service clinical_service.id_clinical_service%TYPE;
        l_desc             opinion.desc_problem%TYPE;
        l_prof_cat_type    category.flg_type%TYPE;
        l_flg_type         opinion.flg_type%TYPE;
        l_flg_priority     opinion.flg_priority%TYPE DEFAULT 'N';
    
        l_config sys_config.value%TYPE := pk_sysconfig.get_config('OPINION_PROF_LIST_GROUP_BY', i_prof);
    BEGIN
    
        g_error := 'GETTING l_prof_cat_type';
        SELECT c.flg_type
          INTO l_prof_cat_type
          FROM prof_cat pc
          JOIN category c
            ON c.id_category = pc.id_category
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution;
    
        g_error := 'GETTING DYNAMIC FORM VALUES';
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_professional
            THEN
                l_prof_questioned := to_number(i_tbl_real_val(i) (1));
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_clinical_service
            THEN
                IF l_config = 'C'
                THEN
                    l_clinical_service := to_number(i_tbl_real_val(i) (1));
                ELSE
                    l_speciality := to_number(i_tbl_real_val(i) (1));
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_specialty
            THEN
                IF l_config = 'C'
                THEN
                    l_clinical_service := to_number(i_tbl_real_val(i) (1));
                ELSE
                    l_speciality := to_number(i_tbl_real_val(i) (1));
                END IF;
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_priority
            THEN
                l_flg_priority := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = pk_orders_constant.g_ds_notes
            THEN
                l_desc := i_tbl_real_val(i) (1);
            END IF;
        END LOOP;
    
        g_error := 'CALL TO PK_OPINION.CREATE_OPINION';
        IF NOT pk_opinion.create_opinion(i_lang             => i_lang,
                                         i_episode          => i_episode,
                                         i_prof_questions   => i_prof,
                                         i_prof_questioned  => l_prof_questioned,
                                         i_speciality       => l_speciality,
                                         i_clinical_service => l_clinical_service,
                                         i_desc             => l_desc,
                                         i_prof_cat_type    => l_prof_cat_type,
                                         i_flg_type         => NULL,
                                         i_flg_priority     => l_flg_priority,
                                         i_flg_origin_req   => i_flg_origin_req,
                                         i_flg_update       => i_flg_update,
                                         i_opinion          => i_opinion,
                                         o_opinion          => o_opinion,
                                         o_error            => o_error)
        THEN
            RAISE g_exception;
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
                                              'CREATE_OPINION',
                                              o_error);
            RETURN FALSE;
    END create_opinion;

    FUNCTION create_opinion
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_prof_questions   IN profissional,
        i_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_speciality       IN opinion.id_speciality%TYPE,
        i_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_desc             IN opinion.desc_problem%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_flg_type         IN opinion.flg_type%TYPE,
        i_flg_priority     IN opinion.flg_priority%TYPE DEFAULT 'N',
        i_flg_origin_req   IN VARCHAR2 DEFAULT 'D',
        i_flg_update       IN VARCHAR2 DEFAULT 'N',
        i_opinion          IN opinion.id_opinion%TYPE DEFAULT NULL,
        o_opinion          OUT opinion.id_opinion%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Chama a fun? create_opinion com o valor do par?tro commit_data a YES
           PARAMETROS:  Entrada: I_LANG - Lingua registada como preferencia do profissional
                       I_EPISODE - ID do episodio
                     I_PROF_QUESTIONS - profissional que pede o parecer
                     I_PROF_QUESTIONED - profissional requisitado
                     I_SPEC - especialidade (conjunto de medicos) requisitada
                     I_DESC - pedido de opini?o
                     I_NOTES - notas
                     I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                               como e retornada em PK_LOGIN.GET_PROF_PREF
                  Saida:   O_ERROR - erro
        
          CRIAC?O: CRS 2005/03/10
          NOTAS: Ou I_PROF_QUESTIONED ou I_SPEC tem q estar preenchido
        *********************************************************************************/
    
    BEGIN
    
        RETURN create_opinion(i_lang             => i_lang,
                              i_episode          => i_episode,
                              i_prof_questions   => i_prof_questions,
                              i_prof_questioned  => i_prof_questioned,
                              i_speciality       => i_speciality,
                              i_clinical_service => i_clinical_service,
                              i_desc             => i_desc,
                              i_prof_cat_type    => i_prof_cat_type,
                              i_commit_data      => pk_alert_constant.g_yes,
                              i_flg_type         => i_flg_type,
                              i_diag             => table_number(),
                              i_patient          => NULL,
                              i_flg_priority     => i_flg_priority,
                              i_flg_origin_req   => i_flg_origin_req,
                              i_flg_update       => i_flg_update,
                              i_opinion          => i_opinion,
                              o_opinion          => o_opinion,
                              o_error            => o_error);
    
    END;

    FUNCTION get_id_epis_pn
    (
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_type IN opinion.id_opinion_type%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_area     IN VARCHAR2
    ) RETURN NUMBER IS
        l_id_tl_task tl_task.id_tl_task%TYPE;
        l_id_epis_pn table_number;
        l_id_pn_area table_number;
    BEGIN
        l_id_tl_task := pk_ea_logic_opinion.get_id_tt_from_id_op_type(i_opinion_type);
        SELECT e.id_epis_pn, e.id_pn_area
          BULK COLLECT
          INTO l_id_epis_pn, l_id_pn_area
          FROM epis_pn e
          JOIN epis_pn_det ed
            ON e.id_epis_pn = ed.id_epis_pn
          JOIN epis_pn_det_task edt
            ON ed.id_epis_pn_det = edt.id_epis_pn_det
         WHERE id_episode = i_episode
           AND e.id_pn_note_type = 175
           AND edt.id_task = i_opinion
           AND edt.id_task_type = l_id_tl_task;
    
        IF l_id_epis_pn.exists(1)
        THEN
            IF i_flg_area IS NULL
            THEN
                RETURN l_id_epis_pn(1);
            ELSE
                RETURN l_id_pn_area(1);
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END get_id_epis_pn;

    FUNCTION create_consult_note
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_opinion   IN opinion.id_opinion%TYPE,
        i_sysdate_tstz IN opinion.dt_problem_tstz%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_description       pn_dblock_ttp_mkt.flg_description%TYPE;
        l_description_condition pn_dblock_ttp_mkt.description_condition%TYPE;
        l_id_epis_pn            epis_pn.id_epis_pn%TYPE;
        l_pn_note               CLOB;
    BEGIN
        IF NOT pk_prog_notes_utils.get_data_block_desc_condition(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_note_type          => 173,
                                                                 i_id_sblock             => 3087,
                                                                 i_id_dblock             => 1115,
                                                                 i_id_task               => 89,
                                                                 o_flg_description       => l_flg_description,
                                                                 o_description_condition => l_description_condition,
                                                                 o_error                 => o_error)
        THEN
            l_flg_description       := NULL;
            l_description_condition := NULL;
        END IF;
    
        l_pn_note := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_id_episode            => i_id_episode,
                                                            i_id_task_type          => 89,
                                                            i_id_task               => i_id_opinion,
                                                            i_universal_description => NULL,
                                                            i_short_desc            => NULL,
                                                            i_code_description      => NULL,
                                                            i_flg_description       => l_flg_description,
                                                            i_description_condition => l_description_condition);
    
        IF NOT pk_prog_notes_core.set_save_def_note(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_epis_pn             => NULL,
                                                    i_id_dictation_report => NULL,
                                                    i_id_episode          => i_id_episode,
                                                    i_pn_flg_status       => pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                    i_id_pn_note_type     => 173, --pk_prog_notes_constants.g_note_type_id_handp_2,
                                                    i_dt_pn_date          => i_sysdate_tstz,
                                                    i_id_dep_clin_serv    => NULL,
                                                    i_id_pn_data_block    => table_number(1115),
                                                    i_id_pn_soap_block    => table_number(3087),
                                                    i_id_task             => table_number(i_id_opinion),
                                                    i_id_task_type        => table_number(89),
                                                    i_pn_note             => table_clob(l_pn_note),
                                                    i_id_professional     => i_prof.id,
                                                    i_dt_create           => i_sysdate_tstz,
                                                    i_dt_last_update      => i_sysdate_tstz,
                                                    i_dt_sent_to_hist     => i_sysdate_tstz,
                                                    i_id_prof_sign_off    => NULL,
                                                    i_dt_sign_off         => NULL,
                                                    o_id_epis_pn          => l_id_epis_pn,
                                                    o_error               => o_error)
        THEN
            RETURN FALSE;
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
                                              'CREATE_CONSULT_NOTE',
                                              o_error);
            RETURN FALSE;
    END create_consult_note;

    FUNCTION create_consult_answer_note
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_opinion   IN opinion.id_opinion%TYPE,
        i_sysdate_tstz IN opinion.dt_problem_tstz%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_description       pn_dblock_ttp_mkt.flg_description%TYPE;
        l_description_condition pn_dblock_ttp_mkt.description_condition%TYPE;
        l_id_epis_pn            epis_pn.id_epis_pn%TYPE;
        l_pn_note_request       CLOB;
        l_pn_note_answer        CLOB;
    BEGIN
        IF NOT pk_prog_notes_utils.get_data_block_desc_condition(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_note_type          => 174,
                                                                 i_id_sblock             => 3087,
                                                                 i_id_dblock             => 1115,
                                                                 i_id_task               => 89,
                                                                 o_flg_description       => l_flg_description,
                                                                 o_description_condition => l_description_condition,
                                                                 o_error                 => o_error)
        THEN
            l_flg_description       := NULL;
            l_description_condition := NULL;
        END IF;
    
        l_pn_note_request := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                                    i_prof                  => i_prof,
                                                                    i_id_episode            => i_id_episode,
                                                                    i_id_task_type          => 89,
                                                                    i_id_task               => i_id_opinion,
                                                                    i_universal_description => NULL,
                                                                    i_short_desc            => NULL,
                                                                    i_code_description      => NULL,
                                                                    i_flg_description       => l_flg_description,
                                                                    i_description_condition => l_description_condition);
    
        IF NOT pk_prog_notes_utils.get_data_block_desc_condition(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_note_type          => 174,
                                                                 i_id_sblock             => 3086,
                                                                 i_id_dblock             => 1114,
                                                                 i_id_task               => 89,
                                                                 o_flg_description       => l_flg_description,
                                                                 o_description_condition => l_description_condition,
                                                                 o_error                 => o_error)
        THEN
            l_flg_description       := NULL;
            l_description_condition := NULL;
        END IF;
    
        l_pn_note_answer := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                                   i_prof                  => i_prof,
                                                                   i_id_episode            => i_id_episode,
                                                                   i_id_task_type          => 89,
                                                                   i_id_task               => i_id_opinion,
                                                                   i_universal_description => NULL,
                                                                   i_short_desc            => NULL,
                                                                   i_code_description      => NULL,
                                                                   i_flg_description       => l_flg_description,
                                                                   i_description_condition => l_description_condition);
    
        IF NOT
            pk_prog_notes_core.set_save_def_note(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_epis_pn             => NULL,
                                                 i_id_dictation_report => NULL,
                                                 i_id_episode          => i_id_episode,
                                                 i_pn_flg_status       => pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                 i_id_pn_note_type     => 174, --pk_prog_notes_constants.g_note_type_id_handp_2,
                                                 i_dt_pn_date          => i_sysdate_tstz,
                                                 i_id_dep_clin_serv    => NULL,
                                                 i_id_pn_data_block    => table_number(1114, 1115),
                                                 i_id_pn_soap_block    => table_number(3086, 3087),
                                                 i_id_task             => table_number(i_id_opinion, i_id_opinion),
                                                 i_id_task_type        => table_number(89, 89),
                                                 i_pn_note             => table_clob(l_pn_note_answer, l_pn_note_request),
                                                 i_id_professional     => i_prof.id,
                                                 i_dt_create           => i_sysdate_tstz,
                                                 i_dt_last_update      => i_sysdate_tstz,
                                                 i_dt_sent_to_hist     => i_sysdate_tstz,
                                                 i_id_prof_sign_off    => NULL,
                                                 i_dt_sign_off         => NULL,
                                                 o_id_epis_pn          => l_id_epis_pn,
                                                 o_error               => o_error)
        THEN
            RETURN FALSE;
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
                                              'CREATE_CONSULT_ANSWER_NOTE',
                                              o_error);
            RETURN FALSE;
    END create_consult_answer_note;

    FUNCTION set_follow_up_note
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_opinion      IN opinion.id_opinion%TYPE,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        i_sysdate_tstz    IN opinion.dt_problem_tstz%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_description       pn_dblock_ttp_mkt.flg_description%TYPE;
        l_description_condition pn_dblock_ttp_mkt.description_condition%TYPE;
        l_id_epis_pn            epis_pn.id_epis_pn%TYPE;
        l_pn_note               CLOB;
        l_id_tl_task            tl_task.id_tl_task%TYPE;
    BEGIN
        l_id_tl_task := pk_ea_logic_opinion.get_id_tt_from_id_op_type(i_id_opinion_type);
        IF NOT pk_prog_notes_utils.get_data_block_desc_condition(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_note_type          => 175,
                                                                 i_id_sblock             => 3088,
                                                                 i_id_dblock             => 1116,
                                                                 i_id_task               => l_id_tl_task,
                                                                 o_flg_description       => l_flg_description,
                                                                 o_description_condition => l_description_condition,
                                                                 o_error                 => o_error)
        THEN
            l_flg_description       := NULL;
            l_description_condition := NULL;
        END IF;
    
        l_pn_note := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_id_episode            => i_id_episode,
                                                            i_id_task_type          => l_id_tl_task,
                                                            i_id_task               => i_id_opinion,
                                                            i_universal_description => NULL,
                                                            i_short_desc            => NULL,
                                                            i_code_description      => NULL,
                                                            i_flg_description       => l_flg_description,
                                                            i_description_condition => l_description_condition);
    
        IF NOT pk_prog_notes_core.set_save_def_note(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_epis_pn             => NULL,
                                                    i_id_dictation_report => NULL,
                                                    i_id_episode          => i_id_episode,
                                                    i_pn_flg_status       => pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                    i_id_pn_note_type     => 175, --pk_prog_notes_constants.g_note_type_id_handp_2,
                                                    i_dt_pn_date          => i_sysdate_tstz,
                                                    i_id_dep_clin_serv    => NULL,
                                                    i_id_pn_data_block    => table_number(1116),
                                                    i_id_pn_soap_block    => table_number(3088),
                                                    i_id_task             => table_number(i_id_opinion),
                                                    i_id_task_type        => table_number(l_id_tl_task),
                                                    i_pn_note             => table_clob(l_pn_note),
                                                    i_id_professional     => i_prof.id,
                                                    i_dt_create           => i_sysdate_tstz,
                                                    i_dt_last_update      => i_sysdate_tstz,
                                                    i_dt_sent_to_hist     => i_sysdate_tstz,
                                                    i_id_prof_sign_off    => NULL,
                                                    i_dt_sign_off         => NULL,
                                                    i_flg_handle_error    => pk_alert_constant.g_yes,
                                                    o_id_epis_pn          => l_id_epis_pn,
                                                    o_error               => o_error)
        THEN
            RETURN FALSE;
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
                                              'SET_FOLLOW_UP_NOTE',
                                              o_error);
            RETURN FALSE;
    END set_follow_up_note;

    FUNCTION cancel_consult_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_opinion    IN opinion.id_opinion%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN epis_pn.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_pn table_number;
    BEGIN
        SELECT e.id_epis_pn
          BULK COLLECT
          INTO l_id_epis_pn
          FROM epis_pn e
          JOIN epis_pn_det ed
            ON e.id_epis_pn = ed.id_epis_pn
          JOIN epis_pn_det_task edt
            ON ed.id_epis_pn_det = edt.id_epis_pn_det
        
         WHERE id_episode = i_id_episode
           AND e.id_pn_note_type = 173
           AND edt.id_task = i_id_opinion
           AND edt.id_task_type = 89;
    
        IF NOT pk_prog_notes_core.cancel_progress_note(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_epis_pn       => l_id_epis_pn(1),
                                                       i_cancel_reason => i_cancel_reason,
                                                       i_notes_cancel  => i_notes_cancel,
                                                       o_error         => o_error)
        THEN
            RETURN FALSE;
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
                                              'CREATE_CONSULT_NOTE',
                                              o_error);
            RETURN FALSE;
    END cancel_consult_note;

    FUNCTION create_follow_up_answer_note
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_opinion      IN opinion.id_opinion%TYPE,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        i_sysdate_tstz    IN opinion.dt_problem_tstz%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_description       pn_dblock_ttp_mkt.flg_description%TYPE;
        l_description_condition pn_dblock_ttp_mkt.description_condition%TYPE;
        l_id_epis_pn            epis_pn.id_epis_pn%TYPE;
        l_id_pn_area            pn_area.id_pn_area%TYPE;
        l_pn_note_request       CLOB;
        l_pn_note_answer        CLOB;
        l_id_tl_task            tl_task.id_tl_task%TYPE;
    BEGIN
        l_id_tl_task := pk_ea_logic_opinion.get_id_tt_from_id_op_type(i_id_opinion_type);
        l_id_pn_area := get_id_epis_pn(i_id_opinion, i_id_opinion_type, i_id_episode, 'Y');
    
        IF NOT pk_prog_notes_utils.get_data_block_desc_condition(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_note_type          => 176,
                                                                 i_id_sblock             => 3088,
                                                                 i_id_dblock             => 1116,
                                                                 i_id_task               => l_id_tl_task,
                                                                 o_flg_description       => l_flg_description,
                                                                 o_description_condition => l_description_condition,
                                                                 o_error                 => o_error)
        THEN
            l_flg_description       := NULL;
            l_description_condition := NULL;
        END IF;
    
        l_pn_note_request := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                                    i_prof                  => i_prof,
                                                                    i_id_episode            => i_id_episode,
                                                                    i_id_task_type          => l_id_tl_task,
                                                                    i_id_task               => i_id_opinion,
                                                                    i_universal_description => NULL,
                                                                    i_short_desc            => NULL,
                                                                    i_code_description      => NULL,
                                                                    i_flg_description       => l_flg_description,
                                                                    i_description_condition => l_description_condition);
    
        IF NOT pk_prog_notes_utils.get_data_block_desc_condition(i_lang                  => i_lang,
                                                                 i_prof                  => i_prof,
                                                                 i_id_note_type          => 176,
                                                                 i_id_sblock             => 3089,
                                                                 i_id_dblock             => 1117,
                                                                 i_id_task               => l_id_tl_task,
                                                                 o_flg_description       => l_flg_description,
                                                                 o_description_condition => l_description_condition,
                                                                 o_error                 => o_error)
        THEN
            l_flg_description       := NULL;
            l_description_condition := NULL;
        END IF;
    
        l_pn_note_answer := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                                   i_prof                  => i_prof,
                                                                   i_id_episode            => i_id_episode,
                                                                   i_id_task_type          => l_id_tl_task,
                                                                   i_id_task               => i_id_opinion,
                                                                   i_universal_description => NULL,
                                                                   i_short_desc            => NULL,
                                                                   i_code_description      => NULL,
                                                                   i_flg_description       => l_flg_description,
                                                                   i_description_condition => l_description_condition);
    
        IF NOT
            pk_prog_notes_core.set_save_def_note(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_epis_pn             => NULL,
                                                 i_id_dictation_report => NULL,
                                                 i_id_episode          => i_id_episode,
                                                 i_pn_flg_status       => pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                 i_id_pn_note_type     => 176, --pk_prog_notes_constants.g_note_type_id_handp_2,
                                                 i_dt_pn_date          => i_sysdate_tstz,
                                                 i_id_dep_clin_serv    => NULL,
                                                 i_id_pn_data_block    => table_number(1117, 1116),
                                                 i_id_pn_soap_block    => table_number(3089, 3088),
                                                 i_id_task             => table_number(i_id_opinion, i_id_opinion),
                                                 i_id_task_type        => table_number(l_id_tl_task, l_id_tl_task),
                                                 i_pn_note             => table_clob(l_pn_note_answer, l_pn_note_request),
                                                 i_id_professional     => i_prof.id,
                                                 i_dt_create           => i_sysdate_tstz,
                                                 i_dt_last_update      => i_sysdate_tstz,
                                                 i_dt_sent_to_hist     => i_sysdate_tstz,
                                                 i_id_prof_sign_off    => NULL,
                                                 i_dt_sign_off         => NULL,
                                                 i_id_pn_area          => l_id_pn_area,
                                                 o_id_epis_pn          => l_id_epis_pn,
                                                 o_error               => o_error)
        THEN
            RETURN FALSE;
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
                                              'CREATE_FOLLOW_UP_ANSWER_NOTE',
                                              o_error);
            RETURN FALSE;
    END create_follow_up_answer_note;

    /******************************************************************************
       OBJECTIVO:   Criar registo de pedido de parecer
       PARAMETROS:  Entrada: I_LANG - Lingua registada como preferencia do profissional
             I_EPISODE - ID do episodio
           I_PROF_QUESTIONS - profissional que pede o parecer
           I_PROF_QUESTIONED - profissional requisitado
           I_SPEC - especialidade (conjunto de medicos) requisitada
           I_DESC - pedido de opini?o
           I_NOTES - notas
           I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                 como e retornada em PK_LOGIN.GET_PROF_PREF
           I_COMMIT_DATA - Flag que indica se a fun? deve fazer o commit dos dados
          Saida:   O_ERROR - erro
    
      CRIAC?O: CRS 2005/03/10
      NOTAS: Ou I_PROF_QUESTIONED ou I_SPEC tem q estar preenchido
    *********************************************************************************/
    FUNCTION create_opinion
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_prof_questions   IN profissional,
        i_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_speciality       IN opinion.id_speciality%TYPE,
        i_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_desc             IN opinion.desc_problem%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_commit_data      IN VARCHAR2,
        i_diag             IN table_number,
        i_patient          IN opinion.id_patient%TYPE,
        i_flg_type         IN opinion.flg_type%TYPE DEFAULT 'O',
        i_dt_creation      IN opinion.dt_problem_tstz%TYPE DEFAULT current_timestamp,
        i_flg_priority     IN opinion.flg_priority%TYPE DEFAULT 'N',
        i_flg_origin_req   IN VARCHAR2 DEFAULT 'D',
        i_flg_update       IN VARCHAR2 DEFAULT 'N',
        i_opinion          IN opinion.id_opinion%TYPE DEFAULT NULL,
        o_opinion          OUT opinion.id_opinion%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message         debug_msg;
        l_seq             opinion.id_opinion%TYPE;
        l_error           VARCHAR2(4000);
        l_prof_questioned opinion.id_prof_questioned%TYPE;
        l_commit_data     BOOLEAN;
        l_rows_out        table_varchar := table_varchar();
        l_patient         opinion.id_patient%TYPE;
        e_epis_exception EXCEPTION;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := i_dt_creation;
        l_flg_state opinion.flg_state%TYPE;
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
        l_num      NUMBER;
        CURSOR c_patient IS
            SELECT e.id_patient
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        CURSOR c_count_episode(i_id_patient IN NUMBER) IS
            SELECT COUNT(1)
              FROM episode e
             WHERE e.id_patient = i_id_patient
               AND e.id_epis_type = pk_alert_constant.g_epis_type_case_manager
               AND e.flg_status NOT IN
                   (pk_alert_constant.g_epis_status_cancel, pk_alert_constant.g_epis_status_inactive);
    
        l_config_create_note sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'CONSULTS_CREATE_REQUEST_NOTE',
                                                                              i_prof    => i_prof_questions);
    
        -- inline function
        FUNCTION set_error
        (
            i_code IN VARCHAR2,
            i_desc IN VARCHAR2
        ) RETURN BOOLEAN IS
        BEGIN
        
            l_error_in.set_all(i_lang,
                               i_code,
                               i_desc,
                               NULL,
                               g_package_owner,
                               g_package_name,
                               'CREATE_OPINION',
                               l_message,
                               'U');
        
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
        
        END set_error;
        -- ###################
    
    BEGIN
    
        l_commit_data := NOT (i_commit_data = 'N');
    
        l_message := 'VALIDATE';
        IF i_prof_questioned IS NULL
           AND i_speciality IS NULL
           AND i_clinical_service IS NULL
           AND i_flg_type NOT IN (g_flg_type_nutritionist, g_flg_type_case_manager)
        THEN
            l_error := REPLACE(REPLACE(pk_message.get_message(i_lang, 'COMMON_M004'), '@1', 'profissional'),
                               '@2',
                               'especialidade');
        
            l_ret := set_error(i_code => 'COMMON_M004', i_desc => l_error);
            RETURN FALSE;
        
        END IF;
    
        IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
        THEN
            IF i_patient IS NULL
            THEN
                l_message := 'OPEN c_patient';
                OPEN c_patient;
                FETCH c_patient
                    INTO l_patient;
                CLOSE c_patient;
            ELSE
                l_patient := i_patient;
            END IF;
        END IF;
    
        l_message := 'GET PROF QUESTIONED';
        IF i_prof_questioned > 0
        THEN
            l_prof_questioned := i_prof_questioned;
        END IF;
    
        -- 
        IF i_flg_type = g_flg_type_case_manager
        THEN
            OPEN c_count_episode(l_patient);
            FETCH c_count_episode
                INTO l_num;
            IF l_num > 0
            THEN
                RAISE e_epis_exception;
            END IF;
        END IF;
        l_message := 'GET NEXT OPINION ID';
        -- SELECT seq_opinion.NEXTVAL
        -- INTO l_seq
        -- FROM dual;
    
        -- TS 24/09/2008 2.4.3.d
        l_seq := ts_opinion.next_key();
    
        IF i_flg_origin_req = pk_alert_constant.g_task_origin_order_set
        THEN
            l_flg_state := pk_opinion.g_status_predefined;
        ELSE
            l_flg_state := pk_opinion.g_opinion_req;
        END IF;
    
        IF i_flg_update = pk_alert_constant.g_no
        THEN
            l_message := 'INSERT INTO OPINION ';
            ts_opinion.ins(id_opinion_in          => l_seq,
                           id_episode_in          => i_episode,
                           flg_state_in           => l_flg_state,
                           dt_problem_tstz_in     => l_sysdate_tstz,
                           desc_problem_in        => i_desc,
                           id_prof_questions_in   => i_prof_questions.id,
                           id_prof_questioned_in  => l_prof_questioned,
                           id_speciality_in       => i_speciality,
                           id_clinical_service_in => i_clinical_service,
                           flg_type_in            => i_flg_type,
                           id_patient_in          => l_patient,
                           flg_priority_in        => i_flg_priority,
                           handle_error_in        => FALSE,
                           rows_out               => l_rows_out);
        ELSIF i_flg_update = pk_alert_constant.g_yes
              AND i_flg_origin_req = pk_alert_constant.g_task_origin_order_set
        THEN
            l_message := 'UPDATE OPINION ';
            ts_opinion.upd(id_opinion_in           => i_opinion,
                           id_episode_in           => i_episode,
                           flg_state_in            => l_flg_state,
                           desc_problem_in         => i_desc,
                           desc_problem_nin        => FALSE,
                           id_prof_questions_in    => i_prof_questions.id,
                           id_prof_questions_nin   => FALSE,
                           id_prof_questioned_in   => l_prof_questioned,
                           id_speciality_in        => i_speciality,
                           flg_type_in             => i_flg_type,
                           id_patient_in           => l_patient,
                           id_patient_nin          => FALSE,
                           id_clinical_service_in  => i_clinical_service,
                           id_clinical_service_nin => FALSE,
                           flg_priority_in         => i_flg_priority,
                           handle_error_in         => FALSE,
                           rows_out                => l_rows_out);
        END IF;
    
        IF i_flg_origin_req != pk_alert_constant.g_task_origin_order_set
        THEN
            l_message := 't_data_gov_mnt.process_insert OPINION';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof_questions,
                                          i_table_name => 'OPINION',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            pk_ia_event_common.opinion_order_new(i_id_opinion => l_seq, i_id_episode => i_episode);
        
            FOR i IN 1 .. i_diag.count
            LOOP
                l_rows_out := table_varchar();
            
                l_message := 'INSERT INTO opinion_reason';
                ts_opinion_reason.ins(id_opinion_in => l_seq, id_diagnosis_in => i_diag(i), rows_out => l_rows_out);
            
                l_message := 'CALL t_data_gov_mnt.process_insert OPINION_REASON';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof_questions,
                                              i_table_name => 'OPINION_REASON',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            END LOOP;
        
            -- CJV BEGIN : Alteração de alertas
            IF NOT
                alert_opinion_request(i_lang => i_lang, i_opinion => l_seq, i_flg_type => i_flg_type, o_error => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
            -- CJV END : Altera? de alertas            
        
            l_message := 'CALL TO SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof_questions,
                                          i_prof_cat_type       => i_prof_cat_type,
                                          i_dt_last_interaction => l_sysdate_tstz,
                                          i_dt_first_obs        => l_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
        
            IF l_config_create_note = pk_alert_constant.g_yes
            THEN
                IF NOT create_consult_note(i_lang         => i_lang,
                                           i_prof         => i_prof_questions,
                                           i_id_episode   => i_episode,
                                           i_id_opinion   => l_seq,
                                           i_sysdate_tstz => l_sysdate_tstz,
                                           o_error        => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        o_opinion := l_seq;
    
        IF l_commit_data
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN e_epis_exception THEN
            l_error := pk_message.get_message(i_lang, i_prof_questions, 'CASE_MANAGER_M008');
        
            l_error_in.set_all(i_lang,
                               'CASE_MANAGER_M008',
                               l_error,
                               NULL,
                               g_package_owner,
                               g_package_name,
                               'CREATE_OPINION',
                               l_error,
                               'U');
        
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_OPINION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION create_opinion_from_order_set
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN opinion.id_episode%TYPE,
        i_id_opinion IN opinion.id_opinion%TYPE,
        o_opinion    OUT opinion.id_opinion%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_opinion_row opinion%ROWTYPE;
        l_prof_cat    category.flg_type%TYPE;
    
    BEGIN
    
        --Fetch the data from the temporary records created by the order set (flg_status=PD)
        g_error := 'ERROR FETCHING OPINION INFO';
        SELECT o.*
          INTO l_opinion_row
          FROM opinion o
         WHERE o.id_opinion = i_id_opinion;
    
        --Delete the temporary records created by the order set
        g_error := 'ERROR CALLING PK_OPINION.SET_OPINION_DELETE_TASK';
        IF NOT pk_opinion.set_opinion_delete_task(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_task_request => table_number(i_id_opinion),
                                                  o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error    := 'ERROR GETTING PROF CAT';
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        --Execute the request whith the fetched data
        g_error := 'ERROR CALLING PK_OPINION.CREATE_OPINION';
        IF NOT pk_opinion.create_opinion(i_lang             => i_lang,
                                         i_episode          => i_id_episode,
                                         i_prof_questions   => i_prof,
                                         i_prof_questioned  => l_opinion_row.id_prof_questioned,
                                         i_speciality       => l_opinion_row.id_speciality,
                                         i_clinical_service => l_opinion_row.id_clinical_service,
                                         i_desc             => l_opinion_row.desc_problem,
                                         i_prof_cat_type    => l_prof_cat,
                                         i_flg_type         => l_opinion_row.flg_type,
                                         i_flg_priority     => coalesce(l_opinion_row.flg_priority,
                                                                        pk_alert_constant.g_task_priority_normal),
                                         i_flg_update       => pk_alert_constant.g_no,
                                         i_opinion          => NULL,
                                         o_opinion          => o_opinion,
                                         o_error            => o_error)
        THEN
            RAISE g_exception;
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
                                              'CREATE_OPINION_FROM_ORDER_SET',
                                              o_error);
        
            RETURN FALSE;
    END create_opinion_from_order_set;

    FUNCTION set_opinion_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN opinion.id_opinion%TYPE,
        o_opinion      OUT opinion.id_opinion%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_seq      opinion.id_opinion%TYPE;
        l_rows_out table_varchar := table_varchar();
    
        l_row opinion%ROWTYPE;
    BEGIN
    
        g_error := 'ERROR FETCHING OPINION';
        SELECT *
          INTO l_row
          FROM opinion o
         WHERE o.id_opinion = i_task_request;
    
        l_seq := ts_opinion.next_key();
    
        g_error := 'ERROR CALLING TS_OPINION.INS';
        ts_opinion.ins(id_opinion_in          => l_seq,
                       id_episode_in          => i_episode,
                       flg_state_in           => l_row.flg_state,
                       dt_problem_tstz_in     => current_timestamp,
                       desc_problem_in        => l_row.desc_problem,
                       id_prof_questions_in   => l_row.id_prof_questions,
                       id_prof_questioned_in  => l_row.id_prof_questioned,
                       id_speciality_in       => l_row.id_speciality,
                       id_clinical_service_in => l_row.id_clinical_service,
                       flg_type_in            => l_row.flg_type,
                       id_patient_in          => l_row.id_patient,
                       flg_priority_in        => l_row.flg_priority,
                       handle_error_in        => FALSE,
                       rows_out               => l_rows_out);
    
        o_opinion := l_seq;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_OPINION_COPY_TASK',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_opinion_copy_task;

    FUNCTION create_opin_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        i_prof             IN profissional,
        i_desc             IN opinion.desc_problem%TYPE,
        i_flg_face_to_face IN opinion_prof.flg_face_to_face%TYPE DEFAULT g_unknown,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_opinion_prof opinion_prof.id_opinion_prof%TYPE;
    BEGIN
        RETURN create_opin_prof_int(i_lang             => i_lang,
                                    i_opinion          => i_opinion,
                                    i_prof             => i_prof,
                                    i_desc             => i_desc,
                                    i_flg_face_to_face => i_flg_face_to_face,
                                    i_commit_data      => pk_alert_constant.g_yes,
                                    o_opinion_prof     => l_opinion_prof,
                                    o_error            => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              NULL,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_OPIN_PROF',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_opin_prof;

    /******************************************************************************
       OBJECTIVO:   Criar registo de leitura / resposta ao pedido de parecer
       PARAMETROS:  Entrada: I_LANG - Lingua registada como preferencia do profissional
             I_OPINION - ID do registo
           I_PROFESSIONAL - profissional q le / responde
           I_DESC - resposta ao parecer, se for o caso
          Saida:   O_ERROR - erro
    
      CRIAC?O: CRS 2005/03/10
      CHANGED BY: FM 2009/04/13 INSERT FLG_FACE_TO_FACE
      NOTAS:
    *********************************************************************************/
    FUNCTION create_opin_prof_int
    (
        i_lang             IN language.id_language%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        i_prof             IN profissional,
        i_desc             IN opinion.desc_problem%TYPE,
        i_flg_face_to_face IN opinion_prof.flg_face_to_face%TYPE,
        i_commit_data      IN VARCHAR2,
        i_dt_reply         IN opinion_prof.dt_opinion_prof_tstz%TYPE DEFAULT current_timestamp,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message  debug_msg;
        l_seq      opinion_prof.id_opinion_prof%TYPE;
        l_error    VARCHAR2(4000);
        l_flg      opinion.flg_state%TYPE;
        l_id       opinion_prof.id_opinion_prof%TYPE;
        l_flg_type opinion_prof.flg_type%TYPE;
        l_type     category.flg_type%TYPE;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := i_dt_reply;
    
        CURSOR c_opin IS
            SELECT flg_state, id_prof_questions, id_episode, flg_type
              FROM opinion
             WHERE id_opinion = i_opinion;
        r_opin c_opin%ROWTYPE;
    
        CURSOR c_exist IS
            SELECT id_opinion_prof
              FROM opinion_prof
             WHERE id_opinion = i_opinion
               AND id_professional = i_prof.id;
    
        l_rows table_varchar := table_varchar();
    
        l_error_in           t_error_in := t_error_in();
        l_ret                BOOLEAN;
        l_commit             BOOLEAN := FALSE;
        l_error_msg          sys_message.desc_message%TYPE;
        l_error_action       sys_message.desc_message%TYPE;
        l_found              BOOLEAN;
        l_config_create_note sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'CONSULTS_CREATE_ANSWER_NOTE',
                                                                              i_prof    => i_prof);
        -- inline function
        FUNCTION set_error
        (
            i_code IN VARCHAR2,
            i_desc IN VARCHAR2
        ) RETURN BOOLEAN IS
        BEGIN
        
            l_error_in.set_all(i_lang,
                               i_code,
                               i_desc,
                               NULL,
                               g_package_owner,
                               g_package_name,
                               'CREATE_OPIN_PROF_INT',
                               l_message,
                               'U');
        
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
        
        END set_error;
        -- ###################
    
    BEGIN
    
        l_commit := (i_commit_data = pk_alert_constant.g_yes);
    
        l_message := 'GET CURSOR C_EPIS';
        OPEN c_opin;
        FETCH c_opin
            INTO r_opin;
        CLOSE c_opin;
    
        l_type := pk_tools.get_prof_cat(i_prof);
    
        l_message := 'VALIDATE';
        IF r_opin.id_prof_questions = i_prof.id
           AND -- O prof q le e o mesmo q requisitou
           i_desc IS NOT NULL
        THEN
            -- O prof esta a responder
            l_error := pk_message.get_message(i_lang, 'OPINION_M004');
        
            l_ret := set_error(i_code => 'OPINION_M004', i_desc => l_error);
            RETURN l_ret;
        
        ELSIF r_opin.id_prof_questions = i_prof.id
              AND -- O prof q le e o mesmo q requisitou
              r_opin.flg_state = g_opinion_reply
        THEN
            -- O pedido ja foi respondido
            l_flg := g_opinion_reply_read;
        
            l_seq := seq_opinion_prof.nextval;
        
            l_message := 'INSERT INTO OPINION_PROF';
            INSERT INTO opinion_prof
                (id_opinion_prof,
                 dt_opinion_prof_tstz,
                 id_opinion,
                 flg_type,
                 id_professional,
                 desc_reply,
                 flg_face_to_face)
            VALUES
                (l_seq,
                 l_sysdate_tstz,
                 i_opinion,
                 g_opin_prof_reply_read,
                 i_prof.id,
                 i_desc,
                 nvl(i_flg_face_to_face, g_unknown));
        
        ELSIF r_opin.id_prof_questions = i_prof.id
              AND -- O prof q le e o mesmo q requisitou
              i_desc IS NULL
        THEN
            -- O prof n?o esta a responder
            NULL;
        
        ELSIF r_opin.flg_state = g_opinion_cancel
        THEN
            -- O pedido ja foi cancelado
            --    O_ERROR := REPLACE(Pk_Message.GET_MESSAGE(I_LANG, 'COMMON_M005'), '@1', 'pedido de parecer');
            --    RETURN FALSE;
            RETURN TRUE;
        
        ELSIF r_opin.flg_state IN (g_opinion_rejected, g_opinion_over, g_opinion_accepted)
        THEN
            -- case management request is answered or finished
            l_error_msg    := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_M010');
            l_error_action := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_M005');
        
            l_error_in.set_all(i_id_lang       => i_lang,
                               i_sqlcode       => 'CASE_MANAGER_M010',
                               i_sqlerrm       => l_error_msg,
                               i_user_err      => l_message,
                               i_owner         => g_package_owner,
                               i_pck_name      => g_package_name,
                               i_function_name => 'CREATE_OPIN_PROF_INT',
                               i_action        => l_error_action,
                               i_flg_action    => 'D');
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
        
        ELSIF r_opin.id_prof_questions != i_prof.id
              AND -- O prof q le ? e o mesmo q requisitou
              (l_type = g_prof_doctor OR l_type = g_prof_nutri OR l_type = g_prof_cm)
        THEN
            -- O prof q le e medico
            l_message := 'OPEN CURSOR C_EXIST';
            OPEN c_exist;
            FETCH c_exist
                INTO l_id;
            l_found := c_exist%NOTFOUND;
            CLOSE c_exist;
        
            IF l_found
               AND (r_opin.flg_type <> g_flg_type_case_manager OR r_opin.flg_type IS NULL)
            THEN
                -- E a 1? vez q este prof le o pedido
                l_flg_type := g_opin_prof_read;
                IF i_desc IS NOT NULL -- EMR-2981
                THEN
                    l_flg := g_opinion_req_read;
                ELSE
                    l_flg := r_opin.flg_state;
                END IF;
            ELSE
                IF i_desc IS NOT NULL
                   OR (r_opin.flg_type = g_flg_type_case_manager)
                THEN
                    -- Ha texto de resposta
                    l_flg_type := g_opin_prof_reply;
                    l_flg      := g_opinion_reply;
                END IF;
            END IF;
        
            IF l_flg_type IS NOT NULL
            THEN
                l_message := 'GET SEQ_OPINION_PROF.NEXTVAL';
            
                l_seq := seq_opinion_prof.nextval;
            
                l_message := 'INSERT INTO OPINION_PROF';
                INSERT INTO opinion_prof
                    (id_opinion_prof,
                     dt_opinion_prof_tstz,
                     id_opinion,
                     flg_type,
                     id_professional,
                     desc_reply,
                     flg_face_to_face)
                VALUES
                    (l_seq,
                     l_sysdate_tstz,
                     i_opinion,
                     l_flg_type,
                     i_prof.id,
                     i_desc,
                     nvl(i_flg_face_to_face, g_unknown));
            
                -- CJV BEGIN : Altera? de alertas
                IF NOT alert_opinion_reply(i_lang            => i_lang,
                                           i_opinion         => i_opinion,
                                           i_flg_type        => l_flg_type,
                                           i_flg_type_opinon => r_opin.flg_type,
                                           o_error           => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    RETURN FALSE;
                END IF;
            
                IF l_config_create_note = pk_alert_constant.g_yes
                   AND i_desc IS NOT NULL
                THEN
                    IF NOT create_consult_answer_note(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_id_episode   => r_opin.id_episode,
                                                      i_id_opinion   => i_opinion,
                                                      i_sysdate_tstz => l_sysdate_tstz,
                                                      o_error        => o_error)
                    THEN
                        pk_alert_exceptions.reset_error_state;
                    
                        RETURN FALSE;
                    END IF;
                END IF;
                -- CJV END : Alteração de alertas
            END IF;
        END IF;
    
        IF l_flg IS NOT NULL
        THEN
        
            l_message := 'UPDATE';
            ts_opinion.upd(flg_state_in => l_flg, id_opinion_in => i_opinion, rows_out => l_rows);
        
            l_message := 't_data_gov_mnt.process_update ts_opinion';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'OPINION',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATE'));
        
            -- CJV BEGIN : Altera? de alertas
            IF NOT alert_opinion_reply(i_lang            => i_lang,
                                       i_opinion         => i_opinion,
                                       i_flg_type        => l_flg_type,
                                       i_flg_type_opinon => r_opin.flg_type,
                                       o_error           => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END IF;
            -- CJV END : Altera? de alertas
        
        END IF;
    
        l_message := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => r_opin.id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => l_type,
                                      i_dt_last_interaction => l_sysdate_tstz,
                                      i_dt_first_obs        => l_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        IF l_commit
        THEN
            COMMIT;
        END IF;
    
        o_opinion_prof := l_seq;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_OPIN_PROF_INT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_opin_prof_int;

    /********************************************************************************************
    * Sets all episode opinions to the 'replied' status
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Jos?ilva
    * @version               2.5.0.7.8
    * @since                 30-09-2010
    ********************************************************************************************/
    FUNCTION set_opinion_auto_reply
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_state_reply   CONSTANT opinion.flg_state%TYPE := g_opinion_reply;
        l_config_auto_reply CONSTANT sys_config.id_sys_config%TYPE := 'STATUS_CLOSE_OPINION';
    
        l_exception EXCEPTION;
    
        l_rows table_varchar := table_varchar();
    
        CURSOR c_opinion IS
            SELECT op.id_opinion, op.flg_type
              FROM opinion op
             WHERE op.id_episode = i_episode
               AND op.flg_state IN (g_opinion_req, g_opinion_req_read);
    
    BEGIN
    
        IF pk_sysconfig.get_config(l_config_auto_reply, i_prof) = pk_alert_constant.g_yes
        THEN
            FOR r_opinion IN c_opinion
            LOOP
                g_error := 'UPDATE OPINION';
                ts_opinion.upd(flg_state_in  => l_flg_state_reply,
                               id_opinion_in => r_opinion.id_opinion,
                               rows_out      => l_rows);
            
                g_error := 't_data_gov_mnt.process_update ts_opinion';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'OPINION',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATE'));
            
                g_error := 'SET ALERT OPINION';
                IF NOT alert_opinion_reply(i_lang            => i_lang,
                                           i_opinion         => r_opinion.id_opinion,
                                           i_flg_type        => g_opin_prof_reply,
                                           i_flg_type_opinon => r_opinion.flg_type,
                                           o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END LOOP;
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
                                              'SET_OPINION_AUTO_REPLY',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_opinion_auto_reply;

    /*******************************************************************************************
    * Ends the request. or undo end
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          Id opinion
    * @param i_flg_type         Flg_Type : C - Completed A - end of request cancellation
    * @param i_commit_data      if must do commit Y - True N - False
    * @param o_opinion          create opinion identifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Elisabete Bugalho
    * @version                   2.5.0.7
    * @since                    26-10-2009
    ********************************************************************************************/
    FUNCTION create_prof_conclusion_int
    (
        i_lang         IN language.id_language%TYPE,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN opinion_prof.flg_type%TYPE,
        i_commit_data  IN VARCHAR2,
        o_opinion_prof OUT opinion_prof.id_opinion_prof%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_seq opinion_prof.id_opinion_prof%TYPE;
        l_flg opinion.flg_state%TYPE;
    
        l_rows table_varchar := table_varchar();
    
        l_commit BOOLEAN := FALSE;
    
    BEGIN
        IF i_commit_data = pk_alert_constant.g_yes
        THEN
            l_commit := TRUE;
        ELSE
            l_commit := FALSE;
        END IF;
    
        IF i_flg_type IS NOT NULL
        THEN
            l_message := 'GET SEQ_OPINION_PROF.NEXTVAL';
            SELECT seq_opinion_prof.nextval
              INTO l_seq
              FROM dual;
        
            l_message := 'INSERT INTO OPINION_PROF';
            INSERT INTO opinion_prof
                (id_opinion_prof,
                 
                 dt_opinion_prof_tstz,
                 id_opinion,
                 flg_type,
                 id_professional,
                 desc_reply,
                 flg_face_to_face)
            VALUES
                (l_seq, l_sysdate_tstz, i_opinion, i_flg_type, i_prof.id, NULL, g_unknown);
        
            IF i_flg_type = g_opin_prof_conclusion
            THEN
                l_flg := g_opinion_over;
            ELSE
                l_flg := g_opinion_accepted;
            END IF;
            l_message := 'UPDATE';
            ts_opinion.upd(flg_state_in => l_flg, id_opinion_in => i_opinion, rows_out => l_rows);
        
            l_message := 't_data_gov_mnt.process_update ts_opinion';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'OPINION',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATE'));
        
        END IF;
    
        IF l_commit
        THEN
            COMMIT;
        END IF;
    
        o_opinion_prof := l_seq;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_PROF_CONCLUSION_INT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_prof_conclusion_int;

    FUNCTION get_opinion_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE,
        o_flg_status OUT opinion.flg_state%TYPE,
        -- o_desc_status  OUT VARCHAR2,
        -- o_flg_text     OUT VARCHAR2,
        -- o_color_status OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_flg_finished  OUT VARCHAR2,
        o_flg_canceled  OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obt?todos os par?tros que devolvem o estado de um parecer.
           PARAMETROS:  Entrada: I_LANG - L?ua registada como prefer?ia do profissional
                                 I_PROF - ID do profissional
                                 I_ID_OPINION - ID do pedido de parecer
                        Saida:   O_FLG_STATUS - Estado do pedido
                                 O_STATUS_STRING - String do estado para ser interpretada pelo Flash
                                 O_FLG_FINISHED - Indica se o pedido de parecer j?st?um estado final
                                 O_FLG_CANCELED - Indica se o pedido de parecer foi cancelado
                                 O_ERROR - Mensagem erro
        
          CRIAC? Tiago Silva 2008/05/28
          NOTAS:
        *********************************************************************************/
        l_message debug_msg;
    
    BEGIN
    
        l_message := 'GET REQUEST STATUS';
    
        SELECT o.flg_state,
               --decode(o.flg_state,
               --       g_opinion_reply,
               --       'CheckIcon',
               --       g_opinion_reply_read,
               --       'CheckIcon',
               --       g_opinion_cancel,
               --       'CancelIcon',
               --       'WorkflowIcon') AS o_desc_status,
               --'I' AS flg_text,
               --NULL AS color_status,
               pk_utils.get_status_string(i_lang, i_prof, o.status_str, o.status_msg, o.status_icon, o.status_flg) status_string,
               decode(o.flg_state,
                      g_opinion_reply,
                      pk_alert_constant.g_yes,
                      g_opinion_reply_read,
                      pk_alert_constant.g_yes,
                      pk_alert_constant.g_no) AS flg_finished,
               decode(o.flg_state, g_opinion_cancel, pk_alert_constant.g_yes, pk_alert_constant.g_no) AS flg_canceled
        --INTO o_flg_status, o_desc_status, o_flg_text, o_color_status, o_flg_finished, o_flg_canceled
          INTO o_flg_status, o_status_string, o_flg_finished, o_flg_canceled
          FROM opinion o
         WHERE o.id_opinion = i_id_opinion;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     l_message,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_OPINION_STATUS',
                                                     o_error);
    END;

    FUNCTION get_epis_opinion
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN opinion.id_episode%TYPE,
        i_prof       IN profissional,
        i_patient    IN opinion.id_patient%TYPE,
        i_flg_type   IN opinion.flg_type%TYPE DEFAULT 'O',
        i_flg_status IN table_varchar DEFAULT NULL,
        o_opinion    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter info dos pedidos de parecer de um epis.
           PARAMETROS:  Entrada: I_LANG - Lingua registada como preferencia do profissional
                       I_EPISODE - ID do episodio
                  Saida:   O_OPINION - array de pedidos de parecer
                       SPEC_PROF - especialidade + prof. requisitado
                       ID_PROFESSIONAL - ID do profissional requisitante
                       PROF_REQ - prof. requisitante
                       STATE - descritivo do estado do pedido
                       DT_PROBLEM - data de registo do pedido
                       DESC_PROBLEM - pedido de parecer
                       PROF_REPLY - prof. q responde
                       DT_REPLY - data de resposta
                       DESC_REPLY - resposta ao parecer
                       PROF_CANCEL - prof. q cancela
                       DT_CANCEL - data de cancelamento
                       NOTES_CANCEL - notas de cancelamento
                       PRIORITY - prioridade
                     O_ERROR - erro
        
          CRIAC?O: CRS 2005/03/10
          NOTAS:
        *********************************************************************************/
        l_message          debug_msg;
        l_tbl_status       table_varchar;
        l_flg_status_count NUMBER := 0;
    BEGIN
    
        IF i_flg_status IS NULL
        THEN
            IF i_flg_status.count = 0
            THEN
                -- l_flg_status_count := 0;
                l_tbl_status := table_varchar();
            ELSE
                l_tbl_status := i_flg_status;
            END IF;
        END IF;
    
        IF nvl(i_flg_type, 'O') = g_flg_type_nutritionist
        THEN
            l_message := 'GET CURSOR';
            OPEN o_opinion FOR
                SELECT o.id_opinion,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned) spec_prof,
                       o.id_prof_questions id_prof_requests,
                       nvl2(o.id_clinical_service,
                            (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                               FROM clinical_service cs
                              WHERE cs.id_clinical_service = o.id_clinical_service),
                            nvl2(o.id_speciality,
                                 pk_prof_utils.get_spec_signature(i_lang,
                                                                  i_prof,
                                                                  o.id_prof_questions,
                                                                  o.dt_problem_tstz,
                                                                  o.id_episode),
                                 NULL)) spec_clin_serv,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) prof_req,
                       pk_sysdomain.get_domain(g_opinion_consults, o.flg_state, i_lang) state,
                       pk_date_utils.dt_chr_tsz(i_lang, o.dt_problem_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang, o.dt_problem_tstz, i_prof.institution, i_prof.software) hour_target,
                       o.desc_problem,
                       o.flg_state,
                       pk_utils.get_status_string(i_lang,
                                                  i_prof,
                                                  o.status_str,
                                                  o.status_icon,
                                                  o.status_msg,
                                                  o.status_flg) status_string,
                       pk_date_utils.date_char_tsz(i_lang, dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                       decode(o.flg_state, g_opinion_cancel, 'Y', 'N') flg_cancel,
                       to_char(o.dt_problem_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                       decode(nvl(o.notes_cancel, '#'), '#', NULL, pk_message.get_message(i_lang, 'COMMON_M008')) title_notes,
                       pk_sysdomain.get_rank(i_lang, g_opinion_consults, o.flg_state) rank,
                       o.dt_problem_tstz dt_problem,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional) prof_resp,
                       o.id_prof_questioned id_prof_questioned,
                       o.id_speciality id_specialty,
                       o.id_clinical_service,
                       get_buttons_state(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_prof_questions   => o.id_prof_questions,
                                         i_id_prof_questioned  => o.id_prof_questioned,
                                         i_id_specialty        => o.id_speciality,
                                         i_id_clinical_service => o.id_clinical_service,
                                         i_flg_status          => o.flg_state) buttons,
                       pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang) priority,
                       pk_sysdomain.get_rank(i_lang, g_opinion_priority, o.flg_priority) rank_priority
                  FROM opinion o, opinion_prof op
                 WHERE o.id_episode = i_episode
                   AND o.flg_type = g_flg_type_nutritionist
                   AND op.id_opinion(+) = o.id_opinion
                   AND op.flg_type(+) = o.flg_state
                   AND o.flg_state = 'P'
                UNION
                SELECT o.id_opinion,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned) spec_prof,
                       o.id_prof_questions id_prof_requests,
                       nvl2(o.id_clinical_service,
                            (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                               FROM clinical_service cs
                              WHERE cs.id_clinical_service = o.id_clinical_service),
                            nvl2(o.id_speciality,
                                 pk_prof_utils.get_spec_signature(i_lang,
                                                                  i_prof,
                                                                  o.id_prof_questions,
                                                                  o.dt_problem_tstz,
                                                                  o.id_episode),
                                 NULL)) spec_clin_serv,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) prof_req,
                       pk_sysdomain.get_domain(g_opinion_consults, o.flg_state, i_lang) state,
                       pk_date_utils.dt_chr_tsz(i_lang, o.dt_problem_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang, o.dt_problem_tstz, i_prof.institution, i_prof.software) hour_target,
                       o.desc_problem,
                       o.flg_state,
                       pk_utils.get_status_string(i_lang,
                                                  i_prof,
                                                  o.status_str,
                                                  o.status_icon,
                                                  o.status_msg,
                                                  o.status_flg) status_string,
                       pk_date_utils.date_char_tsz(i_lang, dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                       decode(o.flg_state, g_opinion_cancel, 'Y', 'N') flg_cancel,
                       to_char(o.dt_problem_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                       decode(nvl(o.notes_cancel, '#'), '#', NULL, pk_message.get_message(i_lang, 'COMMON_M008')) title_notes,
                       pk_sysdomain.get_rank(i_lang, g_opinion_consults, o.flg_state) rank,
                       o.dt_problem_tstz dt_problem,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional) prof_resp,
                       o.id_prof_questioned id_prof_questioned,
                       o.id_speciality id_specialty,
                       o.id_clinical_service,
                       get_buttons_state(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_prof_questions   => o.id_prof_questions,
                                         i_id_prof_questioned  => o.id_prof_questioned,
                                         i_id_specialty        => o.id_speciality,
                                         i_id_clinical_service => o.id_clinical_service,
                                         i_flg_status          => o.flg_state) buttons,
                       pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang) priority,
                       pk_sysdomain.get_rank(i_lang, g_opinion_priority, o.flg_priority) rank_priority
                  FROM opinion o, opinion_prof op
                 WHERE o.id_episode = i_episode
                   AND o.flg_type = g_flg_type_nutritionist
                   AND op.id_opinion(+) = o.id_opinion
                   AND o.flg_state IN ('F', 'R', 'C', 'A')
                 ORDER BY rank, rank_priority, dt_problem DESC;
        ELSIF i_flg_type = g_flg_type_case_manager
        THEN
            l_message := 'OPEN o_opinion (Case manager)';
            OPEN o_opinion FOR
                SELECT id_opinion,
                       (SELECT get_cm_req_origin(i_lang, i_prof, o.id_episode)
                          FROM dual) origin,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) req_prof,
                       pk_date_utils.dt_chr_tsz(i_lang, o.dt_problem_tstz, i_prof) req_date,
                       pk_date_utils.dt_chr_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) req_time,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned) case_manager,
                       o.flg_state,
                       pk_sysdomain.get_domain(g_opinion_consults, o.flg_state, i_lang) state_desc,
                       get_cm_req_reason(i_lang, i_prof, o.id_opinion) req_reason,
                       decode(o.flg_state,
                              g_opinion_cancel,
                              decode(nvl(o.notes_cancel, '#'), '#', NULL, pk_message.get_message(i_lang, 'COMMON_M008')),
                              decode(nvl(desc_problem, '#'), '#', NULL, pk_message.get_message(i_lang, 'COMMON_M008'))) title_notes,
                       o.id_prof_questioned id_prof_questioned,
                       o.id_speciality id_specialty,
                       o.id_clinical_service,
                       get_buttons_state(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_prof_questions   => o.id_prof_questions,
                                         i_id_prof_questioned  => o.id_prof_questioned,
                                         i_id_specialty        => o.id_speciality,
                                         i_id_clinical_service => o.id_clinical_service,
                                         i_flg_status          => o.flg_state) buttons,
                       pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang) priority,
                       pk_sysdomain.get_rank(i_lang, g_opinion_priority, o.flg_priority) rank_priority
                  FROM opinion o
                  JOIN opinion_type ot
                    ON o.id_opinion_type = ot.id_opinion_type
                  JOIN opinion_type_category otc
                    ON otc.id_opinion_type = ot.id_opinion_type
                  JOIN category c
                    ON otc.id_category = c.id_category
                 WHERE c.flg_type = pk_alert_constant.g_cat_type_case_manager
                   AND o.id_patient = i_patient
                 ORDER BY decode(o.flg_state, g_opinion_cancel, 1, 0), rank_priority, o.dt_problem_tstz DESC;
        ELSE
            l_message := 'GET CURSOR';
            OPEN o_opinion FOR
                SELECT o.id_opinion,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) spec_prof,
                       p_req.id_professional id_prof_requests,
                       nvl2(o.id_clinical_service,
                            pk_translation.get_translation(i_lang, cs.code_clinical_service),
                            nvl2(o.id_speciality, pk_translation.get_translation(i_lang, s.code_speciality), NULL)) spec_clin_serv,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p_req.id_professional) prof_req,
                       pk_sysdomain.get_domain(g_opinion_consults, o.flg_state, i_lang) state,
                       pk_date_utils.dt_chr_tsz(i_lang, o.dt_problem_tstz, i_prof) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang, o.dt_problem_tstz, i_prof.institution, i_prof.software) hour_target,
                       o.desc_problem,
                       o.flg_state,
                       pk_utils.get_status_string(i_lang,
                                                  i_prof,
                                                  o.status_str,
                                                  o.status_icon,
                                                  o.status_msg,
                                                  o.status_flg) status_string,
                       pk_date_utils.date_char_tsz(i_lang, dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                       decode(o.flg_state, g_opinion_cancel, 'Y', 'N') flg_cancel,
                       to_char(o.dt_problem_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                       decode(nvl(o.notes_cancel, '#'), '#', NULL, pk_message.get_message(i_lang, 'COMMON_M008')) title_notes,
                       o.id_prof_questioned id_prof_questioned,
                       o.id_speciality id_specialty,
                       o.id_clinical_service,
                       get_buttons_state(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_prof_questions   => o.id_prof_questions,
                                         i_id_prof_questioned  => o.id_prof_questioned,
                                         i_id_specialty        => o.id_speciality,
                                         i_id_clinical_service => o.id_clinical_service,
                                         i_flg_status          => o.flg_state) buttons,
                       pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang) priority,
                       pk_sysdomain.get_rank(i_lang, g_opinion_priority, o.flg_priority) rank_priority
                  FROM opinion o, professional p, speciality s, professional p_req, clinical_service cs
                 WHERE o.id_episode = i_episode
                   AND o.id_opinion_type IS NULL
                   AND (l_flg_status_count = 0 OR
                       o.flg_state IN (SELECT t1.column_value
                                          FROM TABLE(l_tbl_status) t1))
                   AND s.id_speciality(+) = o.id_speciality
                   AND p.id_professional(+) = o.id_prof_questioned
                   AND cs.id_clinical_service(+) = o.id_clinical_service
                   AND p_req.id_professional = o.id_prof_questions
                 ORDER BY pk_sysdomain.get_rank(i_lang, g_opinion_consults, o.flg_state),
                          rank_priority,
                          o.dt_problem_tstz DESC;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_OPINION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_opinion);
            RETURN FALSE;
    END;

    FUNCTION get_epis_opinion_by_prof
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_limit_max IN NUMBER,
        i_limit_min IN NUMBER,
        o_opinion   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message debug_msg;
    BEGIN
    
        l_message := 'GET CURSOR';
    
        OPEN o_opinion FOR
            SELECT *
              FROM (SELECT rownum rn,
                           xmain.id_opinion,
                           xmain.name_patient,
                           xmain.id_prof_questions,
                           xmain.id_prof_questioned,
                           xmain.desc_problem,
                           xmain.id_episode,
                           xmain.id_patient,
                           xmain.name_prof_questions,
                           xmain.id_speciality,
                           xmain.speciality_desc,
                           xmain.date_opinion_create
                      FROM (SELECT o.id_opinion,
                                   p.name name_patient,
                                   o.id_prof_questions,
                                   o.id_prof_questioned,
                                   o.desc_problem,
                                   o.id_episode,
                                   o.id_patient,
                                   pr.name name_prof_questions,
                                   s.id_speciality,
                                   pk_translation.get_translation(i_lang, s.code_speciality) speciality_desc,
                                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                               i_date => o.dt_problem_tstz,
                                                               i_inst => i_prof.institution,
                                                               i_soft => i_prof.software) date_opinion_create
                              FROM opinion o
                              JOIN patient p
                                ON o.id_patient = p.id_patient
                              JOIN professional pr
                                ON o.id_prof_questions = pr.id_professional
                              JOIN speciality s
                                ON o.id_speciality = s.id_speciality
                             WHERE o.id_prof_questioned = i_prof.id
                               AND o.flg_state NOT IN (g_opinion_cancel, g_opinion_rejected)
                             ORDER BY o.dt_problem_tstz DESC) xmain) xfilter
             WHERE rn BETWEEN i_limit_min AND i_limit_max;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_OPINION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_opinion);
            RETURN FALSE;
    END;

    FUNCTION get_opin_prof
    (
        i_lang      IN language.id_language%TYPE,
        i_opinion   IN opinion.id_opinion%TYPE,
        i_prof      IN profissional,
        o_opinion   OUT pk_types.cursor_type,
        o_opin_prof OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter info de um pedido de parecer
           PARAMETROS:  Entrada: I_LANG - Lingua registada como preferencia do profissional
                       I_OPINION - ID do pedido de opini?o
                  Saida:   O_OPINION - Registo do pedido de opii?o
                        O_OPIN_PROF - registos de leitura / resposta
                             ao pedido de parecer
                     O_ERROR - erro
        
          CRIAC?O: CRS 2005/03/10
          NOTAS:
        *********************************************************************************/
        l_message  debug_msg;
        l_flg_type opinion.flg_type%TYPE;
    
    BEGIN
    
        SELECT nvl(o.flg_type, 'O')
          INTO l_flg_type
          FROM opinion o
         WHERE o.id_opinion = i_opinion;
        -- Jos?rito 31/03/2008 WO11232
        -- Devolver a especialidade do profissional que foi questionado; Query reformulada.
        l_message := 'GET O_OPINION';
        OPEN o_opinion FOR
            SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p_req.id_professional) prof_req,
                   nvl2(o.id_speciality,
                        pk_prof_utils.get_spec_signature(i_lang,
                                                         i_prof,
                                                         p_req.id_professional,
                                                         o.dt_problem_tstz,
                                                         o.id_episode),
                        NULL) desc_spec,
                   o.desc_problem,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p_quest.id_professional) prof_questioned,
                   nvl2(o.id_speciality,
                        (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                           FROM speciality s
                          WHERE s.id_speciality = o.id_speciality),
                        NULL) desc_spec_questioned,
                   nvl2(o.id_clinical_service,
                        (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                           FROM clinical_service cs
                          WHERE cs.id_clinical_service = o.id_clinical_service),
                        NULL) desc_clin_serv_questioned,
                   pk_date_utils.dt_chr_tsz(i_lang, dt_problem_tstz, i_prof.institution, i_prof.software) dt_problem_cancel,
                   pk_date_utils.date_char_tsz(i_lang, dt_problem_tstz, i_prof.institution, i_prof.software) dt_problem,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_problem_tstz, i_prof.institution, i_prof.software) hr_problem,
                   decode(o.flg_state, g_opinion_cancel, pk_message.get_message(i_lang, 'COMMON_T022') || ':', '') title_cancel,
                   o.notes_cancel,
                   pk_message.get_message(i_lang, 'COMMON_M072') || ':' title_cancel_reason,
                   pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, o.id_cancel_reason) cancel_reason,
                   pk_date_utils.date_char_tsz(i_lang, dt_cancel_tstz, i_prof.institution, i_prof.software) dt_cancel,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_cancel_tstz, i_prof.institution, i_prof.software) hr_cancel,
                   pk_sysdomain.get_domain('OPINION.FLG_STATE', o.flg_state, i_lang) desc_status,
                   pk_date_utils.date_send_tsz(i_lang, dt_problem_tstz, i_prof) dt_problem_tsz,
                   pk_sysdomain.get_domain(g_opinion_consults, o.flg_state, i_lang) desc_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_cancel) prof_cancel,
                   pk_message.get_message(i_lang, 'PENDING_ISSUE_T034') || ':' AS title_message,
                   pk_message.get_message(i_lang, 'COMMON_M146') title_block_request,
                   pk_message.get_message(i_lang, 'COMMON_M147') title_block_cancel,
                   pk_message.get_message(i_lang, 'OPINION_M021') || ':' AS title_priority,
                   pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang) desc_priority
            
              FROM opinion o,
                   -- Profissional/especialidade que requisitou parecer
                   professional p_req,
                   speciality   s_req,
                   -- Profissional/especialidade que foi questionado
                   professional p_quest,
                   speciality   s_quest
             WHERE o.id_opinion = i_opinion
               AND p_quest.id_professional(+) = o.id_prof_questioned
               AND p_req.id_professional = o.id_prof_questions
               AND s_req.id_speciality(+) = p_req.id_speciality
                  -- JB 31/03/08: pode-se ir buscar directamente a especialidade do prof. questionado ?abela OPINION.
               AND o.id_speciality = s_quest.id_speciality(+);
        --AND s1.id_speciality(+) = p.id_speciality;
    
        IF l_flg_type = g_flg_type_nutritionist
        THEN
            l_message := 'GET O_OPIN_PROF';
            OPEN o_opin_prof FOR
                SELECT op1.desc_reply,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       REPLACE(REPLACE(decode(op1.flg_type,
                                              g_opin_prof_read,
                                              pk_message.get_message(i_lang, 'OPINION_M005'),
                                              g_opin_prof_reply,
                                              pk_message.get_message(i_lang, 'OPINION_M006')),
                                       '@1',
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)),
                               '@2',
                               pk_date_utils.date_char_tsz(i_lang,
                                                           op1.dt_opinion_prof_tstz,
                                                           i_prof.institution,
                                                           i_prof.software)) text,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   op1.dt_opinion_prof_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_opinion_prof,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        p.id_professional,
                                                        NULL, -- falta liga? com epis? por isso dt_req e id_episodio v?a NULL
                                                        NULL) spec,
                       op1.flg_face_to_face,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, op1.id_prof_co_sign) prof_co_sign,
                       pk_date_utils.date_char_tsz(i_lang, op1.dt_co_sign, i_prof.institution, i_prof.software) dt_co_sign,
                       op1.notes_co_sign notes_co_sign,
                       pk_translation.get_translation(i_lang, ot.code_order_type) order_type_desc,
                       pk_date_utils.date_send_tsz(i_lang, op1.dt_opinion_prof_tstz, i_prof) dt_opinion_prof_tsz,
                       pk_date_utils.date_send_tsz(i_lang, op1.dt_co_sign, i_prof) dt_co_sign_tsz
                
                  FROM opinion_prof op1, professional p, order_type ot
                 WHERE op1.id_opinion = i_opinion
                   AND ((op1.flg_type = g_opin_prof_reply) OR
                       (op1.flg_type = g_opin_prof_read AND
                       (op1.id_professional, op1.dt_opinion_prof_tstz) IN
                       (SELECT id_professional, MIN(dt_opinion_prof_tstz)
                            FROM opinion_prof
                           WHERE id_opinion = i_opinion
                           GROUP BY id_professional)))
                   AND p.id_professional = op1.id_professional
                   AND op1.id_order_type = ot.id_order_type(+)
                 ORDER BY op1.dt_opinion_prof_tstz DESC;
        ELSE
        
            l_message := 'GET O_OPIN_PROF';
            OPEN o_opin_prof FOR
                SELECT op1.desc_reply,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name,
                       REPLACE(REPLACE(decode(op1.flg_type,
                                              g_opin_prof_read,
                                              pk_message.get_message(i_lang, 'OPINION_M005'),
                                              g_opin_prof_reply,
                                              pk_message.get_message(i_lang, 'OPINION_M006')),
                                       '@1',
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional)),
                               '@2',
                               pk_date_utils.date_char_tsz(i_lang,
                                                           op1.dt_opinion_prof_tstz,
                                                           i_prof.institution,
                                                           i_prof.software)) text,
                       pk_date_utils.date_char_tsz(i_lang,
                                                   op1.dt_opinion_prof_tstz,
                                                   i_prof.institution,
                                                   i_prof.software) dt_opinion_prof,
                       --pk_translation.get_translation(i_lang, s.code_speciality) spec
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        p.id_professional,
                                                        NULL, -- falta liga? com epis? por isso dt_req e id_episodio v?a NULL
                                                        NULL) spec,
                       op1.flg_face_to_face,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, op1.id_prof_co_sign) prof_co_sign,
                       pk_date_utils.date_char_tsz(i_lang, op1.dt_co_sign, i_prof.institution, i_prof.software) dt_co_sign,
                       pk_translation.get_translation(i_lang, ot.code_order_type) order_type_desc,
                       pk_date_utils.date_send_tsz(i_lang, op1.dt_opinion_prof_tstz, i_prof) dt_opinion_prof_tsz,
                       pk_date_utils.date_send_tsz(i_lang, op1.dt_co_sign, i_prof) dt_co_sign_tsz
                
                  FROM opinion_prof op1, professional p, speciality s, order_type ot
                 WHERE op1.id_opinion = i_opinion
                   AND ((op1.flg_type = g_opin_prof_reply) OR
                       (op1.flg_type = g_opin_prof_read AND
                       (op1.id_professional, op1.dt_opinion_prof_tstz) IN
                       (SELECT id_professional, MIN(dt_opinion_prof_tstz)
                            FROM opinion_prof
                           WHERE id_opinion = i_opinion
                           GROUP BY id_professional)))
                   AND p.id_professional = op1.id_professional
                   AND s.id_speciality = p.id_speciality
                   AND op1.id_order_type = ot.id_order_type(+)
                 ORDER BY op1.dt_opinion_prof_tstz DESC;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OPIN_PROF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_opinion);
            pk_types.open_my_cursor(o_opin_prof);
            RETURN FALSE;
    END;

    FUNCTION get_opin_prof
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message  debug_msg;
        l_flg_type opinion.flg_type%TYPE;
    
        l_tab_dd_block_data t_tab_dd_block_data := t_tab_dd_block_data();
        l_tab_dd_data       t_tab_dd_data := t_tab_dd_data();
        l_data_source_list  table_varchar := table_varchar();
    
        l_tab_dd_opin_prof t_tab_dd_block_data := t_tab_dd_block_data();
    BEGIN
    
        SELECT nvl(o.flg_type, 'O')
          INTO l_flg_type
          FROM opinion o
         WHERE o.id_opinion = i_opinion;
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   ddb.rank,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT t.*
                          FROM (SELECT ' ' title_block_request,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, p_quest.id_professional) ||
                                       decode(p_quest.id_professional, NULL, NULL, ' (') ||
                                       coalesce(decode(o.id_clinical_service,
                                                       NULL,
                                                       NULL,
                                                       (SELECT pk_translation.get_translation(i_lang,
                                                                                              cs.code_clinical_service)
                                                          FROM clinical_service cs
                                                         WHERE cs.id_clinical_service = o.id_clinical_service)),
                                                decode(o.id_speciality,
                                                       NULL,
                                                       NULL,
                                                       (SELECT pk_translation.get_translation(2, s.code_speciality)
                                                          FROM speciality s
                                                         WHERE s.id_speciality = o.id_speciality))) ||
                                       decode(p_quest.id_professional, NULL, NULL, ')') prof_questioned,
                                       pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang) priority,
                                       o.desc_problem,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   o.dt_problem_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software) || g_semicolon ||
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) || ' (' ||
                                       nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                            i_prof,
                                                                            o.id_prof_questions,
                                                                            o.dt_problem_tstz,
                                                                            o.id_episode),
                                           pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T069')) || ')' registry,
                                       ' ' white_line,
                                       --CANCEL INFO
                                       CASE o.flg_state
                                           WHEN 'C' THEN
                                            ' '
                                           ELSE
                                            NULL
                                       END title_block_cancel,
                                       CASE o.flg_state
                                           WHEN 'C' THEN
                                            pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, o.id_cancel_reason)
                                           ELSE
                                            NULL
                                       END cancel_reason,
                                       o.notes_cancel cancel_notes,
                                       CASE o.flg_state
                                           WHEN 'C' THEN
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        o.dt_cancel_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || g_semicolon ||
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_cancel) || ' (' ||
                                            nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                                 i_prof,
                                                                                 o.id_prof_cancel,
                                                                                 o.dt_cancel_tstz,
                                                                                 o.id_episode),
                                                pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T069')) || ')'
                                           ELSE
                                            NULL
                                       END cancel_registry,
                                       CASE o.flg_state
                                           WHEN 'C' THEN
                                            ' '
                                           ELSE
                                            NULL
                                       END cancel_white_line
                                  FROM opinion o,
                                       -- Profissional/especialidade que requisitou parecer
                                       professional p_req,
                                       speciality   s_req,
                                       -- Profissional/especialidade que foi questionado
                                       professional p_quest,
                                       speciality   s_quest
                                 WHERE o.id_opinion = i_opinion
                                   AND p_quest.id_professional(+) = o.id_prof_questioned
                                   AND p_req.id_professional = o.id_prof_questions
                                   AND s_req.id_speciality(+) = p_req.id_speciality
                                      -- JB 31/03/08: pode-se ir buscar directamente a especialidade do prof. questionado ?abela OPINION.
                                   AND o.id_speciality = s_quest.id_speciality(+)) t) unpivot include NULLS(data_source_val FOR data_source IN(title_block_request,
                                                                                                                                               prof_questioned,
                                                                                                                                               priority,
                                                                                                                                               desc_problem,
                                                                                                                                               registry,
                                                                                                                                               white_line,
                                                                                                                                               title_block_cancel,
                                                                                                                                               cancel_reason,
                                                                                                                                               cancel_notes,
                                                                                                                                               cancel_registry,
                                                                                                                                               cancel_white_line))) dd
          JOIN dd_block ddb
            ON ddb.area = 'CONSULTS'
           AND ddb.condition_desc IN ('REQUISITION', 'CANCEL')
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   (ddb.rank * 100) + rn,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_opin_prof
          FROM (SELECT data_source, data_source_val, row_number() over(PARTITION BY data_source ORDER BY rownum) AS rn
                  FROM (SELECT t.*
                          FROM (SELECT decode(rownum, 1, ' ', NULL) title_block_reply,
                                       decode(flg_face_to_face,
                                              pk_alert_constant.g_yes,
                                              pk_message.get_message(i_lang, 'COMMON_M022'),
                                              pk_alert_constant.g_no,
                                              pk_message.get_message(i_lang, 'COMMON_M023')) face_to_face,
                                       desc_reply,
                                       pk_sysdomain.get_domain('OPINION_PROF.FLG_TYPE', flg_type, i_lang) status,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, id_prof_co_sign) reply_from,
                                       pk_translation.get_translation(i_lang, code_order_type) reply_type,
                                       pk_date_utils.date_char_tsz(i_lang, dt_co_sign, i_prof.institution, i_prof.software) reply_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software) || g_semicolon ||
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || ' (' ||
                                       nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                            i_prof,
                                                                            id_professional,
                                                                            dt_opinion_prof_tstz,
                                                                            NULL),
                                           pk_message.get_message(i_lang, i_prof, 'PROBLEM_LIST_T069')) || ')' registry,
                                       ' ' white_line
                                  FROM (SELECT op1.flg_face_to_face,
                                               op1.desc_reply,
                                               op1.flg_type,
                                               op1.dt_opinion_prof_tstz,
                                               p.id_professional,
                                               op1.id_prof_co_sign,
                                               ot.code_order_type,
                                               op1.dt_co_sign
                                          FROM opinion_prof op1, professional p, speciality s, order_type ot
                                         WHERE op1.id_opinion = i_opinion
                                           AND ((op1.flg_type IN (g_opin_prof_reply, g_opin_prof_reply_read)) OR
                                               (op1.flg_type = g_opin_prof_read AND
                                               (op1.id_professional, op1.dt_opinion_prof_tstz) IN
                                               (SELECT id_professional, MIN(dt_opinion_prof_tstz)
                                                    FROM opinion_prof
                                                   WHERE id_opinion = i_opinion
                                                   GROUP BY id_professional)))
                                           AND p.id_professional = op1.id_professional
                                           AND s.id_speciality = p.id_speciality
                                           AND op1.id_order_type = ot.id_order_type(+)
                                         ORDER BY op1.dt_opinion_prof_tstz ASC)) t) unpivot include NULLS(data_source_val FOR data_source IN(title_block_reply,
                                                                                                                                             face_to_face,
                                                                                                                                             desc_reply,
                                                                                                                                             status,
                                                                                                                                             reply_from,
                                                                                                                                             reply_type,
                                                                                                                                             reply_date,
                                                                                                                                             registry,
                                                                                                                                             white_line))) dd
          JOIN dd_block ddb
            ON ddb.area = 'CONSULTS'
           AND ddb.condition_desc = 'REPLY'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  ELSE
                                   NULL
                              END,
                              CASE
                                  WHEN flg_type = 'L1' THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END,
                              flg_type,
                              flg_html,
                              NULL,
                              flg_clob),
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'CONSULTS'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L2N' /*, 'WL'*/))
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       db.id_dd_block,
                       flg_html,
                       flg_clob
                  FROM TABLE(l_tab_dd_opin_prof) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = 'CONSULTS'
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR flg_type IN ('L2N' /*, 'WL'*/)))
         ORDER BY rnk, rank;
    
        g_error := 'OPEN O_DETAIL';
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || decode(d.flg_type, 'LP', NULL, ': ')
                            END descr,
                           d.val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OPIN_PROF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --   pk_types.open_my_cursor(o_opinion);
            --  pk_types.open_my_cursor(o_opin_prof);
            RETURN FALSE;
    END;

    FUNCTION cancel_opinion
    (
        i_lang    IN language.id_language%TYPE,
        i_opinion IN opinion.id_opinion%TYPE,
        i_prof    IN profissional,
        i_notes   IN opinion.notes_cancel%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Chama a fun? cancel_opinion com o valor do par?tro commit_data a YES
           PARAMETROS:  Entrada: I_LANG - Lingua registada como preferencia do profissional
                   I_OPINION - ID do registo a actualizar
                 I_PROF - user
                                 I_NOTES - notas de cancelamento
                  Saida:   O_ERROR - erro
        
          CRIAC?O: CRS 2005/03/10
          NOTAS:
        *********************************************************************************/
    BEGIN
        RETURN cancel_opinion(i_lang          => i_lang,
                              i_opinion       => i_opinion,
                              i_prof          => i_prof,
                              i_notes         => i_notes,
                              i_cancel_reason => NULL,
                              i_commit_data   => pk_alert_constant.g_yes,
                              i_flg_type      => NULL,
                              o_error         => o_error);
    
    END;

    FUNCTION cancel_opinion
    (
        i_lang          IN language.id_language%TYPE,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes         IN opinion.notes_cancel%TYPE,
        i_flg_type      IN opinion.flg_type%TYPE DEFAULT 'O',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:  Chama a fun? cancel_opinion com o valor do par?tro commit_data a YES
           PARAMETROS:  Entrada: I_LANG - Lingua registada como preferencia do profissional
                   I_OPINION - ID do registo a actualizar
                 I_PROF - user
                                 I_NOTES - notas de cancelamento
                  Saida:   O_ERROR - erro
        
          CRIAC?O: CRS 2005/03/10
          NOTAS:
        *********************************************************************************/
    BEGIN
        RETURN cancel_opinion(i_lang          => i_lang,
                              i_opinion       => i_opinion,
                              i_prof          => i_prof,
                              i_notes         => i_notes,
                              i_cancel_reason => i_cancel_reason,
                              i_commit_data   => pk_alert_constant.g_yes,
                              i_flg_type      => i_flg_type,
                              o_error         => o_error);
    
    END;

    /******************************************************************************
       OBJECTIVO:  Cancelar o pedido de opini?o
       PARAMETROS:  Entrada: I_LANG - Lingua registada como preferencia do profissional
                 I_OPINION - ID do registo a actualizar
                 I_PROF - user
                 I_NOTES - notas de cancelamento
                 I_COMMIT_DATA - Flag que indica se a fun? deve fazer o commit dos dados
          Saida:   O_ERROR - erro
    
      CRIAC?O: CRS 2005/03/10
      NOTAS:
    *********************************************************************************/
    FUNCTION cancel_opinion
    (
        i_lang          IN language.id_language%TYPE,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_prof          IN profissional,
        i_notes         IN opinion.notes_cancel%TYPE,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE,
        i_dt_cancel     IN opinion.dt_cancel_tstz%TYPE DEFAULT current_timestamp,
        i_commit_data   IN VARCHAR2,
        i_flg_type      IN opinion.flg_type%TYPE DEFAULT 'O',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message     debug_msg;
        l_commit_data BOOLEAN;
        l_sysdate_tstz CONSTANT TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_consult_req_prof_cancel sys_config.value%TYPE := pk_sysconfig.get_config('CANCEL_CONSULT_OTHER_PROF', i_prof);
    
        CURSOR c_epis IS
            SELECT id_episode, id_prof_questions, flg_state
              FROM opinion
             WHERE id_opinion = i_opinion;
        r_epis c_epis%ROWTYPE;
    
        l_rows table_varchar := table_varchar();
    
        l_error_in           t_error_in := t_error_in();
        l_ret                BOOLEAN;
        l_config_create_note sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'CONSULTS_CREATE_REQUEST_NOTE',
                                                                              i_prof    => i_prof);
    
        -- inline function
        FUNCTION set_error
        (
            i_code IN VARCHAR2,
            i_desc IN VARCHAR2
        ) RETURN BOOLEAN IS
        BEGIN
        
            l_error_in.set_all(i_lang,
                               i_code,
                               i_desc,
                               NULL,
                               g_package_owner,
                               g_package_name,
                               'CANCEL_OPINION',
                               l_message,
                               'U');
        
            l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
        
        END set_error;
        -- ###################
    
    BEGIN
    
        l_commit_data := NOT (i_commit_data = 'N');
    
        l_message := 'OPEN CURSOR C_EPIS';
        OPEN c_epis;
        FETCH c_epis
            INTO r_epis;
        CLOSE c_epis;
    
        IF r_epis.flg_state = g_opinion_cancel
        THEN
            -- Pedido ja tinha sido cancelado
            l_message := REPLACE(pk_message.get_message(i_lang, 'COMMON_M005'),
                                 '@1',
                                 pk_message.get_message(i_lang, 'OPINION_T011'));
        
            l_ret := set_error(i_code => 'COMMON_M005', i_desc => l_message);
            RETURN l_ret;
        
        ELSIF r_epis.id_prof_questions != i_prof.id
              AND l_consult_req_prof_cancel = pk_alert_constant.g_no
        THEN
            -- Prof q tenta cancelar ? e o requisitante
            l_message := pk_message.get_message(i_lang, 'OPINION_M002');
        
            l_ret := set_error(i_code => 'OPINION_M002', i_desc => l_message);
            RETURN l_ret;
        
        ELSIF r_epis.flg_state IN (g_opinion_reply, g_opinion_rejected, g_opinion_over, g_opinion_accepted)
        THEN
            -- Se o pedido ja foi respondido, ? pode ser cancelado
            l_message := pk_message.get_message(i_lang, 'OPINION_M003');
        
            l_ret := set_error(i_code => 'OPINION_M003', i_desc => l_message);
            RETURN l_ret;
        END IF;
    
        l_message := 'UPDATE';
        ts_opinion.upd(flg_state_in        => g_opinion_cancel,
                       dt_cancel_tstz_in   => i_dt_cancel,
                       notes_cancel_in     => i_notes,
                       id_cancel_reason_in => i_cancel_reason,
                       id_opinion_in       => i_opinion,
                       id_prof_cancel_in   => i_prof.id,
                       rows_out            => l_rows);
    
        l_message := 't_data_gov_mnt.process_update ts_opinion';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'OPINION',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATE',
                                                                      'DT_CANCEL_TSTZ',
                                                                      'NOTES_CANCEL',
                                                                      'ID_OPINION',
                                                                      'ID_CANCEL_REASON'));
    
        pk_ia_event_common.opinion_order_cancel(i_id_opinion => i_opinion, i_id_episode => r_epis.id_episode);
    
        -- CJV BEGIN : Altera? de alertas
        IF NOT
            alert_opinion_request(i_lang => i_lang, i_opinion => i_opinion, i_flg_type => i_flg_type, o_error => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        -- CJV END : Altera? de alertas
    
        --ALERT-122350 - Tracking view- Patient status column: Consultation request
        --AS BEGIN: 2010-09-07
        g_error := 'GET UNANSWERED OPINIONS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_patient_tracking.set_after_opinion_status(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_episode    => r_epis.id_episode,
                                                            i_flg_status => g_opinion_cancel,
                                                            o_error      => o_error)
        THEN
            RAISE e_pat_tracking;
        END IF;
        --AS END
    
        -- CANCEL NOTE
        IF l_config_create_note = pk_alert_constant.g_yes
        THEN
            IF NOT cancel_consult_note(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_id_episode    => r_epis.id_episode,
                                       i_id_opinion    => i_opinion,
                                       i_cancel_reason => i_cancel_reason,
                                       i_notes_cancel  => i_notes,
                                       o_error         => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END IF;
        END IF;
        l_message := 'CALL TO SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => r_epis.id_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => i_dt_cancel,
                                      i_dt_first_obs        => i_dt_cancel,
                                      o_error               => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        IF l_commit_data
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_OPINION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_opinion;

    FUNCTION get_face_to_face_available
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_face_to_face OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:  Check if face to face is available for this professional
           PARAMETROS:  Entrada: I_LANG - Professional languange
                                 I_PROF - user
                  Saida:   O_ERROR - erro
        
          CRIACAO: RD 2009/03/22
          CHANGED BY: FM 2009/04/13
          NOTAS:
        *********************************************************************************/
        l_message    debug_msg;
        i_is_default BOOLEAN;
    
        i_res VARCHAR2(1);
    BEGIN
    
        i_is_default := pk_opinion.get_face_to_face_default(i_lang, i_prof, o_error);
    
        IF (i_is_default)
        THEN
            i_res := pk_alert_constant.g_yes;
        ELSE
            i_res := pk_alert_constant.g_no;
        END IF;
    
        l_message := 'GET CURSOR';
        OPEN o_face_to_face FOR
            SELECT face_to_face_flg, face_to_face_default_flg, face_to_face_desc
              FROM (SELECT sc.value face_to_face_flg,
                           nvl(i_res, pk_alert_constant.g_no) face_to_face_default_flg,
                           sm.desc_message face_to_face_desc
                      FROM sys_config sc, sys_message sm
                     WHERE sc.id_sys_config = g_opinion_f_t_f_available
                       AND ((sc.id_software = i_prof.software AND sc.id_institution = i_prof.institution) OR
                           sc.id_software = 0 OR sc.id_institution = 0)
                       AND sm.code_message = 'OPINION_M008'
                       AND sm.id_language = i_lang
                       AND rownum = 1
                    UNION ALL
                    SELECT pk_alert_constant.g_no face_to_face_flg,
                           pk_alert_constant.g_no face_to_face_default_flg,
                           '' face_to_face_desc
                      FROM dual)
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FACE_TO_FACE_AVAILABLE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_face_to_face);
            RETURN FALSE;
    END;

    FUNCTION get_face_to_face_default
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:  Check if face to face is selected by default
           PARAMETROS:  Entrada: I_LANG - Professional languange
                                 I_PROF - user
                  Saida:   O_ERROR - erro
        
          CRIACAO: FM 2009/04/13
          NOTAS:
        *********************************************************************************/
        l_message debug_msg;
    
        CURSOR c_f_to_f_default IS
            SELECT face_to_face_default_flg
              FROM (SELECT scd.value face_to_face_default_flg
                      FROM sys_config scd
                     WHERE scd.id_sys_config = 'OPINION_FACE_TO_FACE_DEFAULT_SELECTED'
                       AND (scd.id_software = i_prof.software OR scd.id_software = 0)
                       AND (scd.id_institution = i_prof.institution OR scd.id_institution = 0)
                       AND rownum = 1
                    UNION ALL
                    SELECT 'N' face_to_face_default_flg
                      FROM dual)
             WHERE rownum = 1;
    
        rec_f_to_f_default c_f_to_f_default%ROWTYPE;
    BEGIN
        l_message := 'OPEN c_f_to_f_default';
        OPEN c_f_to_f_default;
        FETCH c_f_to_f_default
            INTO rec_f_to_f_default;
        CLOSE c_f_to_f_default;
    
        IF rec_f_to_f_default.face_to_face_default_flg = pk_alert_constant.g_no
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FACE_TO_FACE_AVAILABLE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            --pk_types.open_my_cursor(c_f_to_f_default);
            RETURN FALSE;
    END;

    /*******************************************************************************************
    * Checks if a case is requestable. The logged professional and current patient are considered.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_prof_cat         logged professional category
    * @param i_patient          patient identifier
    * @param o_avail            'Y', if cases are requestable, 'N' otherwise
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/18
    ********************************************************************************************/
    FUNCTION check_cm_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_patient  IN opinion.id_patient%TYPE,
        o_avail    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_count   PLS_INTEGER;
    
        CURSOR c_ongoing_case IS
            SELECT COUNT(1)
              FROM opinion o
             WHERE o.flg_type = pk_opinion.g_flg_type_case_manager
               AND o.id_patient = i_patient
               AND o.flg_state IN
                   (g_opinion_req, g_opinion_req_read, g_opinion_reply, g_opinion_reply_read, g_opinion_accepted);
    BEGIN
        IF i_prof_cat = pk_alert_constant.g_cat_type_doc
        THEN
            l_message := 'OPEN c_ongoing_case';
            OPEN c_ongoing_case;
            FETCH c_ongoing_case
                INTO l_count;
            CLOSE c_ongoing_case;
        
            IF l_count > 0
            THEN
                o_avail := pk_alert_constant.g_no;
            ELSE
                o_avail := pk_alert_constant.g_yes;
            END IF;
        ELSE
            o_avail := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_CM_REQ',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_cm_req;

    /*******************************************************************************************
    * Retrieve options for requesting a new case.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param o_reason           list of reasons for the request
    * @param o_manager          list of case managers
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.6
    * @since                    2009/08/19
    ********************************************************************************************/
    FUNCTION get_cm_req_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN opinion.id_patient%TYPE,
        o_reason  OUT pk_types.cursor_type,
        o_manager OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message debug_msg;
    
        l_search_diagnosis sys_config.value%TYPE := pk_sysconfig.get_config('PERMISSION_FOR_SEARCH_DIAGNOSIS', i_prof);
        l_other_diagnosis  sys_config.value%TYPE := pk_sysconfig.get_config('PERMISSION_FOR_OTHER_DIAGNOSIS', i_prof);
    
        l_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
    BEGIN
    
        l_message := 'OPEN o_reason';
        OPEN o_reason FOR
            SELECT z.id_epis_diagnosis, z.id_diagnosis, z.code_icd, z.desc_diagnosis, z.icon_name
              FROM (SELECT ed.id_epis_diagnosis,
                           d.id_diagnosis,
                           d.code_icd,
                           pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                      i_id_diagnosis        => d.id_diagnosis,
                                                      i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                      i_code                => d.code_icd,
                                                      i_flg_other           => d.flg_other,
                                                      i_flg_std_diag        => pk_alert_constant.g_yes,
                                                      i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis,
                           pk_sysdomain.get_img(i_lang,
                                                'EPIS_DIAGNOSIS.FLG_STATUS',
                                                pk_alert_constant.g_epis_diag_flg_status_f) icon_name,
                           row_number() over(PARTITION BY d.id_diagnosis ORDER BY ed.dt_epis_diagnosis_tstz DESC) rn
                      FROM epis_diagnosis ed, diagnosis d
                     WHERE ed.id_patient = i_patient
                       AND ed.flg_status NOT IN
                           (pk_alert_constant.g_epis_diag_flg_status_c, pk_alert_constant.g_epis_diag_flg_status_r)
                       AND ((l_other_diagnosis = 'Y') OR
                           ((l_other_diagnosis = 'N') AND
                           (nvl(d.flg_other, pk_alert_constant.g_yes) != pk_alert_constant.g_yes)))
                       AND (ed.flg_type = pk_alert_constant.g_epis_diag_flg_type_d OR NOT EXISTS
                            (SELECT 1
                               FROM epis_diagnosis ed1
                              WHERE ed1.id_patient = i_patient
                                AND ed1.id_diagnosis = ed.id_diagnosis
                                AND ed1.flg_type = pk_alert_constant.g_epis_diag_flg_type_d))
                       AND d.id_diagnosis = ed.id_diagnosis) z
             WHERE z.rn = 1
            UNION
            SELECT NULL id_epis_diagnosis,
                   NULL id_diagnosis,
                   NULL code_icd,
                   pk_message.get_message(i_lang, i_prof, 'ANALYSIS_M070') desc_diagnosis,
                   NULL icon_name
              FROM dual
             WHERE instr(nvl(l_search_diagnosis, '#'), l_profile_template) != 0;
    
        l_message := 'OPEN o_manager';
        IF NOT pk_list.get_cat_prof_list(i_lang        => i_lang,
                                         i_category    => pk_alert_constant.g_cat_type_case_manager,
                                         i_institution => i_prof.institution,
                                         o_profs       => o_manager,
                                         o_error       => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_manager);
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CM_REQ_OPTIONS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_reason);
            pk_types.open_my_cursor(o_manager);
            RETURN FALSE;
    END get_cm_req_options;

    /*******************************************************************************************
    * Retrieve case management request origin (<software> - <clinical_service>).
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_episode          episode identifier
    *
    * @return                   '<software> - <clinical_service>' shaped string
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.6
    * @since                    2009/08/19
    ********************************************************************************************/
    FUNCTION get_cm_req_origin
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_info.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_ret VARCHAR2(4000);
    BEGIN
        SELECT REPLACE(pk_translation.get_translation(i_lang, 'SOFTWARE.CODE_SOFTWARE.' || ei.id_software), '<br>', ' ') ||
               ' - ' ||
               pk_translation.get_translation(i_lang,
                                              'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || dcs.id_clinical_service) origin
          INTO l_ret
          FROM epis_info ei
          LEFT JOIN dep_clin_serv dcs
         USING (id_dep_clin_serv)
         WHERE ei.id_episode = i_episode;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            alertlog.pk_alertlog.log_error(SQLERRM, g_package_name, 'GET_CM_REQ_ORIGIN');
            RETURN NULL;
    END get_cm_req_origin;

    /*
    * Get case manager reasons for request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param o_id_diagnosis   diagnosis identifiers list
    * @param o_diagnosis      diagnosis list
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */
    PROCEDURE get_cm_req_reason
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_opinion            IN opinion.id_opinion%TYPE,
        o_id_diagnosis       OUT table_number,
        o_id_alert_diagnosis OUT table_number,
        o_diagnosis          OUT table_varchar
    ) IS
        l_id_diagnosis       table_number := table_number();
        l_id_alert_diagnosis table_number := table_number();
        l_diagnosis          table_varchar := table_varchar();
    
        CURSOR c_reason IS
            SELECT t.id_diagnosis,
                   t.id_alert_diagnosis,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_alert_diagnosis  => t.id_alert_diagnosis,
                                              i_id_diagnosis        => t.id_diagnosis,
                                              i_desc_epis_diagnosis => t.diagnosis_desc,
                                              i_code                => t.concept_code,
                                              i_flg_other           => t.flg_other,
                                              i_flg_std_diag        => pk_alert_constant.g_yes) desc_diagnosis
              FROM (SELECT opr.id_diagnosis,
                           opr.id_alert_diagnosis,
                           opr.diagnosis_desc,
                           d.concept_code,
                           d.flg_other,
                           row_number() over(PARTITION BY d.id_concept_version, d.id_concept_term ORDER BY d.id_institution DESC, d.id_software DESC) AS rn
                      FROM diagnosis_ea d
                      JOIN opinion_reason opr
                        ON d.id_concept_version = opr.id_diagnosis
                       AND (opr.id_alert_diagnosis IS NULL OR d.id_concept_term = opr.id_alert_diagnosis)
                       AND d.id_institution IN (0, i_prof.institution)
                       AND d.id_software IN (0, i_prof.software)
                     WHERE opr.id_opinion = i_opinion) t
             WHERE t.rn = 1
             ORDER BY desc_diagnosis;
    BEGIN
        IF i_opinion IS NOT NULL
        THEN
            g_error := 'OPEN c_reason';
            OPEN c_reason;
            FETCH c_reason BULK COLLECT
                INTO l_id_diagnosis, l_id_alert_diagnosis, l_diagnosis;
            CLOSE c_reason;
        END IF;
    
        o_id_diagnosis       := l_id_diagnosis;
        o_id_alert_diagnosis := l_id_alert_diagnosis;
        o_diagnosis          := l_diagnosis;
    END get_cm_req_reason;

    /*******************************************************************************************
    * Retrieves a case management request reasons, comma separated.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    *
    * @return                   case management request reasons, comma separated
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/21
    ********************************************************************************************/
    FUNCTION get_cm_req_reason
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE
    ) RETURN VARCHAR2 IS
        l_comma CONSTANT VARCHAR2(2) := '; ';
        l_ret                 VARCHAR2(4000);
        l_reasons             table_varchar := table_varchar();
        l_ids                 table_number := table_number();
        l_ids_alert_diagnosis table_number := table_number();
    BEGIN
        g_error := 'CALL get_cm_req_reason';
        get_cm_req_reason(i_lang               => i_lang,
                          i_opinion            => i_opinion,
                          i_prof               => i_prof,
                          o_id_diagnosis       => l_ids,
                          o_id_alert_diagnosis => l_ids_alert_diagnosis,
                          o_diagnosis          => l_reasons);
    
        l_ret := NULL;
        FOR i IN 1 .. l_reasons.count
        LOOP
            IF i = 1
            THEN
                l_ret := l_reasons(i);
            ELSE
                l_ret := l_ret || l_comma || l_reasons(i);
            END IF;
        END LOOP;
    
        RETURN l_ret;
    END get_cm_req_reason;

    /*******************************************************************************************
    * Retrieves history of operations made in a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param o_hist             cursor (info, details)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.6
    * @since                    2009/08/19
    ********************************************************************************************/
    FUNCTION get_cm_req_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_hist    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_br CONSTANT VARCHAR2(4) := '<br>';
        l_na CONSTANT VARCHAR2(2) := '--';
        l_msg_req        sys_message.desc_message%TYPE;
        l_msg_canc       sys_message.desc_message%TYPE;
        l_msg_acc        sys_message.desc_message%TYPE;
        l_msg_rej        sys_message.desc_message%TYPE;
        l_msg_over       sys_message.desc_message%TYPE;
        l_msg_reqd       sys_message.desc_message%TYPE;
        l_msg_req_by     sys_message.desc_message%TYPE;
        l_msg_req_to     sys_message.desc_message%TYPE;
        l_msg_rea_rea    sys_message.desc_message%TYPE;
        l_msg_notes      sys_message.desc_message%TYPE;
        l_msg_canc_reas  sys_message.desc_message%TYPE;
        l_msg_canc_nt    sys_message.desc_message%TYPE;
        l_msg_acc_by     sys_message.desc_message%TYPE;
        l_msg_acc_on     sys_message.desc_message%TYPE;
        l_msg_rej_by     sys_message.desc_message%TYPE;
        l_msg_rej_on     sys_message.desc_message%TYPE;
        l_msg_over_by    sys_message.desc_message%TYPE;
        l_msg_over_on    sys_message.desc_message%TYPE;
        l_label_any_prof sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021');
    BEGIN
        l_msg_req       := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T026');
        l_msg_canc      := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T022');
        l_msg_acc       := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T076');
        l_msg_rej       := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T077');
        l_msg_over      := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T110');
        l_msg_reqd      := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T027') || ' </b>';
        l_msg_req_by    := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T028') || ' </b>';
        l_msg_req_to    := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T029') || ' </b>';
        l_msg_rea_rea   := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T073') || ' </b>';
        l_msg_notes     := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T013') || ' </b>';
        l_msg_canc_reas := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T023') || ' </b>';
        l_msg_canc_nt   := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T024') || ' </b>';
        l_msg_acc_by    := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T078') || ' </b>';
        l_msg_acc_on    := '<b>' || l_msg_acc || ' </b>';
        l_msg_rej_by    := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T079') || ' </b>';
        l_msg_rej_on    := '<b>' || l_msg_rej || ' </b>';
    
        l_msg_over_by := '<b>' || pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T111') || ' </b>';
        l_msg_over_on := '<b>' || l_msg_over || ' </b>';
    
        l_message := 'OPEN o_hist';
        OPEN o_hist FOR
            SELECT l_msg_canc operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_cancel_tstz, i_prof) reg_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, o.id_prof_questions, o.dt_cancel_tstz, NULL) desc_speciality,
                   l_msg_canc_reas ||
                   decode(id_cancel_reason, NULL, l_na, pk_translation.get_translation(i_lang, cr.code_cancel_reason)) || l_br ||
                   l_msg_canc_nt || nvl(o.notes_cancel, l_na) history,
                   pk_date_utils.to_char_insttimezone(i_prof, o.dt_cancel_tstz, 'YYYYMMDDHH24MISS') date_opinion
              FROM opinion o
              LEFT JOIN cancel_reason cr
             USING (id_cancel_reason)
             WHERE o.id_opinion = i_opinion
               AND o.flg_state = g_opinion_cancel
            UNION ALL
            SELECT decode(o.flg_state,
                          g_opinion_accepted,
                          l_msg_acc,
                          g_opinion_rejected,
                          l_msg_rej,
                          g_opinion_over,
                          l_msg_over) operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, op.dt_opinion_prof_tstz, i_prof) reg_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, op.id_professional, op.dt_opinion_prof_tstz, NULL) desc_speciality,
                   decode(o.flg_state,
                          g_opinion_accepted,
                          l_msg_acc_by,
                          g_opinion_rejected,
                          l_msg_rej_by,
                          g_opinion_over,
                          l_msg_over_by) || pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional) || l_br ||
                   decode(o.flg_state,
                          g_opinion_accepted,
                          l_msg_acc_on,
                          g_opinion_rejected,
                          l_msg_rej_on,
                          g_opinion_over,
                          l_msg_over_on) || pk_date_utils.dt_chr_tsz(i_lang, o.dt_problem_tstz, i_prof) || l_br ||
                   l_msg_notes || nvl(op.desc_reply, l_na) history,
                   pk_date_utils.to_char_insttimezone(i_prof, op.dt_opinion_prof_tstz, 'YYYYMMDDHH24MISS') date_opinion
              FROM opinion o
              JOIN opinion_prof op
             USING (id_opinion)
             WHERE id_opinion = i_opinion
               AND op.flg_type <> g_opin_prof_a
            UNION ALL
            SELECT l_msg_req operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) reg_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, o.id_prof_questions, o.dt_problem_tstz, NULL) desc_speciality,
                   l_msg_req_by || pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) || l_br ||
                   l_msg_req_to || nvl2(o.id_prof_questioned,
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                                        l_label_any_prof) || l_br || l_msg_reqd ||
                   pk_date_utils.dt_chr_tsz(i_lang, o.dt_problem_tstz, i_prof) || l_br || l_msg_rea_rea ||
                   get_cm_req_reason(i_lang, i_prof, o.id_opinion) || l_br || l_msg_notes || nvl(o.desc_problem, l_na) history,
                   pk_date_utils.to_char_insttimezone(i_prof, o.dt_problem_tstz, 'YYYYMMDDHH24MISS') date_opinion
              FROM opinion o
             WHERE o.id_opinion = i_opinion;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CM_REQ_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_cm_req_hist;

    /*******************************************************************************************
    * Create a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_episode          episode identifier
    * @param i_patient          patient identifier
    * @param i_diag             list of associated reasons
    * @param i_cm_prof          case manager identifier
    * @param i_notes            request notes
    * @param o_opinion          create opinion identifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.6
    * @since                    2009/08/19
    ********************************************************************************************/
    FUNCTION create_cm_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN opinion.id_episode%TYPE,
        i_patient IN opinion.id_patient%TYPE,
        i_diag    IN table_number,
        i_cm_prof IN opinion.id_prof_questions%TYPE,
        i_notes   IN opinion.desc_problem%TYPE,
        o_opinion OUT opinion.id_opinion%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN create_opinion(i_lang             => i_lang,
                              i_episode          => i_episode,
                              i_prof_questions   => i_prof,
                              i_prof_questioned  => i_cm_prof,
                              i_speciality       => NULL,
                              i_clinical_service => NULL,
                              i_desc             => i_notes,
                              i_prof_cat_type    => NULL,
                              i_commit_data      => pk_alert_constant.g_yes,
                              i_diag             => i_diag,
                              i_patient          => i_patient,
                              i_flg_type         => g_flg_type_case_manager,
                              o_opinion          => o_opinion,
                              o_error            => o_error);
    END create_cm_req;

    /*******************************************************************************************
    * Cancel a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_cancel_reason    cancel reason identifier
    * @param i_notes            request notes
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.6
    * @since                    2009/08/31
    ********************************************************************************************/
    FUNCTION cancel_cm_req
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE,
        i_notes         IN opinion.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN cancel_opinion(i_lang          => i_lang,
                              i_opinion       => i_opinion,
                              i_prof          => i_prof,
                              i_notes         => i_notes,
                              i_cancel_reason => i_cancel_reason,
                              i_commit_data   => pk_alert_constant.g_yes,
                              i_flg_type      => g_flg_type_case_manager,
                              o_error         => o_error);
    END cancel_cm_req;

    /**********************************************************************************************
    * Retrieves required data for the case management request's answer.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_opinion               opinion identifier
    * @param o_request               cursor (request data)
    * @param o_refuse_list           cursor (refuse list)
    * @param o_level_list            cursor (urgency levels list)
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.0.1
    * @since                         09-10-2010
    **********************************************************************************************/
    FUNCTION get_req_answer
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_opinion    IN opinion.id_opinion%TYPE,
        o_request    OUT pk_types.cursor_type,
        o_level_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_br CONSTANT VARCHAR2(4) := '<br>';
        l_na CONSTANT VARCHAR2(2) := '; ';
        l_msg_req      sys_message.desc_message%TYPE;
        l_msg_reas     sys_message.desc_message%TYPE;
        l_msg_prof     sys_message.desc_message%TYPE;
        l_msg_prof_any sys_message.desc_message%TYPE;
        l_msg_notes    sys_message.desc_message%TYPE;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[i_opinion:' || i_opinion || ' ]', g_package_name, 'GET_REQ_ANSWER');
        l_msg_req      := '<i>' || pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T022');
        l_msg_reas     := '<b>' || pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T003') || ': </b>';
        l_msg_prof     := '<b>' || pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T020') || ' </b>';
        l_msg_prof_any := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021');
        l_msg_notes    := '<b>' || pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T016') || ' </b>';
        -- l_dmn_req    := pk_sysdomain.get_domain(g_domain_opn_flg_state, g_opn_flg_state_r, i_lang);
    
        g_error := 'OPEN o_request';
        OPEN o_request FOR
            SELECT decode(o.desc_problem, NULL, NULL, l_msg_reas || o.desc_problem || l_br) || l_msg_prof ||
                   decode(o.id_prof_questioned,
                          NULL,
                          l_msg_prof_any,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned)) || l_br ||
                   decode(to_char(o.notes), NULL, NULL, l_msg_notes || o.notes || l_br) || l_msg_req || ' ' ||
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) || l_na ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) || '</i>' request
              FROM opinion o
             WHERE o.id_opinion = i_opinion;
    
        g_error := 'OPEN o_level_list';
        OPEN o_level_list FOR
            SELECT ml.id_management_level, pk_translation.get_translation(i_lang, ml.code_management_level) level_desc
              FROM management_level ml
             WHERE ml.flg_available = pk_alert_constant.g_yes;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REQ_ANSWER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_request);
            pk_types.open_my_cursor(o_level_list);
            RETURN FALSE;
    END get_req_answer;

    /*
    * Get the consult requests list for a given episode.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient id
    * @param i_episode          episode id
    * @param i_show_cancelled   set 'Y' to show cancelled records 
    * @param o_consult_req      consult requests
    * @param o_error            error
    *   
    * @author                 Paulo Teixeira
    * @version                2.6.0.1
    * @since                  2010/04/08
    */
    FUNCTION get_consult_requests_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN opinion.id_patient%TYPE,
        i_episode        IN opinion.id_episode%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_consult_req    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_label_any_prof          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                          i_prof,
                                                                                          'CONSULT_REQUEST_T021');
        l_consult_req_prof_cancel sys_config.value%TYPE := pk_sysconfig.get_config('CANCEL_CONSULT_OTHER_PROF', i_prof);
    BEGIN
    
        -- returns the request grid
        g_error := 'OPEN o_consult_req';
        OPEN o_consult_req FOR
            SELECT o.id_opinion id_opinion,
                   2 id_task_type,
                   o.flg_state flg_status,
                   CASE
                        WHEN o.flg_state IN (g_opinion_req, g_opinion_approved, g_opinion_accepted) THEN
                         g_status_active
                        WHEN o.flg_state IN (g_opinion_not_approved, g_opinion_over) THEN
                         g_status_inactive
                        WHEN o.flg_state IN (g_opinion_cancel) THEN
                         g_status_cancel
                        WHEN o.flg_state IN (g_opinion_rejected) THEN
                         g_status_reject
                    END flg_filter,
                   decode(l_consult_req_prof_cancel,
                          'N',
                          decode(o.id_prof_questions,
                                 i_prof.id,
                                 decode(o.flg_state, g_opinion_req, pk_alert_constant.g_yes, pk_alert_constant.g_no),
                                 pk_alert_constant.g_no),
                          decode(o.flg_state, g_opinion_req, pk_alert_constant.g_yes, pk_alert_constant.g_no)) flg_cancel,
                   get_req_status_str(i_lang,
                                      i_prof,
                                      o.flg_state,
                                      o.dt_last_update,
                                      o.id_opinion_type,
                                      o.id_prof_questions,
                                      o.id_episode) desc_status,
                   ot.id_opinion_type request_type_id,
                   pk_translation.get_translation(i_lang, ot.code_opinion_type) request_type,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) spec_prof_request_type,
                   nvl2(o.id_prof_questioned,
                        pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                        l_label_any_prof) name_prof_request_type,
                   decode(o.id_opinion_type,
                          g_ot_case_manager,
                          get_cm_req_reason(i_lang, i_prof, o.id_opinion),
                          o.desc_problem) request_reason,
                   pk_translation.get_translation(i_lang, et.code_epis_type) || g_dash ||
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, o.id_prof_questions, NULL, o.id_episode) request_origin,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) name_prof_origin,
                   pk_date_utils.date_char_hour_tsz(i_lang, o.dt_problem_tstz, i_prof.institution, i_prof.software) hour_request,
                   pk_date_utils.dt_chr_tsz(i_lang, o.dt_problem_tstz, i_prof.institution, i_prof.software) date_request,
                   o.id_episode_answer id_epis_answer,
                   pk_translation.get_translation(i_lang, et.code_epis_type) desc_epis_type,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, o.id_prof_questions, NULL, o.id_episode) spec_prof_origin,
                   pk_date_utils.date_send_tsz(i_lang, o.dt_problem_tstz, i_prof) date_request_send,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) dt_hour_request_send
              FROM opinion o
              JOIN opinion_type ot
                ON ot.id_opinion_type = o.id_opinion_type
              JOIN episode e
                ON e.id_episode = o.id_episode
              JOIN epis_type et
                ON et.id_epis_type = e.id_epis_type
              LEFT OUTER JOIN clinical_service cs
                ON cs.id_clinical_service = o.id_clinical_service
             WHERE o.id_patient = i_patient
               AND e.id_institution = i_prof.institution
             ORDER BY decode(o.flg_state,
                             g_opinion_req,
                             1,
                             g_opinion_approved,
                             2,
                             g_opinion_accepted,
                             3,
                             g_opinion_over,
                             4,
                             g_opinion_rejected,
                             5,
                             g_opinion_not_approved,
                             6,
                             g_opinion_cancel,
                             7);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONSULT_REQUESTS_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_consult_req);
            RETURN FALSE;
    END get_consult_requests_list;

    /*
    * Get a consult requests record history.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient id
    * @param i_episode          episode id   
    * @param i_opinion          opinion id
    * @param o_consult_req      consult request first state
    * @param o_consult_req_hist consult request history
    * @param o_consult_req_approve consult approve history
    * @param o_consult_req_accept consult accept history
    * @param o_consult_req_comp consult request accompaniment
    * @param o_error            error
    *
    * @author                 Paulo Teixeira
    * @version                2.6.0.1
    * @since                  2010/04/08
    */
    FUNCTION get_consult_requests_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN opinion.id_patient%TYPE,
        i_episode             IN opinion.id_episode%TYPE,
        i_opinion             IN opinion.id_opinion%TYPE,
        o_consult_req         OUT pk_types.cursor_type,
        o_consult_req_hist    OUT table_table_varchar,
        o_consult_req_approve OUT pk_types.cursor_type,
        o_consult_req_accept  OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        consult_dif_table_rec   consult_dif_table;
        consult_record          consult_type;
        consult_record_previous consult_type;
        consult_record_first    consult_type;
        all_consult_req         pk_types.cursor_type;
    
        i             NUMBER := 0;
        first_rec     NUMBER := 0;
        l_counter     NUMBER := 0;
        l_flag_change NUMBER := 0;
    
        l_type_bold         VARCHAR2(1 CHAR) := 'B';
        l_type_red          VARCHAR2(1 CHAR) := 'R';
        l_type_italic       VARCHAR2(1 CHAR) := 'N';
        l_type_title        VARCHAR2(1 CHAR) := 'T';
        l_type_confidencial VARCHAR2(1 CHAR) := 'X';
    
        l_na                         sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'N/A');
        l_label_any_prof             sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T021');
        l_label_speciality           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T024');
        l_label_request_reason       sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T025');
        l_label_prof_questioned      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T026');
        l_label_notes                sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T027');
        l_label_registered           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T037');
        l_label_approved_date        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T029');
        l_label_approved_by          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T030');
        l_label_accepted_date        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T038');
        l_label_accepted_by          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T039');
        l_label_request              sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T023');
        l_label_approval             sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T028');
        l_label_rejected_date        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T040');
        l_label_rejected_by          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T041');
        l_label_speciality_hist      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T042');
        l_label_request_reason_hist  sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T043');
        l_label_prof_questioned_hist sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T044');
        l_label_notes_hist           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T045');
        l_label_accepted             sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T046');
        l_label_refused_date         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T047');
        l_label_refused_by           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T048');
        l_label_reject_motive        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T049');
        l_label_refuse_motive        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T050');
        l_label_refuse               sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T051');
        l_label_reject               sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T052');
        l_label_state                sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T057');
        l_label_notes_cancel         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T058');
        l_label_cancel_reason        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T059');
        l_label_state_hist           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                             i_prof,
                                                                                             'CONSULT_REQUEST_T060');
        l_xml                        xmltype;
        l_clob                       CLOB;
    BEGIN
    
        -- returns all opinion change history
        g_error := 'OPEN all_consult_req';
        OPEN all_consult_req FOR
            SELECT NULL request_title,
                   NULL opinion_type,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) speciality,
                   decode(oh.id_opinion_type,
                          g_ot_case_manager,
                          get_cm_req_reason_hist(i_lang, i_prof, oh.id_opinion_hist),
                          oh.desc_problem) request_reason,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, oh.id_prof_questioned) name_prof_questioned,
                   oh.notes notes,
                   (SELECT pk_sysdomain.get_domain(g_opinion_consults, oh.flg_state, i_lang)
                      FROM dual) state,
                   oh.notes_cancel notes_cancel,
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                   nvl2(oh.dt_last_update,
                        pk_date_utils.date_char_tsz(i_lang, oh.dt_last_update, i_prof.institution, i_prof.software) ||
                        g_semicolon || pk_prof_utils.get_name_signature(i_lang,
                                                                        i_prof,
                                                                        decode(oh.flg_state,
                                                                               g_status_cancel,
                                                                               oh.id_prof_created_hist,
                                                                               g_status_accepted,
                                                                               oh.id_prof_created_hist,
                                                                               g_status_declined,
                                                                               oh.id_prof_created_hist,
                                                                               g_status_approved,
                                                                               oh.id_prof_created_hist,
                                                                               g_status_completed,
                                                                               oh.id_prof_created_hist,
                                                                               oh.id_prof_questions)),
                        NULL) registered,
                   to_char(oh.dt_last_update, 'YYYYMMDDhh24miss') create_time
              FROM opinion_hist oh
              LEFT OUTER JOIN cancel_reason cr
                ON cr.id_cancel_reason = oh.id_cancel_reason
              LEFT OUTER JOIN clinical_service cs
                ON cs.id_clinical_service = oh.id_clinical_service
             WHERE oh.id_opinion = i_opinion
             ORDER BY oh.dt_last_update;
    
        -- find differences
        g_error := 'LOOP sel_problem';
        LOOP
            FETCH all_consult_req
                INTO consult_record;
            EXIT WHEN all_consult_req%NOTFOUND;
        
            IF first_rec = 0
            THEN
                consult_record_first.speciality           := consult_record.speciality;
                consult_record_first.request_reason       := consult_record.request_reason;
                consult_record_first.name_prof_questioned := consult_record.name_prof_questioned;
                consult_record_first.notes                := consult_record.notes;
                consult_record_first.state                := consult_record.state;
                consult_record_first.notes_cancel         := consult_record.notes_cancel;
                consult_record_first.cancel_reason        := consult_record.cancel_reason;
                consult_record_first.registered           := consult_record.registered;
                consult_record_first.create_time          := consult_record.create_time;
                first_rec                                 := 1;
                i                                         := i + 1;
            ELSE
                l_flag_change := 0;
                IF (consult_record_previous.speciality <> consult_record.speciality)
                   OR (consult_record_previous.speciality IS NOT NULL AND consult_record.speciality IS NULL)
                   OR (consult_record_previous.speciality IS NULL AND consult_record.speciality IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).speciality_b := consult_record_previous.speciality;
                    consult_dif_table_rec(i).speciality_a := consult_record.speciality;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.request_reason <> consult_record.request_reason)
                   OR (consult_record_previous.request_reason IS NOT NULL AND consult_record.request_reason IS NULL)
                   OR (consult_record_previous.request_reason IS NULL AND consult_record.request_reason IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).request_reason_b := consult_record_previous.request_reason;
                    consult_dif_table_rec(i).request_reason_a := consult_record.request_reason;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.name_prof_questioned <> consult_record.name_prof_questioned)
                   OR (consult_record_previous.name_prof_questioned IS NOT NULL AND
                   consult_record.name_prof_questioned IS NULL)
                   OR (consult_record_previous.name_prof_questioned IS NULL AND
                   consult_record.name_prof_questioned IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).name_prof_questioned_b := consult_record_previous.name_prof_questioned;
                    consult_dif_table_rec(i).name_prof_questioned_a := consult_record.name_prof_questioned;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.notes <> consult_record.notes)
                   OR (consult_record_previous.notes IS NOT NULL AND consult_record.notes IS NULL)
                   OR (consult_record_previous.notes IS NULL AND consult_record.notes IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).notes_b := consult_record_previous.notes;
                    consult_dif_table_rec(i).notes_a := consult_record.notes;
                    l_flag_change := 1;
                END IF;
            
                IF (consult_record_previous.state <> consult_record.state)
                   OR (consult_record_previous.state IS NOT NULL AND consult_record.state IS NULL)
                   OR (consult_record_previous.state IS NULL AND consult_record.state IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).state_b := consult_record_previous.state;
                    consult_dif_table_rec(i).state_a := consult_record.state;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.notes_cancel <> consult_record.notes_cancel)
                   OR (consult_record_previous.notes_cancel IS NOT NULL AND consult_record.notes_cancel IS NULL)
                   OR (consult_record_previous.notes_cancel IS NULL AND consult_record.notes_cancel IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).notes_cancel_b := consult_record_previous.notes_cancel;
                    consult_dif_table_rec(i).notes_cancel_a := consult_record.notes_cancel;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.cancel_reason <> consult_record.cancel_reason)
                   OR (consult_record_previous.cancel_reason IS NOT NULL AND consult_record.cancel_reason IS NULL)
                   OR (consult_record_previous.cancel_reason IS NULL AND consult_record.cancel_reason IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).cancel_reason_b := consult_record_previous.cancel_reason;
                    consult_dif_table_rec(i).cancel_reason_a := consult_record.cancel_reason;
                    l_flag_change := 1;
                END IF;
            
                IF l_flag_change = 1
                THEN
                    consult_dif_table_rec(i).registered_b := consult_record_previous.registered;
                    consult_dif_table_rec(i).registered_a := consult_record.registered;
                    consult_dif_table_rec(i).create_time := consult_record.create_time;
                    i := i + 1;
                END IF;
            END IF;
            consult_record_previous.speciality           := consult_record.speciality;
            consult_record_previous.request_reason       := consult_record.request_reason;
            consult_record_previous.name_prof_questioned := consult_record.name_prof_questioned;
            consult_record_previous.notes                := consult_record.notes;
            consult_record_previous.state                := consult_record.state;
            consult_record_previous.notes_cancel         := consult_record.notes_cancel;
            consult_record_previous.cancel_reason        := consult_record.cancel_reason;
            consult_record_previous.registered           := consult_record.registered;
            consult_record_previous.create_time          := consult_record.create_time;
        
        END LOOP;
        CLOSE all_consult_req;
    
        g_error := 'Construct XML';
        SELECT xmlagg(xmlelement("xml",
                                 xmlforest(l_type_bold AS type_bold,
                                           l_label_notes AS label_notes,
                                           nvl(consult_record_first.notes, g_dashes) AS notes)))
          INTO l_xml
          FROM dual;
    
        SELECT l_xml.getclobval
          INTO l_clob
          FROM dual;
    
        -- build first history record = creation record    
        g_error := 'OPEN o_consult_req';
        OPEN o_consult_req FOR
            SELECT table_varchar(l_type_title, l_label_request, NULL) request_title,
                   table_varchar(l_type_bold, l_label_speciality, nvl(consult_record_first.speciality, g_dashes)) speciality,
                   table_varchar(l_type_bold,
                                 l_label_request_reason,
                                 nvl(consult_record_first.request_reason, g_dashes)) request_reason,
                   table_varchar(l_type_bold,
                                 l_label_prof_questioned,
                                 nvl(consult_record_first.name_prof_questioned, l_label_any_prof)) name_prof_questioned,
                   l_clob notes,
                   table_varchar(l_type_bold, l_label_state, nvl(consult_record_first.state, g_dashes)) state,
                   table_varchar(l_type_bold, l_label_notes_cancel, consult_record_first.notes_cancel) notes_cancel,
                   table_varchar(l_type_bold, l_label_cancel_reason, consult_record_first.cancel_reason) cancel_reason,
                   table_varchar(l_type_italic, l_label_registered, nvl(consult_record_first.registered, g_dashes)) registered
              FROM dual;
    
        -- build approve record
        g_error := 'open o_consult_req_approve';
        OPEN o_consult_req_approve FOR
            SELECT CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_title, nvl2(op_approve.dt_opinion_prof_tstz, l_label_approval, NULL), NULL)
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_title, nvl2(op_refuse.dt_opinion_prof_tstz, l_label_refuse, NULL), NULL)
                    END approved_title,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_bold,
                                       l_label_approved_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_approve.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold,
                                       l_label_refused_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_refuse.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                    END approved_date,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_bold,
                                       l_label_approved_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_approve.id_professional))
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold,
                                       l_label_refused_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_refuse.id_professional))
                    END approved_by,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(NULL)
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold, l_label_notes, nvl(op_refuse.desc_reply, g_dashes))
                    END refuse_notes,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(NULL)
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold,
                                       l_label_refuse_motive,
                                       pk_translation.get_translation(i_lang, cr_refuse.code_cancel_reason))
                    END refuse_motive,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_approve.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_approve.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || g_semicolon ||
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_approve.id_professional),
                                            NULL))
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_refuse.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_refuse.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || g_semicolon ||
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_refuse.id_professional),
                                            NULL))
                    END approved_registered
            
              FROM opinion o
              LEFT OUTER JOIN opinion_prof op_approve
                ON (op_approve.id_opinion = o.id_opinion AND op_approve.flg_type = g_opinion_prof_approve)
              LEFT OUTER JOIN opinion_prof op_refuse
                ON (op_refuse.id_opinion = o.id_opinion AND op_refuse.flg_type = g_opinion_prof_refuse)
            
              LEFT OUTER JOIN cancel_reason cr_refuse
                ON cr_refuse.id_cancel_reason = op_refuse.id_cancel_reason
             WHERE o.id_opinion = i_opinion;
    
        -- build accepted record
        g_error := 'open o_consult_req_accept';
        OPEN o_consult_req_accept FOR
            SELECT CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_title, nvl2(op_accept.dt_opinion_prof_tstz, l_label_accepted, NULL), NULL)
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_title, nvl2(op_reject.dt_opinion_prof_tstz, l_label_reject, NULL), NULL)
                    END accepted_title,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_bold,
                                       l_label_accepted_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_accept.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold,
                                       l_label_rejected_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_reject.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                    END accepted_date,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_bold,
                                       l_label_accepted_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold,
                                       l_label_rejected_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_reject.id_professional))
                    END accepted_by,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_bold, l_label_notes, nvl(op_accept.desc_reply, g_dashes))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold, l_label_notes, nvl(op_reject.desc_reply, g_dashes))
                    END reject_notes,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(NULL)
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold,
                                       l_label_reject_motive,
                                       pk_translation.get_translation(i_lang, cr_reject.code_cancel_reason))
                    END reject_motive,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_accept.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_accept.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || g_semicolon ||
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional),
                                            NULL))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_reject.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_reject.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || g_semicolon ||
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_reject.id_professional),
                                            NULL))
                    END accepted_registered
            
              FROM opinion o
              LEFT OUTER JOIN opinion_prof op_accept
                ON (op_accept.id_opinion = o.id_opinion AND op_accept.flg_type = g_opinion_prof_accept)
              LEFT OUTER JOIN opinion_prof op_reject
                ON (op_reject.id_opinion = o.id_opinion AND op_reject.flg_type = g_opinion_prof_reject)
              LEFT OUTER JOIN cancel_reason cr_reject
                ON cr_reject.id_cancel_reason = op_reject.id_cancel_reason
             WHERE o.id_opinion = i_opinion;
    
        -- build before / after request history information     
        g_error := 'build o_consult_req_hist';
        IF consult_dif_table_rec.count <> 0
        THEN
            o_consult_req_hist := table_table_varchar(table_varchar(NULL));
        END IF;
        FOR k IN 1 .. consult_dif_table_rec.count
        LOOP
            IF consult_dif_table_rec(k).speciality_b IS NOT NULL
                OR consult_dif_table_rec(k).speciality_a IS NOT NULL
            THEN
                l_counter := o_consult_req_hist.count;
                o_consult_req_hist.extend(2);
                o_consult_req_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                                   l_label_speciality,
                                                                   nvl(consult_dif_table_rec(k).speciality_b, l_na));
                o_consult_req_hist(l_counter + 2) := table_varchar(l_type_red,
                                                                   l_label_speciality_hist,
                                                                   nvl(consult_dif_table_rec(k).speciality_a, l_na));
            
            END IF;
            IF consult_dif_table_rec(k).request_reason_b IS NOT NULL
                OR consult_dif_table_rec(k).request_reason_a IS NOT NULL
            THEN
                l_counter := o_consult_req_hist.count;
                o_consult_req_hist.extend(2);
                o_consult_req_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                                   l_label_request_reason,
                                                                   nvl(consult_dif_table_rec(k).request_reason_b, l_na));
                o_consult_req_hist(l_counter + 2) := table_varchar(l_type_red,
                                                                   l_label_request_reason_hist,
                                                                   nvl(consult_dif_table_rec(k).request_reason_a, l_na));
            
            END IF;
            IF consult_dif_table_rec(k).name_prof_questioned_b IS NOT NULL
                OR consult_dif_table_rec(k).name_prof_questioned_a IS NOT NULL
            THEN
                l_counter := o_consult_req_hist.count;
                o_consult_req_hist.extend(2);
                o_consult_req_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                                   l_label_prof_questioned,
                                                                   nvl(consult_dif_table_rec(k).name_prof_questioned_b,
                                                                       l_label_any_prof));
                o_consult_req_hist(l_counter + 2) := table_varchar(l_type_red,
                                                                   l_label_prof_questioned_hist,
                                                                   nvl(consult_dif_table_rec(k).name_prof_questioned_a,
                                                                       l_label_any_prof));
            
            END IF;
            IF consult_dif_table_rec(k).notes_b IS NOT NULL
                OR consult_dif_table_rec(k).notes_a IS NOT NULL
            THEN
                l_counter := o_consult_req_hist.count;
                o_consult_req_hist.extend(2);
                o_consult_req_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                                   l_label_notes,
                                                                   nvl(consult_dif_table_rec(k).notes_b, l_na));
                o_consult_req_hist(l_counter + 2) := table_varchar(l_type_red,
                                                                   l_label_notes_hist,
                                                                   nvl(consult_dif_table_rec(k).notes_a, l_na));
            
            END IF;
        
            IF consult_dif_table_rec(k).state_b IS NOT NULL
                OR consult_dif_table_rec(k).state_a IS NOT NULL
            THEN
                l_counter := o_consult_req_hist.count;
                o_consult_req_hist.extend(2);
                o_consult_req_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                                   l_label_state,
                                                                   nvl(consult_dif_table_rec(k).state_b, l_na));
                o_consult_req_hist(l_counter + 2) := table_varchar(l_type_red,
                                                                   l_label_state_hist,
                                                                   nvl(consult_dif_table_rec(k).state_a, l_na));
            
            END IF;
            IF consult_dif_table_rec(k).notes_cancel_b IS NOT NULL
                OR consult_dif_table_rec(k).notes_cancel_a IS NOT NULL
            THEN
                l_counter := o_consult_req_hist.count;
                o_consult_req_hist.extend(1);
                o_consult_req_hist(l_counter + 1) := table_varchar(l_type_red,
                                                                   l_label_notes_cancel,
                                                                   nvl(consult_dif_table_rec(k).notes_cancel_a, l_na));
            
            END IF;
            IF consult_dif_table_rec(k).cancel_reason_b IS NOT NULL
                OR consult_dif_table_rec(k).cancel_reason_a IS NOT NULL
            THEN
                l_counter := o_consult_req_hist.count;
                o_consult_req_hist.extend(1);
                o_consult_req_hist(l_counter + 1) := table_varchar(l_type_red,
                                                                   l_label_cancel_reason,
                                                                   nvl(consult_dif_table_rec(k).cancel_reason_a, l_na));
            
            END IF;
        
            l_counter := o_consult_req_hist.count;
            o_consult_req_hist.extend(1);
            o_consult_req_hist(l_counter + 1) := table_varchar(l_type_italic,
                                                               l_label_registered,
                                                               consult_dif_table_rec(k).registered_a,
                                                               consult_dif_table_rec(k).create_time);
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
                                              'GET_CONSULT_REQUESTS_HIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_consult_req);
            pk_types.open_my_cursor(o_consult_req_approve);
            pk_types.open_my_cursor(o_consult_req_accept);
            RETURN FALSE;
        
    END get_consult_requests_hist;

    /*
    * Get a consult requests record history.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient id
    * @param i_episode          episode id   
    * @param i_opinion          opinion id
    * @param o_consult_req      consult request current state
    * @param o_consult_req_comp consult request accompaniment
    * @param o_error            error
    *
    * @author                 Paulo Teixeira
    * @version                2.6.0.1
    * @since                  2010/04/08
    */
    FUNCTION get_consult_requests_general
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN opinion.id_patient%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        o_consult_req      OUT pk_types.cursor_type,
        o_consult_req_comp OUT table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_type_bold             VARCHAR2(1 CHAR) := 'B';
        l_type_red              VARCHAR2(1 CHAR) := 'R';
        l_type_italic           VARCHAR2(1 CHAR) := 'N';
        l_type_title            VARCHAR2(1 CHAR) := 'T';
        l_type_confidencial     VARCHAR2(1 CHAR) := 'X';
        l_label_any_prof        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T021');
        l_label_speciality      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T024');
        l_label_request_reason  sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T025');
        l_label_prof_questioned sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T026');
        l_label_notes           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T027');
        l_label_registered      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T037');
        l_label_approved_date   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T029');
        l_label_approved_by     sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T030');
        l_label_accepted_date   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T038');
        l_label_accepted_by     sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T039');
        l_label_request         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T023');
        l_label_approval        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T028');
        l_label_rejected_date   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T040');
        l_label_rejected_by     sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T041');
        l_label_accepted        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T046');
        l_label_refused_date    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T047');
        l_label_refused_by      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T048');
        l_label_reject_motive   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T049');
        l_label_refuse_motive   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T050');
        l_label_refuse          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T051');
        l_label_reject          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T052');
        l_label_state           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T057');
        l_label_notes_cancel    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T058');
        l_label_cancel_reason   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        
                                                                                        'CONSULT_REQUEST_T059');
        l_label_updated         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        
                                                                                        'CONSULT_REQUEST_T061');
    
        l_xml  xmltype;
        l_clob CLOB;
    
    BEGIN
    
        g_error := 'Construct XML';
        SELECT xmlagg(xmlelement("xml",
                                 xmlforest(l_type_bold AS type_bold,
                                           l_label_notes AS label_notes,
                                           nvl(o.notes, g_dashes) AS notes)))
          INTO l_xml
          FROM opinion o
          LEFT OUTER JOIN cancel_reason cr
            ON cr.id_cancel_reason = o.id_cancel_reason
          LEFT OUTER JOIN clinical_service cs
            ON cs.id_clinical_service = o.id_clinical_service
          LEFT OUTER JOIN opinion_prof op_accept
            ON (op_accept.id_opinion = o.id_opinion AND op_accept.flg_type = g_opinion_prof_accept)
          LEFT OUTER JOIN opinion_prof op_reject
            ON (op_reject.id_opinion = o.id_opinion AND op_reject.flg_type = g_opinion_prof_reject)
          LEFT OUTER JOIN opinion_prof op_approve
            ON (op_approve.id_opinion = o.id_opinion AND op_approve.flg_type = g_opinion_prof_approve)
          LEFT OUTER JOIN opinion_prof op_refuse
            ON (op_refuse.id_opinion = o.id_opinion AND op_refuse.flg_type = g_opinion_prof_refuse)
          LEFT OUTER JOIN cancel_reason cr_reject
            ON cr_reject.id_cancel_reason = op_reject.id_cancel_reason
          LEFT OUTER JOIN cancel_reason cr_refuse
            ON cr_refuse.id_cancel_reason = op_refuse.id_cancel_reason
         WHERE o.id_opinion = i_opinion;
    
        SELECT l_xml.getclobval
          INTO l_clob
          FROM dual;
    
        g_error := 'OPEN o_consult_req_list';
        OPEN o_consult_req FOR
            SELECT table_varchar(l_type_title, l_label_request, NULL) request_title,
                   table_varchar(l_type_bold,
                                 l_label_speciality,
                                 nvl(pk_translation.get_translation(i_lang, cs.code_clinical_service), g_dashes)) speciality,
                   
                   table_varchar(l_type_bold,
                                 l_label_request_reason,
                                 nvl(decode(o.id_opinion_type,
                                            g_ot_case_manager,
                                            get_cm_req_reason(i_lang, i_prof, o.id_opinion),
                                            o.desc_problem),
                                     g_dashes)) request_reason,
                   
                   table_varchar(l_type_bold,
                                 l_label_prof_questioned,
                                 nvl2(o.id_prof_questioned,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                                      l_label_any_prof)) name_prof_questioned,
                   
                   l_clob notes,
                   table_varchar(l_type_bold,
                                 l_label_state,
                                 nvl(pk_sysdomain.get_domain(g_opinion_consults, o.flg_state, i_lang), g_dashes)) state,
                   
                   table_varchar(l_type_bold, l_label_notes_cancel, o.notes_cancel) notes_cancel,
                   
                   table_varchar(l_type_bold,
                                 l_label_cancel_reason,
                                 pk_translation.get_translation(i_lang, cr.code_cancel_reason)) cancel_reason,
                   table_varchar(l_type_italic,
                                 decode(o.flg_state,
                                        g_status_cancel,
                                        l_label_updated,
                                        g_status_accepted,
                                        l_label_updated,
                                        g_status_declined,
                                        l_label_updated,
                                        g_status_approved,
                                        l_label_updated,
                                        g_status_completed,
                                        l_label_updated,
                                        l_label_registered),
                                 nvl2(o.dt_last_update,
                                      pk_date_utils.date_char_tsz(i_lang,
                                                                  o.dt_last_update,
                                                                  i_prof.institution,
                                                                  i_prof.software) || g_semicolon ||
                                      pk_prof_utils.get_name_signature(i_lang,
                                                                       i_prof,
                                                                       decode(o.flg_state,
                                                                              g_status_cancel,
                                                                              o.id_prof_cancel,
                                                                              g_status_accepted,
                                                                              get_prof_last_update(i_lang       => i_lang,
                                                                                                   i_prof       => i_prof,
                                                                                                   i_id_opinion => o.id_opinion),
                                                                              g_status_declined,
                                                                              get_prof_last_update(i_lang       => i_lang,
                                                                                                   i_prof       => i_prof,
                                                                                                   i_id_opinion => o.id_opinion),
                                                                              g_status_approved,
                                                                              get_prof_last_update(i_lang       => i_lang,
                                                                                                   i_prof       => i_prof,
                                                                                                   i_id_opinion => o.id_opinion),
                                                                              g_status_completed,
                                                                              get_prof_last_update(i_lang       => i_lang,
                                                                                                   i_prof       => i_prof,
                                                                                                   i_id_opinion => o.id_opinion),
                                                                              o.id_prof_questions)),
                                      NULL)) request_registered,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_title, nvl2(op_approve.dt_opinion_prof_tstz, l_label_approval, NULL), NULL)
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_title, nvl2(op_refuse.dt_opinion_prof_tstz, l_label_refuse, NULL), NULL)
                    END approved_title,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_bold,
                                       l_label_approved_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_approve.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold,
                                       l_label_refused_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_refuse.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                    END approved_date,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_bold,
                                       l_label_approved_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_approve.id_professional))
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold,
                                       l_label_refused_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_refuse.id_professional))
                    END approved_by,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(NULL)
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold, l_label_notes, nvl(op_refuse.desc_reply, g_dashes))
                    END refuse_notes,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(NULL)
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold,
                                       l_label_refuse_motive,
                                       pk_translation.get_translation(i_lang, cr_refuse.code_cancel_reason))
                    END refuse_motive,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_approve.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_approve.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || g_semicolon ||
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_approve.id_professional),
                                            NULL))
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_refuse.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_refuse.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || g_semicolon ||
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_refuse.id_professional),
                                            NULL))
                    END approved_registered,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_title, nvl2(op_accept.dt_opinion_prof_tstz, l_label_accepted, NULL), NULL)
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_title, nvl2(op_reject.dt_opinion_prof_tstz, l_label_reject, NULL), NULL)
                    END accepted_title,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_bold,
                                       l_label_accepted_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_accept.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold,
                                       l_label_rejected_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_reject.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                    END accepted_date,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_bold,
                                       l_label_accepted_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold,
                                       l_label_rejected_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_reject.id_professional))
                    END accepted_by,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_bold, l_label_notes, nvl(op_accept.desc_reply, g_dashes))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold, l_label_notes, nvl(op_reject.desc_reply, g_dashes))
                    END reject_notes,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(NULL)
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold,
                                       l_label_reject_motive,
                                       pk_translation.get_translation(i_lang, cr_reject.code_cancel_reason))
                    END reject_motive,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_accept.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_accept.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || g_semicolon ||
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional),
                                            NULL))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_reject.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_reject.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software) || g_semicolon ||
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_reject.id_professional),
                                            NULL))
                    END accepted_registered
              FROM opinion o
              LEFT OUTER JOIN cancel_reason cr
                ON cr.id_cancel_reason = o.id_cancel_reason
              LEFT OUTER JOIN clinical_service cs
                ON cs.id_clinical_service = o.id_clinical_service
              LEFT OUTER JOIN opinion_prof op_accept
                ON (op_accept.id_opinion = o.id_opinion AND op_accept.flg_type = g_opinion_prof_accept)
              LEFT OUTER JOIN opinion_prof op_reject
                ON (op_reject.id_opinion = o.id_opinion AND op_reject.flg_type = g_opinion_prof_reject)
              LEFT OUTER JOIN opinion_prof op_approve
                ON (op_approve.id_opinion = o.id_opinion AND op_approve.flg_type = g_opinion_prof_approve)
              LEFT OUTER JOIN opinion_prof op_refuse
                ON (op_refuse.id_opinion = o.id_opinion AND op_refuse.flg_type = g_opinion_prof_refuse)
              LEFT OUTER JOIN cancel_reason cr_reject
                ON cr_reject.id_cancel_reason = op_reject.id_cancel_reason
              LEFT OUTER JOIN cancel_reason cr_refuse
                ON cr_refuse.id_cancel_reason = op_refuse.id_cancel_reason
             WHERE o.id_opinion = i_opinion;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONSULT_REQUESTS_GENERAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_consult_req);
            RETURN FALSE;
        
    END get_consult_requests_general;

    FUNCTION get_cons_req_general_report
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN opinion.id_patient%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        o_consult_req      OUT pk_types.cursor_type,
        o_consult_req_comp OUT table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_type_bold             VARCHAR2(1 CHAR) := 'B';
        l_type_red              VARCHAR2(1 CHAR) := 'R';
        l_type_italic           VARCHAR2(1 CHAR) := 'N';
        l_type_title            VARCHAR2(1 CHAR) := 'T';
        l_type_confidencial     VARCHAR2(1 CHAR) := 'X';
        l_label_any_prof        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T021');
        l_label_speciality      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T024');
        l_label_request_reason  sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T025');
        l_label_prof_questioned sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T026');
        l_label_notes           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T027');
        l_label_registered      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T037');
        l_label_approved_date   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T029');
        l_label_approved_by     sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T030');
        l_label_accepted_date   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T038');
        l_label_accepted_by     sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T039');
        l_label_request         sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T023');
        l_label_approval        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T028');
        l_label_rejected_date   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T040');
        l_label_rejected_by     sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T041');
        l_label_accepted        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T046');
        l_label_refused_date    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T047');
        l_label_refused_by      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T048');
        l_label_reject_motive   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T049');
        l_label_refuse_motive   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T050');
        l_label_refuse          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T051');
        l_label_reject          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T052');
        l_label_state           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T057');
        l_label_notes_cancel    sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T058');
        l_label_cancel_reason   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'CONSULT_REQUEST_T059');
    
    BEGIN
        g_error := 'OPEN o_consult_req_list';
        OPEN o_consult_req FOR
            SELECT table_varchar(l_type_title, l_label_request, NULL) request_title,
                   
                   table_varchar(l_type_bold,
                                 l_label_prof_questioned,
                                 nvl2(o.id_prof_questioned,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                                      l_label_any_prof)) name_prof_questioned,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_title, nvl2(op_approve.dt_opinion_prof_tstz, l_label_approval, NULL), NULL)
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_title, nvl2(op_refuse.dt_opinion_prof_tstz, l_label_refuse, NULL), NULL)
                    END approved_title,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_bold,
                                       l_label_approved_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_approve.id_professional))
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold,
                                       l_label_refused_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_refuse.id_professional))
                    END approved_by,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(NULL)
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold,
                                       l_label_refuse_motive,
                                       pk_translation.get_translation(i_lang, cr_refuse.code_cancel_reason))
                    END refuse_motive,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_title, nvl2(op_accept.dt_opinion_prof_tstz, l_label_accepted, NULL), NULL)
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_title, nvl2(op_reject.dt_opinion_prof_tstz, l_label_reject, NULL), NULL)
                    END accepted_title,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_bold,
                                       l_label_accepted_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold,
                                       l_label_rejected_by,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, op_reject.id_professional))
                    END accepted_by,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(NULL)
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold,
                                       l_label_reject_motive,
                                       pk_translation.get_translation(i_lang, cr_reject.code_cancel_reason))
                    END reject_motive,
                   
                   --------------------------------------
                   table_varchar(l_type_bold,
                                 l_label_speciality,
                                 pk_translation.get_translation(i_lang, cs.code_clinical_service)) speciality_report,
                   
                   table_varchar(l_type_bold,
                                 l_label_request_reason,
                                 decode(o.id_opinion_type,
                                        g_ot_case_manager,
                                        get_cm_req_reason(i_lang, i_prof, o.id_opinion),
                                        o.desc_problem)) request_reason_report,
                   
                   table_clob(to_clob(l_type_bold), to_clob(l_label_notes), to_clob(o.notes), to_clob(g_dashes)) notes_report,
                   
                   table_varchar(l_type_bold,
                                 l_label_state,
                                 pk_sysdomain.get_domain(g_opinion_consults, o.flg_state, i_lang)) state_report,
                   
                   table_varchar(l_type_italic,
                                 l_label_registered,
                                 nvl2(o.dt_last_update,
                                      pk_date_utils.date_char_tsz(i_lang,
                                                                  o.dt_last_update,
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                      NULL),
                                 nvl2(o.dt_last_update,
                                      pk_date_utils.date_send_tsz(i_lang, o.dt_last_update, i_prof),
                                      NULL),
                                 nvl2(o.dt_last_update,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions),
                                      NULL)) request_registered_report,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_bold,
                                       l_label_approved_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_approve.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software),
                                       pk_date_utils.date_send_tsz(i_lang, op_approve.dt_opinion_prof_tstz, i_prof))
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_bold,
                                       l_label_refused_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_refuse.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software),
                                       pk_date_utils.date_send_tsz(i_lang, op_refuse.dt_opinion_prof_tstz, i_prof))
                    END approved_date_report,
                   
                   CASE
                        WHEN op_approve.flg_type = g_opinion_prof_approve THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_approve.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_approve.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software),
                                            NULL),
                                       nvl2(op_approve.dt_opinion_prof_tstz,
                                            pk_date_utils.date_send_tsz(i_lang, op_approve.dt_opinion_prof_tstz, i_prof),
                                            NULL),
                                       nvl2(op_approve.dt_opinion_prof_tstz,
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_approve.id_professional),
                                            NULL))
                        WHEN op_refuse.flg_type = g_opinion_prof_refuse THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_refuse.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_refuse.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software),
                                            NULL),
                                       nvl2(op_refuse.dt_opinion_prof_tstz,
                                            pk_date_utils.date_send_tsz(i_lang, op_refuse.dt_opinion_prof_tstz, i_prof),
                                            NULL),
                                       nvl2(op_refuse.dt_opinion_prof_tstz,
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_refuse.id_professional),
                                            NULL))
                    END approved_registered_report,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_bold,
                                       l_label_accepted_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_accept.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software),
                                       pk_date_utils.date_send_tsz(i_lang, op_accept.dt_opinion_prof_tstz, i_prof))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold,
                                       l_label_rejected_date,
                                       pk_date_utils.date_char_tsz(i_lang,
                                                                   op_reject.dt_opinion_prof_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software),
                                       pk_date_utils.date_send_tsz(i_lang, op_reject.dt_opinion_prof_tstz, i_prof))
                    END accepted_date_report,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_bold, l_label_notes, op_accept.desc_reply)
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_bold, l_label_notes, op_reject.desc_reply)
                    END reject_notes_report,
                   
                   CASE
                        WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_accept.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_accept.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software),
                                            NULL),
                                       nvl2(op_accept.dt_opinion_prof_tstz,
                                            pk_date_utils.date_send_tsz(i_lang, op_accept.dt_opinion_prof_tstz, i_prof),
                                            NULL),
                                       nvl2(op_accept.dt_opinion_prof_tstz,
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional),
                                            NULL))
                        WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                         table_varchar(l_type_italic,
                                       l_label_registered,
                                       nvl2(op_reject.dt_opinion_prof_tstz,
                                            pk_date_utils.date_char_tsz(i_lang,
                                                                        op_reject.dt_opinion_prof_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software),
                                            NULL),
                                       nvl2(op_reject.dt_opinion_prof_tstz,
                                            pk_date_utils.date_send_tsz(i_lang, op_reject.dt_opinion_prof_tstz, i_prof),
                                            NULL),
                                       nvl2(op_reject.dt_opinion_prof_tstz,
                                            pk_prof_utils.get_name_signature(i_lang, i_prof, op_reject.id_professional),
                                            NULL))
                    END accepted_registered_report
            
              FROM opinion o
              LEFT OUTER JOIN cancel_reason cr
                ON cr.id_cancel_reason = o.id_cancel_reason
              LEFT OUTER JOIN clinical_service cs
                ON cs.id_clinical_service = o.id_clinical_service
              LEFT OUTER JOIN opinion_prof op_accept
                ON (op_accept.id_opinion = o.id_opinion AND op_accept.flg_type = g_opinion_prof_accept)
              LEFT OUTER JOIN opinion_prof op_reject
                ON (op_reject.id_opinion = o.id_opinion AND op_reject.flg_type = g_opinion_prof_reject)
              LEFT OUTER JOIN opinion_prof op_approve
                ON (op_approve.id_opinion = o.id_opinion AND op_approve.flg_type = g_opinion_prof_approve)
              LEFT OUTER JOIN opinion_prof op_refuse
                ON (op_refuse.id_opinion = o.id_opinion AND op_refuse.flg_type = g_opinion_prof_refuse)
              LEFT OUTER JOIN cancel_reason cr_reject
                ON cr_reject.id_cancel_reason = op_reject.id_cancel_reason
              LEFT OUTER JOIN cancel_reason cr_refuse
                ON cr_refuse.id_cancel_reason = op_refuse.id_cancel_reason
             WHERE o.id_opinion = i_opinion;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONSULT_REQUESTS_GENERAL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_consult_req);
            RETURN FALSE;
        
    END get_cons_req_general_report;

    /*******************************************************************************************
    * Retrieves a case management request reasons, comma separated.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion_hist          opinion_hist identifier
    *
    * @return                   case management request reasons, comma separated
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/21
    ********************************************************************************************/
    FUNCTION get_cm_req_reason_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_hist IN opinion_hist.id_opinion_hist%TYPE
    ) RETURN VARCHAR2 IS
        l_comma CONSTANT VARCHAR2(2) := '; ';
        l_ret          VARCHAR2(4000);
        l_diagnosis    table_varchar := table_varchar();
        l_id_diagnosis table_number := table_number();
    
        CURSOR c_reason_hist IS
            SELECT d.id_diagnosis,
                   pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_desc_epis_diagnosis => opr.diagnosis_desc,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_flg_std_diag        => pk_alert_constant.g_yes) desc_diagnosis
              FROM diagnosis d
              JOIN opinion_reason_hist opr
                ON d.id_diagnosis = opr.id_diagnosis
             WHERE opr.id_opinion_hist = i_opinion_hist
             ORDER BY 2;
    
    BEGIN
    
        IF i_opinion_hist IS NOT NULL
        THEN
            g_error := 'OPEN c_reason_hist';
            OPEN c_reason_hist;
            FETCH c_reason_hist BULK COLLECT
                INTO l_id_diagnosis, l_diagnosis;
            CLOSE c_reason_hist;
        END IF;
    
        l_ret := NULL;
        FOR i IN 1 .. l_diagnosis.count
        LOOP
            IF i = 1
            THEN
                l_ret := l_diagnosis(i);
            ELSE
                l_ret := l_ret || l_comma || l_diagnosis(i);
            END IF;
        END LOOP;
    
        RETURN l_ret;
    END get_cm_req_reason_hist;

    /************************************************************************************************************
    * This function creates e opinion_hist record bases in the i_opinion passes as a parameter
    *
    * @param      i_lang           language identifier
    * @param      i_prof           logged professional structure
    * @param      i_opinion        Id opinion
    * @param      o_opinion_hist   created opinion history identifier
    *
    * @author     Pedro Teixeira
    * @version    2.6.0.1
    * @since      13-04-2010
    ************************************************************************************************************/
    PROCEDURE set_opinion_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion      IN opinion.id_opinion%TYPE,
        o_opinion_hist OUT opinion_hist.id_opinion_hist%TYPE
    ) IS
        l_error        t_error_out;
        l_rowids       table_varchar;
        l_opinion      opinion%ROWTYPE;
        l_opinion_hist opinion_hist%ROWTYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'SELECT INTO .. FROM OPINION';
        SELECT *
          INTO l_opinion
          FROM opinion o
         WHERE o.id_opinion = i_opinion;
    
        l_opinion_hist.id_opinion_hist      := ts_opinion_hist.next_key;
        l_opinion_hist.id_opinion           := l_opinion.id_opinion;
        l_opinion_hist.id_episode           := l_opinion.id_episode;
        l_opinion_hist.flg_state            := l_opinion.flg_state;
        l_opinion_hist.desc_problem         := l_opinion.desc_problem;
        l_opinion_hist.id_prof_questions    := l_opinion.id_prof_questions;
        l_opinion_hist.id_prof_questioned   := l_opinion.id_prof_questioned;
        l_opinion_hist.id_speciality        := l_opinion.id_speciality;
        l_opinion_hist.notes_cancel         := l_opinion.notes_cancel;
        l_opinion_hist.dt_problem_tstz      := l_opinion.dt_problem_tstz;
        l_opinion_hist.dt_cancel_tstz       := l_opinion.dt_cancel_tstz;
        l_opinion_hist.status_flg           := l_opinion.status_flg;
        l_opinion_hist.status_icon          := l_opinion.status_icon;
        l_opinion_hist.status_msg           := l_opinion.status_msg;
        l_opinion_hist.status_str           := l_opinion.status_str;
        l_opinion_hist.id_management_level  := l_opinion.id_management_level;
        l_opinion_hist.id_episode_answer    := l_opinion.id_episode_answer;
        l_opinion_hist.id_cancel_reason     := l_opinion.id_cancel_reason;
        l_opinion_hist.id_patient           := l_opinion.id_patient;
        l_opinion_hist.dt_last_update       := l_opinion.dt_last_update;
        l_opinion_hist.id_opinion_type      := l_opinion.id_opinion_type;
        l_opinion_hist.id_clinical_service  := l_opinion.id_clinical_service;
        l_opinion_hist.dt_approved          := l_opinion.dt_approved;
        l_opinion_hist.id_prof_approved     := l_opinion.id_prof_approved;
        l_opinion_hist.notes                := l_opinion.notes;
        l_opinion_hist.id_episode_approval  := l_opinion.id_episode_approval;
        l_opinion_hist.flg_auto_follow_up   := l_opinion.flg_auto_follow_up;
        l_opinion_hist.id_prof_created_hist := i_prof.id;
        l_opinion_hist.dt_created_hist      := g_sysdate_tstz;
    
        g_error := 'INSERT INTO OPINION_HIST';
        ts_opinion_hist.ins(rec_in => l_opinion_hist, rows_out => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'OPINION_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
        o_opinion_hist := l_opinion_hist.id_opinion_hist;
    END set_opinion_hist;

    /**
    * Set opinion reasons.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param i_reasons        reason identifiers list
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/14
    */
    PROCEDURE set_opinion_reason
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_opinion             IN opinion.id_opinion%TYPE,
        i_reasons             IN table_number,
        i_tbl_alert_diagnosis IN table_number,
        i_reasons_desc        IN table_varchar
    ) IS
        l_error                  t_error_out;
        l_rows                   table_varchar := table_varchar();
        l_opr_row                opinion_reason%ROWTYPE;
        l_opr_row_coll           ts_opinion_reason.opinion_reason_tc;
        l_tbl_existing_diagnosis table_number;
        l_flg_other_diag         diagnosis_ea.flg_other%TYPE;
    
        l_tbl_id_diagnosis       table_number := table_number();
        l_tbl_id_alert_diagnosis table_number := table_number();
        l_tbl_diagnoses          table_clob := table_clob();
        l_tbl_diagnoses_config   t_coll_diagnosis_config;
    
        l_lst_diagnosis pk_edis_types.table_in_epis_diagnosis;
        l_rec_diagnosis pk_edis_types.rec_in_epis_diagnosis;
    
        l_output pk_edis_types.table_out_epis_diags;
        l_diag   pk_edis_types.rec_in_epis_diagnoses;
    
        l_epis_diag       epis_diagnosis.id_epis_diagnosis%TYPE;
        l_flg_add_problem epis_diagnosis.flg_add_problem%TYPE;
    
        CURSOR c_epis_diag
        (
            l_diagnosis      IN NUMBER,
            l_desc_diagnosis IN VARCHAR2
        ) IS
            SELECT ed.id_epis_diagnosis, ed.flg_add_problem
              FROM epis_diagnosis ed, diagnosis d
             WHERE ed.id_episode = i_episode
               AND ed.id_diagnosis = l_diagnosis
               AND d.id_diagnosis = ed.id_diagnosis
               AND ((nvl(d.flg_other, 'N') = pk_alert_constant.g_yes AND
                   nvl(ed.desc_epis_diagnosis, '#') = nvl(l_desc_diagnosis, '#')) OR
                   (nvl(d.flg_other, 'N') = pk_alert_constant.g_no))
               AND ed.flg_status != pk_diagnosis.g_ed_flg_status_ca;
    BEGIN
    
        -- delete existing reasons (they are saved in history)
        SELECT o.id_diagnosis
          BULK COLLECT
          INTO l_tbl_existing_diagnosis
          FROM opinion_reason o
         WHERE o.id_opinion = i_opinion;
    
        g_error := 'CALL ts_opinion_reason.del';
        IF l_tbl_existing_diagnosis.exists(1)
        THEN
            FOR i IN l_tbl_existing_diagnosis.first .. l_tbl_existing_diagnosis.last
            LOOP
                ts_opinion_reason.del(id_opinion_in   => i_opinion,
                                      id_diagnosis_in => l_tbl_existing_diagnosis(i),
                                      rows_out        => l_rows);
            END LOOP;
        
            g_error := 'CALL t_data_gov_mnt.process_delete';
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'OPINION_REASON',
                                          i_rowids     => l_rows,
                                          o_error      => l_error);
        END IF;
    
        IF i_reasons IS NOT NULL
           AND i_reasons.first IS NOT NULL
           AND i_reasons(i_reasons.first) IS NOT NULL
        THEN
            l_rows := table_varchar();
        
            -- for every specified reason, fill a row, and add it to the collection
            -- (all rows will have the same opinion identifier)
            l_opr_row.id_opinion := i_opinion;
            FOR i IN i_reasons.first .. i_reasons.last
            LOOP
            
                SELECT t.flg_other
                  INTO l_flg_other_diag
                  FROM (SELECT dea.flg_other, rownum AS rn
                          FROM diagnosis_ea dea
                         WHERE dea.id_concept_version = i_reasons(i)
                           AND dea.id_institution IN (0, i_prof.institution)
                           AND dea.id_software IN (0, i_prof.software)
                         ORDER BY dea.id_institution DESC, dea.id_software DESC) t
                 WHERE t.rn = 1;
            
                l_opr_row.id_diagnosis       := i_reasons(i);
                l_opr_row.id_diag_inst_owner := 0;
                l_opr_row.diagnosis_desc := CASE
                                                WHEN l_flg_other_diag = pk_alert_constant.g_yes
                                                     AND i_reasons_desc.exists(1) THEN
                                                 i_reasons_desc(i)
                                                ELSE
                                                 NULL
                                            END;
                IF i_tbl_alert_diagnosis.exists(i)
                THEN
                    l_opr_row.id_alert_diagnosis := i_tbl_alert_diagnosis(i);
                END IF;
                l_opr_row_coll(i) := l_opr_row;
            END LOOP;
        
            -- insert all rows, and process all inserts
            g_error := 'CALL ts_opinion_reason.ins';
            ts_opinion_reason.ins(rows_in => l_opr_row_coll, handle_error_in => FALSE, rows_out => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'OPINION_REASON',
                                          i_rowids     => l_rows,
                                          o_error      => l_error);
        
            --Inserir diagnósticos diferenciais 
            SELECT ad.id_diagnosis, ad.id_alert_diagnosis
              BULK COLLECT
              INTO l_tbl_id_diagnosis, l_tbl_id_alert_diagnosis
              FROM alert_diagnosis ad
             WHERE ad.id_alert_diagnosis IN (SELECT /*+opt_estimate(table a rows=1)*/
                                              t.*
                                               FROM TABLE(i_tbl_alert_diagnosis) t);
        
            IF l_tbl_id_diagnosis.count > 0
            THEN
            
                l_tbl_diagnoses.extend();
                l_tbl_diagnoses(l_tbl_diagnoses.count) := '<EPIS_DIAGNOSES ID_PATIENT="' || i_patient ||
                                                          '" ID_EPISODE="' || i_episode ||
                                                          '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" /> ';
            
                FOR i IN l_tbl_id_diagnosis.first .. l_tbl_id_diagnosis.last
                LOOP
                    l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                              ' <DIAGNOSIS ID_DIAGNOSIS="' || l_tbl_id_diagnosis(i) ||
                                                              '" ID_ALERT_DIAG="' || l_tbl_id_alert_diagnosis(i) || '">
                                <DESC_DIAGNOSIS>undefined</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS> ';
                END LOOP;
            
                l_tbl_diagnoses(l_tbl_diagnoses.count) := l_tbl_diagnoses(l_tbl_diagnoses.count) ||
                                                          ' </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
            ELSE
                l_tbl_diagnoses.extend();
            END IF;
        
            IF l_tbl_diagnoses IS NOT NULL
               AND l_tbl_diagnoses.count > 0
            THEN
                l_lst_diagnosis := pk_diagnosis.get_diag_rec(i_lang   => i_lang,
                                                             i_prof   => i_prof,
                                                             i_params => l_tbl_diagnoses);
            END IF;
        
            IF l_lst_diagnosis.count > 0
            THEN
                l_rec_diagnosis := l_lst_diagnosis(1);
                IF l_rec_diagnosis.tbl_diagnosis IS NOT NULL
                   AND l_rec_diagnosis.tbl_diagnosis.count > 0
                THEN
                    FOR i IN 1 .. l_rec_diagnosis.tbl_diagnosis.count
                    LOOP
                        IF l_rec_diagnosis.tbl_diagnosis(i).id_diagnosis IS NOT NULL
                        THEN
                            g_error := 'GET CURSOR C_EPIS_DIAG';
                            OPEN c_epis_diag(l_rec_diagnosis.tbl_diagnosis(i).id_diagnosis,
                                             l_rec_diagnosis.tbl_diagnosis(i).desc_diagnosis);
                            FETCH c_epis_diag
                                INTO l_epis_diag, l_flg_add_problem;
                            g_found := c_epis_diag%FOUND;
                            CLOSE c_epis_diag;
                        
                            IF NOT g_found
                            THEN
                                l_tbl_diagnoses_config := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                                                  i_prof                     => i_prof,
                                                                                                  i_patient                  => i_patient,
                                                                                                  i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                                                                  i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                                                                  i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                                                  i_tbl_diagnosis            => table_number(l_rec_diagnosis.tbl_diagnosis(i).id_diagnosis),
                                                                                                  i_tbl_alert_diagnosis      => table_number(l_rec_diagnosis.tbl_diagnosis(i).id_alert_diagnosis));
                            
                                IF l_tbl_diagnoses_config.exists(1)
                                THEN
                                    l_diag.epis_diagnosis := l_rec_diagnosis;
                                    --To mantain the old logic we are going to treat one diagnosis at a time
                                    l_diag.epis_diagnosis.tbl_diagnosis := pk_edis_types.table_in_diagnosis(l_rec_diagnosis.tbl_diagnosis(i));
                                
                                    l_diag.epis_diagnosis.flg_edit_mode := pk_diagnosis_core.g_diag_create_mode;
                                    l_diag.epis_diagnosis.flg_type := pk_diagnosis.g_diag_type_p;
                                    l_diag.epis_diagnosis.tbl_diagnosis(1).flg_status := pk_diagnosis.g_ed_flg_status_d;
                                    l_diag.epis_diagnosis.tbl_diagnosis(1).flg_add_problem := l_flg_add_problem;
                                
                                    --g_error := 'CREATE_DIAGNOSIS ' || i_diag.tbl_diagnosis(i).id_diagnosis;
                                    IF NOT pk_diagnosis_core.set_epis_diagnosis(i_lang           => i_lang,
                                                                                i_prof           => i_prof,
                                                                                i_epis_diagnoses => l_diag,
                                                                                o_params         => l_output,
                                                                                o_error          => l_error)
                                    
                                    THEN
                                        RAISE g_exception;
                                    END IF;
                                
                                    g_error := 'GET CURSOR C_EPIS_DIAG 2';
                                    OPEN c_epis_diag(l_rec_diagnosis.tbl_diagnosis(i).id_diagnosis,
                                                     l_rec_diagnosis.tbl_diagnosis(i).desc_diagnosis);
                                    FETCH c_epis_diag
                                        INTO l_epis_diag, l_flg_add_problem;
                                    CLOSE c_epis_diag;
                                ELSE
                                    l_epis_diag       := NULL;
                                    l_flg_add_problem := NULL;
                                END IF;
                            END IF;
                        
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        
        END IF;
    END set_opinion_reason;

    /**
    * Set history of opinion reasons.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param i_opinion_hist   opinion history identifier
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/14
    */
    PROCEDURE set_opinion_reason_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_hist IN opinion_hist.id_opinion_hist%TYPE
    ) IS
        l_reasons       table_number := table_number();
        l_reasons_desc  table_varchar := table_varchar();
        l_error         t_error_out;
        l_rows          table_varchar := table_varchar();
        l_oprh_row      opinion_reason_hist%ROWTYPE;
        l_oprh_row_coll ts_opinion_reason_hist.opinion_reason_hist_tc;
    
        CURSOR c_reason IS
            SELECT opr.id_diagnosis, opr.diagnosis_desc
              FROM opinion_reason opr
             WHERE opr.id_opinion = i_opinion;
    BEGIN
        g_error := 'OPEN c_reason';
        OPEN c_reason;
        FETCH c_reason BULK COLLECT
            INTO l_reasons, l_reasons_desc;
        CLOSE c_reason;
    
        IF l_reasons IS NOT NULL
           AND l_reasons.first IS NOT NULL
           AND l_reasons(l_reasons.first) IS NOT NULL
        THEN
            -- for every specified reason, fill a row, and add it to the collection
            -- (all rows will have the same opinion identifier)
            l_oprh_row.id_opinion_hist      := i_opinion_hist;
            l_oprh_row.id_prof_created_hist := i_prof.id;
            l_oprh_row.dt_created_hist      := g_sysdate_tstz;
            FOR i IN l_reasons.first .. l_reasons.last
            LOOP
                l_oprh_row.id_diagnosis := l_reasons(i);
                l_oprh_row.diagnosis_desc := l_reasons_desc(i);
                l_oprh_row_coll(i) := l_oprh_row;
            END LOOP;
        
            -- insert all rows, and process all inserts
            g_error := 'CALL ts_management_follow_reason.ins';
            ts_opinion_reason_hist.ins(rows_in => l_oprh_row_coll, rows_out => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'OPINION_REASON',
                                          i_rowids     => l_rows,
                                          o_error      => l_error);
        END IF;
    END set_opinion_reason_hist;

    /**
    * Get a professional's default dep_clin_serv.
    *
    * @param i_prof           logged professional structure
    *
    * @return                 dep_clin_serv identifier
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/07/01
    */
    FUNCTION get_prof_def_dcs(i_prof IN profissional) RETURN dep_clin_serv.id_dep_clin_serv%TYPE IS
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE := NULL;
        l_software      software.id_software%TYPE := NULL;
    
        CURSOR c_prof_def_dcs(l_software software.id_software%TYPE) IS
            SELECT dcs.id_dep_clin_serv
              FROM dep_clin_serv dcs
              JOIN prof_dep_clin_serv pdcs
                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
              JOIN department d
                ON dcs.id_department = d.id_department
              JOIN software_dept sd
                ON d.id_dept = sd.id_dept
             WHERE dcs.flg_available = pk_alert_constant.g_yes
               AND pdcs.id_professional = i_prof.id
               AND pdcs.flg_status = pk_alert_constant.g_status_selected
               AND pdcs.flg_default = pk_alert_constant.g_yes
               AND d.id_institution = i_prof.institution
               AND d.flg_available = pk_alert_constant.g_yes
               AND sd.id_software = l_software;
    BEGIN
        --ACTIVITY THERAPIST episodes should be associated with INPATIENT dep_clin_serv
        IF i_prof.software = pk_alert_constant.g_soft_act_therapist
        THEN
            l_software := pk_alert_constant.g_soft_inpatient;
        ELSE
            l_software := i_prof.software;
        END IF;
    
        g_error := 'OPEN c_prof_def_dcs';
        OPEN c_prof_def_dcs(l_software);
        FETCH c_prof_def_dcs
            INTO l_dep_clin_serv;
        g_found := c_prof_def_dcs%FOUND;
        CLOSE c_prof_def_dcs;
    
        IF NOT g_found
        THEN
            l_dep_clin_serv := NULL;
        END IF;
    
        RETURN l_dep_clin_serv;
    END get_prof_def_dcs;

    /*******************************************************************************************
    * Answers (accepts/rejects) a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_patient          patient identifier
    * @param i_flg_state        Acceptance (E - accept / X - Reject )
    * @param i_management_level management level identifier
    * @param i_notes            answer notes
    * @param i_cancel_reason    refuse reason
    * @param i_transaction_id   remote SCH 3.0 transaction id
    * @param i_do_commit        perform commit inside this function
    * @param o_opinion          opinion identifier
    * @param o_opinion_prof     opinion prof identifier
    * @param o_episode          episode identifier
    * @param o_epis_encounter   episode encounter dentifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Elisabete Bugalho
    * @version                  2.6.0.1
    * @since                    09-04-2010
    ********************************************************************************************/
    FUNCTION set_request_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        i_cancel_reason    IN opinion_prof.id_cancel_reason%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_do_commit        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_opinion       IN TIMESTAMP DEFAULT NULL,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_epis_encounter   OUT epis_encounter.id_epis_encounter%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out       table_varchar := table_varchar();
        l_opinion_prof   opinion_prof.id_opinion_prof%TYPE;
        l_episode        episode.id_episode%TYPE;
        l_epis_encounter epis_encounter.id_epis_encounter%TYPE;
        l_episode_out    episode.id_episode%TYPE;
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
        CURSOR c_request IS
            SELECT e.id_epis_type, e.id_visit, v.flg_status
              FROM episode e, opinion o, visit v
             WHERE e.id_episode = o.id_episode
               AND e.id_visit = v.id_visit
               AND o.id_opinion = i_opinion;
    
        l_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_rec           c_request%ROWTYPE;
        l_common_exception EXCEPTION;
        l_error_message      sys_message.desc_message%TYPE;
        l_opinion_hist       opinion_hist.id_opinion_hist%TYPE;
        l_state              opinion.flg_state%TYPE;
        l_prof_questions     opinion.id_prof_questions%TYPE;
        l_op_episode         opinion.id_episode%TYPE;
        l_alert_msg          sys_message.code_message%TYPE;
        l_error_in           t_error_in := t_error_in();
        l_ret                BOOLEAN;
        l_id_opinion_type    opinion.id_opinion_type%TYPE;
        l_config_create_note sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'FOLLOW_UP_REQUEST_CREATE_NOTE',
                                                                              i_prof    => i_prof);
        l_id_epis_pn         epis_pn.id_epis_pn%TYPE;
    
        CURSOR c_opinion IS
            SELECT o.flg_state, o.id_prof_questions, o.id_episode, o.id_opinion_type
              FROM opinion o
             WHERE o.id_opinion = i_opinion
               FOR UPDATE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        alertlog.pk_alertlog.log_debug('PARAMS[i_opinion:' || i_opinion || '; i_patient:' || i_patient ||
                                       ';i_flg_state:' || i_flg_state || ';i_management_level:' || i_management_level ||
                                       '  ]',
                                       g_package_name,
                                       'SET_REQUEST_ANSWER');
    
        g_error := 'OPEN c_opinion';
        OPEN c_opinion;
        FETCH c_opinion
            INTO l_state, l_prof_questions, l_op_episode, l_id_opinion_type;
        CLOSE c_opinion;
    
        -- validate state
        IF l_state NOT IN (g_opinion_req, g_opinion_approved)
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 'OPINION_M013',
                                              i_sqlerrm  => pk_message.get_message(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_code_mess => 'OPINION_M013'),
                                              i_message  => pk_message.get_message(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_code_mess => 'OPINION_M011'),
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'VALIDATE_PROF',
                                              o_error    => o_error);
            RAISE g_exception;
        END IF;
    
        -- STEP 1: answer the request
        -- create opinion answer
        g_error := 'CALL ts_opinion_prof.ins';
        ts_opinion_prof.ins(id_opinion_in           => i_opinion,
                            flg_type_in             => i_flg_state,
                            id_professional_in      => i_prof.id,
                            desc_reply_in           => i_notes,
                            dt_opinion_prof_tstz_in => nvl(i_dt_opinion, g_sysdate_tstz),
                            flg_face_to_face_in     => g_unknown,
                            id_cancel_reason_in     => i_cancel_reason,
                            rows_out                => l_rows_out);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'OPINION_PROF',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
        l_rows_out := table_varchar();
    
        -- proceed only when the request is accepted
        IF i_flg_state = pk_opinion.g_opinion_accepted
        THEN
            l_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
            OPEN c_request;
            FETCH c_request
                INTO l_rec;
            CLOSE c_request;
        
            IF (i_prof.software NOT IN (pk_alert_constant.g_soft_nutritionist,
                                        pk_alert_constant.g_soft_social,
                                        pk_alert_constant.g_soft_psychologist,
                                        pk_alert_constant.g_soft_rehab))
            THEN
            
                -- STEP 2: create episode
                --     g_sysdate_tstz := current_timestamp;
            
                -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
                g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
                l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
            
                IF NOT pk_visit.create_episode(i_lang                 => i_lang,
                                               i_id_visit             => l_rec.id_visit,
                                               i_id_professional      => i_prof,
                                               i_id_sched             => NULL,
                                               i_id_episode           => NULL,
                                               i_health_plan          => NULL,
                                               i_epis_type            => l_epis_type,
                                               i_dep_clin_serv        => l_dep_clin_serv,
                                               i_sysdate              => NULL,
                                               i_sysdate_tstz         => NULL,
                                               i_flg_ehr              => pk_visit.g_flg_ehr_n,
                                               i_flg_appointment_type => pk_visit.g_null_appointment_type,
                                               i_transaction_id       => l_transaction_id,
                                               o_episode              => l_episode,
                                               o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                -- set previous episode information
                g_error := 'CALL ts_episode.upd';
                ts_episode.upd(id_episode_in         => l_episode,
                               id_prev_episode_in    => l_op_episode,
                               id_prev_episode_nin   => FALSE,
                               id_prev_epis_type_in  => l_rec.id_epis_type,
                               id_prev_epis_type_nin => FALSE,
                               rows_out              => l_rows_out);
                g_error := 'CALL t_data_gov_mnt.process_update I';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPISODE',
                                              i_rowids       => l_rows_out,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('ID_PREV_EPISODE', 'ID_PREV_EPIS_TYPE'));
            
            ELSE
                l_episode := l_op_episode;
            END IF;
            l_rows_out := table_varchar();
        
            g_error := 'CALL ts_opinion.upd I';
            ts_opinion.upd(id_opinion_in          => i_opinion,
                           id_episode_answer_in   => l_episode,
                           flg_state_in           => i_flg_state,
                           id_management_level_in => i_management_level,
                           dt_last_update_in      => g_sysdate_tstz,
                           dt_last_update_nin     => FALSE,
                           rows_out               => l_rows_out);
            g_error := 'CALL t_data_gov_mnt.process_update II';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'OPINION',
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATE',
                                                                          'ID_MANAGEMENT_LEVEL',
                                                                          'ID_EPISODE_ANSWER',
                                                                          'DT_LAST_UPDATE'));
            o_episode := l_episode;
        
            IF l_epis_type = pk_case_management.g_epis_type_cm
            THEN
                -- STEP 3: create encounter
                IF NOT pk_case_management.set_encounter(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_epis_encounter => NULL,
                                                        i_episode        => l_episode,
                                                        i_patient        => i_patient,
                                                        i_dt_begin       => NULL,
                                                        --i_dt_begin        => pk_date_utils.get_timestamp_str(i_lang,
                                                        --                                                     i_prof,
                                                        --                                                     current_timestamp,
                                                        --                                                     NULL),
                                                        i_id_professional => i_prof.id,
                                                        i_flg_type        => pk_case_management.g_enc_first,
                                                        i_notes           => NULL,
                                                        i_reasons         => table_number(),
                                                        o_epis_encounter  => l_epis_encounter,
                                                        o_episode         => l_episode_out,
                                                        o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                o_epis_encounter := l_epis_encounter;
            END IF;
        
            l_alert_msg := 'CONSULT_REQUEST_T055';
        ELSE
            g_error := 'CALL ts_opinion.upd II';
            ts_opinion.upd(id_opinion_in      => i_opinion,
                           flg_state_in       => i_flg_state,
                           dt_last_update_in  => g_sysdate_tstz,
                           dt_last_update_nin => FALSE,
                           rows_out           => l_rows_out);
            g_error := 'CALL t_data_gov_mnt.process_update III';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'OPINION',
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATE', 'DT_LAST_UPDATE'));
        
            l_alert_msg := 'CONSULT_REQUEST_T056';
        END IF;
    
        o_opinion_prof := l_opinion_prof;
        g_error        := 'CALL set_opinion_hist';
        set_opinion_hist(i_lang => i_lang, i_prof => i_prof, i_opinion => i_opinion, o_opinion_hist => l_opinion_hist);
    
        -- delete existant alert
        g_error := 'CALL pk_alerts.delete_sys_alert_event';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => g_alert_needs_acceptance,
                                                i_id_record    => i_opinion,
                                                o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_prof_questions <> i_prof.id)
        THEN
            -- create alert for the "questions" professional
            g_error := 'CALL pk_alerts.insert_sys_alert_event';
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => g_alert_acceptance_reply,
                                                    i_id_episode          => l_op_episode,
                                                    i_id_record           => i_opinion,
                                                    i_dt_record           => nvl(i_dt_opinion, g_sysdate_tstz),
                                                    i_id_professional     => l_prof_questions,
                                                    i_id_room             => NULL,
                                                    i_id_clinical_service => NULL,
                                                    i_flg_type_dest       => NULL,
                                                    i_replace1            => pk_message.get_message(i_lang      => i_lang,
                                                                                                    i_prof      => i_prof,
                                                                                                    i_code_mess => l_alert_msg),
                                                    o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF l_config_create_note = pk_alert_constant.g_yes
        THEN
            IF NOT create_follow_up_answer_note(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_id_episode      => l_op_episode,
                                                i_id_opinion      => i_opinion,
                                                i_id_opinion_type => l_id_opinion_type,
                                                i_sysdate_tstz    => nvl(i_dt_opinion, g_sysdate_tstz),
                                                o_error           => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END IF;
        END IF;
        --remote scheduler commit. Doesn't affect PFH.
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL -- esta ultima condicao nao costuma existir. 
        --existe para garantir que o fluxo passou pelo if i_flg_state = pk_opinion.g_opinion_accepted
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        IF nvl(i_do_commit, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_common_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   NULL,
                                   l_error_message,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_REQUEST_ANSWER',
                                   NULL,
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                pk_alert_exceptions.reset_error_state();
            
                pk_utils.undo_changes; -- ROLLBACK
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            END;
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REQUEST_ANSWER',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_request_answer;

    /**
    * Check if a follow-up request needs approval.
    *
    * @param i_prof           requester professional structure
    * @param i_opinion_type   follow-up request type
    *
    * @return                 Y if approval is needed, N otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/09
    */
    FUNCTION check_approval_need
    (
        i_prof         IN profissional,
        i_opinion_type IN opinion.id_opinion_type%TYPE
    ) RETURN opinion_type_prof.flg_approve%TYPE IS
        l_prof_templ  opinion_type_prof.id_profile_template%TYPE;
        l_flg_approve opinion_type_prof.flg_approve%TYPE;
    
        CURSOR c_approve IS
            SELECT otp.flg_approve
              FROM opinion_type_prof otp
             WHERE otp.id_opinion_type = i_opinion_type
               AND otp.id_profile_template = l_prof_templ
               AND otp.id_institution IN (0, i_prof.institution)
               AND otp.flg_available = pk_alert_constant.g_yes
             ORDER BY otp.id_institution DESC;
    BEGIN
        -- get requester profile template
        l_prof_templ := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        -- check approval configuration
        OPEN c_approve;
        FETCH c_approve
            INTO l_flg_approve;
        g_found := c_approve%FOUND;
        CLOSE c_approve;
    
        -- not configured? needs approval by default
        IF NOT g_found
        THEN
            l_flg_approve := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_flg_approve;
    END check_approval_need;

    /*
    * Check if new follow-up request can be created.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param o_create         create flag
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION check_create_request
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_create opinion_type_prof.flg_create%TYPE := pk_alert_constant.g_no;
        l_prof_templ opinion_type_prof.id_profile_template%TYPE;
        l_flags      table_varchar := table_varchar();
    
        CURSOR c_create IS
            SELECT decode(otp.flg_create, pk_alert_constant.g_yes, otp.flg_ongoing, otp.flg_create) flg_create
              FROM (SELECT otp.id_opinion_type,
                           otp.flg_create,
                           decode((SELECT COUNT(*)
                                    FROM opinion op
                                    JOIN episode e
                                      ON op.id_episode = e.id_episode
                                   WHERE op.id_patient = i_patient
                                     AND op.id_opinion_type = otp.id_opinion_type
                                     AND op.flg_state IN (g_opinion_req, g_opinion_accepted, g_opinion_approved)
                                     AND e.id_institution = i_prof.institution),
                                  0,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_ongoing,
                           row_number() over(PARTITION BY otp.id_opinion_type ORDER BY otp.id_institution DESC) rn
                      FROM opinion_type_prof otp
                     WHERE otp.id_profile_template = l_prof_templ
                       AND otp.id_institution IN (0, i_prof.institution)
                       AND otp.flg_available = pk_alert_constant.g_yes) otp
             WHERE otp.rn = 1;
    BEGIN
        g_error      := 'CALL pk_tools.get_prof_profile_template';
        l_prof_templ := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        IF (pk_patient.get_pat_has_inactive(i_lang, i_prof, i_patient) = pk_alert_constant.g_yes)
        THEN
            l_flg_create := pk_alert_constant.g_no;
        ELSIF i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            l_flg_create := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_intern_name => 'HHC_COORDINATOR');
        ELSE
            l_flg_create := pk_alert_constant.g_yes;
        END IF;
    
        IF l_flg_create = pk_alert_constant.g_yes
        THEN
            g_error := 'OPEN c_create';
            OPEN c_create;
            FETCH c_create BULK COLLECT
                INTO l_flags;
            CLOSE c_create;
        
            g_error := 'flags validation';
            IF l_flags IS NULL
               OR l_flags.first IS NULL
               OR l_flags(l_flags.first) IS NULL
            THEN
                NULL;
            ELSE
                FOR i IN l_flags.first .. l_flags.last
                LOOP
                    IF l_flags(i) = pk_alert_constant.g_yes
                    THEN
                        l_flg_create := pk_alert_constant.g_yes;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        END IF;
    
        o_create := l_flg_create;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_CREATE_REQUEST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END check_create_request;

    FUNCTION get_edis_inp_episode
    (
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN episode.id_episode%TYPE IS
        l_episode        episode.id_episode%TYPE;
        l_episode_return episode.id_episode%TYPE := NULL;
        l_episode_first  episode.id_episode%TYPE := NULL;
        l_count          PLS_INTEGER := 0;
    
        -- cursor for obtaining the edis/inp episode
        -- that backgrounds a follow-up request
        CURSOR c_ongoing_epis IS
            SELECT e.id_episode
              FROM episode e
             WHERE e.id_patient = i_patient
               AND e.id_institution = i_prof.institution
               AND e.flg_status = pk_alert_constant.g_epis_status_active
               AND e.flg_ehr = pk_alert_constant.g_epis_ehr_normal
               AND e.id_epis_type IN (pk_alert_constant.g_epis_type_emergency, pk_alert_constant.g_epis_type_inpatient)
               AND NOT EXISTS (SELECT 1
                      FROM discharge d
                     WHERE d.id_episode = e.id_episode
                       AND d.flg_status = pk_alert_constant.g_active)
             ORDER BY decode(e.id_epis_type, pk_alert_constant.g_epis_type_inpatient, 1, 2);
    BEGIN
        g_error := 'OPEN c_ongoing_epis';
        OPEN c_ongoing_epis;
        LOOP
            FETCH c_ongoing_epis
                INTO l_episode;
            IF (l_episode = i_id_episode)
            THEN
                l_episode_return := i_id_episode;
            END IF;
        
            IF (l_count = 0)
            THEN
                l_episode_first := l_episode;
            END IF;
            l_count := l_count + 1;
            EXIT WHEN(c_ongoing_epis%NOTFOUND OR l_episode_return IS NOT NULL);
        END LOOP;
        CLOSE c_ongoing_epis;
    
        RETURN nvl(l_episode_return, l_episode_first);
    END get_edis_inp_episode;

    /*
    * Get list of follow-up requests approvers.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param i_episode        episode identifier
    *
    * @return                 list of approvers
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION get_approvers_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE := NULL
    ) RETURN table_number IS
        l_episode       episode.id_episode%TYPE;
        l_hand_off_type sys_config.value%TYPE;
        l_prof_ids      table_number := table_number();
    BEGIN
        IF i_episode IS NULL
        THEN
            g_error   := 'CALL get_edis_inp_episode';
            l_episode := get_edis_inp_episode(i_prof => i_prof, i_patient => i_patient, i_id_episode => i_episode);
        ELSE
            l_episode := i_episode;
        END IF;
    
        IF l_episode IS NOT NULL
        THEN
            g_error := 'CALL pk_hand_off_core.get_hand_off_type';
            pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
            g_error    := 'CALL pk_hand_off_core.get_responsibles_id';
            l_prof_ids := pk_hand_off_core.get_responsibles_id(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_id_episode    => l_episode,
                                                               i_prof_cat      => pk_alert_constant.g_cat_type_doc,
                                                               i_hand_off_type => l_hand_off_type);
        END IF;
        RETURN l_prof_ids;
    END get_approvers_list;

    /*
    * Check if a given professional can perform a given operation.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param i_state          new state for opinion
    * @param o_error          error
    *
    * @return                 false, if the operation is not valid,
    *                         or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/14
    */
    FUNCTION validate_prof
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        i_state   IN opinion.flg_state%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_can_proceed             BOOLEAN := TRUE;
        l_error_code              sys_message.code_message%TYPE;
        l_cur_state               opinion.flg_state%TYPE;
        l_prof_created            opinion.id_prof_questions%TYPE;
        l_patient                 opinion.id_patient%TYPE;
        l_episode                 episode.id_episode%TYPE;
        l_prof_ids                table_number := table_number();
        l_consult_req_prof_cancel sys_config.value%TYPE := pk_sysconfig.get_config('CANCEL_CONSULT_OTHER_PROF', i_prof);
    
        CURSOR c_opinion IS
            SELECT o.flg_state, o.id_prof_questions, o.id_patient, o.id_episode
              FROM opinion o
             WHERE o.id_opinion = i_opinion;
    BEGIN
        g_error := 'OPEN c_opinion';
        OPEN c_opinion;
        FETCH c_opinion
            INTO l_cur_state, l_prof_created, l_patient, l_episode;
        CLOSE c_opinion;
    
        IF i_state = g_opinion_req
        THEN
            -- record is being edited
            IF l_prof_created != i_prof.id
            THEN
                l_can_proceed := FALSE;
                l_error_code  := 'OPINION_M012';
            ELSIF l_cur_state != g_opinion_req
            THEN
                l_can_proceed := FALSE;
                l_error_code  := 'OPINION_M013';
            END IF;
        ELSIF i_state = g_opinion_cancel
        THEN
            -- record is being cancelled
            IF l_prof_created != i_prof.id
               AND l_consult_req_prof_cancel = pk_alert_constant.get_no
            THEN
                l_can_proceed := FALSE;
                l_error_code  := 'OPINION_M002';
            ELSIF l_cur_state != g_opinion_req
            THEN
                l_can_proceed := FALSE;
                l_error_code  := 'OPINION_M013';
            END IF;
        ELSIF i_state IN (g_opinion_approved, g_opinion_not_approved)
        THEN
            -- record is being approved
            g_error    := 'CALL get_approvers_list';
            l_prof_ids := get_approvers_list(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_patient => l_patient,
                                             i_episode => l_episode);
        
            IF pk_utils.search_table_number(i_table => l_prof_ids, i_search => i_prof.id) < 0
            THEN
                l_can_proceed := FALSE;
                l_error_code  := 'OPINION_M014';
            ELSIF l_cur_state != g_opinion_req
            THEN
                l_can_proceed := FALSE;
                l_error_code  := 'OPINION_M013';
            END IF;
        END IF;
    
        IF NOT l_can_proceed
        THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => l_error_code,
                                              i_sqlerrm  => pk_message.get_message(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_code_mess => l_error_code),
                                              i_message  => pk_message.get_message(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_code_mess => 'OPINION_M011'),
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'VALIDATE_PROF',
                                              o_error    => o_error);
        END IF;
        RETURN l_can_proceed;
    END validate_prof;

    /*
    * Get list of actions for the follow-up requests screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param i_opinion        follow-up request identifier
    * @param o_actions        actions cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION get_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_opinion IN opinion.id_opinion%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_opinion IS
            SELECT o.flg_state, o.id_opinion_type, o.id_prof_questions, ei.id_software, o.id_episode
              FROM opinion o
              JOIN epis_info ei
                ON o.id_episode = ei.id_episode
             WHERE o.id_opinion = i_opinion;
    
        l_subject CONSTANT action.subject%TYPE := 'FOLLOW_UP_REQUEST';
        l_prof_ids                table_number := table_number();
        l_approval_perm           VARCHAR2(1 CHAR) := pk_alert_constant.g_inactive;
        l_flg_approve             opinion_type_prof.flg_approve%TYPE;
        l_op_row                  c_opinion%ROWTYPE;
        l_consult_req_prof_cancel sys_config.value%TYPE := pk_sysconfig.get_config('CANCEL_CONSULT_OTHER_PROF', i_prof);
    
    BEGIN
        g_error := 'OPEN c_opinion';
        OPEN c_opinion;
        FETCH c_opinion
            INTO l_op_row;
        CLOSE c_opinion;
    
        -- get approvers list
        g_error    := 'CALL get_approvers_list';
        l_prof_ids := get_approvers_list(i_lang    => i_lang,
                                         i_prof    => i_prof,
                                         i_patient => i_patient,
                                         i_episode => l_op_row.id_episode);
        -- search responsibles array
        IF pk_utils.search_table_number(i_table => l_prof_ids, i_search => i_prof.id) > 0
        THEN
            -- i_prof is a valid approver
            l_approval_perm := pk_alert_constant.g_active;
        END IF;
    
        g_error       := 'CALL check_approval_need';
        l_flg_approve := check_approval_need(i_prof         => profissional(l_op_row.id_prof_questions,
                                                                            i_prof.institution,
                                                                            l_op_row.id_software),
                                             i_opinion_type => l_op_row.id_opinion_type);
    
        g_error := 'OPEN o_actions';
        OPEN o_actions FOR
            SELECT a.id_action,
                   a.id_parent,
                   1 "LEVEL",
                   a.from_state,
                   a.to_state,
                   pk_message.get_message(i_lang, i_prof, a.code_action) desc_action,
                   a.icon,
                   decode(a.flg_default, 'D', pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
                   decode(l_op_row.flg_state,
                          g_opinion_req,
                          decode(a.to_state,
                                 g_opinion_req,
                                 decode(l_op_row.id_prof_questions,
                                        i_prof.id,
                                        pk_alert_constant.g_active,
                                        pk_alert_constant.g_inactive),
                                 g_opinion_cancel,
                                 decode(l_consult_req_prof_cancel,
                                        pk_alert_constant.g_yes,
                                        pk_alert_constant.g_active,
                                        decode(l_op_row.id_prof_questions,
                                               i_prof.id,
                                               pk_alert_constant.g_active,
                                               pk_alert_constant.g_inactive)),
                                 g_opinion_approved,
                                 decode(l_flg_approve,
                                        pk_alert_constant.g_yes,
                                        l_approval_perm,
                                        pk_alert_constant.g_inactive),
                                 g_opinion_not_approved,
                                 decode(l_flg_approve,
                                        pk_alert_constant.g_yes,
                                        l_approval_perm,
                                        pk_alert_constant.g_inactive)),
                          pk_alert_constant.g_inactive) flg_active,
                   a.internal_name action
              FROM action a
             WHERE a.subject = l_subject
             ORDER BY a.rank, desc_action;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ACTIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    /*
    * Get list of follow-up request types, for the create button.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param o_types          types cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION get_request_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_types   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_intern_name CONSTANT action.internal_name%TYPE := 'CREATE';
        l_prof_templ opinion_type_prof.id_profile_template%TYPE;
        l_prof_cat   category.id_category%TYPE;
    BEGIN
        g_error      := 'CALL pk_tools.get_prof_profile_template';
        l_prof_templ := pk_tools.get_prof_profile_template(i_prof => i_prof);
        g_error      := 'CALL pk_prof_utils.get_id_category';
        l_prof_cat   := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'OPEN o_types';
        OPEN o_types FOR
            SELECT ot.id_opinion_type id_action,
                   ot.id_parent,
                   1 "LEVEL",
                   pk_alert_constant.g_inactive from_state,
                   pk_alert_constant.g_active to_state,
                   pk_translation.get_translation(i_lang, ot.code_opinion_type) desc_action,
                   NULL icon,
                   pk_alert_constant.g_no flg_default,
                   decode(ot.flg_create,
                          pk_alert_constant.g_yes,
                          decode(ot.id_category,
                                 l_prof_cat,
                                 pk_alert_constant.g_inactive,
                                 decode(ot.flg_ongoing,
                                        pk_alert_constant.g_yes,
                                        pk_alert_constant.g_inactive,
                                        pk_alert_constant.g_active)),
                          pk_alert_constant.g_inactive) flg_active,
                   l_intern_name action
              FROM (SELECT ot.id_opinion_type,
                           ot.code_opinion_type,
                           otc.id_category,
                           otp.flg_create,
                           ot.id_parent,
                           decode((SELECT COUNT(*)
                                    FROM opinion op
                                    JOIN episode e
                                      ON op.id_episode = e.id_episode
                                   WHERE op.id_patient = i_patient
                                     AND ((op.id_opinion_type = otp.id_opinion_type AND
                                         otp.id_opinion_type NOT IN (g_ot_social_worker, g_ot_social_worker_ds)) OR
                                         (op.id_opinion_type IN (g_ot_social_worker, g_ot_social_worker_ds) AND
                                         otp.id_opinion_type IN (g_ot_social_worker, g_ot_social_worker_ds)))
                                     AND op.flg_state IN (g_opinion_req, g_opinion_accepted, g_opinion_approved)
                                     AND e.id_institution = i_prof.institution),
                                  0,
                                  pk_alert_constant.g_no,
                                  pk_alert_constant.g_yes) flg_ongoing,
                           row_number() over(PARTITION BY otp.id_opinion_type ORDER BY otp.id_institution DESC) rn
                      FROM opinion_type ot
                      JOIN opinion_type_category otc
                        ON otc.id_opinion_type = ot.id_opinion_type
                      JOIN opinion_type_prof otp
                        ON ot.id_opinion_type = otp.id_opinion_type
                     WHERE otp.id_profile_template = l_prof_templ
                       AND otp.id_institution IN (0, i_prof.institution)
                       AND otp.flg_available = pk_alert_constant.g_yes
                       AND otc.flg_available = pk_alert_constant.g_yes) ot
             WHERE ot.rn = 1
             ORDER BY desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REQUEST_TYPES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_types);
            RETURN FALSE;
    END get_request_types;

    /*
    * Show user warnings prior to creating a new follow-up request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_patient        patient identifier
    * @param i_opinion_type   patient identifier
    * @param o_flg_show       'Y', when warnings exist.
    * @param o_msg            warning message
    * @param o_msg_title      warning message title
    * @param o_popup_title    warning popup title
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION get_warnings
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion_type IN opinion.id_opinion_type%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_popup_title  OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_approval opinion_type_prof.flg_approve%TYPE;
        l_episode  episode.id_episode%TYPE;
        l_prof_ids table_number := table_number();
        l_status   visit.flg_status%TYPE;
    
        CURSOR c_visit_status IS
            SELECT v.flg_status
              FROM visit v
              JOIN episode e
                ON v.id_visit = e.id_visit
             WHERE e.id_episode = i_episode;
    BEGIN
        g_error    := 'CALL check_approval_need';
        l_approval := check_approval_need(i_prof => i_prof, i_opinion_type => i_opinion_type);
    
        IF l_approval = pk_alert_constant.g_yes
        THEN
            -- approval is needed
            -- check if ongoing edis/inp episode exists
            g_error   := 'CALL get_edis_inp_episode';
            l_episode := get_edis_inp_episode(i_prof => i_prof, i_patient => i_patient, i_id_episode => i_episode);
        
            IF l_episode IS NULL
            THEN
                -- show warning: no ongoing edis/inp episode exists
                o_flg_show    := pk_alert_constant.g_yes;
                o_msg         := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => 'OPINION_M009');
                o_msg_title   := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => 'OPINION_M011');
                o_popup_title := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => 'COMMON_T013');
            ELSE
                -- check if visit is active
                g_error := 'OPEN c_visit_status ' || l_episode;
                OPEN c_visit_status;
                FETCH c_visit_status
                    INTO l_status;
                CLOSE c_visit_status;
            
                IF l_status IS NULL
                   OR l_status IN (pk_alert_constant.g_inactive, pk_alert_constant.g_cancelled)
                THEN
                    -- show warning: patient visit is inactive or cancelled
                    o_flg_show    := pk_alert_constant.g_yes;
                    o_msg         := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'OPINION_M015');
                    o_msg_title   := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'OPINION_M011');
                    o_popup_title := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'COMMON_T013');
                ELSE
                    -- get list of episode responsibles
                    g_error    := 'CALL get_approvers_list';
                    l_prof_ids := get_approvers_list(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     i_episode => l_episode);
                
                    IF l_prof_ids IS NULL
                       OR l_prof_ids.first IS NULL
                       OR l_prof_ids(l_prof_ids.first) IS NULL
                    THEN
                        -- show warning: no responsible exists
                        o_flg_show    := pk_alert_constant.g_yes;
                        o_msg         := pk_message.get_message(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_code_mess => 'OPINION_M010');
                        o_msg_title   := pk_message.get_message(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_code_mess => 'OPINION_M011');
                        o_popup_title := pk_message.get_message(i_lang      => i_lang,
                                                                i_prof      => i_prof,
                                                                i_code_mess => 'COMMON_T013');
                    ELSE
                        o_flg_show := pk_alert_constant.g_no;
                    END IF;
                END IF;
            END IF;
        ELSE
            -- approval is not needed
            -- check if visit is active
            g_error := 'OPEN c_visit_status ' || i_episode;
            OPEN c_visit_status;
            FETCH c_visit_status
                INTO l_status;
            CLOSE c_visit_status;
        
            IF l_status IS NULL
               OR l_status IN (pk_alert_constant.g_inactive, pk_alert_constant.g_cancelled)
            THEN
                -- show warning: patient visit is inactive or cancelled
                o_flg_show    := pk_alert_constant.g_yes;
                o_msg         := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => 'OPINION_M015');
                o_msg_title   := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => 'OPINION_M011');
                o_popup_title := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => 'COMMON_T013');
            ELSE
                o_flg_show := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_WARNINGS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_warnings;

    FUNCTION get_detail_description
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_type      IN ds_component.flg_data_type%TYPE,
        i_internal_name IN ds_component.internal_name%TYPE,
        i_code_domain   IN ds_component.code_domain%TYPE,
        i_value         IN opinion_ds.value%TYPE
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(400);
    
    BEGIN
    
        IF i_flg_type = g_ds_check_box_type
        THEN
            l_result := pk_sysdomain.get_domain(i_code_dom => i_code_domain, i_val => i_value, i_lang => i_lang);
        ELSIF i_flg_type = g_ds_single_multi_choice_type
              AND i_internal_name = g_ds_prof_list
        THEN
            IF i_value = g_any_prof
            THEN
                l_result := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021');
            ELSE
                l_result := pk_prof_utils.get_name_signature(i_lang, i_prof, i_value);
            END IF;
        ELSE
            l_result := i_value;
        END IF;
    
        RETURN l_result;
    END get_detail_description;

    /*
    * Get request information, for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param i_opinion_type   patient identifier
    * @param o_spec           specialties cursor
    * @param o_spec_enable    enable specialty field? (Y/N)
    * @param o_reason_type    reason field fill type (T/M)
    * @param o_opinion        opinion cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */
    FUNCTION get_consult_request_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        o_spec         OUT pk_types.cursor_type,
        o_spec_enable  OUT VARCHAR2,
        o_reason_type  OUT VARCHAR2,
        o_opinion      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_label_speciality     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'COMMON_T053');
        l_label_request_reason sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'CONSULT_REQUEST_T025');
        l_label_prof           sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'CONSULT_REQUEST_T026');
        l_label_notes          sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                       i_prof,
                                                                                       'CONSULT_REQUEST_T027');
    
        l_code_cs CONSTANT translation.code_translation%TYPE := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.';
        l_count              PLS_INTEGER;
        l_id_diagnosis       table_number := table_number();
        l_id_alert_diagnosis table_number := table_number();
        l_diagnosis          table_varchar := table_varchar();
    
        CURSOR c_count_spec IS
            SELECT COUNT(*)
              FROM opinion_type_clin_serv otcs
              JOIN clinical_service cs
                ON otcs.id_clinical_service = cs.id_clinical_service
             WHERE otcs.id_opinion_type = i_opinion_type
               AND otcs.id_software IN (0, i_prof.software)
               AND otcs.id_institution IN (0, i_prof.institution)
               AND otcs.flg_available = pk_alert_constant.g_yes
               AND cs.flg_available = pk_alert_constant.g_yes;
    BEGIN
    
        --Check if Opinion has been documented through dynamic screen (l_count > 0)
        SELECT COUNT(1)
          INTO l_count
          FROM opinion_ds od
         WHERE od.id_opinion = i_opinion;
    
        IF l_count = 0
        THEN
            -- count available specialties
            g_error := 'OPEN c_count_spec';
            OPEN c_count_spec;
            FETCH c_count_spec
                INTO l_count;
            CLOSE c_count_spec;
        
            IF l_count = 0
            THEN
                -- no specialties available
                pk_types.open_my_cursor(o_spec);
                o_spec_enable := pk_alert_constant.g_no;
            ELSE
                -- specialties exist
                g_error := 'OPEN o_spec';
                OPEN o_spec FOR
                    SELECT otcs.id_clinical_service data,
                           pk_translation.get_translation(i_lang, cs.code_clinical_service) label
                      FROM (SELECT otcs.id_clinical_service,
                                   row_number() over(PARTITION BY otcs.id_clinical_service ORDER BY otcs.id_institution DESC, otcs.id_software DESC) rn
                              FROM opinion_type_clin_serv otcs
                             WHERE otcs.id_opinion_type = i_opinion_type
                               AND otcs.id_software IN (0, i_prof.software)
                               AND otcs.id_institution IN (0, i_prof.institution)
                               AND otcs.flg_available = pk_alert_constant.g_yes) otcs
                      JOIN clinical_service cs
                        ON otcs.id_clinical_service = cs.id_clinical_service
                     WHERE otcs.rn = 1
                       AND cs.flg_available = pk_alert_constant.g_yes;
            
                o_spec_enable := pk_alert_constant.g_yes;
            END IF;
        
            -- set reason field fill type
            IF i_opinion_type = g_ot_case_manager
            THEN
                o_reason_type := g_reason_multichoice;
                g_error       := 'CALL get_cm_req_reason';
                get_cm_req_reason(i_lang               => i_lang,
                                  i_prof               => i_prof,
                                  i_opinion            => i_opinion,
                                  o_id_diagnosis       => l_id_diagnosis,
                                  o_id_alert_diagnosis => l_id_alert_diagnosis,
                                  o_diagnosis          => l_diagnosis);
            ELSE
                o_reason_type := g_reason_free_text;
            END IF;
        
            IF i_opinion IS NULL
            THEN
                g_error := 'OPEN o_opinion I';
                OPEN o_opinion FOR
                    SELECT NULL                   id,
                           NULL                   spec_id,
                           NULL                   spec_desc,
                           l_label_speciality     spec_title,
                           NULL                   reason_ft_desc,
                           l_id_diagnosis         reason_mc_id,
                           l_diagnosis            reason_mc_desc,
                           l_label_request_reason reason_title,
                           NULL                   prof_id,
                           NULL                   prof_desc,
                           l_label_prof           prof_title,
                           NULL                   notes,
                           l_label_notes          notes_title
                      FROM dual;
            ELSE
                g_error := 'OPEN o_opinion II';
                OPEN o_opinion FOR
                    SELECT op.id_opinion id,
                           op.id_clinical_service spec_id,
                           pk_translation.get_translation(i_lang, l_code_cs || op.id_clinical_service) spec_desc,
                           l_label_speciality spec_title,
                           op.desc_problem reason_ft_desc,
                           l_id_diagnosis reason_mc_id,
                           l_diagnosis reason_mc_desc,
                           l_label_request_reason reason_title,
                           nvl(op.id_prof_questioned, g_any_prof) prof_id,
                           decode(op.id_prof_questioned,
                                  NULL,
                                  pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021'),
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_prof_questioned)) prof_desc,
                           l_label_prof prof_title,
                           op.notes,
                           l_label_notes notes_title
                      FROM opinion op
                     WHERE op.id_opinion = i_opinion;
            END IF;
        ELSE
            --Opinion documented through dynamic screen
            pk_types.open_my_cursor(o_spec);
            o_spec_enable := pk_alert_constant.g_no;
            o_reason_type := NULL;
        
            OPEN o_opinion FOR
                SELECT dscm.id_ds_cmpt_mkt_rel,
                       dscp.id_ds_component,
                       dscp.internal_name,
                       dscp.flg_data_type,
                       od.value AS VALUE,
                       dscp.code_domain,
                       CASE
                            WHEN od.value IS NULL THEN
                             NULL
                            ELSE
                             get_detail_description(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_flg_type      => dscp.flg_data_type,
                                                    i_internal_name => dscp.internal_name,
                                                    i_code_domain   => dscp.code_domain,
                                                    i_value         => od.value)
                        END AS value_desc,
                       od.value_clob
                  FROM opinion o
                  JOIN opinion_ds od
                    ON od.id_opinion = o.id_opinion
                   AND od.dt_problem_tstz = coalesce(o.dt_last_update, o.dt_problem_tstz)
                  JOIN (SELECT dc.id_ds_cmpt_mkt_rel,
                               dc.id_ds_component_child id_ds_component,
                               dc.internal_name_child,
                               dc.flg_event_type,
                               dc.rn
                          FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_patient        => NULL,
                                                             i_component_name => decode(i_opinion_type,
                                                                                        g_ot_social_worker_ds,
                                                                                        g_ds_root_social_worker),
                                                             i_action         => NULL)) dc) dscm
                    ON dscm.id_ds_cmpt_mkt_rel = od.id_ds_cmpt_mkt_rel
                  JOIN ds_component dscp
                    ON dscp.id_ds_component = dscm.id_ds_component
                 WHERE o.id_opinion = i_opinion;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CONSULT_REQUEST_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_spec);
            pk_types.open_my_cursor(o_opinion);
            RETURN FALSE;
    END get_consult_request_edit;

    FUNCTION get_consult_request_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'get_consult_request_values';
    
        l_count_clinical_services PLS_INTEGER := 0;
        l_curr_comp_int_name      ds_component.internal_name%TYPE;
        l_ds_internal_name        ds_component.internal_name%TYPE;
    
        l_id_clinical_service   clinical_service.id_clinical_service%TYPE;
        l_clinical_service_desc VARCHAR2(4000 CHAR);
        l_id_diagnosis          table_number := table_number();
        l_tbl_alert_diagnosis   table_number := table_number();
        l_diagnosis             table_varchar := table_varchar();
        l_reason_ft             VARCHAR2(4000 CHAR);
        l_id_prof               professional.id_professional%TYPE;
        l_prof_desc             VARCHAR2(4000 CHAR);
        l_notes                 CLOB;
        l_id_opinion_type       opinion_type.id_opinion_type%TYPE;
    
        l_code_cs CONSTANT translation.code_translation%TYPE := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.';
    
        l_permission_for_search_diagnosis sys_config.value%TYPE := pk_sysconfig.get_config('PERMISSION_FOR_SEARCH_DIAGNOSIS',
                                                                                           i_prof);
    
        l_profile_template profile_template.id_profile_template%TYPE := pk_prof_utils.get_prof_profile_template(i_prof);
    
        l_search VARCHAR2(1 CHAR);
    
    BEGIN
        --check permissions for search diagnosis option avalilable
        IF instr(nvl(l_permission_for_search_diagnosis, '#'), l_profile_template) != 0
        THEN
            l_search := pk_alert_constant.g_yes;
        ELSE
            l_search := pk_alert_constant.g_no;
        END IF;
    
        IF i_episode IS NOT NULL
        THEN
            IF i_root_name = pk_orders_constant.g_ds_follow_up_social
               AND (i_action IS NULL OR i_action <> pk_dyn_form_constant.get_submit_action())
            THEN
                SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                           id_ds_component    => t.id_ds_component_child,
                                           internal_name      => t.internal_name_child,
                                           VALUE              => od.value,
                                           value_clob         => od.value_clob,
                                           min_value          => NULL,
                                           max_value          => NULL,
                                           desc_value         => CASE
                                                                     WHEN d.flg_data_type = g_ds_check_box_type THEN
                                                                      od.value
                                                                     ELSE
                                                                      get_detail_description(i_lang          => i_lang,
                                                                                             i_prof          => i_prof,
                                                                                             i_flg_type      => d.flg_data_type,
                                                                                             i_internal_name => d.internal_name,
                                                                                             i_code_domain   => d.code_domain,
                                                                                             i_value         => od.value)
                                                                 END,
                                           desc_clob          => od.value_clob,
                                           id_unit_measure    => NULL,
                                           desc_unit_measure  => NULL,
                                           flg_validation     => pk_alert_constant.g_yes,
                                           err_msg            => NULL,
                                           flg_event_type     => 'NA',
                                           flg_multi_status   => NULL,
                                           idx                => 1)
                  BULK COLLECT
                  INTO tbl_result
                  FROM opinion o
                  JOIN opinion_ds od
                    ON od.id_opinion = o.id_opinion
                   AND od.dt_problem_tstz = coalesce(o.dt_last_update, o.dt_problem_tstz)
                  JOIN (SELECT dc.id_ds_cmpt_mkt_rel,
                               dc.id_ds_component_child,
                               dc.internal_name_child,
                               dc.flg_event_type,
                               dc.rn,
                               dc.flg_component_type_child
                          FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_patient        => NULL,
                                                             i_component_name => i_root_name,
                                                             i_action         => NULL)) dc) t
                    ON t.id_ds_cmpt_mkt_rel = od.id_ds_cmpt_mkt_rel
                  JOIN ds_component d
                    ON d.id_ds_component = t.id_ds_component_child
                 WHERE o.id_opinion IN (SELECT /*+opt_estimate(table a rows=1)*/
                                         column_value
                                          FROM TABLE(i_tbl_id_pk) a)
                 ORDER BY t.rn;
            ELSIF i_root_name IN (pk_orders_constant.g_ds_follow_up_case_management,
                                  pk_orders_constant.g_ds_follow_up_cdc,
                                  pk_orders_constant.g_ds_follow_up_mental,
                                  pk_orders_constant.g_ds_follow_up_diet,
                                  pk_orders_constant.g_ds_follow_up_psy,
                                  pk_orders_constant.g_ds_follow_up_rehab_occupational,
                                  pk_orders_constant.g_ds_follow_up_rehab_physical,
                                  pk_orders_constant.g_ds_follow_up_rehab_speech,
                                  pk_orders_constant.g_ds_follow_up_religious,
                                  pk_orders_constant.g_ds_follow_up_social_original,
                                  pk_orders_constant.g_ds_follow_up_activity_therapist)
            THEN
                IF i_action IS NULL
                   OR i_action = -1
                THEN
                    SELECT COUNT(1)
                      INTO l_count_clinical_services
                      FROM opinion_type_clin_serv otcs
                      JOIN clinical_service cs
                        ON otcs.id_clinical_service = cs.id_clinical_service
                     WHERE otcs.id_opinion_type = i_tbl_id_pk(1)
                       AND otcs.id_software IN (0, i_prof.software)
                       AND otcs.id_institution IN (0, i_prof.institution)
                       AND otcs.flg_available = pk_alert_constant.g_yes
                       AND cs.flg_available = pk_alert_constant.g_yes;
                
                    g_error := 'SELECT INTO TBL_RESULT';
                    SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                               id_ds_component    => t.id_ds_component_child,
                                               internal_name      => t.internal_name_child,
                                               VALUE              => CASE
                                                                         WHEN t.internal_name_child = pk_orders_constant.g_ds_dummy_number THEN
                                                                          to_char(i_tbl_id_pk(1))
                                                                         ELSE
                                                                          NULL
                                                                     END,
                                               value_clob         => NULL,
                                               min_value          => NULL,
                                               max_value          => NULL,
                                               desc_value         => NULL,
                                               desc_clob          => NULL,
                                               id_unit_measure    => NULL,
                                               desc_unit_measure  => NULL,
                                               flg_validation     => pk_orders_constant.g_component_valid,
                                               err_msg            => NULL,
                                               flg_event_type     => coalesce(def.flg_event_type,
                                                                              CASE
                                                                                  WHEN t.internal_name_child = pk_orders_constant.g_ds_clinical_service THEN
                                                                                   decode(l_count_clinical_services,
                                                                                          0,
                                                                                          pk_orders_constant.g_component_hidden,
                                                                                          pk_orders_constant.g_component_mandatory)
                                                                                  WHEN t.internal_name_child = pk_orders_constant.g_ds_professional THEN
                                                                                   decode(l_count_clinical_services,
                                                                                          0,
                                                                                          pk_orders_constant.g_component_mandatory,
                                                                                          pk_orders_constant.g_component_inactive)
                                                                                  WHEN t.internal_name_child = pk_orders_constant.g_ds_clinical_indication_mw THEN
                                                                                   decode(l_search,
                                                                                          pk_alert_constant.g_yes,
                                                                                          pk_orders_constant.g_component_active,
                                                                                          pk_orders_constant.g_component_hidden)
                                                                                  WHEN t.internal_name_child = pk_orders_constant.g_ds_req_reason_no_permission THEN
                                                                                   decode(l_search,
                                                                                          pk_alert_constant.g_no,
                                                                                          pk_orders_constant.g_component_active,
                                                                                          pk_orders_constant.g_component_hidden)
                                                                                  ELSE
                                                                                   pk_orders_constant.g_component_active
                                                                              END),
                                               flg_multi_status   => pk_alert_constant.g_no,
                                               idx                => 1)
                      BULK COLLECT
                      INTO tbl_result
                      FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                                   dc.id_ds_component_child,
                                   dc.internal_name_child,
                                   dc.flg_event_type,
                                   dc.rn,
                                   dc.flg_component_type_child,
                                   dc.id_unit_measure
                              FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_patient        => NULL,
                                                                 i_component_name => i_root_name,
                                                                 i_action         => NULL)) dc) t
                      JOIN ds_component d
                        ON d.id_ds_component = t.id_ds_component_child
                      LEFT JOIN ds_def_event def
                        ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
                     WHERE d.internal_name IN (pk_orders_constant.g_ds_clinical_service,
                                               pk_orders_constant.g_ds_professional,
                                               pk_orders_constant.g_ds_dummy_number,
                                               pk_orders_constant.g_ds_clinical_indication_mw,
                                               pk_orders_constant.g_ds_req_reason_no_permission)
                     ORDER BY t.rn;
                ELSIF i_action = pk_dyn_form_constant.get_submit_action()
                THEN
                    IF i_curr_component IS NOT NULL
                    THEN
                        --Check which element has been changed
                        SELECT d.internal_name_child
                          INTO l_curr_comp_int_name
                          FROM ds_cmpt_mkt_rel d
                         WHERE d.id_ds_cmpt_mkt_rel = i_curr_component;
                    
                        IF l_curr_comp_int_name = pk_orders_constant.g_ds_clinical_service
                        THEN
                            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                IF i_tbl_int_name(i) = pk_orders_constant.g_ds_clinical_service
                                THEN
                                    l_id_clinical_service := to_number(i_value(i) (1));
                                    EXIT;
                                END IF;
                            END LOOP;
                        
                            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                            LOOP
                                IF i_tbl_int_name(i) = pk_orders_constant.g_ds_professional
                                THEN
                                    tbl_result.extend();
                                    tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                       id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                                       internal_name      => i_tbl_int_name(i),
                                                                                       VALUE              => NULL,
                                                                                       value_clob         => NULL,
                                                                                       min_value          => NULL,
                                                                                       max_value          => NULL,
                                                                                       desc_value         => NULL,
                                                                                       desc_clob          => NULL,
                                                                                       id_unit_measure    => NULL,
                                                                                       desc_unit_measure  => NULL,
                                                                                       flg_validation     => pk_alert_constant.g_yes,
                                                                                       err_msg            => NULL,
                                                                                       flg_event_type     => CASE
                                                                                                                 WHEN l_id_clinical_service IS NULL THEN
                                                                                                                  pk_orders_constant.g_component_inactive
                                                                                                                 ELSE
                                                                                                                  pk_orders_constant.g_component_mandatory
                                                                                                             END,
                                                                                       flg_multi_status   => NULL,
                                                                                       idx                => 1);
                                    EXIT;
                                END IF;
                            END LOOP;
                        END IF;
                    END IF;
                ELSE
                    --EDITION
                    SELECT COUNT(1)
                      INTO l_count_clinical_services
                      FROM opinion o
                      JOIN opinion_type_clin_serv otcs
                        ON o.id_opinion_type = otcs.id_opinion_type
                      JOIN clinical_service cs
                        ON otcs.id_clinical_service = cs.id_clinical_service
                     WHERE o.id_opinion = i_tbl_id_pk(1)
                       AND otcs.id_software IN (0, i_prof.software)
                       AND otcs.id_institution IN (0, i_prof.institution)
                       AND otcs.flg_available = pk_alert_constant.g_yes
                       AND cs.flg_available = pk_alert_constant.g_yes;
                
                    --The function is called 'get_cm_req_reason', but the coded diagnosis are now available
                    --for all opinion types. (Except for HHC social worker request)
                    g_error := 'CALL get_cm_req_reason';
                    get_cm_req_reason(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_opinion            => i_tbl_id_pk(1),
                                      o_id_diagnosis       => l_id_diagnosis,
                                      o_id_alert_diagnosis => l_tbl_alert_diagnosis,
                                      o_diagnosis          => l_diagnosis);
                
                    SELECT op.id_opinion_type,
                           op.id_clinical_service,
                           pk_translation.get_translation(i_lang, l_code_cs || op.id_clinical_service),
                           op.desc_problem,
                           nvl(op.id_prof_questioned, g_any_prof),
                           decode(op.id_prof_questioned,
                                  NULL,
                                  pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021'),
                                  pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_prof_questioned)),
                           op.notes
                      INTO l_id_opinion_type,
                           l_id_clinical_service,
                           l_clinical_service_desc,
                           l_reason_ft,
                           l_id_prof,
                           l_prof_desc,
                           l_notes
                      FROM opinion op
                     WHERE op.id_opinion = i_tbl_id_pk(1);
                
                    FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                    LOOP
                        l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i));
                    
                        IF l_ds_internal_name = pk_orders_constant.g_ds_dummy_number
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => to_char(l_id_opinion_type),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_clinical_service
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => to_char(l_id_clinical_service),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_clinical_service_desc,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => CASE
                                                                                                         WHEN l_count_clinical_services = 0 THEN
                                                                                                          pk_orders_constant.g_component_inactive
                                                                                                         ELSE
                                                                                                          pk_orders_constant.g_component_mandatory
                                                                                                     END,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_request_reason_other
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => l_reason_ft,
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_reason_ft,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_professional
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => to_char(l_id_prof),
                                                                               value_clob         => NULL,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => l_prof_desc,
                                                                               desc_clob          => NULL,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_mandatory,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_notes_clob
                        THEN
                            tbl_result.extend();
                            tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                               id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                               internal_name      => l_ds_internal_name,
                                                                               VALUE              => NULL,
                                                                               value_clob         => l_notes,
                                                                               min_value          => NULL,
                                                                               max_value          => NULL,
                                                                               desc_value         => NULL,
                                                                               desc_clob          => l_notes,
                                                                               id_unit_measure    => NULL,
                                                                               desc_unit_measure  => NULL,
                                                                               flg_validation     => pk_alert_constant.g_yes,
                                                                               err_msg            => NULL,
                                                                               flg_event_type     => pk_orders_constant.g_component_active,
                                                                               flg_multi_status   => NULL,
                                                                               idx                => 1);
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_clinical_indication_mw
                        THEN
                            IF l_search = pk_alert_constant.g_yes
                            THEN
                                IF l_tbl_alert_diagnosis.exists(1)
                                THEN
                                    FOR j IN l_tbl_alert_diagnosis.first .. l_tbl_alert_diagnosis.last
                                    LOOP
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                           id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                                           internal_name      => l_ds_internal_name,
                                                                                           VALUE              => to_char(l_tbl_alert_diagnosis(j)),
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => l_diagnosis(j),
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => 1);
                                    END LOOP;
                                END IF;
                            ELSE
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => NULL,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_hidden,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => 1);
                            END IF;
                        ELSIF l_ds_internal_name = pk_orders_constant.g_ds_req_reason_no_permission
                        THEN
                            IF l_search = pk_alert_constant.g_no
                            THEN
                                IF l_tbl_alert_diagnosis.exists(1)
                                THEN
                                    FOR j IN l_tbl_alert_diagnosis.first .. l_tbl_alert_diagnosis.last
                                    LOOP
                                        tbl_result.extend();
                                        tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                           id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                                           internal_name      => l_ds_internal_name,
                                                                                           VALUE              => to_char(l_tbl_alert_diagnosis(j)),
                                                                                           value_clob         => NULL,
                                                                                           min_value          => NULL,
                                                                                           max_value          => NULL,
                                                                                           desc_value         => l_diagnosis(j),
                                                                                           desc_clob          => NULL,
                                                                                           id_unit_measure    => NULL,
                                                                                           desc_unit_measure  => NULL,
                                                                                           flg_validation     => pk_alert_constant.g_yes,
                                                                                           err_msg            => NULL,
                                                                                           flg_event_type     => pk_orders_constant.g_component_active,
                                                                                           flg_multi_status   => NULL,
                                                                                           idx                => 1);
                                    END LOOP;
                                END IF;
                            ELSE
                                tbl_result.extend();
                                tbl_result(tbl_result.count) := t_rec_ds_get_value(id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i),
                                                                                   id_ds_component    => pk_orders_utils.get_id_ds_component(i_id_ds_cmpt_mkt_rel => i_tbl_mkt_rel(i)),
                                                                                   internal_name      => l_ds_internal_name,
                                                                                   VALUE              => NULL,
                                                                                   value_clob         => NULL,
                                                                                   min_value          => NULL,
                                                                                   max_value          => NULL,
                                                                                   desc_value         => NULL,
                                                                                   desc_clob          => NULL,
                                                                                   id_unit_measure    => NULL,
                                                                                   desc_unit_measure  => NULL,
                                                                                   flg_validation     => pk_alert_constant.g_yes,
                                                                                   err_msg            => NULL,
                                                                                   flg_event_type     => pk_orders_constant.g_component_hidden,
                                                                                   flg_multi_status   => NULL,
                                                                                   idx                => 1);
                            END IF;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_consult_request_values;

    FUNCTION get_ds_elements
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_opinion_type        IN opinion_type.id_opinion_type%TYPE,
        i_tbl_ds_cmpt_mkt_rel IN table_number
    ) RETURN tbl_consult_ds IS
        l_ret tbl_consult_ds := tbl_consult_ds();
    BEGIN
    
        SELECT t_consult_ds(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                            id_ds_component    => t.id_ds_component,
                            internal_name      => t.internal_name,
                            flg_data_type      => t.flg_data_type)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT dscm.id_ds_cmpt_mkt_rel, dscp.id_ds_component, dscp.internal_name, dscp.flg_data_type
                  FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                               dc.id_ds_component_child,
                               dc.internal_name_child,
                               dc.flg_event_type,
                               dc.rn
                          FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_patient        => NULL,
                                                             i_component_name => decode(i_opinion_type,
                                                                                        g_ot_social_worker_ds,
                                                                                        g_ds_root_social_worker),
                                                             i_action         => NULL)) dc) dscm
                  JOIN ds_component dscp
                    ON dscp.id_ds_component = dscm.id_ds_component_child) t
          JOIN TABLE(i_tbl_ds_cmpt_mkt_rel) r
            ON r.column_value = t.id_ds_cmpt_mkt_rel;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN l_ret;
        
    END get_ds_elements;

    /*
    * Set request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_patient        patient identifier
    * @param i_opinion        opinion identifier
    * @param i_opinion_type   opinion type identifier
    * @param i_clin_serv      clinical service identifier
    * @param i_reason_ft      request reason (free text)
    * @param i_reason_mc      request reason (multichoice)
    * @param i_prof_id        questioned professional identifier
    * @param i_notes          request notes
    * @param i_do_commit      perform commit inside this function
    * @param o_opinion        created opinion identifier
    * @param o_opinion_hist   created opinion history identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */

    FUNCTION set_consult_request
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_opinion             IN opinion.id_opinion%TYPE,
        i_opinion_type        IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv           IN opinion.id_clinical_service%TYPE,
        i_reason_ft           IN opinion.desc_problem%TYPE,
        i_reason_mc           IN table_number,
        i_tbl_alert_diagnosis IN table_number,
        i_reason_mc_desc      IN table_varchar DEFAULT NULL,
        i_prof_id             IN opinion.id_prof_questioned%TYPE,
        i_notes               IN opinion.notes%TYPE,
        i_do_commit           IN VARCHAR2,
        i_followup_auto       IN VARCHAR2,
        i_dt_problem          IN TIMESTAMP DEFAULT NULL,
        i_tbl_ds_cmpt_mkt_rel IN table_number DEFAULT NULL,
        i_tbl_val             IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob        IN table_clob DEFAULT NULL,
        o_opinion             OUT opinion.id_opinion%TYPE,
        o_opinion_hist        OUT opinion_hist.id_opinion_hist%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_opinion        opinion.id_opinion%TYPE;
        l_opinion_hist   opinion_hist.id_opinion_hist%TYPE;
        l_flg_approve    opinion_type_prof.flg_approve%TYPE;
        l_episode        episode.id_episode%TYPE := NULL;
        l_rows           table_varchar := table_varchar();
        l_prof_ids       table_number := table_number();
        l_opinion_status opinion.flg_state%TYPE;
    
        l_error_in t_error_in := t_error_in();
        l_ret      BOOLEAN;
    
        tbl_ds_struct        tbl_consult_ds;
        l_id_prof_questioned professional.id_professional%TYPE := NULL;
        l_notes              opinion.notes%TYPE;
        l_config_create_note sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'FOLLOW_UP_REQUEST_CREATE_NOTE',
                                                                              i_prof    => i_prof);
        l_id_epis_pn         epis_pn.id_epis_pn%TYPE;
    
        FUNCTION check_has_content
        (
            i_tbl_val_desc  IN table_varchar DEFAULT NULL,
            i_val_clob_desc IN CLOB DEFAULT NULL
        ) RETURN BOOLEAN IS
        BEGIN
        
            IF i_tbl_val_desc.exists(1)
            THEN
                IF i_tbl_val_desc(1) <> ''
                   OR i_tbl_val_desc.count > 1 --UX does not allways send the value on the first element of the array
                THEN
                    RETURN TRUE;
                END IF;
            END IF;
        
            IF i_val_clob_desc <> ''
            THEN
                RETURN TRUE;
            END IF;
        
            RETURN FALSE;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END;
    
        --Function to obtain the description of the reasons and equipment needed for the selected opinion.
        --The result is a concatenation of a string to be stored in opinion.desc_problem.
        FUNCTION get_reason_desc RETURN VARCHAR2 IS
            l_ret VARCHAR2(4000) := NULL;
        
            l_flg_data_type      ds_component.flg_data_type%TYPE;
            l_code_domain        ds_component.code_domain%TYPE;
            l_internal_name      ds_component.internal_name%TYPE;
            l_tbl_internal_names table_varchar := table_varchar(g_ds_reason,
                                                                g_ds_reason_ft,
                                                                g_ds_equipment_needed,
                                                                g_ds_equipment_needed_ft);
        
            l_tbl_int_names_reason table_varchar := table_varchar(g_ds_reason, g_ds_reason_ft);
            l_flg_show_reason_tag  BOOLEAN := TRUE;
        
            l_tbl_int_names_equipment table_varchar := table_varchar(g_ds_equipment_needed, g_ds_equipment_needed_ft);
            l_flg_show_equipment_tag  BOOLEAN := TRUE;
        
            l_tbl_val table_varchar;
        
        BEGIN
        
            FOR i IN i_tbl_ds_cmpt_mkt_rel.first .. i_tbl_ds_cmpt_mkt_rel.last
            LOOP
                --Cycle through all the given components. Only the components regarding the "reason for request"
                --and "equipment needed" should be stored in opinion.desc_problem.
                BEGIN
                    SELECT dc.internal_name, dc.flg_data_type, dc.code_domain
                      INTO l_internal_name, l_flg_data_type, l_code_domain
                      FROM ds_cmpt_mkt_rel d
                      JOIN ds_component dc
                        ON dc.id_ds_component = d.id_ds_component_child
                      JOIN (SELECT /*+opt_estimate(table a rows=1)*/
                             column_value
                              FROM TABLE(l_tbl_internal_names) a) t
                        ON t.column_value = dc.internal_name
                     WHERE d.id_ds_cmpt_mkt_rel = i_tbl_ds_cmpt_mkt_rel(i);
                
                    --Check if it is necessaray to add the tag 'Reason(s)' or 'Equipment needed'
                    IF l_flg_show_reason_tag = TRUE
                    THEN
                        FOR x IN l_tbl_int_names_reason.first .. l_tbl_int_names_reason.last
                        LOOP
                            IF l_internal_name = l_tbl_int_names_reason(x)
                            THEN
                                l_ret                 := l_ret ||
                                                         pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'OPINION_T027') || ' ';
                                l_flg_show_reason_tag := FALSE; --After the first insertion, it is no longer needed to add it.
                            END IF;
                        END LOOP;
                    END IF;
                
                    IF l_flg_show_equipment_tag = TRUE
                    THEN
                        FOR x IN l_tbl_int_names_equipment.first .. l_tbl_int_names_equipment.last
                        LOOP
                            IF l_internal_name = l_tbl_int_names_equipment(x)
                            THEN
                                IF check_has_content(i_tbl_val(i), i_tbl_val_clob(i))
                                THEN
                                    l_ret                    := l_ret ||
                                                                pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'OPINION_T028') || ' ';
                                    l_flg_show_equipment_tag := FALSE;
                                END IF;
                            END IF;
                        END LOOP;
                    END IF;
                
                    --Add the description given in i_tbl_val and/or i_tbl_val_clob
                    IF l_flg_data_type <> g_ds_clob_type
                    THEN
                        --It s necessary to re-order the values, because when editing the form,
                        --the UX changes the order of the values, and the 'Other' value is sent in the begining of the array
                        l_tbl_val := table_varchar();
                        SELECT tt.*
                          BULK COLLECT
                          INTO l_tbl_val
                          FROM (SELECT /*+opt_estimate(table t rows=1)*/
                                 column_value
                                  FROM TABLE(i_tbl_val(i)) t
                                 WHERE t.column_value IS NOT NULL --UX is sending null values in the middle of the array
                                 ORDER BY 1) tt;
                    
                        IF l_tbl_val.exists(1)
                        THEN
                            FOR j IN l_tbl_val.first .. l_tbl_val.last
                            LOOP
                                l_ret := l_ret || pk_opinion.get_detail_description(i_lang,
                                                                                    i_prof,
                                                                                    l_flg_data_type,
                                                                                    l_internal_name,
                                                                                    l_code_domain,
                                                                                    l_tbl_val(j)) || CASE
                                             WHEN l_tbl_val(j) = 'O' THEN
                                              ': '
                                             WHEN j = l_tbl_val.last THEN
                                              '. '
                                             ELSE
                                              '; '
                                         END;
                            END LOOP;
                        END IF;
                    ELSE
                        IF to_char(i_tbl_val_clob(i)) IS NOT NULL
                        THEN
                            l_ret := l_ret ||
                                     pk_opinion.get_detail_description(i_lang,
                                                                       i_prof,
                                                                       l_flg_data_type,
                                                                       l_internal_name,
                                                                       l_code_domain,
                                                                       to_char(i_tbl_val_clob(i)) || '. ');
                        END IF;
                    END IF;
                
                    l_flg_data_type := NULL;
                    l_code_domain   := NULL;
                    l_internal_name := NULL;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_flg_data_type := NULL;
                        l_code_domain   := NULL;
                        l_internal_name := NULL;
                        CONTINUE;
                END;
            END LOOP;
        
            RETURN l_ret;
        END get_reason_desc;
    
        FUNCTION get_prof_id RETURN professional.id_professional%TYPE IS
        
            l_id_ds_cmpt_mkt_rel ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := NULL;
            l_pos                NUMBER := NULL;
            l_ret                professional.id_professional%TYPE := NULL;
        BEGIN
            BEGIN
                --Obtain the id_ds_cmpt_mkt_rel that referes to the professional list
                SELECT /*+opt_estimate(table t rows=1)*/
                 t.id_ds_cmpt_mkt_rel
                  INTO l_id_ds_cmpt_mkt_rel
                  FROM TABLE(tbl_ds_struct) t
                 WHERE t.internal_name = g_ds_prof_list;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_ds_cmpt_mkt_rel := NULL;
            END;
        
            IF l_id_ds_cmpt_mkt_rel IS NOT NULL
            THEN
                --Obtain the position of the professional id in the i_tbl_ds_cmpt_mkt_rel array
                BEGIN
                    SELECT t.rn
                      INTO l_pos
                      FROM (SELECT /*+opt_estimate(table a rows=1)*/
                             a.column_value, rownum AS rn
                              FROM TABLE(i_tbl_ds_cmpt_mkt_rel) a) t
                     WHERE t.column_value = l_id_ds_cmpt_mkt_rel;
                
                    l_ret := i_tbl_val(l_pos) (1);
                
                EXCEPTION
                    WHEN OTHERS THEN
                        l_ret := NULL;
                END;
            END IF;
        
            RETURN l_ret;
        END get_prof_id;
    
        FUNCTION get_notes RETURN CLOB IS
            l_id_ds_cmpt_mkt_rel ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE := NULL;
            l_pos                NUMBER := NULL;
            l_ret                CLOB := NULL;
        BEGIN
            BEGIN
                SELECT /*+opt_estimate(table t rows=1)*/
                 t.id_ds_cmpt_mkt_rel
                  INTO l_id_ds_cmpt_mkt_rel
                  FROM TABLE(tbl_ds_struct) t
                 WHERE t.internal_name = g_ds_notes;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_ds_cmpt_mkt_rel := NULL;
            END;
        
            IF l_id_ds_cmpt_mkt_rel IS NOT NULL
            THEN
                BEGIN
                    SELECT t.rn
                      INTO l_pos
                      FROM (SELECT /*+opt_estimate(table a rows=1)*/
                             column_value, rownum AS rn
                              FROM TABLE(i_tbl_ds_cmpt_mkt_rel) a) t
                     WHERE t.column_value = l_id_ds_cmpt_mkt_rel;
                
                    l_ret := i_tbl_val_clob(l_pos);
                EXCEPTION
                    WHEN OTHERS THEN
                        l_ret := NULL;
                END;
            END IF;
            RETURN l_ret;
        END get_notes;
    
        FUNCTION set_opinion_ds RETURN BOOLEAN IS
            l_flg_type        ds_component.flg_data_type%TYPE;
            l_rows_opinion_ds table_varchar := table_varchar();
        BEGIN
        
            FOR i IN i_tbl_ds_cmpt_mkt_rel.first .. i_tbl_ds_cmpt_mkt_rel.last
            LOOP
            
                SELECT /*+opt_estimate(table t rows=1)*/
                 t.flg_data_type
                  INTO l_flg_type
                  FROM TABLE(tbl_ds_struct) t
                 WHERE t.id_ds_cmpt_mkt_rel = i_tbl_ds_cmpt_mkt_rel(i);
            
                FOR j IN i_tbl_val(i).first .. i_tbl_val(i).last
                LOOP
                    IF i_tbl_val(i) (j) IS NOT NULL
                       OR i_tbl_val_clob(i) IS NOT NULL
                    THEN
                        ts_opinion_ds.ins(id_opinion_ds_in      => seq_opinion_ds.nextval,
                                          id_opinion_in         => l_opinion,
                                          dt_problem_tstz_in    => nvl(i_dt_problem, g_sysdate_tstz),
                                          id_ds_cmpt_mkt_rel_in => i_tbl_ds_cmpt_mkt_rel(i),
                                          value_in              => CASE
                                                                       WHEN l_flg_type NOT IN ( /*g_ds_free_text_type,*/ g_ds_clob_type) THEN
                                                                        i_tbl_val(i) (j)
                                                                       ELSE
                                                                        NULL
                                                                   END,
                                          value_clob_in         => CASE
                                                                   --   WHEN l_flg_type = g_ds_free_text_type THEN
                                                                   --  null -- i_tbl_val(i) (j)
                                                                       WHEN l_flg_type = g_ds_clob_type THEN
                                                                        i_tbl_val_clob(i)
                                                                       ELSE
                                                                        NULL
                                                                   END,
                                          rows_out              => l_rows_opinion_ds);
                    END IF;
                END LOOP;
            END LOOP;
        
            RETURN TRUE;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END set_opinion_ds;
    
    BEGIN
        g_sysdate_tstz   := current_timestamp;
        l_opinion        := i_opinion;
        g_error          := 'CALL check_approval_need';
        l_flg_approve    := check_approval_need(i_prof => i_prof, i_opinion_type => i_opinion_type);
        l_opinion_status := g_opinion_req;
    
        IF l_flg_approve = pk_alert_constant.g_yes
        THEN
            -- when approval is needed, send alert to approving professional
            g_error    := 'CALL get_edis_inp_episode';
            l_episode  := nvl(i_episode,
                              get_edis_inp_episode(i_prof => i_prof, i_patient => i_patient, i_id_episode => i_episode));
            g_error    := 'CALL get_approvers_list';
            l_prof_ids := get_approvers_list(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_patient => i_patient,
                                             i_episode => l_episode);
        
            IF pk_utils.search_table_number(i_table => l_prof_ids, i_search => i_prof.id) > 0
            THEN
                l_opinion_status := g_opinion_approved;
                l_flg_approve    := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        IF l_opinion IS NULL
        THEN
            IF i_tbl_ds_cmpt_mkt_rel.exists(1)
            THEN
                --When i_tbl_ds_cmpt_mkt_rel is sent with values, it means we are dealing with a dynamic form
                --Therefore, it is necessary to obtain the structure of the elements that were documented.
                tbl_ds_struct := get_ds_elements(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_episode             => i_episode,
                                                 i_opinion_type        => i_opinion_type,
                                                 i_tbl_ds_cmpt_mkt_rel => i_tbl_ds_cmpt_mkt_rel);
            
                --Obtain the id_professional set through the dynamic form
                --in order to populate opinion.id_prof_questioned
                --(The professional id is sent in i_tbl_val array)                
                l_id_prof_questioned := get_prof_id;
            
                --Obtain the notes saved through dynamic screen in order to be stored in opinion.notes
                --(notes are always sent in i_tbl_val_clob array)                
                l_notes := get_notes;
            
                -- creating a new record
                g_error := 'CALL ts_opinion.ins';
                ts_opinion.ins(id_episode_in          => i_episode,
                               flg_state_in           => l_opinion_status,
                               desc_problem_in        => get_reason_desc,
                               id_prof_questions_in   => i_prof.id,
                               id_prof_questioned_in  => CASE
                                                             WHEN l_id_prof_questioned = g_any_prof THEN
                                                              NULL
                                                             ELSE
                                                              l_id_prof_questioned
                                                         END,
                               dt_problem_tstz_in     => nvl(i_dt_problem, g_sysdate_tstz),
                               id_patient_in          => i_patient,
                               dt_last_update_in      => g_sysdate_tstz,
                               id_opinion_type_in     => i_opinion_type,
                               id_clinical_service_in => i_clin_serv,
                               notes_in               => l_notes,
                               id_episode_approval_in => l_episode,
                               id_opinion_out         => l_opinion,
                               flg_auto_follow_up_in  => i_followup_auto,
                               handle_error_in        => FALSE,
                               rows_out               => l_rows);
            
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'OPINION',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
                pk_ia_event_common.opinion_order_new(i_id_opinion => l_opinion, i_id_episode => i_episode);
            
                --Inserting new records in opinion_ds, which refers to the dynamic elements registered for this opinion            
                IF NOT set_opinion_ds
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
            
                -- creating a new record
                g_error := 'CALL ts_opinion.ins';
                ts_opinion.ins(id_episode_in          => i_episode,
                               flg_state_in           => l_opinion_status,
                               desc_problem_in        => i_reason_ft,
                               id_prof_questions_in   => i_prof.id,
                               id_prof_questioned_in  => CASE
                                                             WHEN i_prof_id = g_any_prof THEN
                                                              NULL
                                                             ELSE
                                                              i_prof_id
                                                         END,
                               dt_problem_tstz_in     => nvl(i_dt_problem, g_sysdate_tstz),
                               id_patient_in          => i_patient,
                               dt_last_update_in      => g_sysdate_tstz,
                               id_opinion_type_in     => i_opinion_type,
                               id_clinical_service_in => i_clin_serv,
                               notes_in               => i_notes,
                               id_episode_approval_in => l_episode,
                               id_opinion_out         => l_opinion,
                               flg_auto_follow_up_in  => i_followup_auto,
                               rows_out               => l_rows);
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'OPINION',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
                pk_ia_event_common.opinion_order_new(i_id_opinion => l_opinion, i_id_episode => i_episode);
            END IF;
        ELSE
            -- editing an existing record
            -- validate edition
            -- get id_epis_pn
            IF l_config_create_note = pk_alert_constant.g_yes
            THEN
                l_id_epis_pn := get_id_epis_pn(l_opinion, i_opinion_type, i_episode, NULL);
            END IF;
            g_error := 'CALL validate_prof';
            IF NOT validate_prof(i_lang    => i_lang,
                                 i_prof    => i_prof,
                                 i_opinion => l_opinion,
                                 i_state   => g_opinion_req,
                                 o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
            -- delete existant alert
            g_error := 'CALL pk_alerts.delete_sys_alert_event';
            IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                               i_prof         => i_prof,
                                               i_id_sys_alert => CASE
                                                                     WHEN l_flg_approve = pk_alert_constant.g_yes THEN
                                                                      g_alert_needs_approval
                                                                     ELSE
                                                                      g_alert_needs_acceptance
                                                                 END,
                                               i_id_record    => l_opinion,
                                               o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF i_tbl_ds_cmpt_mkt_rel.exists(1)
            THEN
                --When i_tbl_ds_cmpt_mkt_rel is sent with values, it means we are dealing with a dynamic form
                --Therefore, it is necessary to obtain the structure of the elements that were documented.
                tbl_ds_struct := get_ds_elements(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_episode             => i_episode,
                                                 i_opinion_type        => i_opinion_type,
                                                 i_tbl_ds_cmpt_mkt_rel => i_tbl_ds_cmpt_mkt_rel);
            
                --Obtain the id_professional set through the dynamic form
                --in order to populate opinion.id_prof_questioned
                --(The professional id is sent in i_tbl_val array)                
                l_id_prof_questioned := get_prof_id;
            
                --Obtain the notes saved through dynamic screen in order to be stored in opinion.notes
                --(notes are always sent in i_tbl_val_clob array)                
                l_notes := get_notes;
            
                -- update record
                g_error := 'CALL ts_opinion.upd';
                ts_opinion.upd(id_opinion_in           => l_opinion,
                               desc_problem_in         => get_reason_desc,
                               desc_problem_nin        => FALSE,
                               id_prof_questioned_in   => CASE
                                                              WHEN l_id_prof_questioned = g_any_prof THEN
                                                               NULL
                                                              ELSE
                                                               l_id_prof_questioned
                                                          END,
                               id_prof_questioned_nin  => FALSE,
                               dt_last_update_in       => g_sysdate_tstz,
                               dt_last_update_nin      => FALSE,
                               id_clinical_service_in  => i_clin_serv,
                               id_clinical_service_nin => FALSE,
                               notes_in                => l_notes,
                               notes_nin               => FALSE,
                               rows_out                => l_rows);
            
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'OPINION',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('DESC_PROBLEM',
                                                                              'ID_PROF_QUESTIONED',
                                                                              'DT_LAST_UPDATE',
                                                                              'ID_CLINICAL_SERVICE',
                                                                              'NOTES'));
                pk_ia_event_common.opinion_order_update(i_id_opinion => l_opinion, i_id_episode => i_episode);
            
                --Inserting new records in opinion_ds, which refers to the dynamic elements registered for this opinion            
                IF NOT set_opinion_ds
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                -- update record
                g_error := 'CALL ts_opinion.upd';
                ts_opinion.upd(id_opinion_in           => l_opinion,
                               desc_problem_in         => i_reason_ft,
                               desc_problem_nin        => FALSE,
                               id_prof_questioned_in   => CASE
                                                              WHEN i_prof_id = g_any_prof THEN
                                                               NULL
                                                              ELSE
                                                               i_prof_id
                                                          END,
                               id_prof_questioned_nin  => FALSE,
                               dt_last_update_in       => g_sysdate_tstz,
                               dt_last_update_nin      => FALSE,
                               id_clinical_service_in  => i_clin_serv,
                               id_clinical_service_nin => FALSE,
                               notes_in                => i_notes,
                               notes_nin               => FALSE,
                               rows_out                => l_rows);
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'OPINION',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('DESC_PROBLEM',
                                                                              'ID_PROF_QUESTIONED',
                                                                              'DT_LAST_UPDATE',
                                                                              'ID_CLINICAL_SERVICE',
                                                                              'NOTES'));
                pk_ia_event_common.opinion_order_update(i_id_opinion => l_opinion, i_id_episode => i_episode);
            END IF;
        END IF;
    
        -- set opinion reasons
        g_error := 'CALL set_opinion_reason';
        set_opinion_reason(i_lang                => i_lang,
                           i_prof                => i_prof,
                           i_patient             => i_patient,
                           i_episode             => i_episode,
                           i_opinion             => l_opinion,
                           i_reasons             => i_reason_mc,
                           i_tbl_alert_diagnosis => i_tbl_alert_diagnosis,
                           i_reasons_desc        => i_reason_mc_desc);
    
        -- set opinion history
        g_error := 'CALL set_opinion_hist';
        set_opinion_hist(i_lang => i_lang, i_prof => i_prof, i_opinion => l_opinion, o_opinion_hist => l_opinion_hist);
        -- set opinion reasons history
        g_error := 'CALL set_opinion_reason_hist';
        set_opinion_reason_hist(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_opinion      => l_opinion,
                                i_opinion_hist => l_opinion_hist);
    
        -- create alerts
        IF l_flg_approve = pk_alert_constant.g_yes
        THEN
            IF l_prof_ids IS NULL
               OR l_prof_ids.first IS NULL
               OR l_prof_ids(l_prof_ids.first) IS NULL
            THEN
                g_error := 'no responsible exists!';
            
                l_error_in.set_all(i_id_lang       => i_lang,
                                   i_sqlcode       => NULL,
                                   i_sqlerrm       => pk_message.get_message(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_code_mess => 'OPINION_M010'),
                                   i_user_err      => g_error,
                                   i_owner         => g_package_owner,
                                   i_pck_name      => g_package_name,
                                   i_function_name => 'SET_CONSULT_REQUEST',
                                   i_action        => NULL,
                                   i_flg_action    => 'U',
                                   i_msg_title     => pk_message.get_message(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_code_mess => 'OPINION_M011'));
                l_ret := pk_alert_exceptions.process_error(i_error_in => l_error_in, i_error_out => o_error);
            
                RAISE g_exception;
            END IF;
        
            IF (i_followup_auto <> pk_alert_constant.g_yes)
            THEN
                g_error := 'CALL pk_alerts.insert_sys_alert_event for approval';
                IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_sys_alert           => g_alert_needs_approval,
                                                        i_id_episode          => l_episode,
                                                        i_id_record           => l_opinion,
                                                        i_dt_record           => nvl(i_dt_problem, g_sysdate_tstz),
                                                        i_id_professional     => l_prof_ids(1),
                                                        i_id_room             => NULL,
                                                        i_id_clinical_service => NULL,
                                                        i_flg_type_dest       => NULL,
                                                        i_replace1            => NULL,
                                                        o_error               => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        ELSE
            -- otherwise, when acceptance is needed, send alert to "questioned" professional
            g_error := 'CALL pk_alerts.insert_sys_alert_event for acceptance';
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_sys_alert           => g_alert_needs_acceptance,
                                               i_id_episode          => i_episode,
                                               i_id_record           => l_opinion,
                                               i_dt_record           => nvl(i_dt_problem, g_sysdate_tstz),
                                               i_id_professional     => CASE
                                                                            WHEN i_prof_id = g_any_prof THEN
                                                                             NULL
                                                                            ELSE
                                                                             i_prof_id
                                                                        END,
                                               i_id_room             => NULL,
                                               i_id_clinical_service => NULL,
                                               i_flg_type_dest       => NULL,
                                               i_replace1            => NULL,
                                               o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        IF l_config_create_note = pk_alert_constant.g_yes
           AND i_followup_auto <> pk_alert_constant.g_yes
        THEN
            IF NOT set_follow_up_note(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_id_episode      => i_episode,
                                      i_id_opinion      => l_opinion,
                                      i_id_opinion_type => i_opinion_type,
                                      i_sysdate_tstz    => nvl(i_dt_problem, g_sysdate_tstz),
                                      i_id_epis_pn      => l_id_epis_pn,
                                      o_error           => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
            
                RETURN FALSE;
            END IF;
        END IF;
        o_opinion      := l_opinion;
        o_opinion_hist := l_opinion_hist;
    
        IF nvl(i_do_commit, pk_alert_constant.g_yes) = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_CONSULT_REQUEST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_consult_request;

    /*
    * Set request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_patient        patient identifier
    * @param i_opinion        opinion identifier
    * @param i_opinion_type   opinion type identifier
    * @param i_clin_serv      clinical service identifier
    * @param i_reason_ft      request reason (free text)
    * @param i_reason_mc      request reason (multichoice)
    * @param i_prof_id        questioned professional identifier
    * @param i_notes          request notes
    * @param i_do_commit      perform commit inside this function
    * @param o_opinion        created opinion identifier
    * @param o_opinion_hist   created opinion history identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */
    FUNCTION set_consult_request
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv    IN opinion.id_clinical_service%TYPE,
        i_reason_ft    IN opinion.desc_problem%TYPE,
        i_reason_mc    IN table_number,
        i_prof_id      IN opinion.id_prof_questioned%TYPE,
        i_notes        IN opinion.notes%TYPE,
        o_opinion      OUT opinion.id_opinion%TYPE,
        o_opinion_hist OUT opinion_hist.id_opinion_hist%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT set_consult_request(i_lang                => i_lang,
                                   i_prof                => i_prof,
                                   i_episode             => i_episode,
                                   i_patient             => i_patient,
                                   i_opinion             => i_opinion,
                                   i_opinion_type        => i_opinion_type,
                                   i_clin_serv           => i_clin_serv,
                                   i_reason_ft           => i_reason_ft,
                                   i_reason_mc           => i_reason_mc,
                                   i_tbl_alert_diagnosis => NULL,
                                   i_reason_mc_desc      => table_varchar(),
                                   i_prof_id             => i_prof_id,
                                   i_notes               => i_notes,
                                   i_do_commit           => pk_alert_constant.g_yes,
                                   i_followup_auto       => pk_alert_constant.g_no,
                                   i_dt_problem          => NULL,
                                   o_opinion             => o_opinion,
                                   o_opinion_hist        => o_opinion_hist,
                                   o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_CONSULT_REQUEST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_consult_request;

    FUNCTION set_consult_request
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_opinion             IN opinion.id_opinion%TYPE,
        i_opinion_type        IN opinion_type.id_opinion_type%TYPE,
        i_tbl_ds_cmpt_mkt_rel IN table_number,
        i_tbl_val             IN table_table_varchar DEFAULT NULL,
        i_tbl_val_desc        IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob        IN table_clob DEFAULT NULL,
        o_opinion             OUT opinion.id_opinion%TYPE,
        o_opinion_hist        OUT opinion_hist.id_opinion_hist%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_clin_serv        opinion.id_clinical_service%TYPE;
        l_reason_ft           opinion.desc_problem%TYPE;
        l_reason_mc           table_number := table_number();
        l_tbl_alert_diagnosis table_number := table_number();
        l_reason_mc_desc      table_varchar := table_varchar();
        l_prof_id             opinion.id_prof_questioned%TYPE;
        l_notes               opinion.notes%TYPE;
    
        l_ds_internal_name ds_component.internal_name%TYPE;
    
    BEGIN
    
        IF i_opinion_type NOT IN (g_ot_social_worker_ds)
        THEN
            FOR i IN i_tbl_ds_cmpt_mkt_rel.first .. i_tbl_ds_cmpt_mkt_rel.last
            LOOP
                l_ds_internal_name := pk_orders_utils.get_ds_internal_name(i_id_ds_cmpt_mkt_rel => i_tbl_ds_cmpt_mkt_rel(i));
            
                IF l_ds_internal_name = pk_orders_constant.g_ds_clinical_service
                THEN
                    l_id_clin_serv := to_number(i_tbl_val(i) (1));
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_request_reason_other
                THEN
                    l_reason_ft := i_tbl_val(i) (1);
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_professional
                THEN
                    l_prof_id := to_number(i_tbl_val(i) (1));
                ELSIF l_ds_internal_name = pk_orders_constant.g_ds_notes_clob
                THEN
                    l_notes := i_tbl_val_clob(i);
                ELSIF l_ds_internal_name IN
                      (pk_orders_constant.g_ds_clinical_indication_mw, pk_orders_constant.g_ds_req_reason_no_permission)
                THEN
                    --g_ds_clinical_indication_mw is available when the user has permission to document new diagnosis
                    --g_ds_req_reason_no_permission is available when the user DOES NOT HAVE permission to document new diagnosis
                    --They cannot be available at the same time
                    IF i_tbl_val(i).exists(1)
                        AND l_reason_mc.count = 0
                        AND l_tbl_alert_diagnosis.count = 0
                    THEN
                        FOR j IN i_tbl_val(i).first .. i_tbl_val(i).last
                        LOOP
                            IF i_tbl_val(i) (j) IS NOT NULL
                            THEN
                                BEGIN
                                    l_reason_mc.extend();
                                    l_tbl_alert_diagnosis.extend();
                                    l_reason_mc_desc.extend();
                                
                                    SELECT t.id_concept_version, t.id_concept_term
                                      INTO l_reason_mc(l_reason_mc.count),
                                           l_tbl_alert_diagnosis(l_tbl_alert_diagnosis.count)
                                      FROM (SELECT dea.id_concept_version, dea.id_concept_term, rownum AS rn
                                              FROM diagnosis_ea dea
                                             WHERE dea.id_concept_term = to_number(i_tbl_val(i) (j))
                                               AND dea.id_institution IN (0, i_prof.institution)
                                               AND dea.id_software IN (0, i_prof.software)
                                             ORDER BY dea.id_institution DESC, dea.id_software DESC) t
                                     WHERE t.rn = 1;
                                    l_reason_mc_desc(l_reason_mc_desc.count) := i_tbl_val_desc(i) (j);
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        CONTINUE;
                                END;
                            END IF;
                        END LOOP;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        IF NOT set_consult_request(i_lang                => i_lang,
                              i_prof                => i_prof,
                              i_episode             => i_episode,
                              i_patient             => i_patient,
                              i_opinion             => i_opinion,
                              i_opinion_type        => i_opinion_type,
                              i_clin_serv           => l_id_clin_serv,
                              i_reason_ft           => l_reason_ft,
                              i_reason_mc           => l_reason_mc,
                              i_tbl_alert_diagnosis => l_tbl_alert_diagnosis,
                              i_reason_mc_desc      => l_reason_mc_desc,
                              i_prof_id             => l_prof_id,
                              i_notes               => l_notes,
                              i_do_commit           => pk_alert_constant.g_yes,
                              i_followup_auto       => pk_alert_constant.g_no,
                              i_dt_problem          => NULL,
                              i_tbl_ds_cmpt_mkt_rel => CASE
                                                           WHEN i_opinion_type NOT IN (g_ot_social_worker_ds) THEN
                                                            NULL
                                                           ELSE
                                                            i_tbl_ds_cmpt_mkt_rel
                                                       END,
                              i_tbl_val             => CASE
                                                           WHEN i_opinion_type NOT IN (g_ot_social_worker_ds) THEN
                                                            NULL
                                                           ELSE
                                                            i_tbl_val
                                                       END,
                              i_tbl_val_clob        => CASE
                                                           WHEN i_opinion_type NOT IN (g_ot_social_worker_ds) THEN
                                                            NULL
                                                           ELSE
                                                            i_tbl_val_clob
                                                       END,
                              o_opinion             => o_opinion,
                              o_opinion_hist        => o_opinion_hist,
                              o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_CONSULT_REQUEST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_CONSULT_REQUEST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_consult_request;

    /************************************************************************************************************
    * This function cancels the passed opinion
    *
    * @param      i_lang           language identifier
    * @param      i_prof           logged professional structure
    * @param      i_opinion        Id opinion
    * @param      i_opinion_type   opinion type identifier
    * @param      i_notes_cancel   cancel notes
    * @param      i_cancel_reason  Id cancel reason
    * @param      o_error          error
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.6.0.1
    * @since      13-04-2010
    ************************************************************************************************************/
    FUNCTION set_opinion_canceled
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_opinion_type  IN opinion_type.id_opinion_type%TYPE,
        i_notes_cancel  IN opinion.notes_cancel%TYPE,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids       table_varchar;
        l_opinion_hist opinion_hist.id_opinion_hist%TYPE;
        l_flg_approve  opinion_type_prof.flg_approve%TYPE;
    
        CURSOR c_epis IS
            SELECT id_episode
              FROM opinion
             WHERE id_opinion = i_opinion;
        r_epis               c_epis%ROWTYPE;
        l_config_create_note sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'FOLLOW_UP_REQUEST_CREATE_NOTE',
                                                                              i_prof    => i_prof);
        l_id_epis_pn         epis_pn.id_epis_pn%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'CALL check_approval_need';
        l_flg_approve  := check_approval_need(i_prof => i_prof, i_opinion_type => i_opinion_type);
    
        g_error := 'CALL validate_prof';
        IF NOT validate_prof(i_lang    => i_lang,
                             i_prof    => i_prof,
                             i_opinion => i_opinion,
                             i_state   => g_opinion_cancel,
                             o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL ts_opinion.upd , flg_state = ' || g_opinion_cancel;
        ts_opinion.upd(id_opinion_in       => i_opinion,
                       flg_state_in        => g_opinion_cancel,
                       dt_cancel_tstz_in   => g_sysdate_tstz,
                       notes_cancel_in     => i_notes_cancel,
                       id_cancel_reason_in => i_cancel_reason,
                       dt_last_update_in   => g_sysdate_tstz,
                       id_prof_cancel_in   => i_prof.id,
                       rows_out            => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'OPINION',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        OPEN c_epis;
        FETCH c_epis
            INTO r_epis;
        CLOSE c_epis;
    
        pk_ia_event_common.opinion_order_cancel(i_id_opinion => i_opinion, i_id_episode => r_epis.id_episode);
    
        g_error := 'CALL set_opinion_hist';
        set_opinion_hist(i_lang => i_lang, i_prof => i_prof, i_opinion => i_opinion, o_opinion_hist => l_opinion_hist);
        g_error := 'CALL set_opinion_reason_hist';
        set_opinion_reason_hist(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_opinion      => i_opinion,
                                i_opinion_hist => l_opinion_hist);
    
        -- get id_epis_pn
        IF l_config_create_note = pk_alert_constant.g_yes
        THEN
            l_id_epis_pn := get_id_epis_pn(i_opinion, i_opinion_type, r_epis.id_episode, NULL);
            IF l_id_epis_pn IS NOT NULL
            THEN
                IF NOT pk_prog_notes_core.cancel_progress_note(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_epis_pn       => l_id_epis_pn,
                                                               i_cancel_reason => i_cancel_reason,
                                                               i_notes_cancel  => i_notes_cancel,
                                                               o_error         => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        -- delete existant alert
        g_error := 'CALL pk_alerts.delete_sys_alert_event';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_id_sys_alert => CASE
                                                                 WHEN l_flg_approve = pk_alert_constant.g_yes THEN
                                                                  g_alert_needs_approval
                                                                 ELSE
                                                                  g_alert_needs_acceptance
                                                             END,
                                           i_id_record    => i_opinion,
                                           o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_OPINION_CANCELED',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_opinion_canceled;

    /************************************************************************************************************
    * This function cancels the passed opinion
    * Equal to the set_opinion_canceled, without validating if the professional that is cancelling the request
    * is the same one that created the registry.
    *
    * @param      i_lang           language identifier
    * @param      i_prof           logged professional structure
    * @param      i_opinion        Id opinion
    * @param      i_opinion_type   opinion type identifier
    * @param      i_notes_cancel   cancel notes
    * @param      i_cancel_reason  Id cancel reason
    * @param      o_error          error
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Sofia Mendes
    * @version    2.6.0.3
    * @since      12-Jul-2010
    ************************************************************************************************************/
    FUNCTION set_opinion_canc_no_val
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion.id_opinion%TYPE,
        i_opinion_type     IN opinion_type.id_opinion_type%TYPE,
        i_notes_cancel     IN opinion.notes_cancel%TYPE,
        i_cancel_reason    IN opinion.id_cancel_reason%TYPE,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids       table_varchar;
        l_opinion_hist opinion_hist.id_opinion_hist%TYPE;
        l_flg_approve  opinion_type_prof.flg_approve%TYPE;
    
        CURSOR c_epis IS
            SELECT id_episode
              FROM opinion
             WHERE id_opinion = i_opinion;
        r_epis c_epis%ROWTYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_error        := 'CALL check_approval_need';
        l_flg_approve  := check_approval_need(i_prof => i_prof, i_opinion_type => i_opinion_type);
    
        g_error := 'CALL ts_opinion.upd , flg_state = ' || g_opinion_cancel;
        ts_opinion.upd(id_opinion_in       => i_opinion,
                       flg_state_in        => g_opinion_cancel,
                       dt_cancel_tstz_in   => g_sysdate_tstz,
                       notes_cancel_in     => i_notes_cancel,
                       id_cancel_reason_in => i_cancel_reason,
                       dt_last_update_in   => g_sysdate_tstz,
                       id_prof_cancel_in   => i_prof.id,
                       rows_out            => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'OPINION',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        OPEN c_epis;
        FETCH c_epis
            INTO r_epis;
        CLOSE c_epis;
    
        IF i_flg_cancel_event = pk_alert_constant.g_yes
        THEN
            pk_ia_event_common.opinion_order_cancel(i_id_opinion => i_opinion, i_id_episode => r_epis.id_episode);
        END IF;
    
        g_error := 'CALL set_opinion_hist';
        set_opinion_hist(i_lang => i_lang, i_prof => i_prof, i_opinion => i_opinion, o_opinion_hist => l_opinion_hist);
        g_error := 'CALL set_opinion_reason_hist';
        set_opinion_reason_hist(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_opinion      => i_opinion,
                                i_opinion_hist => l_opinion_hist);
    
        -- delete existant alert
        g_error := 'CALL pk_alerts.delete_sys_alert_event';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_id_sys_alert => CASE
                                                                 WHEN l_flg_approve = pk_alert_constant.g_yes THEN
                                                                  g_alert_needs_approval
                                                                 ELSE
                                                                  g_alert_needs_acceptance
                                                             END,
                                           i_id_record    => i_opinion,
                                           o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_OPINION_CANC_NO_VAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_opinion_canc_no_val;

    /************************************************************************************************************
    * This function sets the oppinion as "approved" (used by the professional responsible for the episode)
    *
    * @param      i_lang           language identifier
    * @param      i_prof           logged professional structure
    * @param      i_opinion        Id opinion
    * @param      i_notes          approve notes
    * @param      o_error          error
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.6.0.1
    * @since      13-04-2010
    ************************************************************************************************************/
    FUNCTION set_opinion_approved
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        i_notes   IN opinion_prof.desc_reply%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids          table_varchar;
        l_opinion_hist    opinion_hist.id_opinion_hist%TYPE;
        l_prof_questions  opinion.id_prof_questions%TYPE;
        l_prof_questioned opinion.id_prof_questioned%TYPE;
        l_episode         opinion.id_episode%TYPE;
    
        CURSOR c_opinion IS
            SELECT op.id_prof_questions, op.id_prof_questioned, op.id_episode
              FROM opinion op
             WHERE op.id_opinion = i_opinion;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL validate_prof';
        IF NOT validate_prof(i_lang    => i_lang,
                             i_prof    => i_prof,
                             i_opinion => i_opinion,
                             i_state   => g_opinion_approved,
                             o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL ts_opinion.upd , flg_state = ' || g_opinion_approved;
        ts_opinion.upd(id_opinion_in       => i_opinion,
                       flg_state_in        => g_opinion_approved,
                       dt_approved_in      => g_sysdate_tstz,
                       id_prof_approved_in => i_prof.id,
                       dt_last_update_in   => g_sysdate_tstz,
                       rows_out            => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'OPINION',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL set_opinion_hist';
        set_opinion_hist(i_lang => i_lang, i_prof => i_prof, i_opinion => i_opinion, o_opinion_hist => l_opinion_hist);
        g_error := 'CALL set_opinion_reason_hist';
        set_opinion_reason_hist(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_opinion      => i_opinion,
                                i_opinion_hist => l_opinion_hist);
    
        l_rowids := table_varchar();
        g_error  := 'CALL ts_opinion_prof.ins';
        ts_opinion_prof.ins(id_opinion_in           => i_opinion,
                            flg_type_in             => g_opinion_prof_approve,
                            id_professional_in      => i_prof.id,
                            desc_reply_in           => i_notes,
                            dt_opinion_prof_tstz_in => g_sysdate_tstz,
                            flg_face_to_face_in     => g_unknown,
                            rows_out                => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'OPINION_PROF',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- delete existant alert
        g_error := 'CALL pk_alerts.delete_sys_alert_event';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => g_alert_needs_approval,
                                                i_id_record    => i_opinion,
                                                o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- create alerts for "questioned" and "questions" professional
        g_error := 'OPEN c_opinion';
        OPEN c_opinion;
        FETCH c_opinion
            INTO l_prof_questions, l_prof_questioned, l_episode;
        CLOSE c_opinion;
    
        g_error := 'CALL pk_alerts.insert_sys_alert_event I';
        IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_sys_alert           => g_alert_needs_acceptance,
                                                i_id_episode          => l_episode,
                                                i_id_record           => i_opinion,
                                                i_dt_record           => g_sysdate_tstz,
                                                i_id_professional     => l_prof_questioned,
                                                i_id_room             => NULL,
                                                i_id_clinical_service => NULL,
                                                i_flg_type_dest       => NULL,
                                                i_replace1            => NULL,
                                                o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_alerts.insert_sys_alert_event II';
        IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_sys_alert           => g_alert_approval_reply,
                                                i_id_episode          => l_episode,
                                                i_id_record           => i_opinion,
                                                i_dt_record           => g_sysdate_tstz,
                                                i_id_professional     => l_prof_questions,
                                                i_id_room             => NULL,
                                                i_id_clinical_service => NULL,
                                                i_flg_type_dest       => NULL,
                                                i_replace1            => pk_message.get_message(i_lang      => i_lang,
                                                                                                i_prof      => i_prof,
                                                                                                i_code_mess => 'CONSULT_REQUEST_T053'),
                                                o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_OPINION_APPROVED',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_opinion_approved;

    /************************************************************************************************************
    * This function sets the oppinion as "refused" (used by the professional responsible for the episode)
    *
    * @param      i_lang           language identifier
    * @param      i_prof           logged professional structure
    * @param      i_opinion        Id opinion
    * @param      i_notes          refuse notes
    * @param      i_cancel_reason  Id cancel reason
    * @param      o_error          error
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.6.0.1
    * @since      13-04-2010
    ************************************************************************************************************/
    FUNCTION set_opinion_refused
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_notes         IN opinion_prof.desc_reply%TYPE,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowids          table_varchar;
        l_rowids_op       table_varchar;
        l_id_opinion_prof opinion_prof.id_opinion_prof%TYPE;
        l_opinion_hist    opinion_hist.id_opinion_hist%TYPE;
        l_prof_questions  opinion.id_prof_questions%TYPE;
        l_episode         opinion.id_episode%TYPE;
    
        CURSOR c_opinion IS
            SELECT op.id_prof_questions, op.id_episode
              FROM opinion op
             WHERE op.id_opinion = i_opinion;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL validate_prof';
        IF NOT validate_prof(i_lang    => i_lang,
                             i_prof    => i_prof,
                             i_opinion => i_opinion,
                             i_state   => g_opinion_not_approved,
                             o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        ------------------------------------------------------
        g_error := 'CALL ts_opinion.upd , flg_state = ' || g_opinion_not_approved;
        ts_opinion.upd(id_opinion_in       => i_opinion,
                       flg_state_in        => g_opinion_not_approved,
                       dt_approved_in      => g_sysdate_tstz,
                       id_prof_approved_in => i_prof.id,
                       dt_last_update_in   => g_sysdate_tstz,
                       rows_out            => l_rowids);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'OPINION',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        ------------------------------------------------------                              
        g_error := 'CALL ts_opinion.upd';
        ts_opinion_prof.ins(id_opinion_prof_out     => l_id_opinion_prof,
                            id_opinion_in           => i_opinion,
                            flg_type_in             => g_opinion_prof_refuse,
                            id_professional_in      => i_prof.id,
                            dt_opinion_prof_tstz_in => g_sysdate_tstz,
                            desc_reply_in           => i_notes,
                            id_cancel_reason_in     => i_cancel_reason,
                            rows_out                => l_rowids_op);
    
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'OPINION_PROF',
                                      i_rowids     => l_rowids_op,
                                      o_error      => o_error);
    
        ------------------------------------------------------
        g_error := 'CALL set_opinion_hist';
        set_opinion_hist(i_lang => i_lang, i_prof => i_prof, i_opinion => i_opinion, o_opinion_hist => l_opinion_hist);
        g_error := 'CALL set_opinion_reason_hist';
        set_opinion_reason_hist(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_opinion      => i_opinion,
                                i_opinion_hist => l_opinion_hist);
    
        -- delete existant alert
        g_error := 'CALL pk_alerts.delete_sys_alert_event';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => g_alert_needs_approval,
                                                i_id_record    => i_opinion,
                                                o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- create alert for "questions" professional
        g_error := 'OPEN c_opinion';
        OPEN c_opinion;
        FETCH c_opinion
            INTO l_prof_questions, l_episode;
        CLOSE c_opinion;
    
        g_error := 'CALL pk_alerts.insert_sys_alert_event';
        IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_sys_alert           => g_alert_approval_reply,
                                                i_id_episode          => l_episode,
                                                i_id_record           => i_opinion,
                                                i_dt_record           => g_sysdate_tstz,
                                                i_id_professional     => l_prof_questions,
                                                i_id_room             => NULL,
                                                i_id_clinical_service => NULL,
                                                i_flg_type_dest       => NULL,
                                                i_replace1            => pk_message.get_message(i_lang      => i_lang,
                                                                                                i_prof      => i_prof,
                                                                                                i_code_mess => 'CONSULT_REQUEST_T054'),
                                                o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_OPINION_REFUSED',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_opinion_refused;

    /*
    * Set consult request state. For database internal use only.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param i_state          opinion state
    * @param i_set_oprof      create opinion_prof answer? Y/N
    * @param o_opinion_hist   created opinion history identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */
    FUNCTION set_consult_request_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_state        IN opinion.flg_state%TYPE,
        i_set_oprof    IN VARCHAR2 := pk_alert_constant.g_yes,
        o_opinion_hist OUT opinion_hist.id_opinion_hist%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_type opinion_prof.flg_type%TYPE;
        l_rows     table_varchar := table_varchar();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- update opinion state
        g_error := 'CALL ts_opinion.upd';
        ts_opinion.upd(id_opinion_in      => i_opinion,
                       flg_state_in       => i_state,
                       flg_state_nin      => FALSE,
                       dt_last_update_in  => g_sysdate_tstz,
                       dt_last_update_nin => FALSE,
                       rows_out           => l_rows);
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'OPINION',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATE', 'DT_LAST_UPDATE'));
    
        -- create opinion history
        g_error := 'CALL set_opinion_hist';
        set_opinion_hist(i_lang => i_lang, i_prof => i_prof, i_opinion => i_opinion, o_opinion_hist => o_opinion_hist);
        g_error := 'CALL set_opinion_reason_hist';
        set_opinion_reason_hist(i_lang         => i_lang,
                                i_prof         => i_prof,
                                i_opinion      => i_opinion,
                                i_opinion_hist => o_opinion_hist);
    
        IF i_set_oprof = pk_alert_constant.g_yes
        THEN
            -- create opinion_prof answer
            IF i_state = g_opinion_over
            THEN
                l_flg_type := g_opin_prof_conclusion;
            ELSIF i_state = g_opinion_accepted
            THEN
                l_flg_type := g_opinion_prof_accept;
            END IF;
        
            l_rows  := table_varchar();
            g_error := 'CALL ts_opinion_prof.ins';
            ts_opinion_prof.ins(id_opinion_in           => i_opinion,
                                flg_type_in             => l_flg_type,
                                id_professional_in      => i_prof.id,
                                dt_opinion_prof_tstz_in => g_sysdate_tstz,
                                flg_face_to_face_in     => g_unknown,
                                rows_out                => l_rows);
            g_error := 'CALL t_data_gov_mnt.process_insert';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'OPINION_PROF',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_CONSULT_REQUEST_STATE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_consult_request_state;

    /*
    * Get applicable professionals list,
    * for consult request creation/edition.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion_type   opinion type identifier
    * @param i_clin_serv      clinical service identifier
    * @param o_prof_list      professional list
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */
    FUNCTION get_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        o_prof_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cat           table_number;
        l_prof_template table_number;
        l_multiple_prob VARCHAR2(1);
        CURSOR c_cat IS
            SELECT ot.id_category, ot.id_profile_template
              FROM opinion_type_category ot
             WHERE ot.id_opinion_type = i_opinion_type;
    BEGIN
        g_error := 'OPEN c_cat';
        OPEN c_cat;
        FETCH c_cat BULK COLLECT
            INTO l_cat, l_prof_template;
        CLOSE c_cat;
    
        l_multiple_prob := get_has_multiple_prof(i_lang, i_prof, i_clin_serv, i_opinion_type, o_error);
    
        IF i_clin_serv IS NULL
        THEN
            g_error := 'OPEN o_prof_list';
            OPEN o_prof_list FOR
                SELECT g_any_prof data, pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021') label
                  FROM dual
                 WHERE l_multiple_prob = pk_alert_constant.g_yes
                
                UNION ALL
                
                SELECT t.data, t.label
                  FROM (SELECT DISTINCT pc.id_professional data,
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_professional) label
                          FROM prof_cat pc
                          JOIN prof_profile_template ppt
                            ON ppt.id_professional = pc.id_professional
                           AND ppt.id_institution = i_prof.institution
                          JOIN (SELECT t.column_value id_category
                                 FROM TABLE(l_cat) t) cat
                            ON cat.id_category = pc.id_category
                          JOIN (SELECT t.column_value id_prof_template
                                 FROM TABLE(l_prof_template) t) prof_template
                            ON (prof_template.id_prof_template = ppt.id_profile_template OR
                               prof_template.id_prof_template IS NULL)
                          JOIN prof_institution pi
                            ON pi.id_professional = pc.id_professional
                           AND pi.id_institution = i_prof.institution
                           AND pi.flg_state = g_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.flg_external = pk_alert_constant.g_no
                         WHERE pc.id_institution = i_prof.institution
                              --AND pc.id_category = l_cat
                           AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pc.id_professional, i_prof.institution) =
                               pk_alert_constant.g_yes
                         ORDER BY 2) t;
        ELSE
            g_error := 'OPEN o_prof_list';
            OPEN o_prof_list FOR
                SELECT g_any_prof data, pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021') label
                  FROM dual
                 WHERE l_multiple_prob = pk_alert_constant.g_yes
                UNION ALL
                SELECT t.data, t.label
                  FROM (SELECT pdcs.id_professional data,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, pdcs.id_professional) label
                          FROM dep_clin_serv dcs
                          JOIN prof_dep_clin_serv pdcs
                            ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                          JOIN prof_cat pc
                            ON pdcs.id_professional = pc.id_professional
                          JOIN (SELECT t.column_value id_category
                                 FROM TABLE(l_cat) t) cat
                            ON cat.id_category = pc.id_category
                          JOIN prof_institution pi
                            ON pi.id_professional = pdcs.id_professional
                           AND pi.id_institution = i_prof.institution
                           AND pi.flg_state = g_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pi.flg_external = pk_alert_constant.g_no
                         WHERE dcs.id_clinical_service = i_clin_serv
                           AND dcs.flg_available = pk_alert_constant.g_yes
                           AND pdcs.id_institution = i_prof.institution
                           AND pdcs.flg_status = pk_alert_constant.g_status_selected
                           AND pc.id_institution = i_prof.institution
                              --AND pc.id_category = l_cat
                           AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pdcs.id_professional, i_prof.institution) =
                               pk_alert_constant.g_yes
                         ORDER BY 2) t;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_prof_list);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_prof_list);
            RETURN FALSE;
    END get_prof_list;

    FUNCTION get_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE
    ) RETURN t_tbl_core_domain IS
        l_cat           table_number;
        l_prof_template table_number;
        l_multiple_prob VARCHAR2(1);
        CURSOR c_cat IS
            SELECT ot.id_category, ot.id_profile_template
              FROM opinion_type_category ot
             WHERE ot.id_opinion_type = i_opinion_type;
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        g_error := 'OPEN c_cat';
        OPEN c_cat;
        FETCH c_cat BULK COLLECT
            INTO l_cat, l_prof_template;
        CLOSE c_cat;
    
        l_multiple_prob := get_has_multiple_prof(i_lang, i_prof, i_clin_serv, i_opinion_type, l_error);
    
        IF i_clin_serv IS NULL
        THEN
            g_error := 'OPEN L_RET';
            SELECT *
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t_row_core_domain(internal_name => NULL,
                                             desc_domain   => tt.label,
                                             domain_value  => tt.data,
                                             order_rank    => NULL,
                                             img_name      => NULL)
                      FROM (SELECT g_any_prof data, pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021') label
                              FROM dual
                             WHERE l_multiple_prob = pk_alert_constant.g_yes
                            
                            UNION ALL
                            
                            SELECT t.data, t.label
                              FROM (SELECT DISTINCT pc.id_professional data,
                                                    pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_professional) label
                                      FROM prof_cat pc
                                      JOIN prof_profile_template ppt
                                        ON ppt.id_professional = pc.id_professional
                                       AND ppt.id_institution = i_prof.institution
                                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                            t.column_value id_category
                                             FROM TABLE(l_cat) t) cat
                                        ON cat.id_category = pc.id_category
                                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                            t.column_value id_prof_template
                                             FROM TABLE(l_prof_template) t) prof_template
                                        ON (prof_template.id_prof_template = ppt.id_profile_template OR
                                           prof_template.id_prof_template IS NULL)
                                      JOIN prof_institution pi
                                        ON pi.id_professional = pc.id_professional
                                       AND pi.id_institution = i_prof.institution
                                       AND pi.flg_state = g_prof_active
                                       AND pi.dt_end_tstz IS NULL
                                       AND pi.flg_external = pk_alert_constant.g_no
                                     WHERE pc.id_institution = i_prof.institution
                                          --AND pc.id_category = l_cat
                                       AND pk_prof_utils.is_internal_prof(i_lang,
                                                                          i_prof,
                                                                          pc.id_professional,
                                                                          i_prof.institution) = pk_alert_constant.g_yes
                                     ORDER BY 2) t) tt);
        ELSE
            g_error := 'OPEN L_RET';
            SELECT *
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t_row_core_domain(internal_name => NULL,
                                             desc_domain   => tt.label,
                                             domain_value  => tt.data,
                                             order_rank    => NULL,
                                             img_name      => NULL)
                      FROM (SELECT g_any_prof data, pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021') label
                              FROM dual
                             WHERE l_multiple_prob = pk_alert_constant.g_yes
                            UNION ALL
                            SELECT t.data, t.label
                              FROM (SELECT DISTINCT pdcs.id_professional data,
                                                    pk_prof_utils.get_name_signature(i_lang, i_prof, pdcs.id_professional) label
                                      FROM dep_clin_serv dcs
                                      JOIN prof_dep_clin_serv pdcs
                                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                      JOIN prof_cat pc
                                        ON pdcs.id_professional = pc.id_professional
                                      JOIN (SELECT t.column_value id_category
                                             FROM TABLE(l_cat) t) cat
                                        ON cat.id_category = pc.id_category
                                      JOIN prof_institution pi
                                        ON pi.id_professional = pdcs.id_professional
                                       AND pi.id_institution = i_prof.institution
                                       AND pi.flg_state = g_prof_active
                                       AND pi.dt_end_tstz IS NULL
                                       AND pi.flg_external = pk_alert_constant.g_no
                                     WHERE dcs.id_clinical_service = i_clin_serv
                                       AND dcs.flg_available = pk_alert_constant.g_yes
                                       AND pdcs.id_institution = i_prof.institution
                                       AND pdcs.flg_status = pk_alert_constant.g_status_selected
                                       AND pc.id_institution = i_prof.institution
                                          --AND pc.id_category = l_cat
                                       AND pk_prof_utils.is_internal_prof(i_lang,
                                                                          i_prof,
                                                                          pdcs.id_professional,
                                                                          i_prof.institution) = pk_alert_constant.g_yes
                                     ORDER BY 2) t) tt);
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_LIST',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_prof_list;

    /*
    * Get applicable professionals list,
    * for consult request creation/edition.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion_type   opinion type identifier
    * @param i_internal_name  clinical service identifier
    * @param o_error          error
    *
    * @return                 List of professional to be used in the dynamic screens
    *
    */
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_opinion_type  IN opinion_type.id_opinion_type%TYPE,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_cat           table_number;
        l_prof_template table_number;
        l_multiple_prob VARCHAR2(1);
        CURSOR c_cat IS
            SELECT ot.id_category, ot.id_profile_template
              FROM opinion_type_category ot
             WHERE ot.id_opinion_type = i_opinion_type;
    
        l_ret t_tbl_core_domain;
    
    BEGIN
        g_error := 'OPEN c_cat';
        OPEN c_cat;
        FETCH c_cat BULK COLLECT
            INTO l_cat, l_prof_template;
        CLOSE c_cat;
    
        l_multiple_prob := get_has_multiple_prof(i_lang, i_prof, NULL, i_opinion_type, o_error);
    
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => i_internal_name,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT g_any_prof data, pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021') label
                          FROM dual
                         WHERE l_multiple_prob = pk_alert_constant.g_yes
                        
                        UNION ALL
                        
                        SELECT t.data, t.label
                          FROM (SELECT DISTINCT pc.id_professional data,
                                                pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_professional) label
                                  FROM prof_cat pc
                                  JOIN (SELECT /*+opt_estimate(table a rows=1)*/
                                        t.column_value id_category
                                         FROM TABLE(l_cat) t) cat
                                    ON cat.id_category = pc.id_category
                                  JOIN prof_profile_template ppt
                                    ON ppt.id_professional = pc.id_professional
                                   AND ppt.id_institution = i_prof.institution
                                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                        t.column_value id_prof_template
                                         FROM TABLE(l_prof_template) t) prof_template
                                    ON (prof_template.id_prof_template = ppt.id_profile_template OR
                                       prof_template.id_prof_template IS NULL)
                                  JOIN prof_institution pi
                                    ON pi.id_professional = pc.id_professional
                                   AND pi.id_institution = i_prof.institution
                                   AND pi.flg_state = g_prof_active
                                   AND pi.dt_end_tstz IS NULL
                                   AND pi.flg_external = pk_alert_constant.g_no
                                 WHERE pc.id_institution = i_prof.institution
                                   AND pc.id_professional <> i_prof.id
                                   AND pk_prof_utils.is_internal_prof(i_lang,
                                                                      i_prof,
                                                                      pc.id_professional,
                                                                      i_prof.institution) = pk_alert_constant.g_yes
                                 ORDER BY 2) t));
    
        RETURN l_ret;
    
    END get_prof_list;

    /*
    * Build status string for social assistance requests. Internal use only.
    * Made public to be used in SQL statements.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_status         request status
    * @param i_dt_req         request date
    *
    * @return                 request status string
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION get_req_status_str
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_state          IN opinion.flg_state%TYPE,
        i_dt_req         IN opinion.dt_last_update%TYPE,
        i_opinion_type   IN opinion.id_opinion_type%TYPE,
        i_prof_questions IN opinion.id_prof_questions%TYPE,
        i_episode        IN opinion.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_show_workflow BOOLEAN := TRUE;
        l_display_type  VARCHAR2(2 CHAR);
        l_value_date    sys_domain.code_domain%TYPE;
        l_value_icon    sys_domain.code_domain%TYPE;
        l_back_color    VARCHAR2(8 CHAR);
        l_icon_color    VARCHAR2(8 CHAR);
        l_institution   episode.id_institution%TYPE;
        l_software      epis_info.id_software%TYPE;
        l_patient       episode.id_patient%TYPE;
        l_flg_approve   opinion_type_prof.flg_approve%TYPE;
        l_prof_ids      table_number := table_number();
    
        CURSOR c_epis_orig IS
            SELECT e.id_institution, ei.id_software, e.id_patient
              FROM episode e
              JOIN epis_info ei
                ON e.id_episode = ei.id_episode
             WHERE e.id_episode = i_episode;
    BEGIN
        -- follow-up requests status string logic
        IF i_state = g_opinion_req
        THEN
            -- when request is pending, check if it needs approval
            OPEN c_epis_orig;
            FETCH c_epis_orig
                INTO l_institution, l_software, l_patient;
            CLOSE c_epis_orig;
        
            l_flg_approve := check_approval_need(i_prof         => profissional(i_prof_questions,
                                                                                l_institution,
                                                                                l_software),
                                                 i_opinion_type => i_opinion_type);
            IF l_flg_approve = pk_alert_constant.g_yes
            THEN
                -- approval needed? check if i_prof can approve
                l_prof_ids := get_approvers_list(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_patient => l_patient,
                                                 i_episode => i_episode);
            
                IF pk_utils.search_table_number(i_table => l_prof_ids, i_search => i_prof.id) < 0
                THEN
                    -- i_prof cannot approve
                    l_show_workflow := FALSE;
                END IF;
            ELSE
                -- approval is not needed
                l_show_workflow := FALSE;
            END IF;
        ELSE
            -- request is not pending approval
            l_show_workflow := FALSE;
        END IF;
    
        IF l_show_workflow
        THEN
            l_display_type := pk_alert_constant.g_display_type_date;
            --l_value_date   := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_dt_req, i_prof => i_prof);
            l_value_date := pk_date_utils.to_char_insttimezone(i_prof      => i_prof,
                                                               i_timestamp => i_dt_req,
                                                               i_mask      => pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        
            l_value_icon := NULL;
            l_back_color := pk_alert_constant.g_color_red;
            l_icon_color := pk_alert_constant.g_color_null;
        ELSE
            l_display_type := pk_alert_constant.g_display_type_icon;
            l_value_date   := NULL;
            l_value_icon   := g_opinion_state_domain;
            l_back_color   := pk_alert_constant.g_color_null;
            l_icon_color   := CASE i_state
                                  WHEN pk_alert_constant.g_cancelled THEN
                                   pk_alert_constant.g_color_null
                                  ELSE
                                   pk_alert_constant.g_color_icon_medium_grey
                              END;
        END IF;
        -- generate status string
        RETURN pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_display_type    => l_display_type,
                                                    i_flg_state       => i_state,
                                                    i_value_text      => NULL,
                                                    i_value_date      => l_value_date,
                                                    i_value_icon      => l_value_icon,
                                                    i_shortcut        => NULL,
                                                    i_back_color      => l_back_color,
                                                    i_icon_color      => l_icon_color,
                                                    i_message_style   => NULL,
                                                    i_message_color   => NULL,
                                                    i_flg_text_domain => pk_alert_constant.g_no);
    END get_req_status_str;
    --

    /********************************************************************************************
    * Get the Follow-up requests summary, concatenated as a String (CLOB).
    * The information includes: Diagnosis, Intervention plans, Follow-up notes and Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param i_opinion_type          Type of request
    * @ param o_follow_up_request_summary  Array with all information, where each 
    *                                      position has a diferent type of data.
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_follow_up_req_sum_str
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_opinion_type              IN opinion_type.id_opinion_type%TYPE,
        o_follow_up_request_summary OUT table_clob,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_social.get_follow_up_req_sum_str';
    
        IF i_opinion_type = g_ot_dietitian
        THEN
            IF NOT pk_diet.get_follow_up_req_sum_str(i_lang                      => i_lang,
                                                     i_prof                      => i_prof,
                                                     i_patient                   => i_patient,
                                                     i_episode                   => i_episode,
                                                     o_follow_up_request_summary => o_follow_up_request_summary,
                                                     o_error                     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_opinion_type = g_ot_social_worker
        THEN
            IF NOT pk_social.get_follow_up_req_sum_str(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_patient                   => i_patient,
                                                       i_episode                   => i_episode,
                                                       o_follow_up_request_summary => o_follow_up_request_summary,
                                                       o_error                     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_opinion_type = g_ot_psychology
        THEN
            IF NOT pk_paramedical_prof_core.get_follow_up_req_sum_str(i_lang                      => i_lang,
                                                                      i_prof                      => i_prof,
                                                                      i_patient                   => i_patient,
                                                                      i_episode                   => i_episode,
                                                                      o_follow_up_request_summary => o_follow_up_request_summary,
                                                                      o_error                     => o_error)
            
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
            o_follow_up_request_summary := table_clob();
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_FOLLOW_UP_REQ_SUM_STR',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_follow_up_req_sum_str;

    /*******************************************************************************************
    * Answers (accepts/rejects) a case management request. overload created so that we can send in our own remote transaction.
    * This function simply calls the original one.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_patient          patient identifier
    * @param i_flg_state        Acceptance (E - accept / X - Reject )
    * @param i_management_level management level identifier
    * @param i_notes            answer notes
    * @param i_cancel_reason    refuse reason
    * @param o_opinion          opinion identifier
    * @param o_opinion_prof     opinion prof identifier
    * @param o_episode          episode identifier
    * @param o_epis_encounter   episode encounter dentifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Telmo Castro
    * @version                  2.6.0.1
    * @since                    27-04-2010
    ********************************************************************************************/
    FUNCTION set_request_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        i_cancel_reason    IN opinion_prof.id_cancel_reason%TYPE,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_epis_encounter   OUT epis_encounter.id_epis_encounter%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
        l_func_exception EXCEPTION;
    BEGIN
    
        -- get remote transaction
        g_error          := 'START REMOTE TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'CALL ORIGINAL SET_REQUEST_ANSWER';
        IF NOT set_request_answer(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_opinion          => i_opinion,
                                  i_patient          => i_patient,
                                  i_flg_state        => i_flg_state,
                                  i_management_level => i_management_level,
                                  i_notes            => i_notes,
                                  i_cancel_reason    => i_cancel_reason,
                                  i_transaction_id   => l_transaction_id,
                                  i_do_commit        => pk_alert_constant.g_yes,
                                  i_dt_opinion       => NULL,
                                  o_opinion_prof     => o_opinion_prof,
                                  o_episode          => o_episode,
                                  o_epis_encounter   => o_epis_encounter,
                                  o_error            => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- fechar transacoes
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REQUEST_ANSWER',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_request_answer;

    /*******************************************************************************************
    * Retrieves the detail of operations made in a case management request (Reports).
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param o_hist             cursor (info, details)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Elisabete Bugalho
    * @version                  2.5.0.7.4
    * @since                    23-04-2010
    ********************************************************************************************/
    FUNCTION get_cm_req_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_hist    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_br CONSTANT VARCHAR2(4) := '<br>';
        l_na CONSTANT VARCHAR2(2) := '--';
        l_msg_req     sys_message.desc_message%TYPE;
        l_msg_canc    sys_message.desc_message%TYPE;
        l_msg_acc     sys_message.desc_message%TYPE;
        l_msg_rej     sys_message.desc_message%TYPE;
        l_msg_over    sys_message.desc_message%TYPE;
        l_msg_reqd    sys_message.desc_message%TYPE;
        l_msg_req_by  sys_message.desc_message%TYPE;
        l_msg_req_to  sys_message.desc_message%TYPE;
        l_msg_acc_by  sys_message.desc_message%TYPE;
        l_msg_acc_on  sys_message.desc_message%TYPE;
        l_msg_rej_by  sys_message.desc_message%TYPE;
        l_msg_rej_on  sys_message.desc_message%TYPE;
        l_msg_over_by sys_message.desc_message%TYPE;
        l_msg_over_on sys_message.desc_message%TYPE;
    
    BEGIN
        l_msg_req    := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T026');
        l_msg_canc   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T022');
        l_msg_acc    := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T076');
        l_msg_rej    := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T077');
        l_msg_over   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T110');
        l_msg_reqd   := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T027');
        l_msg_req_by := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T028');
        l_msg_req_to := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T029');
        l_msg_acc_by := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T078');
        l_msg_acc_on := l_msg_acc;
        l_msg_rej_by := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T079');
        l_msg_rej_on := l_msg_rej;
    
        l_msg_over_by := pk_message.get_message(i_lang, i_prof, 'CASE_MANAGER_T111');
        l_msg_over_on := l_msg_over;
    
        g_error := 'OPEN o_hist';
        OPEN o_hist FOR
            SELECT l_msg_canc operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_cancel_tstz, i_prof) reg_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) prof_name,
                   NULL desc_speciality,
                   NULL title_operation_by,
                   NULL prof_by,
                   NULL title_operation_to,
                   NULL prof_to,
                   NULL date_by_title,
                   NULL date_by,
                   decode(id_cancel_reason, NULL, l_na, pk_translation.get_translation(i_lang, cr.code_cancel_reason)) reason,
                   nvl(o.notes_cancel, l_na) notes,
                   pk_date_utils.to_char_insttimezone(i_prof, o.dt_cancel_tstz, 'YYYYMMDDHH24MISS') date_opinion,
                   o.flg_state,
                   o.flg_state flg_final_state
              FROM opinion o
              LEFT JOIN cancel_reason cr
             USING (id_cancel_reason)
             WHERE o.id_opinion = i_opinion
               AND o.flg_state = g_opinion_cancel
            UNION ALL
            SELECT decode(o.flg_state,
                          g_opinion_accepted,
                          l_msg_acc,
                          g_opinion_rejected,
                          l_msg_rej,
                          g_opinion_over,
                          l_msg_over) operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, op.dt_opinion_prof_tstz, i_prof) reg_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional) prof_name,
                   NULL desc_speciality,
                   decode(o.flg_state,
                          g_opinion_accepted,
                          l_msg_acc_by,
                          g_opinion_rejected,
                          l_msg_rej_by,
                          g_opinion_over,
                          l_msg_over_by) title_operation_by,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional) prof_by,
                   NULL title_operation_to,
                   NULL prof_to,
                   decode(o.flg_state,
                          g_opinion_accepted,
                          l_msg_acc_on,
                          g_opinion_rejected,
                          l_msg_rej_on,
                          g_opinion_over,
                          l_msg_over_on) date_by_title,
                   pk_date_utils.dt_chr_tsz(i_lang, o.dt_problem_tstz, i_prof) date_by,
                   NULL reason,
                   nvl(op.desc_reply, l_na) notes,
                   pk_date_utils.to_char_insttimezone(i_prof, o.dt_cancel_tstz, 'YYYYMMDDHH24MISS') date_opinion,
                   op.flg_type,
                   o.flg_state
              FROM opinion o
              JOIN opinion_prof op
             USING (id_opinion)
             WHERE id_opinion = i_opinion
               AND op.flg_type <> g_opin_prof_a
            UNION ALL
            SELECT l_msg_req operation,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) reg_date,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) prof_name,
                   NULL desc_speciality,
                   l_msg_req_by title_operation_by,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) prof_by,
                   l_msg_req_to title_operation_to,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned) prof_to,
                   l_msg_reqd date_by_title,
                   pk_date_utils.dt_chr_tsz(i_lang, o.dt_problem_tstz, i_prof) date_by,
                   get_cm_req_reason(i_lang, i_prof, o.id_opinion) reason,
                   nvl(o.desc_problem, l_na) notes,
                   pk_date_utils.to_char_insttimezone(i_prof, o.dt_problem_tstz, 'YYYYMMDDHH24MISS') date_opinion,
                   g_opinion_req,
                   o.flg_state
              FROM opinion o
             WHERE o.id_opinion = i_opinion;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CM_REQ_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_cm_req_detail;

    /*
    * Checks if there is some activity therapy request in the state: requested or approved    
    *    
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_id_episode       episode identifier
    *
    * @returns                'Y', there is a request in state requested or approved, or 'N' otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  27-Mai-2010    
    */
    FUNCTION check_opinion_state
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_nr_opinion PLS_INTEGER;
        l_ret        VARCHAR2(1);
    BEGIN
    
        SELECT COUNT(1)
          INTO l_nr_opinion
          FROM opinion o
         WHERE o.id_episode = i_id_episode
           AND o.flg_state IN (g_opinion_rejected, g_opinion_approved)
           AND o.id_opinion_type = pk_act_therap_constant.g_at_opinion_type;
    
        IF (l_nr_opinion > 0)
        THEN
            l_ret := pk_alert_constant.g_yes;
        ELSE
            l_ret := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_ret;
    END check_opinion_state;

    /**********************************************************************************************
    * Get the opinion id associated to a given episode.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_episode            Episode identifier
    * @param i_id_opinion_type       Opinion type identifier
    * @param i_flg_state             List of Opinion states to be included
    * @param o_id_opinion            Opinion identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *
    * @author                        Sofia Mendes
    * @version                       2.6.0.3
    * @since                         11-Jun-2010
    **********************************************************************************************/
    FUNCTION get_opinion_id_by_state
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        i_flg_states      IN table_varchar,
        o_id_opinion      OUT opinion.id_opinion%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET opinion for episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        SELECT o.id_opinion
          INTO o_id_opinion
          FROM opinion o
         WHERE o.id_episode_answer = i_id_episode
           AND o.flg_state IN (SELECT column_value
                                 FROM TABLE(i_flg_states))
           AND o.id_opinion_type = i_id_opinion_type;
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_opinion := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OPINION_ID_BY_STATE',
                                              o_error);
            RETURN FALSE;
    END get_opinion_id_by_state;

    /*
    * checks if approval is required. If yes, sends an alert to the approvers list
    * To be used when creating a request by the Activity Therapist.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure    
    * @param i_patient        patient identifier
    * @param i_id_episode     episode identifier
    * @param i_opinion        opinion identifier
    * @param i_opinion_type   opinion type identifier
    * @param o_flg_approve    Y- approval is needed. N-otherwise
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  14-Jun-2010
    */
    FUNCTION set_request_alert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        o_flg_approve  OUT opinion_type_prof.flg_approve%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_episode  episode.id_episode%TYPE := NULL;
        l_prof_ids table_number := table_number();
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL check_approval_need';
        pk_alertlog.log_debug(g_error);
        o_flg_approve := check_approval_need(i_prof => i_prof, i_opinion_type => i_opinion_type);
    
        IF o_flg_approve = pk_alert_constant.g_yes
        THEN
            -- when approval is needed, send alert to approving professional
            g_error := 'CALL get_edis_inp_episode';
            pk_alertlog.log_debug(g_error);
            l_episode := get_edis_inp_episode(i_prof => i_prof, i_patient => i_patient, i_id_episode => i_id_episode);
            g_error   := 'CALL get_approvers_list';
            pk_alertlog.log_debug(g_error);
            l_prof_ids := get_approvers_list(i_lang    => i_lang,
                                             i_prof    => i_prof,
                                             i_patient => i_patient,
                                             i_episode => l_episode);
        END IF;
    
        -- create alerts
        IF o_flg_approve = pk_alert_constant.g_yes
        THEN
            IF l_prof_ids IS NULL
               OR l_prof_ids.first IS NULL
               OR l_prof_ids(l_prof_ids.first) IS NULL
            THEN
                g_error := 'no responsible exists!';
                pk_alertlog.log_debug(g_error);
                RAISE g_exception;
            END IF;
        
            g_error := 'CALL pk_alerts.insert_sys_alert_event for approval';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_sys_alert           => g_alert_needs_approval,
                                                    i_id_episode          => l_episode,
                                                    i_id_record           => i_opinion,
                                                    i_dt_record           => g_sysdate_tstz,
                                                    i_id_professional     => l_prof_ids(1),
                                                    i_id_room             => NULL,
                                                    i_id_clinical_service => NULL,
                                                    i_flg_type_dest       => NULL,
                                                    i_replace1            => NULL,
                                                    o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REQUEST_ALERT',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END set_request_alert;

    /*
    * Get Activity Therapist requests list.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             list of episodes
    * @param i_id_opinion_type        Id opinion type
    * @param i_start_date             Time period begin
    * @param i_end_date               Time period end
    * @param o_requests               requests cursor   
    * @param o_error                  error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  21-Jun-2010
    */
    FUNCTION get_request_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN table_number,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        i_start_date      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_requests        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        t_table_message_array pk_paramedical_prof_core.table_message_array;
        l_label_any_prof      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'CONSULT_REQUEST_T021');
    BEGIN
        g_error := 'GET_SOCIAL_REQUESTS_SUMMARY BEGIN';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('DIET_T009',
                                                                                          'CONSULT_REQUEST_T003',
                                                                                          'CONSULT_REQUEST_T024',
                                                                                          'SCH_T004'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        g_error := 'OPEN o_requests';
        OPEN o_requests FOR
            SELECT --o.id_opinion        id,
             o.id_episode_answer id_episode,
             o.id_episode        id_episode_origin,
             --
             pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T024')) ||
             nvl((SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                   FROM clinical_service cs
                  WHERE cs.id_clinical_service = o.id_clinical_service),
                 pk_paramedical_prof_core.c_dashes) request_type,
             --reason
             pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T003')) ||
             nvl(decode(o.id_opinion_type,
                        pk_opinion.g_ot_case_manager,
                        pk_opinion.get_cm_req_reason(i_lang, i_prof, o.id_opinion),
                        o.desc_problem),
                 pk_paramedical_prof_core.c_dashes) request_reason,
             --profissional      
             pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SCH_T004')) ||
             nvl2(o.id_prof_questioned,
                  pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                  l_label_any_prof) name_prof_request_type,
             --notas
             pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('DIET_T009')) || CASE
                  WHEN o.notes IS NULL
                       OR length(o.notes) = 0 THEN
                   pk_paramedical_prof_core.c_dashes
                  ELSE
                   to_char(o.notes)
              END prof_answers,
             pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                               i_prof,
                                                               o.dt_problem_tstz,
                                                               nvl(op.id_professional, o.id_prof_questions),
                                                               o.dt_last_update,
                                                               o.id_episode) last_update_info
              FROM opinion o
              LEFT OUTER JOIN opinion_prof op
                ON (o.id_opinion = op.id_opinion AND op.flg_type = 'E')
              LEFT OUTER JOIN opinion_type ot
                ON ot.id_opinion_type = o.id_opinion_type
              LEFT OUTER JOIN episode e
                ON e.id_episode = o.id_episode
            --LEFT OUTER JOIN epis_type et ON et.id_epis_type = e.id_epis_type
              LEFT OUTER JOIN clinical_service cs
                ON cs.id_clinical_service = o.id_clinical_service
             WHERE o.id_episode IN (SELECT column_value
                                      FROM TABLE(i_id_episode))
               AND (i_start_date IS NULL OR o.dt_problem_tstz >= i_start_date)
               AND (i_end_date IS NULL OR o.dt_problem_tstz <= i_end_date)
               AND o.id_opinion_type = i_id_opinion_type
             ORDER BY o.dt_approved DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REQUEST_SUMMARY',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            RETURN FALSE;
    END get_request_summary;

    /*
    * Get the request state.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_id_episode     list of episodes    
    * @param i_states         Request states to be considered
    * @param o_id_opinion     Request identifiers
    * @param o_flg_state      Request states
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  25-Jun-2010
    */
    FUNCTION get_request_states
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN opinion.id_episode%TYPE,
        i_states          IN table_varchar,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        o_data            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET_SOCIAL_REQUESTS_SUMMARY BEGIN';
        pk_alertlog.log_debug(g_error);
        OPEN o_data FOR
            SELECT o.flg_state, o.id_opinion, o.id_episode_answer
              FROM opinion o
             WHERE o.id_episode = i_id_episode
               AND o.flg_state IN (SELECT column_value
                                     FROM TABLE(i_states))
               AND o.id_opinion_type = i_id_opinion_type
            /*AND rownum = 1*/
            ;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_data);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REQUEST_STATES',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_request_states;

    /*******************************************************************************************
    * Gets total number of unanswered opinions
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_episode          opinion identifier
    * @param o_hist             cursor (info, details)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Alexandre Santos
    * @version                  2.5.0.7.8
    * @since                    06-09-2010
    ********************************************************************************************/
    FUNCTION get_total_unanswered_opinions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
        l_func_name VARCHAR2(30) := 'GET_TOTAL_UNANSWERED_OPINIONS';
        --
        l_total NUMBER(24) := NULL;
        --
        l_error t_error_out;
    BEGIN
        g_error := 'GET UNANSWERED OPINIONS';
        pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
        SELECT COUNT(*)
          INTO l_total
          FROM opinion o
         WHERE o.id_episode = i_episode
           AND nvl(o.flg_type, 'O') NOT IN (g_flg_type_nutritionist, g_flg_type_case_manager)
           AND o.flg_state NOT IN (pk_opinion.g_opinion_reply, pk_opinion.g_opinion_cancel)
           AND o.id_speciality IS NOT NULL;
    
        RETURN l_total;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_total_unanswered_opinions;

    /**
    * Resets consults requests. Used in ALERT RESET.
    *
    * @param i_lang             language identifier
    * @param i_table_id_opinion opinion identifiers
    * @param i_id_dummy_episode reset episode identifier
    * @param l_id_dummy_patient reset patient identifier
    * @param o_error            error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/15
    */
    FUNCTION reset_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_table_id_opinion IN table_number,
        i_id_dummy_episode IN episode.id_episode%TYPE,
        l_id_dummy_patient IN patient.id_patient%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT user_objects.object_name%TYPE := 'RESET_CONSULT_REQ';
        l_rowids table_varchar := table_varchar();
    BEGIN
        IF i_table_id_opinion IS NOT NULL
           AND i_table_id_opinion.count > 0
        THEN
            FOR i IN i_table_id_opinion.first .. i_table_id_opinion.last
            LOOP
                g_error := 'CALL ts_opinion.upd';
                ts_opinion.upd(id_opinion_in  => i_table_id_opinion(i),
                               id_episode_in  => i_id_dummy_episode,
                               id_episode_nin => FALSE,
                               id_patient_in  => l_id_dummy_patient,
                               id_patient_nin => FALSE,
                               rows_out       => l_rowids);
                g_error := 'CALL ts_opinion_hist.upd';
                ts_opinion_hist.upd(id_episode_in  => i_id_dummy_episode,
                                    id_episode_nin => FALSE,
                                    id_patient_in  => l_id_dummy_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_opinion = ' || i_table_id_opinion(i),
                                    rows_out       => l_rowids);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END reset_consult_req;

    /**
    * Calculate buttons status in opinions grid
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_prof_questions     ID of the professional that asked for the opinion
    * @param i_id_prof_questioned    ID of the professional that was asked 
    * @param i_id_specialty          ID of the specialty that was requested
    * @param i_flg_status            Current record status
    *
    * @return               flg_cancel | flg_ok | flg_co_sign_active;
    *
    * @author               Sergio Dias
    * @version              2.6.1.
    * @since                18/03/2011
    */
    FUNCTION get_buttons_state
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_questions   IN opinion.id_prof_questions%TYPE,
        i_id_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_id_specialty        IN opinion.id_speciality%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_status          IN opinion.flg_state%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT user_objects.object_name%TYPE := 'GET_BUTTONS_STATE';
        l_co_sign_enabled sys_config.value%TYPE;
    
        l_flg_cancel         VARCHAR2(1);
        l_flg_ok             VARCHAR2(1);
        l_flg_co_sign_active VARCHAR2(1);
    
        l_specialty               professional.id_speciality%TYPE;
        l_prof_cat                category.flg_type%TYPE;
        l_same_spec_or_clin_serv  BOOLEAN := FALSE;
        l_clin_serv_list          table_number;
        l_error                   t_error_out;
        l_clin_serv_exists        NUMBER := -1;
        l_consult_req_prof_cancel sys_config.value%TYPE := pk_sysconfig.get_config('CANCEL_CONSULT_OTHER_PROF', i_prof);
    BEGIN
        l_co_sign_enabled := pk_sysconfig.get_config(g_sys_config_consult_co_sign, i_prof);
        l_prof_cat        := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET BUTTONS STATE';
        pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
    
        IF (i_flg_status = g_opinion_req AND
           (i_prof.id = i_id_prof_questions OR l_consult_req_prof_cancel = pk_alert_constant.g_yes))
        THEN
            -- if record is available to cancel and professional is the one that created it
            l_flg_cancel := 'Y';
        ELSE
            l_flg_cancel := 'N';
        END IF;
    
        IF (i_flg_status = g_opinion_cancel OR l_prof_cat <> g_prof_doctor)
        THEN
            -- if record is canceled or answering professional is not a doctor
            l_flg_ok := 'N';
        ELSIF (i_prof.id = i_id_prof_questions AND l_co_sign_enabled = pk_alert_constant.get_no)
        THEN
            -- if co-sign is not enabled and the professional is the one that asked for the consult, ok button is disabled
            l_flg_ok := 'N';
        ELSIF i_prof.id = i_id_prof_questions
              AND l_co_sign_enabled = pk_alert_constant.get_yes
              AND i_flg_status NOT IN (g_opinion_req, g_opinion_req_read)
        THEN
            l_flg_ok := 'N';
        ELSE
            l_flg_ok := 'Y';
        END IF;
    
        IF i_id_prof_questioned IS NOT NULL -- opinion asked to a specific doctor
        THEN
            IF i_prof.id <> i_id_prof_questioned
               AND l_co_sign_enabled = pk_alert_constant.get_yes
            THEN
                -- if professional answering the question is not the one that it was asked to
                l_flg_co_sign_active := 'Y';
            ELSE
                l_flg_co_sign_active := 'N';
            END IF;
        ELSE
            --opinion asked to any doctor from that specialty/clincal service
            IF i_id_clinical_service IS NOT NULL
            THEN
                l_clin_serv_list := pk_prof_utils.get_list_prof_dep_clin_serv(i_lang  => i_lang,
                                                                              i_prof  => i_prof,
                                                                              o_error => l_error);
            
                SELECT COUNT(1)
                  INTO l_clin_serv_exists
                  FROM TABLE(l_clin_serv_list)
                 WHERE column_value = i_id_clinical_service;
            
                IF l_clin_serv_exists > 0
                THEN
                    l_same_spec_or_clin_serv := TRUE;
                END IF;
            ELSIF i_id_specialty IS NOT NULL
            THEN
                l_specialty := pk_prof_utils.get_prof_speciality_id(i_lang, i_prof);
                IF l_specialty = i_id_specialty
                THEN
                    l_same_spec_or_clin_serv := TRUE;
                END IF;
            END IF;
        
            IF NOT l_same_spec_or_clin_serv
               AND l_co_sign_enabled = pk_alert_constant.get_yes
            THEN
                -- if doctor answering is not from the required specialty
                l_flg_co_sign_active := 'Y';
            ELSE
                IF i_prof.id = i_id_prof_questions
                   AND l_co_sign_enabled = pk_alert_constant.get_yes
                THEN
                    -- if doctor answering is from the same specialty and is the one that asked for the consult
                    l_flg_co_sign_active := 'Y';
                ELSE
                    -- if doctor answering is from the same specialty and is the not one that asked for the consult
                    l_flg_co_sign_active := 'N';
                END IF;
            END IF;
        END IF;
        RETURN l_flg_cancel || '|' || l_flg_ok || '|' || l_flg_co_sign_active;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N|N|N';
    END get_buttons_state;

    FUNCTION get_buttons_state_cancel
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_questions   IN opinion.id_prof_questions%TYPE,
        i_id_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_id_specialty        IN opinion.id_speciality%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_status          IN opinion.flg_state%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT user_objects.object_name%TYPE := 'GET_BUTTONS_STATE';
        l_co_sign_enabled sys_config.value%TYPE;
    
        l_flg_cancel         VARCHAR2(1);
        l_flg_ok             VARCHAR2(1);
        l_flg_co_sign_active VARCHAR2(1);
    
        l_specialty               professional.id_speciality%TYPE;
        l_prof_cat                category.flg_type%TYPE;
        l_same_spec_or_clin_serv  BOOLEAN := FALSE;
        l_clin_serv_list          table_number;
        l_error                   t_error_out;
        l_clin_serv_exists        NUMBER := -1;
        l_consult_req_prof_cancel sys_config.value%TYPE := pk_sysconfig.get_config('CANCEL_CONSULT_OTHER_PROF', i_prof);
    BEGIN
        l_co_sign_enabled := pk_sysconfig.get_config(g_sys_config_consult_co_sign, i_prof);
        l_prof_cat        := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET BUTTONS STATE';
        pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
    
        IF (i_flg_status = g_opinion_req AND
           (i_prof.id = i_id_prof_questions OR l_consult_req_prof_cancel = pk_alert_constant.g_yes))
        THEN
            -- if record is available to cancel and professional is the one that created it
            l_flg_cancel := 'Y';
        ELSE
            l_flg_cancel := 'N';
        END IF;
    
        RETURN l_flg_cancel;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N|N|N';
    END get_buttons_state_cancel;

    FUNCTION get_buttons_state_ok
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_questions   IN opinion.id_prof_questions%TYPE,
        i_id_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_id_specialty        IN opinion.id_speciality%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_status          IN opinion.flg_state%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT user_objects.object_name%TYPE := 'GET_BUTTONS_STATE';
        l_co_sign_enabled sys_config.value%TYPE;
    
        l_flg_cancel         VARCHAR2(1);
        l_flg_ok             VARCHAR2(1);
        l_flg_co_sign_active VARCHAR2(1);
    
        l_specialty               professional.id_speciality%TYPE;
        l_prof_cat                category.flg_type%TYPE;
        l_same_spec_or_clin_serv  BOOLEAN := FALSE;
        l_clin_serv_list          table_number;
        l_error                   t_error_out;
        l_clin_serv_exists        NUMBER := -1;
        l_consult_req_prof_cancel sys_config.value%TYPE := pk_sysconfig.get_config('CANCEL_CONSULT_OTHER_PROF', i_prof);
    BEGIN
        l_co_sign_enabled := pk_sysconfig.get_config(g_sys_config_consult_co_sign, i_prof);
        l_prof_cat        := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET BUTTONS STATE';
        pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
    
        IF (i_flg_status = g_opinion_cancel OR l_prof_cat <> g_prof_doctor)
        THEN
            -- if record is canceled or answering professional is not a doctor
            l_flg_ok := 'N';
        ELSIF (i_prof.id = i_id_prof_questions AND l_co_sign_enabled = pk_alert_constant.get_no)
        THEN
            -- if co-sign is not enabled and the professional is the one that asked for the consult, ok button is disabled
            l_flg_ok := 'N';
        ELSIF i_prof.id = i_id_prof_questions
              AND l_co_sign_enabled = pk_alert_constant.get_yes
              AND i_flg_status NOT IN (g_opinion_req, g_opinion_req_read)
        THEN
            l_flg_ok := 'N';
        ELSE
            l_flg_ok := 'Y';
        END IF;
    
        RETURN l_flg_ok;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N|N|N';
    END get_buttons_state_ok;

    /**
    * Calculate professionals that can answer the question
    *
    * @param i_lang           Language ID
    * @param i_prof           Professional ID
    * @param i_id_episode     Episode ID
    * @param i_id_opinion     Opinion ID 
    * @param o_prof_list      Professional listing
    * @param o_error          Error control
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author               Sergio Dias
    * @version              2.6.1.
    * @since                18/03/2011
    */
    FUNCTION get_answer_profs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_opinion IN opinion.id_opinion%TYPE,
        o_prof_list  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT user_objects.object_name%TYPE := 'GET_ANSWER_PROFS';
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'GET ANSWER PROFESSIONALS';
        pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
        OPEN o_prof_list FOR
            SELECT DISTINCT data, label
              FROM (SELECT p.id_professional data,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) label
                      FROM professional p
                      JOIN prof_cat pc
                        ON pc.id_professional = p.id_professional
                       AND pk_prof_utils.get_category(i_lang,
                                                      profissional(p.id_professional, pc.id_institution, i_prof.software)) =
                           g_prof_doctor
                     WHERE p.id_professional IN
                           (SELECT *
                              FROM TABLE(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                             i_prof,
                                                                             i_id_episode,
                                                                             pk_prof_utils.get_category(i_lang, i_prof),
                                                                             l_hand_off_type)))
                    UNION ALL
                    SELECT o.id_prof_questioned data,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) label
                      FROM opinion o
                     WHERE o.id_opinion = i_id_opinion);
        RETURN TRUE;
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
            RETURN FALSE;
    END get_answer_profs;

    /**
    * Create a record usign co-sign framework
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional ID
    * @param i_id_episode          Episode ID
    * @param i_id_opinion          Opinion ID 
    * @param i_desc                Question description 
    * @param i_flg_face_to_face    Face to face flag
    * @param i_id_prof_questioned  ID of the professional that was asked the question
    * @param i_id_order_type       Order type ID 
    * @param i_dt_opinion          Date when the opinion was answered
    * @param o_error               Error control
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author               Sergio Dias
    * @version              2.6.1.
    * @since                18/03/2011
    */
    FUNCTION create_opinion_co_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_opinion         IN opinion.id_opinion%TYPE,
        i_desc               IN opinion.desc_problem%TYPE,
        i_flg_face_to_face   IN opinion_prof.flg_face_to_face%TYPE DEFAULT g_unknown,
        i_id_prof_questioned IN opinion_prof.id_prof_co_sign%TYPE,
        i_id_order_type      IN order_type.id_order_type%TYPE,
        i_dt_opinion         IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT user_objects.object_name%TYPE := 'CREATE_OPINION_CO_SIGN';
        l_seq opinion_prof.id_opinion_prof%TYPE;
    
        l_rows           table_varchar := table_varchar();
        l_dpd_rowids_upd table_varchar;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET UNANSWERED OPINIONS';
        SELECT seq_opinion_prof.nextval
          INTO l_seq
          FROM dual;
    
        g_error := 'GET UNANSWERED OPINIONS';
        pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
        ts_opinion_prof.ins(id_opinion_prof_in      => l_seq,
                            dt_opinion_prof_tstz_in => pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_opinion, NULL),
                            id_opinion_in           => i_id_opinion,
                            flg_type_in             => g_opinion_reply,
                            id_professional_in      => i_id_prof_questioned,
                            desc_reply_in           => i_desc,
                            flg_face_to_face_in     => nvl(i_flg_face_to_face, g_unknown),
                            id_order_type_in        => i_id_order_type,
                            rows_out                => l_dpd_rowids_upd);
    
        IF NOT alert_opinion_reply(i_lang            => i_lang,
                                   i_opinion         => i_id_opinion,
                                   i_flg_type        => g_opin_prof_reply,
                                   i_flg_type_opinon => NULL,
                                   o_error           => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        l_dpd_rowids_upd := table_varchar();
        g_error          := 'UPDATE OPINION_PROF';
        ts_opinion_prof.upd(id_opinion_prof_in  => l_seq,
                            id_prof_co_sign_in  => i_prof.id,
                            id_prof_co_sign_nin => FALSE,
                            flg_co_sign_in      => pk_co_sign.flg_co_sign_yes,
                            flg_co_sign_nin     => FALSE,
                            notes_co_sign_in    => '',
                            notes_co_sign_nin   => FALSE,
                            dt_co_sign_in       => g_sysdate_tstz,
                            dt_co_sign_nin      => FALSE,
                            rows_out            => l_dpd_rowids_upd);
    
        g_error := 'UPDATE OPINION';
        ts_opinion.upd(flg_state_in => g_opinion_reply, id_opinion_in => i_id_opinion, rows_out => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_opinion';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'OPINION',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATE'));
    
        g_error := 'CALL pk_alerts.delete_sys_alert_event';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_id_sys_alert => g_alert_type_consult_question,
                                                i_id_record    => i_id_opinion,
                                                o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET UNANSWERED OPINIONS';
        IF NOT pk_patient_tracking.set_after_opinion_status(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_episode    => i_id_episode,
                                                            i_flg_status => g_opinion_reply,
                                                            o_error      => o_error)
        THEN
            RAISE e_pat_tracking;
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
                                              'CREATE_OPIN_PROF_INT',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /*
    * Get the description of a consult to use on single pages import mechanismpo
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param i_opinion_type   patient identifier
    * @param i_flg_short      Short descritpion or long descritpion (Y - short description)
    * @param i_flg_description Flag that indicates if the description condition must be followed
    * @param i_description_condition Condition for the description
    * @param i_flg_desc_for_dblock Flag that indicates if the description is for the dblock or not
    *
    * @return                 Consult description
    *
    * @author                 S?io Santos
    * @version                2.6.2
    * @since                  2012/08/22
    */
    FUNCTION get_sp_consult_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_opinion               IN opinion.id_opinion%TYPE,
        i_opinion_type          IN opinion_type.id_opinion_type%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char,
        i_flg_short             IN VARCHAR2 DEFAULT 'N'
    ) RETURN CLOB IS
        l_code_cs CONSTANT translation.code_translation%TYPE := 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.';
        l_code_s  CONSTANT translation.code_translation%TYPE := 'SPECIALITY.CODE_SPECIALITY.';
    
        --
        l_specialty           VARCHAR2(1000 CHAR);
        l_physician_requested VARCHAR2(1000 CHAR);
        l_prof_reply          VARCHAR2(1000 CHAR);
        l_prof_questions      VARCHAR2(1000 CHAR);
        l_prof_questioned     VARCHAR2(1000 CHAR);
        l_requested_date      VARCHAR2(1000 CHAR);
        l_status              VARCHAR2(1000 CHAR);
        l_category            VARCHAR2(1000 CHAR);
        --
        l_description_split   table_varchar;
        l_token_list          table_varchar;
        l_reply               opinion_prof.desc_reply%TYPE;
        l_reply_date          VARCHAR2(1000 CHAR);
        l_request_date        VARCHAR2(1000 CHAR);
        l_description_opinion CLOB;
        l_desc_problem        opinion.desc_problem%TYPE;
        l_req_by_label        VARCHAR2(1000 CHAR);
        l_for_spec_label      VARCHAR2(1000 CHAR);
        l_for_spec            VARCHAR2(1000 CHAR);
        l_for_phys            VARCHAR2(1000 CHAR);
        l_answ_by_label       VARCHAR2(1000 CHAR);
        l_answ_by             VARCHAR2(1000 CHAR);
        l_status_by_label     VARCHAR2(1000 CHAR);
        -- 
        l_priority                VARCHAR2(25);
        l_priority_label          VARCHAR2(1000 CHAR);
        l_opinion_type            VARCHAR2(1000 CHAR);
        l_opinion_label           VARCHAR2(1000 CHAR);
        l_request_reason          VARCHAR2(1000 CHAR);
        l_request_reason_label    VARCHAR2(1000 CHAR);
        l_request_reason_ft_label VARCHAR2(1000 CHAR);
        l_professional_label      VARCHAR2(1000 CHAR);
        l_notes_label             VARCHAR2(1000 CHAR);
        l_notes                   CLOB;
        l_status_label            VARCHAR2(1000 CHAR);
        l_decline_reason_label    VARCHAR2(1000 CHAR);
        l_decline_reason          VARCHAR2(1000 CHAR);
    
        FUNCTION get_description(i_token_list table_varchar) RETURN VARCHAR2 IS
            l_description CLOB;
        
        BEGIN
            FOR i IN 1 .. i_token_list.last
            LOOP
                IF i_token_list(i) = 'CATEGORY'
                THEN
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_comma || l_category;
                    ELSE
                        l_description := l_description || l_category;
                    END IF;
                ELSIF i_token_list(i) = 'DESCRIPTION'
                THEN
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_comma || l_desc_problem;
                    ELSE
                        l_description := l_description || l_desc_problem;
                    END IF;
                ELSIF i_token_list(i) = 'DESCRIPTION-LABEL'
                THEN
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || l_desc_problem || chr(10);
                    ELSE
                        l_description := l_description || l_desc_problem;
                    END IF;
                ELSIF i_token_list(i) = 'START-DATE'
                THEN
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_comma || l_request_date;
                    ELSE
                        l_description := l_description || l_request_date;
                    END IF;
                ELSIF l_token_list(i) = 'REPLY-DATE'
                THEN
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_comma || l_reply_date;
                    ELSE
                        l_description := l_description || l_reply_date;
                    END IF;
                ELSIF i_token_list(i) = 'SPEC'
                THEN
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_comma || l_specialty;
                    ELSE
                        l_description := l_description || l_specialty;
                    END IF;
                
                ELSIF i_token_list(i) = 'STATUS'
                THEN
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_comma || l_status;
                    ELSE
                        l_description := l_description || l_status;
                    END IF;
                ELSIF i_token_list(i) = 'ANSWER'
                THEN
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_comma || l_reply;
                    ELSE
                        l_description := l_description || l_reply;
                    END IF;
                ELSIF i_token_list(i) = 'REQUESTBY'
                THEN
                    l_description := l_description || l_req_by_label || pk_prog_notes_constants.g_colon ||
                                     l_prof_questions || pk_prog_notes_constants.g_flg_sep || l_request_date || chr(10);
                
                ELSIF i_token_list(i) = 'FORSPEC'
                THEN
                    IF l_prof_questioned IS NOT NULL
                    THEN
                        l_for_spec := pk_prog_notes_constants.g_flg_sep || l_prof_questioned;
                    ELSE
                        l_for_spec := NULL;
                    END IF;
                
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || l_for_spec_label || pk_prog_notes_constants.g_colon ||
                                         l_specialty || l_for_spec || chr(10);
                    ELSE
                        l_description := l_description || l_for_spec_label || pk_prog_notes_constants.g_colon ||
                                         l_specialty || l_for_spec || chr(10);
                    END IF;
                
                ELSIF i_token_list(i) = 'FORPHYS'
                THEN
                    IF l_prof_questioned IS NOT NULL
                    THEN
                        l_for_phys := l_prof_questioned;
                    ELSE
                        l_for_phys := NULL;
                    END IF;
                
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_comma || l_for_phys;
                    
                    ELSE
                        l_description := l_description || l_for_phys;
                    END IF;
                
                ELSIF i_token_list(i) = 'ANSWERBY'
                THEN
                    IF l_prof_reply IS NOT NULL
                    THEN
                        l_answ_by := l_answ_by_label || pk_prog_notes_constants.g_colon || l_prof_reply ||
                                     pk_prog_notes_constants.g_flg_sep || l_specialty;
                    ELSE
                        l_answ_by := NULL;
                    END IF;
                    IF l_description IS NOT NULL
                    THEN
                        l_description := l_description || l_answ_by || chr(10);
                    ELSE
                        l_description := l_description || l_answ_by || chr(10);
                    END IF;
                ELSIF i_token_list(i) = 'PRIORITY'
                THEN
                    IF l_description IS NOT NULL
                       AND l_priority IS NOT NULL
                    THEN
                        l_description := l_description || pk_prog_notes_constants.g_comma || l_priority;
                    ELSE
                        l_description := l_description || l_priority;
                    END IF;
                ELSIF i_token_list(i) = 'PRIORITY-LABEL'
                THEN
                    IF l_description IS NOT NULL
                       AND l_priority IS NOT NULL
                    THEN
                        l_description := l_description || l_priority_label || pk_prog_notes_constants.g_colon ||
                                         l_priority || chr(10);
                    END IF;
                ELSIF i_token_list(i) = 'FOLLOW_UP_TYPE'
                THEN
                    IF l_opinion_type IS NOT NULL
                    THEN
                        l_description := l_description || l_opinion_label || pk_prog_notes_constants.g_colon ||
                                         l_opinion_type || chr(10);
                    END IF;
                ELSIF i_token_list(i) = 'REQUEST_REASON'
                THEN
                    IF l_request_reason IS NOT NULL
                    THEN
                        l_description := l_description || l_request_reason_label || pk_prog_notes_constants.g_colon ||
                                         l_request_reason || chr(10);
                    END IF;
                ELSIF i_token_list(i) = 'REQUEST_REASON_FT'
                THEN
                    IF l_desc_problem IS NOT NULL
                    THEN
                        l_description := l_description || l_request_reason_ft_label || pk_prog_notes_constants.g_colon ||
                                         l_desc_problem || chr(10);
                    END IF;
                ELSIF i_token_list(i) = 'PROFESSIONAL'
                THEN
                    IF l_prof_questioned IS NOT NULL
                    THEN
                        l_description := l_description || l_professional_label || pk_prog_notes_constants.g_colon ||
                                         l_prof_questioned || chr(10);
                    END IF;
                ELSIF i_token_list(i) = 'NOTES'
                THEN
                    IF l_notes IS NOT NULL
                       AND dbms_lob.getlength(l_notes) > 0
                    THEN
                        l_description := l_description || l_notes_label || pk_prog_notes_constants.g_colon || l_notes ||
                                         chr(10);
                    END IF;
                ELSIF i_token_list(i) = 'STATUS_LABEL'
                THEN
                    l_description := l_description || l_status_label || pk_prog_notes_constants.g_colon || l_status ||
                                     chr(10);
                ELSIF i_token_list(i) = 'REJECT_REASON'
                THEN
                    IF l_decline_reason IS NOT NULL
                    THEN
                        l_description := l_description || l_decline_reason_label || pk_prog_notes_constants.g_colon ||
                                         l_decline_reason || chr(10);
                    END IF;
                ELSIF i_token_list(i) = 'ANSWER_LABEL'
                THEN
                    IF l_reply IS NOT NULL
                    THEN
                        l_description := l_description || l_notes_label || pk_prog_notes_constants.g_colon || l_reply;
                    END IF;
                END IF;
            END LOOP;
            RETURN l_description;
        END;
    BEGIN
        l_priority_label          := pk_message.get_message(i_lang => i_lang, i_code_mess => 'OPINION_M021');
        l_opinion_label           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'P1_DOCTOR_REQ_T004');
        l_request_reason_label    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'COMMON_T063');
        l_request_reason_ft_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CONSULT_REQUEST_T025');
        l_professional_label      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CONSULT_REQUEST_T026');
        l_notes_label             := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CONSULT_REQUEST_T027');
        l_status_label            := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CONSULT_REQUEST_T057');
        l_decline_reason_label    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'CONSULT_REQUEST_T049');
    
        SELECT
        --Request specialty
         pk_translation.get_translation(i_lang,
                                        decode(o.id_clinical_service,
                                               NULL,
                                               l_code_s || o.id_speciality,
                                               l_code_cs || o.id_clinical_service)),
         -- physician who responded to the consult
         decode(op.id_professional,
                NULL,
                (pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions)),
                (pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional))),
         --Requested date: Date and time OR Replied date:
         decode(op.dt_opinion_prof_tstz,
                NULL,
                pk_date_utils.date_char_tsz(i_lang, o.dt_problem_tstz, i_prof.institution, i_prof.software),
                pk_date_utils.date_char_tsz(i_lang, op.dt_opinion_prof_tstz, i_prof.institution, i_prof.software)),
         --Status
         pk_sysdomain.get_domain('OPINION.FLG_STATE', o.flg_state, i_lang),
         op.desc_reply,
         pk_date_utils.date_char_tsz(i_lang, op.dt_opinion_prof_tstz, i_prof.institution, i_prof.software) dt_reply,
         pk_date_utils.date_char_tsz(i_lang, o.dt_problem_tstz, i_prof.institution, i_prof.software) dt_request,
         o.desc_problem,
         pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang),
         decode(op.id_professional, NULL, NULL, (pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional))),
         pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions),
         decode(op.id_professional,
                NULL,
                (pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned)),
                (pk_prof_utils.get_name_signature(i_lang, i_prof, op.id_professional))),
         pk_translation.get_translation(i_lang, ot.code_opinion_type),
         pk_opinion.get_cm_req_reason(i_lang, i_prof, o.id_opinion),
         o.notes,
         (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
            FROM cancel_reason cr
           WHERE cr.id_cancel_reason = op.id_cancel_reason)
          INTO l_specialty,
               l_physician_requested,
               l_requested_date,
               l_status,
               l_reply,
               l_reply_date,
               l_request_date,
               l_desc_problem,
               l_priority,
               l_prof_reply,
               l_prof_questions,
               l_prof_questioned,
               l_opinion_type,
               l_request_reason,
               l_notes,
               l_decline_reason
          FROM opinion o
          LEFT JOIN opinion_prof op
            ON op.id_opinion = o.id_opinion
           AND op.flg_type <> g_opin_prof_read
          LEFT JOIN opinion_type ot
            ON ot.id_opinion_type = o.id_opinion_type
        
         WHERE o.id_opinion = i_opinion
           AND (op.dt_opinion_prof_tstz = (SELECT MAX(dt_opinion_prof_tstz)
                                             FROM opinion_prof
                                            WHERE id_opinion = o.id_opinion
                                              AND flg_type <> g_opin_prof_read) OR op.dt_opinion_prof_tstz IS NULL);
    
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
            l_description_opinion := NULL;
            l_category            := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T190');
            l_description_split   := pk_string_utils.str_split(i_list => i_description_condition, i_delim => ';');
            l_req_by_label        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'OPINION_T005');
            l_for_spec_label      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T208');
            l_answ_by_label       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T209');
            l_status_by_label     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'OPINION_T006');
        
            IF (i_flg_desc_for_dblock = pk_prog_notes_constants.g_yes)
            THEN
                l_token_list := pk_string_utils.str_split(i_list => l_description_split(1), i_delim => '|');
            
                l_description_opinion := get_description(l_token_list);
            ELSE
                l_token_list          := pk_string_utils.str_split(i_list => l_description_split(2), i_delim => '|');
                l_description_opinion := get_description(l_token_list);
            END IF;
        
        ELSE
            IF l_priority IS NULL
            THEN
                l_description_opinion := l_specialty || pk_prog_notes_constants.g_comma || l_physician_requested ||
                                         pk_prog_notes_constants.g_comma || l_requested_date ||
                                         pk_prog_notes_constants.g_comma || l_status;
            ELSE
                l_description_opinion := l_specialty || pk_prog_notes_constants.g_comma || l_physician_requested ||
                                         pk_prog_notes_constants.g_comma || l_requested_date ||
                                         pk_prog_notes_constants.g_comma || l_priority ||
                                         pk_prog_notes_constants.g_comma || l_status;
            END IF;
        END IF;
    
        RETURN l_description_opinion;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_sp_consult_desc;

    /************************************************************************************************************
    * This function returns the professionals for a clinical service that can give a consult (opinion)
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      i_speciality      Speciality id for the consult
    * @param      o_prof            Professionals output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     CRS
    * @version    1.0
    * @since      2005/03/10
    ************************************************************************************************************/
    FUNCTION get_prof_clin_serv_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_clin_serv_id IN clinical_service.id_clinical_service%TYPE,
        o_prof         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT obj_name := 'GET_CLIN_SERV_LIST';
        l_message debug_msg;
    
        l_opt_func_id prof_func.id_functionality%TYPE;
        l_prof_cat    category.flg_type%TYPE;
    
    BEGIN
        l_message     := 'GET CONFIG';
        l_opt_func_id := pk_sysconfig.get_config(i_code_cf   => 'FUNCTIONALITY_OPINION',
                                                 i_prof_inst => i_prof.institution,
                                                 i_prof_soft => i_prof.software);
    
        l_message := 'GET PROFESSIONAL CATEGORY';
        IF pk_sysconfig.get_config('SET_OPINION_ONLY_DOC', i_prof) = pk_alert_constant.g_no
        THEN
            l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        ELSE
            l_prof_cat := pk_alert_constant.g_cat_type_doc;
        END IF;
    
        l_message := 'OPEN O_PROF';
        OPEN o_prof FOR
            SELECT DISTINCT p.id_professional,
                            1 AS rank,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS nick_name
              FROM professional p
             INNER JOIN prof_institution pi
                ON p.id_professional = pi.id_professional
             INNER JOIN prof_func pf
                ON p.id_professional = pf.id_professional
               AND pi.id_institution = pi.id_institution
             INNER JOIN prof_cat pc
                ON p.id_professional = pc.id_professional
               AND pi.id_institution = pc.id_institution
             INNER JOIN category c
                ON pc.id_category = c.id_category
             INNER JOIN prof_dep_clin_serv pdcs
                ON pdcs.id_professional = p.id_professional
               AND pdcs.id_institution = i_prof.institution
             INNER JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
             INNER JOIN clinical_service cs
                ON cs.id_clinical_service = dcs.id_clinical_service
             WHERE p.id_professional != i_prof.id
               AND p.flg_state = g_prof_active
               AND pi.id_institution = i_prof.institution
               AND pi.flg_state = g_prof_active
               AND pi.dt_end_tstz IS NULL
               AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, pi.id_institution) =
                   pk_alert_constant.g_yes
               AND pf.id_functionality = l_opt_func_id
               AND c.flg_type = l_prof_cat
               AND dcs.id_clinical_service = i_clin_serv_id
            UNION ALL
            SELECT -1 AS id_professional,
                   -1 AS rank,
                   pk_message.get_message(i_lang, i_prof, 'OPINION_M001') AS nick_name
              FROM dual
             WHERE i_clin_serv_id IS NOT NULL
             ORDER BY rank, nick_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_prof);
            RETURN FALSE;
    END get_prof_clin_serv_list;

    FUNCTION get_prof_clin_serv_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_clin_serv_id IN clinical_service.id_clinical_service%TYPE,
        o_error        OUT t_error_out
    ) RETURN t_tbl_core_domain IS
        l_func_name CONSTANT obj_name := 'GET_CLIN_SERV_LIST';
        l_message debug_msg;
    
        l_opt_func_id prof_func.id_functionality%TYPE;
        l_prof_cat    category.flg_type%TYPE;
    
        l_ret t_tbl_core_domain;
    BEGIN
        l_message     := 'GET CONFIG';
        l_opt_func_id := pk_sysconfig.get_config(i_code_cf   => 'FUNCTIONALITY_OPINION',
                                                 i_prof_inst => i_prof.institution,
                                                 i_prof_soft => i_prof.software);
    
        l_message := 'GET PROFESSIONAL CATEGORY';
        IF pk_sysconfig.get_config('SET_OPINION_ONLY_DOC', i_prof) = pk_alert_constant.g_no
        THEN
            l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
        ELSE
            l_prof_cat := pk_alert_constant.g_cat_type_doc;
        END IF;
    
        l_message := 'OPEN L_RET';
    
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => nick_name,
                                         domain_value  => id_professional,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT DISTINCT p.id_professional,
                                        1 AS rank,
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS nick_name
                          FROM professional p
                         INNER JOIN prof_institution pi
                            ON p.id_professional = pi.id_professional
                         INNER JOIN prof_func pf
                            ON p.id_professional = pf.id_professional
                           AND pi.id_institution = pi.id_institution
                         INNER JOIN prof_cat pc
                            ON p.id_professional = pc.id_professional
                           AND pi.id_institution = pc.id_institution
                         INNER JOIN category c
                            ON pc.id_category = c.id_category
                         INNER JOIN prof_dep_clin_serv pdcs
                            ON pdcs.id_professional = p.id_professional
                           AND pdcs.id_institution = i_prof.institution
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                         INNER JOIN clinical_service cs
                            ON cs.id_clinical_service = dcs.id_clinical_service
                         WHERE p.id_professional != i_prof.id
                           AND p.flg_state = g_prof_active
                           AND pi.id_institution = i_prof.institution
                           AND pi.flg_state = g_prof_active
                           AND pi.dt_end_tstz IS NULL
                           AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, pi.id_institution) =
                               pk_alert_constant.g_yes
                           AND pf.id_functionality = l_opt_func_id
                           AND c.flg_type = l_prof_cat
                           AND (dcs.id_clinical_service = i_clin_serv_id OR i_clin_serv_id IS NULL)
                        UNION ALL
                        SELECT -1 AS id_professional,
                               -1 AS rank,
                               pk_message.get_message(i_lang, i_prof, 'COMMON_M059') AS nick_name
                          FROM dual
                         WHERE i_clin_serv_id IS NOT NULL
                         ORDER BY rank, nick_name));
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_prof_clin_serv_list;

    /************************************************************************************************************
    * This function returns the clinical services of the professionals that can give a consult (opinion).
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      o_spec            Clinical services output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Sergio Dias
    * @version    2.6.3.9
    * @since      Dec/9/2013
    ************************************************************************************************************/
    FUNCTION get_clin_serv_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT obj_name := 'GET_CLIN_SERV_LIST';
        l_id_functionality sys_config.value%TYPE;
    BEGIN
        g_error := 'LOAD SYSCONFIG FUNCTIONALITY_OPINION';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_id_functionality := pk_sysconfig.get_config(i_code_cf   => 'FUNCTIONALITY_OPINION',
                                                      i_prof_inst => i_prof.institution,
                                                      i_prof_soft => i_prof.software);
    
        g_error := 'LOAD CURSOR O_CLIN_SERV';
        pk_alertlog.log_debug(g_error, g_package_name);
        OPEN o_clin_serv FOR
            SELECT identifier, pk_translation.get_translation(i_lang, code) description
              FROM (SELECT DISTINCT dcs.id_clinical_service identifier, cli.code_clinical_service code
                      FROM dep_clin_serv dcs
                      JOIN clinical_service cli
                        ON cli.id_clinical_service = dcs.id_clinical_service
                      JOIN department dpt
                        ON dpt.id_department = dcs.id_department
                      JOIN prof_dep_clin_serv pdc
                        ON pdc.id_dep_clin_serv = dcs.id_dep_clin_serv
                      JOIN software_dept sdt
                        ON sdt.id_dept = dpt.id_dept
                      JOIN prof_institution pi
                        ON pdc.id_professional = pi.id_professional
                      JOIN professional p
                        ON p.id_professional = pdc.id_professional
                      JOIN prof_func pf
                        ON p.id_professional = pf.id_professional
                       AND pi.id_institution = pf.id_institution
                     WHERE p.id_professional != i_prof.id
                       AND pdc.flg_status = 'S'
                       AND dcs.flg_available = pk_alert_constant.g_yes
                       AND cli.flg_available = pk_alert_constant.g_yes
                       AND sdt.id_software = i_prof.software
                       AND dpt.id_institution = i_prof.institution
                       AND p.flg_state = g_prof_active
                       AND pi.id_institution = i_prof.institution
                       AND pi.flg_state = g_prof_active
                       AND pi.dt_end_tstz IS NULL
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, pi.id_institution) =
                           pk_alert_constant.g_yes
                       AND pf.id_functionality = l_id_functionality)
             ORDER BY description ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_clin_serv);
            RETURN FALSE;
    END get_clin_serv_list;

    FUNCTION get_clin_serv_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain IS
        l_func_name CONSTANT obj_name := 'GET_CLIN_SERV_LIST';
        l_id_functionality sys_config.value%TYPE;
    
        l_ret t_tbl_core_domain;
    BEGIN
        g_error := 'LOAD SYSCONFIG FUNCTIONALITY_OPINION';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        l_id_functionality := pk_sysconfig.get_config(i_code_cf   => 'FUNCTIONALITY_OPINION',
                                                      i_prof_inst => i_prof.institution,
                                                      i_prof_soft => i_prof.software);
    
        g_error := 'OPEN L_RET';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => description,
                                         domain_value  => identifier,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT identifier, pk_translation.get_translation(i_lang, code) description
                          FROM (SELECT DISTINCT dcs.id_clinical_service identifier, cli.code_clinical_service code
                                  FROM dep_clin_serv dcs
                                  JOIN clinical_service cli
                                    ON cli.id_clinical_service = dcs.id_clinical_service
                                  JOIN department dpt
                                    ON dpt.id_department = dcs.id_department
                                  JOIN prof_dep_clin_serv pdc
                                    ON pdc.id_dep_clin_serv = dcs.id_dep_clin_serv
                                  JOIN software_dept sdt
                                    ON sdt.id_dept = dpt.id_dept
                                  JOIN prof_institution pi
                                    ON pdc.id_professional = pi.id_professional
                                  JOIN professional p
                                    ON p.id_professional = pdc.id_professional
                                  JOIN prof_func pf
                                    ON p.id_professional = pf.id_professional
                                   AND pi.id_institution = pf.id_institution
                                 WHERE p.id_professional != i_prof.id
                                   AND pdc.flg_status = 'S'
                                   AND dcs.flg_available = pk_alert_constant.g_yes
                                   AND cli.flg_available = pk_alert_constant.g_yes
                                   AND sdt.id_software = i_prof.software
                                   AND dpt.id_institution = i_prof.institution
                                   AND p.flg_state = g_prof_active
                                   AND pi.id_institution = i_prof.institution
                                   AND pi.flg_state = g_prof_active
                                   AND pi.dt_end_tstz IS NULL
                                   AND pk_prof_utils.is_internal_prof(i_lang, i_prof, p.id_professional, pi.id_institution) =
                                       pk_alert_constant.g_yes
                                   AND pf.id_functionality = l_id_functionality))
                 ORDER BY description ASC);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_clin_serv_list;

    FUNCTION get_clin_serv_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE
    ) RETURN t_tbl_core_domain IS
        l_func_name CONSTANT obj_name := 'GET_CLIN_SERV_LIST';
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        g_error := 'OPEN L_RET';
        pk_alertlog.log_debug(g_error, g_package_name);
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => label,
                                         domain_value  => data,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT otcs.id_clinical_service data,
                               pk_translation.get_translation(i_lang, cs.code_clinical_service) label
                          FROM (SELECT otcs.id_clinical_service,
                                       row_number() over(PARTITION BY otcs.id_clinical_service ORDER BY otcs.id_institution DESC, otcs.id_software DESC) rn
                                  FROM opinion_type_clin_serv otcs
                                 WHERE otcs.id_opinion_type = i_opinion_type
                                   AND otcs.id_software IN (0, i_prof.software)
                                   AND otcs.id_institution IN (0, i_prof.institution)
                                   AND otcs.flg_available = pk_alert_constant.g_yes) otcs
                          JOIN clinical_service cs
                            ON otcs.id_clinical_service = cs.id_clinical_service
                         WHERE otcs.rn = 1
                           AND cs.flg_available = pk_alert_constant.g_yes)
                 ORDER BY label);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_clin_serv_list;

    /************************************************************************************************************
    * This function returns if has one or more profissional.
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      o_spec            Clinical services output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Jorge Silva
    * @version    2.6.3.14
    * @since      28/03/2014
    ************************************************************************************************************/
    FUNCTION get_has_multiple_prof
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT obj_name := 'GET_HAS_MULTIPLE_PROF';
        l_count_prof NUMBER := 0;
        l_cat        table_number;
    
        CURSOR c_cat IS
            SELECT ot.id_category
              FROM opinion_type_category ot
             WHERE ot.id_opinion_type = i_opinion_type;
    BEGIN
        g_error := 'OPEN c_cat';
        OPEN c_cat;
        FETCH c_cat BULK COLLECT
            INTO l_cat;
        CLOSE c_cat;
    
        IF i_clin_serv IS NULL
        THEN
            g_error := 'OPEN o_prof_list';
            SELECT COUNT(*)
              INTO l_count_prof
              FROM (SELECT DISTINCT pi.id_professional
                      FROM prof_cat pc
                      JOIN (SELECT t.column_value id_category
                             FROM TABLE(l_cat) t) cat
                        ON cat.id_category = pc.id_category
                      JOIN prof_institution pi
                        ON pi.id_professional = pc.id_professional
                       AND pi.id_institution = i_prof.institution
                       AND pi.flg_state = g_prof_active
                       AND pi.dt_end_tstz IS NULL
                       AND pi.flg_external = pk_alert_constant.g_no
                     WHERE pc.id_institution = i_prof.institution
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pc.id_professional, i_prof.institution) =
                           pk_alert_constant.g_yes) t;
        ELSE
            g_error := 'OPEN o_prof_list';
            SELECT COUNT(*)
              INTO l_count_prof
              FROM (SELECT DISTINCT pi.id_professional
                      FROM dep_clin_serv dcs
                      JOIN prof_dep_clin_serv pdcs
                        ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                      JOIN prof_cat pc
                        ON pdcs.id_professional = pc.id_professional
                      JOIN (SELECT t.column_value id_category
                             FROM TABLE(l_cat) t) cat
                        ON cat.id_category = pc.id_category
                      JOIN prof_institution pi
                        ON pi.id_professional = pdcs.id_professional
                       AND pi.id_institution = i_prof.institution
                       AND pi.flg_state = g_prof_active
                       AND pi.dt_end_tstz IS NULL
                       AND pi.flg_external = pk_alert_constant.g_no
                     WHERE dcs.id_clinical_service = i_clin_serv
                       AND dcs.flg_available = pk_alert_constant.g_yes
                       AND pdcs.id_institution = i_prof.institution
                       AND pdcs.flg_status = pk_alert_constant.g_status_selected
                       AND pc.id_institution = i_prof.institution
                       AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pdcs.id_professional, i_prof.institution) =
                           pk_alert_constant.g_yes);
        END IF;
    
        IF (l_count_prof > 1)
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN pk_alert_constant.g_no;
        
    END get_has_multiple_prof;

    /********************************************************************************************
    * Gets the requested consultations
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @o_consults             List of Consults 
    * @o_actions              List of possible actions   
    * @param o_error          Error message     
    *
    * @return                 true or false on success or error
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.3.8.2
    * @since                  2015/01/27
    **********************************************************************************************/
    FUNCTION get_requested_opinion
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_consults OUT pk_types.cursor_type,
        o_actions  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_documented sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M107');
        l_space      VARCHAR2(2 CHAR) := ' ';
        l_any_doctor sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'OPINION_T019');
        l_actions    t_coll_action;
        l_subject    action.subject%TYPE := 'OPINION';
    
        --
        l_consult_area        VARCHAR2(7) := 'CONSULT';
        l_cons_rep_permission VARCHAR(1);
        l_error               t_error_out;
    
    BEGIN
        /*INIT*/
        OPEN o_consults FOR
            SELECT o.id_opinion consult_request_id,
                   pk_translation.get_translation(i_lang, s.code_speciality) || ' - ' ||
                   decode(o.id_prof_questioned,
                          NULL,
                          l_any_doctor,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned)) consult_request_title,
                   o.desc_problem consult_request_notes,
                   l_documented || l_space || pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions) || '(' ||
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    o.id_prof_questions,
                                                    o.dt_problem_tstz,
                                                    o.id_episode) || ');' || l_space ||
                   pk_date_utils.date_char_tsz(i_lang, dt_problem_tstz, i_prof.institution, i_prof.software) consult_request_prof,
                   pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang) priority,
                   pk_message.get_message(i_lang, 'OPINION_M021') || ':' AS title_priority
              FROM opinion o, speciality s
             WHERE o.id_episode = i_episode
               AND o.id_opinion_type IS NULL
               AND s.id_speciality(+) = o.id_speciality
               AND o.flg_state IN (g_opinion_req, g_opinion_req_read)
               AND o.id_prof_questions <> i_prof.id
             ORDER BY o.dt_problem_tstz DESC;
    
        /*CHECK REPLY PERMISSION*/
    
        IF NOT pk_ehr_access.check_area_create_permission(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          i_area    => l_consult_area,
                                                          o_val     => l_cons_rep_permission,
                                                          o_error   => l_error)
        THEN
            RETURN FALSE;
        END IF;
    
        OPEN o_actions FOR
            SELECT o.id_opinion consult_request_id,
                   o.flg_state flg_state,
                   act.action response_id,
                   act.desc_action response_label,
                   CASE
                        WHEN act.action = 'L' THEN
                         l_cons_rep_permission
                        ELSE
                         NULL
                    END flg_can_reply, /*para o debug*/
                   decode(act.action, /*a? a avaliar */
                          'L', /*Reply*/
                          decode(l_cons_rep_permission,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_active,
                                 pk_alert_constant.g_inactive),
                          'F', /*Mark as read*/
                          decode(o.flg_state, /*estado da requisi?*/
                                 'R', /*validar se est?ido (R = Requisitado)*/
                                 pk_alert_constant.g_active,
                                 pk_alert_constant.g_inactive),
                          pk_alert_constant.g_active /*caso nenhuma das anteriores entao sempre ativo*/) flg_status
              FROM opinion o
              JOIN speciality s
                ON s.id_speciality(+) = o.id_speciality
              JOIN TABLE(pk_action.tf_get_actions(i_lang, i_prof, l_subject, NULL)) act
                ON act.id_action IS NOT NULL
             WHERE o.id_opinion_type IS NULL
               AND o.id_episode = i_episode
               AND o.flg_state IN (g_opinion_req, g_opinion_req_read)
               AND o.id_prof_questions <> i_prof.id;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_REQUESTED_OPINION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_consults);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
        
    END get_requested_opinion;

    /********************************************************************************************
    * Updates the status of several constultation requests
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_opinion        List of consultation request
    * @param i_action         List of associated actions
    *
    * @param o_error          Error message     
    *
    * @return                 true or false on success or error
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.3.8.2
    * @since                  2015/01/27
    **********************************************************************************************/

    FUNCTION set_opinion_answer
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion      IN table_number,
        i_action       IN table_varchar,
        o_sys_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_status opinion.flg_state%TYPE;
        l_type   opinion.flg_type%TYPE;
        l_rows   table_varchar;
        l_exception EXCEPTION;
        l_rows_out  table_varchar;
        l_flg_state opinion_prof.flg_type%TYPE;
    
        --
        l_flg_action      opinion.flg_state%TYPE;
        l_id_sys_shortcut sys_shortcut.id_sys_shortcut%TYPE := 170657;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_opinion.count
        LOOP
        
            SELECT flg_state, flg_type
              INTO l_status, l_type
              FROM opinion op
             WHERE op.id_opinion = i_opinion(i);
        
            IF l_status = g_opinion_req
               AND (i_action(i) = g_opinion_reply OR i_action(i) = g_opinion_replied)
            THEN
            
                g_error := 'UPDATE OPINION READ';
                ts_opinion.upd(flg_state_in => g_opinion_req_read, id_opinion_in => i_opinion(i), rows_out => l_rows);
            
                l_flg_state := g_opin_prof_read;
                -- create opinion answer
                g_error := 'CALL ts_opinion_prof.ins';
                ts_opinion_prof.ins(id_opinion_in           => i_opinion(i),
                                    flg_type_in             => l_flg_state,
                                    id_professional_in      => i_prof.id,
                                    desc_reply_in           => NULL,
                                    dt_opinion_prof_tstz_in => g_sysdate_tstz,
                                    flg_face_to_face_in     => g_unknown,
                                    rows_out                => l_rows_out);
            END IF;
            g_error := 'UPDATE OPINION';
        
            IF i_action(i) = g_opinion_replied
            THEN
                l_flg_action   := g_opinion_reply;
                o_sys_shortcut := l_id_sys_shortcut;
            ELSE
                l_flg_action   := i_action(i);
                o_sys_shortcut := NULL;
            END IF;
        
            ts_opinion.upd(flg_state_in => l_flg_action, id_opinion_in => i_opinion(i), rows_out => l_rows);
        
            IF i_action(i) = g_opinion_req_read
            THEN
                l_flg_state := g_opin_prof_read;
            ELSIF i_action(i) = g_opinion_replied
            THEN
                l_flg_state := g_opinion_reply;
            ELSE
                l_flg_state := i_action(i);
            END IF;
        
            g_error := 'CALL ts_opinion_prof.ins';
            ts_opinion_prof.ins(id_opinion_in           => i_opinion(i),
                                flg_type_in             => l_flg_state,
                                id_professional_in      => i_prof.id,
                                desc_reply_in           => NULL,
                                dt_opinion_prof_tstz_in => g_sysdate_tstz,
                                flg_face_to_face_in     => g_unknown,
                                rows_out                => l_rows_out);
        
            IF l_flg_state = g_opinion_reply
            THEN
                g_error := 'SET ALERT OPINION';
                IF NOT alert_opinion_reply(i_lang            => i_lang,
                                           i_opinion         => i_opinion(i),
                                           i_flg_type        => l_flg_state,
                                           i_flg_type_opinon => l_type,
                                           o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
        END LOOP;
    
        g_error := 't_data_gov_mnt.process_update ts_opinion';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'OPINION',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATE'));
    
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'OPINION_PROF',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_OPINION_ANSWER',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_opinion_answer;

    FUNCTION set_opinion_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        FOR i IN 1 .. i_task_request.count
        LOOP
            g_error := 'DELETE OPINION_HIST';
            ts_opinion_hist.del_by(where_clause_in => 'id_opinion = ' || i_task_request(i));
        
            g_error := 'DELETE OPINION_PROF';
            ts_opinion_prof.del_by(where_clause_in => 'id_opinion = ' || i_task_request(i));
        
            g_error := 'DELETE OPINION_REASON';
            ts_opinion_reason.del_by(where_clause_in => 'id_opinion = ' || i_task_request(i));
        
            g_error := 'DELETE OPINION_DS';
            ts_opinion_ds.del_by(where_clause_in => 'id_opinion = ' || i_task_request(i));
        
            g_error := 'DELETE OPINION';
            ts_opinion.del_by(where_clause_in => 'id_opinion = ' || i_task_request(i));
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
                                              'SET_OPINION_DELETE_TASK',
                                              o_error);
            RETURN FALSE;
    END set_opinion_delete_task;

    /********************************************************************************************
    * Gets a string with all consults request and the current status
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @return                 String with all consults
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.3.8.2
    * @since                  2015/01/28
    **********************************************************************************************/
    FUNCTION get_consultations_tooltip
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_domain_requested    sys_domain.desc_val%TYPE := pk_sysdomain.get_domain(pk_opinion.g_opinion_consults,
                                                                                  pk_opinion.g_opinion_req,
                                                                                  i_lang);
        l_domain_request_read sys_domain.desc_val%TYPE := pk_sysdomain.get_domain(pk_opinion.g_opinion_consults,
                                                                                  pk_opinion.g_opinion_req_read,
                                                                                  i_lang);
        --
        l_domain_prof_read       sys_domain.desc_val%TYPE := pk_sysdomain.get_domain(pk_opinion.g_opinion_prof_state_domain,
                                                                                     pk_opinion.g_opin_prof_read,
                                                                                     i_lang);
        l_domain_prof_reply      sys_domain.desc_val%TYPE := pk_sysdomain.get_domain(pk_opinion.g_opinion_prof_state_domain,
                                                                                     pk_opinion.g_opin_prof_reply,
                                                                                     i_lang);
        l_domain_prof_reply_read sys_domain.desc_val%TYPE := pk_sysdomain.get_domain(g_opinion_consults,
                                                                                     pk_opinion.g_opinion_reply_read,
                                                                                     i_lang);
        --
        l_any_doctor    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'OPINION_T019');
        l_cons_label    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'OPINION_T020');
        l_tooltip       VARCHAR2(2000 CHAR);
        l_consultations table_varchar;
    
    BEGIN
    
        SELECT nvl2(op1.id_clinical_service,
                     pk_translation.get_translation(i_lang, cs.code_clinical_service),
                     pk_translation.get_translation(i_lang, sp.code_speciality)) ||
               -- PRIORITY
                CASE
                    WHEN op1.flg_priority IS NOT NULL THEN
                     ' (' || pk_sysdomain.get_domain(g_opinion_priority, op1.flg_priority, i_lang) || ')'
                    ELSE
                     NULL
                END || ' - ' ||
                decode(op1.id_prof_questioned,
                       NULL,
                       l_any_doctor,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, op1.id_prof_questioned)) || --
                ' (' || --
               --Requested               
                l_domain_requested || ': ' || pk_prof_utils.get_name_signature(i_lang, i_prof, op1.id_prof_questions) || --
               --Questioned Prof Read
                pk_opinion.get_opinion_prof(i_lang,
                                            i_prof,
                                            op1.id_opinion,
                                            pk_opinion.g_opin_prof_read,
                                            l_domain_prof_read) || --
               --Questioned Prof Answered
                pk_opinion.get_opinion_prof(i_lang,
                                            i_prof,
                                            op1.id_opinion,
                                            pk_opinion.g_opin_prof_reply,
                                            l_domain_prof_reply) || --
               --Answer read
                decode(op1.flg_state,
                       pk_opinion.g_opinion_reply_read,
                       '; ' || l_domain_prof_reply_read || ': ' ||
                       pk_prof_utils.get_name_signature(i_lang, i_prof, op1.id_prof_questions),
                       NULL) || ')'
          BULK COLLECT
          INTO l_consultations
          FROM opinion op1
          LEFT JOIN speciality sp
            ON sp.id_speciality = op1.id_speciality
          LEFT JOIN clinical_service cs
            ON cs.id_clinical_service = op1.id_clinical_service
         WHERE op1.id_episode = i_episode
           AND op1.id_opinion_type IS NULL
           AND op1.flg_state <> pk_opinion.g_opinion_cancel
         ORDER BY op1.id_opinion;
    
        IF l_consultations.count > 0
        THEN
            l_tooltip := '<b>' || l_cons_label || '</b>' || chr(10) || chr(13) ||
                         pk_utils.concat_table_l(i_tab => l_consultations, i_delim => chr(10) || chr(13));
        END IF;
        RETURN l_tooltip;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_consultations_tooltip;

    FUNCTION get_opinion_status_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_state       IN opinion.flg_state%TYPE,
        i_dt_problem_tstz IN opinion.dt_problem_tstz%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(30) := 'GET_OPINION_STATUS_STRING';
    
        l_error         t_error_out;
        l_status_string VARCHAR2(200);
        l_status_str    VARCHAR2(200);
        l_status_msg    VARCHAR2(200);
        l_status_icon   VARCHAR2(200);
        l_status_flg    VARCHAR2(200);
    
    BEGIN
    
        g_error := 'IF TO STRING';
        -- STATUS REQ THEN TIME
        IF i_flg_state IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_req_read) -- R e F
        THEN
            g_error := '[2]REQ = DATE';
            /*            l_status_string := pk_utils.get_status_string_immediate(i_lang            => i_lang,
            i_prof            => i_prof,
            i_display_type    => pk_alert_constant.g_display_type_date, -- icon only
            i_flg_state       => 'A',
            i_value_text      => NULL,
            i_value_date      => pk_date_utils.to_char_insttimezone(i_prof,
                                                                    i_dt_problem_tstz,
                                                                    pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
            i_value_icon      => NULL,
            i_shortcut        => pk_opinion.g_opinion_consults_shortcut, -- SHORTCUT 
            i_back_color      => NULL,
            i_icon_color      => NULL,
            i_message_style   => NULL,
            i_message_color   => NULL,
            i_flg_text_domain => NULL,
            i_dt_server       => current_timestamp);*/
        
            pk_utils.build_status_string(i_display_type    => pk_alert_constant.g_display_type_date, -- icon only
                                         i_flg_state       => 'A',
                                         i_value_text      => NULL,
                                         i_value_date      => pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                 i_dt_problem_tstz,
                                                                                                 pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                         i_value_icon      => NULL,
                                         i_shortcut        => pk_opinion.g_opinion_consults_shortcut, -- SHORTCUT 
                                         i_back_color      => NULL,
                                         i_icon_color      => NULL,
                                         i_message_style   => NULL,
                                         i_message_color   => NULL,
                                         i_flg_text_domain => NULL,
                                         o_status_str      => l_status_str,
                                         o_status_msg      => l_status_msg,
                                         o_status_icon     => l_status_icon,
                                         o_status_flg      => l_status_flg);
            l_status_string := REPLACE(l_status_str,
                                       pk_alert_constant.g_status_rpl_chr_dt_server,
                                       pk_date_utils.to_char_insttimezone(i_prof,
                                                                          i_dt_problem_tstz,
                                                                          pk_alert_constant.g_dt_yyyymmddhh24miss_tzr)) || '|';
        
            -- STATUS REPLYED - THEN ICON
        ELSIF i_flg_state IN (pk_opinion.g_opinion_reply, pk_opinion.g_opinion_reply_read) -- 'P', 'A'
        THEN
            g_error         := '[2]REPLYED = ICON';
            l_status_string := pk_utils.get_status_string_immediate(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_display_type    => pk_alert_constant.g_display_type_icon, -- icon only
                                                                    i_flg_state       => i_flg_state,
                                                                    i_value_text      => NULL,
                                                                    i_value_date      => NULL,
                                                                    i_value_icon      => pk_opinion.g_opinion_consults,
                                                                    i_shortcut        => pk_opinion.g_opinion_consults_shortcut, -- SHORTCUT 
                                                                    i_back_color      => NULL,
                                                                    i_icon_color      => NULL,
                                                                    i_message_style   => NULL,
                                                                    i_message_color   => NULL,
                                                                    i_flg_text_domain => NULL,
                                                                    i_dt_server       => NULL);
        
        END IF;
    
        RETURN l_status_string;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN 'ERROR';
    END get_opinion_status_string;

    FUNCTION get_epis_last_opinion
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_data       OUT t_rec_epis_last_opinion,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(30) := 'GET_EPIS_LAST_OPINION';
    
        l_flg_state       opinion.flg_state%TYPE;
        l_dt_problem_tstz opinion.dt_problem_tstz%TYPE;
        l_opinion_popup   opinion.flg_state%TYPE;
        l_rank            sys_domain.rank%TYPE;
        l_status_string   VARCHAR2(100);
        l_id_opinion      opinion.id_opinion%TYPE;
        l_data            t_rec_epis_last_opinion := t_rec_epis_last_opinion();
    BEGIN
    
        g_error := 'SELECT TO OPINION';
        BEGIN
            SELECT f.id_opinion, f.flg_state, f.dt_problem_tstz, f.rank
              INTO l_id_opinion, l_flg_state, l_dt_problem_tstz, l_rank
              FROM (SELECT o.flg_state, o.id_opinion, sd.rank, o.dt_problem_tstz
                      FROM opinion o
                      JOIN sys_domain sd
                        ON sd.code_domain = pk_opinion.g_opinion_consults
                       AND sd.val = o.flg_state
                       AND sd.id_language = i_lang
                     WHERE o.id_episode = i_id_episode
                       AND o.id_opinion_type IS NULL -- to filter consults
                       AND o.flg_state NOT IN (pk_opinion.g_opinion_cancel)
                     ORDER BY sd.rank ASC, o.dt_problem_tstz ASC) f
             WHERE rownum = 1;
        
            g_error := 'IF TO STRING';
        
            g_error         := 'GET STATUS STRING';
            l_status_string := pk_opinion.get_opinion_status_string(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_flg_state       => l_flg_state,
                                                                    i_dt_problem_tstz => l_dt_problem_tstz);
            g_error         := 'T_REC_EPIS_LAST_OPINION';
            l_data          := t_rec_epis_last_opinion(id_opinion        => l_id_opinion,
                                                       dt_problem_tstz   => l_dt_problem_tstz,
                                                       status_string     => l_status_string,
                                                       sys_domain_called => pk_opinion.g_opinion_consults,
                                                       rank              => l_rank);
        
            o_data := l_data;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_last_opinion;

    FUNCTION get_epis_last_opinion_popup
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_func_name VARCHAR2(30) := 'GET_EPIS_LAST_OPINION_POPUP';
    
        l_error  t_error_out;
        l_data   t_rec_epis_last_opinion := t_rec_epis_last_opinion();
        l_return VARCHAR2(1 CHAR);
        l_count  NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
        
          FROM opinion o
         WHERE o.id_episode = i_id_episode
           AND o.id_opinion_type IS NULL -- to filter consults
           AND o.flg_state IN (pk_opinion.g_opinion_req, pk_opinion.g_opinion_req_read)
           AND o.id_prof_questions != i_prof.id;
    
        IF l_count > 0
        THEN
            l_return := pk_alert_constant.g_yes;
        ELSE
            l_return := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN 'ERROR';
    END get_epis_last_opinion_popup;

    FUNCTION get_opinion_viewer_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_OPINION_VIEWER_DETAIL';
        l_params VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_opinon =' || i_id_opinion;
        -- init
        g_error := 'Init ' || l_func_name || ' / ' || l_params;
    
        -- func
        g_error := 'OPEN o_detail FOR / ' || l_params;
        OPEN o_detail FOR
            SELECT f.*
              FROM (SELECT o.id_opinion id_opinion,
                           pk_sysdomain.get_domain(g_opinion_consults, o.flg_state, i_lang) status_desc,
                           pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => nvl(op.id_professional, o.id_prof_questions)) prof_name,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                              nvl(op.dt_opinion_prof_tstz, o.dt_problem_tstz),
                                                              i_prof) dt_status_str,
                           NULL flg_nature_description
                      FROM opinion o
                      LEFT JOIN opinion_prof op
                        ON o.id_opinion = op.id_opinion
                     WHERE o.id_opinion = i_id_opinion
                     ORDER BY op.dt_opinion_prof_tstz DESC) f
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_opinion_viewer_detail;

    FUNCTION get_ordered_list_opinion
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_records t_table_rec_gen_area_rank_tmp;
    
        l_viewer_area VARCHAR2(200);
        l_episode     table_number;
    
        CURSOR c_episode IS
            SELECT e.id_episode
              FROM episode e
             WHERE e.id_visit = pk_episode.get_id_visit(i_episode);
    
        l_any_doctor sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'OPINION_T019');
        l_task_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'OPINION_T020');
    BEGIN
    
        l_viewer_area := i_viewer_area;
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_episode;
        FETCH c_episode BULK COLLECT
            INTO l_episode;
    
        --insert in temporary table
        g_error := 'INSERT ON TEMP TABLE';
        SELECT t_rec_gen_area_rank_tmp(t.varch1,
                                       t.flg_status,
                                       t.flg_time,
                                       t.code,
                                       t.flg_type,
                                       t.status_str,
                                       t.status_msg,
                                       t.status_icon,
                                       t.status_flg,
                                       t.varch10,
                                       t.varch11,
                                       t.varch12,
                                       t.varch13,
                                       t.varch14,
                                       t.varch15,
                                       t.id_episode_origin,
                                       t.id,
                                       t.numb3,
                                       t.numb4,
                                       t.numb5,
                                       t.numb6,
                                       t.numb7,
                                       t.numb8,
                                       t.numb9,
                                       t.numb10,
                                       t.numb11,
                                       t.numb12,
                                       t.numb13,
                                       t.numb14,
                                       t.numb15,
                                       t.dt_begin,
                                       t.dt_req,
                                       t.currdate,
                                       t.dt_tstz4,
                                       t.dt_tstz5,
                                       t.dt_tstz6,
                                       t.dt_tstz7,
                                       t.dt_tstz8,
                                       t.dt_tstz9,
                                       t.dt_tstz10,
                                       t.dt_tstz11,
                                       t.dt_tstz12,
                                       t.dt_tstz13,
                                       t.dt_tstz14,
                                       t.dt_tstz15,
                                       t.rank)
          BULK COLLECT
          INTO l_records
          FROM (SELECT NULL varch1,
                       NULL flg_status,
                       NULL flg_time,
                       nvl2(o.id_clinical_service,
                            pk_translation.get_translation(i_lang, cs.code_clinical_service),
                            nvl2(o.id_speciality, pk_translation.get_translation(i_lang, s.code_speciality), NULL)) ||
                       ' - ' || decode(o.id_prof_questioned,
                                       NULL,
                                       l_any_doctor,
                                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned)) code,
                       'OPINION_CONSULTS' flg_type,
                       NULL status_str,
                       NULL status_msg,
                       NULL status_icon,
                       NULL status_flg,
                       o.flg_state,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p_req.id_professional) varch10,
                       (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_opinion.get_opinion_status_string(i_lang            => i_lang,
                                                                                                           i_prof            => i_prof,
                                                                                                           i_flg_state       => o.flg_state,
                                                                                                           i_dt_problem_tstz => o.dt_problem_tstz))
                          FROM dual) varch11,
                       NULL varch12,
                       NULL varch13,
                       NULL varch14,
                       NULL varch15,
                       o.id_episode id_episode_origin,
                       o.id_opinion id,
                       NULL numb3,
                       rank() over(PARTITION BY 1 ORDER BY pk_sysdomain.get_rank(i_lang, g_opinion_consults, o.flg_state), o.dt_problem_tstz) numb4,
                       NULL numb5,
                       NULL numb6,
                       NULL numb7,
                       NULL numb8,
                       NULL numb9,
                       NULL numb10,
                       NULL numb11,
                       NULL numb12,
                       NULL numb13,
                       NULL numb14,
                       NULL numb15,
                       o.dt_problem_tstz dt_begin,
                       o.dt_problem_tstz dt_req,
                       g_sysdate_tstz currdate,
                       o.dt_problem_tstz dt_tstz4,
                       NULL dt_tstz5,
                       NULL dt_tstz6,
                       NULL dt_tstz7,
                       NULL dt_tstz8,
                       NULL dt_tstz9,
                       NULL dt_tstz10,
                       NULL dt_tstz11,
                       NULL dt_tstz12,
                       NULL dt_tstz13,
                       NULL dt_tstz14,
                       NULL dt_tstz15,
                       decode(pk_sysdomain.get_rank(i_lang, g_opinion_consults, o.flg_state),
                              2,
                              2 * 1000,
                              4,
                              4 * 1000,
                              pk_sysdomain.get_rank(i_lang, g_opinion_consults, o.flg_state)) rank
                  FROM opinion o, professional p, speciality s, professional p_req, clinical_service cs
                 WHERE o.id_patient = nvl(i_patient, o.id_patient)
                   AND o.flg_state IN (g_opinion_req, g_opinion_reply, g_opinion_req_read)
                   AND o.id_opinion_type IS NULL
                   AND s.id_speciality(+) = o.id_speciality
                   AND p.id_professional(+) = o.id_prof_questioned
                   AND cs.id_clinical_service(+) = o.id_clinical_service
                   AND p_req.id_professional = o.id_prof_questions
                   AND (o.id_episode IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                          *
                                           FROM TABLE(l_episode) t) OR o.id_episode IS NULL)) t;
    
        g_error := 'OPEN CURSOR';
        OPEN o_ordered_list FOR
            SELECT /*+opt_estimate(table gart rows=1)*/
             gart.numb2 id,
             gart.varch4 code_description,
             gart.varch4 description,
             NULL title,
             gart.dt_tstz1 dt_req_tstz,
             pk_date_utils.dt_chr_date_hour_tsz(i_lang, gart.dt_tstz1, i_prof) dt_req,
             gart.varch2 flg_status,
             gart.varch5 flg_type,
             gart.varch11 desc_status,
             gart.rank rank,
             gart.numb4 rank_order,
             COUNT(0) over() num_count,
             l_task_title task_title
              FROM TABLE(l_records) gart;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              o_error);
            RETURN FALSE;
    END get_ordered_list_opinion;

    FUNCTION get_opinion_prof
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_flg_type     IN opinion_prof.flg_type%TYPE,
        i_domain_state IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_opinion_prof VARCHAR2(1000 CHAR);
    BEGIN
        SELECT '; ' || i_domain_state || ': ' || pk_prof_utils.get_name_signature(i_lang, i_prof, opf.id_professional)
          INTO l_opinion_prof
          FROM opinion_prof opf
         WHERE opf.flg_type = i_flg_type
           AND opf.id_opinion = i_opinion;
        RETURN l_opinion_prof;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END;

    FUNCTION get_epis_prof_req_opinions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_limit_max IN NUMBER,
        i_limit_min IN NUMBER,
        o_opinion   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_message debug_msg;
    BEGIN
    
        l_message := 'GET CURSOR';
    
        OPEN o_opinion FOR
            SELECT *
              FROM (SELECT rownum rn,
                           xmain.id_opinion,
                           xmain.name_patient,
                           xmain.id_prof_questions,
                           xmain.id_prof_questioned,
                           xmain.desc_problem,
                           xmain.id_episode,
                           xmain.id_patient,
                           xmain.name_prof_questions,
                           xmain.id_speciality,
                           xmain.speciality_desc,
                           xmain.date_opinion_create
                      FROM (SELECT o.id_opinion,
                                   p.name name_patient,
                                   o.id_prof_questions,
                                   o.id_prof_questioned,
                                   o.desc_problem,
                                   o.id_episode,
                                   o.id_patient,
                                   pr.name name_prof_questions,
                                   s.id_speciality,
                                   pk_translation.get_translation(i_lang, s.code_speciality) speciality_desc,
                                   pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                               i_date => o.dt_problem_tstz,
                                                               i_inst => i_prof.institution,
                                                               i_soft => i_prof.software) date_opinion_create
                              FROM opinion o
                              JOIN patient p
                                ON o.id_patient = p.id_patient
                              JOIN professional pr
                                ON o.id_prof_questions = i_prof.id
                              JOIN speciality s
                                ON o.id_speciality = s.id_speciality
                             WHERE o.id_prof_questioned = pr.id_professional
                               AND o.flg_state NOT IN (g_opinion_cancel, g_opinion_rejected)
                             ORDER BY o.dt_problem_tstz DESC) xmain) xfilter
             WHERE rn BETWEEN i_limit_min AND i_limit_max;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_OPINION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_opinion);
            RETURN FALSE;
    END get_epis_prof_req_opinions;

    /********************************************************************************************
    * Checks the existence of a consultation for a given professional 
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @return                 Y/N
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.3.6
    * @since                  2018/07/18
    **********************************************************************************************/

    FUNCTION check_opinion_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_nr_opinion PLS_INTEGER;
        l_config     VARCHAR2(1 CHAR) := pk_sysconfig.get_config('OPINION_PROF_LIST_GROUP_BY', i_prof);
        l_consultant VARCHAR2(1 CHAR);
    BEGIN
    
        l_consultant := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_intern_name => 'parecer');
        SELECT COUNT(1)
          INTO l_nr_opinion
          FROM opinion o
         WHERE o.id_episode = i_id_episode
           AND o.flg_state NOT IN (g_opinion_cancel, g_opinion_not_approved)
           AND (o.id_prof_questioned = i_prof.id OR
               (o.id_prof_questioned IS NULL AND
               ((l_config = 'S' AND
               o.id_speciality = (SELECT id_speciality
                                        FROM professional p
                                       WHERE p.id_professional = i_prof.id)) OR
               (l_config = 'C' AND
               o.id_clinical_service IN (SELECT 1
                                               FROM professional p
                                              INNER JOIN prof_dep_clin_serv pdcs
                                                 ON pdcs.id_professional = p.id_professional
                                                AND pdcs.id_institution = i_prof.institution
                                              INNER JOIN dep_clin_serv dcs
                                                 ON dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                              INNER JOIN clinical_service cs
                                                 ON cs.id_clinical_service = dcs.id_clinical_service
                                              WHERE p.id_professional = i_prof.id)))));
    
        IF (l_nr_opinion > 0)
           AND l_consultant = pk_alert_constant.g_yes
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    END check_opinion_prof;

    /********************************************************************************************
    * Checks the existence of a follow up request for a given professional 
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @return                 Y/N
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.4.7
    * @since                  2019/01/12
    **********************************************************************************************/

    FUNCTION check_follow_up_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_nr_follow    PLS_INTEGER;
        l_consultant   VARCHAR2(1 CHAR);
        l_type_opinion opinion_type.id_opinion_type%TYPE;
        l_category     category.id_category%TYPE;
        l_prof_cat     category.flg_type%TYPE;
        l_handoff_type sys_config.value%TYPE;
    
        CURSOR c_type_request IS
            SELECT ot.id_opinion_type
              FROM opinion_type ot
             WHERE ot.id_category = l_category;
    
    BEGIN
    
        g_error    := 'GET PROF CATEGORY';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'OPEN C_TYPE_REQUEST';
        OPEN c_type_request;
        FETCH c_type_request
            INTO l_type_opinion;
        CLOSE c_type_request;
    
        SELECT COUNT(1)
          INTO l_nr_follow
          FROM opinion o
         WHERE o.id_episode = i_id_episode
           AND o.flg_state IN (g_opinion_req, g_opinion_accepted, g_opinion_approved)
           AND o.id_opinion_type = l_type_opinion
           AND o.id_prof_questioned = i_prof.id;
    
        IF (l_nr_follow > 0)
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    END check_follow_up_prof;

    /********************************************************************************************
    * Checks if the patient is on list of professional (My patient list) AND return the message
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_id_schedule    schedule identifier
    * @param o_flg_in_my_list flag to identify is patient is ON my list ( R (in my patient list)  or A (not IN my patient list))
    * @param o_message        message to show ON pop up
    * @return                 boolean
    *
    * @author                 Nuno Coelho
    * @version                2.7.4.7
    * @since                  2019/03/28
    **********************************************************************************************/

    FUNCTION get_follow_episode_by_me
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        o_flg_in_my_list OUT VARCHAR2,
        o_message        OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_cat       category.flg_type%TYPE;
        l_hand_off_type  sys_config.value%TYPE;
        l_flg_in_my_list VARCHAR2(1);
    BEGIN
        g_error    := 'GET PROF_CAT';
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        g_error := 'Get o_flg_in_my_list value';
    
        g_error := 'GET L_FLG_IN_MY_LIST';
        SELECT decode(pk_prof_follow.get_follow_episode_by_me(i_prof, i_id_episode, i_id_schedule),
                      pk_alert_constant.g_no,
                      decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                              i_prof,
                                                                                              i_id_episode,
                                                                                              l_prof_cat,
                                                                                              l_hand_off_type,
                                                                                              pk_alert_constant.g_yes),
                                                          i_prof.id),
                             -1,
                             pk_alert_constant.g_yes,
                             pk_alert_constant.g_no),
                      pk_alert_constant.g_yes)
          INTO l_flg_in_my_list
          FROM dual;
    
        g_error := 'GET O_FLG_IN_MY_LIST';
        IF l_flg_in_my_list = pk_alert_constant.g_yes
        THEN
            o_flg_in_my_list := CASE pk_prof_follow.get_follow_episode_by_me(i_prof, i_id_episode, i_id_schedule)
                                    WHEN 'Y' THEN
                                     g_follow_by_me_rem
                                    ELSE
                                     g_follow_by_me_add
                                END;
        
            g_error := 'get o_message value';
            IF o_flg_in_my_list = g_follow_by_me_add
            THEN
                o_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'OPINION_T024');
            ELSE
                o_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'OPINION_T025');
            END IF;
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
                                              'GET_FOLLOW_EPISODE_BY_ME',
                                              o_error);
            RETURN FALSE;
        
    END get_follow_episode_by_me;

    FUNCTION create_opin_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN epis_info.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_desc             IN opinion.desc_problem%TYPE,
        i_flg_face_to_face IN opinion_prof.flg_face_to_face%TYPE DEFAULT g_unknown,
        i_flag_active      IN VARCHAR2, --(Resposta ('A','R'))
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flag_active  VARCHAR2(1);
        l_opinion_prof opinion_prof.id_opinion_prof%TYPE;
    BEGIN
        g_error := 'create_opin_prof_int';
        IF NOT create_opin_prof_int(i_lang             => i_lang,
                                    i_opinion          => i_opinion,
                                    i_prof             => i_prof,
                                    i_desc             => i_desc,
                                    i_flg_face_to_face => i_flg_face_to_face,
                                    i_commit_data      => pk_alert_constant.g_yes,
                                    o_opinion_prof     => l_opinion_prof,
                                    o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'set_follow_episode_by_me';
        /*
        the ux only return value case the anwser = 'Y'
        */
        IF i_flag_active IS NOT NULL
        THEN
        
            IF i_flag_active = g_follow_by_me_rem
            THEN
                l_flag_active := pk_alert_constant.g_no;
            ELSE
                l_flag_active := pk_alert_constant.g_yes;
            END IF;
        
            IF NOT pk_prof_follow_ux.set_follow_episode_by_me(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_episode  => i_id_episode,
                                                              i_id_schedule => i_id_schedule,
                                                              i_flag_active => l_flag_active,
                                                              o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
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
                                              'CREATE_OPIN_PROF',
                                              o_error);
            RETURN FALSE;
        
    END create_opin_prof;

    FUNCTION create_opin_prof
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_opinion              IN opinion.id_opinion%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_flag_active          IN VARCHAR2, --(Resposta ('A','R'))
        o_opinion_prof         OUT opinion_prof.id_opinion_prof%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_desc             opinion.desc_problem%TYPE;
        l_flg_face_to_face opinion_prof.flg_face_to_face%TYPE;
        l_flag_active      VARCHAR2(1);
    
        l_id_prof_co_sign professional.id_professional%TYPE;
        l_order_type      opinion_prof.id_order_type%TYPE;
        l_dt_co_sign      VARCHAR2(100 CHAR);
    
    BEGIN
        g_error := 'GETTING DYNAMIC FORM VALUES';
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = 'DS_REPLY_NOTES'
            THEN
                l_desc := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_CONSULT_REPLY_OPTIONS'
            THEN
                l_flg_face_to_face := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORDER_TYPE'
            THEN
                l_order_type := to_number(i_tbl_real_val(i) (1));
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORDERED_BY'
            THEN
                l_id_prof_co_sign := to_number(i_tbl_real_val(i) (1));
            ELSIF i_tbl_ds_internal_name(i) = 'DS_ORDERED_AT'
            THEN
                l_dt_co_sign := i_tbl_real_val(i) (1);
            END IF;
        END LOOP;
    
        IF l_id_prof_co_sign IS NULL
        THEN
            g_error := 'create_opin_prof_int';
            IF NOT create_opin_prof_int(i_lang             => i_lang,
                                        i_opinion          => i_opinion,
                                        i_prof             => i_prof,
                                        i_desc             => l_desc,
                                        i_flg_face_to_face => l_flg_face_to_face,
                                        i_commit_data      => pk_alert_constant.g_yes,
                                        o_opinion_prof     => o_opinion_prof,
                                        o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'set_follow_episode_by_me';
            /*
            the ux only return value case the anwser = 'Y'
            */
            IF i_flag_active IS NOT NULL
            THEN
            
                IF i_flag_active = g_follow_by_me_rem
                THEN
                    l_flag_active := pk_alert_constant.g_no;
                ELSE
                    l_flag_active := pk_alert_constant.g_yes;
                END IF;
            
                IF NOT pk_prof_follow_ux.set_follow_episode_by_me(i_lang        => i_lang,
                                                                  i_prof        => i_prof,
                                                                  i_id_episode  => i_episode,
                                                                  i_id_schedule => i_id_schedule,
                                                                  i_flag_active => l_flag_active,
                                                                  o_error       => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        ELSE
            IF NOT pk_opinion.create_opinion_co_sign(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_episode         => i_episode,
                                                     i_id_opinion         => i_opinion,
                                                     i_desc               => l_desc,
                                                     i_flg_face_to_face   => l_flg_face_to_face,
                                                     i_id_prof_questioned => l_id_prof_co_sign,
                                                     i_id_order_type      => l_order_type,
                                                     i_dt_opinion         => l_dt_co_sign,
                                                     o_error              => o_error)
            THEN
                RAISE g_exception;
            END IF;
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
                                              'CREATE_OPIN_PROF',
                                              o_error);
            RETURN FALSE;
    END create_opin_prof;

    FUNCTION inactivate_opinion
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_CANCEL_REASON',
                                                                      i_prof    => i_prof);
    
        l_descontinued_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_DISCONTINUED_REASON',
                                                                            i_prof    => i_prof);
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_descontinued_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                                    i_prof,
                                                                                                    l_descontinued_cfg);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                    i_prof => profissional(0, i_inst, 0),
                                                                                    i_area => 'OPINION_INACTIVATE');
    
        l_tbl_config_no_discharge t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                                 i_prof => profissional(0,
                                                                                                                        i_inst,
                                                                                                                        0),
                                                                                                 i_area => 'OPINION_INACTIVATE_NO_DISCHARGE');
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_send_cancel_event sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                 i_code_cf => 'SEND_CANCEL_EVENT'),
                                                         pk_alert_constant.g_yes);
    
        l_tbl_opinion      table_number;
        l_tbl_opinion_type table_number;
        l_final_status     table_varchar;
        l_opinion_hist     opinion_hist.id_opinion_hist%TYPE;
    
        l_tbl_error_ids table_number := table_number();
    
        l_error t_error_out;
        g_other_exception EXCEPTION;
    
        --The cursor will not fetch the records for the ids (id_opinion) sent in i_ids_exclude
        CURSOR c_opinion(ids_exclude IN table_number) IS
            SELECT o.id_opinion, o.id_opinion_type, cfg.field_04 final_status
              FROM opinion o
              LEFT JOIN episode e
                ON e.id_episode = o.id_episode
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.*
                           FROM TABLE(l_tbl_config) t) cfg
                ON cfg.field_01 = o.flg_state
             INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.*
                           FROM TABLE(l_tbl_config_no_discharge) t) cfg_no_disch
                ON cfg_no_disch.field_01 = o.flg_state
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.column_value
                           FROM TABLE(i_ids_exclude) t) t_ids
                ON t_ids.column_value = o.id_opinion
             WHERE o.id_opinion_type IS NOT NULL --To only cancel the Follow-ups and not the consults.
               AND e.id_institution = i_inst
               AND (e.dt_end_tstz IS NOT NULL AND
                   pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                     i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => e.dt_end_tstz,
                                                                                                i_amount    => cfg.field_02,
                                                                                                i_unit      => cfg.field_03))) <=
                   pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp) OR
                   (e.dt_end_tstz IS NULL AND
                   pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                      i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => o.dt_problem_tstz,
                                                                                                 i_amount    => cfg_no_disch.field_02,
                                                                                                 i_unit      => cfg_no_disch.field_03))) <=
                   pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)))
               AND rownum <= l_max_rows
               AND t_ids.column_value IS NULL;
    
    BEGIN
    
        OPEN c_opinion(i_ids_exclude);
        FETCH c_opinion BULK COLLECT
            INTO l_tbl_opinion, l_tbl_opinion_type, l_final_status;
        CLOSE c_opinion;
    
        o_has_error := FALSE;
    
        IF l_tbl_opinion.count > 0
        THEN
            FOR i IN 1 .. l_tbl_opinion.count
            LOOP
                IF l_final_status(i) = g_opinion_cancel
                THEN
                    SAVEPOINT init_cancel;
                    IF NOT set_opinion_canc_no_val(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_opinion          => l_tbl_opinion(i),
                                                   i_opinion_type     => l_tbl_opinion_type(i),
                                                   i_notes_cancel     => NULL,
                                                   i_cancel_reason    => l_cancel_id,
                                                   i_flg_cancel_event => l_send_cancel_event,
                                                   o_error            => l_error)
                    
                    THEN
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_opinion, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_opinion that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR CALLING PK_OPINION.SET_OPINION_CANC_NO_VAL FOR RECORD ' || l_tbl_opinion(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'INACTIVATE_OPINION',
                                                          o_error);
                    
                        --The array for the ids (id_exam_req_det) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_tbl_opinion(i);
                    
                        CONTINUE;
                    END IF;
                ELSIF l_final_status(i) = g_opinion_over
                THEN
                    SAVEPOINT init_cancel;
                    IF NOT set_consult_request_state(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_opinion      => l_tbl_opinion(i),
                                                     i_state        => l_final_status(i),
                                                     i_set_oprof    => pk_alert_constant.g_no,
                                                     o_opinion_hist => l_opinion_hist,
                                                     o_error        => l_error)
                    
                    THEN
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_opinion, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_opinion that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR CALLING PK_OPINION.SET_CONSULT_REQUEST_STATE FOR RECORD ' || l_tbl_opinion(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'INACTIVATE_OPINION',
                                                          o_error);
                    
                        --The array for the ids (id_exam_req_det) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_tbl_opinion(i);
                    
                        CONTINUE;
                    END IF;
                END IF;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_opinion has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_exam_req_det) that could not
                    --be inactivated with the current call of the function
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_ids(i);
                END LOOP;
            
                --Since no inactivations were performed with the current call, a new call to this function is performed,
                --however, this time, the array i_ids_exclude will include a list of ids that cannot be fetched by the cursor
                --on the next call. The recursion will be perfomed until at least one record is inactivated, or the cursor
                --has no more records to fetch.
                --Note: i_ids_exclude is incremented and is an IN OUT parameter, therefore, 
                --it will hold all the ids that were not inactivated from ALL calls.            
                IF NOT pk_opinion.inactivate_opinion(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_inst        => i_inst,
                                                     i_ids_exclude => i_ids_exclude,
                                                     o_has_error   => o_has_error,
                                                     o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error.err_desc,
                                              'ALERT',
                                              'PK_OPINION',
                                              'INACTIVATE_OPINION',
                                              l_error);
            RETURN FALSE;
    END inactivate_opinion;

    FUNCTION get_prof_last_update
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE
    ) RETURN NUMBER IS
        l_ret opinion_hist.id_prof_created_hist%TYPE;
    BEGIN
        SELECT id_prof_created_hist
          INTO l_ret
          FROM (SELECT oh.id_prof_created_hist
                  FROM opinion_hist oh
                 WHERE oh.id_opinion = i_id_opinion
                 ORDER BY oh.dt_created_hist DESC) t
         WHERE rownum = 1;
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_opinion_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_OPINION_DET';
    
        l_tab_dd_block_data      t_tab_dd_block_data;
        l_tab_dd_block_prod_desc t_tab_dd_block_data;
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
        l_exists_prod      VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_id_episode_oop      epis_out_on_pass.id_episode%TYPE;
        l_prod_desc_and_instr table_varchar := table_varchar();
    
        k_active    NUMBER := pk_alert_constant.g_status_out_on_pass_active;
        k_ongoing   NUMBER := pk_alert_constant.g_status_out_on_pass_ongoing;
        k_completed NUMBER := pk_alert_constant.g_status_out_on_pass_completed;
        k_cancelled NUMBER := pk_alert_constant.g_status_out_on_pass_cancelled;
    
        l_label_updated sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T061') || ':';
    
        l_label_registered sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'CONSULT_REQUEST_T037') || ':';
    
        l_label_reject sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T052');
    
        l_label_accepted sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T046');
    BEGIN
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                    CASE
                                        WHEN dd.data_source IN ('FU_NOTES', 'FU_NOTES_REGISTERED', 'FU_NOTES_WHITE_LINE') THEN
                                         to_number(1000 || rownum)
                                        ELSE
                                         ddb.rank
                                    END,
                                    NULL,
                                    NULL,
                                    ddb.condition_val,
                                    NULL,
                                    NULL,
                                    dd.data_source,
                                    dd.data_source_val,
                                    NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data
          FROM (SELECT data_source, data_source_val
                  FROM (SELECT (SELECT pk_translation.get_translation(i_lang, ot.code_opinion_type)
                                  FROM dual) opinion_type,
                               (SELECT pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T023')
                                  FROM dual) request_title,
                               pk_translation.get_translation(i_lang, cs.code_clinical_service) speciality,
                               /*CASE
                                   WHEN o.id_opinion_type = g_ot_case_manager THEN
                                    pk_opinion.get_cm_req_reason(i_lang, i_prof, o.id_opinion)
                                   ELSE
                                    o.desc_problem
                               END*/
                               pk_opinion.get_cm_req_reason(i_lang, i_prof, o.id_opinion) request_reason,
                               o.desc_problem request_reason_ft,
                               nvl2(o.id_prof_questioned,
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                                    pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021')) name_prof_questioned,
                               to_char(o.notes) notes,
                               coalesce(pk_sysdomain.get_domain(g_opinion_consults, o.flg_state, i_lang), g_dashes) state,
                               o.notes_cancel,
                               pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                               decode(o.flg_state,
                                      g_status_cancel,
                                      l_label_updated,
                                      g_status_accepted,
                                      l_label_updated,
                                      g_status_declined,
                                      l_label_updated,
                                      g_status_approved,
                                      l_label_updated,
                                      g_status_completed,
                                      l_label_updated,
                                      l_label_registered) || ' ' ||
                               nvl2(o.dt_last_update,
                                    pk_prof_utils.get_name_signature(i_lang,
                                                                     i_prof,
                                                                     decode(o.flg_state,
                                                                            g_status_cancel,
                                                                            o.id_prof_cancel,
                                                                            g_status_accepted,
                                                                            get_prof_last_update(i_lang       => i_lang,
                                                                                                 i_prof       => i_prof,
                                                                                                 i_id_opinion => o.id_opinion),
                                                                            g_status_declined,
                                                                            get_prof_last_update(i_lang       => i_lang,
                                                                                                 i_prof       => i_prof,
                                                                                                 i_id_opinion => o.id_opinion),
                                                                            g_status_approved,
                                                                            get_prof_last_update(i_lang       => i_lang,
                                                                                                 i_prof       => i_prof,
                                                                                                 i_id_opinion => o.id_opinion),
                                                                            g_status_completed,
                                                                            get_prof_last_update(i_lang       => i_lang,
                                                                                                 i_prof       => i_prof,
                                                                                                 i_id_opinion => o.id_opinion),
                                                                            o.id_prof_questions)) ||
                                    decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                            i_prof,
                                                                            decode(o.flg_state,
                                                                                   g_status_cancel,
                                                                                   o.id_prof_cancel,
                                                                                   g_status_accepted,
                                                                                   get_prof_last_update(i_lang       => i_lang,
                                                                                                        i_prof       => i_prof,
                                                                                                        i_id_opinion => o.id_opinion),
                                                                                   g_status_declined,
                                                                                   get_prof_last_update(i_lang       => i_lang,
                                                                                                        i_prof       => i_prof,
                                                                                                        i_id_opinion => o.id_opinion),
                                                                                   g_status_approved,
                                                                                   get_prof_last_update(i_lang       => i_lang,
                                                                                                        i_prof       => i_prof,
                                                                                                        i_id_opinion => o.id_opinion),
                                                                                   g_status_completed,
                                                                                   get_prof_last_update(i_lang       => i_lang,
                                                                                                        i_prof       => i_prof,
                                                                                                        i_id_opinion => o.id_opinion),
                                                                                   o.id_prof_questions),
                                                                            o.dt_last_update,
                                                                            o.id_episode),
                                           NULL,
                                           '; ',
                                           ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                    i_prof,
                                                                                    decode(o.flg_state,
                                                                                           g_status_cancel,
                                                                                           o.id_prof_cancel,
                                                                                           g_status_accepted,
                                                                                           get_prof_last_update(i_lang       => i_lang,
                                                                                                                i_prof       => i_prof,
                                                                                                                i_id_opinion => o.id_opinion),
                                                                                           g_status_declined,
                                                                                           get_prof_last_update(i_lang       => i_lang,
                                                                                                                i_prof       => i_prof,
                                                                                                                i_id_opinion => o.id_opinion),
                                                                                           g_status_approved,
                                                                                           get_prof_last_update(i_lang       => i_lang,
                                                                                                                i_prof       => i_prof,
                                                                                                                i_id_opinion => o.id_opinion),
                                                                                           g_status_completed,
                                                                                           get_prof_last_update(i_lang       => i_lang,
                                                                                                                i_prof       => i_prof,
                                                                                                                i_id_opinion => o.id_opinion),
                                                                                           o.id_prof_questions),
                                                                                    o.dt_last_update,
                                                                                    o.id_episode) || '); ') ||
                                    pk_date_utils.date_char_tsz(i_lang,
                                                                o.dt_last_update,
                                                                i_prof.institution,
                                                                i_prof.software),
                                    NULL) request_registered,
                               nvl2(op_reject.dt_opinion_prof_tstz, l_label_reject, NULL) declined_title,
                               CASE
                                    WHEN op_reject.dt_opinion_prof_tstz IS NOT NULL
                                         AND op_reject.flg_type = g_opinion_prof_reject THEN
                                     pk_date_utils.date_char_tsz(i_lang,
                                                                 op_reject.dt_opinion_prof_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software)
                                    ELSE
                                     NULL
                                END declined_date,
                               CASE
                                    WHEN op_reject.id_professional IS NOT NULL
                                         AND op_reject.flg_type = g_opinion_prof_reject THEN
                                     pk_prof_utils.get_name_signature(i_lang, i_prof, op_reject.id_professional)
                                    ELSE
                                     NULL
                                END declined_by,
                               CASE
                                    WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                                     op_reject.desc_reply
                                    ELSE
                                     NULL
                                END declined_notes,
                               CASE
                                    WHEN cr_reject.code_cancel_reason IS NOT NULL
                                         AND op_reject.flg_type = g_opinion_prof_reject THEN
                                     pk_translation.get_translation(i_lang, cr_reject.code_cancel_reason)
                                    ELSE
                                     NULL
                                END declined_motive,
                               CASE
                                    WHEN op_reject.flg_type = g_opinion_prof_reject THEN
                                     nvl2(op_reject.dt_opinion_prof_tstz,
                                          l_label_registered || ' ' ||
                                           pk_prof_utils.get_name_signature(i_lang, i_prof, op_reject.id_professional) ||
                                          --
                                           decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                   i_prof,
                                                                                   op_reject.id_professional,
                                                                                   op_reject.dt_opinion_prof_tstz,
                                                                                   o.id_episode),
                                                  NULL,
                                                  '; ',
                                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                           i_prof,
                                                                                           op_reject.id_professional,
                                                                                           op_reject.dt_opinion_prof_tstz,
                                                                                           o.id_episode) || '); ') ||
                                           pk_date_utils.date_char_tsz(i_lang,
                                                                       op_reject.dt_opinion_prof_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software),
                                          NULL)
                                    ELSE
                                     NULL
                                END declined_registered,
                               nvl2(op_accept.dt_opinion_prof_tstz, l_label_accepted, NULL) accepted_title,
                               CASE
                                    WHEN op_accept.dt_opinion_prof_tstz IS NOT NULL
                                         AND op_accept.flg_type = g_opinion_prof_accept THEN
                                     pk_date_utils.date_char_tsz(i_lang,
                                                                 op_accept.dt_opinion_prof_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software)
                                    ELSE
                                     NULL
                                END accepted_date,
                               CASE
                                    WHEN op_accept.id_professional IS NOT NULL
                                         AND op_accept.flg_type = g_opinion_prof_accept THEN
                                     pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional)
                                    ELSE
                                     NULL
                                END accepted_by,
                               CASE
                                    WHEN op_accept.dt_opinion_prof_tstz IS NOT NULL
                                         AND op_accept.flg_type = g_opinion_prof_accept THEN
                                     op_accept.desc_reply
                                    ELSE
                                     NULL
                                END accepted_notes,
                               CASE
                                    WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                                     nvl2(op_accept.dt_opinion_prof_tstz,
                                          l_label_registered || ' ' ||
                                          pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional) ||
                                          decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                  i_prof,
                                                                                  op_accept.id_professional,
                                                                                  op_accept.dt_opinion_prof_tstz,
                                                                                  o.id_episode),
                                                 NULL,
                                                 '; ',
                                                 ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                          i_prof,
                                                                                          op_accept.id_professional,
                                                                                          op_accept.dt_opinion_prof_tstz,
                                                                                          o.id_episode) || '); ')
                                          
                                          || pk_date_utils.date_char_tsz(i_lang,
                                                                         op_accept.dt_opinion_prof_tstz,
                                                                         i_prof.institution,
                                                                         i_prof.software),
                                          NULL)
                                    ELSE
                                     NULL
                                END accepted_registered
                          FROM opinion o
                          LEFT OUTER JOIN cancel_reason cr
                            ON cr.id_cancel_reason = o.id_cancel_reason
                          LEFT OUTER JOIN clinical_service cs
                            ON cs.id_clinical_service = o.id_clinical_service
                          LEFT OUTER JOIN opinion_prof op_accept
                            ON (op_accept.id_opinion = o.id_opinion AND op_accept.flg_type = g_opinion_prof_accept)
                          LEFT OUTER JOIN opinion_prof op_reject
                            ON (op_reject.id_opinion = o.id_opinion AND op_reject.flg_type = g_opinion_prof_reject)
                          LEFT OUTER JOIN opinion_prof op_approve
                            ON (op_approve.id_opinion = o.id_opinion AND op_approve.flg_type = g_opinion_prof_approve)
                          LEFT OUTER JOIN opinion_prof op_refuse
                            ON (op_refuse.id_opinion = o.id_opinion AND op_refuse.flg_type = g_opinion_prof_refuse)
                          LEFT OUTER JOIN cancel_reason cr_reject
                            ON cr_reject.id_cancel_reason = op_reject.id_cancel_reason
                          LEFT OUTER JOIN cancel_reason cr_refuse
                            ON cr_refuse.id_cancel_reason = op_refuse.id_cancel_reason
                          LEFT OUTER JOIN opinion_type ot
                            ON ot.id_opinion_type = o.id_opinion_type
                         WHERE o.id_opinion = i_opinion) unpivot include NULLS(data_source_val FOR data_source IN(opinion_type,
                                                                                                                  request_title,
                                                                                                                  speciality,
                                                                                                                  request_reason,
                                                                                                                  request_reason_ft,
                                                                                                                  name_prof_questioned,
                                                                                                                  notes,
                                                                                                                  state,
                                                                                                                  notes_cancel,
                                                                                                                  cancel_reason,
                                                                                                                  request_registered,
                                                                                                                  declined_title,
                                                                                                                  declined_date,
                                                                                                                  declined_by,
                                                                                                                  declined_notes,
                                                                                                                  declined_motive,
                                                                                                                  declined_registered,
                                                                                                                  accepted_title,
                                                                                                                  accepted_date,
                                                                                                                  accepted_by,
                                                                                                                  accepted_notes,
                                                                                                                  accepted_registered))
                
                UNION ALL
                SELECT data_source, data_source_val
                  FROM (SELECT (SELECT pk_message.get_message(i_lang, i_prof, 'SOCIAL_T100')
                                  FROM dual) fu_notes_title,
                               to_char(mfu.notes) AS fu_notes,
                               l_label_registered || ' ' ||
                               pk_prof_utils.get_name_signature(i_lang, i_prof, mfu.id_professional) ||
                               decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       mfu.id_professional,
                                                                       mfu.dt_register,
                                                                       mfu.id_episode),
                                      NULL,
                                      '; ',
                                      ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                               i_prof,
                                                                               mfu.id_professional,
                                                                               mfu.dt_register,
                                                                               mfu.id_episode) || '); ') ||
                               pk_date_utils.date_char_tsz(i_lang, mfu.dt_register, i_prof.institution, i_prof.software) AS fu_notes_registered,
                               NULL AS fu_notes_white_line
                          FROM management_follow_up mfu
                         WHERE mfu.id_opinion = i_opinion
                           AND mfu.flg_status NOT IN (pk_alert_constant.g_outdated, pk_alert_constant.g_cancelled)
                         ORDER BY mfu.dt_register) unpivot include NULLS(data_source_val FOR data_source IN(fu_notes_title,
                                                                                                            fu_notes,
                                                                                                            fu_notes_registered,
                                                                                                            fu_notes_white_line))) dd
          JOIN dd_content ddc
            ON ddc.area = pk_dynamic_detail.g_area_opinion
           AND ddc.data_source = dd.data_source
           AND ddc.flg_available = pk_alert_constant.g_yes
          JOIN dd_block ddb
            ON ddb.id_dd_block = ddc.id_dd_block
           AND ddb.area = pk_dynamic_detail.g_area_opinion
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                              --For L1, it will only show the message available in dd_code_source.
                              --If there is no message configured in dd_code_source, it will instead show
                              --the info from data_source_val
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NOT NULL THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              flg_type,
                              flg_html,
                              NULL,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       db.id_dd_block,
                       ddc.flg_html,
                       ddc.flg_clob
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_opinion
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR ddc.flg_type = 'WL') --white lines from follow-up notes 
                UNION
                --New lines
                SELECT ddc.data_code_message,
                       ddc.flg_type,
                       NULL                  data_source_val,
                       ddc.data_source,
                       ddb.rank              rnk,
                       ddc.rank,
                       ddb.id_dd_block,
                       ddc.flg_html,
                       ddc.flg_clob
                  FROM dd_content ddc
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_area_opinion
                  JOIN (SELECT DISTINCT id_dd_block --Join to show 'new lines' only for blocks that are available
                         FROM TABLE(l_tab_dd_block_data)
                        WHERE data_source_val IS NOT NULL) t
                    ON t.id_dd_block = ddb.id_dd_block
                 WHERE ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_opinion
                   AND ddc.flg_type = 'WL'
                   AND ddb.id_dd_block <> 4)
         ORDER BY rnk, rank;
    
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || ': '
                            END descr,
                           d.val,
                           d.flg_type,
                           d.flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn)
             ORDER BY rn;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_OPINION',
                                              'GET_OPINION_DET',
                                              o_error);
            RETURN FALSE;
    END get_opinion_det;

    FUNCTION get_opinion_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_OPINION_HIST';
    
        l_tab_dd_block_data_req    t_tab_dd_block_data;
        l_tab_dd_block_data_hist   t_tab_dd_block_data;
        l_tab_dd_block_data_app    t_tab_dd_block_data;
        l_tab_dd_block_data_refuse t_tab_dd_block_data;
        l_tab_dd_block_data_mnu    t_tab_dd_block_data;
    
        consult_dif_table_rec   consult_dif_table;
        consult_record          consult_type;
        consult_record_previous consult_type;
        consult_record_first    consult_type;
        all_consult_req         pk_types.cursor_type;
    
        diff_record         t_rec_consult_diff;
        tbl_updated_records table_t_consult_diff := table_t_consult_diff();
    
        i             NUMBER := 0;
        first_rec     NUMBER := 0;
        l_flag_change NUMBER := 0;
    
        l_tab_dd_data      t_tab_dd_data := t_tab_dd_data();
        l_data_source_list table_varchar := table_varchar();
    
        l_label_updated sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                i_prof,
                                                                                
                                                                                'CONSULT_REQUEST_T061') || ':';
    
        l_label_registered sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'CONSULT_REQUEST_T037') || ':';
        l_label_reject     sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'CONSULT_REQUEST_T052');
        l_label_accepted   sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                   i_prof,
                                                                                   'CONSULT_REQUEST_T046');
    
        l_label_any_prof sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021');
        l_na             sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'N/A');
    
        l_label_request sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T023');
    
    BEGIN
    
        g_error := 'Open cursor all_consult_req';
        OPEN all_consult_req FOR
            SELECT l_label_request request_title,
                   (SELECT pk_translation.get_translation(i_lang, ot.code_opinion_type)
                      FROM dual) opinion_type,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) speciality,
                   -- CASE
                   --      WHEN oh.id_opinion_type = g_ot_case_manager THEN
                   get_cm_req_reason_hist(i_lang, i_prof, oh.id_opinion_hist) request_reason,
                   --     ELSE
                   oh.desc_problem request_reason_ft,
                   --  END request_reason,
                   nvl2(oh.id_prof_questioned,
                        pk_prof_utils.get_name_signature(i_lang, i_prof, oh.id_prof_questioned),
                        pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021')) name_prof_questioned,
                   to_char(oh.notes) notes,
                   (SELECT pk_sysdomain.get_domain(g_opinion_consults, oh.flg_state, i_lang)
                      FROM dual) state,
                   NULL AS fu_notes,
                   oh.notes_cancel,
                   pk_translation.get_translation(i_lang, cr.code_cancel_reason) cancel_reason,
                   l_label_registered || ' ' ||
                   nvl2(oh.dt_last_update,
                        pk_prof_utils.get_name_signature(i_lang,
                                                          i_prof,
                                                          decode(oh.flg_state,
                                                                 g_status_cancel,
                                                                 oh.id_prof_created_hist,
                                                                 g_status_accepted,
                                                                 oh.id_prof_created_hist,
                                                                 g_status_declined,
                                                                 oh.id_prof_created_hist,
                                                                 g_status_approved,
                                                                 oh.id_prof_created_hist,
                                                                 g_status_completed,
                                                                 oh.id_prof_created_hist,
                                                                 oh.id_prof_questions)) ||
                         decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                 i_prof,
                                                                 decode(oh.flg_state,
                                                                        g_status_cancel,
                                                                        oh.id_prof_created_hist,
                                                                        g_status_accepted,
                                                                        oh.id_prof_created_hist,
                                                                        g_status_declined,
                                                                        oh.id_prof_created_hist,
                                                                        g_status_approved,
                                                                        oh.id_prof_created_hist,
                                                                        g_status_completed,
                                                                        oh.id_prof_created_hist,
                                                                        oh.id_prof_questions),
                                                                 oh.dt_last_update,
                                                                 oh.id_episode),
                                NULL,
                                '; ',
                                ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                         i_prof,
                                                                         decode(oh.flg_state,
                                                                                g_status_cancel,
                                                                                oh.id_prof_created_hist,
                                                                                g_status_accepted,
                                                                                oh.id_prof_created_hist,
                                                                                g_status_declined,
                                                                                oh.id_prof_created_hist,
                                                                                g_status_approved,
                                                                                oh.id_prof_created_hist,
                                                                                g_status_completed,
                                                                                oh.id_prof_created_hist,
                                                                                oh.id_prof_questions),
                                                                         oh.dt_last_update,
                                                                         oh.id_episode) || '); ') ||
                        --                                                                               
                         pk_date_utils.date_char_tsz(i_lang, oh.dt_last_update, i_prof.institution, i_prof.software),
                        NULL) request_registered,
                   to_char(oh.dt_last_update, 'YYYYMMDDhh24miss') create_time
              FROM opinion_hist oh
              LEFT OUTER JOIN cancel_reason cr
                ON cr.id_cancel_reason = oh.id_cancel_reason
              LEFT OUTER JOIN clinical_service cs
                ON cs.id_clinical_service = oh.id_clinical_service
              LEFT OUTER JOIN opinion_type ot
                ON ot.id_opinion_type = oh.id_opinion_type
             WHERE oh.id_opinion = i_opinion
             ORDER BY oh.dt_created_hist;
    
        -- find differences        
        g_error := 'LOOP sel_problem';
        LOOP
            FETCH all_consult_req
                INTO consult_record;
            EXIT WHEN all_consult_req%NOTFOUND;
        
            IF first_rec = 0
            THEN
                consult_record_first.request_title        := consult_record.request_title;
                consult_record_first.opinion_type         := consult_record.opinion_type;
                consult_record_first.speciality           := consult_record.speciality;
                consult_record_first.request_reason       := consult_record.request_reason;
                consult_record_first.request_reason_ft    := consult_record.request_reason_ft;
                consult_record_first.name_prof_questioned := consult_record.name_prof_questioned;
                consult_record_first.notes                := consult_record.notes;
                consult_record_first.state                := consult_record.state;
                consult_record_first.fu_notes             := consult_record.fu_notes;
                consult_record_first.notes_cancel         := consult_record.notes_cancel;
                consult_record_first.cancel_reason        := consult_record.cancel_reason;
                consult_record_first.registered           := consult_record.registered;
                consult_record_first.create_time          := consult_record.create_time;
                first_rec                                 := 1;
                i                                         := i + 1;
            ELSE
                l_flag_change := 0;
                IF (consult_record_previous.speciality <> consult_record.speciality)
                   OR (consult_record_previous.speciality IS NOT NULL AND consult_record.speciality IS NULL)
                   OR (consult_record_previous.speciality IS NULL AND consult_record.speciality IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).speciality_b := consult_record_previous.speciality;
                    consult_dif_table_rec(i).speciality_a := consult_record.speciality;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.request_reason <> consult_record.request_reason)
                   OR (consult_record_previous.request_reason IS NOT NULL AND consult_record.request_reason IS NULL)
                   OR (consult_record_previous.request_reason IS NULL AND consult_record.request_reason IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).request_reason_b := consult_record_previous.request_reason;
                    consult_dif_table_rec(i).request_reason_a := consult_record.request_reason;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.request_reason_ft <> consult_record.request_reason_ft)
                   OR
                   (consult_record_previous.request_reason_ft IS NOT NULL AND consult_record.request_reason_ft IS NULL)
                   OR
                   (consult_record_previous.request_reason_ft IS NULL AND consult_record.request_reason_ft IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).request_reason_ft_b := consult_record_previous.request_reason_ft;
                    consult_dif_table_rec(i).request_reason_ft_a := consult_record.request_reason_ft;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.name_prof_questioned <> consult_record.name_prof_questioned)
                   OR (consult_record_previous.name_prof_questioned IS NOT NULL AND
                   consult_record.name_prof_questioned IS NULL)
                   OR (consult_record_previous.name_prof_questioned IS NULL AND
                   consult_record.name_prof_questioned IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).name_prof_questioned_b := consult_record_previous.name_prof_questioned;
                    consult_dif_table_rec(i).name_prof_questioned_a := consult_record.name_prof_questioned;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.notes <> consult_record.notes)
                   OR (consult_record_previous.notes IS NOT NULL AND consult_record.notes IS NULL)
                   OR (consult_record_previous.notes IS NULL AND consult_record.notes IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).notes_b := consult_record_previous.notes;
                    consult_dif_table_rec(i).notes_a := consult_record.notes;
                    l_flag_change := 1;
                END IF;
            
                IF (consult_record_previous.state <> consult_record.state)
                   OR (consult_record_previous.state IS NOT NULL AND consult_record.state IS NULL)
                   OR (consult_record_previous.state IS NULL AND consult_record.state IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).state_b := consult_record_previous.state;
                    consult_dif_table_rec(i).state_a := consult_record.state;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.notes_cancel <> consult_record.notes_cancel)
                   OR (consult_record_previous.notes_cancel IS NOT NULL AND consult_record.notes_cancel IS NULL)
                   OR (consult_record_previous.notes_cancel IS NULL AND consult_record.notes_cancel IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).notes_cancel_b := consult_record_previous.notes_cancel;
                    consult_dif_table_rec(i).notes_cancel_a := consult_record.notes_cancel;
                    l_flag_change := 1;
                END IF;
                IF (consult_record_previous.cancel_reason <> consult_record.cancel_reason)
                   OR (consult_record_previous.cancel_reason IS NOT NULL AND consult_record.cancel_reason IS NULL)
                   OR (consult_record_previous.cancel_reason IS NULL AND consult_record.cancel_reason IS NOT NULL)
                THEN
                    consult_dif_table_rec(i).cancel_reason_b := consult_record_previous.cancel_reason;
                    consult_dif_table_rec(i).cancel_reason_a := consult_record.cancel_reason;
                    l_flag_change := 1;
                END IF;
            
                IF l_flag_change = 1
                THEN
                    consult_dif_table_rec(i).registered_b := consult_record_previous.registered;
                    consult_dif_table_rec(i).registered_a := consult_record.registered;
                    consult_dif_table_rec(i).create_time := consult_record.create_time;
                    i := i + 1;
                END IF;
            END IF;
            consult_record_previous.speciality           := consult_record.speciality;
            consult_record_previous.request_reason       := consult_record.request_reason;
            consult_record_previous.request_reason_ft    := consult_record.request_reason_ft;
            consult_record_previous.name_prof_questioned := consult_record.name_prof_questioned;
            consult_record_previous.notes                := consult_record.notes;
            consult_record_previous.state                := consult_record.state;
            consult_record_previous.fu_notes             := consult_record.fu_notes;
            consult_record_previous.notes_cancel         := consult_record.notes_cancel;
            consult_record_previous.cancel_reason        := consult_record.cancel_reason;
            consult_record_previous.registered           := consult_record.registered;
            consult_record_previous.create_time          := consult_record.create_time;
        END LOOP;
        CLOSE all_consult_req;
    
        IF consult_dif_table_rec.count <> 0
        THEN
            FOR k IN 1 .. consult_dif_table_rec.count
            LOOP
                tbl_updated_records.extend();
                diff_record := t_rec_consult_diff(NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL,
                                                  NULL);
                IF consult_dif_table_rec(k).speciality_b IS NOT NULL
                    OR consult_dif_table_rec(k).speciality_a IS NOT NULL
                THEN
                    diff_record.speciality_b := nvl(consult_dif_table_rec(k).speciality_b, l_na);
                    diff_record.speciality_a := nvl(consult_dif_table_rec(k).speciality_a, l_na);
                END IF;
                IF consult_dif_table_rec(k).request_reason_b IS NOT NULL
                    OR consult_dif_table_rec(k).request_reason_a IS NOT NULL
                THEN
                    diff_record.request_reason_b := consult_dif_table_rec(k).request_reason_b;
                    diff_record.request_reason_a := nvl(consult_dif_table_rec(k).request_reason_a, l_na);
                END IF;
                IF consult_dif_table_rec(k).request_reason_ft_b IS NOT NULL
                    OR consult_dif_table_rec(k).request_reason_ft_a IS NOT NULL
                THEN
                    diff_record.request_reason_ft_b := consult_dif_table_rec(k).request_reason_ft_b;
                    diff_record.request_reason_ft_a := nvl(consult_dif_table_rec(k).request_reason_ft_a, l_na);
                END IF;
                IF consult_dif_table_rec(k).name_prof_questioned_b IS NOT NULL
                    OR consult_dif_table_rec(k).name_prof_questioned_a IS NOT NULL
                THEN
                    diff_record.name_prof_questioned_b := nvl(consult_dif_table_rec(k).name_prof_questioned_b,
                                                              l_label_any_prof);
                    diff_record.name_prof_questioned_a := nvl(consult_dif_table_rec(k).name_prof_questioned_a,
                                                              l_label_any_prof);
                END IF;
                IF consult_dif_table_rec(k).notes_b IS NOT NULL
                    OR consult_dif_table_rec(k).notes_a IS NOT NULL
                THEN
                    diff_record.notes_b := consult_dif_table_rec(k).notes_b;
                    diff_record.notes_a := nvl(consult_dif_table_rec(k).notes_a, l_na);
                
                END IF;
                IF consult_dif_table_rec(k).state_b IS NOT NULL
                    OR consult_dif_table_rec(k).state_a IS NOT NULL
                THEN
                    diff_record.state_b := nvl(consult_dif_table_rec(k).state_b, l_na);
                    diff_record.state_a := nvl(consult_dif_table_rec(k).state_a, l_na);
                END IF;
                IF consult_dif_table_rec(k).notes_cancel_b IS NOT NULL
                    OR consult_dif_table_rec(k).notes_cancel_a IS NOT NULL
                THEN
                    diff_record.notes_cancel_a := nvl(consult_dif_table_rec(k).notes_cancel_a, l_na);
                END IF;
                IF consult_dif_table_rec(k).cancel_reason_b IS NOT NULL
                    OR consult_dif_table_rec(k).cancel_reason_a IS NOT NULL
                THEN
                    diff_record.cancel_reason_a := nvl(consult_dif_table_rec(k).cancel_reason_a, l_na);
                
                END IF;
            
                diff_record.registered_a := consult_dif_table_rec(k).registered_a;
                diff_record.create_time  := consult_dif_table_rec(k).create_time;
            
                tbl_updated_records(k) := diff_record;
            END LOOP;
        END IF;
    
        --REQUISITION BLOCK 
        g_error := 'REQUISITION BLOCK';
        SELECT t_rec_dd_block_data(t.id_dd_block,
                                   t.rank,
                                   NULL,
                                   NULL,
                                   t.condition_val,
                                   NULL,
                                   NULL,
                                   t.data_source,
                                   t.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_req
          FROM (SELECT dd.data_source, dd.data_source_val, ddb.id_dd_block, ddb.rank, ddb.condition_val, 1 rank_hist
                  FROM (SELECT data_source, data_source_val
                          FROM (SELECT consult_record_first.request_title,
                                       consult_record_first.opinion_type,
                                       consult_record_first.speciality,
                                       consult_record_first.request_reason,
                                       consult_record_first.request_reason_ft,
                                       consult_record_first.name_prof_questioned,
                                       to_char(consult_record_first.notes) notes,
                                       consult_record_first.state,
                                       consult_record_first.fu_notes,
                                       consult_record_first.notes_cancel,
                                       consult_record_first.cancel_reason,
                                       consult_record_first.registered request_registered,
                                       NULL request_white_line
                                  FROM dual) --
                               unpivot include NULLS(data_source_val FOR data_source IN(request_title,
                                                                                        opinion_type,
                                                                                        speciality,
                                                                                        request_reason,
                                                                                        request_reason_ft,
                                                                                        name_prof_questioned,
                                                                                        notes,
                                                                                        state,
                                                                                        fu_notes,
                                                                                        notes_cancel,
                                                                                        cancel_reason,
                                                                                        request_registered,
                                                                                        request_white_line))
                        
                        ) dd
                  JOIN dd_content ddc
                    ON ddc.area = pk_dynamic_detail.g_area_opinion
                   AND ddc.data_source = dd.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_area_opinion
                   AND ddb.flg_available = pk_alert_constant.g_yes) t;
    
        --FOLLOW_UP NOTES BLOCK 
        g_error := 'FOLLOW_UP NOTES BLOCK';
        SELECT t_rec_dd_block_data(t.id_dd_block,
                                   to_number(1000 || rownum),
                                   NULL,
                                   NULL,
                                   t.condition_val,
                                   NULL,
                                   NULL,
                                   t.data_source,
                                   t.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_mnu
          FROM (SELECT dd.data_source, dd.data_source_val, ddb.id_dd_block, ddb.rank, ddb.condition_val
                  FROM (SELECT (SELECT pk_message.get_message(i_lang, i_prof, 'SOCIAL_T100')
                                  FROM dual) fu_notes_title,
                               to_char(mfu.notes) AS fu_notes,
                               l_label_registered || ' ' ||
                               pk_prof_utils.get_name_signature(i_lang, i_prof, mfu.id_professional) ||
                               decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       mfu.id_professional,
                                                                       mfu.dt_register,
                                                                       mfu.id_episode),
                                      NULL,
                                      '; ',
                                      ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                               i_prof,
                                                                               mfu.id_professional,
                                                                               mfu.dt_register,
                                                                               mfu.id_episode) || '); ') ||
                               pk_date_utils.date_char_tsz(i_lang, mfu.dt_register, i_prof.institution, i_prof.software) AS fu_notes_registered,
                               NULL AS fu_notes_white_line
                          FROM management_follow_up mfu
                         WHERE mfu.id_opinion = i_opinion
                           AND mfu.notes IS NOT NULL
                           AND mfu.flg_status NOT IN (pk_alert_constant.g_outdated, pk_alert_constant.g_cancelled)
                         ORDER BY mfu.dt_register) unpivot include NULLS(data_source_val FOR data_source IN(fu_notes_title,
                                                                                                            fu_notes,
                                                                                                            fu_notes_registered,
                                                                                                            fu_notes_white_line)) dd
                  JOIN dd_content ddc
                    ON ddc.area = pk_dynamic_detail.g_area_opinion
                   AND ddc.data_source = dd.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_area_opinion
                   AND ddb.flg_available = pk_alert_constant.g_yes) t
         WHERE (t.data_source = 'FU_NOTES_TITLE' AND rownum = 1)
            OR t.data_source <> 'FU_NOTES_TITLE';
    
        --APPROVAL BLOCK
        g_error := 'APPROVAL BLOCK';
        SELECT t_rec_dd_block_data(t.id_dd_block,
                                   t.rank,
                                   NULL,
                                   NULL,
                                   t.condition_val,
                                   NULL,
                                   NULL,
                                   t.data_source,
                                   t.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_app
          FROM (SELECT dd.data_source, dd.data_source_val, ddb.id_dd_block, ddb.rank, ddb.condition_val
                  FROM (SELECT data_source, data_source_val
                          FROM (SELECT nvl2(op_accept.dt_opinion_prof_tstz, l_label_accepted, NULL) accepted_title,
                                       CASE
                                            WHEN op_accept.dt_opinion_prof_tstz IS NOT NULL
                                                 AND op_accept.flg_type = g_opinion_prof_accept THEN
                                             pk_date_utils.date_char_tsz(i_lang,
                                                                         op_accept.dt_opinion_prof_tstz,
                                                                         i_prof.institution,
                                                                         i_prof.software)
                                            ELSE
                                             NULL
                                        END accepted_date,
                                       CASE
                                            WHEN op_accept.id_professional IS NOT NULL
                                                 AND op_accept.flg_type = g_opinion_prof_accept THEN
                                             pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional)
                                            ELSE
                                             NULL
                                        END accepted_by,
                                       CASE
                                            WHEN op_accept.dt_opinion_prof_tstz IS NOT NULL
                                                 AND op_accept.flg_type = g_opinion_prof_accept THEN
                                             op_accept.desc_reply
                                            ELSE
                                             NULL
                                        END accepted_notes,
                                       CASE
                                            WHEN op_accept.flg_type = g_opinion_prof_accept THEN
                                             nvl2(op_accept.dt_opinion_prof_tstz,
                                                  l_label_registered || ' ' ||
                                                  pk_prof_utils.get_name_signature(i_lang, i_prof, op_accept.id_professional) ||
                                                  decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                          i_prof,
                                                                                          op_accept.id_professional,
                                                                                          op_accept.dt_opinion_prof_tstz,
                                                                                          o.id_episode),
                                                         NULL,
                                                         '; ',
                                                         ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                                  i_prof,
                                                                                                  op_accept.id_professional,
                                                                                                  op_accept.dt_opinion_prof_tstz,
                                                                                                  o.id_episode) || '); ') ||
                                                  pk_date_utils.date_char_tsz(i_lang,
                                                                              op_accept.dt_opinion_prof_tstz,
                                                                              i_prof.institution,
                                                                              i_prof.software),
                                                  NULL)
                                            ELSE
                                             NULL
                                        END accepted_registered,
                                       NULL accepted_white_line
                                  FROM opinion o
                                 INNER JOIN opinion_prof op_accept
                                    ON (op_accept.id_opinion = o.id_opinion AND op_accept.flg_type = g_opinion_prof_accept)
                                 WHERE o.id_opinion = i_opinion) unpivot include NULLS(data_source_val FOR data_source IN(accepted_title,
                                                                                                                          accepted_date,
                                                                                                                          accepted_by,
                                                                                                                          accepted_notes,
                                                                                                                          accepted_registered,
                                                                                                                          accepted_white_line))
                        
                        ) dd
                  JOIN dd_content ddc
                    ON ddc.area = pk_dynamic_detail.g_area_opinion
                   AND ddc.data_source = dd.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_area_opinion
                   AND ddb.flg_available = pk_alert_constant.g_yes) t;
    
        --REFUSAL BLOCK
        g_error := 'REFUSAL BLOCK';
        SELECT t_rec_dd_block_data(t.id_dd_block,
                                   t.rank,
                                   NULL,
                                   NULL,
                                   t.condition_val,
                                   NULL,
                                   NULL,
                                   t.data_source,
                                   t.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_refuse
          FROM (SELECT dd.data_source, dd.data_source_val, ddb.id_dd_block, ddb.rank, ddb.condition_val
                  FROM (SELECT data_source, data_source_val
                          FROM (SELECT nvl2(op_refuse.dt_opinion_prof_tstz, l_label_accepted, NULL) declined_title,
                                       CASE
                                            WHEN op_refuse.dt_opinion_prof_tstz IS NOT NULL THEN
                                             pk_date_utils.date_char_tsz(i_lang,
                                                                         op_refuse.dt_opinion_prof_tstz,
                                                                         i_prof.institution,
                                                                         i_prof.software)
                                            ELSE
                                             NULL
                                        END declined_date,
                                       CASE
                                            WHEN op_refuse.id_professional IS NOT NULL THEN
                                             pk_prof_utils.get_name_signature(i_lang, i_prof, op_refuse.id_professional)
                                            ELSE
                                             NULL
                                        END declined_by,
                                       CASE
                                            WHEN op_refuse.dt_opinion_prof_tstz IS NOT NULL THEN
                                             op_refuse.desc_reply
                                            ELSE
                                             NULL
                                        END declined_notes,
                                       CASE
                                            WHEN op_refuse.flg_type IN (g_opinion_prof_reject, g_opinion_prof_refuse) THEN
                                             nvl2(op_refuse.dt_opinion_prof_tstz,
                                                  l_label_registered || ' ' ||
                                                  pk_prof_utils.get_name_signature(i_lang, i_prof, op_refuse.id_professional) ||
                                                  decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                                          i_prof,
                                                                                          op_refuse.id_professional,
                                                                                          op_refuse.dt_opinion_prof_tstz,
                                                                                          o.id_episode),
                                                         NULL,
                                                         '; ',
                                                         ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                                                  i_prof,
                                                                                                  op_refuse.id_professional,
                                                                                                  op_refuse.dt_opinion_prof_tstz,
                                                                                                  o.id_episode) || '); ') ||
                                                  
                                                  pk_date_utils.date_char_tsz(i_lang,
                                                                              op_refuse.dt_opinion_prof_tstz,
                                                                              i_prof.institution,
                                                                              i_prof.software),
                                                  NULL)
                                            ELSE
                                             NULL
                                        END declined_registered,
                                       CASE
                                            WHEN cr_refuse.code_cancel_reason IS NOT NULL
                                                 AND op_refuse.flg_type IN (g_opinion_prof_reject, g_opinion_prof_refuse) THEN
                                             pk_translation.get_translation(i_lang, cr_refuse.code_cancel_reason)
                                            ELSE
                                             NULL
                                        END declined_motive
                                  FROM opinion o
                                  LEFT OUTER JOIN opinion_prof op_refuse
                                    ON (op_refuse.id_opinion = o.id_opinion AND
                                       op_refuse.flg_type IN (g_opinion_prof_reject, g_opinion_prof_refuse))
                                  LEFT OUTER JOIN cancel_reason cr_refuse
                                    ON cr_refuse.id_cancel_reason = op_refuse.id_cancel_reason
                                 WHERE o.id_opinion = i_opinion) --
                               unpivot include NULLS(data_source_val FOR data_source IN(declined_title,
                                                                                        declined_date,
                                                                                        declined_by,
                                                                                        declined_notes,
                                                                                        declined_registered,
                                                                                        declined_motive))
                        
                        ) dd
                  JOIN dd_content ddc
                    ON ddc.area = pk_dynamic_detail.g_area_opinion
                   AND ddc.data_source = dd.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_area_opinion
                   AND ddb.flg_available = pk_alert_constant.g_yes) t;
    
        --HISTORY BLOCKS
        g_error := 'HISTORY BLOCKS';
        SELECT t_rec_dd_block_data(t.id_dd_block,
                                   (rn * 1000),
                                   NULL,
                                   NULL,
                                   t.condition_val,
                                   NULL,
                                   NULL,
                                   t.data_source,
                                   t.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data_hist
          FROM (SELECT dd.data_source,
                       dd.data_source_val,
                       ddb.id_dd_block,
                       ddc.rank,
                       ddb.condition_val,
                       row_number() over(PARTITION BY ddc.data_source ORDER BY rn1 ASC) AS rn
                  FROM (SELECT data_source, data_source_val, rownum AS rn1
                          FROM (SELECT l_label_request request_title_update,
                                       NULL opinion_type,
                                       t.speciality_b speciality,
                                       CASE
                                            WHEN t.request_reason_b IS NULL THEN
                                             t.speciality_a
                                            ELSE
                                             NULL
                                        END speciality_new,
                                       CASE
                                            WHEN t.request_reason_b IS NOT NULL THEN
                                             t.speciality_a
                                            ELSE
                                             NULL
                                        END speciality_update,
                                       t.request_reason_b request_reason,
                                       CASE
                                            WHEN t.request_reason_b IS NULL THEN
                                             t.request_reason_a
                                            ELSE
                                             NULL
                                        END request_reason_new,
                                       CASE
                                            WHEN t.request_reason_b IS NOT NULL THEN
                                             t.request_reason_a
                                            ELSE
                                             NULL
                                        END request_reason_update,
                                       t.request_reason_ft_b request_reason_ft,
                                       CASE
                                            WHEN t.request_reason_ft_b IS NULL THEN
                                             t.request_reason_ft_a
                                            ELSE
                                             NULL
                                        END request_reason_ft_new,
                                       CASE
                                            WHEN t.request_reason_ft_b IS NOT NULL THEN
                                             t.request_reason_ft_a
                                            ELSE
                                             NULL
                                        END request_reason_ft_update,
                                       t.name_prof_questioned_b name_prof_questioned,
                                       CASE
                                            WHEN t.name_prof_questioned_b IS NULL THEN
                                             t.name_prof_questioned_a
                                            ELSE
                                             NULL
                                        END name_prof_questioned_new,
                                       CASE
                                            WHEN t.name_prof_questioned_b IS NOT NULL THEN
                                             t.name_prof_questioned_a
                                            ELSE
                                             NULL
                                        END name_prof_questioned_update,
                                       to_char(t.notes_b) notes,
                                       CASE
                                            WHEN t.notes_b IS NULL THEN
                                             to_char(t.notes_a)
                                            ELSE
                                             NULL
                                        END notes_new,
                                       CASE
                                            WHEN t.notes_b IS NOT NULL THEN
                                             to_char(t.notes_a)
                                            ELSE
                                             NULL
                                        END notes_update,
                                       t.state_b state,
                                       t.state_a state_new,
                                       t.notes_cancel_a notes_cancel_new,
                                       t.cancel_reason_a cancel_reason_new,
                                       t.registered_a request_registered,
                                       NULL request_white_line
                                  FROM (SELECT tt.*
                                          FROM TABLE(tbl_updated_records) tt) t) --
                               unpivot include NULLS(data_source_val FOR data_source IN(request_title_update,
                                                                                        opinion_type,
                                                                                        speciality,
                                                                                        speciality_new,
                                                                                        speciality_update,
                                                                                        request_reason,
                                                                                        request_reason_new,
                                                                                        request_reason_update,
                                                                                        request_reason_ft,
                                                                                        request_reason_ft_new,
                                                                                        request_reason_ft_update,
                                                                                        name_prof_questioned,
                                                                                        name_prof_questioned_new,
                                                                                        name_prof_questioned_update,
                                                                                        notes,
                                                                                        notes_new,
                                                                                        notes_update,
                                                                                        state,
                                                                                        state_new,
                                                                                        notes_cancel_new,
                                                                                        cancel_reason_new,
                                                                                        request_registered,
                                                                                        request_white_line))
                        
                        ) dd
                  JOIN dd_content ddc
                    ON ddc.area = pk_dynamic_detail.g_area_opinion
                   AND ddc.data_source = dd.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                  JOIN dd_block ddb
                    ON ddb.id_dd_block = ddc.id_dd_block
                   AND ddb.area = pk_dynamic_detail.g_area_opinion
                   AND ddb.flg_available = pk_alert_constant.g_yes) t;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  ELSE
                                   NULL
                              END, --DESCR
                              CASE
                              --For L1, it will only show the message available in dd_code_source.
                              --If there is no message configured in dd_code_source, it will instead show
                              --the info from data_source_val
                                  WHEN flg_type = 'L1'
                                       AND data_code_message IS NOT NULL THEN
                                   NULL
                                  ELSE
                                   data_source_val
                              END, --VAL
                              flg_type,
                              flg_html,
                              NULL,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       ddc.rank,
                       200 AS rank_hist,
                       ddc.flg_html,
                       ddc.flg_clob
                  FROM TABLE(l_tab_dd_block_data_hist) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_opinion
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR ddc.flg_type = 'WL')
                --REQUEST                
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       0 rank_hist,
                       ddc.flg_html,
                       ddc.flg_clob
                  FROM TABLE(l_tab_dd_block_data_req) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_opinion
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR ddc.flg_type = 'WL')
                --APPROVED
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       100 rank_hist,
                       ddc.flg_html,
                       ddc.flg_clob
                  FROM TABLE(l_tab_dd_block_data_app) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_opinion
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR ddc.flg_type = 'WL')
                --REFUSE
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       100 rank_hist,
                       ddc.flg_html,
                       ddc.flg_clob
                  FROM TABLE(l_tab_dd_block_data_refuse) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_opinion
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND db.data_source_val IS NOT NULL
                --FOLLOW_UP NOTES               
                UNION ALL
                SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       50 rank_hist,
                       ddc.flg_html,
                       ddc.flg_clob
                  FROM TABLE(l_tab_dd_block_data_mnu) db
                  JOIN dd_content ddc
                    ON ddc.data_source = db.data_source
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND ddc.area = pk_dynamic_detail.g_area_opinion
                 WHERE ddc.id_dd_block = db.id_dd_block
                   AND (db.data_source_val IS NOT NULL OR ddc.flg_type = 'WL'))
         ORDER BY rank_hist DESC, rnk DESC, rank;
    
        OPEN o_detail FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                ELSE
                                 d.descr || ': '
                            END descr,
                           d.val,
                           d.flg_type,
                           d.flg_html,
                           d.val_clob,
                           d.flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn)
             ORDER BY rn;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_OPINION',
                                              'GET_OPINION_HIST',
                                              o_error);
            RETURN FALSE;
    END get_opinion_hist;

    FUNCTION get_consult_for_reply
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_CONSULT_FOR_REPLY';
    
        l_ds_internal_name        ds_component.internal_name%TYPE;
        l_id_ds_component         ds_component.id_ds_component%TYPE;
        l_index_current_component NUMBER;
    
        l_rows table_number;
    
        l_id_spec            opinion.id_speciality%TYPE;
        l_desc_spec          translation.desc_lang_1%TYPE;
        l_id_prof_questioned opinion.id_prof_questioned%TYPE;
        l_prof_questioned    VARCHAR2(1000 CHAR);
        l_flg_priority       opinion.flg_priority%TYPE;
        l_priority_desc      sys_domain.desc_val%TYPE;
        l_desc_problem       opinion.desc_problem%TYPE;
    
        i_is_default               BOOLEAN;
        i_res                      VARCHAR2(1);
        l_face_to_face_flg         sys_config.value%TYPE;
        l_face_to_face_default_flg VARCHAR2(1 CHAR);
    
        l_co_sign_enabled sys_config.value%TYPE;
        l_dt_co_sign      TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_id_specialty           opinion.id_speciality%TYPE;
        l_id_clinical_service    clinical_service.id_clinical_service%TYPE;
        l_clin_serv_list         table_number;
        l_clin_serv_exists       NUMBER := -1;
        l_same_spec_or_clin_serv BOOLEAN := FALSE;
        l_specialty              professional.id_speciality%TYPE;
        l_id_prof_questions      opinion.id_prof_questions%TYPE;
    BEGIN
    
        IF i_action IS NULL
           OR i_action = -1
        THEN
            --Obtain the information of the request
            BEGIN
                SELECT coalesce(o.id_speciality, o.id_clinical_service),
                       coalesce(nvl2(o.id_speciality,
                                     (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                                        FROM speciality s
                                       WHERE s.id_speciality = o.id_speciality),
                                     NULL),
                                nvl2(o.id_clinical_service,
                                     (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                        FROM clinical_service cs
                                       WHERE cs.id_clinical_service = o.id_clinical_service),
                                     NULL)),
                       nvl(o.id_prof_questioned, -1),
                       --FUTURE_EVENTS_T017
                       pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                       o.flg_priority,
                       pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang),
                       o.desc_problem,
                       o.id_speciality,
                       o.id_clinical_service,
                       o.id_prof_questions
                  INTO l_id_spec,
                       l_desc_spec,
                       l_id_prof_questioned,
                       l_prof_questioned,
                       l_flg_priority,
                       l_priority_desc,
                       l_desc_problem,
                       l_id_specialty,
                       l_id_clinical_service,
                       l_id_prof_questions
                  FROM opinion o
                 WHERE o.id_opinion = i_tbl_id_pk(1);
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_spec             := NULL;
                    l_desc_spec           := NULL;
                    l_id_prof_questioned  := NULL;
                    l_prof_questioned     := NULL;
                    l_flg_priority        := NULL;
                    l_priority_desc       := NULL;
                    l_id_specialty        := NULL;
                    l_id_clinical_service := NULL;
                    l_id_prof_questions   := NULL;
            END;
        
            --Checking if co-sign is needed
            l_co_sign_enabled := pk_sysconfig.get_config(g_sys_config_consult_co_sign, i_prof);
        
            IF l_co_sign_enabled = pk_alert_constant.g_yes
            THEN
                IF l_id_prof_questioned IS NOT NULL
                THEN
                    -- opinion asked to a specific doctor
                    IF l_id_prof_questioned <> i_prof.id
                       AND l_id_prof_questioned IS NOT NULL
                    THEN
                        l_dt_co_sign := current_timestamp;
                    END IF;
                ELSE
                    --opinion asked to any doctor from that specialty/clincal service
                    IF l_id_clinical_service IS NOT NULL
                    THEN
                        l_clin_serv_list := pk_prof_utils.get_list_prof_dep_clin_serv(i_lang  => i_lang,
                                                                                      i_prof  => i_prof,
                                                                                      o_error => o_error);
                    
                        SELECT COUNT(1)
                          INTO l_clin_serv_exists
                          FROM TABLE(l_clin_serv_list)
                         WHERE column_value = l_id_clinical_service;
                    
                        IF l_clin_serv_exists > 0
                        THEN
                            l_same_spec_or_clin_serv := TRUE;
                        END IF;
                    ELSIF l_id_specialty IS NOT NULL
                    THEN
                        l_specialty := pk_prof_utils.get_prof_speciality_id(i_lang, i_prof);
                        IF l_specialty = l_id_specialty
                        THEN
                            l_same_spec_or_clin_serv := TRUE;
                        END IF;
                    END IF;
                
                    IF NOT l_same_spec_or_clin_serv
                    THEN
                        -- if doctor answering is not from the required specialty
                        l_dt_co_sign := current_timestamp;
                    ELSE
                        IF i_prof.id = l_id_prof_questions
                        THEN
                            -- if doctor answering is from the same specialty and is the one that asked for the consult
                            l_dt_co_sign := current_timestamp;
                        ELSE
                            -- if doctor answering is from the same specialty and is the not one that asked for the consult
                            l_dt_co_sign := NULL;
                        END IF;
                    END IF;
                END IF;
            END IF;
        
            BEGIN
                i_is_default := pk_opinion.get_face_to_face_default(i_lang, i_prof, o_error);
            
                IF (i_is_default)
                THEN
                    i_res := pk_alert_constant.g_yes;
                ELSE
                    i_res := pk_alert_constant.g_no;
                END IF;
            
                SELECT face_to_face_flg, face_to_face_default_flg
                  INTO l_face_to_face_flg, l_face_to_face_default_flg
                  FROM (SELECT sc.value face_to_face_flg, nvl(i_res, pk_alert_constant.g_no) face_to_face_default_flg
                          FROM sys_config sc
                         WHERE sc.id_sys_config = g_opinion_f_t_f_available
                           AND ((sc.id_software = i_prof.software AND sc.id_institution = i_prof.institution) OR
                               sc.id_software = 0 OR sc.id_institution = 0)
                           AND rownum = 1
                        UNION ALL
                        SELECT pk_alert_constant.g_no face_to_face_flg, pk_alert_constant.g_no face_to_face_default_flg
                          FROM dual)
                 WHERE rownum = 1;
            EXCEPTION
                WHEN OTHERS THEN
                    l_face_to_face_flg         := pk_alert_constant.g_no;
                    l_face_to_face_default_flg := pk_alert_constant.g_no;
            END;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = 'DS_CLINICAL_SERVICE' THEN
                                                                  to_char(l_id_spec)
                                                                 WHEN t.internal_name_child = 'DS_PROFESSIONAL' THEN
                                                                  to_char(l_id_prof_questioned)
                                                                 WHEN t.internal_name_child = 'DS_PRIORITY' THEN
                                                                  l_flg_priority
                                                                 WHEN t.internal_name_child = 'DS_NOTES' THEN
                                                                  l_desc_problem
                                                                 WHEN t.internal_name_child = 'DS_CONSULT_REPLY_OPTIONS' THEN
                                                                  decode(l_face_to_face_flg,
                                                                         pk_alert_constant.g_yes,
                                                                         l_face_to_face_default_flg,
                                                                         l_face_to_face_flg)
                                                                 WHEN t.internal_name_child = 'DS_ORDERED_AT'
                                                                      AND l_dt_co_sign IS NOT NULL THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_dt_co_sign, i_prof => i_prof)
                                                                 WHEN t.internal_name_child = 'DS_ORDERED_BY'
                                                                      AND l_dt_co_sign IS NOT NULL
                                                                      AND (l_id_prof_questioned IS NOT NULL AND l_id_prof_questioned <> -1) THEN
                                                                  to_char(l_id_prof_questioned)
                                                                 WHEN t.internal_name_child = 'DS_CO_SIGN_CONTROL'
                                                                      AND l_dt_co_sign IS NOT NULL THEN
                                                                  'Y'
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = 'DS_CLINICAL_SERVICE' THEN
                                                                  l_desc_spec
                                                                 WHEN t.internal_name_child = 'DS_PROFESSIONAL' THEN
                                                                  l_prof_questioned
                                                                 WHEN t.internal_name_child = 'DS_PRIORITY' THEN
                                                                  l_priority_desc
                                                                 WHEN t.internal_name_child = 'DS_NOTES' THEN
                                                                  l_desc_problem
                                                                 WHEN t.internal_name_child = 'DS_ORDERED_BY'
                                                                      AND l_dt_co_sign IS NOT NULL
                                                                      AND (l_id_prof_questioned IS NOT NULL AND l_id_prof_questioned <> -1) THEN
                                                                  l_prof_questioned
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => pk_alert_constant.g_yes,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE
                                                                 WHEN t.internal_name_child = 'DS_CONSULT_REPLY_OPTIONS' THEN
                                                                  decode(l_face_to_face_flg, pk_alert_constant.g_yes, 'A', 'I')
                                                                 WHEN t.internal_name_child IN ('DS_ORDER_TYPE', 'DS_ORDERED_BY', 'DS_ORDERED_AT')
                                                                      AND l_dt_co_sign IS NOT NULL THEN
                                                                  'M'
                                                                 ELSE
                                                                  'R'
                                                             END,
                                       flg_multi_status   => NULL,
                                       idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             WHERE d.internal_name IN ('DS_CLINICAL_SERVICE',
                                       'DS_PROFESSIONAL',
                                       'DS_PRIORITY',
                                       'DS_NOTES',
                                       'DS_CONSULT_REPLY_OPTIONS',
                                       'DS_ORDER_TYPE',
                                       'DS_ORDERED_BY',
                                       'DS_ORDERED_AT',
                                       'DS_CO_SIGN_CONTROL');
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_consult_for_reply;

    FUNCTION get_order_set_consult_form
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
    
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_ORDER_SET_CONSULT_FORM';
    
        l_ds_internal_name        ds_component.internal_name%TYPE;
        l_id_ds_component         ds_component.id_ds_component%TYPE;
        l_index_current_component NUMBER;
    
        l_rows table_number;
    
        l_id_spec              opinion.id_speciality%TYPE;
        l_desc_spec            translation.desc_lang_1%TYPE;
        l_flg_priority         opinion.flg_priority%TYPE;
        l_priority_desc        sys_domain.desc_val%TYPE;
        l_desc_problem         opinion.desc_problem%TYPE;
        l_id_prof_questioned   opinion.id_prof_questioned%TYPE;
        l_desc_prof_questioned VARCHAR2(4000 CHAR);
    
        l_id_opinion opinion.id_opinion%TYPE;
    BEGIN
    
        IF i_action IN (pk_order_sets.g_order_set_bo_edit_task, pk_order_sets.g_order_set_fo_request)
        THEN
        
            g_error := 'ERROR GETTING ID_OPINION';
            IF i_action = pk_order_sets.g_order_set_fo_request
            THEN
                SELECT o.id_task_link
                  INTO l_id_opinion
                  FROM order_set_process_task_link o
                 WHERE o.id_order_set_process_task = i_tbl_id_pk(2);
            ELSE
                SELECT ostl.id_task_link
                  INTO l_id_opinion
                  FROM order_set_task_link ostl
                 WHERE ostl.id_order_set_task = i_tbl_id_pk(2);
            END IF;
        
            --Obtain the information of the request
            BEGIN
                SELECT coalesce(o.id_speciality, o.id_clinical_service),
                       coalesce(nvl2(o.id_speciality,
                                     (SELECT pk_translation.get_translation(i_lang, s.code_speciality)
                                        FROM speciality s
                                       WHERE s.id_speciality = o.id_speciality),
                                     NULL),
                                nvl2(o.id_clinical_service,
                                     (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                        FROM clinical_service cs
                                       WHERE cs.id_clinical_service = o.id_clinical_service),
                                     NULL)),
                       o.flg_priority,
                       pk_sysdomain.get_domain(g_opinion_priority, o.flg_priority, i_lang),
                       o.desc_problem,
                       nvl(o.id_prof_questioned, g_any_prof) prof_id,
                       decode(o.id_prof_questioned,
                              NULL,
                              pk_message.get_message(i_lang, i_prof, 'CONSULT_REQUEST_T021'),
                              pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned)) prof_desc
                  INTO l_id_spec,
                       l_desc_spec,
                       l_flg_priority,
                       l_priority_desc,
                       l_desc_problem,
                       l_id_prof_questioned,
                       l_desc_prof_questioned
                  FROM opinion o
                 WHERE o.id_opinion = l_id_opinion;
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_spec       := NULL;
                    l_desc_spec     := NULL;
                    l_flg_priority  := NULL;
                    l_priority_desc := NULL;
                    l_desc_problem  := NULL;
            END;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_specialty THEN
                                                                  to_char(l_id_spec)
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_priority THEN
                                                                  l_flg_priority
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_professional THEN
                                                                  to_char(l_id_prof_questioned)
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_specialty THEN
                                                                  l_desc_spec
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_priority THEN
                                                                  l_priority_desc
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_notes THEN
                                                                  l_desc_problem
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_professional THEN
                                                                  l_desc_prof_questioned
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => t.id_unit_measure,
                                       desc_unit_measure  => CASE
                                                                 WHEN t.id_unit_measure IS NOT NULL THEN
                                                                  pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                                                               i_prof         => i_prof,
                                                                                                               i_unit_measure => t.id_unit_measure)
                                                             END,
                                       flg_validation     => pk_orders_constant.g_component_valid,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_professional
                                                                      AND i_action = pk_order_sets.g_order_set_fo_request THEN
                                                                  pk_orders_constant.g_component_mandatory
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_specialty
                                                                      AND i_action = pk_order_sets.g_order_set_fo_request THEN
                                                                  pk_orders_constant.g_component_read_only
                                                                 WHEN t.internal_name_child = pk_orders_constant.g_ds_priority
                                                                      AND i_action = pk_order_sets.g_order_set_bo_edit_task THEN
                                                                  pk_orders_constant.g_component_active
                                                                 ELSE
                                                                  coalesce(def.flg_event_type, pk_orders_constant.g_component_active)
                                                             END,
                                       flg_multi_status   => pk_alert_constant.g_no,
                                       idx                => i_idx)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           dc.id_unit_measure
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
              LEFT JOIN ds_def_event def
                ON def.id_ds_cmpt_mkt_rel = t.id_ds_cmpt_mkt_rel
             WHERE d.flg_component_type = 'L'
             ORDER BY t.rn;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_order_set_consult_form;

    FUNCTION get_reason_request_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_core_domain IS
        l_func_name CONSTANT obj_name := 'GET_REASON_REQUEST_LIST';
    
        l_ret   t_tbl_core_domain;
        l_error t_error_out;
    BEGIN
    
        g_error := 'OPEN L_RET';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t_row_core_domain(internal_name => NULL,
                                         desc_domain   => desc_diagnosis,
                                         domain_value  => id_alert_diagnosis,
                                         order_rank    => NULL,
                                         img_name      => NULL)
                  FROM (SELECT z.id_alert_diagnosis, z.desc_diagnosis
                          FROM (SELECT ed.id_alert_diagnosis,
                                       pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_alert_diagnosis  => ed.id_alert_diagnosis,
                                                                  i_id_diagnosis        => d.id_diagnosis,
                                                                  i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                                                  i_code                => d.code_icd,
                                                                  i_flg_other           => d.flg_other,
                                                                  i_flg_std_diag        => pk_alert_constant.g_yes,
                                                                  i_epis_diag           => ed.id_epis_diagnosis) desc_diagnosis,
                                       row_number() over(PARTITION BY d.id_diagnosis ORDER BY ed.dt_epis_diagnosis_tstz DESC) rn
                                  FROM epis_diagnosis ed
                                  JOIN diagnosis d
                                    ON d.id_diagnosis = ed.id_diagnosis
                                 WHERE ed.id_patient = i_patient
                                   AND ed.flg_status NOT IN
                                       (pk_alert_constant.g_epis_diag_flg_status_c,
                                        pk_alert_constant.g_epis_diag_flg_status_r)
                                   AND (ed.flg_type = pk_alert_constant.g_epis_diag_flg_type_d OR NOT EXISTS
                                        (SELECT 1
                                           FROM epis_diagnosis ed1
                                          WHERE ed1.id_patient = i_patient
                                            AND ed1.id_diagnosis = ed.id_diagnosis
                                            AND ed1.flg_type = pk_alert_constant.g_epis_diag_flg_type_d))) z
                         WHERE z.rn = 1)
                 ORDER BY desc_diagnosis);
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN t_tbl_core_domain();
    END get_reason_request_list;

    FUNCTION get_consult_instruction
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_opinion           IN opinion.id_opinion%TYPE,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch instructions for i_opinion: ' || i_opinion;
        BEGIN
            SELECT CASE
                        WHEN o.flg_priority IS NOT NULL THEN
                         pk_message.get_message(i_lang, 'OPINION_M021') || ': ' ||
                         pk_sysdomain.get_domain('OPINION.FLG_PRIORITY', o.flg_priority, i_lang) || '; '
                    END || pk_message.get_message(i_lang, 'OPINION_T026') || ': ' || o.desc_problem
              INTO o_task_instructions
              FROM opinion o
              LEFT JOIN speciality s
                ON s.id_speciality = o.id_speciality
             WHERE o.id_opinion = i_opinion;
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONSULT_INSTRUCTION',
                                              o_error);
            RETURN FALSE;
    END get_consult_instruction;

    FUNCTION get_consult_title
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_opinion   IN opinion.id_opinion%TYPE,
        o_task_desc OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Fetch alias_translation for i_opinion: ' || i_opinion;
        BEGIN
            SELECT CASE
                       WHEN o.id_speciality IS NOT NULL THEN
                        pk_translation.get_translation(i_lang, s.code_speciality)
                       ELSE
                        pk_translation.get_translation(i_lang, cs.code_clinical_service)
                   END
              INTO o_task_desc
              FROM opinion o
              LEFT JOIN speciality s
                ON s.id_speciality = o.id_speciality
              LEFT JOIN clinical_service cs
                ON cs.id_clinical_service = o.id_clinical_service
             WHERE o.id_opinion = i_opinion;
        
            RETURN TRUE;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN TRUE;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONSULT_TITLE',
                                              o_error);
            RETURN FALSE;
    END get_consult_title;

    PROCEDURE init_params_grid
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        l_patient patient.id_patient%TYPE;
        l_sys_cfg sys_config.value%TYPE;
    
        o_error t_error_out;
    
    BEGIN
    
        l_sys_cfg := pk_sysconfig.get_config('CANCEL_CONSULT_OTHER_PROF', l_prof);
    
        IF i_context_vals.count > 0
        THEN
            IF i_context_vals(1) = 0
            THEN
                l_patient := NULL;
            ELSE
                l_patient := i_context_vals(1);
            END IF;
        
        END IF;
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_id_prof', l_prof.id);
        pk_context_api.set_parameter('i_id_institution', l_prof.institution);
        pk_context_api.set_parameter('i_id_software', l_prof.software);
        pk_context_api.set_parameter('i_patient', l_patient);
    
        CASE i_name
            WHEN 'l_consult_req_prof_cancel' THEN
                o_vc2 := l_sys_cfg;
            WHEN 'l_lang' THEN
                o_vc2 := l_lang;
            ELSE
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_OPINION',
                                              i_function => 'INIT_PARAMS_GRID',
                                              o_error    => o_error);
    END init_params_grid;

    PROCEDURE init_params_epis_list
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
    
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_flg_type     VARCHAR2(2 CHAR);
        l_codification codification.id_codification%TYPE;
        l_analysis_req analysis_req.id_analysis_req%TYPE;
        l_harvest      harvest.id_harvest%TYPE;
        l_visit        visit.id_visit%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
        pk_context_api.set_parameter('l_patient', l_patient);
        pk_context_api.set_parameter('l_episode', l_episode);
    
        l_visit := pk_episode.get_id_visit(i_episode => l_episode);
        pk_context_api.set_parameter('l_visit', l_visit);
    
        IF i_context_vals.count > 0
        THEN
            pk_context_api.set_parameter('l_flg_type', nvl(i_context_vals(1), 'N'));
        ELSE
            pk_context_api.set_parameter('l_flg_type', 'N');
        END IF;
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_id := l_lang;
            ELSE
                NULL;
        END CASE;
    
    END init_params_epis_list;

    FUNCTION check_opinion_mandatory_field
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN opinion.id_opinion%TYPE,
        i_flg_process_tasks IN VARCHAR2,
        o_check             OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count PLS_INTEGER;
    
        CURSOR c_opinion IS
            SELECT COUNT(1)
              FROM opinion o
             WHERE o.id_opinion = i_task_request
               AND (o.id_speciality IS NOT NULL OR o.id_clinical_service IS NOT NULL)
               AND ((o.flg_priority IS NOT NULL AND i_flg_process_tasks = pk_alert_constant.g_yes) OR
                   i_flg_process_tasks = pk_alert_constant.g_no)
               AND (o.desc_problem IS NOT NULL);
    BEGIN
    
        OPEN c_opinion;
        FETCH c_opinion
            INTO l_count;
        CLOSE c_opinion;
    
        IF l_count > 0
        THEN
            o_check := pk_alert_constant.g_yes;
        ELSE
            o_check := pk_alert_constant.g_no;
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
                                              'CHECK_OPINION_MANDATORY_FIELD',
                                              o_error);
            RETURN FALSE;
    END check_opinion_mandatory_field;

BEGIN

    -- Log initialization.
    pk_alertlog.log_init(g_package_name);
END pk_opinion;
/
