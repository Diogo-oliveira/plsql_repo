/*-- Last Change Revision: $Rev: 2027728 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_clinical_info AS

    /**
    * Obter as labels utilizadas pelo ecrã de Resumo da Informação Clínica.
    *
    * @param i_lang        ID da lingua
    * @param i_mess_code   Array de códigos de mensagens para obter as labels do ecran
    * @param i_prof        ID do profissional, instituição e software
    * @param o_mess        Array de labels  
    * @param o_error       Mensagem de erro
    *
    * @return              true /false
    *
    * @author RB, 2005/08/30
    */

    FUNCTION get_ci_summary_labels
    (
        i_lang      IN language.id_language%TYPE,
        i_mess_code IN table_varchar,
        i_prof      IN profissional,
        o_mess      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code_list  VARCHAR2(1000);
        l_first_code BOOLEAN := TRUE;
    
    BEGIN
    
        --lê array com os códigos das mensagens a obter
        g_error := 'GET CODE ARRAY';
        FOR i IN 1 .. i_mess_code.count
        LOOP
            --constroi lista de códigos a obter
            IF l_first_code
            THEN
                l_code_list  := '''' || i_mess_code(i) || '''';
                l_first_code := FALSE;
            ELSE
                l_code_list := l_code_list || ', ''' || i_mess_code(i) || '''';
            END IF;
        END LOOP;
    
        --constroi query a executar para a obtenção das labels
        g_error := 'GET CURSOR STRING';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_message.get_message_array(i_lang, i_mess_code, o_mess)
        THEN
            pk_types.open_my_cursor(o_mess);
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
                                              'GET_CI_SUMMARY_LABELS',
                                              o_error);
            pk_types.open_my_cursor(o_mess);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter as últimas leituras de sinais vitais do paciente para mostrar no ecrâ de resumo da
    *  informação clínica.
    *
    * @param i_lang        Id do idioma
    * @param i_id_patient  ID do paciente
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_vital_signs Cursor com as leituras dos sinais vitais
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2005/09/27
       ********************************************************************************************/

    FUNCTION get_ci_vs_reads
    (
        i_lang        IN language.id_language%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_prof        IN profissional,
        o_vital_signs OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sys_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    
    BEGIN
    
        --obtem o ID do atalho dos sinais vitais
        g_error := 'GET SHORTCUT ID';
        pk_alertlog.log_debug(g_error);
        SELECT pk_sr_clinical_info.get_sys_shortcut(i_lang, 'SR_CLINICAL_INFO_SUMMARY_VITAL_SIGNS')
          INTO l_id_sys_shortcut
          FROM dual;
    
        --Abre cursor com a leitura dos sinais vitais
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_vital_signs FOR
            SELECT decode(id_vital_sign,
                          1,
                          1, --Temperatura aux.
                          8,
                          2, --Pulso
                          28,
                          3, --Tensão arterial
                          5,
                          4, --Frequência Respiratória
                          18,
                          5, --Glasgow
                          2,
                          7, -- DX
                          15,
                          9, --Sat.O2
                          17,
                          10, --PCO2
                          27,
                          11, --PO2
                          10,
                          12, --HCO3
                          16,
                          13, --Ph
                          100 --outros
                          ) num_col,
                   id_vital_sign,
                   vs_desc,
                   vs_value,
                   vs_measure,
                   hour_vs_read,
                   dt_vs_read,
                   id_atalho
              FROM (SELECT vs.id_vital_sign,
                           pk_translation.get_translation(i_lang, vs.code_vs_short_desc) vs_desc,
                           to_char(vs_ea.value) vs_value,
                           pk_translation.get_translation(i_lang, um.code_unit_measure) vs_measure,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            vs_ea.dt_vital_sign_read,
                                                            i_prof.institution,
                                                            i_prof.software) hour_vs_read,
                           pk_date_utils.dt_chr_short_tsz(i_lang, vs_ea.dt_vital_sign_read, i_prof) dt_vs_read,
                           l_id_sys_shortcut id_atalho
                      FROM vital_sign vs
                      LEFT JOIN vital_signs_ea vs_ea
                        ON vs_ea.id_patient = i_id_patient
                       AND vs_ea.id_vital_sign = vs.id_vital_sign
                       AND vs_ea.flg_state = g_status_active
                      LEFT JOIN unit_measure um
                        ON um.id_unit_measure = vs_ea.id_unit_measure
                     WHERE vs.id_vital_sign IN (1, 8, 5, 2, 15, 17, 27, 10, 16)
                       AND (pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0 OR
                           vs_ea.id_vital_sign_read IS NULL)
                    UNION ALL
                    --Total GLASGOW
                    SELECT DISTINCT r.id_vital_sign_parent id_vital_sign,
                                    (SELECT pk_translation.get_translation(i_lang, vs.code_vs_short_desc)
                                       FROM vital_sign vs
                                      WHERE vs.id_vital_sign = r.id_vital_sign_parent) vs_desc,
                                    to_char(aux.value) vs_value,
                                    NULL vs_measure,
                                    NULL hour_vs_read,
                                    NULL dt_vs_read,
                                    l_id_sys_shortcut id_atalho
                      FROM vital_sign vs,
                           vital_sign_relation r,
                           (SELECT r1.id_vital_sign_parent, SUM(vsd1.value) VALUE
                              FROM vital_sign_desc vsd1, vital_sign_relation r1, vital_signs_ea vs_ea1
                             WHERE r1.relation_domain = g_vs_rel_sum
                               AND r1.id_vital_sign_detail = vs_ea1.id_vital_sign
                               AND vs_ea1.id_patient = i_id_patient
                               AND vs_ea1.flg_state(+) = g_status_active
                               AND vsd1.id_vital_sign_desc = vs_ea1.id_vital_sign_desc
                               AND (pk_delivery.check_vs_read_from_fetus(vs_ea1.id_vital_sign_read) = 0 OR
                                   vs_ea1.id_vital_sign_read IS NULL)
                             GROUP BY r1.id_vital_sign_parent) aux
                     WHERE r.id_vital_sign_parent = vs.id_vital_sign
                       AND r.relation_domain = g_vs_rel_sum
                       AND aux.id_vital_sign_parent(+) = vs.id_vital_sign
                    UNION ALL
                    --Pressão Arterial
                    SELECT s.id_vital_sign,
                           pk_translation.get_translation(i_lang, s.code_vs_short_desc) vs_desc,
                           MAX(aux.value) || decode(MAX(aux.value), NULL, NULL, '/') || MIN(aux.value) vs_value,
                           pk_translation.get_translation(i_lang, um.code_unit_measure) vs_measure,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            MAX(aux.dt_vital_sign_read),
                                                            i_prof.institution,
                                                            i_prof.software) hour_vs_read,
                           pk_date_utils.dt_chr_short_tsz(i_lang, MAX(aux.dt_vital_sign_read), i_prof) dt_vs_read,
                           l_id_sys_shortcut id_atalho
                      FROM vital_sign s,
                           vital_sign_relation rl,
                           (SELECT vs.id_vital_sign,
                                   vs_ea.dt_vital_sign_read,
                                   l.id_vital_sign_parent,
                                   vs_ea.value,
                                   vs_ea.id_unit_measure
                              FROM vital_sign vs, vital_signs_ea vs_ea, vital_sign_relation l
                             WHERE vs_ea.id_patient = i_id_patient
                               AND vs_ea.flg_state = g_status_active
                               AND vs_ea.id_vital_sign = l.id_vital_sign_detail
                               AND l.relation_domain = g_vs_rel_conc
                               AND vs.id_vital_sign = vs_ea.id_vital_sign
                               AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0) aux,
                           unit_measure um
                     WHERE rl.relation_domain = g_vs_rel_conc
                       AND s.id_vital_sign = rl.id_vital_sign_parent
                       AND aux.id_vital_sign_parent(+) = s.id_vital_sign
                       AND um.id_unit_measure(+) = aux.id_unit_measure
                     GROUP BY s.id_vital_sign,
                              pk_translation.get_translation(i_lang, s.code_vs_short_desc),
                              pk_translation.get_translation(i_lang, um.code_unit_measure))
             ORDER BY num_col;
    
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
                                              'GET_CI_VS_READS',
                                              o_error);
            pk_types.open_my_cursor(o_vital_signs);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter os dados relativos a anestesia/medicação, sangue, exames e imagem, procedimentos e
    * protocolos cirúrgicos e anestésicos, de forma a preencher a respectiva grelha do ecrã de
    * Resumo da Informação clínica.
    *
    * @param i_lang        Id do idioma
    * @param i_id_episode  ID do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_dt_server   Data/Hora do sistema
    * @param o_anest       Array de anestesia/medicação
    * @param o_hemo        Array de sangue, exames e imagens 
    * @param o_proc        Array de procedimentos
    * @param o_prot        Array de protocolos cirúrgicos/anestésicos
    * @param o_req_icon    Nome do icon a mostrar para registos no estado Requisitado
    * @param o_done_icon   Nome do icon a mostrar para registos no estado Concluído
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2005/09/30
    * @notes               Cada registo pode ter um tempo que falta ou que passa em relação à hora prevista da adminstração
    *                      do medicamento. Além deste tempo, devolve também uma flag que indica:
    *                      R - Fundo a vermelho. Administração em atrazo    
    *                      G - Fundo a verde. Administração agendada para o futuro.
       ********************************************************************************************/

    FUNCTION get_ci_grid
    (
        i_lang             IN language.id_language%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        o_anest            OUT pk_types.cursor_type,
        o_hemo             OUT pk_types.cursor_type,
        o_proc             OUT pk_types.cursor_type,
        o_prot             OUT pk_types.cursor_type,
        o_days_warning     OUT sys_message.desc_message%TYPE,
        o_flg_show_warning OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_inst IS
            SELECT v.id_institution, v.id_visit, e.id_epis_type, e.flg_status
              FROM episode e, visit v
             WHERE e.id_episode = i_id_episode
               AND v.id_visit = e.id_visit;
    
        l_inst             visit.id_institution%TYPE;
        l_id_visit         visit.id_visit%TYPE;
        l_epis_type        epis_type.id_epis_type%TYPE;
        l_sr_time_margin_r NUMBER;
        l_epis_flg_status  episode.flg_status%TYPE;
        l_exception EXCEPTION;
        l_table_summary_grid_exam     t_table_summary_grid_exam;
        l_table_summary_grid_analy    t_table_summary_grid_analy;
        l_cfg_closed_task_filter      sys_config.value%TYPE;
        l_closed_task_filter_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
        l_closed_task_filt_medication INTERVAL DAY TO SECOND;
    
        l_exam_status table_varchar;
    
        l_analysis_status table_varchar;
    
        l_procedures_status      table_varchar;
        l_nursing_status         table_varchar;
        l_filter_status_sr_posit table_varchar;
    
        l_filter_status_sr_reserv    table_varchar;
        l_medication_status          table_varchar;
        l_filter_status_sr_protocols table_varchar;
        l_id_category                category.id_category%TYPE;
        l_param                      table_varchar := table_varchar();
    
        l_screens table_varchar := table_varchar('SR_CLINICAL_INFO_SUMMARY_DRUG_PRESC', --LIST_IVFLUIDS
                                                 'SR_CLINICAL_INFO_SUMMARY_DRUG_PRESC', --LIST_DRUG
                                                 'GRID_OTH_EXAM', --LIST_OTHER_EXAM
                                                 'GRID_IMAGE', --LIST_IMAGE
                                                 'GRID_ANALYSIS', --LIST_ANALYSIS
                                                 'GRID_HARVEST', --LIST_TUBE
                                                 'SR_CLINICAL_INFO_SUMMARY_INTERV_PRESC', --LIST_PROC
                                                 'GRID_PAT_EDUCATION', --LIST_NURSE_TEACH
                                                 'SR_RESERVE',
                                                 'SR_CLINICAL_INFO_SUMMARY_PROTOCOLS',
                                                 'SR_CLINICAL_INFO_SUMMARY_POSIT',
                                                 'SR_SURGICAL_SUPPLIES');
    
        l_scr_alias table_varchar := table_varchar('LIST_IVFLUIDS',
                                                   'LIST_DRUG',
                                                   'GRID_OTH_EXAM',
                                                   'GRID_IMAGE',
                                                   'GRID_ANALYSIS',
                                                   'GRID_HARVEST',
                                                   'LIST_PROC',
                                                   'LIST_NURSE_TEACH',
                                                   'SR_RESERVE',
                                                   'SR_CLINICAL_INFO_SUMMARY_PROTOCOLS',
                                                   'SR_CLINICAL_INFO_SUMMARY_POSIT',
                                                   'SR_SURGICAL_SUPPLIES');
    
    BEGIN
    
        g_error := 'CALL PK_ACCESS.GET_SHORTCUTS_ARRAY';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_access.preload_shortcuts(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_screens   => l_screens,
                                           i_scr_alias => l_scr_alias,
                                           o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET PROFESSIONAL CATEGORY FOR THE PROFESSIONAL ID: ' || i_prof.id;
        pk_alertlog.log_debug(g_error);
        l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        -- Obter prazo limite antes da cirurgia para terminar posicionamentos e reservas.
        g_error := 'GET PROC TME LIMIT';
        pk_alertlog.log_debug(g_error);
        l_sr_time_margin_r := to_number(nvl(pk_sysconfig.get_config('SR_TIME_MARGIN_RES', i_prof), 0));
        l_sr_time_margin_r := -l_sr_time_margin_r;
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        --Verifica visita para episodio
        g_error := 'OPEN c_inst';
        pk_alertlog.log_debug(g_error);
        OPEN c_inst;
        FETCH c_inst
            INTO l_inst, l_id_visit, l_epis_type, l_epis_flg_status;
        CLOSE c_inst;
    
        g_error := 'CALL PK_SYSCONFIG.GET_CONFIG';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sysconfig.get_config(pk_edis_summary.g_cfg_closed_task_filter, i_prof, l_cfg_closed_task_filter)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_outpatient
           OR i_prof.software = pk_alert_constant.g_soft_inpatient
           OR i_prof.software = pk_alert_constant.g_soft_oris
           OR i_prof.software = pk_alert_constant.g_soft_edis
        THEN
        
            l_closed_task_filter_tstz := current_timestamp -
                                         numtodsinterval(to_number(l_cfg_closed_task_filter), 'DAY');
        
            l_closed_task_filt_medication := numtodsinterval(to_number((l_cfg_closed_task_filter * -1)), 'DAY');
        
            o_flg_show_warning := pk_alert_constant.get_yes;
        
            l_exam_status := pk_edis_summary.g_exam_status;
        
            l_analysis_status := pk_edis_summary.g_analysis_status;
        
            l_procedures_status      := pk_edis_summary.g_procedures_status;
            l_nursing_status         := pk_edis_summary.g_nursing_status;
            l_filter_status_sr_posit := pk_sr_clinical_info.g_filter_status_sr_posit;
        
            l_filter_status_sr_reserv := g_filter_status_sr_reserv;
            l_medication_status       := pk_edis_summary.g_medication_status;
            l_filter_status_sr_reserv := g_filter_status_sr_reserv;
        
            IF to_number(l_cfg_closed_task_filter) > 1
            THEN
            
                o_days_warning := REPLACE(pk_message.get_message(i_lang => i_lang, i_code_mess => g_summary_filter),
                                          '@1',
                                          l_cfg_closed_task_filter);
            ELSE
                o_days_warning := pk_message.get_message(i_lang => i_lang, i_code_mess => g_summary_filter_one);
            END IF;
        ELSE
            l_closed_task_filter_tstz := NULL;
            o_flg_show_warning        := pk_alert_constant.get_no;
        
            l_exam_status := NULL;
        
            l_analysis_status := NULL;
        
            l_procedures_status      := NULL;
            l_nursing_status         := NULL;
            l_filter_status_sr_posit := NULL;
        
            l_filter_status_sr_reserv    := NULL;
            l_medication_status          := NULL;
            l_filter_status_sr_reserv    := NULL;
            l_filter_status_sr_protocols := NULL;
        
            o_days_warning := NULL;
        END IF;
    
        g_error := 'CALL PK_EDIS_SUMMARY.TF_SUMMARY_GRID_EXAM FOR ID_VISIT: ' || l_id_visit;
        pk_alertlog.log_debug(g_error);
        l_table_summary_grid_exam := pk_edis_summary.tf_summary_grid_exam(i_lang          => i_lang,
                                                                          i_prof          => i_prof,
                                                                          i_id_visit      => l_id_visit,
                                                                          i_epis_type     => l_epis_type,
                                                                          i_filter_tstz   => l_closed_task_filter_tstz,
                                                                          i_filter_status => l_exam_status);
    
        g_error := 'CALL PK_EDIS_SUMMARY.TF_SUMMARY_GRID_ANALY FOR ID_VISIT: ' || l_id_visit;
        pk_alertlog.log_debug(g_error);
        l_table_summary_grid_analy := pk_edis_summary.tf_summary_grid_analy(i_lang          => i_lang,
                                                                            i_prof          => i_prof,
                                                                            i_id_visit      => l_id_visit,
                                                                            i_epis_type     => l_epis_type,
                                                                            i_filter_tstz   => l_closed_task_filter_tstz,
                                                                            i_filter_status => l_analysis_status);
    
        --obtem dados da prescrição e administração de anestesia e medicação
        g_error := 'OPEN O_ANEST CURSOR';
        g_error := 'CALL PK_EDIS_SUMMARY.TF_SUMMARY_GRID_EXAM FOR ID_VISIT: ' || l_id_visit;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_clindoc_in.get_current_medication(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_episode          => i_id_episode,
                                                            i_filter_date         => l_closed_task_filt_medication,
                                                            o_pat_medication_list => o_anest,
                                                            o_error               => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        -------------------------------------------------------------------------------------------------------------------
        --Obtem dados das requisições de hemoderivados, exames e imagem
        g_error := 'OPEN O_HEMO CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_hemo FOR --Sangue
            SELECT pk_date_utils.date_send_tsz(i_lang, r.dt_req_tstz, i_prof) dt_req,
                   pk_sysdomain.get_rank(i_lang, 'SR_RESERV_REQ.FLG_STATUS', r.flg_status) rank_status,
                   pk_translation.get_translation(i_lang, sq.code_equip) description,
                   r.flg_status,
                   g_sysdate_char dt_server,
                   pk_access.get_shortcut('SR_RESERVE') ||
                   decode(r.flg_status,
                          pk_sr_planning.g_reserv_req,
                          decode(pk_date_utils.compare_dates_tsz(i_prof, current_timestamp, sr.dt_interv_preview_tstz),
                                 g_flg_time_g,
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_p,
                                                                     r.flg_status,
                                                                     g_flg_time_e,
                                                                     r.flg_status,
                                                                     r.dt_req_tstz,
                                                                     r.dt_req_tstz,
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_RESERV.FLG_STATUS',
                                                                                          r.flg_status)),
                                 pk_sr_clinical_info.get_string_task(i_lang,
                                                                     i_prof,
                                                                     g_flg_type_p,
                                                                     r.flg_status,
                                                                     g_flg_time_e,
                                                                     r.flg_status,
                                                                     pk_date_utils.add_to_ltstz(sr.dt_target_tstz,
                                                                                                l_sr_time_margin_r,
                                                                                                'MINUTE'),
                                                                     pk_date_utils.add_to_ltstz(sr.dt_target_tstz,
                                                                                                l_sr_time_margin_r,
                                                                                                'MINUTE'),
                                                                     pk_sysdomain.get_img(i_lang,
                                                                                          'SR_RESERV.FLG_STATUS',
                                                                                          r.flg_status))),
                          pk_utils.get_status_string(i_lang,
                                                     i_prof,
                                                     '|I|||#|||||&',
                                                     '',
                                                     'HEMO_REQ_DET.FLG_STATUS',
                                                     r.flg_status)) icon_name1,
                   pk_alert_constant.g_no flg_external
              FROM sr_equip sq, sr_reserv_req r, episode e, schedule_sr sr
             WHERE sq.id_sr_equip = r.id_sr_equip
               AND e.id_episode = i_id_episode
               AND r.id_episode_context = e.id_episode
               AND sr.id_episode = e.id_episode
               AND sr.id_episode = r.id_episode_context
               AND sq.flg_hemo_yn = pk_alert_constant.g_yes
               AND r.flg_status != g_cancel
                  --
               AND (r.flg_status NOT IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                          t.column_value
                                           FROM TABLE(l_filter_status_sr_reserv) t) OR
                   r.dt_req_tstz > l_closed_task_filter_tstz)
            --
            UNION ALL
            SELECT DISTINCT dt_req,
                            rank_status            AS rank,
                            description,
                            flg_status,
                            g_sysdate_char         dt_server,
                            icon_name1             AS status_str,
                            pk_alert_constant.g_no flg_external
              FROM TABLE(l_table_summary_grid_exam)
            UNION ALL
            SELECT DISTINCT dt_req,
                            rank_status    AS rank,
                            description,
                            flg_status,
                            g_sysdate_char dt_server,
                            icon_name1     AS status_str,
                            flg_external
              FROM TABLE(l_table_summary_grid_analy)
             ORDER BY 2, 1;
    
        -------------------------------------------------------------------------------------------------------------------
        --Otem dados das prescrições de procedimentos        
    
        g_error := 'CALL PK_EDIS_SUMMARY.GET_SUMMARY_GRID_PROC';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_edis_summary.get_summary_grid_proc(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_episode            => i_id_episode,
                                                     i_flg_stat_epis      => l_epis_flg_status,
                                                     i_filter_tstz        => l_closed_task_filter_tstz,
                                                     i_filter_status_proc => l_procedures_status,
                                                     i_filter_status_nur  => l_nursing_status,
                                                     i_filter_status_oris => l_filter_status_sr_posit,
                                                     o_proc               => o_proc,
                                                     o_error              => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        -------------------------------------------------------------------------------------------------------------------        
    
        --Obtem dados da activação de protocolos cirúrgicos e anestésicos
        g_error := 'OPEN CURSOR O_PROT';
        OPEN o_prot FOR
            SELECT pk_workflow.get_status_rank(i_lang,
                                               i_prof,
                                               pk_supplies_constant.g_id_workflow_sr,
                                               sws.id_status,
                                               l_id_category,
                                               NULL,
                                               NULL,
                                               l_param) num_order,
                   pk_date_utils.date_send_tsz(i_lang, sw.dt_request, i_prof) num_order2,
                   sw.id_supply_workflow,
                   pk_translation.get_translation(i_lang, 'SUPPLY.CODE_SUPPLY.' || sw.id_supply) description,
                   '(' || sw.quantity || ' ' || pk_message.get_message(i_lang, 'SR_UNIT') || ')' desc_dosage,
                   pk_date_utils.date_send_tsz(i_lang, sw.dt_request, i_prof) dt_req,
                   sw.flg_status,
                   pk_sup_status.get_sup_status_string(i_lang,
                                                       i_prof,
                                                       sw.flg_status,
                                                       pk_access.get_shortcut('SR_SURGICAL_SUPPLIES'),
                                                       pk_supplies_constant.g_id_workflow_sr,
                                                       l_id_category,
                                                       sw.dt_supply_workflow,
                                                       sw.id_episode) status_str,
                   g_sysdate_char dt_server,
                   decode(s.flg_type, 'S', 1, 'K', 2, 3) flg_type_rank
              FROM supply_workflow sw
             INNER JOIN supplies_wf_status sws
                ON sws.flg_status = sw.flg_status
             INNER JOIN supply s
                ON sw.id_supply = s.id_supply
             WHERE sw.id_supply_area = pk_supplies_constant.g_area_surgical_supplies
               AND sw.id_supply_set IS NULL
               AND sw.id_episode = i_id_episode
               AND sw.flg_status != g_cancel
               AND sws.id_category = l_id_category
               AND (sw.flg_status NOT IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                           t.column_value
                                            FROM TABLE(g_filter_status_sr_supplies) t) OR
                   sw.dt_request > l_closed_task_filter_tstz)
             ORDER BY flg_type_rank, num_order, num_order2 DESC;
    
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
                                              'GET_CI_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_anest);
            pk_types.open_my_cursor(o_hemo);
            pk_types.open_my_cursor(o_proc);
            pk_types.open_my_cursor(o_prot);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Chama a função que constroi a string do estados dos workflows para ser utilizado numa grelha
    *
    * @param i_lang          Id do idioma
    * @param i_prof          Id do profissional, instituição e software
    * @param i_type          Tipo de workflow (as análises têm lógica de estados diferentes)
    * @param i_epis_status   Estado do episódio
    * @param i_flg_time      Realização: E - neste episódio; N - próximo episódio; B - entre episódios
    * @param i_flg_status    Estado da requisição
    * @param i_dt_begin      Data pretendida para início da execução do exame (ie, não imediata) 
    * @param i_dt_req        Data / hora de requisição 
    * @param i_icon_name     Nome da imagem do estado da requisição
    *
    * @return                String com o estado do workflow
    *
    * @author              Rui Batista
    * @since               2006/02/27 
       ********************************************************************************************/

    FUNCTION get_string_task(i_lang IN language.id_language%TYPE,
                             -- JS, 2007-09-08 - Timezone
                             i_prof        IN profissional,
                             i_type        IN VARCHAR2,
                             i_epis_status IN episode.flg_status%TYPE,
                             i_flg_time    IN VARCHAR2,
                             i_flg_status  IN VARCHAR2,
                             i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
                             i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
                             i_icon_name   IN VARCHAR2) RETURN VARCHAR2 IS
    
        l_task        VARCHAR2(120);
        l_error_strut t_error_out;
    
    BEGIN
    
        g_error := 'CALL PK_SR_CLINICAL_INFO.GET_SR_STRING_TASK';
        pk_alertlog.log_debug(g_error);
        l_task := pk_sr_clinical_info.get_sr_string_task(i_lang,
                                                         -- JS, 2007-09-08 - Timezone
                                                         i_prof,
                                                         i_type,
                                                         i_epis_status,
                                                         i_flg_time,
                                                         i_flg_status,
                                                         i_dt_begin,
                                                         i_dt_req,
                                                         i_icon_name,
                                                         l_error_strut);
    
        RETURN l_task;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END;

    /********************************************************************************************
    * Obter a string constituída por: 
    *    1ª posição indica qual o ID do atalho 
    *    2ª posição:
    *           D - é para fazer cálculos e apresentar tempo.
    *           T - é para apresentar a mensagem AGENDADO e fazer cálculos caso a data esteja preenchida.
    *           I - é para apresentar o ícone dos resultados. 
    *    3ª posição:
    *           se a 2ª posição é D - data
    *           se a 2ª posição é T - AGENDADO
    *           se a 2ª posição é I - nome do ícone 
    *
    * @param i_lang         Id do idioma
    * @param i_epis_status  Estado do episódio 
    * @param i_flg_time     Realização: E - neste episódio; N - próximo episódio; B - entre episódios
    * @param i_flg_status   Estado da requisição 
    * @param i_dt_begin     Data pretendida para início da execução do exame (ie, não imediata) 
    * @param i_dt_req       Data / hora de requisição 
    * @param i_icon_name    Nome da imagem do estado da requisição 
    *
    * @param o_error        Mensagem de erro
    *
    * @return               String com o estado do workflow
    *
    * @author              SS
    * @since               2006/01/19 
       ********************************************************************************************/

    FUNCTION create_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_icon_name   IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
    
        v_out VARCHAR2(200);
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_color_red || '|' || i_icon_name;
    
        RETURN v_out;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_STRING_TASK',
                                              o_error);
            RETURN NULL;
    END;

    /********************************************************************************************
    * Obter a grelha das leituras de sinais vitais.
    *
    * @param i_lang        Id do idioma
    * @param i_id_patient  ID do paciente
    * @param i_prof        Id do profissional, instituição e software
    * @param i_episode     ID do episódio
    * 
    * @param o_vs_header   Array de sinais vitais
    * @param o_vs_det      Array de leituras de sinais vitais
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/05/23 
       ********************************************************************************************/

    FUNCTION get_ci_vs_grid
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_vs_header  OUT pk_types.cursor_type,
        o_vs_det     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Abre cursor com a leitura dos sinais vitais
        g_error := 'OPEN HEADER CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_vs_header FOR
            SELECT decode(vs.id_vital_sign,
                          1,
                          1, --Temperatura aux.
                          8,
                          2, --Pulso
                          28,
                          3, --Tensão arterial
                          5,
                          4, --Frequência Respiratória
                          18,
                          5, --Glasgow
                          2,
                          7, -- DX
                          15,
                          9, --Sat.O2
                          17,
                          10, --PCO2
                          27,
                          11, --PO2
                          10,
                          12, --HCO3
                          16,
                          13, --Ph
                          100 --outros
                          ) num_col,
                   vs.id_vital_sign,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) vs_desc
            --                                      pk_translation.get_translation(I_LANG, vs.code_measure_unit) vs_unit
              FROM vital_sign vs, vital_signs_ea vs_ea
             WHERE vs.id_vital_sign IN (1, 8, 28, 5, 18, 2, 15, 17, 27, 10, 16)
               AND vs_ea.id_patient(+) = i_id_patient
               AND vs_ea.id_vital_sign(+) = vs.id_vital_sign
               AND (pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0 OR
                   vs_ea.id_vital_sign_read IS NULL)
             ORDER BY num_col;
    
        g_error := 'OPEN O_VS_DET CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_vs_det FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, epis.dt_vital_sign_read_tstz, i_prof) dt_vital_sign_read,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    epis.dt_vital_sign_read_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_vs_read,
                   pk_date_utils.dt_chr_short_tsz(i_lang, epis.dt_vital_sign_read_tstz, i_prof) dt_vs_read,
                   (SELECT VALUE
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = epis.id_episode
                       AND vsr.id_vital_sign = 1
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_a,
                   (SELECT VALUE
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = epis.id_episode
                       AND vsr.id_vital_sign = 8
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_b,
                   --Pressão Arterial
                   (SELECT MAX(VALUE) || decode(MAX(VALUE), NULL, NULL, '/') || MIN(VALUE)
                      FROM vital_sign_read vsr, vital_sign_relation r
                     WHERE r.relation_domain = g_vs_rel_conc
                       AND vsr.id_vital_sign = r.id_vital_sign_detail
                       AND vsr.id_episode = epis.id_episode
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_c,
                   (SELECT VALUE
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = epis.id_episode
                       AND vsr.id_vital_sign = 5
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_d,
                   --Total GLASGOW
                   --                                                 (select value from vital_sign_read vsr
                   --                                                  where vsr.id_episode = epis.id_episode
                   --                                                              and vsr.id_vital_sign = 18                                                       
                   --                                                              and vsr.flg_state = G_STATUS_ACTIVE 
                   --                                                              and vsr.dt_vital_sign_read = epis.dt_vital_sign_read ) value_e,
                   (SELECT SUM(vsd.value)
                      FROM vital_sign_read vsr, vital_sign_desc vsd, vital_sign_relation r
                     WHERE vsr.id_episode = epis.id_episode
                       AND r.relation_domain = g_vs_rel_sum
                       AND r.id_vital_sign_detail = vsr.id_vital_sign
                       AND vsr.flg_state = g_status_active
                       AND vsd.id_vital_sign_desc = vsr.id_vital_sign_desc
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_e,
                   (SELECT VALUE
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = epis.id_episode
                       AND vsr.id_vital_sign = 2
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_f,
                   (SELECT VALUE
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = epis.id_episode
                       AND vsr.id_vital_sign = 15
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_g,
                   (SELECT VALUE
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = epis.id_episode
                       AND vsr.id_vital_sign = 17
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_h,
                   (SELECT VALUE
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = epis.id_episode
                       AND vsr.id_vital_sign = 27
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_i,
                   (SELECT VALUE
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = epis.id_episode
                       AND vsr.id_vital_sign = 10
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_j,
                   (SELECT VALUE
                      FROM vital_sign_read vsr
                     WHERE vsr.id_episode = epis.id_episode
                       AND vsr.id_vital_sign = 16
                       AND vsr.flg_state = g_status_active
                       AND vsr.dt_vital_sign_read_tstz = epis.dt_vital_sign_read_tstz
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0) value_l
            -- <DENORM_EPISODE_JOSE_BRITO>
              FROM (SELECT DISTINCT e.id_episode, vsr.dt_vital_sign_read_tstz
                      FROM episode e, vital_sign_read vsr --visit v, 
                     WHERE e.id_patient = i_id_patient --v.id_patient = i_id_patient
                          --AND e.id_visit = v.id_visit
                       AND (e.id_episode = (SELECT MAX(e1.id_episode)
                                              FROM episode e1 --visit v1, 
                                             WHERE e1.id_patient = e.id_patient --v1.id_patient = v.id_patient
                                                  --AND e1.id_visit = v1.id_visit
                                               AND e1.id_episode < i_episode) OR e.id_episode = i_episode)
                       AND vsr.id_episode = e.id_episode
                       AND vsr.flg_state = g_status_active
                       AND vsr.id_vital_sign IN (1, 8, 28, 5, 6, 7, 12, 13, 14, 18, 2, 15, 17, 27, 10, 16)
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                     ORDER BY 2) epis
             ORDER BY epis.dt_vital_sign_read_tstz;
    
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
                                              'GET_CI_VS_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_vs_header);
            pk_types.open_my_cursor(o_vs_det);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter a string constituída por: 
    *       1ª posição indica qual o ID do atalho 
    *       2ª posição:
    *             D - é para fazer cálculos e apresentar tempo.
    *             T - é para apresentar a mensagem AGENDADO e fazer cálculos caso a data esteja preenchida.
    *             I - é para apresentar o ícone dos resultados. 
    *       3ª posição:
    *             se a 2ª posição é D - data
    *             se a 2ª posição é T - AGENDADO
    *             se a 2ª posição é I - nome do ícone 
    *
    * @param i_lang          Id do idioma
    * @param i_prof          Id do profissional, instituição e software
    * @param i_type          Tipo de workflow (as análises têm lógica de estados diferentes)
    * @param i_epis_status   Estado do episódio 
    * @param i_flg_time      Realização: E - neste episódio; N - próximo episódio; B - entre episódios
    * @param i_flg_status    Estado da requisição 
    * @param i_dt_begin      Data pretendida para início da execução do exame (ie, não imediata)
    * @param i_dt_req        Data / hora de requisição 
    * @param i_icon_name     Nome da imagem do estado da requisição 
    *
    * @param o_error         Mensagem de erro
    *
    * @return                Array com estado do workflow
    *
    * @author                SS
    * @since                 2006/01/19 
       ********************************************************************************************/

    FUNCTION get_sr_string_task(i_lang IN language.id_language%TYPE,
                                -- JS, 2007-09-08 - Timezone
                                i_prof        IN profissional,
                                i_type        IN VARCHAR2,
                                i_epis_status IN episode.flg_status%TYPE,
                                i_flg_time    IN VARCHAR2,
                                i_flg_status  IN VARCHAR2,
                                i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
                                i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
                                i_icon_name   IN VARCHAR2,
                                o_error       OUT t_error_out) RETURN VARCHAR2 IS
    
        v_out      VARCHAR2(200);
        l_agendado VARCHAR2(20);
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET MESSAGE';
        pk_alertlog.log_debug(g_error);
        l_agendado := pk_message.get_message(i_lang, 'ICON_T056'); --'AGENDADO' 
    
        g_error := 'GET V_OUT STRING';
        pk_alertlog.log_debug(g_error);
        IF i_flg_time = g_flg_time_e
        THEN
            -- Requisição / prescrição foi pedida para o próprio episódio 
        
            IF i_flg_status IN (g_flg_status_f, g_flg_status_l, g_flg_status_s, g_flg_status_i)
            THEN
                -- Tem resultados 
                v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
            
            ELSIF i_flg_status IN (g_flg_status_p, g_flg_status_e)
            THEN
                -- Está em execução 
                v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
            
                --Adicionado em 2006/09/01      
            ELSIF i_flg_status = g_flg_status_c
            THEN
                -- Está cancelado
                v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                --RB
            
            ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_a)
            THEN
                -- requisitado 
                -- JS, 2007-09-10 - Timezone
                -- v_out := to_char(CAST(i_dt_req AS DATE), 'YYYYMMDDHH24MISS') || '|' || g_date || '|' || g_no_color;
                IF i_type = g_flg_type_a
                THEN
                    IF i_dt_begin IS NULL
                    THEN
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_no_color;
                    ELSE
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_no_color;
                    END IF;
                ELSIF i_type = g_flg_type_p
                THEN
                    IF i_dt_begin IS NULL
                    THEN
                        v_out := '|I|||WaitingIcon|||||';
                    ELSE
                        v_out := '|' || g_date || '|' ||
                                 pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, 'YYYYMMDDHH24MISS') || '|||' || '' ||
                                 '||||' ||
                                 pk_date_utils.to_char_insttimezone(i_prof, current_timestamp, 'YYYYMMDDHH24MISS');
                    END IF;
                ELSE
                    IF i_dt_begin IS NULL
                    THEN
                        v_out := '|I|||WaitingIcon|||||' ||
                                 pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
                    ELSE
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_no_color;
                    END IF;
                END IF;
            
            ELSIF i_flg_status = g_flg_status_d
            THEN
                -- pendente 
                IF i_dt_begin IS NULL
                THEN
                    -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_red || '|' || l_agendado;
                ELSE
                    -- JS, 2007-09-10 - Timezone
                    -- v_out := to_char(CAST(i_dt_begin AS DATE), 'YYYYMMDDHH24MISS') || '|' || g_date || '|' ||
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_no_color;
                END IF;
            
            ELSIF i_flg_status = g_read
            THEN
                -- lido 
                v_out := NULL;
            END IF; -- I_FLG_STATUS 
        
        ELSIF i_flg_time = g_flg_time_n
        THEN
            -- Requisição / prescrição foi pedida para o próximo episódio 
            --if I_FLG_STATUS = G_FLG_STATUS_D then -- pendente 
            v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_green || '|' || l_agendado;
        
        ELSIF i_flg_time = g_flg_time_b
        THEN
            -- Requisição / prescrição foi pedida até ao próximo episódio 
            IF i_flg_status = g_flg_status_d
            THEN
                -- pendente 
                IF i_dt_begin IS NULL
                THEN
                    -- exames e análises (se FLG_TIME=B então DT_BEGIN=NULL=não aplicável)
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_green || '|' || l_agendado;
                ELSE
                    -- JS, 2007-09-10 - Timezone
                    -- v_out := to_char(CAST(i_dt_begin AS DATE), 'YYYYMMDDHH24MISS') || '|' || g_date || '|' ||
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_no_color;
                END IF;
            
            ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_a)
            THEN
                -- requisição  
                -- JS, 2007-09-10 - Timezone
                -- v_out := to_char(CAST(i_dt_req AS DATE), 'YYYYMMDDHH24MISS') || '|' || g_date || '|' || g_no_color;
                v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, 'YYYYMMDDHH24MISS TZR') || '|' || g_date || '|' ||
                         g_no_color;
            
            END IF;
        ELSIF i_flg_time = g_flg_time_r
        THEN
            --Exames trazidos pelo paciente
            v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
        END IF; -- I_FLG_TIME 
        --  END IF; -- I_EPIS_STATUS 
    
        RETURN v_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_STRING_TASK',
                                              o_error);
        
            RETURN NULL;
    END;
    /********************************************************************************************
    * retrieve all available diagnosis, by episode
    *
    * @param i_lang        Id Language in use by the user
    * @param i_prof        Professional ID, Institution ID, Software ID
    * @param i_episode     Episode ID
    *
    * @return              string containing all available diagnosis for a certain episode
    *
    * @author              Pedro Santos
    * @since               2008/08/21
       ********************************************************************************************/

    FUNCTION get_summary_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_short_description IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
    
        l_diagtotext VARCHAR2(2000) := NULL;
    
    BEGIN
    
        FOR diag_rec IN (SELECT DISTINCT -- ALERT-736: diagnosis synonyms support
                                          pk_diagnosis.std_diag_desc(i_lang                  => i_lang,
                                                                     i_prof                  => i_prof,
                                                                     i_id_alert_diagnosis    => ad.id_alert_diagnosis,
                                                                     i_id_diagnosis          => d.id_diagnosis,
                                                                     i_desc_epis_diagnosis   => eds.desc_epis_diagnosis,
                                                                     i_code                  => d.code_icd,
                                                                     i_flg_other             => d.flg_other,
                                                                     i_flg_std_diag          => ad.flg_icd9,
                                                                     i_epis_diag             => eds.id_epis_diagnosis,
                                                                     i_show_aditional_info   => CASE
                                                                                                    WHEN i_short_description = pk_alert_constant.g_yes THEN
                                                                                                     pk_alert_constant.g_no
                                                                                                    ELSE
                                                                                                     NULL
                                                                                                END,
                                                                     i_flg_show_term_code    => CASE
                                                                                                    WHEN i_short_description = pk_alert_constant.g_yes THEN
                                                                                                     pk_alert_constant.g_no
                                                                                                    ELSE
                                                                                                     NULL
                                                                                                END,
                                                                     i_flg_show_ae_diag_info => CASE
                                                                                                    WHEN i_short_description = pk_alert_constant.g_yes THEN
                                                                                                     pk_alert_constant.g_no
                                                                                                    ELSE
                                                                                                     NULL
                                                                                                END) desc_diag,
                                         d.id_diagnosis diag
                           FROM epis_diagnosis eds, diagnosis d, alert_diagnosis ad
                          WHERE eds.id_episode = i_episode
                            AND eds.flg_status NOT IN (g_cancel, g_excluded)
                            AND eds.id_diagnosis = d.id_diagnosis
                            AND eds.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                          ORDER BY diag)
        LOOP
            l_diagtotext := l_diagtotext || ', ' || diag_rec.desc_diag;
        END LOOP;
        l_diagtotext := ltrim(l_diagtotext, ',');
    
        RETURN l_diagtotext;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;
    /********************************************************************************************
    * Obter o diagnóstico base da página resumo
    *
    * @param i_lang        Id do idioma
    * @param i_episode     ID do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_title       Título a mostrar na página resumo 
    * @param o_diag        Lista de Diagnósticos base do episódio
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/08/30
       ********************************************************************************************/

    FUNCTION get_summary_diagnosis
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_diag    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtém o título
        g_error := 'GET TITLE';
        pk_alertlog.log_debug(g_error);
        SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T047')
          INTO o_title
          FROM dual;
    
        g_error := 'OPEN O_DIAG CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_diag FOR
            SELECT DISTINCT -- ALERT-736: diagnosis synonyms support
                            pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                                       i_id_diagnosis        => d.id_diagnosis,
                                                       i_desc_epis_diagnosis => s.desc_epis_diagnosis,
                                                       i_code                => d.code_icd,
                                                       i_flg_other           => d.flg_other,
                                                       i_flg_std_diag        => ad.flg_icd9,
                                                       i_epis_diag           => s.id_epis_diagnosis) desc_diag,
                            s.id_diagnosis
              FROM epis_diagnosis s, diagnosis d, alert_diagnosis ad
             WHERE s.id_episode = i_episode
               AND s.flg_status NOT IN (g_cancel, g_excluded)
               AND d.id_diagnosis = s.id_diagnosis
               AND s.id_alert_diagnosis = ad.id_alert_diagnosis(+);
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
                                              'GET_SUMMARY_DIAGNOSIS',
                                              o_error);
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter a Cirurgia proposta da página resumo
    *
    * @param i_lang        Id do idioma
    * @param i_episode     ID do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_title       Título a mostrar na página resumo  
    * @param o_interv      Lista de Diagnósticos base do episódio
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/08/30
       ********************************************************************************************/

    FUNCTION get_summary_intervention
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_interv  OUT pk_types.cursor_type,
        o_labels  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_call_summ_interv EXCEPTION;
        l_interv_supplies           pk_types.cursor_type;
        l_interv_clinical_questions pk_types.cursor_type;
    BEGIN
    
        --Obtém o título
        g_error := 'GET TITLE';
        pk_alertlog.log_debug(g_error);
        SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T048')
          INTO o_title
          FROM dual;
    
        g_error := 'OPEN O_INTERV CURSOR';
        pk_alertlog.log_debug(g_error);
    
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_planning.get_summ_interv_api(i_lang                      => i_lang,
                                                  i_prof                      => i_prof,
                                                  i_id_context                => i_episode,
                                                  i_flg_type_context          => pk_sr_planning.g_flg_type_context_epis_e,
                                                  o_interv                    => o_interv,
                                                  o_labels                    => o_labels,
                                                  o_interv_supplies           => l_interv_supplies,
                                                  o_interv_clinical_questions => l_interv_clinical_questions,
                                                  o_error                     => o_error)
        THEN
            RAISE l_call_summ_interv;
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
                                              'GET_SUMMARY_INTERVENTION',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_labels);
            RETURN FALSE;
    END get_summary_intervention;

    /********************************************************************************************
    * Obter informação sobre o acolhimento para a página resumo
    *
    * @param i_lang        Id do idioma
    * @param i_episode     ID do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_title       Título a mostrar na página resumo
    * @param o_receive     Lista de Diagnósticos base do episódio
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/08/30
       ********************************************************************************************/

    FUNCTION get_summary_receive_proc
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_receive OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_admit           VARCHAR2(1);
        l_desc            VARCHAR2(4000) := NULL;
        l_first           BOOLEAN := TRUE;
        l_label           sys_message.desc_message%TYPE;
        l_aux             VARCHAR2(200);
        l_aux_cur         pk_types.cursor_type;
        l_id_epis_doc     epis_documentation.id_epis_documentation%TYPE;
        l_id_doc_template epis_documentation.id_doc_template%TYPE;
        l_transaction_id  VARCHAR2(4000);
    
        -- Cursor para obter a última avaliação feita no acolhimento
        CURSOR c_epis_doc IS
            SELECT id_epis_documentation, id_doc_template
              FROM epis_documentation
             WHERE id_doc_area = g_receive_doc_area
               AND id_episode = i_episode
               AND flg_status = g_flg_status_a
             ORDER BY dt_creation_tstz DESC;
    
        CURSOR c_items_not_verified
        (
            l_id_epis_doc     epis_documentation.id_epis_documentation%TYPE,
            l_id_doc_template epis_documentation.id_doc_template%TYPE
        ) IS
            SELECT pk_translation.get_translation(i_lang, dc.code_doc_component) desc_item
              FROM (SELECT DISTINCT (de.id_documentation) id_documentation
                      FROM doc_element de
                     INNER JOIN doc_element_crit DEC
                        ON dec.id_doc_element = de.id_doc_element
                       AND dec.flg_mandatory = pk_alert_constant.g_yes
                     INNER JOIN documentation d
                        ON d.id_documentation = de.id_documentation
                     INNER JOIN doc_template_area_doc dtad
                        ON d.id_documentation = dtad.id_documentation
                     WHERE dtad.id_doc_area = g_receive_doc_area
                       AND dtad.id_doc_template = l_id_doc_template
                       AND d.flg_available = g_available
                    MINUS
                    SELECT edd.id_documentation id_documentation
                      FROM epis_documentation_det edd
                     WHERE (l_id_epis_doc IS NOT NULL AND id_epis_documentation = l_id_epis_doc)) doc -- Identificador da última avaliação na EPIS_DOCUMENTATION
             INNER JOIN documentation d
                ON d.id_documentation = doc.id_documentation
               AND d.flg_available = g_available
             INNER JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = l_id_doc_template
               AND dtad.id_doc_area = g_receive_doc_area
               AND dtad.id_documentation = d.id_documentation
             ORDER BY dtad.rank;
    
        CURSOR c_no_admission_items(l_id_epis_doc epis_documentation.id_epis_documentation%TYPE) IS
            SELECT DISTINCT d.id_documentation,
                            dtad.rank,
                            nvl(pk_translation.get_translation(i_lang, dec.code_element_view),
                                pk_touch_option.get_epis_doc_component_desc(i_lang,
                                                                            i_prof,
                                                                            epd.id_epis_documentation,
                                                                            d.id_doc_component,
                                                                            'N')) desc_item,
                            epd.id_doc_element_crit
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det epd
                ON ed.id_epis_documentation = epd.id_epis_documentation
             INNER JOIN documentation d
                ON epd.id_documentation = d.id_documentation
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             INNER JOIN doc_element de
                ON de.id_documentation = d.id_documentation
             INNER JOIN doc_component dc
                ON d.id_doc_component = dc.id_doc_component
             INNER JOIN doc_element_crit DEC
                ON dec.id_doc_element_crit = epd.id_doc_element_crit
             INNER JOIN (SELECT id_doc_element, id_doc_element_crit, code_element_view
                           FROM doc_element_crit
                          WHERE flg_mandatory = 'Y') mand
                ON de.id_doc_element = mand.id_doc_element
             INNER JOIN doc_template_area_doc dtad
                ON dtad.id_doc_template = ed.id_doc_template
               AND dtad.id_doc_area = ed.id_doc_area
               AND dtad.id_documentation = d.id_documentation
             WHERE epd.id_epis_documentation = l_id_epis_doc
               AND epd.id_doc_element_crit != mand.id_doc_element_crit
               AND nvl(dec.flg_mandatory, 'N') = 'N'
               AND epd.dt_creation_tstz = (SELECT MAX(dt_creation_tstz)
                                             FROM epis_documentation_det
                                            WHERE id_epis_documentation = l_id_epis_doc
                                              AND id_documentation = d.id_documentation)
             ORDER BY dtad.rank;
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        --Obtém o título
        g_error := 'GET TITLE';
        pk_alertlog.log_debug(g_error);
        SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T049')
          INTO o_title
          FROM dual;
    
        --Obtem o valor do item "Admitido para Cirurgia"
        g_error := 'GET RECEIVE_STATUS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_procedures.get_receive_status(i_lang,
                                                   i_episode,
                                                   l_transaction_id,
                                                   l_admit,
                                                   l_aux,
                                                   l_aux,
                                                   l_aux_cur,
                                                   o_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUMMARY_RECEIVE_PROC',
                                              o_error);
            RETURN FALSE;
        
        END IF;
    
        --Obtem a label que indica se o paciente foi ou não admitido para cirurgia
        g_error := 'GET ADMISSON LABEL';
        pk_alertlog.log_debug(g_error);
        IF l_admit = 'Y'
        THEN
            SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T237')
              INTO l_desc
              FROM dual;
        ELSE
            SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T238')
              INTO l_desc
              FROM dual;
        END IF;
    
        g_error := 'OPEN C_EPIS_DOC';
        pk_alertlog.log_debug(g_error);
        OPEN c_epis_doc;
        FETCH c_epis_doc
            INTO l_id_epis_doc, l_id_doc_template;
        g_found := c_epis_doc%FOUND;
        CLOSE c_epis_doc;
    
        -- Apenas mostra itens por verificar e itens que impedem admissão se já existir
        -- pelo menos uma avaliação de Acolhimento neste episódio.
        IF g_found
        THEN
            g_error := 'OPEN C_ITEMS_NOT_VERIFIED';
            pk_alertlog.log_debug(g_error);
            FOR i IN c_items_not_verified(l_id_epis_doc, l_id_doc_template)
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                    l_desc  := l_desc || chr(13);
                    SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T239')
                      INTO l_label
                      FROM dual;
                    IF l_label IS NOT NULL
                    THEN
                        SELECT l_desc || chr(13) || l_label
                          INTO l_desc
                          FROM dual;
                    END IF;
                END IF;
                l_desc := l_desc || chr(13) || i.desc_item;
            END LOOP;
        
            g_error := 'OPEN C_NO_ADMISSION_ITEMS';
            pk_alertlog.log_debug(g_error);
            l_first := TRUE;
            FOR i IN c_no_admission_items(l_id_epis_doc)
            LOOP
                IF l_first
                THEN
                    l_first := FALSE;
                    l_desc  := l_desc || chr(13);
                    SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T355')
                      INTO l_label
                      FROM dual;
                    IF l_label IS NOT NULL
                    THEN
                        SELECT l_desc || chr(13) || l_label
                          INTO l_desc
                          FROM dual;
                    END IF;
                END IF;
                l_desc := l_desc || chr(13) || i.desc_item;
            END LOOP;
        END IF;
    
        --Abre o cursor
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_receive FOR
            SELECT l_desc b1
              FROM dual;
    
        IF l_transaction_id IS NOT NULL
        THEN
            g_error := 'call pk_schedule_api_upstream.do_commit for id_transaction: ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
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
                                              'GET_SUMMARY_RECEIVE_PROC',
                                              o_error);
            pk_types.open_my_cursor(o_receive);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter informação sobre antecedentes cirúrgicos do doente para a página resumo
    *
    * @param i_lang        Id do idioma
    * @param i_episode     ID do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_title       Título a mostrar na página resumo  
    * @param o_cursor      Lista de Diagnósticos base do episódio
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/08/30
       ********************************************************************************************/

    FUNCTION get_summary_prior_surg_epis
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_cursor  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        --Obtém o título
        g_error := 'GET TITLE';
        pk_alertlog.log_debug(g_error);
        SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T222')
          INTO o_title
          FROM dual;
    
        g_error := 'call  pk_sr_clinical_info.get_last_element_values for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_clinical_info.get_last_element_values(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => i_episode,
                                                           i_flg_val_group  => g_surgical_history,
                                                           o_element_values => o_cursor,
                                                           o_error          => o_error)
        THEN
            RAISE l_exception;
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
                                              'GET_SUMMARY_PRIOR_SURG_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter informação sobre outros antecedentes relevantes do doente para a página resumo
    *
    * @param i_lang        Id do idioma
    * @param i_episode     ID do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_title       Título a mostrar na página resumo  
    * @param o_cursor      Lista de Diagnósticos base do episódio
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/08/30
       ********************************************************************************************/

    FUNCTION get_summary_prior_prob_epis
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_cursor  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        --Obtém o título
        g_error := 'GET TITLE';
        pk_alertlog.log_debug(g_error);
        SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T223')
          INTO o_title
          FROM dual;
    
        g_error := 'call  pk_sr_clinical_info.get_last_element_values for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_clinical_info.get_last_element_values(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => i_episode,
                                                           i_flg_val_group  => g_past_history,
                                                           o_element_values => o_cursor,
                                                           o_error          => o_error)
        THEN
            RAISE l_exception;
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
                                              'GET_SUMMARY_PRIOR_PROB_EPIS',
                                              o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter informação sobre medicação pessoal do doente para a página resumo
    *
    * @param i_lang        Id do idioma
    * @param i_episode     ID do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_title       Título a mostrar na página resumo 
    * @param o_cursor      Lista de medicação pessoal
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/08/30
       ********************************************************************************************/

    FUNCTION get_summary_medication
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_title   OUT VARCHAR2,
        o_cursor  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        --Obtém o título
        g_error := 'GET TITLE';
        pk_alertlog.log_debug(g_error);
        SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T224')
          INTO o_title
          FROM dual;
    
        g_error := 'call  pk_sr_clinical_info.get_last_element_values for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_clinical_info.get_last_element_values(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_episode        => i_episode,
                                                           i_flg_val_group  => g_home_medication,
                                                           o_element_values => o_cursor,
                                                           o_error          => o_error)
        THEN
            RAISE l_exception;
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
                                              'GET_SUMMARY_MEDICATION',
                                              o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Get surgical procedures for a specific episode 
    *
    * @param i_lang        Id language
    * @param i_prof        Id professisonal
    * @param i_id_episode  ID episode
    * @param i_flg_show_code Show surgical procedure code Y/N
    *
    * @param o_surg_proc   surgical procedures cursor
    
    * @return              True/False
    *
    * @since               2010/11/02
    ********************************************************************************************/

    FUNCTION get_surgical_procedures
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_flg_show_code IN VARCHAR2 DEFAULT 'N',
        o_surg_proc     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'open o_surg_proc cursor';
        pk_alertlog.log_debug(g_error);
        OPEN o_surg_proc FOR
            SELECT desc_interv, id_sr_epis_interv
              FROM (SELECT pk_date_utils.date_send_tsz(i_lang, ei.dt_req_tstz, i_prof) dt_req,
                           CASE
                                WHEN ei.flg_code_type = g_flg_code_type_c THEN
                                 pk_translation.get_translation(i_lang,
                                                                'INTERVENTION.CODE_INTERVENTION.' || ei.id_sr_intervention) ||
                                 decode(i_flg_show_code,
                                        pk_alert_constant.g_no,
                                        '',
                                        decode(ic.standard_code, NULL, '', ' / ' || ic.standard_code)) ||
                                 decode(ei.laterality,
                                        NULL,
                                        '',
                                        ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', ei.laterality, i_lang) || ')')
                                ELSE
                                 pk_message.get_message(i_lang, 'SR_UNCODED_LABEL_M001') || ' - ' || ei.name_interv
                            END desc_interv,
                           CASE
                                WHEN ei.flg_code_type = g_flg_code_type_c THEN
                                 1
                                ELSE
                                 0
                            END flg,
                           ei.id_sr_epis_interv,
                           ei.flg_type
                      FROM sr_epis_interv ei,
                           (SELECT ic.id_intervention, ic.id_codification, ic.standard_code
                              FROM interv_codification ic, codification_instit_soft cis
                             WHERE ic.flg_available = pk_alert_constant.g_yes
                               AND ic.id_codification = cis.id_codification
                               AND cis.id_institution = i_prof.institution
                               AND cis.id_software = i_prof.software
                               AND cis.flg_available = pk_alert_constant.g_yes) ic
                     WHERE ei.id_episode_context = i_id_episode
                       AND ei.flg_status != pk_sr_clinical_info.g_flg_status_c
                       AND ei.id_sr_intervention = ic.id_intervention(+)
                     ORDER BY flg_type, flg, dt_req);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURGICAL_PROCEDURES',
                                              o_error);
            pk_types.open_my_cursor(o_surg_proc);
            RETURN FALSE;
    END get_surgical_procedures;

    /********************************************************************************************
    * Get surgical procedures description  
    *
    * @param i_lang        Id language
    * @param i_prof        Id professisonal
    * @param i_id_sr_epis_interv SR_EPIS_INTERV ID 
    *
    * @return              Surgical procedure description
    *
    * @since               2010/11/02
    ********************************************************************************************/

    FUNCTION get_surgical_procedure_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE
    ) RETURN VARCHAR2 IS
    
        l_surg_proc_desc VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'GET SURGICAL PROCEDURE DESC: i_id_sr_epis_interv: ' || i_id_sr_epis_interv;
        SELECT CASE
                    WHEN ei.flg_code_type = g_flg_code_type_c THEN
                     pk_translation.get_translation(i_lang, 'INTERVENTION.CODE_INTERVENTION.' || ei.id_sr_intervention) ||
                     decode(ic.standard_code, NULL, '', ' / ' || ic.standard_code) ||
                     decode(ei.laterality,
                            NULL,
                            '',
                            ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', ei.laterality, i_lang) || ')')
                    ELSE
                     pk_message.get_message(i_lang, 'SR_UNCODED_LABEL_M001') || ' - ' || ei.name_interv
                END desc_interv
          INTO l_surg_proc_desc
          FROM sr_epis_interv ei,
               (SELECT ic.id_intervention, ic.id_codification, ic.standard_code
                  FROM interv_codification ic, codification_instit_soft cis
                 WHERE ic.flg_available = pk_alert_constant.g_yes
                   AND ic.id_codification = cis.id_codification
                   AND cis.id_institution = i_prof.institution
                   AND cis.id_software = i_prof.software
                   AND cis.flg_available = pk_alert_constant.g_yes) ic
         WHERE ei.id_sr_epis_interv = i_id_sr_epis_interv
           AND ei.id_sr_intervention = ic.id_intervention(+);
    
        RETURN l_surg_proc_desc;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_surgical_procedure_desc;

    /********************************************************************************************
    * Obter as cirurgias propostas concatenadas numa única string
    *
    * @param i_lang        Id do idioma
    * @param i_episode     ID do episódio
    * @param i_prof        Id do profissional, instituição e software
    *
    * @return              Lista de cirurgias
    *
    * @author              Rui Batista
    * @since               2006/08/30
       ********************************************************************************************/

    FUNCTION get_proposed_surgery
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_flg_show_code IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
        l_function_name VARCHAR2(30) := 'GET_PROPOSED_SURGERY';
        l_surg_proc     pk_types.cursor_type;
        l_error         t_error_out;
    
        l_first             BOOLEAN := TRUE;
        l_interv            VARCHAR2(2000) := NULL;
        l_desc_interv       VARCHAR2(2000) := NULL;
        l_id_sr_epis_interv sr_epis_interv.id_sr_epis_interv%TYPE;
    
    BEGIN
    
        g_error := 'CALL GET_SURGICAL_PROCUDRES';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT get_surgical_procedures(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_id_episode    => i_episode,
                                       i_flg_show_code => i_flg_show_code,
                                       o_surg_proc     => l_surg_proc,
                                       o_error         => l_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        FETCH l_surg_proc
            INTO l_desc_interv, l_id_sr_epis_interv;
        WHILE l_surg_proc%FOUND
        LOOP
            IF l_first
            THEN
                l_interv := l_desc_interv;
                l_first  := FALSE;
            ELSE
                l_interv := l_interv || ', ' || l_desc_interv;
            END IF;
            FETCH l_surg_proc
                INTO l_desc_interv, l_id_sr_epis_interv;
        END LOOP;
        CLOSE l_surg_proc;
    
        RETURN l_interv;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              l_error);
            RETURN NULL;
    END;

    /*
    * Obter os id_content das cirurgias propostas concatenadas numa única string.
    * INline function. Used by the waiting list search function in pk_wtl_pbl_core
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_episode          surgery episode from which to extract surg. procedures
    * 
    * return true /false
    *
    * @author  Telmo
    * @version 2.6.0.3
    * @date    18-06-2010
    */
    FUNCTION get_surgeries_id_content
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_first  BOOLEAN := TRUE;
        l_interv VARCHAR2(4000) := NULL;
    
        CURSOR c_interv IS
            SELECT ei.dt_req_tstz dt_req,
                   CASE
                        WHEN TRIM(id_content) IS NULL THEN
                         decode(TRIM(ei.name_interv), NULL, 'NULL', 'NC')
                        ELSE
                         id_content
                    END id_content,
                   CASE
                        WHEN ei.flg_code_type = g_flg_code_type_c THEN
                         1
                        ELSE
                         0
                    END flg
              FROM sr_epis_interv ei
              LEFT JOIN intervention i
                ON i.id_intervention = ei.id_sr_intervention
              LEFT JOIN interv_codification ic
                ON ic.id_intervention = i.id_intervention
             WHERE ei.id_episode_context = i_id_episode
               AND ei.flg_status != g_cancel
             ORDER BY flg, dt_req;
    BEGIN
    
        g_error := 'fetch c_interv cursor';
        pk_alertlog.log_debug(g_error);
        FOR i IN c_interv
        LOOP
            IF l_first
            THEN
                l_interv := i.id_content;
                l_first  := FALSE;
            ELSE
                l_interv := l_interv || ',' || i.id_content;
            END IF;
        END LOOP;
    
        RETURN l_interv;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_surgeries_id_content;

    /********************************************************************************************
    * Obtem ID do atalho de um ecrã 
    *
    * @param i_lang         Id do idioma
    * @param i_intern_name  Nome interno do atalho
    *
    * @return               ID do atalho
    *
    * @author              Rui Batista
    * @since               2006/02/23
       ********************************************************************************************/

    FUNCTION get_sys_shortcut
    (
        i_lang        IN language.id_language%TYPE,
        i_intern_name IN sys_shortcut.intern_name%TYPE
    ) RETURN NUMBER IS
    
        l_id_sys_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    
    BEGIN
        g_error := 'get id_sys_shortcut for intern_name : ' || i_intern_name;
        pk_alertlog.log_debug(g_error);
        SELECT id_sys_shortcut
          INTO l_id_sys_shortcut
          FROM sys_shortcut
         WHERE intern_name = i_intern_name
           AND id_software = 2
           AND id_institution = 0;
    
        RETURN l_id_sys_shortcut;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN too_many_rows THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /************************************************************************************************
    * Constroi a descrição dos procedimentos cirúrgicos com o formato parametrizado na sysconfig
    * por exemplo: descrição procedimentos cirurgicos (codigo icd) - lateralidade
    *
    * @param i_lang                   Id do idioma
    * @param i_code_int               Código de intervenção
    * @param i_code                   Código do ICD
    * @param i_laterality             lateralidade associado ao procedimento cirúrgico
    * 
    * @return                         Descrição que vai ser mostrada
    * 
    * @author                         Filipe Silva
    * @version                        2.5   
    * @since                          2009/07/13
    **********************************************************************************************/
    FUNCTION get_surg_proc_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_code_int   IN intervention.code_intervention%TYPE,
        i_code       IN interv_codification.standard_code%TYPE,
        i_laterality IN sr_epis_interv.laterality%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc       VARCHAR2(2000);
        l_desc_final VARCHAR2(2000);
    
        CURSOR c_get_mask IS
            SELECT *
              FROM TABLE(pk_utils.str_split_c(pk_sysconfig.get_config('SR_MASK_PROC_SURG', 0, 0), '|'));
    
    BEGIN
        FOR c IN c_get_mask
        LOOP
            --podem ir valores a null caso o separador esteja por exemplo no inicio/fim da máscara
            IF c.column_value IS NOT NULL
            THEN
                IF c.column_value LIKE '%@Desc%'
                   AND i_code_int IS NOT NULL
                THEN
                    l_desc := REPLACE(c.column_value, '@Desc', pk_translation.get_translation(i_lang, i_code_int));
                END IF;
                IF c.column_value LIKE '%@Desc%'
                   AND i_code_int IS NULL
                THEN
                    l_desc := '';
                END IF;
            
                IF c.column_value LIKE '%@ICD%'
                   AND i_code IS NOT NULL
                THEN
                    l_desc := REPLACE(c.column_value, '@ICD', i_code);
                END IF;
                IF c.column_value LIKE '%@ICD%'
                   AND i_code IS NULL
                THEN
                    l_desc := '';
                END IF;
            
                IF c.column_value LIKE '%@Lat%'
                   AND i_laterality IS NOT NULL
                THEN
                    l_desc := REPLACE(c.column_value,
                                      '@Lat',
                                      pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', i_laterality, i_lang));
                END IF;
                IF c.column_value LIKE '%@Lat%'
                   AND i_laterality IS NULL
                THEN
                    l_desc := '';
                END IF;
            END IF;
        
            l_desc_final := l_desc_final || l_desc;
            l_desc       := '';
        END LOOP;
    
        RETURN l_desc_final;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_surg_proc_desc;

    /********************************************************************************************
    * Returns the value of specific elements from last documentation for an area, episode and template
    * The element's internal name is the internal name of documentation table
    *
    * @param i_lang                Language ID                                                                                              
    * @param i_prof                Professional, software and institution ids                                                                                                                                          
    * @param i_episode             Episode ID 
    * @param i_flg_val_group       String to filter de group of internal names
    * @param o_element_values      Element values
    * @param o_error               Error info
    *                        
    * @return                      true or false on success or error
    *
    * @autor                       Filipe Silva
    * @version                     2.5.7.0.8
    * @since                       2010/03/23
    **********************************************************************************************/
    FUNCTION get_last_element_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_val_group  IN sr_surgery_validation.flg_group%TYPE,
        o_element_values OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_last_epis_doc      epis_documentation.id_epis_documentation%TYPE;
        l_last_date_epis_doc epis_documentation.dt_creation_tstz%TYPE;
        l_aux_epis_doc       table_number := table_number();
        l_internal_name      table_varchar := table_varchar();
        l_counter            NUMBER := 1;
    
        CURSOR c_get_recs IS
            SELECT id_doc_area
              FROM (SELECT sv.internal_name,
                           sv.id_doc_area,
                           rank() over(PARTITION BY sv.internal_name ORDER BY sv.id_institution DESC, sv.id_software DESC) origin_rank
                      FROM sr_surgery_validation sv
                     WHERE sv.flg_group = i_flg_val_group
                       AND sv.flg_available = pk_alert_constant.g_available
                       AND sv.id_institution IN (0, i_prof.institution)
                       AND sv.id_software IN (0, i_prof.software)
                       AND instr(sv.flg_type, g_flg_type_get) > 0)
             WHERE origin_rank = 1
             GROUP BY id_doc_area;
    
        CURSOR c_get_internal_names IS
            SELECT CAST(COLLECT(internal_name) AS table_varchar) list_in
              FROM (SELECT sv.internal_name,
                           sv.id_doc_area,
                           rank() over(PARTITION BY sv.internal_name ORDER BY sv.id_institution DESC, sv.id_software DESC) origin_rank
                      FROM sr_surgery_validation sv
                     WHERE sv.flg_group = i_flg_val_group
                       AND sv.flg_available = pk_alert_constant.g_available
                       AND sv.id_institution IN (0, i_prof.institution)
                       AND sv.id_software IN (0, i_prof.software)
                       AND instr(sv.flg_type, g_flg_type_get) > 0)
             WHERE origin_rank = 1;
    
    BEGIN
    
        FOR c IN c_get_recs
        LOOP
        
            g_error := 'OPEN C_LAST_EPIS_DOC';
            pk_alertlog.log_debug(g_error);
        
            IF NOT pk_touch_option.get_last_doc_area(i_lang,
                                                     i_prof,
                                                     i_episode,
                                                     c.id_doc_area,
                                                     NULL,
                                                     l_last_epis_doc,
                                                     l_last_date_epis_doc,
                                                     o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            l_aux_epis_doc.extend;
            l_aux_epis_doc(l_counter) := l_last_epis_doc;
            l_counter := l_counter + 1;
        
        END LOOP;
    
        g_error := 'GET INTERNAL NAMES';
        pk_alertlog.log_debug(g_error);
    
        OPEN c_get_internal_names;
        FETCH c_get_internal_names
            INTO l_internal_name;
        CLOSE c_get_internal_names;
    
        g_error := 'OPEN CURSOR O_ELEMENT_VALUES';
        pk_alertlog.log_debug(g_error);
        OPEN o_element_values FOR
            SELECT nvl(t.desc_element_view, t.answer_given) b1
              FROM (SELECT pk_translation.get_translation(i_lang, aux.code_element_view) desc_element_view,
                           pk_translation.get_translation(i_lang, aux.code_element_close) desc_element,
                           pk_touch_option.get_epis_doc_component_desc(i_lang,
                                                                       i_prof,
                                                                       aux.id_epis_documentation,
                                                                       aux.id_doc_component) answer_given
                      FROM (SELECT decr.code_element_view,
                                   decr.code_element_close,
                                   d.id_doc_component,
                                   edd.id_epis_documentation,
                                   -- last record by id_component 
                                   rank() over(PARTITION BY d.id_doc_component ORDER BY edd.dt_creation_tstz DESC, edd.id_doc_element) rank
                              FROM epis_documentation_det edd
                             INNER JOIN doc_element de
                                ON edd.id_doc_element = de.id_doc_element
                             INNER JOIN documentation d
                                ON edd.id_documentation = d.id_documentation
                             INNER JOIN doc_component dc
                                ON d.id_doc_component = dc.id_doc_component
                              LEFT JOIN doc_element_crit decr
                                ON edd.id_doc_element_crit = decr.id_doc_element_crit
                             WHERE edd.id_epis_documentation IN
                                   (SELECT t1.column_value /*+opt_estimate(table,t1,scale_rows=0.0000000001)*/
                                      FROM TABLE(l_aux_epis_doc) t1)
                               AND d.internal_name IN (SELECT t2.column_value /*+opt_estimate(table,t2,scale_rows=0.0000000001)*/
                                                         FROM TABLE(l_internal_name) t2)) aux
                     WHERE rank = 1) t
             WHERE t.desc_element IS NOT NULL;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAST_ELEMENT_VALUES',
                                              o_error);
            pk_types.open_my_cursor(o_element_values);
            RETURN FALSE;
    END get_last_element_values;

    /**************************************************************************
    * return coded surgical procedure description       
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_sr_intervention     Intervention ID                       
    *
    * @return                         Surgical procedure description                                                           
    *
    * @author                         Filipe Silva                            
    * @version                        2.6.1                                 
    * @since                          2011/04/27                              
    **************************************************************************/
    FUNCTION get_coded_surg_procedure_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_intervention IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2 IS
    
        l_intervention_desc pk_translation.t_desc_translation;
    
    BEGIN
    
        BEGIN
            SELECT pk_translation.get_translation(i_lang, si.code_intervention) ||
                   decode(ci.standard_code, NULL, '', ' / ') || to_char(ci.standard_code)
              INTO l_intervention_desc
              FROM intervention si
             INNER JOIN interv_codification ci
                ON si.id_intervention = ci.id_intervention
             WHERE si.id_intervention = i_id_sr_intervention;
        EXCEPTION
            WHEN no_data_found THEN
                l_intervention_desc := NULL;
        END;
    
        RETURN l_intervention_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_coded_surg_procedure_desc;

    /**************************************************************************
    * return principal surgical procedure for a episode      
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_episode                EPISODE ID                       
    *
    * @return                         Principal Surgical procedure                                                            
    *
    * @author                         Elisabete Bugalho                            
    * @version                        2.6.2                                 
    * @since                          2012/04/05                              
    **************************************************************************/
    FUNCTION get_primary_surg_proc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_description pk_translation.t_desc_translation;
    BEGIN
        SELECT CASE
                    WHEN ei.flg_code_type = g_flg_code_type_c THEN
                     pk_translation.get_translation(i_lang, i.code_intervention) ||
                     decode(ei.laterality,
                            NULL,
                            '',
                            ' (' || pk_sysdomain.get_domain('SR_EPIS_INTERV.LATERALITY', ei.laterality, i_lang) || ')')
                    ELSE
                     pk_message.get_message(i_lang, 'SR_UNCODED_LABEL_M001') || ' - ' || ei.name_interv
                END desc_interv
          INTO l_description
          FROM sr_epis_interv ei, intervention i
         WHERE ei.id_episode_context = i_episode
           AND ei.flg_type = g_flg_type_p
           AND ei.flg_status != g_cancel
           AND i.id_intervention = ei.id_sr_intervention;
        RETURN l_description;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_primary_surg_proc;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_sr_clinical_info;
/
