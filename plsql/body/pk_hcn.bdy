/*-- Last Change Revision: $Rev: 2027192 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_hcn IS

    /********************************************************************************************
    * Esta fun��o devolve um array com os pontos de HCN correspondentes a cada item da avalia��o
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     Episode id
    * @param i_doc_area    ID da avalia��o
    * @param i_id_dept     ID do servi�o
    * @param i_doc_templ   ID do template
    *
    * @param o_points      Array com os pontos de HCN correspondentes a cada item da avalia��o
    * @param o_hcn         Array com a tabela que relaciona os pontos com as horas de HCN
    * @param o_error       Mensagem de erro
    *
    * @return                Array com os pontos de HCN correspondentes a cada item da avalia��o
    *
    * @author                Pedro Lopes
    * @version               1.0
    * @since                 2008/03/17
     ********************************************************************************************/

    FUNCTION get_eval_hcn_points_template
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_id_dept  IN department.id_department%TYPE,
        i_id_templ IN doc_template.id_doc_template%TYPE,
        o_points   OUT pk_types.cursor_type,
        o_hcn      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_dept department.id_department%TYPE := i_id_dept;
    BEGIN
    
        IF (i_id_dept IS NULL)
        THEN
            g_error   := 'CALL pk_episode.get_epis_department. i_episode: ' || i_episode;
            l_id_dept := pk_episode.get_epis_department(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        END IF;
    
        --Abre array com o valor dos pontos da avalia��o
        g_error := 'OPEN CURSOR O_POINTS';
        OPEN o_points FOR
            SELECT dec.id_doc_element_crit, de.score AS num_points --cr.num_points
              FROM doc_element de
             INNER JOIN documentation d
                ON de.id_documentation = d.id_documentation
             INNER JOIN doc_element_crit DEC
                ON dec.id_doc_element = de.id_doc_element
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_documentation = d.id_documentation
             WHERE dtad.id_doc_area = i_doc_area
               AND dtad.id_doc_template = i_id_templ
               AND d.flg_available = pk_alert_constant.g_available
               AND de.flg_available = pk_alert_constant.g_available
               AND dec.id_doc_criteria = 1
               AND dec.flg_available = pk_alert_constant.g_available
             ORDER BY dec.id_doc_element_crit;
    
        --Obter a tabela que relaciona os pontos com as horas de HCN
        OPEN o_hcn FOR
            SELECT points_min_value, points_max_value, num_hcn
              FROM hcn_def_points p
             WHERE id_department = l_id_dept
               AND id_institution IN (i_prof.institution, 0)
               AND id_software IN (i_prof.software, 0);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_EVAL_HCN_POINTS_TEMPLATE');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_points);
                pk_types.open_my_cursor(o_hcn);
                RETURN FALSE;
            END;
        
    END get_eval_hcn_points_template;

    /********************************************************************************************
    * Esta fun��o devolve a informa��o respeitante �s avalia��es dos cuidados de enfermagem,
    *  incluindo o ID_DOC_AREA respeitante ao servi�o a que est� alocado o paciente
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    *
    * @param o_det         Array com o detalhe da avalia��o
    * @param o_eval        Array com o cabe�alho da avalia��o
    * @param o_id_dept     ID do servi�o ao qual o paciente est� alocado
    * @param o_id_doc_area ID da DOC_AREA
    * @param o_flg_show    Indica se deve ou n�o mostrar mensagem de aviso ao criar nova avalia��o
    * @param o_msg_result  Mensagem de aviso a ser mostrada
    * @param o_title       T�tulo da mensagem de aviso
    * @param o_button      Bot�es a mostrar no aviso
    * @param o_error       Mensagem de erro
    *
    * @return                Array com os pontos de HCN correspondentes a cada item da avalia��o
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/03/27
       ********************************************************************************************/

    FUNCTION get_eval_summ_page
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_det        OUT pk_types.cursor_type,
        o_eval       OUT pk_types.cursor_type,
        o_id_dept    OUT department.id_department%TYPE,
        o_doc_area   OUT pk_types.cursor_type,
        o_flg_show   OUT VARCHAR2,
        o_msg_result OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_eval PLS_INTEGER;
        l_num_serv PLS_INTEGER;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        --ET 2007/05/09
        o_flg_show := 'N';
        IF i_prof.software NOT IN
           (pk_sysconfig.get_config('SOFTWARE_ID_EDIS', i_prof), pk_sysconfig.get_config('SOFTWARE_ID_UBU', i_prof))
        THEN
            --Obt�m o servi�o ao qual o paciente est� alocado
            g_error := 'GET DEPARTMENT';
            BEGIN
                SELECT d.id_department
                  INTO o_id_dept
                  FROM epis_info ei, dep_clin_serv d
                 WHERE ei.id_episode = i_episode
                   AND d.id_dep_clin_serv = ei.id_dep_clin_serv;
            
            EXCEPTION
                WHEN no_data_found THEN
                    --ET 2007/05/09
                    pk_types.open_my_cursor(o_det);
                    pk_types.open_my_cursor(o_eval);
                    pk_types.open_my_cursor(o_doc_area);
                    --O paciente n�o est� alocado a nenhum servi�o
                    RETURN FALSE;
            END;
        END IF;
    
        --Obt�m a DOC_AREA atrav�s do servi�o ao qual o paciente est� alocado
        g_error := 'GET DOC_AREA';
        OPEN o_doc_area FOR
            SELECT hd.id_doc_area data, '' --s.desc_val label
              FROM hcn_docarea_dept hd --, sys_domain s
             WHERE hd.id_department = o_id_dept
                  --AND s.code_domain = 'HCN_DOCAREA_DEPT.ID_DOC_AREA'
                  --AND s.id_language = i_lang
                  --AND s.val = hd.id_doc_area
               AND hd.flg_available = g_yes; --PLLopes 17-03-2009 ALERT-19098
    
        --Abre o array com o cabe�alho da avalia��o
        g_error := 'OPEN O_EVAL ARRAY';
        OPEN o_eval FOR
            SELECT pk_date_utils.dt_chr_tsz(i_lang, nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz), i_prof) dt_register,
                   --p.nick_name, --ALERT-10363
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS nick_name,
                   pk_date_utils.date_send_tsz(i_lang, nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz), i_prof) last_date,
                   pk_date_utils.dt_chr_hour_tsz(i_lang, nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz), i_prof) hour_eval,
                   ed.id_epis_documentation,
                   pk_hcn.get_eval_total_points(ed.id_epis_documentation) tot_pnt,
                   (SELECT num_hcn
                      FROM hcn_def_points dp, hcn_eval he
                     WHERE he.id_epis_documentation = ed.id_epis_documentation
                       AND dp.id_department = he.id_department
                       AND nvl(pk_hcn.get_eval_total_points(ed.id_epis_documentation), 0) BETWEEN points_min_value AND
                           points_max_value) num_hcn,
                   ed.id_doc_template,
                   pk_translation.get_translation(i_lang, dtem.code_doc_template) AS templ_desc,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_creation_tstz,
                                                    ed.id_episode) desc_speciality
              FROM epis_documentation ed,
                   professional p,
                   (SELECT DISTINCT id_doc_area
                      FROM hcn_docarea_dept
                     WHERE flg_available = g_yes) dt,
                   doc_template dtem
             WHERE ed.id_episode = i_episode
               AND ed.id_doc_area = dt.id_doc_area
               AND ed.flg_status = g_active
               AND ed.id_doc_template = dtem.id_doc_template --PLLopes 18-03-2009 ALERT-19098
               AND p.id_professional = nvl(ed.id_prof_last_update, ed.id_professional)
             ORDER BY 3 DESC;
    
        --Abre o array com o detalhe das avalia��es
        g_error := 'OPEN O_DET ARRAY';
        OPEN o_det FOR
            SELECT dtad.rank,
                   ed.id_epis_documentation,
                   decr.id_doc_element_crit,
                   pk_translation.get_translation(i_lang, code_doc_component) d_comp,
                   pk_touch_option.get_element_description(i_lang,
                                                           i_prof,
                                                           de.flg_type,
                                                           edd.value,
                                                           edd.value_properties,
                                                           decr.id_doc_element_crit,
                                                           de.id_unit_measure_reference,
                                                           de.id_master_item,
                                                           decr.code_element_close) d_crit,
                   '(' || decode(de.score,
                                 1,
                                 nvl(de.score, 0) || ' ' || pk_message.get_message(i_lang, 'HCN_LABEL_T007'),
                                 nvl(de.score, 0) || ' ' || pk_message.get_message(i_lang, 'HCN_LABEL_T005')) || ')' d_pontos
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN documentation d
                ON d.id_documentation = edd.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
             INNER JOIN (SELECT DISTINCT id_doc_area
                           FROM hcn_docarea_dept
                          WHERE flg_available = g_yes) dt
                ON ed.id_doc_area = dt.id_doc_area
             WHERE ed.id_episode = i_episode
               AND ed.flg_status = g_active
             ORDER BY dtad.rank;
    
        --Verifica se a �ltima avalia��o DE HOJE j� foi alocada a enfermeiros. Se sim, d� uma mensagem de aviso
        SELECT COUNT(*)
          INTO l_num_eval
          FROM hcn_eval e, hcn_eval_det d
         WHERE e.flg_status = g_active
           AND e.id_episode = i_episode
           AND trunc(e.dt_eval_tstz) = trunc(g_sysdate_tstz)
           AND d.id_hcn_eval = e.id_hcn_eval
           AND d.flg_type = 'P'
           AND d.flg_status = g_active;
    
        IF nvl(l_num_eval, 0) > 0
        THEN
            o_flg_show   := 'Y';
            o_title      := pk_message.get_message(i_lang, 'HCN_LABEL_T010');
            o_msg_result := pk_message.get_message(i_lang, 'HCN_LABEL_T011');
            o_button     := 'NC';
        END IF;
    
        --Verifica se o servi�o ao qual o paciente est� alocado j� est� parametrizado
        SELECT COUNT(*)
          INTO l_num_serv
          FROM hcn_docarea_dept hd --, sys_domain s
         WHERE hd.id_department = o_id_dept
              --AND s.code_domain = 'HCN_DOCAREA_DEPT.ID_DOC_AREA'
              --AND s.id_language = i_lang
              --AND s.val = hd.id_doc_area
           AND hd.flg_available = g_yes;
    
        IF nvl(l_num_serv, 0) = 0
        THEN
            o_flg_show   := 'Y';
            o_title      := pk_message.get_message(i_lang, 'HCN_LABEL_T035');
            o_msg_result := pk_message.get_message(i_lang, 'HCN_LABEL_T036');
            o_button     := 'C';
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_EVAL_SUMM_PAGE');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_det);
                pk_types.open_my_cursor(o_eval);
                pk_types.open_my_cursor(o_doc_area);
                RETURN FALSE;
            END;
        
    END get_eval_summ_page;

    /********************************************************************************************
    * Esta fun��o devolve o total de pontos de uma avalia��o de HCN
    *
    * @param i_id_epis_documentation    ID da avalia��o
    *
    * @return               Total de pontos de uma avalia��o de HCN
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/04/04
       ********************************************************************************************/

    FUNCTION get_eval_total_points(i_epis_documentation IN episode.id_episode%TYPE) RETURN NUMBER IS
    
        l_tot_points NUMBER(6, 3);
    
    BEGIN
    
        --Obt�m o total de pontos e as HCN correspondentes
        g_error := 'GET POINTS';
        SELECT SUM(de.score)
          INTO l_tot_points
          FROM epis_documentation ed, epis_documentation_det dd, doc_element_crit c, doc_element de --, hcn_def_crit h
         WHERE ed.id_epis_documentation = i_epis_documentation
           AND dd.id_epis_documentation = ed.id_epis_documentation
           AND c.id_doc_element_crit = dd.id_doc_element_crit
           AND c.id_doc_criteria = 1
           AND de.id_doc_element = c.id_doc_element;
        --AND h.internal_name = de.internal_name --PLLopes 13/3/2009 ALERT-19098 
        --AND h.id_doc_element = de.id_doc_element;
    
        RETURN l_tot_points;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END;

    /********************************************************************************************
    * Esta fun��o guarda uma nova avalia��o de HCN e verifica que s� a �ltima fica activa.
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_dt_eval     Data do dia (por defeito � a data de sistema)
    * @param i_department  ID do servi�o a que o paciente est� alocado
    *
    * @return
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/04/04
       ********************************************************************************************/

    FUNCTION set_eval_hcn
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_dt_eval    IN VARCHAR2,
        i_department IN department.id_department%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --Cursor com todas as avalia��es do dia para garantir que s� a �ltima est� activa
        CURSOR c_all_eval IS
            SELECT e.id_epis_documentation,
                   e.id_episode,
                   e.id_professional,
                   e.dt_creation_tstz,
                   e.dt_last_update_tstz,
                   e.id_prof_last_update,
                   e.flg_status,
                   e.id_doc_area,
                   e.dt_cancel_tstz,
                   e.id_prof_cancel,
                   e.notes_cancel,
                   pk_hcn.get_eval_total_points(e.id_epis_documentation) tot_points
              FROM epis_documentation e,
                   (SELECT DISTINCT id_doc_area
                      FROM hcn_docarea_dept
                     WHERE flg_available = g_yes) dt
             WHERE e.id_episode = i_episode
               AND e.flg_status = g_active
               AND e.id_doc_area = dt.id_doc_area
               AND pk_date_utils.trunc_insttimezone(i_prof, e.dt_creation_tstz, NULL) =
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                    nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_eval, NULL),
                                                        current_timestamp))
             ORDER BY id_epis_documentation DESC;
    
        l_count PLS_INTEGER;
        --l_error       VARCHAR2(2000);
        l_error       t_error_out;
        l_first       BOOLEAN;
        l_id_hcn_eval hcn_eval.id_hcn_eval%TYPE;
    
        l_dt_cancel      DATE;
        l_dt_cancel_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_prof_cancel professional.id_professional%TYPE;
        l_ed_rows        table_varchar;
    
        l_id_department department.id_department%TYPE := i_department;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF (i_department IS NULL)
        THEN
            g_error         := 'CALL pk_episode.get_epis_department. i_episode: ' || i_episode;
            l_id_department := pk_episode.get_epis_department(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_episode);
        END IF;
    
        --Obt�m o id_epis_documentation da �ltima avalia��o de HCN
        l_first := TRUE;
        FOR i IN c_all_eval
        LOOP
        
            --Verifica se a avalia��o j� existe nas tabelas de HCN
            g_error := 'CHECK HCN_EVAL';
            SELECT COUNT(*)
              INTO l_count
              FROM hcn_eval
             WHERE id_episode = i_episode
               AND id_epis_documentation = i.id_epis_documentation;
        
            IF nvl(l_count, 0) = 0
            THEN
                --A avalia��o ainda n�o existe e vai ser inserida
                SELECT seq_hcn_eval.nextval
                  INTO l_id_hcn_eval
                  FROM dual;
            
                g_error := 'INSERT HCN_EVAL';
                INSERT INTO hcn_eval
                    (id_hcn_eval,
                     id_episode,
                     id_epis_documentation,
                     dt_eval_tstz,
                     flg_status,
                     dt_cancel_tstz,
                     id_prof_cancel,
                     total_points,
                     id_department)
                VALUES
                    (l_id_hcn_eval,
                     i_episode,
                     i.id_epis_documentation,
                     i.dt_last_update_tstz,
                     i.flg_status,
                     i.dt_cancel_tstz,
                     i.id_prof_cancel,
                     i.tot_points,
                     l_id_department);
            ELSE
                --A Avalia��o j� existe. Verifica o estado e actualiza-o de for diferente
                g_error := 'UPDATE HCN_EVAL';
                UPDATE hcn_eval
                   SET dt_eval_tstz   = i.dt_creation_tstz,
                       flg_status     = i.flg_status,
                       dt_cancel_tstz = i.dt_cancel_tstz,
                       id_prof_cancel = i.id_prof_cancel,
                       total_points   = i.tot_points
                 WHERE id_epis_documentation = i.id_epis_documentation
                   AND id_episode = i_episode
                   AND (flg_status != i.flg_status OR dt_eval_tstz != i.dt_creation_tstz OR
                       total_points != i.tot_points);
            
            END IF;
        
            --Verifica que s� a �ltima avalia��o fica com o estado Activo
            IF l_first
            THEN
                --� a �ltima avalia��o de hoje por isso fica activa
                l_first := FALSE;
                --A data e profissional de cancelamento s�o os de cria��o da �ltima avalia��o, j� que a �ltima
                --  avalia��o cancela as avalia��es anteriores do dia.
                l_dt_cancel_tstz := i.dt_creation_tstz;
                l_id_prof_cancel := i.id_professional;
            ELSE
                --N�o � a �ltima avalia��o de hoje por isso cancela-a
                g_error := 'CANCEL EPIS_DOCUMENTATION';
                ts_epis_documentation.upd(id_epis_documentation_in => i.id_epis_documentation,
                                          flg_status_in            => g_inactive,
                                          dt_cancel_tstz_in        => l_dt_cancel_tstz,
                                          id_prof_cancel_in        => l_id_prof_cancel,
                                          rows_out                 => l_ed_rows);
            
                g_error := 'CANCEL HCN_EVAL';
                UPDATE hcn_eval
                   SET flg_status = g_inactive, dt_cancel_tstz = l_dt_cancel_tstz, id_prof_cancel = l_id_prof_cancel
                 WHERE id_epis_documentation = i.id_epis_documentation;
            
            END IF;
        
        END LOOP;
    
        g_error := 'CALL process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DOCUMENTATION',
                                      i_rowids       => l_ed_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS', 'DT_CANCEL_TSTZ', 'ID_PROF_CANCEL'));
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => l_error)
        THEN
            o_error := l_error;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'SET_EVAL_HCN');
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                pk_utils.undo_changes; --ALERT-25017 
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************
    * Esta fun��o actualiza a tabela hcn_eval quando uma avalia��o � cancelada
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_epis_documentation     ID da avalia��o
    * @param i_dt_eval     Data do dia (por defeito � a data de sistema)
    *
    * @return
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/04/04
       ********************************************************************************************/

    FUNCTION cancel_eval_hcn
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_eval IS
            SELECT e.id_epis_documentation, e.id_episode, e.dt_cancel_tstz, e.id_prof_cancel, e.notes_cancel
              FROM epis_documentation e
             WHERE e.id_epis_documentation = i_epis_documentation
             ORDER BY id_epis_documentation DESC;
    
        --l_error   VARCHAR2(2000);
        l_error t_error_out;
    
        l_episode episode.id_episode%TYPE;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN c_eval
        LOOP
            --Cancela avalia��o HCN
            l_episode := i.id_episode;
        
            UPDATE hcn_eval
               SET flg_status = g_cancel, dt_cancel_tstz = i.dt_cancel_tstz, id_prof_cancel = i_prof.id
             WHERE id_epis_documentation = i.id_epis_documentation;
        
            UPDATE hcn_eval_det
               SET flg_status = g_cancel, id_prof_cancel = i_prof.id, dt_cancel_tstz = i.dt_cancel_tstz
             WHERE id_hcn_eval IN (SELECT id_hcn_eval
                                     FROM hcn_eval
                                    WHERE id_epis_documentation = i.id_epis_documentation);
        
        END LOOP;
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_episode,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => l_error)
        THEN
            o_error := l_error;
            RETURN FALSE;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'CANCEL_EVAL_HCN');
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                pk_utils.undo_changes; --ALERT-25017 
                RETURN FALSE;
            END;
    END;

    /********************************************************************************************
    * Esta fun��o disponibiliza o detalhe das avalia��es de um epis�dio
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    *
    * @param o_eval        Array com o cabe�alho das avalia��es
    * @param o_det         Array com o detalhe das avalia��es
    *
    * @return
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/04/04
       ********************************************************************************************/

    FUNCTION get_eval_hcn_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_eval    OUT pk_types.cursor_type,
        o_det     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Abre o array com o cabe�alho da avalia��o
        g_error := 'OPEN O_EVAL ARRAY';
        OPEN o_eval FOR
            SELECT pk_date_utils.dt_chr_tsz(i_lang, nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz), i_prof) dt_eval,
                   pk_date_utils.dt_chr_hour_tsz(i_lang, nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz), i_prof) hour_eval,
                   --p.nick_name, ALERT-10363
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS nick_name,
                   nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz) last_date,
                   pk_date_utils.dt_chr_tsz(i_lang, ed.dt_cancel_tstz, i_prof) dt_cancel,
                   pk_date_utils.dt_chr_hour_tsz(i_lang, ed.dt_cancel_tstz, i_prof) hour_cancel,
                   ed.id_epis_documentation,
                   ed.flg_status,
                   --pc.name prof_cancel, --ALERT -10363
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pc.id_professional) AS prof_cancel,
                   pk_hcn.get_eval_total_points(ed.id_epis_documentation) tot_pnt,
                   (SELECT num_hcn
                      FROM hcn_def_points dp, hcn_eval he
                     WHERE he.id_epis_documentation = ed.id_epis_documentation
                       AND dp.id_department = he.id_department
                       AND nvl(pk_hcn.get_eval_total_points(ed.id_epis_documentation), 0) BETWEEN points_min_value AND
                           points_max_value) num_hcn,
                   ed.id_doc_template,
                   pk_translation.get_translation(i_lang, dtem.code_doc_template) AS templ_desc,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    ed.id_professional,
                                                    ed.dt_creation_tstz,
                                                    ed.id_episode) desc_speciality
              FROM epis_documentation ed,
                   professional p,
                   professional pc,
                   (SELECT DISTINCT id_doc_area
                      FROM hcn_docarea_dept
                     WHERE flg_available = g_yes) dt,
                   doc_template dtem
             WHERE ed.id_episode = i_episode
               AND ed.id_doc_area = dt.id_doc_area
               AND ed.id_doc_template = dtem.id_doc_template --ALERT-20265, Pllopes 18-03-2009 
               AND p.id_professional = nvl(ed.id_prof_last_update, ed.id_professional)
               AND pc.id_professional(+) = ed.id_prof_cancel
             ORDER BY 7 DESC;
    
        --Abre o array com o detalhe das avalia��es
        g_error := 'OPEN O_DET ARRAY';
        OPEN o_det FOR
            SELECT dtad.rank,
                   ed.id_epis_documentation,
                   decr.id_doc_element_crit,
                   pk_translation.get_translation(i_lang, code_doc_component) || ':' d_comp,
                   pk_touch_option.get_element_description(i_lang,
                                                           i_prof,
                                                           de.flg_type,
                                                           edd.value,
                                                           edd.value_properties,
                                                           decr.id_doc_element_crit,
                                                           de.id_unit_measure_reference,
                                                           de.id_master_item,
                                                           decr.code_element_close) d_crit,
                   '(' || decode(de.score,
                                 1,
                                 nvl(de.score, 0) || ' ' || pk_message.get_message(i_lang, 'HCN_LABEL_T007'),
                                 nvl(de.score, 0) || ' ' || pk_message.get_message(i_lang, 'HCN_LABEL_T005')) || ')' d_pontos
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN documentation d
                ON d.id_documentation = edd.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             INNER JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
             INNER JOIN (SELECT DISTINCT id_doc_area
                           FROM hcn_docarea_dept
                          WHERE flg_available = g_yes) dt
                ON ed.id_doc_area = dt.id_doc_area
             WHERE ed.id_episode = i_episode
             ORDER BY ed.id_epis_documentation DESC, dtad.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_EVAL_HCN_DETAIL');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_det);
                pk_types.open_my_cursor(o_eval);
                RETURN FALSE;
            END;
        
    END get_eval_hcn_detail;

    /********************************************************************************************
    * Esta fun��o devolve o hist�rio de HCN do paciente, composto por todos os pontos e HCN de
    * todas as avalia��es realizadas bem como as m�dias calculadas, de forma a mostrar no viewer
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    *
    * @param o_hcn         Array com os valores hist�ricos de pontos e HCN
    * @param o_error       Mensagem de erro
    *
    * @return                Array com os pontos de HCN correspondentes a cada item da avalia��o
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/04/20
       ********************************************************************************************/

    FUNCTION get_eval_hcn_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_hcn     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_HCN ARRAY';
        OPEN o_hcn FOR
            SELECT he.dt_eval_tstz, he.total_points, hdp.num_hcn
              FROM epis_documentation ed,
                   hcn_eval he,
                   hcn_def_points hdp,
                   (SELECT DISTINCT id_doc_area, id_department
                      FROM hcn_docarea_dept
                     WHERE flg_available = g_yes) dpt
             WHERE he.id_episode = i_episode
               AND he.flg_status = g_active
               AND ed.id_epis_documentation = he.id_epis_documentation
               AND ed.id_doc_area = dpt.id_doc_area
               AND hdp.id_department = dpt.id_department
               AND hdp.id_institution IN (0, i_prof.institution)
               AND hdp.id_software IN (0, i_prof.software)
               AND he.id_department = dpt.id_department
               AND he.total_points BETWEEN hdp.points_min_value AND hdp.points_max_value;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_EVAL_HCN_HIST');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_hcn);
                RETURN FALSE;
            END;
        
    END get_eval_hcn_hist;

    /********************************************************************************************
    * Esta fun��o a informa��o necess�ria � constru��o do ecr� de distibui��o dos doentes pelos
    *   enfermeiros.
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    *
    * @param o_pat         Array com doentes do servi�o e respectivas aloca��es
    * @param o_nurse       Array com os enfermeiros do servi�o
    * @param o_rel         Array com a rela��o entre os doentes e enfermeiros
    *
    * @return                Arrays com os doentes do servi�o e respectivas aloca��es e com os
    *                        enfermeiros do servi�o, quer estejam alocados ou n�o
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/04/23
       ********************************************************************************************/

    FUNCTION get_hcn_pat_dist
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_pat   OUT pk_types.cursor_type,
        o_nurse OUT pk_types.cursor_type,
        o_rel   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        --Abre array com os pacientes do servi�o ao qual o enfermeiro est� alocado. Devolve ainda o total de horas de enfermagem
        --  determinado pela avalia��o HCN feita.
        g_error := 'OPEN O_PAT ARRAY';
        OPEN o_pat FOR
            SELECT epis.id_episode id_episode,
                   e.id_hcn_eval,
                   nvl((dpt.rank * 100000), 0) + nvl((ro.rank * 1000), 0) + nvl(bd.rank, 99) rank,
                   nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) desc_bed,
                   nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                       nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                   decode(pk_patphoto.check_blob(pat.id_patient),
                          'N',
                          '',
                          pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   pk_patient.get_gender(i_lang, pat.gender) gender,
                   pk_patient.get_pat_age(i_lang,
                                          pat.dt_birth,
                                          pat.dt_deceased,
                                          pat.age,
                                          i_prof.institution,
                                          i_prof.software) pat_age,
                   pat.id_patient id_patient,
                   
                   pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, epis.id_episode) desc_diagnosis,
                   decode(pk_date_utils.trunc_insttimezone(i_prof, e.dt_eval_tstz, NULL),
                          pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL),
                          'Y',
                          'N') flg_today,
                   (SELECT dp.num_hcn
                      FROM hcn_eval e, hcn_def_points dp, epis_documentation d
                     WHERE e.flg_status = g_active
                       AND e.id_episode = epis.id_episode
                       AND d.id_epis_documentation = e.id_epis_documentation
                       AND pk_date_utils.trunc_insttimezone(i_prof, d.dt_creation_tstz, NULL) =
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
                       AND dp.id_department = e.id_department
                       AND e.total_points BETWEEN dp.points_min_value AND dp.points_max_value) num_hcn,
                   pk_hcn.get_hcn_from_points(i_prof, e.id_hcn_eval) num_hours,
                   decode((SELECT COUNT(*)
                            FROM hcn_eval_det hed
                           WHERE hed.id_hcn_eval = e.id_hcn_eval),
                          0,
                          g_no,
                          g_yes) flg_nurse, --Patient already allocated to nurse
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon
              FROM patient            pat,
                   department         dpt,
                   episode            epis,
                   epis_info          ei,
                   bed                bd,
                   room               ro,
                   hcn_eval           e,
                   epis_documentation d
             WHERE epis.id_episode = ei.id_episode
               AND bd.id_bed(+) = ei.id_bed
               AND ro.id_room(+) = bd.id_room
               AND ro.id_department = dpt.id_department(+)
               AND epis.id_patient = pat.id_patient
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, i_prof.institution) = i_prof.software
               AND epis.id_epis_type = g_inp_epis_type
               AND epis.dt_begin_tstz < (pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL) + 1)
               AND ei.id_dep_clin_serv IN (SELECT dcs1.id_dep_clin_serv
                                             FROM prof_dep_clin_serv pdc1, dep_clin_serv dcs1, department dpt
                                            WHERE pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
                                              AND pdc1.flg_status = g_selected
                                              AND dpt.id_department = dcs1.id_department
                                              AND pdc1.id_professional = i_prof.id
                                              AND dpt.id_institution = i_prof.institution
                                              AND instr(dpt.flg_type, 'I') > 0)
               AND epis.flg_status = g_active
               AND e.flg_status(+) = g_active
               AND e.id_episode(+) = epis.id_episode
               AND (e.dt_eval_tstz = (SELECT MAX(e1.dt_eval_tstz)
                                        FROM hcn_eval e1
                                       WHERE e1.flg_status = g_active
                                         AND e1.id_episode = e.id_episode) OR NOT EXISTS
                    (SELECT 1
                       FROM hcn_eval e1
                      WHERE e1.flg_status = g_active
                        AND e1.id_episode = e.id_episode))
               AND d.id_epis_documentation(+) = e.id_epis_documentation
             ORDER BY pat.name;
    
        --Abre array com os enfermeiros do turno de hoje deste servi�o, quer estejam ou n�o "logados" no Alert
        g_error := 'OPEN O_NURSE ARRAY';
        OPEN o_nurse FOR
            SELECT p.id_professional,
                   --p.nick_name, --ALERT-10363
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS nick_name,
                   pdcs.id_dep_clin_serv,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) professional_photo,
                   (SELECT SUM(pk_hcn.get_hcn_from_points(i_prof, he.id_hcn_eval))
                      FROM hcn_eval_det hd, hcn_eval he
                     WHERE id_professional = p.id_professional
                       AND pk_date_utils.trunc_insttimezone(i_prof, hd.dt_aloc_prof_tstz, NULL) =
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
                       AND hd.flg_status = 'A'
                       AND hd.flg_type = g_flg_type_pat
                       AND he.id_hcn_eval = hd.id_hcn_eval
                       AND he.flg_status = g_active) total_hours
              FROM prof_dep_clin_serv pdcs,
                   professional p,
                   category c,
                   prof_cat pc,
                   (SELECT DISTINCT pdcs1.id_dep_clin_serv
                      FROM prof_dep_clin_serv pdcs1, dep_clin_serv dcs1, department dpt1
                     WHERE pdcs1.id_professional = i_prof.id
                       AND pdcs1.flg_status = g_selected --Seleccionado pelo utilizador no tools
                       AND pdcs1.flg_default = g_default_y
                       AND dcs1.id_dep_clin_serv = pdcs1.id_dep_clin_serv
                       AND dpt1.id_department = dcs1.id_department
                       AND dpt1.id_institution = i_prof.institution
                       AND instr(dpt1.flg_type, 'I') > 0) pc
             WHERE pdcs.id_dep_clin_serv = pc.id_dep_clin_serv
               AND p.id_professional = pdcs.id_professional
               AND pc.id_professional = p.id_professional
               AND pc.id_institution IN (0, i_prof.institution)
               AND c.id_category = pc.id_category
               AND c.flg_type = g_cat_type_nurse
               AND NOT EXISTS (SELECT 1 --N�o devolver enfermeiros que estejam de folga neste dia
                      FROM hcn_eval_det hd
                     WHERE hd.id_professional = p.id_professional
                       AND pk_date_utils.trunc_insttimezone(i_prof, hd.dt_aloc_prof_tstz, NULL) =
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
                       AND hd.flg_type != g_hcn_type_pat
                       AND hd.flg_status = g_active);
    
        --abre array com a associa��o entre os pacientes e os enfermeiros
        g_error := 'OPEN O_REL ARRAY';
        OPEN o_rel FOR
            SELECT hd.id_professional, e.id_patient, he.id_episode
              FROM hcn_eval_det hd,
                   hcn_eval he,
                   episode e,
                   prof_dep_clin_serv pdcs,
                   professional p,
                   (SELECT DISTINCT pdcs1.id_dep_clin_serv
                      FROM prof_dep_clin_serv pdcs1, dep_clin_serv dcs1, department dpt1
                     WHERE pdcs1.id_professional = i_prof.id
                       AND pdcs1.flg_status = g_selected --Seleccionado pelo utilizador no tools
                       AND pdcs1.flg_default = g_default_y
                       AND dcs1.id_dep_clin_serv = pdcs1.id_dep_clin_serv
                       AND dpt1.id_department = dcs1.id_department
                       AND dpt1.id_institution = i_prof.institution
                       AND instr(dpt1.flg_type, 'I') > 0) pc
             WHERE pdcs.id_dep_clin_serv = pc.id_dep_clin_serv
               AND p.id_professional = pdcs.id_professional
               AND hd.id_professional = pdcs.id_professional
               AND hd.flg_status = g_active
               AND hd.flg_type = g_hcn_type_pat
               AND he.id_hcn_eval = hd.id_hcn_eval
               AND he.flg_status = g_active
               AND e.id_episode = he.id_episode
               AND (hd.dt_aloc_prof_tstz = (SELECT MAX(e1.dt_aloc_prof_tstz)
                                              FROM hcn_eval_det e1
                                             WHERE e1.id_hcn_eval = he.id_hcn_eval
                                               AND e1.flg_status = g_active
                                               AND e1.flg_type = g_hcn_type_pat) OR NOT EXISTS
                    (SELECT 1
                       FROM hcn_eval_det e1
                      WHERE e1.id_hcn_eval = he.id_hcn_eval
                        AND e1.flg_status = g_active
                        AND e1.flg_type = g_hcn_type_pat));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_PAT_DIST');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_pat);
                pk_types.open_my_cursor(o_nurse);
                pk_types.open_my_cursor(o_rel);
                RETURN FALSE;
            END;
        
    END get_hcn_pat_dist;

    /********************************************************************************************
    * Esta fun��o calcula o n�mero de horas HCN em fun��o dos pontos de uma avalia��o de HCN.
    *
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_hcn_eval    ID da avalia��o HCN
    *
    * @param o_hours       N�mero de horas correspondentes ao n�mero de pontos da avalia��o
    *
    * @return              N�mero de horas correspondentes ao n�mero de pontos da avalia��o
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/23
       ********************************************************************************************/

    FUNCTION get_hcn_from_points
    (
        i_prof     IN profissional,
        i_hcn_eval IN hcn_eval.id_hcn_eval%TYPE
    ) RETURN NUMBER IS
    
        l_hours NUMBER(6, 3);
    
    BEGIN
    
        --Calcula o n�mero de horas de cuidados de enfermagem tendo em conta os pontos obtidos na avalia��o
        g_error := 'get hcn';
        SELECT dp.num_hcn
          INTO l_hours
          FROM hcn_eval e, hcn_def_points dp, epis_documentation d, episode epis
         WHERE e.id_hcn_eval = i_hcn_eval
           AND e.flg_status = g_active
           AND d.id_epis_documentation = e.id_epis_documentation
           AND dp.id_department = e.id_department
           AND dp.id_software IN (0, i_prof.software)
           AND dp.id_institution IN (0, i_prof.institution)
           AND e.total_points BETWEEN dp.points_min_value AND dp.points_max_value
           AND epis.id_episode = e.id_episode
           AND epis.id_institution = i_prof.institution;
    
        RETURN l_hours;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_hcn_from_points;

    /********************************************************************************************
    * Esta fun��o permite alocar os doentes aos enfermeiros
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_prof_nurse  Array de IDs de enfermeiros alocados. Se o valor � nulo ent�o deve-se cancelar a aloca��o
    * @param i_hcn_eval    Array de IDs da avalia��o HCN
    *
    * @param o_hours       N�mero de horas correspondentes ao n�mero de pontos da avalia��o
    *
    * @return              N�mero de horas correspondentes ao n�mero de pontos da avalia��o
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/23
       ********************************************************************************************/

    FUNCTION set_hcn_eval_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_nurse IN table_number,
        i_hcn_eval   IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num PLS_INTEGER;
    
        l_rows table_varchar;
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        FOR i IN 1 .. i_hcn_eval.count
        LOOP
        
            IF i_hcn_eval(i) IS NOT NULL
            THEN
            
                --Se o enfermeiro da aloca��o est� preenchido, insere a nova aloca��o
                IF i_prof_nurse(i) IS NOT NULL
                THEN
                    --Verifica se existe uma aloca��o anterior para a mesma avalia��o. Se existe, cancela-a
                    SELECT COUNT(*)
                      INTO l_num
                      FROM hcn_eval_det
                     WHERE id_hcn_eval = i_hcn_eval(i)
                       AND dt_aloc_prof_tstz = trunc(g_sysdate_tstz)
                       AND flg_status = g_active;
                
                    IF l_num > 0
                    THEN
                        --J� existe uma aloca��o activa, por isso, desactiva-a
                        g_error := 'UPDATE HCN_EVAL_DET';
                        UPDATE hcn_eval_det
                           SET flg_status = g_inactive
                         WHERE id_hcn_eval = i_hcn_eval(i)
                           AND dt_aloc_prof_tstz = pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
                           AND flg_status = g_active;
                    END IF;
                    --Guarda a nova aloca��o
                    g_error := 'INSERT HCN_EVAL_DET';
                    INSERT INTO hcn_eval_det
                        (id_hcn_eval_det,
                         id_hcn_eval,
                         id_professional,
                         dt_aloc_prof_tstz,
                         flg_status,
                         flg_type,
                         id_prof_reg,
                         dt_reg_tstz)
                    VALUES
                        (seq_hcn_eval_det.nextval,
                         i_hcn_eval(i),
                         i_prof_nurse(i),
                         pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL),
                         g_active,
                         g_hcn_type_pat,
                         i_prof.id,
                         g_sysdate_tstz);
                
                    --Actualiza o enfermeiro respons�vel por este paciente
                    /* <DENORM F�bio> */
                    ts_epis_info.upd(id_first_nurse_resp_in  => i_prof_nurse(i),
                                     id_first_nurse_resp_nin => FALSE,
                                     where_in                => 'id_episode = (SELECT id_episode
                                           FROM hcn_eval
                                          WHERE id_hcn_eval = ' ||
                                                                i_hcn_eval(i) || ')',
                                     rows_out                => l_rows);
                
                ELSE
                    --Se o enfermeiro da aloca��o n�o est� preenchido, cancela a aloca��o actual.
                    g_error := 'CANCEL HCN_EVAL_DET';
                    UPDATE hcn_eval_det
                       SET flg_status = g_cancel, id_prof_reg = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
                     WHERE id_hcn_eval = i_hcn_eval(i)
                       AND dt_aloc_prof_tstz = pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
                       AND flg_status = g_active;
                
                END IF;
            END IF;
        
        END LOOP;
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'EPIS_INFO',
                                      l_rows,
                                      o_error,
                                      table_varchar('id_first_nurse_resp'));
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'SET_HCN_EVAL_DET');
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                pk_utils.undo_changes; --ALERT-25017 
                RETURN FALSE;
            END;
        
    END set_hcn_eval_det;

    /********************************************************************************************
    * Esta fun��o permite cancelar a aloca��o dos doentes aos enfermeiros
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_hcn_eval    ID da avalia��o HCN
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/23
       ********************************************************************************************/

    FUNCTION cancel_hcn_eval_det
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_hcn_eval IN hcn_eval.id_hcn_eval%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num PLS_INTEGER;
    
    BEGIN
    
        g_sysdate := SYSDATE;
    
        --Verifica se existe a aloca��o e se est� activa
        SELECT COUNT(*)
          INTO l_num
          FROM hcn_eval_det
         WHERE id_hcn_eval = i_hcn_eval
           AND dt_aloc_prof_tstz = pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
           AND flg_status = g_active;
    
        IF l_num > 0
        THEN
            --Cancela a aloca��o actual.
            g_error := 'CANCEL HCN_EVAL_DET';
            UPDATE hcn_eval_det
               SET flg_status = g_cancel, id_prof_reg = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
             WHERE id_hcn_eval = i_hcn_eval
               AND dt_aloc_prof_tstz = pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
               AND flg_status = g_active;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'CANCEL_HCN_EVAL_DET');
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
        
    END cancel_hcn_eval_det;

    /********************************************************************************************
    * Esta fun��o obt�m a lista de doentes � responsabilidade de um enfermeiro. Essa lista ser�
    * visualizada na �rea do viewer
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_professional ID do enfermeiro
    * @param i_type        Tipo de pesquisa. Valores poss�veis:
    *                       A- Todos os servi�os
    *                       M- Meu servi�o
    *
    * @param o_pat         Array com a lista de pacientes alocados ao enfermeiro
    * @param o_date        Data de hoje
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/26
       ********************************************************************************************/

    FUNCTION get_hcn_prof_pat_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_professional IN professional.id_professional%TYPE,
        i_type         IN VARCHAR2,
        o_pat          OUT pk_types.cursor_type,
        o_date         OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        --Abre array com a lista de pacientes � responsabilidade de um enfermeiro
        g_error := 'OPEN O_PAT ARRAY';
        OPEN o_pat FOR
            SELECT p.id_patient,
                   e.id_episode,
                   --pf.name prof_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pf.id_professional) AS prof_name,
                   he.id_hcn_eval,
                   decode(pk_patphoto.check_blob(p.id_patient), 'N', '', pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_hand_off_type) resp_icons,
                   pk_patient.get_gender(i_lang, p.gender) gender,
                   pk_patient.get_pat_age(i_lang, p.dt_birth, p.dt_deceased, p.age, i_prof.institution, i_prof.software) pat_age,
                   pk_translation.get_translation(i_lang, d.code_department) d_dept,
                   pk_message.get_message(1, 'HCN_LABEL_T012') || pk_hcn.get_hcn_from_points(i_prof, he.id_hcn_eval) num_hours,
                   pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode) name_pat_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon
              FROM hcn_eval_det hd, hcn_eval he, episode e, patient p, department d, professional pf
             WHERE pk_date_utils.trunc_insttimezone(i_prof, hd.dt_aloc_prof_tstz, NULL) =
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
               AND hd.id_professional = i_professional
               AND hd.flg_status = g_active
               AND pf.id_professional = hd.id_professional
               AND he.id_hcn_eval = hd.id_hcn_eval
               AND he.flg_status = g_active
               AND e.id_episode = he.id_episode
               AND e.flg_status = g_active
               AND p.id_patient = e.id_patient
               AND d.id_department = e.id_department
               AND ((i_type = g_all_serv) OR
                    (i_type = g_my_serv AND
                    e.id_department IN (SELECT dpt.id_department
                                           FROM prof_dep_clin_serv pdc1, dep_clin_serv dcs1, department dpt
                                          WHERE pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
                                            AND pdc1.flg_status = g_selected
                                            AND dpt.id_department = dcs1.id_department
                                            AND pdc1.id_professional = i_professional
                                            AND dpt.id_institution = i_prof.institution
                                            AND instr(dpt.flg_type, 'I') > 0)));
    
        SELECT pk_date_utils.dt_chr_tsz(i_lang, current_timestamp, i_prof)
          INTO o_date
          FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_PROF_PAT_LIST');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_pat);
                RETURN FALSE;
            END;
        
    END get_hcn_prof_pat_list;

    /********************************************************************************************
    * Esta fun��o obt�m a lista de doentes � responsabilidade de um enfermeiro. Essa lista ser�
    * visualizada na �rea do viewer
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_professional ID do enfermeiro
    * @param i_type        Tipo de pesquisa. Valores poss�veis:
    *                       A- Todos os servi�os
    *                       M- Meu servi�o
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/26
       ********************************************************************************************/

    FUNCTION get_service_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obt�m a lista dos servi�os de internamento da institui��o
        g_error := 'GET O_LIST ARRAY';
        OPEN o_list FOR
            SELECT DISTINCT d.id_department, pk_translation.get_translation(i_lang, d.code_department) desc_service
              FROM department d, dep_clin_serv dcs
             WHERE dcs.id_department = d.id_department
               AND d.id_institution = i_prof.institution
               AND instr(d.flg_type, 'I') > 0
             ORDER BY desc_service;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_SERVICE_LIST');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_list);
                RETURN FALSE;
            END;
        
    END get_service_list;

    /********************************************************************************************
    * Esta fun��o obt�m a vista semanal, por enfermeiro, das horas de cuidados de enfermagem
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_department  ID do servi�o de internamento
    * @param i_date        Data central a partir da qual � constru�da a vista semanal
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/26
       ********************************************************************************************/

    FUNCTION get_hcn_weekly_view
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_date       IN VARCHAR2,
        o_nurse      OUT pk_types.cursor_type,
        o_days       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        --        l_date := nvl(i_date, SYSDATE);
        l_date_tstz := nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL), current_timestamp);
    
        --Abre array de enfermeiros do servi�o seleccionado
        g_error := 'OPEN O_NURSE ARRAY';
        OPEN o_nurse FOR
            SELECT p.id_professional,
                   pdcs.id_dep_clin_serv,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) professional_photo,
                   --p.nick_name,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) AS nick_name,
                   pk_hcn.get_hcn_from_day(i_lang,
                                           i_prof,
                                           p.id_professional,
                                           pk_date_utils.get_timestamp_str(i_lang,
                                                                           i_prof,
                                                                           pk_date_utils.add_days_to_tstz(l_date_tstz, -3),
                                                                           NULL)) day1,
                   pk_hcn.get_hcn_type_scheduled(i_lang,
                                                 i_prof,
                                                 NULL,
                                                 p.id_professional,
                                                 pk_date_utils.get_timestamp_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                -3),
                                                                                 NULL)) day1_d,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   pk_date_utils.add_days_to_tstz(l_date_tstz, -3),
                                                   NULL) day1_e,
                   pk_hcn.get_hcn_from_day(i_lang,
                                           i_prof,
                                           p.id_professional,
                                           pk_date_utils.get_timestamp_str(i_lang,
                                                                           i_prof,
                                                                           pk_date_utils.add_days_to_tstz(l_date_tstz, -2),
                                                                           NULL)) day2,
                   pk_hcn.get_hcn_type_scheduled(i_lang,
                                                 i_prof,
                                                 NULL,
                                                 p.id_professional,
                                                 pk_date_utils.get_timestamp_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                -2),
                                                                                 NULL)) day2_d,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   pk_date_utils.add_days_to_tstz(l_date_tstz, -2),
                                                   NULL) day2_e,
                   pk_hcn.get_hcn_from_day(i_lang,
                                           i_prof,
                                           p.id_professional,
                                           pk_date_utils.get_timestamp_str(i_lang,
                                                                           i_prof,
                                                                           pk_date_utils.add_days_to_tstz(l_date_tstz, -1),
                                                                           NULL)) day3,
                   pk_hcn.get_hcn_type_scheduled(i_lang,
                                                 i_prof,
                                                 NULL,
                                                 p.id_professional,
                                                 pk_date_utils.get_timestamp_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                -1),
                                                                                 NULL)) day3_d,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   pk_date_utils.add_days_to_tstz(l_date_tstz, -1),
                                                   NULL) day3_e,
                   pk_hcn.get_hcn_from_day(i_lang,
                                           i_prof,
                                           p.id_professional,
                                           pk_date_utils.get_timestamp_str(i_lang, i_prof, l_date_tstz, NULL)) day4,
                   pk_hcn.get_hcn_type_scheduled(i_lang,
                                                 i_prof,
                                                 NULL,
                                                 p.id_professional,
                                                 pk_date_utils.get_timestamp_str(i_lang, i_prof, l_date_tstz, NULL)) day4_d,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, l_date_tstz, NULL) day4_e,
                   pk_hcn.get_hcn_from_day(i_lang,
                                           i_prof,
                                           p.id_professional,
                                           pk_date_utils.get_timestamp_str(i_lang,
                                                                           i_prof,
                                                                           pk_date_utils.add_days_to_tstz(l_date_tstz, 1),
                                                                           NULL)) day5,
                   pk_hcn.get_hcn_type_scheduled(i_lang,
                                                 i_prof,
                                                 NULL,
                                                 p.id_professional,
                                                 pk_date_utils.get_timestamp_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                1),
                                                                                 NULL)) day5_d,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, pk_date_utils.add_days_to_tstz(l_date_tstz, 1), NULL) day5_e,
                   pk_hcn.get_hcn_from_day(i_lang,
                                           i_prof,
                                           p.id_professional,
                                           pk_date_utils.get_timestamp_str(i_lang,
                                                                           i_prof,
                                                                           pk_date_utils.add_days_to_tstz(l_date_tstz, 2),
                                                                           NULL)) day6,
                   pk_hcn.get_hcn_type_scheduled(i_lang,
                                                 i_prof,
                                                 NULL,
                                                 p.id_professional,
                                                 pk_date_utils.get_timestamp_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                2),
                                                                                 NULL)) day6_d,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, pk_date_utils.add_days_to_tstz(l_date_tstz, 2), NULL) day6_e,
                   pk_hcn.get_hcn_from_day(i_lang,
                                           i_prof,
                                           p.id_professional,
                                           pk_date_utils.get_timestamp_str(i_lang,
                                                                           i_prof,
                                                                           pk_date_utils.add_days_to_tstz(l_date_tstz, 3),
                                                                           NULL)) day7,
                   pk_hcn.get_hcn_type_scheduled(i_lang,
                                                 i_prof,
                                                 NULL,
                                                 p.id_professional,
                                                 pk_date_utils.get_timestamp_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                3),
                                                                                 NULL)) day7_d,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, pk_date_utils.add_days_to_tstz(l_date_tstz, 3), NULL) day7_e,
                   pk_hcn.get_hcn_from_day(i_lang,
                                           i_prof,
                                           p.id_professional,
                                           pk_date_utils.get_timestamp_str(i_lang,
                                                                           i_prof,
                                                                           pk_date_utils.add_days_to_tstz(l_date_tstz, 4),
                                                                           NULL)) day8,
                   pk_hcn.get_hcn_type_scheduled(i_lang,
                                                 i_prof,
                                                 NULL,
                                                 p.id_professional,
                                                 pk_date_utils.get_timestamp_str(i_lang,
                                                                                 i_prof,
                                                                                 pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                4),
                                                                                 NULL)) day8_d,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, pk_date_utils.add_days_to_tstz(l_date_tstz, 4), NULL) day8_e
              FROM prof_dep_clin_serv pdcs, professional p, category c, prof_cat pc, dep_clin_serv dcs, department dpt
             WHERE dpt.id_department = i_department
               AND dpt.id_institution = i_prof.institution
               AND instr(dpt.flg_type, 'I') > 0
               AND dcs.id_department = dpt.id_department
               AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND pdcs.flg_status = g_selected --Seleccionado pelo utilizador no tools
               AND pdcs.flg_default = g_default_y
               AND p.id_professional = pdcs.id_professional
               AND pc.id_professional = p.id_professional
               AND pc.id_institution IN (0, i_prof.institution)
               AND c.id_category = pc.id_category
               AND c.flg_type = g_cat_type_nurse;
    
        --Abre array com os dias a visualizar na grelha
        g_error := 'OPEN O_DAYS ARRAY';
        OPEN o_days FOR
            SELECT to_number(to_char(pk_date_utils.add_days_to_tstz(l_date_tstz, -4 + rownum), 'dd')) d_day,
                   pk_date_utils.dt_chr_month_tsz(i_lang,
                                                  pk_date_utils.add_days_to_tstz(l_date_tstz, -4 + rownum),
                                                  i_prof) d_month,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   pk_date_utils.add_days_to_tstz(l_date_tstz, -4 + rownum),
                                                   NULL) d_date,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, current_timestamp, NULL) d_this_day
              FROM dual,
                   (SELECT 1 --Produto cartesiano propositado, de forma a obter o n�mero de registos pretendido
                      FROM sys_config
                     WHERE rownum < 9);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_WEEKLY_VIEW');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_nurse);
                pk_types.open_my_cursor(o_days);
                RETURN FALSE;
            END;
        
    END get_hcn_weekly_view;

    /********************************************************************************************
    * Esta fun��o calcula o total do n�mero de horas HCN de um enfermeiro para um dia.
    *
    * @param i_lang        ID do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_hcn_eval    ID da avalia��o HCN
    * @param i_professional ID do enfermeiro
    *
    * @return              Total de horas de HCN de um enfermeiro ou informa��o sobre folgas, f�rias, etc.
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/27
       ********************************************************************************************/

    FUNCTION get_hcn_from_day
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_professional IN professional.id_professional%TYPE,
        i_date         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_ret VARCHAR2(20);
        --        l_date DATE;
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        l_date_tstz := pk_date_utils.trunc_insttimezone(i_prof,
                                                        nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL),
                                                            current_timestamp),
                                                        NULL);
        --        l_date := trunc(nvl(i_date, SYSDATE));
    
        --Verifica se o enfermeiro est� de folga, f�rias, etc. qualquer estado diferente de "Alocado a um paciente"
        BEGIN
            g_error := 'GET NURSE DAY OFF';
            SELECT pk_sysdomain.get_domain('HCN_EVAL_DET.FLG_TYPE', flg_type, i_lang)
              INTO l_ret
              FROM hcn_eval_det
             WHERE dt_aloc_prof_tstz = l_date_tstz
               AND id_professional = i_professional
               AND flg_status = g_active
               AND flg_type != g_hcn_type_pat;
        
        EXCEPTION
            WHEN no_data_found THEN
                BEGIN
                    --Se o enfermeiro n�o est� indispon�vel, verifica se est� alocado a pacientes e
                    --obtem o total de HCN para esse dia
                    g_error := 'GET NURSE TOTAL HCN';
                    SELECT SUM(pk_hcn.get_hcn_from_points(i_prof, hd1.id_hcn_eval)) num_hours
                      INTO l_ret
                      FROM hcn_eval_det hd1
                     WHERE hd1.id_professional = i_professional
                       AND pk_date_utils.trunc_insttimezone(i_prof, hd1.dt_aloc_prof_tstz, NULL) = l_date_tstz
                       AND hd1.flg_status = g_active
                       AND flg_type = g_hcn_type_pat;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        --Se o enfermeiro n�o est� alocado a pacientes nem indispon�vel, retorna null
                        l_ret := NULL;
                END;
        END;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_FROM_DAY');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                pk_alert_exceptions.reset_error_state;
                RETURN NULL;
            END;
        
    END get_hcn_from_day;

    /********************************************************************************************
    * Esta fun��o verifica se j� existe, para o dia, uma aloca��o do paciente a um enfermeiro. Caso
    *  exista, ser� dada uma mensagem de aviso ao utilizador na cria��o de uma nova avalia��o e no
    *  cancelamento de uma avalia��o existente
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_date        Data do dia a avaliar
    * @param i_type        Tipo de opera��o que despoleta esta verifica��o. Valores poss�veis:
    *                           N- Nova avalia��o
    *                           C- Cancelamento de uma avalia��o
    *
    * @param o_hcn_eval    ID da avalia��o do dia, activa e j� alocada
    * @param o_flg_show    Array com a lista de pacientes alocados ao enfermeiro
    * @param o_msg_title   T�tulo da mensagem a mostrar
    * @param o_msg_text    Texto da mensagem a mostrar
    * @param o_button      Bot�es a disponibilizar
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/27
       ********************************************************************************************/

    FUNCTION check_exists_nurse_aloc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_date               IN VARCHAR2,
        i_type               IN VARCHAR2,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_hcn_eval           OUT hcn_eval.id_hcn_eval%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text           OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        o_flg_show := 'N';
    
        IF i_type = 'N'
        THEN
            --Verifica se existe uma avalia��o no dia, activa, j� alocada a um enfermeiro
            g_error := 'GET PREV ALOC EVALUATION';
        
            BEGIN
                SELECT MAX(he.id_hcn_eval)
                  INTO o_hcn_eval
                  FROM hcn_eval he, hcn_eval_det hd
                 WHERE he.id_episode = i_episode
                   AND pk_date_utils.trunc_insttimezone(i_prof, he.dt_eval_tstz, NULL) =
                       pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)
                   AND he.flg_status = g_active
                   AND hd.id_hcn_eval = he.id_hcn_eval
                   AND hd.flg_status = g_active
                   AND hd.flg_type = g_flg_type_pat;
            EXCEPTION
                WHEN no_data_found THEN
                    o_hcn_eval := NULL;
            END;
        
            IF o_hcn_eval IS NOT NULL
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'HCN_LABEL_T015');
                o_msg_text  := pk_message.get_message(i_lang, 'HCN_LABEL_T016');
                o_button    := 'NC';
            END IF;
        
        ELSE
            --Verifica se a avalia��o a cancelar j� foi alocada
            g_error := 'GET PREV ALOC EVALUATION';
        
            BEGIN
                SELECT MAX(he.id_hcn_eval)
                  INTO o_hcn_eval
                  FROM hcn_eval he, hcn_eval_det hd
                 WHERE he.id_episode = i_episode
                   AND he.id_epis_documentation = i_epis_documentation
                   AND he.flg_status = g_active
                   AND hd.id_hcn_eval = he.id_hcn_eval
                   AND hd.flg_status = g_active
                   AND hd.flg_type = g_flg_type_pat;
            EXCEPTION
                WHEN no_data_found THEN
                    o_hcn_eval := NULL;
            END;
        
            IF o_hcn_eval IS NOT NULL
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'HCN_LABEL_T015');
                o_msg_text  := pk_message.get_message(i_lang, 'HCN_LABEL_T017');
                o_button    := 'NC';
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'CHECK_EXISTS_NURSE_ALOC');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                RETURN FALSE;
            END;
        
    END check_exists_nurse_aloc;

    /********************************************************************************************
    * Esta fun��o mostra a lista de valores poss�veis para a aloca��o de um doente a um enfermeiro.
    *
    * @param i_lang        ID do idioma
    * @param i_prof        Id do profissional, institui��o e software
    *
    * @param o_list        Array com valores poss�veis para a aloca��o de um doente a um enfermeiro.
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/27
       ********************************************************************************************/

    FUNCTION get_hcn_aloc_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Abre array
        g_error := 'GET O_LIST ARRAY';
        OPEN o_list FOR
            SELECT val data, desc_val label
              FROM sys_domain
             WHERE id_language = i_lang
               AND code_domain = 'HCN_EVAL_DET.FLG_TYPE'
               AND domain_owner = pk_sysdomain.k_default_schema
               AND val != g_flg_type_pat
               AND flg_available = 'Y'
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_ALOC_LIST');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_list);
                RETURN FALSE;
            END;
        
    END get_hcn_aloc_list;

    /********************************************************************************************
    * Esta fun��o mostra estat�ticas de HCN, di�rias e semanais
    *
    * @param i_lang        ID do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_date        Data a considerar. Em caso de n�o ser preenchida, considera a data de sistema
    * @param i_department  ID do servi�o
    *
    * @param o_tot_hcn_day     Total HCN di�rio
    * @param o_tot_hcn_week    Total HCN nesta semana
    * @param o_avg_hcn_day     M�dia HCN di�ria
    * @param o_avg_hcn_week    M�dia HCN semanal
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/27
       ********************************************************************************************/

    FUNCTION get_hcn_statistics
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_date         IN VARCHAR2,
        i_department   IN department.id_department%TYPE,
        o_tot_hcn_day  OUT VARCHAR2,
        o_tot_hcn_week OUT VARCHAR2,
        o_avg_hcn_day  OUT VARCHAR2,
        o_avg_hcn_week OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --        l_date     DATE;
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_tot_day   NUMBER(9, 3) := 0;
        l_tot_week  NUMBER(9, 3) := 0;
    
    BEGIN
        --        l_date := trunc(nvl(i_date, SYSDATE));
        l_date_tstz := pk_date_utils.trunc_insttimezone(i_prof,
                                                        nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL),
                                                            current_timestamp),
                                                        NULL);
    
        --Obt�m o total de HCN do dia para o servi�o
        g_error := 'GET DAY TOTAL';
        SELECT SUM(pk_hcn.get_hcn_from_points(i_prof, he.id_hcn_eval))
          INTO l_tot_day
          FROM department d, dep_clin_serv dcs, epis_info ei, hcn_eval he
         WHERE d.id_department = i_department
           AND dcs.id_department = d.id_department
           AND ei.id_dep_clin_serv = dcs.id_dep_clin_serv
           AND he.id_episode = ei.id_episode
           AND he.flg_status = g_active
           AND pk_date_utils.trunc_insttimezone(i_prof, he.dt_eval_tstz, NULL) = l_date_tstz;
    
        --Obt�m o total de HCN da semana para este servi�o
        g_error := 'GET WEEK TOTAL';
        SELECT SUM(pk_hcn.get_hcn_from_points(i_prof, he.id_hcn_eval))
          INTO l_tot_week
          FROM department d, dep_clin_serv dcs, epis_info ei, hcn_eval he
         WHERE d.id_department = i_department
           AND dcs.id_department = d.id_department
           AND ei.id_dep_clin_serv = dcs.id_dep_clin_serv
           AND he.id_episode = ei.id_episode
           AND he.flg_status = g_active
           AND pk_date_utils.trunc_insttimezone(i_prof, he.dt_eval_tstz, NULL) BETWEEN
               pk_date_utils.add_days_to_tstz(l_date_tstz, -6) AND l_date_tstz;
    
        --Calcula as m�dias
        IF l_tot_day IS NOT NULL
        THEN
            o_tot_hcn_day := to_char(l_tot_day, '90D9') || ' h';
            o_avg_hcn_day := to_char(round(l_tot_day / 7, 1), '90D9') || ' h';
        ELSE
            o_tot_hcn_day := '---';
            o_avg_hcn_day := '---';
        END IF;
    
        IF l_tot_week IS NOT NULL
        THEN
            o_tot_hcn_week := to_char(l_tot_week, '90D9') || ' h';
            o_avg_hcn_week := to_char(round(l_tot_week / 7, 1), '90D9') || ' h';
        ELSE
            o_tot_hcn_week := '---';
            o_avg_hcn_week := '---';
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_STATISTICS');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                RETURN FALSE;
            END;
        
    END get_hcn_statistics;

    /********************************************************************************************
    * Esta fun��o altera o estado de disponibilidade dos enfermeiros para uma determinada data
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_prof_nurse  Array de IDs de enfermeiros alocados. Se o valor � nulo ent�o deve-se cancelar a aloca��o
    * @param i_date        Dia a alocar
    * @param i_status      Tipo de aloca��o. Valores poss�veis: F-folga, V- f�rias, I- indispon�vel
    * @param i_test        Flag que indica se deve ser verificada a existencia de aloca��es anteriores para este dia
    *
    * @param o_flg_show    Indica se deve ser mostrado ecr� de aviso
    * @param o_msg_title   T�tulo do ecr� de aviso
    * @param o_msg_text    Mensagem do ecr� de aviso
    * @param o_button      Bot�es a disponibilizar no ecr� de aviso
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/30
       ********************************************************************************************/

    FUNCTION set_hcn_prof_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_nurse IN professional.id_professional%TYPE,
        i_date       IN VARCHAR2,
        i_status     IN VARCHAR2,
        i_test       IN VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg_text   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count     PLS_INTEGER;
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        o_flg_show     := 'N';
    
        l_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL);
    
        --Verifica se o enfermeiro j� tens aloca��es para esse dia
        g_error := 'CHECK PREVIOUS ALOCATIONS';
        SELECT COUNT(*)
          INTO l_count
          FROM hcn_eval_det hd
         WHERE hd.id_professional = i_prof_nurse
           AND hd.flg_status = g_active
           AND pk_date_utils.trunc_insttimezone(i_prof, hd.dt_aloc_prof_tstz, NULL) =
               pk_date_utils.trunc_insttimezone(i_prof, l_date_tstz, NULL)
           AND hd.flg_type = g_hcn_type_pat;
    
        IF l_count > 0
        THEN
            --O enfermeiro j� tem aloca��es para esse dia. Mostra ecr� de confirma��o
            IF i_test = 'Y'
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'HCN_LABEL_T025');
                o_msg_text  := pk_message.get_message(i_lang, 'HCN_LABEL_T026');
                o_button    := 'NC';
                --Sai para mostrar ecr� de aviso
                RETURN TRUE;
            ELSE
                --N�o � para validar aloca��es anteriores. Elas ir�o ser canceladas
                g_error := 'UPDATE HCN_EVAL_DET CANCELED';
                UPDATE hcn_eval_det
                   SET flg_status = g_cancel, id_prof_cancel = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
                 WHERE id_professional = i_prof_nurse
                   AND flg_status = g_active
                   AND pk_date_utils.trunc_insttimezone(i_prof, dt_aloc_prof_tstz, NULL) =
                       pk_date_utils.trunc_insttimezone(i_prof, l_date_tstz, NULL)
                   AND flg_type = g_hcn_type_pat;
            
            END IF;
        END IF;
    
        --Inactiva as aloca��es de f�rias, folgas, etc. j� existentes para este per�odo.
        g_error := 'UPDATE HCN_EVAL_DET INACTIVE';
        UPDATE hcn_eval_det
           SET flg_status = g_inactive, id_prof_cancel = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
         WHERE id_professional = i_prof_nurse
           AND flg_status = g_active
           AND pk_date_utils.trunc_insttimezone(i_prof, dt_aloc_prof_tstz, NULL) =
               pk_date_utils.trunc_insttimezone(i_prof, l_date_tstz, NULL)
           AND flg_type != g_hcn_type_pat;
    
        --Insere o registo da disponibilidade do enfermeiro se o estado for diferente de "Dispon�vel".
        IF i_status != g_hcn_available
        THEN
            g_error := 'INSERT HCN_EVAL_DET';
            INSERT INTO hcn_eval_det
                (id_hcn_eval_det,
                 id_hcn_eval,
                 id_professional,
                 dt_aloc_prof_tstz,
                 flg_status,
                 flg_type,
                 id_prof_reg,
                 dt_reg_tstz)
            VALUES
                (seq_hcn_eval_det.nextval,
                 NULL,
                 i_prof_nurse,
                 l_date_tstz,
                 g_active,
                 i_status,
                 i_prof.id,
                 g_sysdate_tstz);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'SET_HCN_PROF_STATUS');
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                pk_utils.undo_changes; --ALERT-25017 
                RETURN FALSE;
            END;
        
    END set_hcn_prof_status;

    /********************************************************************************************
    * Esta fun��o obt�m a vista semanal, por paciente, das horas de cuidados de enfermagem
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio. Se vier a null, n�o est�vamos na ficha de um doente, por
    *                       isso, ir� ser disponibilizada a informa��o de v�rios pacientes
    * @param i_date        Data central a partir da qual � constru�da a vista semanal
    * @param i_type        Tipo de grelha que estava seleccionada anteriormente. Valores poss�veis:
    *                           1- grelha "os meus pacientes"
    *                       2- grelha "os pacientes dos meus servi�os"
    *                           3- grelha "as minhas camas"?
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/30
       ********************************************************************************************/

    FUNCTION get_hcn_pat_weekly_view
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN VARCHAR2,
        i_type    IN VARCHAR2,
        o_pat     OUT pk_types.cursor_type,
        o_days    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_hand_off_type sys_config.value%TYPE;
        l_prof_cat      category.flg_type%TYPE;
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'GET PROF CAT';
        alertlog.pk_alertlog.log_info(text => g_error);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        l_date_tstz := nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL), current_timestamp);
    
        --Se o paciente vem preenchido, mostra apenas o paciente
        IF i_episode IS NOT NULL
        THEN
            g_error := 'OPEN O_PAT ARRAY - 1';
            OPEN o_pat FOR
                SELECT epis.id_episode id_episode,
                       nvl((dpt.rank * 100000), 0) + nvl((ro.rank * 1000), 0) + nvl(bd.rank, 99) rank,
                       nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) desc_bed,
                       nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                           nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                       decode(pk_patphoto.check_blob(pat.id_patient),
                              'N',
                              '',
                              pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                       pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                       pk_patient.get_gender(i_lang, pat.gender) gender,
                       pk_patient.get_pat_age(i_lang,
                                              pat.dt_birth,
                                              pat.dt_deceased,
                                              pat.age,
                                              i_prof.institution,
                                              i_prof.software) pat_age,
                       pat.id_patient id_patient,
                       pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, epis.id_episode) desc_diagnosis,
                       pk_hcn.get_hcn_epis_avg(i_prof, epis.id_episode) avg_hcn,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 -3),
                                                                                  NULL)) day_1,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    -3),
                                                                                     NULL)) day_d_1,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 -2),
                                                                                  NULL)) day_2,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    -2),
                                                                                     NULL)) day_d_2,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 -1),
                                                                                  NULL)) day_3,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    -1),
                                                                                     NULL)) day_d_3,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang, i_prof, l_date_tstz, NULL)) day_4,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang, i_prof, l_date_tstz, NULL)) day_d_4,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 1),
                                                                                  NULL)) day_5,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    1),
                                                                                     NULL)) day_d_5,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 2),
                                                                                  NULL)) day_6,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    2),
                                                                                     NULL)) day_d_6,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 3),
                                                                                  NULL)) day_7,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    3),
                                                                                     NULL)) day_d_7,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 4),
                                                                                  NULL)) day_8,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    4),
                                                                                     NULL)) day_d_8,
                       pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat_to_sort,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon
                  FROM patient pat, department dpt, episode epis, epis_info ei, bed bd, room ro
                 WHERE epis.id_episode = i_episode
                   AND nvl(ei.flg_dsch_status, g_active) = g_active
                   AND epis.id_episode = ei.id_episode
                   AND bd.id_bed(+) = ei.id_bed
                   AND ro.id_room(+) = bd.id_room
                   AND ro.id_department = dpt.id_department(+)
                   AND epis.id_patient = pat.id_patient
                   AND epis.id_institution = i_prof.institution
                   AND epis.flg_status = g_active
                 ORDER BY rank;
        ELSE
            g_error := 'OPEN O_PAT ARRAY - 2';
            OPEN o_pat FOR
                SELECT epis.id_episode id_episode,
                       nvl((dpt.rank * 100000), 0) + nvl((ro.rank * 1000), 0) + nvl(bd.rank, 99) rank,
                       nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) desc_bed,
                       nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                           nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                       decode(pk_patphoto.check_blob(pat.id_patient),
                              'N',
                              '',
                              pk_patphoto.get_pat_foto(pat.id_patient, i_prof)) photo,
                       pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                       pat.gender gender,
                       pk_patient.get_pat_age(i_lang,
                                              pat.dt_birth,
                                              pat.dt_deceased,
                                              pat.age,
                                              i_prof.institution,
                                              i_prof.software) pat_age,
                       pat.id_patient id_patient,
                       pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, epis.id_episode) desc_diagnosis,
                       pk_hcn.get_hcn_epis_avg(i_prof, epis.id_episode) avg_hcn,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 -3),
                                                                                  NULL)) day_1,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    -3),
                                                                                     NULL)) day_d_1,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 -2),
                                                                                  NULL)) day_2,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    -2),
                                                                                     NULL)) day_d_2,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 -1),
                                                                                  NULL)) day_3,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    -1),
                                                                                     NULL)) day_d_3,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang, i_prof, l_date_tstz, NULL)) day_4,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang, i_prof, l_date_tstz, NULL)) day_d_4,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 1),
                                                                                  NULL)) day_5,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    1),
                                                                                     NULL)) day_d_5,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 2),
                                                                                  NULL)) day_6,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    2),
                                                                                     NULL)) day_d_6,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 3),
                                                                                  NULL)) day_7,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    3),
                                                                                     NULL)) day_d_7,
                       pk_hcn.get_hcn_day_episode(i_lang,
                                                  i_prof,
                                                  epis.id_episode,
                                                  pk_date_utils.get_timestamp_str(i_lang,
                                                                                  i_prof,
                                                                                  pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                 4),
                                                                                  NULL)) day_8,
                       pk_hcn.get_hcn_type_scheduled(i_lang,
                                                     i_prof,
                                                     epis.id_episode,
                                                     NULL,
                                                     pk_date_utils.get_timestamp_str(i_lang,
                                                                                     i_prof,
                                                                                     pk_date_utils.add_days_to_tstz(l_date_tstz,
                                                                                                                    -4),
                                                                                     NULL)) day_d_8,
                       pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat_to_sort,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon
                  FROM origin       ori,
                       patient      pat,
                       professional p,
                       professional pn,
                       department   dpt,
                       episode      epis,
                       epis_info    ei,
                       grid_task    gt,
                       visit        v,
                       bed          bd,
                       room         ro,
                       sys_domain   sd
                 WHERE sd.id_language = i_lang
                   AND v.id_origin = ori.id_origin(+)
                   AND nvl(ei.flg_dsch_status, g_active) = g_active
                   AND epis.id_episode = ei.id_episode
                   AND bd.id_bed(+) = ei.id_bed
                   AND ro.id_room(+) = bd.id_room
                   AND ro.id_department = dpt.id_department(+)
                   AND gt.id_episode(+) = epis.id_episode
                   AND epis.id_visit = v.id_visit
                   AND v.id_patient = pat.id_patient
                   AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, i_prof.institution) = i_prof.software
                   AND p.id_professional(+) = ei.id_professional
                   AND pn.id_professional(+) = ei.id_first_nurse_resp
                   AND epis.id_epis_type = g_inp_epis_type
                   AND sd.val = ei.flg_status
                   AND epis.dt_begin_tstz <
                       pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL),
                                                      1)
                   AND sd.code_domain = 'EPIS_INFO.FLG_STATUS'
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND epis.flg_status = g_active
                   AND (((pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                           i_prof,
                                                                                           ei.id_episode,
                                                                                           l_prof_cat,
                                                                                           l_hand_off_type),
                                                       i_prof.id) != -1) AND i_type = 1) OR
                       ((ei.id_dep_clin_serv IN
                       (SELECT dcs1.id_dep_clin_serv
                             FROM prof_dep_clin_serv pdc1, dep_clin_serv dcs1, department dpt1
                            WHERE pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
                              AND pdc1.flg_status = g_selected
                              AND dpt1.id_department = dcs1.id_department
                              AND pdc1.id_professional = i_prof.id
                              AND dpt1.id_institution = i_prof.institution
                              AND instr(dpt1.flg_type, g_flg_dpt_type) > 0
                              AND (g_flg_dpt_type != 'I' OR instr(dpt1.flg_type, 'O') = 0))) AND i_type = 2) OR
                       ((ei.id_bed IN (SELECT b.id_bed --R.ID_ROOM
                                          FROM prof_room pr, room r, department d, bed b
                                         WHERE pr.id_professional = i_prof.id
                                           AND r.id_room = pr.id_room
                                           AND d.id_department = r.id_department
                                           AND b.id_room = r.id_room
                                           AND instr(d.flg_type, 'I') > 0)) AND i_type = 3))
                 ORDER BY rank;
        
        END IF;
    
        --Abre array com os dias a visualizar na grelha
        g_error := 'OPEN O_DAYS ARRAY';
        OPEN o_days FOR
            SELECT to_number(to_char(pk_date_utils.add_days_to_tstz(l_date_tstz, -4 + rownum), 'dd')) d_day,
                   pk_date_utils.dt_chr_month(i_lang, pk_date_utils.add_days_to_tstz(l_date_tstz, -4 + rownum), i_prof) d_month,
                   pk_date_utils.get_timestamp_str(i_lang,
                                                   i_prof,
                                                   pk_date_utils.add_days_to_tstz(l_date_tstz, -4 + rownum),
                                                   NULL) d_date,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, current_timestamp, NULL) d_this_day
              FROM dual,
                   (SELECT 1 --Produto cartesiano propositado, de forma a obter o n�mero de registos pretendido
                      FROM sys_config
                     WHERE rownum < 9);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_PAT_WEEKLY_VIEW');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_types.open_my_cursor(o_pat);
                pk_types.open_my_cursor(o_days);
                RETURN FALSE;
            END;
        
    END get_hcn_pat_weekly_view;

    /********************************************************************************************
    * Esta fun��o calcula o n�mero de horas HCN de um epis�dio num determinado dia.
    *
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_date        Dia a analisar
    *
    * @return              N�mero de horas correspondentes ao n�mero de pontos da avalia��o
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/23
       ********************************************************************************************/

    FUNCTION get_hcn_day_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN VARCHAR2
    ) RETURN NUMBER IS
    
        l_hours     NUMBER(6, 3);
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL);
    
        --Calcula o n�mero de horas de cuidados de enfermagem, tendo em conta os pontos obtidos na avalia��o,
        --  para um episodio e para um determinado dia
        g_error := 'get hcn';
        SELECT SUM(v_hours)
          INTO l_hours
          FROM (SELECT dp.num_hcn v_hours
                  FROM hcn_eval e, hcn_def_points dp, epis_documentation d
                 WHERE e.id_episode = i_episode
                   AND e.flg_status = g_active
                   AND pk_date_utils.trunc_insttimezone(i_prof, e.dt_eval_tstz, NULL) =
                       pk_date_utils.trunc_insttimezone(i_prof, nvl(l_date_tstz, current_timestamp), NULL)
                   AND d.id_epis_documentation = e.id_epis_documentation
                   AND dp.id_department = e.id_department
                   AND dp.id_software IN (0, i_prof.software)
                   AND dp.id_institution IN (0, i_prof.institution)
                   AND e.total_points BETWEEN dp.points_min_value AND dp.points_max_value);
    
        RETURN l_hours;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_DAY_EPISODE');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            END;
        
    END get_hcn_day_episode;

    /********************************************************************************************
    * Esta fun��o verifica se existe uma marca��o no agendamento di�rio do paciente ou do enfermeiro.
    *
    * @param i_lang        ID do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio (se est� preenchido vamos verificar o agendamento do paciente)
    * @param i_professional ID do enfermeiro (se est� preenchido vamos verificar o agendamento do enfermeiro).
    * @param i_date        Dia a analisar
    *
    * @return              Poss�vel agendamento para o dia
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/05/02
       ********************************************************************************************/

    FUNCTION get_hcn_type_scheduled
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_date         IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_desc_type VARCHAR2(100);
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL);
    
        IF i_episode IS NOT NULL
        THEN
            --Se o epis�dio est� preenchido, procura o agendamento do paciente
            SELECT desc_val
              INTO l_desc_type
              FROM (SELECT s.desc_val, s.rank
                      FROM hcn_pat_det hp, sys_domain s
                     WHERE hp.id_episode = i_episode
                       AND hp.flg_status = g_active
                       AND pk_date_utils.trunc_insttimezone(i_prof, hp.dt_status_tstz, NULL) =
                           pk_date_utils.trunc_insttimezone(i_prof, l_date_tstz, NULL)
                       AND s.code_domain = 'HCN_PAT_DET.FLG_TYPE'
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                       AND s.id_language = i_lang
                       AND s.val = hp.flg_type
                     ORDER BY s.rank)
             WHERE rownum < 2;
        
        ELSIF i_professional IS NOT NULL
        THEN
            --se o profissional est� preenchido, procura o agendamento do profissional
            SELECT desc_val
              INTO l_desc_type
              FROM (SELECT s.desc_val, s.rank
                      FROM hcn_eval_det hd, sys_domain s
                     WHERE hd.id_professional = i_professional
                       AND hd.flg_status = g_active
                       AND pk_date_utils.trunc_insttimezone(i_prof, hd.dt_aloc_prof_tstz) =
                           pk_date_utils.trunc_insttimezone(i_prof, l_date_tstz, NULL)
                       AND hd.flg_type != g_hcn_type_pat
                       AND s.code_domain = 'HCN_EVAL_DET.FLG_TYPE'
                       AND s.domain_owner = pk_sysdomain.k_default_schema
                       AND s.id_language = i_lang
                       AND s.val = hd.flg_type)
             WHERE rownum < 2;
        END IF;
    
        RETURN l_desc_type;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_TYPE_SCHEDULED');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            END;
        
    END get_hcn_type_scheduled;

    /********************************************************************************************
    * Esta fun��o altera o estado de disponibilidade de um paciente para uma determinada data
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     Id do episodio
    * @param i_date        Dia a alocar
    * @param i_type        Tipo de aloca��o. Valores poss�veis: A- Alta programada, U- Ausente, E- Exame
    * @param i_test        Flag que indica se deve ser verificada a existencia de aloca��es anteriores para este dia
    *
    * @param o_flg_show    Indica se deve ser mostrado ecr� de aviso
    * @param o_msg_title   T�tulo do ecr� de aviso
    * @param o_msg_text    Mensagem do ecr� de aviso
    * @param o_button      Bot�es a disponibilizar no ecr� de aviso
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/05/02
       ********************************************************************************************/

    FUNCTION set_hcn_pat_status
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_date      IN VARCHAR2,
        i_type      IN VARCHAR2,
        i_test      IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count     PLS_INTEGER;
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        o_flg_show     := 'N';
    
        l_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL);
    
        --Verifica se o paciente j� tens aloca��es para esse dia
        g_error := 'CHECK PREVIOUS ALOCATIONS';
        SELECT COUNT(*)
          INTO l_count
          FROM hcn_pat_det hp
         WHERE hp.id_episode = i_episode
           AND hp.flg_status = g_active
           AND pk_date_utils.trunc_insttimezone(i_prof, hp.dt_status_tstz, NULL) =
               pk_date_utils.trunc_insttimezone(i_prof, l_date_tstz, NULL);
    
        IF l_count > 0
        THEN
            --O paciente j� tem aloca��es para esse dia. Mostra ecr� de confirma��o
            IF i_test = 'Y'
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'HCN_LABEL_T029');
                o_msg_text  := pk_message.get_message(i_lang, 'HCN_LABEL_T030');
                o_button    := 'NC';
                --Sai para mostrar ecr� de aviso
                RETURN TRUE;
            ELSE
                --N�o � para validar aloca��es anteriores. Elas ir�o ser canceladas
                UPDATE hcn_pat_det
                   SET flg_status = g_cancel, id_prof_cancel = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
                 WHERE id_episode = i_episode
                   AND flg_status = g_active
                   AND pk_date_utils.trunc_insttimezone(i_prof, dt_status_tstz) =
                       pk_date_utils.trunc_insttimezone(i_prof, l_date_tstz, NULL);
            
            END IF;
        END IF;
    
        --Insere o registo da disponibilidade do paciente.
        g_error := 'INSERT HCN_PAT_DET';
        IF i_type != g_hcn_available
        THEN
            INSERT INTO hcn_pat_det
                (id_hcn_pat_det, id_episode, dt_status_tstz, flg_status, id_prof_reg, dt_reg_tstz, flg_type)
            VALUES
                (seq_hcn_pat_det.nextval, i_episode, l_date_tstz, g_active, i_prof.id, g_sysdate_tstz, i_type);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'SET_HCN_PAT_STATUS');
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                pk_alert_exceptions.reset_error_state;
                o_error := l_error_out;
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                pk_utils.undo_changes; --ALERT-25017 
                RETURN FALSE;
            END;
        
    END set_hcn_pat_status;

    /********************************************************************************************
    * Esta fun��o devolve o total de pontos de um item de uma avalia��o, para um determinado dia.
    *
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_date        Dia a analisar
    *
    * @return              N�mero de horas correspondentes ao n�mero de pontos da avalia��o
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/23
       ********************************************************************************************/

    FUNCTION get_hcn_eval_item_points
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_documentation IN documentation.id_documentation%TYPE,
        i_date          IN TIMESTAMP WITH TIME ZONE
    ) RETURN NUMBER IS
    
        l_points NUMBER(6, 3);
        --        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        SELECT SUM(de.score) points
          INTO l_points
          FROM epis_documentation     ed,
               epis_documentation_det edd,
               hcn_eval               he,
               doc_element            de,
               --hcn_def_crit           hdc,
               doc_component dc,
               documentation d
         WHERE ed.id_episode = i_episode
           AND ed.flg_status = g_active
           AND he.id_epis_documentation = ed.id_epis_documentation
           AND he.flg_status = g_active
           AND edd.id_epis_documentation = ed.id_epis_documentation
           AND de.id_doc_element = edd.id_doc_element
              --AND hdc.internal_name = de.internal_name --PLLopes 13/3/2009 ALERT-19098
              --AND hdc.id_doc_element = de.id_doc_element
           AND d.id_documentation = edd.id_documentation
           AND dc.id_doc_component = d.id_doc_component
           AND d.id_documentation = i_documentation
           AND pk_date_utils.trunc_insttimezone(i_prof, he.dt_eval_tstz, NULL) =
               pk_date_utils.trunc_insttimezone(i_prof, i_date, NULL);
    
        RETURN l_points;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_ITEM_POINTS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            END;
    END get_hcn_eval_item_points;

    /********************************************************************************************
    * Esta fun��o devolve os valores das avalia��es HCN do paciente, por item e por dias.
    *
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_date        Dia a analisar
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/23
       ********************************************************************************************/

    FUNCTION get_hcn_pat_evolution
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_date    IN VARCHAR2,
        o_pat     OUT pk_types.cursor_type,
        o_days    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --        l_date DATE;
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        --        l_date := trunc(nvl(i_date, SYSDATE));
        l_date_tstz := pk_date_utils.trunc_insttimezone(i_prof,
                                                        nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL),
                                                            current_timestamp),
                                                        NULL);
    
        --Abre o array de valores das avalia��es
        g_error := 'OPEN O_PAT ARRAY';
        OPEN o_pat FOR
            SELECT 1,
                   1 rank,
                   -1 id_documentation,
                   pk_message.get_message(i_lang, 'HCN_LABEL_T031') d_component,
                   0 val_min,
                   200 val_max,
                   '0x829664' d_color
              FROM dual
            UNION ALL
            SELECT 2,
                   1 rank,
                   -2 id_documentation,
                   pk_message.get_message(i_lang, 'HCN_LABEL_T020') d_component,
                   0 val_min,
                   20 val_max,
                   '0xFF6633' d_color
              FROM dual
            UNION ALL
            SELECT 3,
                   a.rank,
                   a.id_documentation,
                   pk_translation.get_translation(i_lang, a.code_doc_component) d_component,
                   0 val_min,
                   20 val_max,
                   color.color d_color
              FROM (SELECT rownum linha, rank, id_documentation, code_doc_component, id_episode
                      FROM (SELECT DISTINCT dtad.rank, d.id_documentation, dc.code_doc_component, ed.id_episode
                              FROM epis_documentation ed
                             INNER JOIN hcn_eval he
                                ON he.id_epis_documentation = ed.id_epis_documentation
                             INNER JOIN doc_template_area_doc dtad
                                ON dtad.id_doc_template = ed.id_doc_template
                               AND dtad.id_doc_area = ed.id_doc_area
                             INNER JOIN documentation d
                                ON dtad.id_documentation = d.id_documentation
                             INNER JOIN doc_component dc
                                ON dc.id_doc_component = d.id_doc_component
                             WHERE ed.id_episode = i_episode
                               AND he.flg_status = g_active
                               AND pk_date_utils.trunc_insttimezone(i_prof, he.dt_eval_tstz, NULL) BETWEEN
                                   pk_date_utils.trunc_insttimezone(i_prof,
                                                                    pk_date_utils.add_days_to_tstz(l_date_tstz, -5),
                                                                    NULL) AND
                                   pk_date_utils.trunc_insttimezone(i_prof,
                                                                    pk_date_utils.add_days_to_tstz(l_date_tstz, 4),
                                                                    NULL)
                             ORDER BY dtad.rank)) a,
                   (SELECT rownum linha, color
                      FROM (SELECT DISTINCT color_grafh color
                              FROM vs_soft_inst
                             WHERE color_grafh IS NOT NULL
                               AND color_grafh NOT IN ('0x829664', '0xFF6633'))) color
             WHERE color.linha = a.linha
             GROUP BY a.rank, id_documentation, pk_translation.get_translation(i_lang, a.code_doc_component), color
             ORDER BY 1, rank;
    
        --Abre array com os dias a visualizar na grelha
        g_error := 'OPEN O_DAYS ARRAY';
        OPEN o_days FOR
            SELECT to_number(to_char(pk_date_utils.add_days_to_tstz(l_date_tstz, -6 + rownum), 'dd')) d_day,
                   pk_date_utils.dt_chr_month(i_lang, pk_date_utils.add_days_to_tstz(l_date_tstz, -6 + rownum), i_prof) d_month,
                   pk_date_utils.add_days_to_tstz(l_date_tstz, -6 + rownum) d_date
              FROM dual,
                   (SELECT 1 --Produto cartesiano propositado, de forma a obter o n�mero de registos pretendido
                      FROM sys_config
                     WHERE rownum < 11);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_PAT_EVOLUTION');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_pat);
                pk_types.open_my_cursor(o_days);
                RETURN FALSE;
            END;
        
    END get_hcn_pat_evolution;

    /********************************************************************************************
    * Esta fun��o devolve os valores das avalia��es HCN do paciente, por item e por dias, em pontos.
    *
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_date        Dia a analisar
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/05/02
       ********************************************************************************************/

    FUNCTION get_hcn_eval_total_points
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN TIMESTAMP WITH TIME ZONE --DATE
    ) RETURN NUMBER IS
    
        l_points NUMBER(6, 3);
        -- l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        --        l_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL);
    
        SELECT SUM(total_points)
          INTO l_points
          FROM hcn_eval
         WHERE id_episode = i_episode
           AND flg_status = g_active
           AND pk_date_utils.trunc_insttimezone(i_prof, dt_eval_tstz, NULL) =
               pk_date_utils.trunc_insttimezone(i_prof, i_date, NULL);
    
        RETURN l_points;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_EVAL_TOTAL_POINTS');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            END;
    END get_hcn_eval_total_points;

    /********************************************************************************************
    * Esta fun��o devolve os valores das avalia��es HCN do paciente, por item e por dias, em HCN.
    *
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_date        Dia a analisar
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/05/01
       ********************************************************************************************/

    FUNCTION get_hcn_eval_total_hcn
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN TIMESTAMP WITH TIME ZONE
    ) RETURN NUMBER IS
    
        l_hcn NUMBER(6, 3);
        --      l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        --        l_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL);
    
        SELECT SUM(num_hcn)
          INTO l_hcn
          FROM hcn_eval he, hcn_def_points dp
         WHERE he.id_episode = i_episode
           AND he.flg_status = g_active
           AND pk_date_utils.trunc_insttimezone(i_prof, he.dt_eval_tstz, NULL) =
               pk_date_utils.trunc_insttimezone(i_prof, i_date, NULL)
           AND dp.id_department = he.id_department
           AND he.total_points BETWEEN dp.points_min_value AND dp.points_max_value
           AND dp.id_software IN (0, i_prof.software)
           AND dp.id_institution IN (0, i_prof.institution);
    
        RETURN l_hcn;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_EVAL_TOTAL_HCN');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            END;
    END get_hcn_eval_total_hcn;

    /********************************************************************************************
    * Esta fun��o devolve os valores das avalia��es HCN do paciente, por item e por dias.
    *
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_date        Dia a analisar
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/23
       ********************************************************************************************/

    FUNCTION get_hcn_pat_evolution_array
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_date    IN VARCHAR2,
        o_val     OUT table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_time IS
            SELECT to_number(to_char(pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                     nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                       i_prof,
                                                                                                                                       i_date,
                                                                                                                                       NULL),
                                                                                                         current_timestamp)),
                                                                    -6 + rownum),
                                     'dd')) d_day,
                   
                   pk_date_utils.dt_chr_month_tsz(i_lang,
                                                  pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                  nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                    i_prof,
                                                                                                                                                    i_date,
                                                                                                                                                    NULL),
                                                                                                                      current_timestamp)),
                                                                                 -6 + rownum),
                                                  i_prof) d_month,
                   
                   pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                   nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                                     i_prof,
                                                                                                                     i_date,
                                                                                                                     NULL),
                                                                                       current_timestamp)),
                                                  -6 + rownum) d_date
              FROM dual,
                   (SELECT 1 --Produto cartesiano propositado, de forma a obter o n�mero de registos pretendido
                      FROM sys_config
                     WHERE rownum < 11);
    
        CURSOR c_item IS
            SELECT 1 rank, -1 id_documentation, pk_message.get_message(i_lang, 'HCN_LABEL_T031') d_component
              FROM dual
            UNION ALL
            SELECT 2 rank, -2 id_documentation, pk_message.get_message(i_lang, 'HCN_LABEL_T020') d_component
              FROM dual
            UNION ALL
            SELECT rank, id_documentation, pk_translation.get_translation(i_lang, code_doc_component) d_component
              FROM (SELECT DISTINCT dtad.rank, d.id_documentation, dc.code_doc_component, ed.id_episode
                      FROM epis_documentation ed
                     INNER JOIN hcn_eval he
                        ON he.id_epis_documentation = ed.id_epis_documentation
                     INNER JOIN doc_template_area_doc dtad
                        ON dtad.id_doc_template = ed.id_doc_template
                       AND dtad.id_doc_area = ed.id_doc_area
                     INNER JOIN documentation d
                        ON dtad.id_documentation = d.id_documentation
                     INNER JOIN doc_component dc
                        ON dc.id_doc_component = d.id_doc_component
                     WHERE ed.id_episode = i_episode
                       AND he.flg_status = g_active
                       AND pk_date_utils.trunc_insttimezone(i_prof, he.dt_eval_tstz, NULL) BETWEEN
                           pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                           nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                                             i_prof,
                                                                                                                             i_date,
                                                                                                                             NULL),
                                                                                               current_timestamp),
                                                                                           NULL),
                                                          -5) AND
                           pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                           nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                                             i_prof,
                                                                                                                             i_date,
                                                                                                                             NULL),
                                                                                               current_timestamp),
                                                                                           NULL),
                                                          +4)
                    
                    )
             ORDER BY rank;
    
        CURSOR c_values
        (
            pin_date             IN TIMESTAMP WITH TIME ZONE,
            pin_id_documentation IN NUMBER
        ) IS
            SELECT 1 rank,
                   --                 '0x829664' d_color,
                   pk_hcn.get_hcn_eval_total_points(i_lang, i_prof, i_episode, pin_date) v_day
              FROM dual
             WHERE pin_id_documentation = -1
            UNION ALL
            SELECT 2 rank,
                   --                 '0xFF6633' d_color,
                   pk_hcn.get_hcn_eval_total_hcn(i_lang, i_prof, i_episode, pin_date) v_day
              FROM dual
             WHERE pin_id_documentation = -2
            UNION ALL
            SELECT 3 rank,
                   --                   SUM(pk_hcn.get_hcn_eval_item_points(i_episode, pin_id_documentation, pin_date)) v_day
                   pk_hcn.get_hcn_eval_item_points(i_lang, i_prof, i_episode, pin_id_documentation, pin_date) v_day
              FROM dual
             WHERE pin_id_documentation NOT IN (-1, -2)
             ORDER BY rank;
    
        l_line VARCHAR2(2000) := NULL;
        i      PLS_INTEGER := 0;
    
    BEGIN
    
        g_error := 'INICIALIZA��O';
        o_val   := table_varchar();
        i       := 0;
    
        --Abre lista de items (coordenadas dos Y)
        g_error := 'OPEN C_ITEM';
        FOR r_item IN c_item
        LOOP
            --Adiciona uma posi��o ao array
            o_val.extend;
            i      := i + 1;
            l_line := NULL;
            l_line := r_item.id_documentation || ';';
            --Abre lista de dias (coordenadas dos X)
            g_error := 'OPEN C_TIME';
            FOR r_time IN c_time
            LOOP
                --abre lista dos valores
                g_error := 'OPEN C_VALUES';
                FOR r_values IN c_values(r_time.d_date, r_item.id_documentation)
                LOOP
                    l_line := l_line || r_values.v_day || ';';
                END LOOP;
            END LOOP;
            o_val(i) := l_line;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_PAT_EVOLUTION_ARRAY');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_alert_exceptions.reset_error_state;
                RETURN FALSE;
            END;
        
    END get_hcn_pat_evolution_array;

    /********************************************************************************************
    * Esta fun��o devolve a m�dia de HCN de um epis�dio
    *
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_date        Dia a analisar
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/05/02
       ********************************************************************************************/

    FUNCTION get_hcn_epis_avg
    (
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER IS
    
        l_hcn   NUMBER(12, 3);
        l_count PLS_INTEGER;
    
    BEGIN
    
        --Conta o n�mero de avalia��es existentes
        g_error := 'GET EVAL COUNT';
        SELECT COUNT(*)
          INTO l_count
          FROM hcn_eval
         WHERE id_episode = i_episode
           AND flg_status = g_active;
    
        --Obt�m o total de HCN, em horas, para o epis�dio
        g_error := 'GET EVAL TOTAL HCN';
        SELECT SUM(num_hcn)
          INTO l_hcn
          FROM hcn_eval he, hcn_def_points dp
         WHERE he.id_episode = i_episode
           AND he.flg_status = g_active
           AND dp.id_department = he.id_department
           AND he.total_points BETWEEN dp.points_min_value AND dp.points_max_value
           AND dp.id_software IN (0, i_prof.software)
           AND dp.id_institution IN (0, i_prof.institution);
    
        RETURN round(l_hcn / l_count, 1);
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_hcn_epis_avg;

    /********************************************************************************************
    * Esta fun��o mostra a lista de valores poss�veis para a marca��o de Alta programada, Exames ou Aus�ncia
    * do paciente.
    *
    * @param i_lang        ID do idioma
    * @param i_prof        Id do profissional, institui��o e software
    * @param i_episode     ID do epis�dio
    * @param i_date        Dia seleccionado
    *
    * @param o_list        Array com valores poss�veis para a aloca��o de um doente a um enfermeiro.
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @version             1.0
    * @since               2007/04/27
       ********************************************************************************************/

    FUNCTION get_hcn_disch_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN VARCHAR2,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_date_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_date, NULL);
    
        --Abre array
        g_error := 'GET O_LIST ARRAY';
        OPEN o_list FOR
            SELECT sd.val data, sd.desc_val label
              FROM sys_domain sd
             WHERE sd.id_language = i_lang
               AND sd.code_domain = 'HCN_PAT_DET.FLG_TYPE'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND NOT EXISTS (SELECT 1
                      FROM hcn_pat_det hp
                     WHERE hp.id_episode = i_episode
                       AND hp.flg_status = g_active
                       AND pk_date_utils.trunc_insttimezone(i_prof, hp.dt_status_tstz, NULL) =
                           pk_date_utils.trunc_insttimezone(i_prof, l_date_tstz, NULL)
                       AND hp.flg_type = sd.val)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
                l_error_s   VARCHAR2(4000) := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || g_error;
            BEGIN
                --PLLopes 10/03/2009 - setting error content into input object 
                l_error_in.set_errors(SQLCODE, SQLERRM, l_error_s);
                l_error_in.set_lang(i_lang);
                l_error_in.set_package_id('ALERT', 'PK_HCN', 'GET_HCN_DISCH_LIST');
                -- undo changes quando aplic�vel-> s� faz ROLLBACK 
                --pk_utils.undo_changes;
                -- execute error processing 
                l_ret   := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                o_error := l_error_out;
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_list);
                RETURN FALSE;
            END;
    END get_hcn_disch_list;

    /********************************************************************************************
    * return list of hcn values and scores for the given epis_documentation           
    *                                                                         
    * @param i_lang                   The language ID                         
    * @param i_prof                   Object (professional ID, institution ID,software ID)   
    * @param i_epis_documentation     array with ID_EPIS_DOCUMENTION                        
    *                                                                         
    * @return                         return list of scales epis_documentation       
    *                                                                         
    * @author                         Sofia Mendes                            
    * @version                        2.6.3.8                                
    * @since                          2013/10/21                              
    **************************************************************************/
    FUNCTION tf_hcn_score
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN table_number
    ) RETURN t_coll_hcn_score
        PIPELINED IS
    
        l_coll_hcn      t_coll_hcn_score;
        l_message_score sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'HCN_LABEL_T005');
        l_message_hcn   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'HCN_LABEL_T006');
    
        CURSOR c_hcn IS
            SELECT ed.id_epis_documentation,
                   ed.id_doc_template,
                   l_message_score || ': ' || he.total_points || CASE
                        WHEN hdp.num_hcn IS NOT NULL THEN
                         chr(10) || l_message_hcn || ' ' || hdp.num_hcn
                    END desc_class,
                   he.total_points,
                   hdp.num_hcn,
                   ed.id_professional,
                   ed.dt_last_update_tstz,
                   ed.flg_status
              FROM epis_documentation ed
            
             INNER JOIN hcn_eval he
                ON he.id_epis_documentation = ed.id_epis_documentation
              LEFT JOIN hcn_def_points hdp
                ON hdp.id_department = he.id_department
               AND nvl(pk_hcn.get_eval_total_points(ed.id_epis_documentation), 0) BETWEEN hdp.points_min_value AND
                   hdp.points_max_value
            
             WHERE ed.id_epis_documentation IN (SELECT /*+opt_estimate(table,t,scale_rows=0.00001)*/
                                                 t.column_value
                                                  FROM TABLE(i_epis_documentation) t);
    
    BEGIN
    
        OPEN c_hcn;
        LOOP
            FETCH c_hcn BULK COLLECT
                INTO l_coll_hcn LIMIT 500;
            FOR i IN 1 .. l_coll_hcn.count
            LOOP
                PIPE ROW(l_coll_hcn(i));
            END LOOP;
            EXIT WHEN c_hcn%NOTFOUND;
        END LOOP;
        CLOSE c_hcn;
    
        RETURN;
    
    END tf_hcn_score;

    /**********************************************************************************************
    * get actions of the HCN records
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_epis_documentation      Epis documentation id
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                29-Oct-2013
    **********************************************************************************************/
    FUNCTION get_hcn_actions
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_actions            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL PK_ACTION.TF_GET_ACTIONS';
        pk_alertlog.log_debug(g_error);
        OPEN o_actions FOR
            SELECT NULL id_action, --it is sent Null to be threated the same form as the touch-option actions
                   id_parent,
                   level_nr,
                   from_state,
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   flg_active,
                   action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, 'HCN_ACTION', NULL)) act;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_HCN',
                                              'GET_HCN_ACTIONS',
                                              o_error);
            RETURN FALSE;
    END get_hcn_actions;

    /**********************************************************************************************
    * Check if the epis_documentation is an HCN record
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_epis_documentation      Epis documentation id
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  1- It is an hcn record; 0 - otherwise
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                29-Oct-2013
    **********************************************************************************************/
    FUNCTION check_is_hcn_record
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN NUMBER IS
        l_id_doc_area doc_area.id_doc_area%TYPE;
        l_error       t_error_out;
    BEGIN
        g_error := 'Check if it is an HCN record. i_epis_documentation: ' || i_epis_documentation;
        pk_alertlog.log_debug(g_error);
        SELECT ed.id_doc_area
          INTO l_id_doc_area
          FROM epis_documentation ed
         WHERE ed.id_epis_documentation = i_epis_documentation;
    
        IF (l_id_doc_area = g_hcn_doc_area)
        THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_HCN',
                                              'check_is_hcn_record',
                                              l_error);
            RETURN NULL;
    END check_is_hcn_record;

    /********************************************************************************************
    * Cancel an hcn documentation
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_test                   Indica se deve mostrar a confirma��o de altera��o
    * @param o_flg_show               Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title              T�tulo da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text               Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                 Bot�es a mostrar: N - N�o, R - lido, C - confirmado 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.8.3.4
    * @since                          29-10-2013
    **********************************************************************************************/
    FUNCTION cancel_hcn_documentation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_touch_option.cancel_epis_doc_no_commit. i_id_epis_doc: ' || i_id_epis_doc;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.cancel_epis_doc_no_commit(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_id_epis_doc   => i_id_epis_doc,
                                                         i_notes         => NULL,
                                                         i_test          => i_test,
                                                         i_cancel_reason => NULL,
                                                         o_flg_show      => o_flg_show,
                                                         o_msg_title     => o_msg_title,
                                                         o_msg_text      => o_msg_text,
                                                         o_button        => o_button,
                                                         o_error         => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL pk_hcn.cancel_eval_hcn. i_id_epis_doc: ' || i_id_epis_doc;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_hcn.cancel_eval_hcn(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_epis_documentation => i_id_epis_doc,
                                      o_error              => o_error)
        THEN
            ROLLBACK;
            RETURN FALSE;
        END IF;
    
        --
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_HCN', 'cancel_hcn_documentation');
                ROLLBACK;
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            
            END;
        
    END cancel_hcn_documentation;

END pk_hcn;
/
