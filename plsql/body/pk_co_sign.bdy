/*-- Last Change Revision: $Rev: 2047249 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-10-12 08:22:45 +0100 (qua, 12 out 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_co_sign AS

    FUNCTION get_prof_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_prof_list  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar os profissionais que podem efectuar co-sign 
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional 
                                 I_PROF - ID do profissional 
                                                      
                       Saida:   o_prof_list  - Listar os profissionais que podem efectuar co-sign
                                 O_ERROR - Erro 
          
          CRIA��O: SF 2007/08/24  
          NOTAS:
        *********************************************************************************/
    
        l_flg_type          category.flg_type%TYPE;
        l_show_current_prof sys_config.value%TYPE;
        l_curr_prof_default sys_config.value%TYPE;
    
        l_id_episode episode.id_episode%TYPE;
        l_prof_list  table_number;
    BEGIN
    
        g_error := 'GET PROF_CAT';
        SELECT c.flg_type
          INTO l_flg_type
          FROM prof_cat pc, category c
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution
           AND pc.id_category = c.id_category;
    
        g_error             := 'GET_CONFIG';
        l_show_current_prof := pk_sysconfig.get_config(i_code_cf => 'CO_SIGN_SHOW_CURRENT_PROFESSIONAL',
                                                       i_prof    => i_prof);
        l_curr_prof_default := nvl(pk_sysconfig.get_config(i_code_cf => 'CO_SIGN_CURRENT_PROF_DEFAULT',
                                                           i_prof    => i_prof),
                                   pk_alert_constant.g_yes);
    
        IF i_id_episode IS NOT NULL
        THEN
            l_id_episode := i_id_episode;
        ELSE
            l_id_episode := -1; -- In ORIS functions, ID_EPISODE is passed as NULL value. Use -1 for the ID.
        END IF;
        l_prof_list := tf_get_prof_co_sign(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET CURSOR O_prof_list';
        OPEN o_prof_list FOR
            WITH tbl_profs AS
             (SELECT /*+ MATERIALIZED */
              DISTINCT pi.id_professional, psi.id_software
                FROM prof_institution pi
                JOIN prof_soft_inst psi
                  ON psi.id_software = decode(l_flg_type,
                                              g_flg_type_tech,
                                              psi.id_software,
                                              'P',
                                              psi.id_software,
                                              pk_alert_constant.g_cat_type_nutritionist,
                                              psi.id_software,
                                              i_prof.software)
                 AND psi.id_professional = pi.id_professional
                 AND psi.id_institution = pi.id_institution
                JOIN prof_profile_template ppt
                  ON ppt.id_professional = pi.id_professional
                 AND ppt.id_software = psi.id_software
               WHERE pi.id_professional != i_prof.id
                 AND pi.id_institution = i_prof.institution
                 AND pi.flg_state = pk_backoffice.g_prof_flg_state_active
                 AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pi.id_professional, pi.id_institution) =
                     pk_alert_constant.g_yes
                 AND pi.id_prof_institution = (SELECT MAX(pi2.id_prof_institution)
                                                 FROM prof_institution pi2
                                                WHERE pi2.id_professional = pi.id_professional
                                                  AND pi2.id_institution = pi.id_institution)
                 AND ppt.id_profile_template IN (SELECT /*+OPT_ESTIMATE(TABLE t rows = 1)*/
                                                  column_value id_profile_template
                                                   FROM TABLE(l_prof_list) t))
            SELECT /*+ LEADING(pi cc) */
            DISTINCT pi.id_professional,
                     pk_prof_utils.get_name_signature(i_lang, i_prof, pi.id_professional) name_prof,
                     -- Jos� Brito 28/09/2009 ALERT-41064  Responsible physician is the default name in the co-sign list
                     decode((SELECT COUNT(*)
                              FROM epis_info ei
                             WHERE ei.id_episode = l_id_episode
                               AND ei.id_professional = pi.id_professional),
                            0, -- Does not exist a responsible physician or the current physician is not the responsible
                            flg_prof_default_n,
                            flg_prof_default_y) prof_default -- The default selected professional is the responsible physician
              FROM tbl_profs pi
            UNION ALL
            SELECT pi.id_professional,
                    pk_prof_utils.get_name_signature(i_lang, i_prof, pi.id_professional) name_prof,
                    decode((SELECT COUNT(*)
                              FROM epis_info ei
                             WHERE ei.id_episode = l_id_episode
                               AND ei.id_professional != pi.id_professional),
                            0, -- If there's no responsible physician, the default name is the current professional
                          l_curr_prof_default,
                          flg_prof_default_n) prof_default
              FROM prof_institution pi
             WHERE pi.id_professional = i_prof.id
             AND pi.id_institution = i_prof.institution
             AND l_show_current_prof = pk_alert_constant.g_yes -- Jos� Brito ALERT-41064
             AND pi.flg_state = pk_backoffice.g_prof_flg_state_active
             AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pi.id_professional, pi.id_institution) =
             pk_alert_constant.g_yes
             AND
             pi.id_prof_institution = (SELECT MAX(pi2.id_prof_institution)
                                         FROM prof_institution pi2
                                        WHERE pi2.id_professional = pi.id_professional
                                          AND pi2.id_institution = pi.id_institution)
             ORDER BY name_prof;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_prof_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_order_type IN order_type.id_order_type%TYPE,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar os profissionais que podem efectuar co-sign 
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional 
                                 I_PROF - ID do profissional 
                                                      
                       Saida:   o_prof_list  - Listar os profissionais que podem efectuar co-sign
                                 O_ERROR - Erro 
          
          CRIA��O: SF 2007/08/24  
          NOTAS:
        *********************************************************************************/
    
        l_flg_type          category.flg_type%TYPE;
        l_show_current_prof sys_config.value%TYPE;
        l_curr_prof_default sys_config.value%TYPE;
    
        l_id_episode     episode.id_episode%TYPE;
        l_flg_default_ob order_type.flg_default_ob%TYPE;
        l_flg_ordered_by order_type.flg_ordered_by%TYPE;
        l_prof_list      table_number;
    BEGIN
    
        IF i_id_order_type IS NULL
        THEN
            IF NOT get_prof_list(i_lang       => i_lang,
                                 i_prof       => i_prof,
                                 i_id_episode => i_id_episode,
                                 o_prof_list  => o_prof_list,
                                 o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
            g_error := 'get_order_type';
            BEGIN
                SELECT ot.flg_default_ob, ot.flg_ordered_by
                  INTO l_flg_default_ob, l_flg_ordered_by
                  FROM order_type ot
                 WHERE ot.id_order_type = i_id_order_type;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'order_type not found';
                    RAISE g_exception;
            END;
        
            g_error := 'GET PROF_CAT';
            SELECT c.flg_type
              INTO l_flg_type
              FROM prof_cat pc, category c
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution
               AND pc.id_category = c.id_category;
        
            g_error             := 'GET_CONFIG';
            l_show_current_prof := pk_sysconfig.get_config(i_code_cf => 'CO_SIGN_SHOW_CURRENT_PROFESSIONAL',
                                                           i_prof    => i_prof);
            l_curr_prof_default := nvl(pk_sysconfig.get_config(i_code_cf => 'CO_SIGN_CURRENT_PROF_DEFAULT',
                                                               i_prof    => i_prof),
                                       pk_alert_constant.g_yes);
        
            IF i_id_episode IS NOT NULL
            THEN
                l_id_episode := i_id_episode;
            ELSE
                l_id_episode := -1; -- In ORIS functions, ID_EPISODE is passed as NULL value. Use -1 for the ID.
            END IF;
        
            l_prof_list := tf_get_prof_co_sign(i_lang => i_lang, i_prof => i_prof);
            g_error     := 'GET CURSOR O_prof_list';
            OPEN o_prof_list FOR
            -- show professional list
                SELECT t.id_professional, t.name_prof, t.prof_default
                  FROM (WITH tbl_profs AS (SELECT /*+ MATERIALIZED */
                                           DISTINCT pi.id_professional, psi.id_software
                                             FROM prof_institution pi
                                             JOIN prof_soft_inst psi
                                               ON psi.id_software = decode(l_flg_type,
                                                                           g_flg_type_tech,
                                                                           psi.id_software,
                                                                           'P',
                                                                           psi.id_software,
                                                                           pk_alert_constant.g_cat_type_nutritionist,
                                                                           psi.id_software,
                                                                           i_prof.software)
                                              AND psi.id_professional = pi.id_professional
                                              AND psi.id_institution = pi.id_institution
                                             JOIN prof_profile_template ppt
                                               ON pi.id_professional = ppt.id_professional
                                              AND psi.id_software = ppt.id_software
                                            WHERE pi.id_professional != i_prof.id
                                              AND pi.id_institution = i_prof.institution
                                              AND pi.flg_state = pk_backoffice.g_prof_flg_state_active
                                              AND pk_prof_utils.is_internal_prof(i_lang,
                                                                                 i_prof,
                                                                                 pi.id_professional,
                                                                                 pi.id_institution) =
                                                  pk_alert_constant.g_yes
                                              AND pi.id_prof_institution =
                                                  (SELECT MAX(pi2.id_prof_institution)
                                                     FROM prof_institution pi2
                                                    WHERE pi2.id_professional = pi.id_professional
                                                      AND pi2.id_institution = pi.id_institution)
                                              AND instr(l_flg_ordered_by, g_flg_prof_list) <> 0
                                              AND ppt.id_profile_template IN
                                                  (SELECT /*+OPT_ESTIMATE(TABLE t rows = 1)*/
                                                    column_value id_profile_template
                                                     FROM TABLE(l_prof_list) t))
                           SELECT /*+ LEADING(pi cc) */
                           DISTINCT pi.id_professional,
                                    get_prof_order_desc(i_lang, i_prof, l_flg_ordered_by, pi.id_professional) name_prof,
                                    --pk_prof_utils.get_name_signature(i_lang, i_prof, pi.id_professional) name_prof,
                                    CASE
                                         WHEN l_flg_default_ob = g_flg_current_user
                                              AND l_curr_prof_default = pk_alert_constant.g_yes THEN
                                          pk_alert_constant.g_no
                                         WHEN (SELECT COUNT(*)
                                                 FROM epis_info ei
                                                WHERE ei.id_episode = l_id_episode
                                                  AND ei.id_professional = pi.id_professional) = 0 THEN
                                          pk_alert_constant.g_no -- Does not exist a responsible physician or the current physician is not the responsible
                                         WHEN instr(l_flg_ordered_by, g_flg_not_applicable) <> 0
                                              AND l_flg_default_ob = g_flg_not_applicable THEN
                                          pk_alert_constant.g_no
                                         WHEN instr(l_flg_ordered_by, g_flg_external) <> 0
                                              AND l_flg_default_ob = g_flg_external THEN
                                          pk_alert_constant.g_no
                                         ELSE
                                          pk_alert_constant.g_yes -- The default selected professional is the responsible physician
                                     END prof_default,
                                    
                                    1 order_by
                             FROM tbl_profs pi
                           UNION ALL
                           -- show current user
                           SELECT pi.id_professional,
                                  get_prof_order_desc(i_lang, i_prof, l_flg_ordered_by, pi.id_professional) name_prof,
                                  --pk_prof_utils.get_name_signature(i_lang, i_prof, pi.id_professional) name_prof,
                                  CASE
                                       WHEN l_flg_default_ob = g_flg_current_user THEN
                                        l_curr_prof_default
                                       ELSE
                                        pk_alert_constant.g_no
                                   END prof_default,
                                  1 order_by
                             FROM prof_institution pi
                            WHERE pi.id_professional = i_prof.id
                              AND pi.id_institution = i_prof.institution
                              AND l_show_current_prof = pk_alert_constant.g_yes -- Jos� Brito ALERT-41064
                              AND pi.flg_state = pk_backoffice.g_prof_flg_state_active
                              AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pi.id_professional, pi.id_institution) =
                                  pk_alert_constant.g_yes
                              AND pi.id_prof_institution =
                                  (SELECT MAX(pi2.id_prof_institution)
                                     FROM prof_institution pi2
                                    WHERE pi2.id_professional = pi.id_professional
                                      AND pi2.id_institution = pi.id_institution)
                              AND instr(l_flg_ordered_by, g_flg_current_user) <> 0
                           
                           UNION ALL
                           -- show Not applicable
                           SELECT NULL id_professional,
                                  get_prof_order_desc(i_lang, i_prof, l_flg_ordered_by, NULL) name_prof,
                                  --pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'SIGN_OFF_T014') name_prof,
                                  CASE
                                      WHEN l_flg_default_ob = g_flg_not_applicable THEN
                                       pk_alert_constant.g_yes
                                      ELSE
                                       pk_alert_constant.g_no
                                  END prof_default,
                                  0 order_by
                             FROM dual
                            WHERE instr(l_flg_ordered_by, g_flg_not_applicable) <> 0
                           UNION ALL
                           -- show external professional
                           SELECT NULL id_professional,
                                  get_prof_order_desc(i_lang, i_prof, l_flg_ordered_by, NULL) name_prof,
                                  --pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'SIGN_OFF_T034') name_prof,
                                  CASE
                                      WHEN l_flg_default_ob = g_flg_external THEN
                                       pk_alert_constant.g_yes
                                      ELSE
                                       pk_alert_constant.g_no
                                  END prof_default,
                                  0 order_by
                             FROM dual
                            WHERE instr(l_flg_ordered_by, g_flg_external) <> 0) t
                            ORDER BY order_by ASC, name_prof ASC;
        
        
        END IF;
    
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PROF_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_prof_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_prof_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_order_type    IN order_type.id_order_type%TYPE,
        i_internal_name    IN VARCHAR2,
        i_flg_show_default IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error            OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_flg_type          category.flg_type%TYPE;
        l_show_current_prof sys_config.value%TYPE;
        l_curr_prof_default sys_config.value%TYPE;
    
        l_id_episode     episode.id_episode%TYPE;
        l_flg_default_ob order_type.flg_default_ob%TYPE;
        l_flg_ordered_by order_type.flg_ordered_by%TYPE;
        l_prof_list      table_number;
    
        l_ret t_tbl_core_domain := t_tbl_core_domain();
    BEGIN
    
        g_error := 'get_order_type';
        BEGIN
            SELECT ot.flg_default_ob, ot.flg_ordered_by
              INTO l_flg_default_ob, l_flg_ordered_by
              FROM order_type ot
             WHERE ot.id_order_type = i_id_order_type;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'order_type not found';
                RAISE g_exception;
        END;
    
        g_error := 'GET PROF_CAT';
        SELECT c.flg_type
          INTO l_flg_type
          FROM prof_cat pc, category c
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution
           AND pc.id_category = c.id_category;
    
        g_error             := 'GET_CONFIG';
        l_show_current_prof := pk_sysconfig.get_config(i_code_cf => 'CO_SIGN_SHOW_CURRENT_PROFESSIONAL',
                                                       i_prof    => i_prof);
        l_curr_prof_default := nvl(pk_sysconfig.get_config(i_code_cf => 'CO_SIGN_CURRENT_PROF_DEFAULT',
                                                           i_prof    => i_prof),
                                   pk_alert_constant.g_yes);
    
        IF i_id_episode IS NOT NULL
        THEN
            l_id_episode := i_id_episode;
        ELSE
            l_id_episode := -1; -- In ORIS functions, ID_EPISODE is passed as NULL value. Use -1 for the ID.
        END IF;
    
        l_prof_list := tf_get_prof_co_sign(i_lang => i_lang, i_prof => i_prof);
        g_error     := 'GET L_RET';
    
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => name_prof,
                                 domain_value  => id_professional,
                                 order_rank    => rownum,
                                 img_name      => NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.name_prof, t.id_professional
                  FROM (WITH tbl_profs AS (SELECT /*+ MATERIALIZED */
                                           DISTINCT pi.id_professional, psi.id_software
                                             FROM prof_institution pi
                                             JOIN prof_soft_inst psi
                                               ON psi.id_software = decode(l_flg_type,
                                                                           g_flg_type_tech,
                                                                           psi.id_software,
                                                                           'P',
                                                                           psi.id_software,
                                                                           pk_alert_constant.g_cat_type_nutritionist,
                                                                           psi.id_software,
                                                                           i_prof.software)
                                              AND psi.id_professional = pi.id_professional
                                              AND psi.id_institution = pi.id_institution
                                             JOIN prof_profile_template ppt
                                               ON pi.id_professional = ppt.id_professional
                                              AND psi.id_software = ppt.id_software
                                            WHERE pi.id_professional != i_prof.id
                                              AND pi.id_institution = i_prof.institution
                                              AND pi.flg_state = pk_backoffice.g_prof_flg_state_active
                                              AND pk_prof_utils.is_internal_prof(i_lang,
                                                                                 i_prof,
                                                                                 pi.id_professional,
                                                                                 pi.id_institution) =
                                                  pk_alert_constant.g_yes
                                              AND pi.id_prof_institution =
                                                  (SELECT MAX(pi2.id_prof_institution)
                                                     FROM prof_institution pi2
                                                    WHERE pi2.id_professional = pi.id_professional
                                                      AND pi2.id_institution = pi.id_institution)
                                              AND instr(l_flg_ordered_by, g_flg_prof_list) <> 0
                                              AND ppt.id_profile_template IN
                                                  (SELECT /*+OPT_ESTIMATE(TABLE t rows = 1)*/
                                                    column_value id_profile_template
                                                     FROM TABLE(l_prof_list) t))
                           SELECT /*+ LEADING(pi cc) */
                           DISTINCT pi.id_professional,
                                    get_prof_order_desc(i_lang, i_prof, l_flg_ordered_by, pi.id_professional) name_prof,
                                    --pk_prof_utils.get_name_signature(i_lang, i_prof, pi.id_professional) name_prof,
                                    CASE
                                         WHEN l_flg_default_ob = g_flg_current_user
                                              AND l_curr_prof_default = pk_alert_constant.g_yes THEN
                                          pk_alert_constant.g_no
                                         WHEN (SELECT COUNT(*)
                                                 FROM epis_info ei
                                                WHERE ei.id_episode = l_id_episode
                                                  AND ei.id_professional = pi.id_professional) = 0 THEN
                                          pk_alert_constant.g_no -- Does not exist a responsible physician or the current physician is not the responsible
                                         WHEN instr(l_flg_ordered_by, g_flg_not_applicable) <> 0
                                              AND l_flg_default_ob = g_flg_not_applicable THEN
                                          pk_alert_constant.g_no
                                         WHEN instr(l_flg_ordered_by, g_flg_external) <> 0
                                              AND l_flg_default_ob = g_flg_external THEN
                                          pk_alert_constant.g_no
                                         ELSE
                                          pk_alert_constant.g_yes -- The default selected professional is the responsible physician
                                     END prof_default,
                                    
                                    1 order_by
                             FROM tbl_profs pi
                           UNION ALL
                           -- show current user
                           SELECT pi.id_professional,
                                  get_prof_order_desc(i_lang, i_prof, l_flg_ordered_by, pi.id_professional) name_prof,
                                  --pk_prof_utils.get_name_signature(i_lang, i_prof, pi.id_professional) name_prof,
                                  CASE
                                       WHEN l_flg_default_ob = g_flg_current_user THEN
                                        l_curr_prof_default
                                       ELSE
                                        pk_alert_constant.g_no
                                   END prof_default,
                                  1 order_by
                             FROM prof_institution pi
                            WHERE pi.id_professional = i_prof.id
                              AND pi.id_institution = i_prof.institution
                              AND l_show_current_prof = pk_alert_constant.g_yes -- Jos� Brito ALERT-41064
                              AND pi.flg_state = pk_backoffice.g_prof_flg_state_active
                              AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pi.id_professional, pi.id_institution) =
                                  pk_alert_constant.g_yes
                              AND pi.id_prof_institution =
                                  (SELECT MAX(pi2.id_prof_institution)
                                     FROM prof_institution pi2
                                    WHERE pi2.id_professional = pi.id_professional
                                      AND pi2.id_institution = pi.id_institution)
                              AND instr(l_flg_ordered_by, g_flg_current_user) <> 0
                           
                           UNION ALL
                           -- show Not applicable
                           SELECT -1 id_professional,
                                  get_prof_order_desc(i_lang, i_prof, l_flg_ordered_by, NULL) name_prof,
                                  --pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'SIGN_OFF_T014') name_prof,
                                  CASE
                                      WHEN l_flg_default_ob = g_flg_not_applicable THEN
                                       pk_alert_constant.g_yes
                                      ELSE
                                       pk_alert_constant.g_no
                                  END prof_default,
                                  0 order_by
                             FROM dual
                            WHERE instr(l_flg_ordered_by, g_flg_not_applicable) <> 0
                           UNION ALL
                           -- show external professional
                           SELECT -1 id_professional,
                                  get_prof_order_desc(i_lang, i_prof, l_flg_ordered_by, NULL) name_prof,
                                  --pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'SIGN_OFF_T034') name_prof,
                                  CASE
                                      WHEN l_flg_default_ob = g_flg_external THEN
                                       pk_alert_constant.g_yes
                                      ELSE
                                       pk_alert_constant.g_no
                                  END prof_default,
                                  0 order_by
                             FROM dual
                            WHERE instr(l_flg_ordered_by, g_flg_external) <> 0) t
                            WHERE (i_flg_show_default = pk_alert_constant.g_yes AND t.prof_default = i_flg_show_default)
                               OR i_flg_show_default = pk_alert_constant.g_no
                            ORDER BY order_by ASC, name_prof ASC
                );
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PROF_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
    END;

    /**
    * Returns description of professional that requested the order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identifier and its context (institution and software)    
    * @param   i_flg_ordered_by     Ordered by list
    * @param   i_id_prof_order      Professional identifier that requested the order
    *
    * @return  varchar2             Professional description that requested the order
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   28-04-2014
    */
    FUNCTION get_prof_order_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_ordered_by IN order_type.flg_ordered_by%TYPE,
        i_id_prof_order  IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_params VARCHAR2(1000 CHAR);
        l_result VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_flg_ordered_by=' || i_flg_ordered_by ||
                    ' i_id_prof_order=' || i_id_prof_order;
        g_error  := 'Init prof_order_desc / ' || l_params;
        --pk_alertlog.log_init(g_error);
    
        IF i_flg_ordered_by IS NOT NULL
        THEN
        
            g_error := 'i_id_prof_order / ' || l_params;
            IF i_id_prof_order IS NOT NULL
            THEN
                l_result := pk_prof_utils.get_name_signature(i_lang, i_prof, i_id_prof_order);
            ELSE
            
                g_error := 'CASE i_flg_ordered_by / ' || l_params;
                CASE
                    WHEN instr(i_flg_ordered_by, g_flg_not_applicable) <> 0 THEN
                        l_result := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'SIGN_OFF_T014');
                    WHEN instr(i_flg_ordered_by, g_flg_external) <> 0 THEN
                        l_result := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'SIGN_OFF_T034');
                    ELSE
                        l_result := pk_prof_utils.get_name_signature(i_lang, i_prof, i_id_prof_order);
                END CASE;
            END IF;
        
        END IF;
    
        RETURN l_result;
    END get_prof_order_desc;

    /**
    * Returns description of professional that requested the order
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identifier and its context (institution and software)    
    * @param   i_id_order_type      Order type identifier
    * @param   i_id_prof_order      Professional identifier that requested the order
    *
    * @return  varchar2             Professional description that requested the order
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   28-04-2014
    */
    FUNCTION get_prof_order_desc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_order_type IN order_type.id_order_type%TYPE,
        i_id_prof_order IN professional.id_professional%TYPE
    ) RETURN VARCHAR2 IS
        l_params         VARCHAR2(1000 CHAR);
        l_flg_ordered_by order_type.flg_ordered_by%TYPE;
        l_result         VARCHAR2(1000 CHAR);
    BEGIN
        l_params := 'i_prof=' || pk_utils.to_string(i_prof) || ' i_id_order_type=' || i_id_order_type ||
                    ' i_id_prof_order=' || i_id_prof_order;
        g_error  := 'Init prof_order_desc / ' || l_params;
        --pk_alertlog.log_init(g_error);
    
        IF i_id_order_type IS NOT NULL
        THEN
        
            g_error := 'get_order_type / ' || l_params;
            BEGIN
                SELECT ot.flg_ordered_by
                  INTO l_flg_ordered_by
                  FROM order_type ot
                 WHERE ot.id_order_type = i_id_order_type;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'order_type not found / ' || l_params;
                    RAISE g_exception;
            END;
        
            g_error  := 'Call get_prof_order_desc / ' || l_params;
            l_result := get_prof_order_desc(i_lang           => i_lang,
                                            i_prof           => i_prof,
                                            i_flg_ordered_by => l_flg_ordered_by,
                                            i_id_prof_order  => i_id_prof_order);
        
        END IF;
    
        RETURN l_result;
    END get_prof_order_desc;

    FUNCTION get_order_type
    (
        i_lang       IN language.id_language%TYPE,
        o_order_type OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar todos os tipos de ordens para co_sign 
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional 
                                                      
                        Saida: o_order_type  - Listar todos os tipos de ordens para co_sign     
                                 O_ERROR - Erro 
          
          CRIA��O: SF 2007/08/24 
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR o_order_type';
        OPEN o_order_type FOR
            SELECT id_order_type, pk_translation.get_translation(i_lang, code_order_type) desc_order_type, ot.rank rank
              FROM order_type ot
            UNION ALL
            SELECT -1 id_order_type, pk_message.get_message(i_lang, 'COMMON_M036') desc_order_type, -1 rank
              FROM dual
             ORDER BY rank ASC;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_ORDER_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_order_type);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_date_time_stamp_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_flg_show OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /********************************************************************************************
        * validar se o perfil tem ou n�o permiss�o registar date /time stamp nas requisi��es
        
        * @param i_lang                   The language ID
        * @param o_prof                   Cursor containing the professional list 
        
        * @param i_flg_type               Devolve Y ou N                                      
        * @param o_error                  Error message
                            
        * @return                         true or false on success or error
        * 
        * @author                         S�lvia Freitas
        * @since                          2007/08/30
        **********************************************************************************************/
        l_date_time_stamp_req VARCHAR2(200);
        l_profile             VARCHAR2(200);
        --
        --  
        CURSOR c_profile IS
            SELECT ppt.id_profile_template
              FROM prof_profile_template ppt, profile_template pt
             WHERE ppt.id_profile_template = pt.id_profile_template
               AND ppt.id_professional = i_prof.id
               AND ppt.id_institution = i_prof.institution
               AND ppt.id_software = i_prof.software
               AND pt.id_software = i_prof.software;
        --    
    BEGIN
        g_error               := 'GET CONFIG DATE_TIME_STAMP_REQ';
        l_date_time_stamp_req := pk_sysconfig.get_config('DATE_TIME_STAMP_REQ', i_prof);
        --
        -- LO: 2007-11-20
        -- Este mecanismo apenas funciona para os casos em que existe um �nico perfil parametrizado para um
        -- determinado software / institui��o; � devolvido o primeiro perfil encontrado
        g_error := 'OPEN C_PROFILE';
        OPEN c_profile;
        FETCH c_profile
            INTO l_profile;
        CLOSE c_profile;
        --
        l_profile := '|' || l_profile || '|';
        IF instr(l_date_time_stamp_req, l_profile) > 0
        THEN
            o_flg_show := g_available;
        ELSE
            o_flg_show := g_not_available;
        END IF;
        --
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_DATE_TIME_STAMP_REQ',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /**
    *
    * Function to insert or delete co-sign alerts
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_id_episode          Episode ID
    * @param i_id_episode_new      New Episode ID (applicable in match case) 
    * @param i_id_req_det          Detail ID (eg. id_co_sign_task)
    * @param i_dt_req_det          Record date
    * @param i_type                Operation type A - add, R- remove        
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Jos� Silva
    * @since                       2008/05/22
    * @version                     1.0
    *
    */

    FUNCTION set_co_sign_alerts
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN sys_alert_event.id_episode%TYPE,
        i_id_episode_new  IN sys_alert_event.id_episode%TYPE DEFAULT NULL,
        i_id_req_det      IN sys_alert_event.id_record%TYPE,
        i_dt_req_det      IN sys_alert_event.dt_record%TYPE,
        i_id_professional IN sys_alert_event.id_professional%TYPE,
        i_type            IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_alert_co_sign CONSTANT sys_alert.id_sys_alert%TYPE := 45;
    
        l_count              NUMBER(6);
        l_id_req_det         sys_alert_event.id_record%TYPE;
        l_id_sys_alert_event sys_alert_event.id_sys_alert_event%TYPE;
        l_exceptions EXCEPTION;
    
        tbl_id_req_det         table_number;
        tbl_id_sys_alert_event table_number;
    BEGIN
        pk_alertlog.log_debug('i_prof:' || i_prof.id || ' i_episode:' || i_episode || ' i_id_professional:' ||
                              i_id_professional || 'i_type :' || i_type);
        IF i_type = g_type_add
        THEN
            -- Jos� Brito 08/09/2008 Se j� existir um alerta de co-sign para 
            -- o profissional de destino, n�o cria um novo alerta.
            g_error := 'GET CO-SIGN ALERTS COUNT';
            SELECT COUNT(*)
              INTO l_count
              FROM sys_alert_event s
             WHERE s.id_sys_alert = l_alert_co_sign
               AND s.id_episode = i_episode
               AND s.id_professional = i_id_professional
               AND s.id_institution = i_prof.institution;
        
            -- Se n�o existirem alertas de co-sign, � gerado o alerta
            IF l_count = 0
            THEN
                g_error := 'INSERT INTO SYS_ALERT_EVENT';
                IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_sys_alert           => l_alert_co_sign,
                                                        i_id_episode          => i_episode,
                                                        i_id_record           => i_id_req_det,
                                                        i_dt_record           => i_dt_req_det,
                                                        i_id_professional     => i_id_professional,
                                                        i_id_room             => NULL,
                                                        i_id_clinical_service => NULL,
                                                        i_flg_type_dest       => NULL,
                                                        i_replace1            => NULL,
                                                        o_error               => o_error)
                THEN
                    RAISE l_exceptions;
                END IF;
            
            END IF;
        
        ELSIF i_type = g_type_rem
        THEN
        
            -- Jos� Brito 08/09/2008 Se j� n�o existirem tarefas na CO_SIGN,
            -- o alerta pode ser removido.
            g_error := 'GET CO_SIGN COUNT';
            SELECT COUNT(*)
              INTO l_count
              FROM co_sign cs
             WHERE cs.id_episode = i_episode
               AND cs.id_prof_ordered_by = i_id_professional
               AND cs.flg_status = pk_co_sign.g_cosign_flg_status_p;
            pk_alertlog.log_debug('l_count:' || l_count);
        
            IF l_count = 0
            THEN
            
                -- Obt�m o registo a eliminar. Como s� foi feito um registo na SYS_ALERT_EVENT
                -- s� dever� retornar um registo.
                g_error := 'GET SYS_ALERT_EVENT.ID_RECORD';
                SELECT s.id_record, s.id_sys_alert_event
                  BULK COLLECT
                  INTO tbl_id_req_det, tbl_id_sys_alert_event
                  FROM sys_alert_event s
                 WHERE s.id_sys_alert = l_alert_co_sign
                   AND s.id_episode = i_episode
                   AND s.id_professional = i_id_professional
                   AND s.id_institution = i_prof.institution;
            
                -- Cleans all alerts, even duplicated ones if need be            
                <<lup_thru_alerts_created>>
                FOR i IN 1 .. tbl_id_req_det.count
                LOOP
                
                    l_id_req_det         := tbl_id_req_det(i);
                    l_id_sys_alert_event := tbl_id_sys_alert_event(i);
                
                    pk_alertlog.log_debug('l_id_req_det:' || l_id_req_det || ' l_id_sys_alert_event:' ||
                                          l_id_sys_alert_event);
                    l_sys_alert_event.id_sys_alert       := l_alert_co_sign;
                    l_sys_alert_event.id_episode         := i_episode;
                    l_sys_alert_event.id_record          := l_id_req_det; --i_id_req_det;
                    l_sys_alert_event.id_sys_alert_event := l_id_sys_alert_event;
                
                    g_error := 'DELETE SYS_ALERT_EVENT';
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RAISE l_exceptions;
                    END IF;
                
                END LOOP lup_thru_alerts_created;
            
            END IF;
        ELSIF i_type = g_type_match
        THEN
            g_error := 'UPDATE SYS_ALERT_EVENT';
            IF NOT pk_alerts.match_sys_alert_event(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_id_episode     => i_episode,
                                                   i_id_episode_new => i_id_episode_new,
                                                   i_id_sys_alert   => l_alert_co_sign,
                                                   o_error          => o_error)
            THEN
                RAISE l_exceptions;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'SET_CO_SIGN_ALERTS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_co_sign_alerts;

    /********************************************************************************************
    * Sets the co_sign task
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_prof_dest                  destination professional    
    * @param i_episode                    episode ID
    * @param i_id_task                    task ID
    * @param i_flg_type                   task type: (A) Analysis, (D) Drugs and other types of medication, (E) Exams, (I) Interventions, (M) Monitorizations, (CO) Communication orders
    * @param i_dt_reg                     task request date   
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos� Silva
    * @version                            1.0   
    * @since                              21-05-2008
    **********************************************************************************************/
    FUNCTION set_co_sign_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_dest     IN professional.id_professional%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_task       IN co_sign_task.id_task%TYPE,
        i_flg_type      IN co_sign_task.flg_type%TYPE,
        i_dt_reg        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_order_type IN order_type.id_order_type%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_co_sign_task co_sign_task.id_co_sign_task%TYPE;
        l_prof_cat        category.flg_type%TYPE;
        l_flg_co_sign_wf  order_type.flg_co_sign_wf%TYPE;
        l_exceptions EXCEPTION;
    BEGIN
    
        g_error := 'get order type';
        BEGIN
            SELECT get_flg_co_sign_wf(i_lang, i_prof, ot.id_order_type, ot.flg_co_sign_wf)
              INTO l_flg_co_sign_wf
              FROM order_type ot
             WHERE ot.id_order_type = i_id_order_type;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_co_sign_wf := pk_alert_constant.g_yes;
        END;
    
        -- Get professional category
        SELECT c.flg_type
          INTO l_prof_cat
          FROM prof_cat p, category c
         WHERE p.id_category = c.id_category
           AND p.id_professional = i_prof.id
           AND p.id_institution = i_prof.institution;
    
        -- Co-sign task must be registered only if professional isn't a physician and..
        -- .. if target professional isn't the same who ordered the task.
        IF i_prof.id <> i_prof_dest
           AND l_flg_co_sign_wf = pk_alert_constant.g_yes
        THEN
        
            g_error           := 'GET seq_co_sign_task NEXTVAL';
            l_id_co_sign_task := seq_co_sign_task.nextval;
        
            g_error := 'INSERT INTO CO SIGN TASK';
            INSERT INTO co_sign_task
                (id_co_sign_task, id_task, flg_type, id_prof_order, id_prof_dest, id_episode)
            VALUES
                (l_id_co_sign_task, i_id_task, i_flg_type, i_prof.id, i_prof_dest, i_episode);
        
            g_error := 'INSERT CO_SIGN ALERT';
            IF NOT set_co_sign_alerts(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_episode         => i_episode,
                                      i_id_req_det      => l_id_co_sign_task,
                                      i_dt_req_det      => i_dt_reg,
                                      i_id_professional => i_prof_dest,
                                      i_type            => g_type_add,
                                      o_error           => o_error)
            THEN
                RAISE l_exceptions;
            END IF;
        
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'SET_CO_SIGN_ALERTS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_co_sign_task;

    /********************************************************************************************
    * Removes the co_sign task
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_episode                    episode ID    
    * @param i_id_task                    task ID
    * @param i_flg_type                   task type: (A) Analysis, (D) Drugs and other types of medication, (E) Exams, (I) Interventions, (M) Monitorizations, (OP) Opinions, (CO) Communication orders
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Jos� Silva
    * @version                            1.0   
    * @since                              21-05-2008
    **********************************************************************************************/
    FUNCTION remove_co_sign_task
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_id_task  IN co_sign_task.id_task%TYPE,
        i_flg_type IN co_sign_task.flg_type%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_co_sign_task co_sign_task.id_co_sign_task%TYPE;
        l_id_prof_dest    co_sign_task.id_prof_dest%TYPE;
    
        l_exceptions EXCEPTION;
    BEGIN
    
        BEGIN
            g_error := 'GET CO_SIGN_TASK PK';
            SELECT ct.id_co_sign_task, ct.id_prof_dest
              INTO l_id_co_sign_task, l_id_prof_dest
              FROM co_sign_task ct
             WHERE ct.id_task = i_id_task
               AND ct.flg_type = i_flg_type;
        EXCEPTION
            WHEN no_data_found THEN
                -- The function also returns TRUE if there are no results because Co-Sign
                -- might not be available for the current professional.
                -- Therefore, there will be no records on CO_SIGN_TASK for this task.
                RETURN TRUE;
        END;
    
        g_error := 'DELETE CO SIGN TASK';
        DELETE FROM co_sign_task ct
         WHERE ct.id_task = i_id_task
           AND ct.flg_type = i_flg_type;
    
        g_error := 'CALL TO SET_CO_SIGN_ALERTS';
        /*IF NOT
            set_co_sign_alerts(i_lang, i_prof, i_episode, l_id_co_sign_task, NULL, l_id_prof_dest, g_type_rem, o_error)
        THEN
            RAISE l_exceptions;
        END IF;*/
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'REMOVE_CO_SIGN_TASK',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END remove_co_sign_task;

    FUNCTION get_order_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_order_type OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Listar todos os tipos de ordens para co_sign 
           PARAMETROS:  Entrada: I_LANG - L�ngua registada como prefer�ncia do profissional 
                                                        
                        Saida: o_order_type  - Listar todos os tipos de ordens para co_sign     
                                 O_ERROR - Erro 
            
          CRIA��O: SF 2007/08/24 
          NOTAS:
        *********************************************************************************/
        l_external_ordered_by sys_config.value%TYPE;
    BEGIN
    
        l_external_ordered_by := nvl(pk_sysconfig.get_config(i_code_cf => 'EXTERNAL_ORDERED_BY_MANDATORY',
                                                             i_prof    => i_prof),
                                     pk_alert_constant.g_yes);
    
        g_error := 'GET CURSOR o_order_type';
        OPEN o_order_type FOR
            SELECT t.id_order_type,
                   pk_translation.get_translation(i_lang, t.code_order_type) desc_order_type,
                   t.icon_name icon,
                   t.rank,
                   CASE
                        WHEN t.id_order_type = g_id_order_type_external THEN
                         l_external_ordered_by
                        ELSE
                         pk_alert_constant.g_yes
                    END flg_mandatory_ob
              FROM (SELECT ot.id_order_type,
                           ot.code_order_type,
                           ot.icon_name,
                           ot.rank,
                           otsi.flg_available,
                           row_number() over(PARTITION BY ot.id_order_type ORDER BY id_institution DESC, id_software DESC) rn
                      FROM order_type ot
                      JOIN order_type_soft_inst otsi
                        ON ot.id_order_type = otsi.id_order_type
                     WHERE id_institution IN (i_prof.institution, 0)
                       AND id_software IN (i_prof.software, 0)
                       AND rownum > 0) t
             WHERE flg_available = 'Y'
               AND rn = 1
             ORDER BY rank ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_ORDER_TYPE',
                                              o_error);
            pk_types.open_my_cursor(o_order_type);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_order_type;

    FUNCTION get_order_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain IS
    
        l_ret t_tbl_core_domain := t_tbl_core_domain();
    
    BEGIN
        g_error := 'get l_ret cursor';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        SELECT t_row_core_domain(internal_name => NULL,
                                 desc_domain   => t.desc_order_type,
                                 domain_value  => t.id_order_type,
                                 order_rank    => t.rank,
                                 img_name      => 'icon-' || t.icon)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.id_order_type,
                       pk_translation.get_translation(i_lang, t.code_order_type) desc_order_type,
                       t.icon_name icon,
                       t.rank
                  FROM (SELECT ot.id_order_type,
                               ot.code_order_type,
                               ot.icon_name,
                               ot.rank,
                               otsi.flg_available,
                               row_number() over(PARTITION BY ot.id_order_type ORDER BY id_institution DESC, id_software DESC) rn
                          FROM order_type ot
                          JOIN order_type_soft_inst otsi
                            ON ot.id_order_type = otsi.id_order_type
                         WHERE id_institution IN (i_prof.institution, 0)
                           AND id_software IN (i_prof.software, 0)
                           AND rownum > 0) t
                 WHERE flg_available = pk_alert_constant.g_yes
                   AND rn = 1
                 ORDER BY rank ASC) t;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_ORDER_TYPE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN l_ret;
    END get_order_type;

    FUNCTION get_flg_co_sign_wf
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_order_type  order_type.id_order_type%TYPE,
        i_flg_co_sign_wf order_type.flg_co_sign_wf%TYPE
    ) RETURN VARCHAR2 IS
        l_return                 VARCHAR2(1 CHAR);
        l_stand_order_co_sign_wf sys_config.value%TYPE := pk_sysconfig.get_config('STAND_ORDER_CO_SIGN_WF', i_prof);
    BEGIN
    
        CASE
            WHEN i_id_order_type = g_id_order_type_stand_ord THEN
                l_return := nvl(l_stand_order_co_sign_wf, pk_alert_constant.g_yes);
            ELSE
                l_return := nvl(i_flg_co_sign_wf, pk_alert_constant.g_yes);
        END CASE;
    
        RETURN l_return;
    
    END;

    /********************************************************************************************
    * Gets co sign task type functions result
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_task                   Task transactional id
    * @param i_func_name              Function to be executed
    *                        
    * @return                         Returns i_func_name description
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task            IN co_sign_task.id_task%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE,
        i_func_name       IN VARCHAR2
    ) RETURN CLOB IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_DESCRIPTION';
        --
        l_sql         CLOB;
        l_description CLOB;
    BEGIN
        l_sql := 'BEGIN :desc := ' || i_func_name || '; END;';
    
        g_error := 'EXECUTE l_sql: ' || l_sql;
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        EXECUTE IMMEDIATE l_sql
            USING OUT l_description, --DESCRIPTION
        i_lang, -- :LANG
        i_prof.id, -- :PROFESSIONAL
        i_prof.institution, -- :INSTITUTION
        i_prof.software, -- :SOFTWARE
        i_task, i_id_co_sign_hist;
    
        RETURN l_description;
        /*
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
                */
    END get_description;

    /********************************************************************************************
    * Gets co sign task type functions result
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_task                   Task transactional id
    * @param i_func_name              Function to be executed
    *                        
    * @return                         Returns i_func_name date
    * 
    * @author                         Nuno Alves
    * @version                        2.6.5
    * @since                          2015/10/13
    **********************************************************************************************/
    FUNCTION get_task_exec_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task            IN co_sign.id_task%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE,
        i_func_name       IN VARCHAR2
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_DESCRIPTION';
        --
        l_sql            CLOB;
        l_task_exec_date TIMESTAMP(6) WITH LOCAL TIME ZONE;
    BEGIN
        IF i_func_name IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        l_sql := 'BEGIN :date := ' || i_func_name || '; END;';
    
        g_error := 'EXECUTE l_sql: ' || l_sql;
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        EXECUTE IMMEDIATE l_sql
            USING OUT l_task_exec_date, --DESCRIPTION
        i_lang, -- :LANG
        i_prof.id, -- :PROFESSIONAL
        i_prof.institution, -- :INSTITUTION
        i_prof.software, -- :SOFTWARE
        i_task, i_id_co_sign_hist;
    
        RETURN l_task_exec_date;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_task_exec_date;

    /********************************************************************************************
    * Gets action description from a co-sign task
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign             Co-sign task identifier
    * @param i_func_name              Function to be executed
    *                        
    * @return                         Returns i_func_name description
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_action_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_task            IN co_sign_task.id_task%TYPE,
        i_id_action       IN co_sign.id_action%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE,
        i_func_name       IN VARCHAR2
    ) RETURN CLOB IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_ACTION_DESCRIPTION';
        --
        l_sql         CLOB;
        l_description CLOB;
    BEGIN
        l_sql := 'BEGIN :desc := ' || i_func_name || '; END;';
    
        g_error := 'EXECUTE l_sql: ' || l_sql;
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        EXECUTE IMMEDIATE l_sql
            USING OUT l_description, --DESCRIPTION
        i_lang, -- :LANG
        i_prof.id, -- :PROFESSIONAL
        i_prof.institution, -- :INSTITUTION
        i_prof.software, -- :SOFTWARE
        i_task, i_id_action, i_id_co_sign_hist;
    
        RETURN l_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_action_description;

    /********************************************************************************************
    * Returns de id_action based on the default co-sign actions  
    *
    * @param i_cosign_def_action_type  The default co_sign action (order or cancel)
    *
    * @param o_error                   Error message       
    *                    
    * @return                         id_action
    * 
    * @author                         Nuno Alves
    * @since                          2015/04/10
    **********************************************************************************************/
    FUNCTION get_id_action
    (
        i_cosign_def_action_type IN action.internal_name%TYPE,
        i_action                 IN action.id_action%TYPE
    ) RETURN action.id_action%TYPE IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_ID_ACTION';
        --
        l_action action.id_action%TYPE;
    BEGIN
        g_error := 'INPUT PARAMETERS VALIDATION';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        IF i_action IS NULL
           AND i_cosign_def_action_type IS NULL
        THEN
            raise_application_error(-20001, 'PLEASE PROVIDE A VALUE FOR I_ACTION OR I_COSIGN_DEF_ACTION_TYPE');
        ELSIF i_action IS NULL
              AND i_cosign_def_action_type NOT IN
              (pk_co_sign.g_cosign_action_def_add, pk_co_sign.g_cosign_action_def_cancel)
        THEN
            raise_application_error(-20002,
                                    'INVALID I_COSIGN_DEF_ACTION_TYPE. VALID VALUES ARE: "' ||
                                    pk_co_sign.g_cosign_action_def_add || '", "' ||
                                    pk_co_sign.g_cosign_action_def_cancel || '"');
        END IF;
    
        g_error := 'GET/SET ID_ACTION';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        IF i_action IS NOT NULL
        THEN
            l_action := i_action;
        ELSE
            SELECT a.id_action
              INTO l_action
              FROM action a
             WHERE a.subject = pk_co_sign.g_cosign_action_subject
               AND a.internal_name = i_cosign_def_action_type;
        END IF;
    
        RETURN l_action;
    END get_id_action;

    ---
    FUNCTION get_id_task_type_action
    (
        i_task_type IN task_type_actions.id_task_type%TYPE,
        i_action    IN task_type_actions.id_action%TYPE
    ) RETURN task_type_actions.id_task_type_action%TYPE IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_ID_TASK_TYPE_ACTION';
        --
        l_id_task_type_action action.id_action%TYPE;
    BEGIN
        g_error := 'QUERY TASK_TYPE_ACTIONS TABLE';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        SELECT tta.id_task_type_action
          INTO l_id_task_type_action
          FROM task_type_actions tta
         WHERE tta.id_task_type = i_task_type
           AND tta.id_action = i_action;
    
        RETURN l_id_task_type_action;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alertlog.log_error(text            => 'TASK_TYPE: ' || i_task_type || '; ID_ACTION: ' || i_action ||
                                                     ' ARE NOT CONFIGURED',
                                  sub_object_name => l_func_name);
            RAISE;
    END get_id_task_type_action;

    ---
    FUNCTION get_id_co_sign_from_hist(i_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE)
        RETURN co_sign_hist.id_co_sign%TYPE IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_ID_CO_SIGN_FROM_HIST';
        --
        l_id_co_sign co_sign_hist.id_co_sign%TYPE;
    BEGIN
        g_error := 'QUERY CO_SIGN_HIST TABLE';
        --pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        SELECT csh.id_co_sign
          INTO l_id_co_sign
          FROM co_sign_hist csh
         WHERE csh.id_co_sign_hist = i_id_co_sign_hist;
    
        RETURN l_id_co_sign;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_id_co_sign_from_hist;
    ---

    /**
    * Insert a co-sign task_type action.
    *
    * @param i_task_type_action         Task type action
    * @param i_task_type                Task type id
    * @param i_cosign_def_action_type   Co-sign default action
    * @param i_action                   Action id
    * @param i_func_task_description    Function that returns the description of the order/task
    * @param i_func_instructions        Function that returns the instructions of the order/task
    *
    * @value   i_cosign_def_action_type  NEEDS_COSIGN_ORDER  - Add co-sign task
    *                                    NEEDS_COSIGN_CANCEL - Cancel co-sign task
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    01-12-2014
    */
    PROCEDURE insert_into_task_type_actions
    (
        i_task_type_action       IN task_type_actions.id_task_type_action%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT NULL,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        i_func_task_description  IN task_type_actions.func_task_description%TYPE DEFAULT NULL,
        i_func_instructions      IN task_type_actions.func_instructions%TYPE DEFAULT NULL,
        i_func_task_action_desc  IN task_type_actions.func_task_action_desc%TYPE DEFAULT NULL,
        i_func_task_exec_date    IN task_type_actions.func_task_exec_date%TYPE DEFAULT NULL
    ) IS
        l_proc_name CONSTANT VARCHAR2(32) := 'INSERT_INTO_TASK_TYPE_ACTIONS';
        --
        l_action                action.id_action%TYPE;
        l_func_task_description task_type_actions.func_task_description%TYPE;
        l_func_instructions     task_type_actions.func_instructions%TYPE;
        l_func_task_action_desc task_type_actions.func_task_action_desc%TYPE;
    BEGIN
        g_error := 'CALL GET_ID_ACTION';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        l_action := get_id_action(i_cosign_def_action_type => i_cosign_def_action_type, i_action => i_action);
    
        g_error := 'VALIDATE API''s';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        IF i_func_task_description IS NULL
           OR i_func_instructions IS NULL
           OR i_func_task_action_desc IS NULL
        THEN
            raise_application_error(-20007,
                                    'I_FUNC_TASK_DESCRIPTION, I_FUNC_INSTRUCTIONS AND I_FUNC_TASK_ACTION_DESC ARE MANDATORY FIELDS');
        ELSE
            l_func_task_description := i_func_task_description;
            l_func_instructions     := i_func_instructions;
            l_func_task_action_desc := i_func_task_action_desc;
        END IF;
    
        BEGIN
            g_error := 'INSERT TASK_TYPE_ACTION';
            pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
            INSERT INTO task_type_actions
                (id_task_type_action,
                 id_task_type,
                 id_action,
                 func_task_description,
                 func_instructions,
                 func_task_action_desc,
                 func_task_exec_date)
            VALUES
                (i_task_type_action,
                 i_task_type,
                 l_action,
                 l_func_task_description,
                 l_func_instructions,
                 l_func_task_action_desc,
                 i_func_task_exec_date);
        EXCEPTION
            WHEN dup_val_on_index THEN
                g_error := 'UPDATE TASK_TYPE_ACTION';
                pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
                UPDATE task_type_actions tta
                   SET tta.id_task_type = i_task_type, tta.id_action = l_action
                 WHERE tta.id_task_type_action = i_task_type_action;
        END;
    END insert_into_task_type_actions;

    /**
    * Insert a co-sign task_type action.
    *
    * @param i_id_config                Configuration identifier
    * @param i_id_inst_owner            Instituiton owner of the record (0-ALERT)
    * @param i_task_type                Task type id
    * @param i_cosign_def_action_type   Co-sign default action
    * @param i_action                   Action id
    * @param i_flg_needs_cosign         Needs cosign to order/cancel tasks? Y - yes; N - otherwise
    * @param i_flg_has_cosign           Can validate co-signed tasks? Y - yes; N - otherwise
    * @param i_flg_add_remove           Action id
    *
    * @value   i_cosign_def_action_type  ADD        - Add co-sign task
    *                                    CANCEL     - Cancel co-sign task
    *                                    HAS_COSIGN - Has cosign action
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    01-12-2014
    */
    PROCEDURE insert_into_config_table
    (
        i_id_config              IN pk_core_config.t_low_char,
        i_id_inst_owner          IN pk_core_config.t_big_num DEFAULT pk_core_config.k_zero_value,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        i_flg_needs_cosign       IN pk_core_config.t_med_char, --FIELD_01
        i_flg_has_cosign         IN pk_core_config.t_med_char, --FIELD_02
        i_flg_add_remove         IN pk_core_config.t_flg_char DEFAULT pk_core_config.k_flg_type_add
    ) IS
        l_proc_name CONSTANT VARCHAR2(32) := 'INSERT_INTO_CONFIG_TABLE';
        --
        l_action           action.id_action%TYPE;
        l_task_type_action task_type_actions.id_task_type_action%TYPE;
    BEGIN
        g_error := 'VALIDATE CONFIGURATION DATA';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        IF i_flg_needs_cosign IS NOT NULL
           AND i_flg_needs_cosign NOT IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
        THEN
            raise_application_error(-20003,
                                    'I_FLG_NEEDS_COSIGN POSSIBLE VALUES ARE: "' || pk_alert_constant.g_yes || '", "' ||
                                    pk_alert_constant.g_no || '"');
        END IF;
    
        IF i_flg_has_cosign IS NOT NULL
           AND i_flg_has_cosign NOT IN (pk_alert_constant.g_yes, pk_alert_constant.g_no)
        THEN
            raise_application_error(-20004,
                                    'I_FLG_HAS_COSIGN POSSIBLE VALUES ARE: "' || pk_alert_constant.g_yes || '", "' ||
                                    pk_alert_constant.g_no || '"');
        END IF;
    
        IF i_flg_needs_cosign = pk_alert_constant.g_yes
           AND i_flg_has_cosign = pk_alert_constant.g_yes
        THEN
            raise_application_error(-20005,
                                    'INVALID CONFIGURATION: IT''S NOT POSSIBLE TO HAVE THE NEED TO REQUEST CO-SIGN AND HAVE CO-SIGN CAPABILITY AT THE SAME TIME');
        END IF;
    
        g_error := 'CALL GET_ID_ACTION';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        l_action := get_id_action(i_cosign_def_action_type => i_cosign_def_action_type, i_action => i_action);
    
        g_error := 'CALL GET_ID_TASK_TYPE_ACTION';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        l_task_type_action := get_id_task_type_action(i_task_type => i_task_type, i_action => l_action);
    
        g_error := 'CALL PK_CORE_CONFIG.INSERT_INTO_CONFIG_TABLE';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        pk_core_config.insert_into_config_table(i_config_table   => pk_co_sign.g_cosign_config_table,
                                                i_id_record      => l_task_type_action,
                                                i_id_inst_owner  => i_id_inst_owner,
                                                i_id_config      => i_id_config,
                                                i_flg_add_remove => i_flg_add_remove,
                                                i_field_01       => i_flg_needs_cosign,
                                                i_field_02       => i_flg_has_cosign);
    END insert_into_config_table;
    --
    /**
    * Insert into config table a new task with co-sign availability
    *
    * @param i_id_config                Configuration identifier
    * @param i_id_inst_owner            Instituiton owner of the record (0-ALERT)
    * @param i_task_type                Task type id
    * @param i_cosign_def_action_type   Co-sign default action
    * @param i_action                   Action id
    * @param i_flg_add_remove           Action id
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    01-12-2014
    */
    PROCEDURE insert_into_ctbl_has_cosign
    (
        i_id_config              IN pk_core_config.t_low_char,
        i_id_inst_owner          IN pk_core_config.t_big_num DEFAULT pk_core_config.k_zero_value,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        i_flg_add_remove         IN pk_core_config.t_flg_char DEFAULT pk_core_config.k_flg_type_add
    ) IS
        l_proc_name CONSTANT VARCHAR2(32) := 'INSERT_INTO_CTBL_HAS_COSIGN';
    BEGIN
        g_error := 'CALL INSERT_INTO_CONFIG_TABLE';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        insert_into_config_table(i_id_config              => i_id_config,
                                 i_id_inst_owner          => i_id_inst_owner,
                                 i_task_type              => i_task_type,
                                 i_cosign_def_action_type => i_cosign_def_action_type,
                                 i_action                 => i_action,
                                 i_flg_needs_cosign       => pk_alert_constant.g_no,
                                 i_flg_has_cosign         => pk_alert_constant.g_yes,
                                 i_flg_add_remove         => i_flg_add_remove);
    END insert_into_ctbl_has_cosign;
    --
    /**
    * Insert a co-sign task_type action.
    *
    * @param i_id_config                Configuration identifier
    * @param i_id_inst_owner            Instituiton owner of the record (0-ALERT)
    * @param i_task_type                Task type id
    * @param i_cosign_def_action_type   Co-sign default action
    * @param i_action                   Action id
    * @param i_flg_add_remove           Action id
    *
    * @value   i_cosign_def_action_type  ADD        - Add co-sign task
    *                                    CANCEL     - Cancel co-sign task
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    01-12-2014
    */
    PROCEDURE insert_into_ctbl_needs_cosign
    (
        i_id_config              IN pk_core_config.t_low_char,
        i_id_inst_owner          IN pk_core_config.t_big_num DEFAULT pk_core_config.k_zero_value,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        i_flg_add_remove         IN pk_core_config.t_flg_char DEFAULT pk_core_config.k_flg_type_add
    ) IS
        l_proc_name CONSTANT VARCHAR2(32) := 'INSERT_INTO_CTBL_NEEDS_COSIGN';
    BEGIN
        IF i_action IS NULL
           AND
           i_cosign_def_action_type NOT IN (pk_co_sign.g_cosign_action_def_add, pk_co_sign.g_cosign_action_def_cancel)
        THEN
            raise_application_error(-20006,
                                    'INVALID I_COSIGN_DEF_ACTION_TYPE. VALID VALUES ARE: "' ||
                                    pk_co_sign.g_cosign_action_def_add || '", "' ||
                                    pk_co_sign.g_cosign_action_def_cancel || '""');
        END IF;
    
        g_error := 'CALL INSERT_INTO_CONFIG_TABLE';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_proc_name);
        insert_into_config_table(i_id_config              => i_id_config,
                                 i_id_inst_owner          => i_id_inst_owner,
                                 i_task_type              => i_task_type,
                                 i_cosign_def_action_type => i_cosign_def_action_type,
                                 i_action                 => i_action,
                                 i_flg_needs_cosign       => pk_alert_constant.g_yes,
                                 i_flg_has_cosign         => pk_alert_constant.g_no,
                                 i_flg_add_remove         => i_flg_add_remove);
    END insert_into_ctbl_needs_cosign;
    --
    /********************************************************************************************
    * Gets the co-sign config table
    *
    * @param i_lang             Origin Institution id
    * @param i_prof             Destination institution id
    * @param i_prof_dcs         Professional dep_clin_serv
    * @param i_episode          Episode id
    * @param i_task_type        Task type id 
    * @param i_action           Action id 
    *
    * @author                      Alexandre Santos
    * @since                       2014-12-01
    * @version                     2.6.4
    ********************************************************************************************/
    FUNCTION tf_cosign_config
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_prof_dcs  IN table_number DEFAULT NULL,
        i_episode   IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type IN task_type_actions.id_task_type%TYPE DEFAULT NULL,
        i_action    IN task_type_actions.id_action%TYPE DEFAULT NULL
    ) RETURN t_table_co_sign_cfg IS
        l_func_name CONSTANT VARCHAR2(32) := 'TF_COSIGN_CONFIG';
        --
        l_tbl_ret t_table_co_sign_cfg;
        l_tbl_cfg t_tbl_config_table;
    BEGIN
        g_error := 'CALL PK_CORE_CONFIG.TF_CONFIG';
        --pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        l_tbl_cfg := pk_core_config.tf_config(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_config_table => pk_co_sign.g_cosign_config_table,
                                              i_prof_dcs     => i_prof_dcs,
                                              i_episode      => i_episode);
    
        IF i_task_type IS NOT NULL
           AND i_action IS NOT NULL
        THEN
            --This means that the function is being called to get data to join with the transactional table
            --so we only search in the configuration for the current permissions
            SELECT t_rec_co_sign_cfg(id_task_type          => tt.id_task_type,
                                     desc_task_type        => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                                     i_code_mess => tt.code_task_type)
                                                                 FROM dual),
                                     icon_task_type        => tt.icon,
                                     flg_task_type         => tt.flg_type,
                                     id_action             => a.id_action,
                                     desc_action           => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                                     i_code_mess => a.code_action)
                                                                 FROM dual),
                                     flg_needs_cosign      => nvl(c.flg_needs_cosign, pk_alert_constant.g_no),
                                     flg_has_cosign        => nvl(c.flg_has_cosign, pk_alert_constant.g_no),
                                     id_task_type_action   => c.id_task_type_action,
                                     func_task_description => tta.func_task_description,
                                     func_instructions     => tta.func_instructions,
                                     func_task_action_desc => tta.func_task_action_desc,
                                     func_task_exec_date   => tta.func_task_exec_date,
                                     id_config             => c.id_config,
                                     id_inst_owner         => c.id_inst_owner)
              BULK COLLECT
              INTO l_tbl_ret
              FROM task_type_actions tta
              LEFT JOIN (SELECT /*+ opt_estimate(table cfg rows=1) */
                          cfg.id_config,
                          cfg.id_inst_owner,
                          cfg.id_record     id_task_type_action,
                          cfg.field_01      flg_needs_cosign,
                          cfg.field_02      flg_has_cosign
                           FROM TABLE(l_tbl_cfg) cfg) c
                ON c.id_task_type_action = tta.id_task_type_action
              JOIN task_type tt
                ON tt.id_task_type = tta.id_task_type
              JOIN action a
                ON a.id_action = tta.id_action
             WHERE tta.id_task_type = i_task_type
               AND tta.id_action = i_action;
        ELSIF l_tbl_cfg.exists(1)
        THEN
            SELECT t_rec_co_sign_cfg(id_task_type          => tt.id_task_type,
                                     desc_task_type        => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                                     i_code_mess => tt.code_task_type)
                                                                 FROM dual),
                                     icon_task_type        => tt.icon,
                                     flg_task_type         => tt.flg_type,
                                     id_action             => a.id_action,
                                     desc_action           => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                                     i_code_mess => a.code_action)
                                                                 FROM dual),
                                     flg_needs_cosign      => c.flg_needs_cosign,
                                     flg_has_cosign        => c.flg_has_cosign,
                                     id_task_type_action   => c.id_task_type_action,
                                     func_task_description => tta.func_task_description,
                                     func_instructions     => tta.func_instructions,
                                     func_task_action_desc => tta.func_task_action_desc,
                                     func_task_exec_date   => tta.func_task_exec_date,
                                     id_config             => c.id_config,
                                     id_inst_owner         => c.id_inst_owner)
              BULK COLLECT
              INTO l_tbl_ret
              FROM (SELECT /*+ opt_estimate(table cfg rows=1) */
                     cfg.id_config,
                     cfg.id_inst_owner,
                     cfg.id_record     id_task_type_action,
                     cfg.field_01      flg_needs_cosign,
                     cfg.field_02      flg_has_cosign
                      FROM TABLE(l_tbl_cfg) cfg) c
              JOIN task_type_actions tta
                ON tta.id_task_type_action = c.id_task_type_action
              JOIN task_type tt
                ON tt.id_task_type = tta.id_task_type
              JOIN action a
                ON a.id_action = tta.id_action;
        END IF;
    
        IF NOT l_tbl_ret.exists(1)
        THEN
            --Set default configuration
            l_tbl_ret := t_table_co_sign_cfg(t_rec_co_sign_cfg(id_task_type          => NULL,
                                                               desc_task_type        => NULL,
                                                               icon_task_type        => NULL,
                                                               flg_task_type         => NULL,
                                                               id_action             => NULL,
                                                               desc_action           => NULL,
                                                               flg_needs_cosign      => pk_alert_constant.g_no,
                                                               flg_has_cosign        => pk_alert_constant.g_no,
                                                               id_task_type_action   => NULL,
                                                               func_task_description => NULL,
                                                               func_instructions     => NULL,
                                                               func_task_action_desc => NULL,
                                                               func_task_exec_date   => NULL,
                                                               id_config             => NULL,
                                                               id_inst_owner         => NULL));
        END IF;
    
        RETURN l_tbl_ret;
    END tf_cosign_config;

    /********************************************************************************************
    * Gets the co-sign config table
    *
    * @param i_lang             Origin Institution id
    * @param i_prof             Destination institution id
    * @param i_prof_dcs         Professional dep_clin_serv
    * @param i_episode          Episode id
    * @param i_task_type        Task type id 
    * @param i_action           Action id 
    *
    * @author                      Alexandre Santos
    * @since                       2014-12-01
    * @version                     2.6.4
    ********************************************************************************************/
    FUNCTION tf_cosign_config
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_dcs         IN table_number DEFAULT NULL,
        i_episode          IN episode.id_episode%TYPE DEFAULT NULL,
        i_tbl_id_task_type IN table_number,
        i_action           IN task_type_actions.id_action%TYPE DEFAULT NULL
    ) RETURN t_table_co_sign_cfg IS
        l_func_name CONSTANT VARCHAR2(32) := 'TF_COSIGN_CONFIG';
        --
        l_tbl_ret t_table_co_sign_cfg;
        l_tbl_cfg t_tbl_config_table;
    BEGIN
        g_error := 'CALL PK_CORE_CONFIG.TF_CONFIG';
        --pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        l_tbl_cfg := pk_core_config.tf_config(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_config_table => pk_co_sign.g_cosign_config_table,
                                              i_prof_dcs     => i_prof_dcs,
                                              i_episode      => i_episode);
    
        IF i_tbl_id_task_type.exists(1)
           AND i_action IS NOT NULL
        THEN
            --This means that the function is being called to get data to join with the transactional table
            --so we only search in the configuration for the current permissions
            SELECT t_rec_co_sign_cfg(id_task_type          => tt.id_task_type,
                                     desc_task_type        => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                                     i_code_mess => tt.code_task_type)
                                                                 FROM dual),
                                     icon_task_type        => tt.icon,
                                     flg_task_type         => tt.flg_type,
                                     id_action             => a.id_action,
                                     desc_action           => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                                     i_code_mess => a.code_action)
                                                                 FROM dual),
                                     flg_needs_cosign      => nvl(c.flg_needs_cosign, pk_alert_constant.g_no),
                                     flg_has_cosign        => nvl(c.flg_has_cosign, pk_alert_constant.g_no),
                                     id_task_type_action   => c.id_task_type_action,
                                     func_task_description => tta.func_task_description,
                                     func_instructions     => tta.func_instructions,
                                     func_task_action_desc => tta.func_task_action_desc,
                                     func_task_exec_date   => tta.func_task_exec_date,
                                     id_config             => c.id_config,
                                     id_inst_owner         => c.id_inst_owner)
              BULK COLLECT
              INTO l_tbl_ret
              FROM task_type_actions tta
              LEFT JOIN (SELECT /*+ opt_estimate(table cfg rows=1) */
                          cfg.id_config,
                          cfg.id_inst_owner,
                          cfg.id_record     id_task_type_action,
                          cfg.field_01      flg_needs_cosign,
                          cfg.field_02      flg_has_cosign
                           FROM TABLE(l_tbl_cfg) cfg) c
                ON c.id_task_type_action = tta.id_task_type_action
              JOIN task_type tt
                ON tt.id_task_type = tta.id_task_type
              JOIN action a
                ON a.id_action = tta.id_action
             WHERE tta.id_action = i_action
               AND tta.id_task_type IN (SELECT column_value
                                          FROM TABLE(i_tbl_id_task_type));
        ELSIF l_tbl_cfg.exists(1)
        THEN
            SELECT /*+ opt_estimate(table c rows=1) */
             t_rec_co_sign_cfg(id_task_type          => tt.id_task_type,
                               desc_task_type        => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                               i_code_mess => tt.code_task_type)
                                                           FROM dual),
                               icon_task_type        => tt.icon,
                               flg_task_type         => tt.flg_type,
                               id_action             => a.id_action,
                               desc_action           => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                               i_code_mess => a.code_action)
                                                           FROM dual),
                               flg_needs_cosign      => c.flg_needs_cosign,
                               flg_has_cosign        => c.flg_has_cosign,
                               id_task_type_action   => c.id_task_type_action,
                               func_task_description => tta.func_task_description,
                               func_instructions     => tta.func_instructions,
                               func_task_action_desc => tta.func_task_action_desc,
                               func_task_exec_date   => tta.func_task_exec_date,
                               id_config             => c.id_config,
                               id_inst_owner         => c.id_inst_owner)
              BULK COLLECT
              INTO l_tbl_ret
              FROM (SELECT /*+ opt_estimate(table c rows=1) */
                     cfg.id_config,
                     cfg.id_inst_owner,
                     cfg.id_record     id_task_type_action,
                     cfg.field_01      flg_needs_cosign,
                     cfg.field_02      flg_has_cosign
                      FROM TABLE(l_tbl_cfg) cfg) c
              JOIN task_type_actions tta
                ON tta.id_task_type_action = c.id_task_type_action
              JOIN task_type tt
                ON tt.id_task_type = tta.id_task_type
              JOIN action a
                ON a.id_action = tta.id_action;
        END IF;
    
        IF NOT l_tbl_ret.exists(1)
        THEN
            --Set default configuration
            l_tbl_ret := t_table_co_sign_cfg(t_rec_co_sign_cfg(id_task_type          => NULL,
                                                               desc_task_type        => NULL,
                                                               icon_task_type        => NULL,
                                                               flg_task_type         => NULL,
                                                               id_action             => NULL,
                                                               desc_action           => NULL,
                                                               flg_needs_cosign      => pk_alert_constant.g_no,
                                                               flg_has_cosign        => pk_alert_constant.g_no,
                                                               id_task_type_action   => NULL,
                                                               func_task_description => NULL,
                                                               func_instructions     => NULL,
                                                               func_task_action_desc => NULL,
                                                               func_task_exec_date   => NULL,
                                                               id_config             => NULL,
                                                               id_inst_owner         => NULL));
        END IF;
    
        RETURN l_tbl_ret;
    END tf_cosign_config;

    /**
    * Checks if the current professional needs the co-sign fields to complete the action, at the request time
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise 
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    02-12-2014
    */
    FUNCTION check_prof_needs_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        o_flg_prof_need_cosign   OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'CHECK_PROF_NEEDS_COSIGN';
        --
        c_null_value CONSTANT NUMBER := -999;
        --
        l_action           action.id_action%TYPE;
        l_task_type_action task_type_actions.id_task_type_action%TYPE;
    BEGIN
        g_error := 'CALL GET_ID_ACTION';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        l_action := get_id_action(i_cosign_def_action_type => i_cosign_def_action_type, i_action => i_action);
    
        BEGIN
            g_error := 'CALL GET_ID_TASK_TYPE_ACTION';
            pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
            l_task_type_action := get_id_task_type_action(i_task_type => i_task_type, i_action => l_action);
        EXCEPTION
            WHEN no_data_found THEN
                l_task_type_action := NULL;
        END;
    
        BEGIN
            g_error := 'CALL PK_CO_SIGN.TF_COSIGN_CONFIG';
            pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
            SELECT cfg.flg_needs_cosign
              INTO o_flg_prof_need_cosign
              FROM TABLE(pk_co_sign.tf_cosign_config(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode)) cfg
             WHERE nvl(cfg.id_task_type_action, c_null_value) = nvl(l_task_type_action, c_null_value);
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_prof_need_cosign := pk_alert_constant.g_no;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_prof_needs_cosign;

    /**
    * Checks if the current professional needs the co-sign fields to complete the action, at the request time
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_tbl_task_type          Task type ids
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise 
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Alexandre Santos
    * @version  2.6.4
    * @since    02-12-2014
    */
    FUNCTION check_prof_needs_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_tbl_id_task_type       IN table_number,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        o_flg_prof_need_cosign   OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'CHECK_PROF_NEEDS_COSIGN';
        --
        c_null_value CONSTANT NUMBER := -999;
        --
        l_action                   action.id_action%TYPE;
        l_task_type_action         task_type_actions.id_task_type_action%TYPE;
        l_flg_prof_need_cosign_tab table_varchar := table_varchar();
    BEGIN
        g_error := 'CALL GET_ID_ACTION';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        l_action := get_id_action(i_cosign_def_action_type => i_cosign_def_action_type, i_action => i_action);
    
        BEGIN
            g_error := 'CALL PK_CO_SIGN.TF_COSIGN_CONFIG';
            pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
            SELECT cfg.flg_needs_cosign
              BULK COLLECT
              INTO l_flg_prof_need_cosign_tab
              FROM TABLE(pk_co_sign.tf_cosign_config(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_episode          => i_episode,
                                                     i_tbl_id_task_type => i_tbl_id_task_type,
                                                     i_action           => l_action)) cfg;
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_prof_need_cosign := pk_alert_constant.g_no;
                RETURN TRUE;
        END;
    
        FOR i IN l_flg_prof_need_cosign_tab.first .. l_flg_prof_need_cosign_tab.last
        LOOP
            IF l_flg_prof_need_cosign_tab(i) = pk_alert_constant.g_yes
            THEN
                o_flg_prof_need_cosign := pk_alert_constant.g_yes;
                RETURN TRUE;
            END IF;
        END LOOP;
    
        o_flg_prof_need_cosign := pk_alert_constant.g_no;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_prof_needs_cosign;

    /**
    * Checks if the current professional has permissions to co-sign tasks
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_task_type              Task type id
    * @param i_cosign_def_action_type Co-sign default action (Only send this parameter or i_action)
    * @param i_action                 Action id (Only send this parameter or i_cosign_def_action_type)
    * @param o_flg_prof_need_cosign   Professional needs cosig? Y - Yes; N - Otherwise 
    * @param o_error                  Error message
    *
    * @value   i_cosign_def_action_type  ADD    - Add co-sign task
    *                                    CANCEL - Cancel co-sign task
    *
    * @return  true or false on success or error
    *
    * @author   Gisela Couto
    * @version  2.6.4
    * @since    31-12-2014
    */
    FUNCTION check_prof_has_cosign
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_task_type              IN task_type.id_task_type%TYPE,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT g_cosign_action_def_add,
        i_action                 IN action.id_action%TYPE DEFAULT NULL,
        o_flg_prof_has_cosign    OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'CHECK_PROF_HAS_COSIGN';
        --
        c_null_value CONSTANT NUMBER := -999;
        --
        l_action           action.id_action%TYPE;
        l_task_type_action task_type_actions.id_task_type_action%TYPE;
    BEGIN
        g_error := 'CALL GET_ID_ACTION';
        pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        l_action := get_id_action(i_cosign_def_action_type => i_cosign_def_action_type, i_action => i_action);
    
        BEGIN
            g_error := 'CALL GET_ID_TASK_TYPE_ACTION';
            pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
            l_task_type_action := get_id_task_type_action(i_task_type => i_task_type, i_action => l_action);
        EXCEPTION
            WHEN no_data_found THEN
                l_task_type_action := NULL;
        END;
    
        BEGIN
            g_error := 'CALL PK_CO_SIGN.TF_COSIGN_CONFIG';
            pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
            SELECT cfg.flg_has_cosign
              INTO o_flg_prof_has_cosign
              FROM TABLE(pk_co_sign.tf_cosign_config(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode)) cfg
             WHERE nvl(cfg.id_task_type_action, c_null_value) = nvl(l_task_type_action, c_null_value);
        EXCEPTION
            WHEN no_data_found THEN
                o_flg_prof_has_cosign := pk_alert_constant.g_no;
        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END check_prof_has_cosign;

    /**
    * Checks if one co-sign task exists
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   The professional record
    * @param i_episode                Episode id
    * @param i_id_co_sign             Co-sign task id
    * @param i_task                   Task id
    * @param i_task_type              Task type id
    * @param i_id_action              Action id 
    * @param o_id_co_sign             Co-sign task identifier (if exists)
    * @param o_flg_status             Flag status from co_sign task (if exists)
    * @param o_error                  Error message
    *
    * @return  true or false on success or error
    *
    * @author   Gisela Couto
    * @version  2.6.4
    * @since    18-12-2014
    */
    FUNCTION check_co_sign_task_exists
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_co_sign    IN co_sign.id_co_sign%TYPE DEFAULT NULL,
        i_id_task       IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_id_task_type  IN action.internal_name%TYPE DEFAULT NULL,
        i_id_action     IN action.id_action%TYPE DEFAULT NULL,
        o_id_co_sign    OUT VARCHAR2,
        o_flg_status    OUT VARCHAR2,
        o_id_order_type OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'CHECK_CO_SIGN_TASK_EXISTS';
    BEGIN
    
        SELECT cs.id_co_sign, cs.flg_status, cs.id_order_type
          INTO o_id_co_sign, o_flg_status, o_id_order_type
          FROM co_sign cs
         WHERE cs.id_episode = i_episode
           AND (cs.id_task = i_id_task OR i_id_task IS NULL)
           AND (cs.id_task_type = i_id_task_type OR i_id_task_type IS NULL)
           AND (cs.id_action = i_id_action OR i_id_action IS NULL)
           AND (cs.id_co_sign = i_id_co_sign OR i_id_co_sign IS NULL);
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_co_sign := NULL;
            o_flg_status := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END check_co_sign_task_exists;

    /********************************************************************************************
    * Creates formated co-sign task tooltip text
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_tbl_labels             Labels (text will be formated with bold style)
    * @param i_tbl_desc               Descriptions
    *                                 (The array must be the same range and the items must be 
    *                                  in the same order)
    *                        
    * @return                         Tooltip text formatted
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION get_tooltip_task_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_tbl_labels IN table_varchar,
        i_tbl_desc   IN table_varchar
    ) RETURN CLOB IS
        l_tooltip_desc  CLOB;
        l_next_position NUMBER;
    BEGIN
    
        IF i_tbl_labels.exists(1)
        THEN
            FOR i IN i_tbl_labels.first .. i_tbl_labels.last
            LOOP
                l_next_position := i + 1;
            
                IF i_tbl_desc(i) IS NOT NULL
                THEN
                    l_tooltip_desc := l_tooltip_desc || '<b>' || i_tbl_labels(i) || '</b> ' || chr(10) || --
                                      i_tbl_desc(i);
                END IF;
            
                IF i_tbl_desc.exists(l_next_position)
                   AND i_tbl_desc(l_next_position) <> chr(32)
                THEN
                    l_tooltip_desc := l_tooltip_desc || chr(10) || chr(10);
                END IF;
            
            END LOOP;
        END IF;
    
        RETURN l_tooltip_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_tooltip_task_desc;

    /********************************************************************************************
    * Gets co-sign information by episode and/or by task identifier. Returns all tasks in all 
    * statuses
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_tbl_id_co_sign         Co-sign tasks  id
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_tbl_status             Set of task status
    * @param i_id_task_group          Task group identifier
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action 
    *                                 as well as task execution date for sorting
    *                                 'Y' - Returns details, 'N' - Otherwise
    * IMPORTANT - When the flag is passed with the Y value, the performance can be low. Please be careful.
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_sign_tasks_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type      IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_tbl_id_co_sign IN table_number DEFAULT NULL,
        i_prof_ord_by    IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_tbl_status     IN table_varchar DEFAULT NULL,
        i_id_task_group  IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_flg_with_desc  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_filter     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign IS
        l_func_name CONSTANT VARCHAR2(32) := 'TF_CO_SIGN_TASKS_INFO';
        --
        l_tbl_co_sign t_table_co_sign;
        --
        l_total_id_cs     PLS_INTEGER;
        l_total_status_cs PLS_INTEGER;
    BEGIN
        --verify if contains elements
        SELECT COUNT(*)
          INTO l_total_id_cs
          FROM TABLE(i_tbl_id_co_sign) t
         WHERE t.column_value IS NOT NULL;
    
        SELECT COUNT(*)
          INTO l_total_status_cs
          FROM TABLE(i_tbl_status) t
         WHERE t.column_value IS NOT NULL;
    
        --get co-sign information
        BEGIN
            l_tbl_co_sign := t_table_co_sign();
        
            FOR cs_record IN (SELECT t.id_co_sign,
                                     t.id_co_sign_hist,
                                     t.id_episode,
                                     t.id_task_type,
                                     t.id_action,
                                     t.id_task,
                                     t.id_task_group,
                                     t.id_order_type,
                                     t.code_order_type,
                                     t.id_prof_created,
                                     t.id_prof_ordered_by,
                                     t.id_prof_co_signed,
                                     t.dt_req,
                                     t.dt_created,
                                     t.dt_ordered_by,
                                     t.dt_co_signed,
                                     t.flg_status,
                                     t.co_sign_notes,
                                     t.flg_made_auth
                                FROM (SELECT t1.id_co_sign,
                                             t1.id_co_sign_hist,
                                             t1.id_episode,
                                             t1.id_task_type,
                                             t1.id_action,
                                             t1.id_task,
                                             t1.id_task_group,
                                             t1.id_order_type,
                                             t1.code_order_type,
                                             t1.id_prof_created,
                                             t1.id_prof_ordered_by,
                                             t1.id_prof_co_signed,
                                             t1.dt_req,
                                             t1.dt_created,
                                             t1.dt_ordered_by,
                                             t1.dt_co_signed,
                                             t1.flg_status,
                                             t1.co_sign_notes,
                                             t1.flg_made_auth,
                                             t1.rn
                                        FROM TABLE(tf_co_sign_tasks_info_int(i_prof            => i_prof,
                                                                             i_episode         => i_episode,
                                                                             i_prof_ord_by     => i_prof_ord_by,
                                                                             i_task_type       => i_task_type,
                                                                             i_tbl_id_co_sign  => i_tbl_id_co_sign,
                                                                             i_total_id_cs     => l_total_id_cs,
                                                                             i_tbl_status      => i_tbl_status,
                                                                             i_total_status_cs => l_total_status_cs,
                                                                             i_id_task_group   => i_id_task_group,
                                                                             i_flg_filter      => i_flg_filter)) t1
                                      
                                      ) t
                               WHERE t.rn = 1)
            LOOP
                l_tbl_co_sign.extend;
            
                SELECT t_rec_co_sign(id_co_sign           => cs_record.id_co_sign,
                                     id_co_sign_hist      => cs_record.id_co_sign_hist,
                                     id_episode           => cs_record.id_episode,
                                     id_task              => cs_record.id_task,
                                     id_task_group        => cs_record.id_task_group,
                                     id_task_type         => csconf.id_task_type,
                                     desc_task_type       => csconf.desc_task_type,
                                     icon_task_type       => csconf.icon_task_type,
                                     id_action            => csconf.id_action,
                                     desc_action          => csconf.desc_action,
                                     id_task_type_action  => csconf.id_task_type_action,
                                     desc_order           => decode(i_flg_with_desc,
                                                                    pk_alert_constant.g_yes,
                                                                    get_description(i_lang            => i_lang,
                                                                                    i_prof            => i_prof,
                                                                                    i_task            => cs_record.id_task,
                                                                                    i_id_co_sign_hist => cs_record.id_co_sign_hist,
                                                                                    i_func_name       => csconf.func_task_description),
                                                                    ''),
                                     desc_instructions    => decode(i_flg_with_desc,
                                                                    pk_alert_constant.g_yes,
                                                                    get_description(i_lang            => i_lang,
                                                                                    i_prof            => i_prof,
                                                                                    i_task            => cs_record.id_task,
                                                                                    i_id_co_sign_hist => cs_record.id_co_sign_hist,
                                                                                    i_func_name       => csconf.func_instructions),
                                                                    ''),
                                     desc_task_action     => decode(i_flg_with_desc,
                                                                    pk_alert_constant.g_yes,
                                                                    get_action_description(i_lang            => i_lang,
                                                                                           i_prof            => i_prof,
                                                                                           i_task            => cs_record.id_task,
                                                                                           i_id_action       => cs_record.id_action,
                                                                                           i_id_co_sign_hist => cs_record.id_co_sign_hist,
                                                                                           i_func_name       => csconf.func_task_action_desc),
                                                                    ''),
                                     id_order_type        => cs_record.id_order_type,
                                     desc_order_type      => pk_translation.get_translation(i_lang      => i_lang,
                                                                                            i_code_mess => cs_record.code_order_type),
                                     id_prof_created      => cs_record.id_prof_created,
                                     id_prof_ordered_by   => cs_record.id_prof_ordered_by,
                                     desc_prof_ordered_by => get_prof_order_desc(i_lang          => i_lang,
                                                                                 i_prof          => i_prof,
                                                                                 i_id_order_type => cs_record.id_order_type,
                                                                                 i_id_prof_order => cs_record.id_prof_ordered_by),
                                     id_prof_co_signed    => cs_record.id_prof_co_signed,
                                     dt_req               => cs_record.dt_req,
                                     dt_created           => cs_record.dt_created,
                                     dt_ordered_by        => cs_record.dt_ordered_by,
                                     dt_co_signed         => cs_record.dt_co_signed,
                                     dt_exec_date_sort    => decode(i_flg_with_desc,
                                                                    pk_alert_constant.g_yes,
                                                                    get_task_exec_date(i_lang            => i_lang,
                                                                                       i_prof            => i_prof,
                                                                                       i_task            => cs_record.id_task,
                                                                                       i_id_co_sign_hist => cs_record.id_co_sign_hist,
                                                                                       i_func_name       => csconf.func_task_exec_date),
                                                                    NULL),
                                     flg_status           => cs_record.flg_status,
                                     icon_status          => pk_sysdomain.get_img(i_lang     => i_lang,
                                                                                  i_code_dom => g_cosign_flg_status,
                                                                                  i_val      => cs_record.flg_status),
                                     desc_status          => pk_sysdomain.get_domain(i_code_dom => g_cosign_flg_status,
                                                                                     i_val      => cs_record.flg_status,
                                                                                     i_lang     => i_lang),
                                     code_co_sign_notes   => cs_record.co_sign_notes,
                                     co_sign_notes        => pk_translation.get_translation_trs(i_code_mess => cs_record.co_sign_notes),
                                     flg_has_notes        => decode(length(pk_translation.get_translation_trs(i_code_mess => cs_record.co_sign_notes)),
                                                                    0,
                                                                    pk_alert_constant.g_no,
                                                                    NULL,
                                                                    pk_alert_constant.g_no,
                                                                    pk_alert_constant.g_yes),
                                     flg_has_cosign       => csconf.flg_has_cosign,
                                     flg_needs_cosign     => csconf.flg_needs_cosign,
                                     flg_made_auth        => cs_record.flg_made_auth)
                  INTO l_tbl_co_sign(l_tbl_co_sign.count)
                  FROM TABLE(pk_co_sign.tf_cosign_config(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_episode   => cs_record.id_episode,
                                                         i_task_type => cs_record.id_task_type,
                                                         i_action    => cs_record.id_action)) csconf;
            END LOOP;
        EXCEPTION
            WHEN no_data_found THEN
                l_tbl_co_sign := NULL;
        END;
    
        RETURN l_tbl_co_sign;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_co_sign_tasks_info;

    /********************************************************************************************
    * Gets co-sign information by episode and/or by task identifier. Returns all tasks in all 
    * statuses
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_tbl_id_co_sign         Co-sign tasks  id
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_tbl_status             Set of task status
    * @param i_id_task_group          Task group identifier
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    *
    * IMPORTANT - When the flag is passed with the Y value, the performance can be low. Please be careful.
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_sign_tasks_hist_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type           IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_tbl_id_co_sign      IN table_number DEFAULT NULL,
        i_tbl_id_co_sign_hist IN table_number DEFAULT NULL,
        i_prof_ord_by         IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_tbl_status          IN table_varchar DEFAULT NULL,
        i_id_task_group       IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_flg_with_desc       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_id_task         IN table_number DEFAULT NULL
    ) RETURN t_table_co_sign IS
        l_func_name CONSTANT VARCHAR2(32) := 'GET_CO_SIGN_INFO';
        --
        l_tbl_co_sign_hist t_table_co_sign;
        --
        l_total_id_cs     PLS_INTEGER;
        l_total_id_csh    PLS_INTEGER;
        l_total_status_cs PLS_INTEGER;
    BEGIN
        --verify if contains elements
        SELECT COUNT(1)
          INTO l_total_id_cs
          FROM TABLE(i_tbl_id_co_sign) t
         WHERE t.column_value IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_total_id_csh
          FROM TABLE(i_tbl_id_co_sign_hist) t
         WHERE t.column_value IS NOT NULL;
    
        SELECT COUNT(1)
          INTO l_total_status_cs
          FROM TABLE(i_tbl_status) t
         WHERE t.column_value IS NOT NULL;
    
        --get co-sign information
        BEGIN
            l_tbl_co_sign_hist := t_table_co_sign();
        
            FOR csh_record IN (SELECT t.id_co_sign_hist,
                                      t.id_co_sign,
                                      t.id_episode,
                                      t.id_task_type,
                                      t.id_action,
                                      t.id_task,
                                      t.id_task_group,
                                      t.id_order_type,
                                      t.code_order_type,
                                      t.id_prof_created,
                                      t.id_prof_ordered_by,
                                      t.id_prof_co_signed,
                                      NULL dt_req,
                                      t.dt_created,
                                      t.dt_ordered_by,
                                      t.dt_co_signed,
                                      t.flg_status,
                                      t.co_sign_notes,
                                      t.flg_made_auth
                                 FROM TABLE(tf_cs_t_hist_info_int(i_episode             => i_episode,
                                                                  i_prof_ord_by         => i_prof_ord_by,
                                                                  i_task_type           => i_task_type,
                                                                  i_tbl_id_co_sign      => i_tbl_id_co_sign,
                                                                  i_total_id_cs         => l_total_id_cs,
                                                                  i_tbl_id_co_sign_hist => i_tbl_id_co_sign_hist,
                                                                  i_total_id_csh        => l_total_id_csh,
                                                                  i_tbl_status          => i_tbl_status,
                                                                  i_total_status_cs     => l_total_status_cs,
                                                                  i_id_task_group       => i_id_task_group,
                                                                  i_tbl_id_task         => i_tbl_id_task)) t)
            LOOP
                l_tbl_co_sign_hist.extend;
            
                SELECT t_rec_co_sign(id_co_sign           => csh_record.id_co_sign,
                                     id_co_sign_hist      => csh_record.id_co_sign_hist,
                                     id_episode           => csh_record.id_episode,
                                     id_task              => csh_record.id_task,
                                     id_task_group        => csh_record.id_task_group,
                                     id_task_type         => csconf.id_task_type,
                                     desc_task_type       => csconf.desc_task_type,
                                     icon_task_type       => csconf.icon_task_type,
                                     id_action            => csconf.id_action,
                                     desc_action          => csconf.desc_action,
                                     id_task_type_action  => csconf.id_task_type_action,
                                     desc_order           => decode(i_flg_with_desc,
                                                                    pk_alert_constant.g_yes,
                                                                    get_description(i_lang            => i_lang,
                                                                                    i_prof            => i_prof,
                                                                                    i_task            => csh_record.id_task,
                                                                                    i_id_co_sign_hist => csh_record.id_co_sign_hist,
                                                                                    i_func_name       => csconf.func_task_description),
                                                                    ''),
                                     desc_instructions    => decode(i_flg_with_desc,
                                                                    pk_alert_constant.g_yes,
                                                                    get_description(i_lang            => i_lang,
                                                                                    i_prof            => i_prof,
                                                                                    i_task            => csh_record.id_task,
                                                                                    i_id_co_sign_hist => csh_record.id_co_sign_hist,
                                                                                    i_func_name       => csconf.func_instructions),
                                                                    ''),
                                     desc_task_action     => decode(i_flg_with_desc,
                                                                    pk_alert_constant.g_yes,
                                                                    get_action_description(i_lang            => i_lang,
                                                                                           i_prof            => i_prof,
                                                                                           i_task            => csh_record.id_task,
                                                                                           i_id_action       => csh_record.id_action,
                                                                                           i_id_co_sign_hist => csh_record.id_co_sign_hist,
                                                                                           i_func_name       => csconf.func_task_action_desc),
                                                                    ''),
                                     id_order_type        => csh_record.id_order_type,
                                     desc_order_type      => pk_translation.get_translation(i_lang      => i_lang,
                                                                                            i_code_mess => csh_record.code_order_type),
                                     id_prof_created      => csh_record.id_prof_created,
                                     id_prof_ordered_by   => csh_record.id_prof_ordered_by,
                                     desc_prof_ordered_by => get_prof_order_desc(i_lang          => i_lang,
                                                                                 i_prof          => i_prof,
                                                                                 i_id_order_type => csh_record.id_order_type,
                                                                                 i_id_prof_order => csh_record.id_prof_ordered_by),
                                     id_prof_co_signed    => csh_record.id_prof_co_signed,
                                     dt_req               => csh_record.dt_req,
                                     dt_created           => csh_record.dt_created,
                                     dt_ordered_by        => csh_record.dt_ordered_by,
                                     dt_co_signed         => csh_record.dt_co_signed,
                                     dt_exec_date_sort    => decode(i_flg_with_desc,
                                                                    pk_alert_constant.g_yes,
                                                                    get_task_exec_date(i_lang            => i_lang,
                                                                                       i_prof            => i_prof,
                                                                                       i_task            => csh_record.id_task,
                                                                                       i_id_co_sign_hist => csh_record.id_co_sign_hist,
                                                                                       i_func_name       => csconf.func_task_exec_date),
                                                                    NULL),
                                     flg_status           => csh_record.flg_status,
                                     icon_status          => pk_sysdomain.get_img(i_lang     => i_lang,
                                                                                  i_code_dom => g_cosign_flg_status,
                                                                                  i_val      => csh_record.flg_status),
                                     desc_status          => pk_sysdomain.get_domain(i_code_dom => g_cosign_flg_status,
                                                                                     i_val      => csh_record.flg_status,
                                                                                     i_lang     => i_lang),
                                     code_co_sign_notes   => NULL,
                                     co_sign_notes        => csh_record.co_sign_notes,
                                     flg_has_notes        => decode(length(csh_record.co_sign_notes),
                                                                    0,
                                                                    pk_alert_constant.g_no,
                                                                    NULL,
                                                                    pk_alert_constant.g_no,
                                                                    pk_alert_constant.g_yes),
                                     flg_has_cosign       => csconf.flg_has_cosign,
                                     flg_needs_cosign     => csconf.flg_needs_cosign,
                                     flg_made_auth        => csh_record.flg_made_auth)
                  INTO l_tbl_co_sign_hist(l_tbl_co_sign_hist.count)
                  FROM TABLE(pk_co_sign.tf_cosign_config(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_episode   => csh_record.id_episode,
                                                         i_task_type => csh_record.id_task_type,
                                                         i_action    => csh_record.id_action)) csconf;
            END LOOP;
        EXCEPTION
            WHEN no_data_found THEN
                l_tbl_co_sign_hist := NULL;
        END;
    
        RETURN l_tbl_co_sign_hist;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_co_sign_tasks_hist_info;

    /********************************************************************************************
    * Gets information about pending co-sign tasks
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    * IMPORTANT - When the flag is passed with the Y value, the performance can be low. Please be careful.
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_pending_co_sign_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type     IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_prof_ord_by   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_flg_with_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign IS
    
    BEGIN
    
        RETURN tf_co_sign_tasks_info(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_episode        => i_episode,
                                     i_task_type      => i_task_type,
                                     i_tbl_id_co_sign => NULL,
                                     i_prof_ord_by    => i_prof_ord_by,
                                     i_tbl_status     => table_varchar(g_cosign_flg_status_p),
                                     i_flg_with_desc  => i_flg_with_desc);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_pending_co_sign_tasks;

    /********************************************************************************************
    * Gets information about co-signed tasks
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    * IMPORTANT - When the flag is passed with the Y value, the performance can be low. Please be careful.
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_co_signed_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type     IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_prof_ord_by   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_flg_with_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign IS
    
    BEGIN
    
        RETURN tf_co_sign_tasks_info(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_episode        => i_episode,
                                     i_task_type      => i_task_type,
                                     i_tbl_id_co_sign => NULL,
                                     i_prof_ord_by    => i_prof_ord_by,
                                     i_tbl_status     => table_varchar(g_cosign_flg_status_cs),
                                     i_flg_with_desc  => i_flg_with_desc);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_co_signed_tasks;

    /********************************************************************************************
    * Gets information about outdated co-sign tasks
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_task_type              Tsk type identifiera
    * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
    * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
    *                                 'Y' - Returns decription, 'N' - Otherwise
    * IMPORTANT - When the flag is passed with the Y value, the performance can be low. Please be careful.
    *                        
    * @return                         Returns t_table_co_sign table function that contains co_sign 
    *                                 tasks information.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION tf_outdated_co_sign_tasks
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_task_type     IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_prof_ord_by   IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_flg_with_desc IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign IS
    
    BEGIN
    
        RETURN tf_co_sign_tasks_info(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_episode        => i_episode,
                                     i_task_type      => i_task_type,
                                     i_tbl_id_co_sign => NULL,
                                     i_prof_ord_by    => i_prof_ord_by,
                                     i_tbl_status     => table_varchar(g_cosign_flg_status_na),
                                     i_flg_with_desc  => i_flg_with_desc);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END tf_outdated_co_sign_tasks;

    /********************************************************************************************
    * Validate the input co-sign task status 
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_order_type          Order type identifier 
    * @param i_flg_status             Co-sign task flag status ('P' - Peding, 'D' - Draft)
    *                        
    * @return                         Returns a valid co-sign task flag status
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/18
    **********************************************************************************************/
    FUNCTION get_co_sign_flg_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_order_type IN order_type.id_order_type%TYPE,
        i_flg_status    IN sys_domain.val%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_flg_status sys_domain.val%TYPE;
    BEGIN
    
        IF i_flg_status = g_cosign_flg_status_p
        THEN
            BEGIN
                --this function is called to know if this workflow will generate co-sign task
                SELECT decode(get_flg_co_sign_wf(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_order_type  => ot.id_order_type,
                                                 i_flg_co_sign_wf => ot.flg_co_sign_wf),
                              pk_alert_constant.g_yes,
                              g_cosign_flg_status_p,
                              g_cosign_flg_status_na)
                  INTO l_flg_status
                  FROM order_type ot
                 WHERE ot.id_order_type = i_id_order_type;
            EXCEPTION
                WHEN OTHERS THEN
                    l_flg_status := g_cosign_flg_status_na;
            END;
        
        ELSE
            l_flg_status := i_flg_status;
        END IF;
    
        RETURN l_flg_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_co_sign_flg_status;

    /********************************************************************************************
    * Check if order type generates co_sign workflow
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_order_type          Order type identifier 
    *                        
    * @return                         Returns 'Y' or 'N'
    * 
    * @author                         Nuno Alves
    * @version                        2.6.5
    * @since                          2015/04/22
    **********************************************************************************************/
    FUNCTION get_order_type_generates_wf
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_order_type IN order_type.id_order_type%TYPE
    ) RETURN VARCHAR2 IS
        l_generates_wf sys_domain.val%TYPE;
    BEGIN
        BEGIN
            --this function is called to know if this workflow will generate co-sign task
            SELECT get_flg_co_sign_wf(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_id_order_type  => ot.id_order_type,
                                      i_flg_co_sign_wf => ot.flg_co_sign_wf)
              INTO l_generates_wf
              FROM order_type ot
             WHERE ot.id_order_type = i_id_order_type;
        EXCEPTION
            WHEN OTHERS THEN
                l_generates_wf := NULL;
        END;
    
        RETURN l_generates_wf;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_order_type_generates_wf;

    /********************************************************************************************
    * Insert co-sign task in co_sign_hist table, by co-sign task identifier
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_co_sign             Co-sign identifier 
    * @param o_notes_trans_code       Code translation notes
    * @param o_id_prof_ordered        Ordered by professional id    
    * @param o_id_co_sign_hist        Co-sign history record identifier        
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/18
    **********************************************************************************************/
    FUNCTION insert_into_co_sign_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_co_sign       IN co_sign.id_co_sign%TYPE,
        o_notes_trans_code OUT translation.code_translation%TYPE,
        o_id_prof_ordered  OUT professional.id_professional%TYPE,
        o_id_co_sign_hist  OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(40 CHAR) := 'INSERT_INTO_CO_SIGN_HIST';
        --
        l_co_sign_record   co_sign_hist%ROWTYPE;
        l_translation_code translation_trs.code_translation%TYPE;
        l_rows_out         table_varchar := table_varchar();
        --
        l_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
    BEGIN
    
        SELECT ts_co_sign_hist.next_key() id_co_sign_hist,
               cs.id_co_sign,
               cs.id_task,
               cs.id_task_group,
               cs.id_task_type,
               cs.id_action,
               cs.id_order_type,
               cs.id_episode,
               cs.id_prof_created,
               cs.id_prof_ordered_by,
               cs.id_prof_co_signed,
               cs.dt_created,
               cs.dt_ordered_by,
               cs.dt_co_signed,
               cs.flg_status,
               cs.co_sign_notes co_sign_notes,
               cs.flg_made_auth,
               NULL create_user,
               NULL create_time,
               NULL create_institution,
               NULL update_user,
               NULL update_time,
               NULL update_institution
          INTO l_co_sign_record.id_co_sign_hist,
               l_co_sign_record.id_co_sign,
               l_co_sign_record.id_task,
               l_co_sign_record.id_task_group,
               l_co_sign_record.id_task_type,
               l_co_sign_record.id_action,
               l_co_sign_record.id_order_type,
               l_co_sign_record.id_episode,
               l_co_sign_record.id_prof_created,
               l_co_sign_record.id_prof_ordered_by,
               l_co_sign_record.id_prof_co_signed,
               l_co_sign_record.dt_created,
               l_co_sign_record.dt_ordered_by,
               l_co_sign_record.dt_co_signed,
               l_co_sign_record.flg_status,
               l_co_sign_record.co_sign_notes,
               l_co_sign_record.flg_made_auth,
               l_co_sign_record.create_user,
               l_co_sign_record.create_time,
               l_co_sign_record.create_institution,
               l_co_sign_record.update_user,
               l_co_sign_record.update_time,
               l_co_sign_record.update_institution
          FROM co_sign cs
         WHERE cs.id_co_sign = i_id_co_sign;
    
        g_error := 'GET CODE TRANSLATION TRS WITH CO_SIGN_NOTES';
        pk_alertlog.log_debug(text => g_error);
        l_translation_code := l_co_sign_record.co_sign_notes;
    
        g_error := 'GET CO-SIGN NOTES';
        pk_alertlog.log_debug(text => g_error);
        l_co_sign_record.co_sign_notes := pk_translation.get_translation_trs(i_code_mess => l_translation_code);
    
        g_error := 'INSERT IN CO_SIGN_HIST TABLE';
        pk_alertlog.log_debug(text => g_error);
        ts_co_sign_hist.ins(rec_in => l_co_sign_record);
    
        g_error := 'CALL PROCESS_INSERT - CO_SIGN_HIST';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => g_table_name_hist,
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        o_notes_trans_code := l_translation_code;
        o_id_prof_ordered  := l_co_sign_record.id_prof_ordered_by;
        o_id_co_sign_hist  := l_co_sign_record.id_co_sign_hist;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END insert_into_co_sign_hist;

    /********************************************************************************************
    * Verify if a co-sign task can be co-signed inline
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode identifier
    * @param i_id_co_sign             Co-sign identifier 
    * @param i_id_task_group          Co-sign task group
    * @param i_task_type              Task type identifier
    *                        
    * @return                         Value 'Y' (yes) or 'N' (no)
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          2014/12/21
    **********************************************************************************************/
    FUNCTION check_task_co_sign_inline
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_id_co_sign    IN co_sign.id_co_sign%TYPE,
        i_id_task_group IN co_sign.id_task_group%TYPE,
        i_task_type     IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_tbl_id_cosign    table_varchar := table_varchar();
        l_flg_status       co_sign.flg_status%TYPE;
        l_can_be_cs_inline VARCHAR2(1 CHAR);
        l_error            t_error_out;
        --
        l_exception EXCEPTION;
        l_id_action co_sign.id_action%TYPE;
    BEGIN
    
        IF i_id_co_sign IS NOT NULL
        THEN
        
            --Verify if the task was already co-signed
            SELECT cs.flg_status, id_action
              INTO l_flg_status, l_id_action
              FROM co_sign cs
             WHERE cs.id_co_sign = i_id_co_sign;
        
            --The task can only be co-signed if the status is waiting for co-sign.
            IF l_flg_status = g_cosign_flg_status_p
            THEN
                --Verify if exists another task to be co-signed
                BEGIN
                    SELECT cs.id_co_sign
                      BULK COLLECT
                      INTO l_tbl_id_cosign
                      FROM co_sign cs
                     WHERE cs.id_task_group = i_id_task_group
                       AND cs.id_task_type = i_task_type
                       AND cs.flg_status = g_cosign_flg_status_p
                       AND cs.dt_created < (SELECT cs1.dt_created
                                              FROM co_sign cs1
                                             WHERE cs1.id_co_sign = i_id_co_sign);
                EXCEPTION
                    WHEN no_data_found THEN
                        RETURN pk_alert_constant.g_yes;
                END;
            
                IF l_tbl_id_cosign.exists(1)
                THEN
                    --Cannot be co-signed
                    l_can_be_cs_inline := pk_alert_constant.g_no;
                ELSE
                    --No tasks exists.
                    --Verify if the professional has permissions to co-sign
                    IF NOT check_prof_has_cosign(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_episode             => i_episode,
                                                 i_task_type           => i_task_type,
                                                 i_action              => l_id_action,
                                                 o_flg_prof_has_cosign => l_can_be_cs_inline,
                                                 o_error               => l_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                END IF;
            
            ELSE
                --Cannot be co-signed 
                l_can_be_cs_inline := pk_alert_constant.g_no;
            END IF;
        ELSE
            --Cannot be co-signed 
            l_can_be_cs_inline := pk_alert_constant.g_no;
        END IF;
        RETURN l_can_be_cs_inline;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END check_task_co_sign_inline;

    /********************************************************************************************
    * Gets all co-sing tasks, by professional identifier and patient episode
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                The episode ID
    * @param o_co_sign_list           Cursor containing the task list to co-sign 
                                          
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    TODO: TO BE CHANGED TO get_co_sign_list
    **********************************************************************************************/

    FUNCTION get_cosign_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_flg_filter   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_co_sign_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'GET_COSIGN_LIST';
        --
        --tooltip co-sign task
        l_msg_action sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => g_action_sys_message) || ':';
        l_msg_order  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => g_order_sys_message) || ':';
        l_msg_instr  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => g_instr_sys_message) || ':';
        l_msg_notes  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => g_cs_notes_sys_message) || ':';
    
        l_msg_order_type sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => g_order_type_sys_message);
        l_msg_ordered_by sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => g_ordered_by_sys_message);
        l_msg_ordered_at sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => g_ordered_at_sys_message);
    
        l_exception EXCEPTION;
    
    BEGIN
    
        IF i_episode IS NULL
        THEN
            g_error := 'MISSING ID_EPISODE';
            pk_types.open_my_cursor(o_co_sign_list);
            RAISE l_exception;
        END IF;
    
        OPEN o_co_sign_list FOR
            SELECT cs.id_co_sign,
                   cs.id_task_group,
                   cs.task_group_need_co_sign,
                   cs.flg_task_need_co_sign,
                   cs.flg_can_co_sign_inline,
                   cs.id_task_type,
                   cs.icon_task_type,
                   cs.desc_action,
                   cs.desc_order,
                   cs.desc_instructions,
                   cs.desc_order_type,
                   cs.ordered_by,
                   cs.dt_ordered_at,
                   cs.desc_dt_ordered_at,
                   cs.icon_status,
                   cs.desc_type_tooltip,
                   cs.desc_co_sign_task_tooltip,
                   cs.desc_ordered_tooltip,
                   cs.desc_status_tooltip,
                   cs.flg_has_notes,
                   cs.dt_ord_first_group,
                   cs.dt_exec_date_sort
              FROM (SELECT tcs.id_co_sign,
                           tcs.id_task_group,
                           tcs.id_task_group || --
                           '_' || --
                           decode(tcs.flg_status, g_cosign_flg_status_p, tcs.flg_has_cosign, pk_alert_constant.g_no) task_group_need_co_sign,
                           decode(tcs.flg_status, g_cosign_flg_status_p, tcs.flg_has_cosign, pk_alert_constant.g_no) flg_task_need_co_sign,
                           check_task_co_sign_inline(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_episode       => tcs.id_episode,
                                                     i_id_co_sign    => tcs.id_co_sign,
                                                     i_id_task_group => tcs.id_task_group,
                                                     i_task_type     => tcs.id_task_type) flg_can_co_sign_inline,
                           tcs.id_task_type,
                           tcs.icon_task_type,
                           tcs.desc_task_action desc_action,
                           tcs.desc_order,
                           tcs.desc_instructions,
                           tcs.desc_order_type,
                           tcs.desc_prof_ordered_by ordered_by,
                           pk_date_utils.date_send_tsz(i_lang, tcs.dt_ordered_by, i_prof) dt_ordered_at,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, tcs.dt_ordered_by, i_prof) desc_dt_ordered_at,
                           tcs.icon_status,
                           tcs.desc_task_type desc_type_tooltip,
                           get_tooltip_task_desc(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_tbl_labels => table_varchar(l_msg_action,
                                                                               l_msg_order,
                                                                               l_msg_instr,
                                                                               l_msg_notes),
                                                 i_tbl_desc   => table_varchar(tcs.desc_task_action,
                                                                               tcs.desc_order,
                                                                               tcs.desc_instructions,
                                                                               tcs.co_sign_notes)) desc_co_sign_task_tooltip,
                           get_tooltip_task_desc(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_tbl_labels => table_varchar(l_msg_order_type,
                                                                               l_msg_ordered_by,
                                                                               l_msg_ordered_at),
                                                 i_tbl_desc   => table_varchar(tcs.desc_order_type,
                                                                               pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                                                i_prof    => i_prof,
                                                                                                                i_prof_id => tcs.id_prof_ordered_by),
                                                                               pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                                                                  tcs.dt_ordered_by,
                                                                                                                  i_prof))) desc_ordered_tooltip,
                           tcs.desc_status desc_status_tooltip,
                           tcs.flg_has_notes,
                           tcs.dt_ordered_by,
                           tcs.flg_status,
                           first_value(tcs.dt_ordered_by) over(PARTITION BY tcs.id_task_group ORDER BY tcs.dt_ordered_by ASC) dt_ord_first_group,
                           tcs.dt_exec_date_sort
                      FROM TABLE(tf_co_sign_tasks_info(i_lang          => i_lang,
                                                       i_prof          => i_prof,
                                                       i_episode       => i_episode,
                                                       i_flg_with_desc => pk_alert_constant.g_yes,
                                                       i_tbl_status    => table_varchar(g_cosign_flg_status_p,
                                                                                        g_cosign_flg_status_cs),
                                                       i_flg_filter    => i_flg_filter)) tcs) cs
             ORDER BY cs.flg_status        DESC,
                      cs.id_task_type      DESC,
                      cs.dt_exec_date_sort ASC,
                      cs.id_task_group     DESC,
                      cs.dt_ordered_by     DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_cosign_list;

    /********************************************************************************************
    * Creates the co-sign task
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign task identifier (to be updated)
    * @param i_id_task_type            Task type identifier
    * @param i_id_action               Action identifier
    * @param i_cosign_def_action_type  Co-sign default action ('NEEDS_COSIGN_ORDER', 'NEEDS_COSIGN_CANCEL',
                                       'HAS_COSIGN')       
    * @param i_id_task                 Task id
    * @param i_id_task_group           Task group id
    * @param i_id_order_type           Order type identifier
    * @param i_id_prof_created         Professional identifier that was created the order  
    * @param i_id_prof_ordered_by      Professional identifier that is the ordered by     
    * @param i_dt_created              Order creation date
    * @param i_dt_ordered_by           Date ordered by
    * @param i_flg_status              Represents the first state of the co-sign task ('D' - Draft
    *                                  'P'-Dending).
    * @param o_id_co_sign              Co-sign record identifier created  
    * @param o_id_co_sign_hist         Co-sign history record id created  
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION set_cosign_task
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_co_sign             IN co_sign.id_co_sign%TYPE DEFAULT NULL,
        i_id_co_sign_hist        IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_type           IN task_type.id_task_type%TYPE,
        i_id_action              IN action.id_action%TYPE DEFAULT NULL,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT pk_co_sign.g_cosign_action_def_add,
        i_id_task                IN co_sign.id_task%TYPE,
        i_id_task_group          IN co_sign.id_task_group%TYPE,
        i_id_order_type          IN co_sign.id_order_type%TYPE,
        --
        i_id_prof_created    IN co_sign.id_prof_created%TYPE,
        i_id_prof_ordered_by IN co_sign.id_prof_ordered_by%TYPE,
        --
        i_dt_created      IN co_sign.dt_created%TYPE,
        i_dt_ordered_by   IN co_sign.dt_ordered_by%TYPE DEFAULT NULL,
        i_flg_status      IN sys_domain.val%TYPE DEFAULT g_cosign_flg_status_p,
        o_id_co_sign      OUT co_sign.id_co_sign%TYPE,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'SET_COSIGN_TASK';
        --
        l_id_action        action.id_action%TYPE;
        l_task_type_action task_type_actions.id_task_type_action%TYPE;
        --
        l_id_co_sign           co_sign.id_co_sign%TYPE;
        l_curr_id_co_sign      co_sign.id_co_sign%TYPE;
        l_curr_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
        l_curr_flg_status      co_sign.flg_status%TYPE;
        l_curr_id_order_type   co_sign.id_order_type%TYPE;
        l_rowids               table_varchar;
        l_flg_status           co_sign.flg_status%TYPE;
        l_rows_out             table_varchar := table_varchar();
        l_translation_code     translation_trs.code_translation%TYPE;
        l_id_prof_ordered      professional.id_professional%TYPE;
        --
        l_co_sign_hist co_sign_hist%ROWTYPE;
        l_exception_ext_calls EXCEPTION; -- External function calls
        l_exception_int_calls EXCEPTION; -- Internal function exceptions
    BEGIN
    
        g_error := 'VERIFY IF MANDATORY FIELDS ARE PASSED';
        pk_alertlog.log_debug(text => g_error);
        IF i_id_task IS NULL
           OR i_id_task_group IS NULL
           OR i_episode IS NULL
           OR i_id_task_type IS NULL
           OR i_id_order_type IS NULL
           OR i_id_prof_created IS NULL
           OR i_dt_created IS NULL
        THEN
            g_error := 'i_episode,' || i_episode || '  i_id_task_type,' || i_id_task_type || ' i_id_order_type,' ||
                       i_id_order_type || ' i_id_prof_created,' || i_id_prof_created || ' i_dt_created' || i_dt_created ||
                       ' MUST BE NOT NULL';
            pk_alertlog.log_error(text => g_error);
            RAISE l_exception_int_calls;
        END IF;
    
        IF i_flg_status NOT IN (g_cosign_flg_status_p, g_cosign_flg_status_d)
        THEN
            g_error := 'FLG_STATUS MUST BE - PENGING (P) OR DRAFT (D)';
            pk_alertlog.log_error(text => g_error);
            RAISE l_exception_int_calls;
        END IF;
    
        g_error := 'GET ID_ACTIONS';
        pk_alertlog.log_debug(text => g_error);
        l_id_action := get_id_action(i_cosign_def_action_type => i_cosign_def_action_type, i_action => i_id_action);
    
        g_error := 'VERIFY IF EXISTS ID_TASK_TYPE_ACTION TO ID_TASK_TYPE ' || i_id_task_type || ' AND ID_ACTION ' ||
                   i_id_action;
        pk_alertlog.log_debug(text => g_error);
        l_task_type_action := get_id_task_type_action(i_task_type => i_id_task_type, i_action => l_id_action);
    
        IF i_id_co_sign IS NULL
           AND i_id_co_sign_hist IS NOT NULL
        THEN
            g_error := 'GET ID_CO_SIGN FOR ID_CO_SIGN_HIST: ' || i_id_co_sign_hist;
            pk_alertlog.log_debug(text => g_error);
            l_id_co_sign := get_id_co_sign_from_hist(i_id_co_sign_hist => i_id_co_sign_hist);
        ELSE
            l_id_co_sign := i_id_co_sign;
        END IF;
    
        g_error := 'VERIFY IF EXISTS THE SAME CO_SIGN RECORD';
        pk_alertlog.log_debug(text => g_error);
        IF l_id_co_sign IS NOT NULL
        THEN
            --find by id_co_sign
            IF NOT check_co_sign_task_exists(i_lang          => i_lang,
                                             i_prof          => i_prof,
                                             i_episode       => i_episode,
                                             i_id_co_sign    => l_id_co_sign,
                                             o_id_co_sign    => l_curr_id_co_sign,
                                             o_flg_status    => l_curr_flg_status,
                                             o_id_order_type => l_curr_id_order_type,
                                             o_error         => o_error)
            THEN
                RAISE l_exception_ext_calls;
            END IF;
        
        ELSE
            -- create new co_sign, UK constraint disabled
            l_curr_id_co_sign := NULL;
        END IF;
    
        IF l_curr_id_co_sign IS NOT NULL
        THEN
            g_error := 'SET CO-SIGN FLG_STATUS AS - ' || i_flg_status;
            pk_alertlog.log_debug(text => g_error);
        
            l_flg_status := get_co_sign_flg_status(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_id_order_type => i_id_order_type,
                                                   i_flg_status    => i_flg_status);
        
            g_error := 'UPDATE EXISTING RECORD IN CO_SIGN TABLE';
            pk_alertlog.log_debug(text => g_error);
            ts_co_sign.upd(id_co_sign_in          => l_curr_id_co_sign,
                           id_task_in             => i_id_task,
                           id_task_nin            => FALSE,
                           id_task_group_in       => i_id_task_group,
                           id_task_group_nin      => FALSE,
                           id_order_type_in       => i_id_order_type,
                           id_order_type_nin      => FALSE,
                           id_episode_in          => i_episode,
                           id_episode_nin         => FALSE,
                           id_prof_created_in     => i_id_prof_created,
                           id_prof_created_nin    => FALSE,
                           id_prof_ordered_by_in  => i_id_prof_ordered_by,
                           id_prof_ordered_by_nin => FALSE,
                           id_prof_co_signed_in   => NULL,
                           id_prof_co_signed_nin  => FALSE,
                           dt_created_in          => i_dt_created,
                           dt_created_nin         => FALSE,
                           dt_ordered_by_in       => i_dt_ordered_by,
                           dt_ordered_by_nin      => FALSE,
                           dt_co_signed_in        => NULL,
                           dt_co_signed_nin       => FALSE,
                           flg_status_in          => l_flg_status,
                           flg_status_nin         => FALSE,
                           flg_made_auth_in       => NULL,
                           flg_made_auth_nin      => FALSE,
                           rows_out               => l_rowids);
        
            g_error := 'CALL PROCESS_UPDATE - CO_SIGN';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => g_table_name,
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        ELSE
            g_error      := 'GET CO-SIGN TASK FLG_STATUS -- CALL GET_CO_SIGN_FLG_STATUS';
            l_flg_status := get_co_sign_flg_status(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_id_order_type => i_id_order_type,
                                                   i_flg_status    => i_flg_status);
        
            g_error := 'GET CO_SIGN IDENTIFIER';
            pk_alertlog.log_debug(text => g_error);
            l_curr_id_co_sign := ts_co_sign.next_key;
        
            g_error := 'INSERT NEW RECORD IN CO_SIGN TABLE';
            pk_alertlog.log_debug(text => g_error);
            ts_co_sign.ins(id_co_sign_in         => l_curr_id_co_sign,
                           id_task_in            => i_id_task,
                           id_task_group_in      => nvl(i_id_task_group, i_id_task),
                           id_task_type_in       => i_id_task_type,
                           id_action_in          => l_id_action,
                           id_order_type_in      => i_id_order_type,
                           id_episode_in         => i_episode,
                           id_prof_created_in    => i_id_prof_created,
                           id_prof_ordered_by_in => i_id_prof_ordered_by,
                           dt_created_in         => i_dt_created,
                           dt_ordered_by_in      => i_dt_ordered_by,
                           flg_status_in         => l_flg_status,
                           rows_out              => l_rowids);
        
            g_error := 'CALL PROCESS_INSERT - CO_SIGN';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => g_table_name,
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END IF;
    
        g_error := 'INSERT THE EXISTING RECORD IN CO_SIGN_HIST - CALL INSERT_INTO_CO_SIGN_HIST';
        pk_alertlog.log_debug(text => g_error);
        IF NOT insert_into_co_sign_hist(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        i_id_co_sign       => l_curr_id_co_sign,
                                        o_notes_trans_code => l_translation_code,
                                        o_id_prof_ordered  => l_id_prof_ordered,
                                        o_id_co_sign_hist  => l_curr_id_co_sign_hist,
                                        o_error            => o_error)
        THEN
            RAISE l_exception_ext_calls;
        END IF;
    
        g_error := 'INSERT NEW CO-SIGN NOTES';
        pk_alertlog.log_debug(text => g_error);
        IF pk_translation.get_translation_trs(i_code_mess => l_translation_code) IS NOT NULL
        THEN
            pk_translation.insert_translation_trs(i_lang              => i_lang,
                                                  i_code              => l_translation_code,
                                                  i_desc              => NULL,
                                                  i_module            => g_translation_trs_module,
                                                  i_episode           => i_episode,
                                                  i_professional      => i_prof.id,
                                                  i_flg_record_format => g_co_sign_text_format);
        
        END IF;
    
        IF l_flg_status = g_cosign_flg_status_p
        THEN
            g_error := 'ADD CO_SIGN TASK SYS ALERT TO THE PROFESSIONAL ASSIGNED - ' || i_id_prof_ordered_by;
            pk_alertlog.log_debug(text => g_error);
            IF NOT set_co_sign_alerts(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_episode         => i_episode,
                                      i_id_req_det      => l_curr_id_co_sign,
                                      i_dt_req_det      => current_timestamp,
                                      i_id_professional => i_id_prof_ordered_by,
                                      i_type            => g_type_add,
                                      o_error           => o_error)
            THEN
                RAISE l_exception_ext_calls;
            END IF;
        END IF;
    
        o_id_co_sign      := l_curr_id_co_sign;
        o_id_co_sign_hist := l_curr_id_co_sign_hist;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception_ext_calls THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_cosign_task;

    /********************************************************************************************
    * Creates the co-sign task in pending status
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign task identifier (to be updated)
    * @param i_id_task_type            Task type identifier
    * @param i_id_action               Action identifier
    * @param i_cosign_def_action_type  Co-sign default action ('NEEDS_COSIGN_ORDER', 'NEEDS_COSIGN_CANCEL',
                                       'HAS_COSIGN')       
    * @param i_id_task                 Task id
    * @param i_id_task_group           Task group id
    * @param i_id_order_type           Order type identifier
    * @param i_id_prof_created         Professional identifier that was created the order  
    * @param i_id_prof_ordered_by      Professional identifier that is the ordered by     
    * @param i_dt_created              Order creation date
    * @param i_dt_ordered_by           Date ordered by
    * @param o_id_co_sign              Co-sign record identifier created
    * @param o_id_co_sign_hist         Co-sign history record id created  
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION set_pending_co_sign_task
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_co_sign             IN co_sign.id_co_sign%TYPE,
        i_id_co_sign_hist        IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_type           IN task_type.id_task_type%TYPE,
        i_id_action              IN action.id_action%TYPE DEFAULT NULL,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT pk_co_sign.g_cosign_action_def_add,
        i_id_task                IN co_sign.id_task%TYPE,
        i_id_task_group          IN co_sign.id_task_group%TYPE,
        i_id_order_type          IN co_sign.id_order_type%TYPE,
        --
        i_id_prof_created    IN co_sign.id_prof_created%TYPE,
        i_id_prof_ordered_by IN co_sign.id_prof_ordered_by%TYPE,
        --
        i_dt_created      IN co_sign.dt_created%TYPE,
        i_dt_ordered_by   IN co_sign.dt_ordered_by%TYPE,
        o_id_co_sign      OUT co_sign.id_co_sign%TYPE,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN set_cosign_task(i_lang                   => i_lang,
                               i_prof                   => i_prof,
                               i_episode                => i_episode,
                               i_id_co_sign             => i_id_co_sign,
                               i_id_co_sign_hist        => i_id_co_sign_hist,
                               i_id_task_type           => i_id_task_type,
                               i_id_action              => i_id_action,
                               i_cosign_def_action_type => i_cosign_def_action_type,
                               i_id_task                => i_id_task,
                               i_id_task_group          => i_id_task_group,
                               i_id_order_type          => i_id_order_type,
                               i_id_prof_created        => i_id_prof_created,
                               i_id_prof_ordered_by     => i_id_prof_ordered_by,
                               i_dt_created             => i_dt_created,
                               i_dt_ordered_by          => i_dt_ordered_by,
                               i_flg_status             => g_cosign_flg_status_p,
                               o_id_co_sign             => o_id_co_sign,
                               o_id_co_sign_hist        => o_id_co_sign_hist,
                               o_error                  => o_error);
    
    END set_pending_co_sign_task;

    /********************************************************************************************
    * Creates the co-sign task in draft status
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_task_type            Task type identifier
    * @param i_id_action               Action identifier
    * @param i_cosign_def_action_type  Co-sign default action ('NEEDS_COSIGN_ORDER', 'NEEDS_COSIGN_CANCEL',
                                       'HAS_COSIGN')       
    * @param i_id_task                 Task id
    * @param i_id_task_group           Task group id
    * @param i_id_order_type           Order type identifier
    * @param i_id_prof_created         Professional identifier that was created the order  
    * @param i_id_prof_ordered_by      Professional identifier that is the ordered by     
    * @param i_dt_created              Order creation date
    * @param i_dt_ordered_by           Date ordered by
    * @param o_id_co_sign              Co-sign record identifier created  
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/
    FUNCTION set_draft_co_sign_task
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_co_sign             IN co_sign.id_co_sign%TYPE DEFAULT NULL,
        i_id_co_sign_hist        IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_type           IN task_type.id_task_type%TYPE,
        i_id_action              IN action.id_action%TYPE DEFAULT NULL,
        i_cosign_def_action_type IN action.internal_name%TYPE DEFAULT pk_co_sign.g_cosign_action_def_add,
        i_id_task                IN co_sign.id_task%TYPE,
        i_id_task_group          IN co_sign.id_task_group%TYPE,
        i_id_order_type          IN co_sign.id_order_type%TYPE,
        --
        i_id_prof_created    IN co_sign.id_prof_created%TYPE,
        i_id_prof_ordered_by IN co_sign.id_prof_ordered_by%TYPE,
        --
        i_dt_created      IN co_sign.dt_created%TYPE,
        i_dt_ordered_by   IN co_sign.dt_ordered_by%TYPE,
        o_id_co_sign      OUT co_sign.id_co_sign%TYPE,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN set_cosign_task(i_lang                   => i_lang,
                               i_prof                   => i_prof,
                               i_episode                => i_episode,
                               i_id_co_sign             => i_id_co_sign,
                               i_id_co_sign_hist        => i_id_co_sign_hist,
                               i_id_task_type           => i_id_task_type,
                               i_id_action              => i_id_action,
                               i_cosign_def_action_type => i_cosign_def_action_type,
                               i_id_task                => i_id_task,
                               i_id_task_group          => i_id_task_group,
                               i_id_order_type          => i_id_order_type,
                               i_id_prof_created        => i_id_prof_created,
                               i_id_prof_ordered_by     => i_id_prof_ordered_by,
                               i_dt_created             => i_dt_created,
                               i_dt_ordered_by          => i_dt_ordered_by,
                               i_flg_status             => g_cosign_flg_status_d,
                               o_id_co_sign             => o_id_co_sign,
                               o_id_co_sign_hist        => o_id_co_sign_hist,
                               o_error                  => o_error);
    
    END set_draft_co_sign_task;

    /********************************************************************************************
    * Change a set of co-sign task status 
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign record identifiers
    * @param i_dt_update               Date when record was updated
    * @param i_id_prof_co_signed       Professional that co-signed the task        
    * @param i_cosign_notes            Co-sign notes
    * @param i_flg_made_auth           Flag that indicates if professional made authentication: 
    *                                  (Y) - Yes, (N) - No
    * @param i_flg_made_auth           Co-sign flag status: 
    *                                  (CS) - Co-signed, (D) - Draft, (P) - Pending ,(NA) - 
    *                                  Outdated
    *
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION update_co_sign_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_co_sign       IN co_sign.id_co_sign%TYPE,
        i_id_task_upd      IN co_sign.id_task%TYPE DEFAULT NULL,
        i_dt_update        IN co_sign.dt_created%TYPE DEFAULT current_timestamp,
        i_id_prof_cosigned IN co_sign.id_prof_co_signed%TYPE,
        i_cosign_notes     IN translation_trs.desc_translation%TYPE,
        i_flg_made_auth    IN co_sign.flg_made_auth%TYPE,
        i_flg_status       IN sys_domain.val%TYPE,
        o_id_co_sign_hist  OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'UPDATE_CO_SIGN_STATUS';
        --
        l_rowids               table_varchar;
        l_to_flg_status        co_sign.flg_status%TYPE := i_flg_status;
        l_curr_id_co_sign      co_sign.id_co_sign%TYPE;
        l_curr_flg_status      co_sign.flg_status%TYPE;
        l_curr_id_order_type   co_sign.id_order_type%TYPE;
        l_translation_code     translation_trs.code_translation%TYPE;
        l_rows_out             table_varchar := table_varchar();
        l_id_prof_ordered      professional.id_professional%TYPE;
        l_curr_id_co_sign_hist co_sign_hist.id_co_sign_hist%TYPE;
        --
        l_exception_int_calls EXCEPTION; -- Internal function calls
        l_exception_ext_calls EXCEPTION; -- External function calls
    
    BEGIN
    
        g_error := 'VERIFY IF FLG_STATUS IS PENDING, COSIGNED OR NOT APPLICABLE';
        pk_alertlog.log_debug(text => g_error);
        IF l_to_flg_status NOT IN
           (g_cosign_flg_status_p, g_cosign_flg_status_cs, g_cosign_flg_status_na, g_cosign_flg_status_o)
        THEN
            g_error := 'FLG_STATUS MUST BE PENDING (P), COSIGNED (CS) OR NOT APPLICABLE (NA)';
            pk_alertlog.log_error(text => g_error);
            RAISE l_exception_int_calls;
        END IF;
    
        g_error := 'VERIFY IF CO_SIGN TAKS EXISTS - ID_CO_SIGN: ' || i_id_co_sign;
        pk_alertlog.log_debug(text => g_error);
        IF NOT check_co_sign_task_exists(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_episode       => i_episode,
                                         i_id_co_sign    => i_id_co_sign,
                                         o_id_co_sign    => l_curr_id_co_sign,
                                         o_flg_status    => l_curr_flg_status,
                                         o_id_order_type => l_curr_id_order_type,
                                         o_error         => o_error)
        THEN
            RAISE l_exception_ext_calls;
        END IF;
    
        IF l_curr_id_co_sign IS NOT NULL
           AND (
           --from pending to co-signed status
            (l_to_flg_status = g_cosign_flg_status_cs AND l_curr_flg_status = g_cosign_flg_status_p) OR
           --from draft to pending
            (l_to_flg_status = g_cosign_flg_status_p AND l_curr_flg_status = g_cosign_flg_status_d) OR
           --from pending/draft to not applicable
            (l_to_flg_status = g_cosign_flg_status_na AND
            l_curr_flg_status IN (g_cosign_flg_status_p, g_cosign_flg_status_d, g_cosign_flg_status_o)) OR
           --from pending/draft to outated
            (l_to_flg_status = g_cosign_flg_status_o AND
            l_curr_flg_status IN (g_cosign_flg_status_p, g_cosign_flg_status_d, g_cosign_flg_status_na)))
        THEN
        
            IF l_to_flg_status = g_cosign_flg_status_cs
            THEN
                g_error := 'GET CO-SIGN NOTES CODE';
                pk_alertlog.log_debug(text => g_error);
                SELECT cs.co_sign_notes
                  INTO l_translation_code
                  FROM co_sign cs
                 WHERE cs.id_co_sign = l_curr_id_co_sign;
            
                g_error := 'INSERT NEW CO-SIGN NOTES';
                pk_alertlog.log_debug(text => g_error);
                pk_translation.insert_translation_trs(i_lang              => i_lang,
                                                      i_code              => l_translation_code,
                                                      i_desc              => i_cosign_notes,
                                                      i_module            => g_translation_trs_module,
                                                      i_episode           => i_episode,
                                                      i_professional      => i_prof.id,
                                                      i_flg_record_format => g_co_sign_text_format);
            
                g_error := 'UPDATE STATE FROM WAITING TO CO-SIGNED';
                pk_alertlog.log_debug(text => g_error);
                ts_co_sign.upd(id_co_sign_in         => l_curr_id_co_sign,
                               id_prof_co_signed_in  => i_id_prof_cosigned,
                               id_prof_co_signed_nin => FALSE,
                               dt_created_in         => i_dt_update,
                               dt_created_nin        => FALSE,
                               dt_co_signed_in       => i_dt_update,
                               dt_co_signed_nin      => FALSE,
                               flg_status_in         => g_cosign_flg_status_cs,
                               flg_status_nin        => FALSE,
                               flg_made_auth_in      => i_flg_made_auth,
                               flg_made_auth_nin     => FALSE,
                               rows_out              => l_rowids);
            
            ELSE
                g_error := 'VALIDATE CO-SIGN FLG_STATUS FOR - ' || l_to_flg_status || ' TO ORDER TYPE: ' ||
                           l_curr_id_order_type;
                pk_alertlog.log_debug(text => g_error);
                l_to_flg_status := get_co_sign_flg_status(i_lang          => i_lang,
                                                          i_prof          => i_prof,
                                                          i_id_order_type => l_curr_id_order_type,
                                                          i_flg_status    => l_to_flg_status);
            
                g_error := 'UPDATE STATE FROM ' || l_curr_flg_status || ' TO ' || l_to_flg_status;
                pk_alertlog.log_debug(text => g_error);
                ts_co_sign.upd(id_co_sign_in  => l_curr_id_co_sign,
                               id_task_in     => i_id_task_upd,
                               id_task_nin    => TRUE,
                               dt_created_in  => i_dt_update,
                               dt_created_nin => FALSE,
                               flg_status_in  => l_to_flg_status,
                               flg_status_nin => FALSE,
                               rows_out       => l_rowids);
            
            END IF;
        
            g_error := 'CALL PROCESS_UPDATE - CO_SIGN';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => g_table_name,
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'INSERT THE EXISTING RECORD IN CO_SIGN_HIST - CALL INSERT_INTO_CO_SIGN_HIST';
            pk_alertlog.log_debug(text => g_error);
            IF NOT insert_into_co_sign_hist(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_id_co_sign       => l_curr_id_co_sign,
                                            o_notes_trans_code => l_translation_code,
                                            o_id_prof_ordered  => l_id_prof_ordered,
                                            o_id_co_sign_hist  => l_curr_id_co_sign_hist,
                                            o_error            => o_error)
            THEN
                RAISE l_exception_ext_calls;
            END IF;
        
            IF l_to_flg_status = g_cosign_flg_status_p
            THEN
                g_error := 'ADD CO_SIGN TASK SYS ALERT TO THE PROFESSIONAL ASSIGNED - ' || l_id_prof_ordered;
                pk_alertlog.log_debug(text => g_error);
                IF NOT set_co_sign_alerts(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_episode         => i_episode,
                                          i_id_req_det      => l_curr_id_co_sign,
                                          i_dt_req_det      => current_timestamp,
                                          i_id_professional => l_id_prof_ordered,
                                          i_type            => g_type_add,
                                          o_error           => o_error)
                THEN
                    RAISE l_exception_ext_calls;
                END IF;
            
            ELSIF l_to_flg_status IN (g_cosign_flg_status_cs, g_cosign_flg_status_na, g_cosign_flg_status_o)
            THEN
                g_error := 'REMOVE CO_SIGN TASK SYS ALERT TO THE PROFESSIONAL THAS WAS CO_SIGNED - ' ||
                           i_id_prof_cosigned;
                pk_alertlog.log_debug(text => g_error);
                IF NOT set_co_sign_alerts(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_episode         => i_episode,
                                          i_id_req_det      => l_curr_id_co_sign,
                                          i_dt_req_det      => current_timestamp,
                                          i_id_professional => nvl(i_id_prof_cosigned, l_id_prof_ordered),
                                          i_type            => g_type_rem,
                                          o_error           => o_error)
                THEN
                    RAISE l_exception_ext_calls;
                END IF;
            END IF;
        END IF;
    
        o_id_co_sign_hist := l_curr_id_co_sign_hist;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception_ext_calls THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_co_sign_status;

    /********************************************************************************************
    * Change a set of co-sign task status 
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign record identifiers
    * @param i_dt_update               Date when record was updated
    * @param i_id_prof_co_signed       Professional that co-signed the task       
    * @param i_cosign_notes            Co-sign notes
    * @param i_flg_made_auth           Flag that indicates if professional made authentication: 
    *                                  (Y) - Yes, (N) - No
    * @param i_flg_made_auth           Co-sign flag status: 
    *                                  (CS) - Co-signed, (D) - Draft, (P) - Pending ,(NA) - 
    *                                  Outdated
    *
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION update_co_sign_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_tbl_id_co_sign      IN table_number,
        i_dt_update           IN co_sign.dt_created%TYPE DEFAULT current_timestamp,
        i_id_prof_cosigned    IN co_sign.id_prof_co_signed%TYPE,
        i_cosign_notes        IN translation_trs.desc_translation%TYPE,
        i_flg_made_auth       IN co_sign.flg_made_auth%TYPE,
        i_flg_status          IN sys_domain.val%TYPE,
        o_tbl_id_co_sign_hist OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'UPDATE_CO_SIGN_STATUS';
        l_co_sign_history table_number := table_number();
        l_current_co_sign co_sign.id_co_sign%TYPE;
        l_hist_co_sign    co_sign_hist.id_co_sign_hist%TYPE;
        --
        l_exception_ext_calls EXCEPTION; -- External function calls
    BEGIN
    
        IF i_tbl_id_co_sign.exists(1)
        THEN
            FOR i IN i_tbl_id_co_sign.first .. i_tbl_id_co_sign.last
            LOOP
                l_current_co_sign := i_tbl_id_co_sign(i);
            
                g_error := 'CALL SET_TASK_CO_SIGNED - id_co_sign: ' || l_current_co_sign;
                IF NOT update_co_sign_status(i_lang             => i_lang,
                                             i_prof             => i_prof,
                                             i_episode          => i_episode,
                                             i_id_co_sign       => l_current_co_sign,
                                             i_dt_update        => i_dt_update,
                                             i_id_prof_cosigned => i_id_prof_cosigned,
                                             i_cosign_notes     => i_cosign_notes,
                                             i_flg_made_auth    => i_flg_made_auth,
                                             i_flg_status       => i_flg_status,
                                             o_id_co_sign_hist  => l_hist_co_sign,
                                             o_error            => o_error)
                THEN
                    RAISE l_exception_ext_calls;
                END IF;
            
                l_co_sign_history.extend();
                l_co_sign_history(l_co_sign_history.count) := l_hist_co_sign;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception_ext_calls THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_co_sign_status;

    /*********************************************************************************************
    * Change co-sign task status to "pending" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign record identifiers
    * @param i_id_co_sign_hist         Co_sign_hist record identifiers
    * @param i_dt_update               Date when record was updated
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_pending
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_co_sign      IN co_sign.id_co_sign%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_id_task_upd     IN co_sign.id_task%TYPE DEFAULT NULL,
        i_dt_update       IN co_sign.dt_created%TYPE DEFAULT current_timestamp,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_current_status co_sign.flg_status%TYPE;
        l_id_co_sign     co_sign.id_co_sign%TYPE := i_id_co_sign;
    BEGIN
        IF i_id_co_sign IS NULL
           AND i_id_co_sign_hist IS NOT NULL
        THEN
            -- get id_co_sign from co_sign_hist table based on id_co_sign_hist
            l_id_co_sign := get_id_co_sign_from_hist(i_id_co_sign_hist => i_id_co_sign_hist);
        END IF;
        RETURN update_co_sign_status(i_lang             => i_lang,
                                     i_prof             => i_prof,
                                     i_episode          => i_episode,
                                     i_id_co_sign       => l_id_co_sign,
                                     i_id_task_upd      => i_id_task_upd,
                                     i_dt_update        => i_dt_update,
                                     i_id_prof_cosigned => NULL,
                                     i_cosign_notes     => NULL,
                                     i_flg_made_auth    => NULL,
                                     i_flg_status       => g_cosign_flg_status_p,
                                     o_id_co_sign_hist  => o_id_co_sign_hist,
                                     o_error            => o_error);
    
    END set_task_pending;

    /********************************************************************************************
    * Change co-sign task status to "outdated" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign record identifiers
    * @param i_id_co_sign_hist         Co_sign_hist record identifiers
    * @param i_dt_update               Date when record was updated
    * @param o_id_co_sign_hist         Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_outdated
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_id_co_sign      IN co_sign.id_co_sign%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE DEFAULT NULL,
        i_dt_update       IN co_sign.dt_created%TYPE DEFAULT current_timestamp,
        o_id_co_sign_hist OUT co_sign_hist.id_co_sign_hist%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_current_status co_sign.flg_status%TYPE;
        l_id_co_sign     co_sign.id_co_sign%TYPE := i_id_co_sign;
    BEGIN
        IF i_id_co_sign IS NULL
           AND i_id_co_sign_hist IS NOT NULL
        THEN
            -- get id_co_sign from co_sign_hist table based on id_co_sign_hist
            l_id_co_sign := get_id_co_sign_from_hist(i_id_co_sign_hist => i_id_co_sign_hist);
        ELSE
            l_id_co_sign := i_id_co_sign;
        END IF;
    
        RETURN update_co_sign_status(i_lang             => i_lang,
                                     i_prof             => i_prof,
                                     i_episode          => i_episode,
                                     i_id_co_sign       => l_id_co_sign,
                                     i_dt_update        => i_dt_update,
                                     i_id_prof_cosigned => NULL,
                                     i_cosign_notes     => NULL,
                                     i_flg_made_auth    => NULL,
                                     i_flg_status       => g_cosign_flg_status_o,
                                     o_id_co_sign_hist  => o_id_co_sign_hist,
                                     o_error            => o_error);
    
    END set_task_outdated;

    /********************************************************************************************
    * Changes the co-sign status to "co-signed" status.
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_tbl_id_co_sign              Co-sign record identifier
    * @param i_cosign_notes            Co-sign notes
    * @param i_flg_made_auth           Flag that indicates if professional was made authentication: 
                                       (Y) - Yes, (N) - No
    * @param o_tbl_id_co_sign_hist     Co-sign history record id created 
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION set_task_co_signed
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_tbl_id_co_sign      IN table_number,
        i_id_prof_cosigned    IN co_sign.id_prof_co_signed%TYPE,
        i_dt_cosigned         IN co_sign.dt_co_signed%TYPE DEFAULT current_timestamp,
        i_cosign_notes        IN translation_trs.desc_translation%TYPE,
        i_flg_made_auth       IN co_sign.flg_made_auth%TYPE,
        o_tbl_id_co_sign_hist OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN update_co_sign_status(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_episode             => i_episode,
                                     i_tbl_id_co_sign      => i_tbl_id_co_sign,
                                     i_dt_update           => i_dt_cosigned,
                                     i_id_prof_cosigned    => i_id_prof_cosigned,
                                     i_cosign_notes        => i_cosign_notes,
                                     i_flg_made_auth       => i_flg_made_auth,
                                     i_flg_status          => pk_co_sign.g_cosign_flg_status_cs,
                                     o_tbl_id_co_sign_hist => o_tbl_id_co_sign_hist,
                                     o_error               => o_error);
    END set_task_co_signed;

    /********************************************************************************************
    * Returns co-sign detail information 
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_episode                 The episode ID
    * @param i_id_co_sign              Co-sign task identifier
    * @param i_flg_detail              Detail type: 'C'- current information details
    *                                               'H' - History of changes 
    * @param o_co_sign_info            Co-sign details
    * @param o_error                   Error message          
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2014/12/03
    **********************************************************************************************/

    FUNCTION get_co_sign_details
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_co_sign   IN table_number,
        i_flg_detail   IN VARCHAR2,
        i_tbl_status   IN table_varchar DEFAULT NULL,
        o_co_sign_info OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(32 CHAR) := 'GET_CO_SIGN_DETAILS';
        --
        l_exception_int_calls EXCEPTION;
        --
        l_flg_call VARCHAR2(1 CHAR);
        --
        l_tbl_co_sign_info t_table_co_sign := t_table_co_sign();
        --
        r_curr_co_sign t_rec_co_sign;
        r_prev_co_sign t_rec_co_sign;
        --
        l_msg_order_type    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_M023');
        l_msg_ordered_by    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_M024');
        l_msg_ordered_at    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_M021');
        l_msg_revised_by    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_M030');
        l_msg_co_sign_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_M020');
        l_msg_documented    sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_M025');
        l_msg_reg_by        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_M026');
        l_msg_status        sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_M022');
        l_msg_co_sign_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_T006');
        l_msg_electronicaly sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'CO_SIGN_M029');
        l_msg_signature     sys_message.desc_message%TYPE;
    
        l_prof_name      professional.name%TYPE;
        l_prof_name_prev professional.name%TYPE;
    
        l_total_id_cs PLS_INTEGER;
        l_id_history  NUMBER;
    BEGIN
        --verify if contains elements
        SELECT COUNT(1)
          INTO l_total_id_cs
          FROM TABLE(i_id_co_sign) t
         WHERE t.column_value IS NOT NULL;
    
        g_error := 'VERIFY IF MANDATORY FIELDS ARE PASSED';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF l_total_id_cs = 0
        THEN
            g_error := 'i_id_co_sign MUST BE NOT NULL';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            RAISE l_exception_int_calls;
        END IF;
    
        g_error := 'INITIALIZE HISTORY TABLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        pk_edis_hist.init_vars;
    
        IF i_flg_detail = g_cosign_curr_info
        THEN
            IF i_tbl_status IS NOT NULL
            THEN
                g_error := 'GET CO_SIGN CURRENT INFO - PK_CO_SIGN.TF_CO_SIGN_TASKS_INFO with satus';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_tbl_co_sign_info := pk_co_sign.tf_co_sign_tasks_info(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_tbl_id_co_sign => i_id_co_sign,
                                                                       i_tbl_status     => i_tbl_status,
                                                                       i_flg_with_desc  => pk_alert_constant.g_yes);
            ELSE
                g_error := 'GET CO_SIGN CURRENT INFO - PK_CO_SIGN.TF_CO_SIGN_TASKS_INFO';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_tbl_co_sign_info := pk_co_sign.tf_co_sign_tasks_info(i_lang           => i_lang,
                                                                       i_prof           => i_prof,
                                                                       i_tbl_id_co_sign => i_id_co_sign,
                                                                       i_tbl_status     => table_varchar(g_cosign_flg_status_p,
                                                                                                         g_cosign_flg_status_cs,
                                                                                                         g_cosign_flg_status_na),
                                                                       i_flg_with_desc  => pk_alert_constant.g_yes);
            END IF;
        ELSIF i_flg_detail = g_cosign_hist_info
        THEN
            IF i_tbl_status IS NOT NULL
            THEN
                g_error := 'GET CO_SIGN HISTORY INFO - PK_CO_SIGN.TF_CO_SIGN_TASKS_HIST_INFO with status';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_tbl_co_sign_info := pk_co_sign.tf_co_sign_tasks_hist_info(i_lang           => i_lang,
                                                                            i_prof           => i_prof,
                                                                            i_tbl_id_co_sign => i_id_co_sign,
                                                                            i_tbl_status     => i_tbl_status,
                                                                            i_flg_with_desc  => pk_alert_constant.g_yes);
            ELSE
                g_error := 'GET CO_SIGN HISTORY INFO - PK_CO_SIGN.TF_CO_SIGN_TASKS_HIST_INFO';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_tbl_co_sign_info := pk_co_sign.tf_co_sign_tasks_hist_info(i_lang           => i_lang,
                                                                            i_prof           => i_prof,
                                                                            i_tbl_id_co_sign => i_id_co_sign,
                                                                            i_tbl_status     => table_varchar(g_cosign_flg_status_p,
                                                                                                              g_cosign_flg_status_cs),
                                                                            i_flg_with_desc  => pk_alert_constant.g_yes);
            END IF;
        
        END IF;
    
        FOR r_co_sign IN (SELECT VALUE(t) co_sign_obj
                            FROM TABLE(l_tbl_co_sign_info) t
                           ORDER BY t.dt_created, t.dt_co_signed DESC)
        LOOP
        
            r_curr_co_sign := r_co_sign.co_sign_obj;
        
            g_error := 'DEFINE SCOPE - l_flg_call';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF i_flg_detail = g_cosign_hist_info
               AND r_prev_co_sign.id_co_sign IS NOT NULL
            THEN
                l_flg_call   := pk_edis_hist.g_call_hist;
                l_id_history := nvl(r_curr_co_sign.id_co_sign_hist, r_curr_co_sign.id_co_sign);
            ELSE
                l_flg_call   := pk_edis_hist.g_call_detail;
                l_id_history := r_curr_co_sign.id_co_sign;
            END IF;
        
            g_error := 'PK_EDIS_HIST - ADD BASIC INFORMATION';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            -- Create a new line in history table with current history record 
            pk_edis_hist.add_line(i_history => l_id_history,
                                  
                                  i_dt_hist        => nvl(r_curr_co_sign.dt_co_signed, r_curr_co_sign.dt_created),
                                  i_record_state   => r_curr_co_sign.flg_status,
                                  i_desc_rec_state => pk_sysdomain.get_domain(i_code_dom => g_cosign_flg_status,
                                                                              i_val      => r_curr_co_sign.flg_status,
                                                                              i_lang     => i_lang));
        
            -- Title - will be shown only in current information details
            IF i_flg_detail = g_cosign_curr_info
            THEN
                --Get last co-sign information (order desc, instr desc) 
                g_error := 'PK_EDIS_HIST - ADD CO_SIGN TASK TITLE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                pk_edis_hist.add_value(i_label => r_curr_co_sign.desc_order,
                                       i_value => '(' || pk_sysdomain.get_domain(i_code_dom => g_cosign_flg_status,
                                                                                 i_val      => r_curr_co_sign.flg_status,
                                                                                 i_lang     => i_lang) || ')',
                                       i_type  => pk_edis_hist.g_type_title,
                                       i_code  => 'LBL_INSTR');
            
                pk_edis_hist.add_value(i_label => NULL,
                                       i_value => r_curr_co_sign.desc_instructions,
                                       i_type  => pk_edis_hist.g_type_subtitle,
                                       i_code  => 'DESC_INSTR');
            
                pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
            
            END IF;
        
            --Task description
            IF r_curr_co_sign.flg_status = g_cosign_flg_status_p
               OR (r_curr_co_sign.flg_status = g_cosign_flg_status_cs AND i_flg_detail = g_cosign_curr_info)
            THEN
                g_error := 'PK_EDIS_HIST - ADD CO_SIGN TASK DESCRIPTION - TASK_TYPE_ACTION';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                -- Task type,action description
                pk_edis_hist.add_value(i_label => r_curr_co_sign.desc_task_action,
                                       i_value => NULL,
                                       i_type  => pk_edis_hist.g_type_title,
                                       i_code  => 'TASK_TYPE_ACT_DESC');
            
            ELSIF r_curr_co_sign.flg_status = g_cosign_flg_status_cs
            THEN
                g_error := 'PK_EDIS_HIST - ADD CO_SIGN TASK DESCRIPTION - CO_SIGN';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                --Co-sign information 
                pk_edis_hist.add_value(i_label => l_msg_co_sign_title,
                                       i_value => NULL,
                                       i_type  => pk_edis_hist.g_type_title,
                                       i_code  => 'CO_SIGN_TITLE');
            
            END IF;
        
            -- Satus info - will be shown only in history of changes section
            IF i_flg_detail = g_cosign_hist_info
            THEN
                g_error := 'PK_EDIS_HIST - ADD CO_SIGN TASK STATUS INFO';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                --Status
                pk_edis_hist.add_value_if_not_null(i_lang      => i_lang,
                                                   i_flg_call  => l_flg_call,
                                                   i_label     => l_msg_status,
                                                   i_value     => pk_sysdomain.get_domain(i_code_dom => g_cosign_flg_status,
                                                                                          i_val      => r_curr_co_sign.flg_status,
                                                                                          i_lang     => i_lang),
                                                   i_old_value => pk_sysdomain.get_domain(i_code_dom => g_cosign_flg_status,
                                                                                          i_val      => r_prev_co_sign.flg_status,
                                                                                          i_lang     => i_lang),
                                                   i_type      => pk_edis_hist.g_type_content,
                                                   i_code      => 'STATUS');
            
            END IF;
        
            g_error := 'PK_EDIS_HIST - ADD CO_SIGN TASK ORDER TYPE FIELD';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            -- Order type
            pk_edis_hist.add_value_if_not_null(i_lang      => i_lang,
                                               i_flg_call  => l_flg_call,
                                               i_label     => l_msg_order_type,
                                               i_value     => r_curr_co_sign.desc_order_type,
                                               i_old_value => r_prev_co_sign.desc_order_type,
                                               i_type      => pk_edis_hist.g_type_content,
                                               i_code      => 'ORDER_TYPE');
        
            g_error := 'PK_EDIS_HIST - ADD CO_SIGN TASK ORDERED BY FIELD';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            -- Ordered by
            pk_edis_hist.add_value_if_not_null(i_lang      => i_lang,
                                               i_flg_call  => l_flg_call,
                                               i_label     => l_msg_ordered_by,
                                               i_value     => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                               i_prof    => i_prof,
                                                                                               i_prof_id => r_curr_co_sign.id_prof_ordered_by),
                                               i_old_value => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                               i_prof    => i_prof,
                                                                                               i_prof_id => r_prev_co_sign.id_prof_ordered_by),
                                               i_type      => pk_edis_hist.g_type_content,
                                               i_code      => 'ORDERED_BY');
        
            g_error := 'PK_EDIS_HIST - ADD CO_SIGN TASK ORDERED AT FIELD';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            -- Ordered at
            pk_edis_hist.add_value_if_not_null(i_lang      => i_lang,
                                               i_flg_call  => l_flg_call,
                                               i_label     => l_msg_ordered_at,
                                               i_value     => pk_date_utils.dt_chr_date_hour_tsz(i_lang => i_lang,
                                                                                                 i_date => r_curr_co_sign.dt_ordered_by,
                                                                                                 i_inst => i_prof.institution,
                                                                                                 i_soft => i_prof.software),
                                               i_old_value => pk_date_utils.dt_chr_date_hour_tsz(i_lang => i_lang,
                                                                                                 i_date => r_prev_co_sign.dt_ordered_by,
                                                                                                 i_inst => i_prof.institution,
                                                                                                 i_soft => i_prof.software),
                                               i_type      => pk_edis_hist.g_type_content,
                                               i_code      => 'ORDERED_AT');
        
            g_error := 'PK_EDIS_HIST - ADD CO_SIGN TASK REGISTERED BY FIELD';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            --Registered by  
            pk_edis_hist.add_value_if_not_null(i_lang      => i_lang,
                                               i_flg_call  => l_flg_call,
                                               i_label     => l_msg_reg_by,
                                               i_value     => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                               i_prof    => i_prof,
                                                                                               i_prof_id => r_curr_co_sign.id_prof_created),
                                               i_old_value => pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                                               i_prof    => i_prof,
                                                                                               i_prof_id => r_prev_co_sign.id_prof_created),
                                               i_type      => pk_edis_hist.g_type_content,
                                               i_code      => 'REGISTERED_BY');
        
            --Revised By
            IF r_curr_co_sign.id_task_type = pk_alert_constant.g_task_med_local
            THEN
            
                IF NOT pk_rt_med_pfh.get_revised_prof_id(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_id_presc  => r_curr_co_sign.id_task,
                                                         o_prof_name => l_prof_name,
                                                         o_error     => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF NOT pk_rt_med_pfh.get_revised_prof_id(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_id_presc  => r_prev_co_sign.id_task,
                                                         o_prof_name => l_prof_name_prev,
                                                         o_error     => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                pk_edis_hist.add_value_if_not_null(i_lang      => i_lang,
                                                   i_flg_call  => l_flg_call,
                                                   i_label     => l_msg_revised_by,
                                                   i_value     => l_prof_name,
                                                   i_old_value => l_prof_name_prev,
                                                   i_type      => pk_edis_hist.g_type_content,
                                                   i_code      => 'REVISED_BY');
            
            END IF;
        
            IF r_curr_co_sign.flg_status <> g_cosign_flg_status_cs
            THEN
                g_error := 'PK_EDIS_HIST - ADD DOCUMENTED BY SIGNATURE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                --Documented signature                      
                pk_edis_hist.add_value(i_label => l_msg_documented,
                                       i_value => pk_edis_hist.get_signature(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_episode          => r_curr_co_sign.id_episode,
                                                                             i_date                => r_curr_co_sign.dt_created,
                                                                             i_id_prof_last_change => r_curr_co_sign.id_prof_created),
                                       i_type  => pk_edis_hist.g_type_signature,
                                       i_code  => 'SIGNATURE');
            
            ELSE
                g_error := 'PK_EDIS_HIST - ADD CO_SIGN INFORMATION - NOTES AND SIGNATURE';
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                --Co-sign information                        
                --Co-sign notes
                pk_edis_hist.add_value_if_not_null(i_lang      => i_lang,
                                                   i_flg_call  => l_flg_call,
                                                   i_label     => l_msg_co_sign_notes,
                                                   i_value     => r_curr_co_sign.co_sign_notes,
                                                   i_old_value => '',
                                                   i_type      => pk_edis_hist.g_type_content,
                                                   i_code      => 'CO_SIGN_NOTES');
            
                --Co-sign documented signature    
                IF r_curr_co_sign.flg_made_auth = pk_alert_constant.g_yes
                THEN
                    l_msg_signature := l_msg_electronicaly;
                ELSE
                    l_msg_signature := l_msg_documented;
                END IF;
                pk_edis_hist.add_value(i_label => l_msg_signature,
                                       i_value => pk_edis_hist.get_signature(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_episode          => r_curr_co_sign.id_episode,
                                                                             i_date                => r_curr_co_sign.dt_co_signed,
                                                                             i_id_prof_last_change => r_curr_co_sign.id_prof_co_signed,
                                                                             i_desc_signature      => l_msg_signature),
                                       i_type  => pk_edis_hist.g_type_signature,
                                       i_code  => 'SIGNATURE');
            
            END IF;
        
            pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
        
            r_prev_co_sign := r_curr_co_sign;
        END LOOP;
    
        g_error := 'OPEN O_CO_SIGN_INFO CURSOR';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_co_sign_info FOR
            SELECT t.id_history,
                   t.dt_history,
                   t.tbl_labels,
                   t.tbl_values,
                   t.tbl_types,
                   t.tbl_info_labels,
                   t.tbl_info_values,
                   t.tbl_codes
              FROM TABLE(pk_edis_hist.tf_hist) t
             ORDER BY t.dt_history DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_co_sign_details;

    /********************************************************************************************
    * Match co-sign task from id_episode to id_episode_new  
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              Old episode identifier
    * @param i_id_episode_new          New episode identifier
    *
    * @param o_error                   Error message       
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Gisela Couto
    * @since                          2015/01/13
    **********************************************************************************************/

    FUNCTION match_co_sign_task
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_episode_new IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
        l_exception EXCEPTION;
        l_func_name VARCHAR(100 CHAR) := 'MATCH_CO_SIGN_TASK';
    BEGIN
    
        g_error := 'UPDATE CO_SIGN TABLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        ts_co_sign.upd(id_episode_in => i_id_episode_new,
                       where_in      => 'id_episode=' || i_id_episode,
                       rows_out      => l_rowids);
    
        g_error := 'UPDATE CO_SIGN_HIST TABLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        ts_co_sign_hist.upd(id_episode_in => i_id_episode_new,
                            where_in      => 'id_episode=' || i_id_episode,
                            rows_out      => l_rowids);
    
        g_error := 'UPDATE EXISTING SYS_ALERT_EVENTS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT set_co_sign_alerts(i_lang            => i_lang,
                                  i_prof            => i_prof,
                                  i_episode         => i_id_episode,
                                  i_id_episode_new  => i_id_episode_new,
                                  i_id_req_det      => NULL,
                                  i_dt_req_det      => NULL,
                                  i_id_professional => NULL,
                                  i_type            => g_type_match,
                                  o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END match_co_sign_task;

    /*********************************************************************************************
    * This function deletes all data related to a co-sign request for patient (all episodes) 
    * or for a singular patient episode. 
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_patients             Array of patient identifiers
    * @param i_id_episodes             Array of episode identifiers
    *
    * @param o_error                   Error message       
    *                    
    * @return                         true or false on success or error
    * 
    * @author                         Renato Nunes
    * @since                          2015/04/10
    **********************************************************************************************/

    FUNCTION reset_cosign_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patients IN table_number,
        i_id_episodes IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        /*local variables*/
        l_episode_list table_number := table_number();
        l_func_name    pk_core_config.t_low_char := 'RESET_COSIGN_REG';
        --    
    BEGIN
    
        IF i_id_patients IS NULL
           AND i_id_episodes IS NULL
        THEN
            g_error := 'ID_PATIENT AND ID_EPISODE CANNOT BE BOTH NULL';
            RAISE g_exception;
        END IF;
    
        l_episode_list := i_id_episodes;
    
        IF i_id_patients IS NOT NULL
           AND i_id_patients.count > 0
        THEN
        
            l_episode_list := table_number();
            g_error        := 'ERROR GETTING THE EPISODES FROM A SPECIFIC PATIENTS';
        
            SELECT e.id_episode
              BULK COLLECT
              INTO l_episode_list
              FROM episode e
             WHERE e.id_patient IN (SELECT /*+opt_estimate(TABLE, t, rows = 1)*/
                                     column_value
                                      FROM TABLE(i_id_patients) t);
        
        END IF;
    
        g_error := 'ERROR DELETING BY A SPECIFIC PATIENTS FROM CO_SIGN_HIST';
    
        DELETE FROM co_sign_hist csh
         WHERE csh.id_episode IN (SELECT /*+opt_estimate(TABLE, t, rows = 1)*/
                                   column_value
                                    FROM TABLE(l_episode_list) t);
    
        g_error := 'ERROR DELETING BY A SPECIFIC PATIENTS FROM CO_SIGN';
    
        DELETE FROM co_sign cs
         WHERE cs.id_episode IN (SELECT /*+opt_estimate(TABLE, t, rows = 1)*/
                                  column_value
                                   FROM TABLE(l_episode_list) t);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END reset_cosign_reg;

    /*********************************************************************************************
    * This function deletes all task_type data related to a co-sign request in a task_type_group
    *
    * @param i_lang                    The language ID
    * @param i_prof                    Object (professional ID, institution ID, software ID)
    * @param i_id_episode              Episode identifier
    * @param i_id_task_group           Task group identifiers
    * @param i_id_task_type            Task Type identifier
    *
    * @param o_error                   Error message       
    *                    
    * @return                          true or false on success or error
    * 
    * @author                          Renato Nunes
    * @since                           2015/04/13
    **********************************************************************************************/

    FUNCTION remove_draft_cosign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_task_group IN task_group.id_task_group%TYPE,
        i_id_task_type  IN task_type.id_task_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /*local variables*/
        l_flg_draft_cosign co_sign.flg_status%TYPE := pk_co_sign.g_cosign_flg_status_d;
        l_func_name        pk_core_config.t_low_char := 'REMOVE_DRAFT_COSIGN';
        --
    BEGIN
    
        IF i_id_task_group IS NULL
           OR i_id_task_type IS NULL
        THEN
            g_error := 'I_ID_TASK_GROUP OR I_ID_TASK_TYPE CANNOT BE BOTH NULL';
            RAISE g_exception;
        END IF;
    
        g_error := 'ERROR DELETING FROM CO_SIGN_HIST';
        DELETE FROM co_sign_hist ch
         WHERE ch.id_task_group = i_id_task_group
           AND ch.id_task_type = i_id_task_type
           AND ch.flg_status = l_flg_draft_cosign;
    
        g_error := 'ERROR DELETING FROM CO_SIGN';
        DELETE FROM co_sign c
         WHERE c.id_task_group = i_id_task_group
           AND c.id_task_type = i_id_task_type
           AND c.flg_status = l_flg_draft_cosign;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END remove_draft_cosign;

    /********************************************************************************************
     * Gets co-sign information by episode and/or by task identifier. Returns all tasks in all 
     * statuses
     *
     * @param i_lang                   The language ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_episode                Episode identifier
     * @param i_task_type              Tsk type identifiera
     * @param i_tbl_id_co_sign         Co-sign tasks  id
     * @param i_prof_ord_by            Professional that was ordered the request - Ordered by
     * @param i_tbl_status             Set of task status
     * @param i_id_task_group          Task group identifier
     * @param i_flg_with_desc          Description about desc_order, desc_instructions and desc_task_action
     *                                 'Y' - Returns decription, 'N' - Otherwise
     *                        
     * @return                         Returns t_table_co_sign table function that contains co_sign 
     *                                 tasks information.
     * 
     * @author                         Elisabete Bugalho
     * @version                        2.6.5
     * @since                          2016/11/04
    **********************************************************************************************/

    FUNCTION tf_co_sign_tasks_info_int
    (
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE DEFAULT NULL,
        i_prof_ord_by     IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_task_type       IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_tbl_id_co_sign  IN table_number DEFAULT NULL,
        i_total_id_cs     IN NUMBER,
        i_tbl_status      IN table_varchar DEFAULT NULL,
        i_total_status_cs IN NUMBER,
        i_id_task_group   IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_flg_filter      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_co_sign_int IS
        l_out_rec        t_table_co_sign_int := t_table_co_sign_int(NULL);
        l_sql_header     VARCHAR2(2000 CHAR);
        l_sql_inner      VARCHAR2(1000 CHAR);
        l_sql_footer     VARCHAR2(1000 CHAR);
        l_sql_filter     VARCHAR2(1000 CHAR);
        l_sql_final      VARCHAR2(1000 CHAR);
        l_sql_stmt       CLOB;
        l_curid          INTEGER;
        l_ret            INTEGER;
        l_cursor         pk_types.cursor_type;
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_CO_SIGN_TASKS_INFO_INT';
        l_record_num     NUMBER;
        l_filter_records VARCHAR2(2 CHAR);
    BEGIN
        l_curid := dbms_sql.open_cursor;
    
        l_filter_records := pk_sysconfig.get_config('COSIGN_SIGNED_TASK_FILTER_RECORD', i_prof);
    
        IF i_flg_filter = pk_alert_constant.g_yes
        THEN
            l_record_num := pk_sysconfig.get_config('COSIGN_SIGNED_TASK_RECORD_NUM', i_prof);
        END IF;
    
        l_sql_header := 'select t_rec_co_sign_int(id_co_sign,id_co_sign_hist,id_episode,id_task,id_task_type,id_task_group,id_action,id_order_type,code_order_type,id_prof_created,id_prof_ordered_by,id_prof_co_signed,dt_req,dt_created,dt_ordered_by,dt_co_signed,flg_status,co_sign_notes,flg_made_auth,rn)
from (select id_co_sign,id_co_sign_hist,id_episode,id_task,id_task_type,id_task_group,id_action,id_order_type,code_order_type,id_prof_created,id_prof_ordered_by,id_prof_co_signed,dt_req,dt_created,dt_ordered_by,dt_co_signed,flg_status,co_sign_notes,flg_made_auth,rn, 
row_number() over( ORDER BY flg_status desc, dt_created desc) rn2 from 
(SELECT cs.id_co_sign,csh.id_co_sign_hist,cs.id_episode,cs.id_task,cs.id_task_type,cs.id_task_group,cs.id_action,cs.id_order_type,
ot.code_order_type,cs.id_prof_created,cs.id_prof_ordered_by,cs.id_prof_co_signed,first_value(csh.dt_created) over(PARTITION BY csh.id_co_sign ORDER BY csh.dt_created ASC) dt_req,
cs.dt_created,cs.dt_ordered_by,cs.dt_co_signed,cs.flg_status,cs.co_sign_notes,cs.flg_made_auth,row_number() over(PARTITION BY csh.id_co_sign ORDER BY csh.dt_created DESC) rn
FROM co_sign cs
JOIN co_sign_hist csh
ON cs.id_co_sign = csh.id_co_sign
JOIN order_type ot
ON cs.id_order_type = ot.id_order_type WHERE 1 = 1 ';
    
        --i_prof_ord_by
        IF i_prof_ord_by IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND cs.id_prof_ordered_by = :i_prof_ord_by ';
        END IF;
    
        --i_episode
        IF i_episode IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND cs.id_episode = :i_episode';
        END IF;
    
        --i_task_type
        IF i_task_type IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND cs.id_task_type = :i_task_type';
        END IF;
    
        --i_total_id_cs
        IF i_total_id_cs != 0
        THEN
            l_sql_inner := l_sql_inner || ' AND cs.id_co_sign IN (SELECT /*+ OPT_ESTIMATE(TABLE xpto ROWS=1) */ column_value
                                      FROM TABLE(:i_tbl_id_co_sign) xpto ) ';
        END IF;
    
        --i_total_status_cs
        IF i_total_status_cs != 0
        THEN
            l_sql_inner := l_sql_inner || ' AND cs.flg_status IN (SELECT /*+ OPT_ESTIMATE(TABLE xpto1 ROWS=1) */ column_value
                                      FROM TABLE(:i_tbl_status) xpto1 ) ';
        END IF;
    
        --i_id_task_group
        IF i_id_task_group IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND cs.id_task_group = :i_id_task_group';
        END IF;
    
        l_sql_footer := ' AND csh.flg_status != ''' || g_cosign_flg_status_cs || ''' )';
        l_sql_final  := ' where rn = 1 ) t ';
        IF i_flg_filter = pk_alert_constant.g_yes
           AND l_filter_records = pk_alert_constant.g_yes
        THEN
            l_sql_filter := ' WHERE rn2 < :l_record_num  ';
        END IF;
        l_sql_stmt := to_clob(l_sql_header || l_sql_inner || l_sql_footer || l_sql_final || l_sql_filter);
        --        dbms_output.put_line(l_sql_header);
        --        dbms_output.put_line(l_sql_inner);
        --        dbms_output.put_line(l_sql_footer);
        --         dbms_output.put_line(l_sql_final);
        --        dbms_output.put_line(l_sql_filter);
    
        pk_alertlog.log_debug(object_name     => g_package_name,
                              sub_object_name => l_db_object_name,
                              text            => dbms_lob.substr(l_sql_stmt, 4000, 1));
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        IF i_prof_ord_by IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_prof_ord_by', i_prof_ord_by);
        END IF;
    
        IF i_episode IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_episode', i_episode);
        END IF;
    
        IF i_task_type IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_task_type', i_task_type);
        END IF;
    
        IF i_total_id_cs != 0
        THEN
            dbms_sql.bind_variable(l_curid, 'i_tbl_id_co_sign', i_tbl_id_co_sign);
        END IF;
    
        IF i_total_status_cs != 0
        THEN
            dbms_sql.bind_variable(l_curid, 'i_tbl_status', i_tbl_status);
        END IF;
    
        IF i_id_task_group IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_id_task_group', i_id_task_group);
        END IF;
        IF i_flg_filter = pk_alert_constant.g_yes
           AND l_filter_records = pk_alert_constant.g_yes
        THEN
            dbms_sql.bind_variable(l_curid, 'l_record_num', l_record_num);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        RETURN l_out_rec;
    END tf_co_sign_tasks_info_int;

    /********************************************************************************************
    * Gets the co-sign config table for a given profile_template
    *
    * @param i_lang             Language
    * @param i_prof             profissional
    * @param i_profile_template Profile_template
    *
    * @author                      Elisabete Bugalho
    * @since                       2017/01/12
    * @version                     2.7.0
    ********************************************************************************************/
    FUNCTION check_profile_cosign_config
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(32) := 'TF_COSIGN_CONFIG';
        --
        l_tbl_ret t_table_co_sign_cfg;
        l_tbl_cfg t_tbl_config_table;
        l_count   NUMBER;
    BEGIN
        g_error := 'CALL PK_CORE_CONFIG.TF_CONFIG';
        --pk_alertlog.log_debug(text => g_error, sub_object_name => l_func_name);
        l_tbl_cfg := pk_core_config.tf_config(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_config_table     => pk_co_sign.g_cosign_config_table,
                                              i_profile_template => i_profile_template);
    
        IF l_tbl_cfg.exists(1)
        THEN
            SELECT /*+ opt_estimate(table c rows=1) */
             t_rec_co_sign_cfg(id_task_type          => tt.id_task_type,
                               desc_task_type        => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                               i_code_mess => tt.code_task_type)
                                                           FROM dual),
                               icon_task_type        => tt.icon,
                               flg_task_type         => tt.flg_type,
                               id_action             => a.id_action,
                               desc_action           => (SELECT pk_translation.get_translation(i_lang      => i_lang,
                                                                                               i_code_mess => a.code_action)
                                                           FROM dual),
                               flg_needs_cosign      => c.flg_needs_cosign,
                               flg_has_cosign        => c.flg_has_cosign,
                               id_task_type_action   => c.id_task_type_action,
                               func_task_description => tta.func_task_description,
                               func_instructions     => tta.func_instructions,
                               func_task_action_desc => tta.func_task_action_desc,
                               func_task_exec_date   => tta.func_task_exec_date,
                               id_config             => c.id_config,
                               id_inst_owner         => c.id_inst_owner)
              BULK COLLECT
              INTO l_tbl_ret
              FROM (SELECT cfg.id_config,
                           cfg.id_inst_owner,
                           cfg.id_record     id_task_type_action,
                           cfg.field_01      flg_needs_cosign,
                           cfg.field_02      flg_has_cosign
                      FROM TABLE(l_tbl_cfg) cfg) c
              JOIN task_type_actions tta
                ON tta.id_task_type_action = c.id_task_type_action
              JOIN task_type tt
                ON tt.id_task_type = tta.id_task_type
              JOIN action a
                ON a.id_action = tta.id_action;
        END IF;
    
        IF NOT l_tbl_ret.exists(1)
        THEN
            RETURN pk_alert_constant.g_no;
        
        ELSE
            SELECT /*+opt_estimate(TABLE, cc, rows = 1)*/
             COUNT(1)
              INTO l_count
              FROM TABLE(l_tbl_ret) cc
             WHERE cc.flg_has_cosign = pk_alert_constant.g_yes;
            IF l_count > 0
            THEN
                RETURN pk_alert_constant.g_yes;
            ELSE
                RETURN pk_alert_constant.g_no;
            END IF;
        
        END IF;
    
    END check_profile_cosign_config;

    /********************************************************************************************
    * Gets List of profile templates that can co-sign tasks
    * @param i_lang             Language
    * @param i_prof             profissional
    * @param i_profile_template Profile_template
    *
    * @author                      Elisabete Bugalho
    * @since                       2017/01/12
    * @version                     2.7.0
    ********************************************************************************************/
    FUNCTION tf_get_prof_co_sign
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_number IS
        l_profile_template table_number;
        l_flg_type         category.flg_type%TYPE;
        l_prof_co_sign     table_number := table_number();
    BEGIN
    
        -- check the type of professional 
        SELECT c.flg_type
          INTO l_flg_type
          FROM prof_cat pc, category c
         WHERE pc.id_professional = i_prof.id
           AND pc.id_institution = i_prof.institution
           AND pc.id_category = c.id_category;
    
        SELECT /*+ MATERIALIZED */
        DISTINCT ppt.id_profile_template
          BULK COLLECT
          INTO l_profile_template
          FROM prof_institution pi
          JOIN prof_soft_inst psi
            ON psi.id_software = decode(l_flg_type,
                                        g_flg_type_tech,
                                        psi.id_software,
                                        'P',
                                        psi.id_software,
                                        pk_alert_constant.g_cat_type_nutritionist,
                                        psi.id_software,
                                        i_prof.software)
           AND psi.id_professional = pi.id_professional
           AND psi.id_institution = pi.id_institution
          JOIN prof_profile_template ppt
            ON ppt.id_professional = pi.id_professional
           AND pi.id_institution = ppt.id_institution
           AND ppt.id_software = psi.id_software
          JOIN profile_template pt
            ON ppt.id_profile_template = pt.id_profile_template
         WHERE pi.id_institution = i_prof.institution
           AND pi.flg_state = pk_backoffice.g_prof_flg_state_active
           AND pk_prof_utils.is_internal_prof(i_lang, i_prof, pi.id_professional, pi.id_institution) =
               pk_alert_constant.g_yes
           AND pt.flg_available = pk_alert_constant.g_yes
           AND pi.id_prof_institution = (SELECT MAX(pi2.id_prof_institution)
                                           FROM prof_institution pi2
                                          WHERE pi2.id_professional = pi.id_professional
                                            AND pi2.id_institution = pi.id_institution);
    
        -- templates used on institution 
        IF l_profile_template.count > 0
        THEN
            -- check for all active profile_template 
            FOR i IN l_profile_template.first .. l_profile_template.last
            LOOP
                -- verify if this profile can co-sign orders
                IF check_profile_cosign_config(i_lang             => i_lang,
                                               i_prof             => profissional(0, i_prof.institution, 0),
                                               i_profile_template => l_profile_template(i)) = pk_alert_constant.g_yes
                THEN
                    l_prof_co_sign.extend();
                    l_prof_co_sign(l_prof_co_sign.last) := l_profile_template(i);
                END IF;
            END LOOP;
        
        END IF;
        RETURN l_prof_co_sign;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_prof_co_sign;
        
    END tf_get_prof_co_sign;

    FUNCTION tf_cs_t_hist_info_int
    (
        i_episode             IN episode.id_episode%TYPE DEFAULT NULL,
        i_prof_ord_by         IN co_sign.id_prof_ordered_by%TYPE DEFAULT NULL,
        i_task_type           IN task_type.id_task_type%TYPE DEFAULT NULL,
        i_tbl_id_co_sign      IN table_number DEFAULT NULL,
        i_total_id_cs         IN NUMBER,
        i_tbl_id_co_sign_hist IN table_number DEFAULT NULL,
        i_total_id_csh        IN NUMBER,
        i_tbl_status          IN table_varchar DEFAULT NULL,
        i_total_status_cs     IN NUMBER,
        i_id_task_group       IN co_sign.id_task_group%TYPE DEFAULT NULL,
        i_tbl_id_task         IN table_number DEFAULT NULL
    ) RETURN t_tab_cs_t_hist_int IS
        l_out_rec        t_tab_cs_t_hist_int := t_tab_cs_t_hist_int(NULL);
        l_sql_header     VARCHAR2(1000 CHAR);
        l_sql_inner      VARCHAR2(1000 CHAR);
        l_sql_footer     VARCHAR2(1000 CHAR);
        l_sql_stmt       CLOB;
        l_curid          INTEGER;
        l_ret            INTEGER;
        l_cursor         pk_types.cursor_type;
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_CS_T_HIST_INFO_INT';
    BEGIN
        l_curid := dbms_sql.open_cursor;
    
        l_sql_header := 'select t_rec_cs_t_hist_int(id_co_sign_hist,id_co_sign,id_episode,id_task_type,id_action,id_task,id_task_group,id_order_type,code_order_type,id_prof_created,id_prof_ordered_by,id_prof_co_signed,dt_req,dt_created,dt_ordered_by,dt_co_signed,flg_status,co_sign_notes,flg_made_auth) 
from (SELECT csh.id_co_sign_hist,
    csh.id_co_sign,
    csh.id_episode,
    csh.id_task_type,
    csh.id_action,
    csh.id_task,
    csh.id_task_group,
    csh.id_order_type,
    ot.code_order_type,
    csh.id_prof_created,
    csh.id_prof_ordered_by,
    csh.id_prof_co_signed,
    NULL dt_req,
    csh.dt_created,
    csh.dt_ordered_by,
    csh.dt_co_signed,
    csh.flg_status,
    csh.co_sign_notes,
    csh.flg_made_auth
FROM co_sign_hist csh 
JOIN order_type ot 
ON csh.id_order_type = ot.id_order_type WHERE 1 = 1 ';
    
        --i_prof_ord_by 
        IF i_prof_ord_by IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND csh.id_prof_ordered_by = :i_prof_ord_by ';
        END IF;
    
        --i_episode 
        IF i_episode IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND csh.id_episode = :i_episode';
        END IF;
    
        --i_task_type 
        IF i_task_type IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND csh.id_task_type = :i_task_type';
        END IF;
    
        --i_total_id_cs 
        IF i_total_id_cs != 0
        THEN
            l_sql_inner := l_sql_inner || ' AND csh.id_co_sign IN (SELECT column_value 
                                      FROM TABLE(:i_tbl_id_co_sign)) ';
        END IF;
    
        --i_total_id_csh 
        IF i_total_id_csh != 0
        THEN
            l_sql_inner := l_sql_inner || ' AND csh.id_co_sign_hist IN (SELECT column_value 
                                      FROM TABLE(:i_tbl_id_co_sign_hist)) ';
        END IF;
    
        --i_total_status_cs 
        IF i_total_status_cs != 0
        THEN
            l_sql_inner := l_sql_inner || ' AND csh.flg_status IN (SELECT column_value 
                                      FROM TABLE(:i_tbl_status)) ';
        END IF;
    
        --i_id_task_group 
        IF i_id_task_group IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND csh.id_task_group = :i_id_task_group';
        END IF;
    
        --i_tbl_id_task
        IF i_tbl_id_task IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND csh.id_task IN (SELECT column_value 
                                      FROM TABLE(:i_tbl_id_task)) ';
        END IF;
    
        l_sql_footer := ' )';
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_inner || l_sql_footer);
    
        pk_alertlog.log_debug(object_name     => g_package_name,
                              sub_object_name => l_db_object_name,
                              text            => dbms_lob.substr(l_sql_stmt, 4000, 1));
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        IF i_prof_ord_by IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_prof_ord_by', i_prof_ord_by);
        END IF;
    
        IF i_episode IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_episode', i_episode);
        END IF;
    
        IF i_task_type IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_task_type', i_task_type);
        END IF;
    
        IF i_total_id_cs != 0
        THEN
            dbms_sql.bind_variable(l_curid, 'i_tbl_id_co_sign', i_tbl_id_co_sign);
        END IF;
    
        IF i_total_id_csh != 0
        THEN
            dbms_sql.bind_variable(l_curid, 'i_tbl_id_co_sign_hist', i_tbl_id_co_sign_hist);
        END IF;
    
        IF i_total_status_cs != 0
        THEN
            dbms_sql.bind_variable(l_curid, 'i_tbl_status', i_tbl_status);
        END IF;
    
        IF i_id_task_group IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_id_task_group', i_id_task_group);
        END IF;
    
        IF i_tbl_id_task IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_tbl_id_task', i_tbl_id_task);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        RETURN l_out_rec;
    END tf_cs_t_hist_info_int;

    PROCEDURE inicialize IS
    BEGIN
        g_available     := 'Y';
        g_epis_active   := 'A';
        g_not_available := 'N';
        --
        --G_ATTEND_STATUS_ACT   :='A';
        --G_ATTEND_STATUS_CANC  :='C';
        --
        g_flg_status_a := 'A';
        g_flg_status_c := 'C';
        --
    
        g_co_sign_interv         := 'I';
        g_co_sign_exam           := 'E';
        g_co_sign_analysis       := 'A';
        g_co_sign_monitorization := 'M';
        g_co_sign_prescription   := 'P';
        g_co_sign_opinion        := 'OP';
    
        --
        flg_co_sign_yes := 'Y';
    
        --
        flg_prof_default_y := 'Y';
    
        flg_prof_default_n := 'N';
    
        g_flg_type_c := 'C'; -- Critical care
        g_flg_type_h := 'H';
        --
        g_interv_take_sos := 'S';
        --
        g_flg_type_d := 'D';
        g_flg_type_n := 'N';
        --
        g_cms_area_hpi  := 'HPI';
        g_cms_area_ros  := 'ROS';
        g_cms_area_pfsh := 'PFSH';
        g_cms_area_pe   := 'PE';
        g_cms_area_mdm  := 'MDM';
    
        g_bartchart_status_a := 'A';
        g_label              := 'L';
        g_no_color           := 'X';
        --
    END inicialize;

    FUNCTION get_co_sign_detail_ux
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_co_sign IN NUMBER,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';
    
        --l_tab_dd_block_data t_tab_dd_block_data;
        --l_data_source_list  table_varchar := table_varchar();
    
        tbl_data    t_tab_dd_data := t_tab_dd_data();
        tbl_co_sign t_table_co_sign := t_table_co_sign();
    
        l_desc     VARCHAR2(4000);
        l_val      VARCHAR2(4000);
        l_type     VARCHAR2(0010 CHAR);
        l_clob     CLOB;
        l_bool     BOOLEAN;
        l_flg_clob CLOB;
    
        --****************************************
        PROCEDURE push(i_row IN t_rec_dd_data) IS
            l_count NUMBER;
        BEGIN
        
            tbl_data.extend();
            l_count := tbl_data.count;
            tbl_data(l_count) := i_row;
        
        END push;
    
        --*****************************************
        PROCEDURE fill_row
        (
            i_desc     IN VARCHAR2,
            i_val      IN VARCHAR2,
            i_flg_type IN VARCHAR2,
            i_clob     IN CLOB,
            i_flg_clob IN VARCHAR2 DEFAULT 'N',
            i_flg_sep  IN VARCHAR2 DEFAULT 'Y'
        ) IS
            l_bool BOOLEAN;
            l_row  t_rec_dd_data;
            l_desc VARCHAR2(4000);
            l_sep  VARCHAR2(0020 CHAR);
        BEGIN
        
            l_bool := i_flg_clob = k_no AND i_val IS NOT NULL;
            l_bool := l_bool OR (i_flg_clob = k_yes AND dbms_lob.getlength(i_clob) > 0);
        
            IF i_flg_type NOT IN ('LP', 'L1', 'WL')
            THEN
            
                l_sep := NULL;
                IF i_flg_sep = k_yes
                THEN
                    l_sep := ': ';
                END IF;
                l_desc := i_desc || l_sep;
            
            ELSE
                l_desc := i_desc;
            END IF;
        
            IF l_bool
               OR (i_flg_type IN ('L1', 'WL'))
            THEN
                l_row := t_rec_dd_data(descr    => l_desc, --VARCHAR2(1000 CHAR),
                                       val      => i_val, --VARCHAR2(4000 CHAR),
                                       flg_type => i_flg_type, --VARCHAR2(200 CHAR),
                                       flg_html => k_no, --VARCHAR2(1 CHAR),
                                       val_clob => i_clob, --CLOB,
                                       flg_clob => i_flg_clob --VARCHAR2(1 CHAR)
                                       );
                push(l_row);
            
            END IF;
        
        END fill_row;
    
        --***********************************
        FUNCTION iif
        (
            i_bool  IN BOOLEAN,
            i_true  IN VARCHAR2,
            i_false IN VARCHAR2
        ) RETURN VARCHAR2 IS
        BEGIN
            IF i_bool
            THEN
                RETURN i_true;
            ELSE
                RETURN i_false;
            END IF;
        END iif;
    
        --***********************************
        FUNCTION get_prof_name(i_prof IN NUMBER) RETURN VARCHAR2 IS
            tbl_name table_varchar;
            l_return VARCHAR2(4000);
        BEGIN
        
            SELECT name
              BULK COLLECT
              INTO tbl_name
              FROM professional
             WHERE id_professional = i_prof;
        
            IF tbl_name.count > 0
            THEN
                l_return := tbl_name(1);
            END IF;
        
            RETURN l_return;
        
        END get_prof_name;
    
        --****************************************************************
        PROCEDURE get_signature(i_row IN t_rec_co_sign) IS
            k_code_electronically CONSTANT VARCHAR2(0100 CHAR) := 'CO_SIGN_M029';
            k_code_documented     CONSTANT VARCHAR2(0100 CHAR) := 'CO_SIGN_M025';
            l_code_label          VARCHAR2(0200 CHAR);
            l_id_prof_last_change NUMBER;
            l_date                TIMESTAMP WITH LOCAL TIME ZONE;
            l_desc_signature      VARCHAR2(4000);
            l_label               VARCHAR2(4000);
            l_signature           VARCHAR2(4000);
            l_spec                VARCHAR2(4000);
            l_id_visit            NUMBER;
        BEGIN
        
            IF i_row.flg_status <> g_cosign_flg_status_cs
            THEN
                --Documented signature                      
                l_code_label          := k_code_documented;
                l_id_prof_last_change := i_row.id_prof_created;
                l_date                := i_row.dt_created;
                l_desc_signature      := l_code_label;
            ELSE
            
                --Co-sign documented signature    
                l_code_label          := iif(i_row.flg_made_auth = k_yes, k_code_electronically, k_code_documented);
                l_id_prof_last_change := i_row.id_prof_co_signed;
                l_date                := i_row.dt_co_signed;
                l_desc_signature      := l_code_label;
            
            END IF;
        
            l_label          := pk_message.get_message(i_lang, l_code_label);
            l_desc_signature := iif(l_desc_signature IS NOT NULL, l_label, NULL);
        
            l_id_visit := pk_episode.get_id_visit(i_episode => i_row.id_episode);
            l_spec     := pk_prof_utils.get_spec_sign_by_visit(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_prof_id  => l_id_prof_last_change,
                                                               i_dt_reg   => l_date,
                                                               i_id_visit => l_id_visit);
        
            l_signature := l_desc_signature;
            l_signature := l_signature || ': ' ||
                           pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => l_id_prof_last_change);
            l_signature := l_signature || CASE
                               WHEN l_spec IS NOT NULL THEN
                                ' (' || l_spec || ')'
                           END || '; ' || pk_date_utils.date_char_tsz(i_lang, l_date, i_prof.institution, i_prof.software);
        
            --  ( signature )
            l_desc := NULL; --l_label;
            l_val  := l_signature;
            l_clob := NULL;
            l_type := 'LP';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
        END get_signature;
    
    BEGIN
    
        tbl_co_sign := pk_co_sign.tf_co_sign_tasks_info(i_lang           => i_lang,
                                                        i_prof           => i_prof,
                                                        i_tbl_id_co_sign => table_number(i_co_sign),
                                                        i_tbl_status     => NULL,
                                                        i_flg_with_desc  => 'Y');
    
        <<lup_thru_cosign>>
        FOR i IN 1 .. tbl_co_sign.count
        LOOP
        
            -- white line
            l_desc := '';
            l_val  := '';
            l_clob := NULL;
            l_type := 'WL';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
            -- header DSC_action
            l_desc := tbl_co_sign(i).desc_task_action;
            l_val  := NULL;
            l_clob := NULL;
            l_type := 'L1';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
            -- Task Title
            l_desc := tbl_co_sign(i).desc_order;
            l_val  := chr(10) || tbl_co_sign(i).desc_instructions;
            l_clob := NULL;
            l_type := 'L2B';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob, i_flg_sep => k_no);
        
            -- header DSC_STATUS
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_T012');
            l_val  := tbl_co_sign(i).desc_status;
            l_clob := NULL;
            l_type := 'L2B';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
            -- DESC_ORDER_TYPE
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M023');
            l_val  := tbl_co_sign(i).desc_order_type;
            l_clob := NULL;
            l_type := 'L2B';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
            -- DESC_PROF_ORDERED_BY
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M024');
            l_val  := tbl_co_sign(i).desc_prof_ordered_by;
            l_clob := NULL;
            l_type := 'L2B';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
            -- Ordered At
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M021');
            l_val  := pk_date_utils.dt_chr_date_hour_tsz(i_lang => i_lang,
                                                         i_date => tbl_co_sign(i).dt_ordered_by,
                                                         i_inst => i_prof.institution,
                                                         i_soft => i_prof.software);
            l_clob := NULL;
            l_type := 'L2B';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
            -- ID_PROF_CREATED ( registered by )
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M026');
            l_val  := get_prof_name(tbl_co_sign(i).id_prof_created);
            l_clob := NULL;
            l_type := 'L2B';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
            -- CO_SIGN_NOTES 
            l_flg_clob := iif(dbms_lob.getlength(tbl_co_sign(i).co_sign_notes) > 0, k_yes, k_no);
            IF l_flg_clob = k_yes
            THEN
                l_clob := tbl_co_sign(i).co_sign_notes;
                l_val  := NULL;
            ELSE
                l_clob := NULL;
                l_val  := pk_translation.get_translation(i_lang, tbl_co_sign(i).code_co_sign_notes);
            END IF;
        
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M020');
            l_type := 'L2B';
            fill_row(i_desc     => l_desc,
                     i_val      => l_val,
                     i_flg_type => l_type,
                     i_clob     => l_clob,
                     i_flg_clob => l_flg_clob);
        
            get_signature(tbl_co_sign(i));
        
            -- white line
            l_desc := '';
            l_val  := '';
            l_clob := NULL;
            l_type := 'WL';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
        END LOOP lup_thru_cosign;
    
        OPEN o_detail FOR
            SELECT t.*
              FROM TABLE(tbl_data) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            l_bool := pk_alert_exceptions.process_error(i_lang,
                                                        SQLCODE,
                                                        SQLERRM,
                                                        '',
                                                        'ALERT',
                                                        'PK_CO_SIGN',
                                                        'GET_CO_SIGN_DETAIL',
                                                        o_error);
            RETURN FALSE;
        
    END get_co_sign_detail_ux;

    FUNCTION get_co_sign_detail_ux_h
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_co_sign IN NUMBER,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        k_yes    CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        k_no     CONSTANT VARCHAR2(0010 CHAR) := 'N';
        k_update CONSTANT VARCHAR2(0200 CHAR) := 'CO_SIGN_M031'; -- sys_message
        k_new    CONSTANT VARCHAR2(0200 CHAR) := 'CO_SIGN_M032'; -- sys_message
        l_update VARCHAR2(4000);
        l_new    VARCHAR2(4000);
    
        --l_tab_dd_block_data t_tab_dd_block_data;
        --l_data_source_list  table_varchar := table_varchar();
    
        tbl_data    t_tab_dd_data := t_tab_dd_data();
        tbl_co_sign t_table_co_sign := t_table_co_sign();
    
        l_desc     VARCHAR2(4000);
        l_val      VARCHAR2(4000);
        l_type     VARCHAR2(0010 CHAR);
        l_clob     CLOB;
        l_bool     BOOLEAN;
        l_flg_clob CLOB;
    
        --****************************************
        PROCEDURE push(i_row IN t_rec_dd_data) IS
            l_count NUMBER;
        BEGIN
        
            tbl_data.extend();
            l_count := tbl_data.count;
            tbl_data(l_count) := i_row;
        
        END push;
    
        --*****************************************
        PROCEDURE fill_row
        (
            i_desc     IN VARCHAR2,
            i_val      IN VARCHAR2,
            i_flg_type IN VARCHAR2,
            i_clob     IN CLOB,
            i_flg_clob IN VARCHAR2 DEFAULT 'N',
            i_flg_sep  IN VARCHAR2 DEFAULT 'Y'
        ) IS
            l_bool BOOLEAN;
            l_row  t_rec_dd_data;
            l_desc VARCHAR2(4000);
            l_sep  VARCHAR2(0020 CHAR);
        BEGIN
        
            l_bool := i_flg_clob = k_no AND i_val IS NOT NULL;
            l_bool := l_bool OR (i_flg_clob = k_yes AND dbms_lob.getlength(i_clob) > 0);
        
            IF i_flg_type NOT IN ('LP', 'L1', 'WL')
            THEN
                l_sep := NULL;
                IF i_flg_sep = k_yes
                THEN
                    l_sep := ': ';
                END IF;
                l_desc := i_desc || l_sep;
            ELSE
                l_desc := i_desc;
            END IF;
        
            IF l_bool
               OR (i_flg_type IN ('L1', 'WL'))
            THEN
                l_row := t_rec_dd_data(descr    => l_desc, --VARCHAR2(1000 CHAR),
                                       val      => i_val, --VARCHAR2(4000 CHAR),
                                       flg_type => i_flg_type, --VARCHAR2(200 CHAR),
                                       flg_html => k_no, --VARCHAR2(1 CHAR),
                                       val_clob => i_clob, --CLOB,
                                       flg_clob => i_flg_clob --VARCHAR2(1 CHAR)
                                       );
                push(l_row);
            
            END IF;
        
        END fill_row;
    
        --***********************************
        FUNCTION iif
        (
            i_bool  IN BOOLEAN,
            i_true  IN VARCHAR2,
            i_false IN VARCHAR2
        ) RETURN VARCHAR2 IS
        BEGIN
            IF i_bool
            THEN
                RETURN i_true;
            ELSE
                RETURN i_false;
            END IF;
        END iif;
    
        --***********************************
        FUNCTION get_prof_name(i_prof IN NUMBER) RETURN VARCHAR2 IS
            tbl_name table_varchar;
            l_return VARCHAR2(4000);
        BEGIN
        
            SELECT name
              BULK COLLECT
              INTO tbl_name
              FROM professional
             WHERE id_professional = i_prof;
        
            IF tbl_name.count > 0
            THEN
                l_return := tbl_name(1);
            END IF;
        
            RETURN l_return;
        
        END get_prof_name;
    
        --****************************************************************
        PROCEDURE get_signature(i_row IN t_rec_co_sign) IS
            k_code_electronically CONSTANT VARCHAR2(0100 CHAR) := 'CO_SIGN_M029';
            k_code_documented     CONSTANT VARCHAR2(0100 CHAR) := 'CO_SIGN_M025';
            l_code_label          VARCHAR2(0200 CHAR);
            l_id_prof_last_change NUMBER;
            l_date                TIMESTAMP WITH LOCAL TIME ZONE;
            l_desc_signature      VARCHAR2(4000);
            l_label               VARCHAR2(4000);
            l_signature           VARCHAR2(4000);
            l_spec                VARCHAR2(4000);
            l_id_visit            NUMBER;
        BEGIN
        
            IF i_row.flg_status <> g_cosign_flg_status_cs
            THEN
                --Documented signature                      
                l_code_label          := k_code_documented;
                l_id_prof_last_change := i_row.id_prof_created;
                l_date                := i_row.dt_created;
                l_desc_signature      := l_code_label;
            ELSE
            
                --Co-sign documented signature    
                l_code_label          := iif(i_row.flg_made_auth = k_yes, k_code_electronically, k_code_documented);
                l_id_prof_last_change := i_row.id_prof_co_signed;
                l_date                := i_row.dt_co_signed;
                l_desc_signature      := l_code_label;
            
            END IF;
        
            l_label          := pk_message.get_message(i_lang, l_code_label);
            l_desc_signature := iif(l_desc_signature IS NOT NULL, l_label, NULL);
        
            l_id_visit := pk_episode.get_id_visit(i_episode => i_row.id_episode);
            l_spec     := pk_prof_utils.get_spec_sign_by_visit(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_prof_id  => l_id_prof_last_change,
                                                               i_dt_reg   => l_date,
                                                               i_id_visit => l_id_visit);
        
            l_signature := l_desc_signature;
            l_signature := l_signature || ': ' ||
                           pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                            i_prof    => i_prof,
                                                            i_prof_id => l_id_prof_last_change);
            l_signature := l_signature || CASE
                               WHEN l_spec IS NOT NULL THEN
                                ' (' || l_spec || ')'
                           END || '; ' || pk_date_utils.date_char_tsz(i_lang, l_date, i_prof.institution, i_prof.software);
        
            --  ( signature )
            l_desc := NULL; --l_label;
            --l_desc := l_label;
            l_val  := l_signature;
            l_clob := NULL;
            l_type := 'LP';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
        END get_signature;
    
        --********************************
        PROCEDURE process_hist
        (
            i_lang    IN NUMBER,
            i_idx     IN NUMBER,
            i_desc    IN VARCHAR2,
            i_old_val IN VARCHAR2,
            i_new_val IN VARCHAR2
        ) IS
        
            l_old_val VARCHAR2(4000);
            l_old_idx NUMBER;
            tbl_row   table_number := table_number();
            l_pos     NUMBER;
        
            tbl_data t_table_co_sign := t_table_co_sign();
        
            tbl_desc table_varchar := table_varchar();
            tbl_val  table_varchar := table_varchar();
            tbl_type table_varchar := table_varchar();
            tbl_clob table_clob := table_clob();
        
            --************************************
            PROCEDURE init_array IS
            BEGIN
                tbl_desc := table_varchar();
                tbl_val  := table_varchar();
                tbl_type := table_varchar();
                tbl_clob := table_clob();
            END init_array;
            --***********************************
            FUNCTION do_extend RETURN NUMBER IS
            BEGIN
            
                tbl_desc.extend();
                tbl_val.extend();
                tbl_type.extend();
                tbl_clob.extend();
            
                RETURN tbl_type.count;
            
            END do_extend;
        
        BEGIN
        
            init_array();
            l_desc := i_desc;
            l_val  := i_new_val;
            l_clob := NULL;
            l_type := 'L2B';
        
            IF i_idx > 1
            THEN
            
                init_array();
            
                -- check new value
                l_old_idx := i_idx - 1;
                l_old_val := i_old_val;
            
                IF l_old_val IS NULL
                   AND l_val IS NOT NULL
                THEN
                
                    l_pos := do_extend();
                
                    --tbl_row:= tbl_row( i_idx );
                
                    tbl_desc(l_pos) := l_desc || k_new;
                    tbl_val(l_pos) := l_val;
                    tbl_type(l_pos) := 'L2BN';
                
                END IF;
            
                -- check update
                l_bool := (l_old_val IS NOT NULL) AND (l_val IS NOT NULL);
                l_bool := l_bool AND (l_old_val != l_val);
                IF l_bool
                THEN
                
                    -- prepare new value
                    l_pos := do_extend();
                    tbl_desc(l_pos) := l_desc || l_update;
                    tbl_val(l_pos) := l_val;
                    tbl_type(l_pos) := 'L2BN';
                
                    -- prepare old value
                    l_pos := do_extend();
                    tbl_desc(l_pos) := l_desc;
                    tbl_val(l_pos) := l_old_val;
                    tbl_type(l_pos) := 'L2B';
                
                END IF;
            
            ELSE
                -- when i_idx = 1
                l_pos := do_extend();
            
                tbl_desc(l_pos) := l_desc;
                tbl_val(l_pos) := l_val;
                tbl_type(l_pos) := l_type;
            
            END IF;
        
            <<lup_thru_hist_lines>>
            FOR i IN 1 .. tbl_desc.count
            LOOP
            
                l_desc := tbl_desc(i);
                l_val  := tbl_val(i);
                l_clob := tbl_clob(i);
                l_type := tbl_type(i);
            
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            
            END LOOP lup_thru_hist_lines;
        
        END process_hist;
    
        --***********
        PROCEDURE fill_desc_status(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_T012');
            l_val  := tbl_co_sign(i_idx).desc_status;
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_co_sign(l_pos).desc_status;
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END fill_desc_status;
    
        PROCEDURE fill_desc_task(i_idx IN NUMBER) IS
        BEGIN
        
            -- Task Title
            l_desc := tbl_co_sign(i_idx).desc_order;
            l_val  := chr(10) || tbl_co_sign(i_idx).desc_instructions;
            l_clob := NULL;
            l_type := 'L2B';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob, i_flg_sep => k_no);
        
        END fill_desc_task;
    
        --***********************************
        PROCEDURE fill_desc_order_type(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M023');
            l_val  := tbl_co_sign(i_idx).desc_order_type;
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_co_sign(l_pos).desc_order_type;
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END fill_desc_order_type;
    
        --*****************************
        PROCEDURE fill_desc_prof_ordered_by(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M024');
            l_val  := tbl_co_sign(i_idx).desc_prof_ordered_by;
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := tbl_co_sign(l_pos).desc_prof_ordered_by;
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END fill_desc_prof_ordered_by;
    
        --******************
        PROCEDURE fill_registered_by(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            -- ID_PROF_CREATED ( regsitered by )
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M026');
            l_val  := get_prof_name(tbl_co_sign(i_idx).id_prof_created);
        
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := get_prof_name(tbl_co_sign(l_pos).id_prof_created);
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END fill_registered_by;
    
        PROCEDURE fill_dt_created(i_idx IN NUMBER) IS
            l_desc    VARCHAR2(4000);
            l_val     VARCHAR2(4000);
            l_old_val VARCHAR2(4000);
            l_pos     NUMBER;
        BEGIN
        
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M021');
            l_val  := pk_date_utils.date_char_tsz(i_lang,
                                                  tbl_co_sign(i_idx).dt_created,
                                                  i_prof.institution,
                                                  i_prof.software);
            IF i_idx > 1
            THEN
                l_pos     := i_idx - 1;
                l_old_val := pk_date_utils.date_char_tsz(i_lang,
                                                         tbl_co_sign(l_pos).dt_created,
                                                         i_prof.institution,
                                                         i_prof.software);
            END IF;
        
            process_hist(i_lang    => i_lang,
                         i_idx     => i_idx,
                         i_desc    => l_desc,
                         i_old_val => l_old_val,
                         i_new_val => l_val);
        
        END fill_dt_created;
    
        --****************************
        PROCEDURE fill_co_sign_notes(i_idx IN NUMBER) IS
        BEGIN
        
            l_flg_clob := iif(dbms_lob.getlength(tbl_co_sign(i_idx).co_sign_notes) > 0, k_yes, k_no);
            IF l_flg_clob = k_yes
            THEN
                l_clob := tbl_co_sign(i_idx).co_sign_notes;
                l_val  := NULL;
            ELSE
                l_clob := NULL;
                l_val  := pk_translation.get_translation(i_lang, tbl_co_sign(i_idx).code_co_sign_notes);
            END IF;
        
            l_desc := pk_message.get_message(i_lang, 'CO_SIGN_M020');
            l_type := 'L2B';
            fill_row(i_desc     => l_desc,
                     i_val      => l_val,
                     i_flg_type => l_type,
                     i_clob     => l_clob,
                     i_flg_clob => l_flg_clob);
        
        END fill_co_sign_notes;
    
        --***************************
        PROCEDURE fill_empty_line(i_idx IN NUMBER) IS
        BEGIN
        
            l_desc := '';
            l_val  := '';
            l_clob := NULL;
            l_type := 'WL';
            fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
        
        END fill_empty_line;
    
        PROCEDURE fill_title(i_idx IN NUMBER) IS
        BEGIN
        
            IF i_idx = tbl_co_sign.count
            THEN
                -- header DSC_STATUS
                --l_desc := pk_message.get_message(i_lang, 'CO_SIGN_T006');
                l_desc := tbl_co_sign(i_idx).desc_task_action;
                l_val  := NULL;
                l_clob := NULL;
                l_type := 'L1';
                fill_row(i_desc => l_desc, i_val => l_val, i_flg_type => l_type, i_clob => l_clob);
            END IF;
        
        END fill_title;
    
    BEGIN
    
        -- ( updated)
        l_update := pk_message.get_message(i_lang, 'CO_SIGN_M031');
        -- (new)
        l_new := pk_message.get_message(i_lang, 'CO_SIGN_M032');
    
        tbl_co_sign := pk_co_sign.tf_co_sign_tasks_hist_info(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_tbl_id_co_sign => table_number(i_co_sign),
                                                             i_tbl_status     => table_varchar('P', 'CS'),
                                                             i_flg_with_desc  => k_yes);
    
        <<lup_thru_cosign>>
        FOR i IN REVERSE 1 .. tbl_co_sign.count
        LOOP
        
            fill_title(i);
        
            -- task
            fill_desc_task(i);
        
            -- header DSC_STATUS
            fill_desc_status(i);
        
            -- DESC_ORDER_TYPE
            fill_desc_order_type(i);
        
            -- DESC_PROF_ORDERED_BY
            fill_desc_prof_ordered_by(i);
        
            -- ordered at
            fill_dt_created(i);
        
            -- ID_PROF_CREATED ( regsitered by )
            fill_registered_by(i);
        
            -- CO_SIGN_NOTES 
            fill_co_sign_notes(i);
        
            get_signature(tbl_co_sign(i));
        
            -- empty line
            fill_empty_line(i);
        
        END LOOP lup_thru_cosign;
    
        OPEN o_detail FOR
            SELECT t.*
              FROM TABLE(tbl_data) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_detail);
            l_bool := pk_alert_exceptions.process_error(i_lang,
                                                        SQLCODE,
                                                        SQLERRM,
                                                        '',
                                                        'ALERT',
                                                        'PK_CO_SIGN',
                                                        'GET_CO_SIGN_DETAIL_H',
                                                        o_error);
            RETURN FALSE;
        
    END get_co_sign_detail_ux_h;

BEGIN

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

    inicialize();

END pk_co_sign;
/
