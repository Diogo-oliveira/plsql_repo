/*-- Last Change Revision: $Rev: 2027088 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_edis_summary AS

    g_package_name VARCHAR2(32);

    FUNCTION get_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_epis_status IN episode.flg_status%TYPE,
        i_fgl_type    IN VARCHAR2,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_icon_name   IN VARCHAR2,
        i_rank        IN sys_domain.rank%TYPE
    ) RETURN VARCHAR2 IS
        l_task  VARCHAR2(120);
        l_error t_error_out;
    BEGIN
        l_task := pk_edis_summary.get_edis_string_task(i_lang,
                                                       i_prof,
                                                       i_episode,
                                                       i_epis_status,
                                                       i_fgl_type,
                                                       i_flg_time,
                                                       i_flg_status,
                                                       i_dt_begin,
                                                       i_dt_req,
                                                       i_icon_name,
                                                       i_rank,
                                                       l_error);
        RETURN l_task;
    
    END;

    FUNCTION get_edis_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_epis_status IN episode.flg_status%TYPE,
        i_fgl_type    IN VARCHAR2,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_req      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_icon_name   IN VARCHAR2,
        i_rank        IN sys_domain.rank%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
        v_out      VARCHAR2(200);
        l_agendado sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_error    := 'GET MESSAGE';
        l_agendado := pk_message.get_message(i_lang, 'ICON_T056'); --'AGENDADO' 
    
        g_error := 'GET V_OUT STRING';
        -- O episódio está activo.
        IF i_flg_time = pk_alert_constant.g_flg_time_e -- neste episódio
        THEN
            -- Requisição / prescrição foi pedida para o próprio episódio 
        
            IF i_fgl_type = g_flg_type_d
            THEN
                -- DRUG'S             
                IF i_flg_status = g_flg_status_f -- IN (g_flg_status_f, g_flg_status_i)
                THEN
                    -- Tem resultados  (terminado/interrompido)
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_icon || '|' || g_no_color || '|' || i_icon_name;
                ELSIF i_flg_status = g_flg_status_i
                THEN
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                ELSIF i_flg_status = g_flg_status_e
                THEN
                    -- Está em execução 
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_color_green;
                
                ELSIF i_flg_status = g_flg_status_r
                THEN
                    -- requisitado 
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_color_red;
                
                ELSIF i_flg_status = g_flg_status_d
                THEN
                    -- pendente 
                    --v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS') || '|' || g_date || '|' || g_color_green;
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_red || '|' || l_agendado;
                    -- 'xxxxxxxxxxxxxx'||'|'||G_TEXT||'|'||G_COLOR_GREEN||'|'||L_AGENDADO;-- Comentado dia 10/10/2006
                END IF; -- I_FLG_STATUS 
                ------------------------------------------------------------------------------
            ELSIF i_fgl_type = g_flg_type_e
            THEN
                -- EXAMES (IMAGENS) 
            
                IF i_flg_status = g_flg_status_f
                THEN
                    -- com resultados
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                
                ELSIF i_flg_status IN (g_flg_status_e, g_flg_status_ex, g_flg_status_t)
                THEN
                    -- em execução, executado, transporte
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                
                ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_x)
                THEN
                    -- requisitado, para o exterior
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_color_red;
                
                ELSIF i_flg_status = g_flg_status_d
                THEN
                    -- pendente 
                    IF i_dt_begin IS NOT NULL
                    THEN
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_color_green;
                    ELSE
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_color_red || '|' || i_icon_name;
                    END IF;
                
                ELSIF i_flg_status = g_flg_status_l
                THEN
                    -- lido 
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || g_icon_name;
                ELSIF i_flg_status = g_flg_status_s
                THEN
                    -- sos 
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                END IF; -- I_FLG_STATUS 
                ------------------------------------------------------------------------------
            ELSIF i_fgl_type = g_flg_type_i
            THEN
                -- PROCEDIMENTOS (INTERVENTION)
            
                IF i_flg_status IN (g_flg_status_f, g_flg_status_i)
                THEN
                    -- Tem resultados  (terminado/interrompido)
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                
                ELSIF i_flg_status = g_flg_status_e
                THEN
                    -- Está em execução (em curso)
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_color_green;
                
                ELSIF i_flg_status = g_flg_status_r
                THEN
                    -- requisitado (em atraso)
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_color_red;
                
                ELSIF i_flg_status = g_flg_status_d
                THEN
                    IF i_dt_begin IS NOT NULL
                    THEN
                        -- pendente 
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_color_green;
                    ELSE
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_red || '|' || l_agendado;
                    END IF;
                
                ELSIF i_flg_status = g_interv_type_sos
                THEN
                    -- sos
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_label || '|' || g_no_color || '|' || i_icon_name;
                END IF; -- I_FLG_STATUS 
                ------------------------------------------------------------------------------
            ELSIF i_fgl_type = g_flg_type_a
            THEN
                -- ANALYSIS
            
                IF i_flg_status IN
                   (g_flg_status_l, g_flg_status_f, g_flg_status_p, g_flg_status_t, g_flg_status_h, g_flg_status_e)
                THEN
                    -- lido, com resultado, parcial, transporte, colhido ou em execução
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                
                ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_cc, g_flg_status_x)
                THEN
                    -- requisitado, colheita em curso, para o exterior
                    IF i_dt_begin IS NULL
                    THEN
                        -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_color_red || '|' || i_icon_name;
                    ELSE
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_no_color;
                    END IF;
                
                ELSIF i_flg_status = g_flg_status_d
                THEN
                    -- pendente 
                    IF i_dt_begin IS NULL
                    THEN
                        -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_color_red || '|' || i_icon_name;
                    ELSE
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_no_color;
                    END IF;
                ELSIF i_flg_status = g_flg_status_s
                THEN
                    -- sos 
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                END IF; -- I_FLG_STATUS 
            END IF;
        
        ELSIF i_flg_time = pk_alert_constant.g_flg_time_n -- proximo episodio
        THEN
            IF i_fgl_type = g_flg_type_e
            THEN
                IF i_episode IS NULL
                THEN
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_color_green || '|' || i_icon_name;
                ELSE
                    IF i_flg_status IN (g_flg_status_f, g_flg_status_ex, g_flg_status_e, g_flg_status_t)
                    THEN
                        -- com resultados, executado, em execução ou transporte
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                    
                    ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_x)
                    THEN
                        -- requisitado, para o exterior
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_color_red;
                    
                    ELSIF i_flg_status = g_flg_status_d
                    THEN
                        -- pendente 
                        IF i_dt_begin IS NOT NULL
                        THEN
                            -- pendente 
                            v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                     g_date || '|' || g_color_green;
                        ELSE
                            v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || pk_alert_constant.g_color_red || '|' ||
                                     i_icon_name;
                        END IF;
                    ELSIF i_flg_status = g_flg_status_l
                    THEN
                        -- lido 
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || g_icon_name;
                    ELSIF i_flg_status = g_flg_status_s
                    THEN
                        -- sos 
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                    END IF; -- I_FLG_STATUS 
                END IF;
            ELSIF i_fgl_type = g_flg_type_a
            THEN
                IF i_episode IS NULL
                THEN
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || pk_alert_constant.g_color_green || '|' ||
                             i_icon_name;
                ELSE
                    IF i_flg_status IN (g_flg_status_f, g_flg_status_p, g_flg_status_e, g_flg_status_t)
                    THEN
                        -- com resultados, parcial ou em execução, transporte
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                    
                    ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_cc, g_flg_status_x)
                    THEN
                        -- requisitado, colheita em curso ou para o exterior
                        IF i_dt_begin IS NULL
                        THEN
                            -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                            v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || pk_alert_constant.g_color_red || '|' ||
                                     i_icon_name;
                        ELSE
                            v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                     g_date || '|' || g_no_color;
                        END IF;
                    
                    ELSIF i_flg_status = g_flg_status_d
                    THEN
                        -- pendente 
                        IF i_dt_begin IS NOT NULL
                        THEN
                            -- pendente 
                            v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                     g_date || '|' || g_color_green;
                        ELSE
                            v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || pk_alert_constant.g_color_red || '|' ||
                                     i_icon_name;
                        END IF;
                    ELSIF i_flg_status = g_flg_status_l
                    THEN
                        -- lido 
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || g_icon_name;
                    ELSIF i_flg_status = g_flg_status_s
                    THEN
                        -- sos 
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                    END IF; -- I_FLG_STATUS 
                END IF;
            ELSE
                IF i_flg_status = g_interv_type_sos
                THEN
                    --sos
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_label || '|' || g_no_color || '|' || i_icon_name;
                ELSE
                    -- Requisição / prescrição foi pedida para o próximo episódio 
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_green || '|' || l_agendado;
                END IF;
            END IF;
        
        ELSIF i_flg_time = pk_alert_constant.g_flg_time_b
        THEN
            -- Requisição / prescrição foi pedida até ao próximo episódio 
            IF i_fgl_type = g_flg_type_e
            THEN
                -- Exames
                IF i_flg_status = g_flg_status_d
                THEN
                    -- pendente 
                    IF i_dt_begin IS NULL
                    THEN
                        -- exames e análises (se FLG_TIME=B então DT_BEGIN=NULL=não aplicável)
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' ||
                                 pk_sysdomain.get_img(i_lang, 'EXAM_REQ_DET.FLG_STATUS', g_flg_status_pa);
                    ELSE
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_no_color;
                    END IF;
                
                ELSIF i_flg_status = g_flg_status_e
                THEN
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_ex, g_flg_status_x)
                THEN
                    -- requisição, em execução, executado ou para o exterior
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_no_color;
                
                ELSIF i_flg_status IN (g_flg_status_l, g_flg_status_f, g_flg_status_pa)
                THEN
                    -- lido, com resultado ou por agendar
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                
                ELSIF i_flg_status = g_flg_status_a
                THEN
                    -- agendado
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || pk_alert_constant.g_color_green || '|' ||
                             i_icon_name;
                
                ELSIF i_flg_status = g_flg_status_s
                THEN
                    --sos
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                END IF;
            ELSIF i_fgl_type = g_flg_type_a
            THEN
                -- Análises
                IF i_flg_status = g_flg_status_d
                THEN
                    -- pendente 
                    IF i_dt_begin IS NULL
                    THEN
                        -- exames e análises (se FLG_TIME=B então DT_BEGIN=NULL=não aplicável)
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' ||
                                 pk_sysdomain.get_img(i_lang, 'ANALYSIS_REQ_DET.FLG_STATUS', g_flg_status_pa);
                    ELSE
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_no_color;
                    END IF;
                
                ELSIF i_flg_status = g_flg_status_e
                THEN
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                
                ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_cc, g_flg_status_x)
                THEN
                    -- requisição, colheita em curso, em execução ou para o exterior
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_no_color;
                
                ELSIF i_flg_status IN (g_flg_status_l, g_flg_status_f, g_flg_status_pa)
                THEN
                    -- lido, com resultado ou por agendar
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                
                ELSIF i_flg_status = g_flg_status_a
                THEN
                    -- agendado
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || pk_alert_constant.g_color_green || '|' ||
                             i_icon_name;
                
                ELSIF i_flg_status = g_flg_status_s
                THEN
                    --sos
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                END IF;
            ELSE
                -- Requisição / prescrição foi pedida até ao próximo episódio 
                IF i_flg_status = g_flg_status_d
                THEN
                    -- pendente 
                    IF i_dt_begin IS NULL
                    THEN
                        -- exames e análises (se FLG_TIME=B então DT_BEGIN=NULL=não aplicável)
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_req, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_text || '|' || g_color_green || '|' || l_agendado;
                    ELSE
                        v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                                 g_date || '|' || g_no_color;
                    END IF;
                
                ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_a, g_flg_status_e)
                THEN
                    -- requisição  
                    v_out := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR') || '|' ||
                             g_date || '|' || g_no_color;
                    --v_out := to_char(i_dt_req, 'YYYYMMDDHH24MISS') || '|' || g_text || '|' || g_color_green || '|' || l_agendado;
                
                ELSIF i_flg_status IN (g_flg_status_l, g_flg_status_f, g_interv_type_sos, g_flg_status_i)
                THEN
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                
                END IF;
            END IF;
        ELSIF i_flg_time = pk_alert_constant.g_flg_time_r
        THEN
            --Exames trazidos pelo paciente
            v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || g_icon_name;
        
        END IF; -- I_FLG_TIME 
    
        IF i_rank IS NOT NULL
        THEN
            v_out := v_out || '|' || i_rank;
        ELSE
            v_out := v_out || '|';
        END IF;
    
        RETURN v_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_SUMMARY',
                                              'GET_EDIS_STRING_TASK',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END;

    FUNCTION get_critical_care_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_crit_data  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_critical_care_da_reg pk_touch_option.t_cur_doc_area_register;
    
        l_tbl_crit_care_da_register  pk_touch_option.t_coll_doc_area_register;
        l_critical_care_da_col_val   t_coll_crit_doc_area_val;
        l_cur_data                   pk_types.cursor_type;
        l_num_records                NUMBER := 0;
        l_critical_care_da_rec_count NUMBER := 0;
        l_critical_care_doc_area CONSTANT NUMBER(4) := 6746;
        l_desc_info VARCHAR2(4000 CHAR);
        l_rec_crit  t_rec_crit_doc_area_val;
        l_msg_notes CONSTANT VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                           i_code_mess => 'DOCUMENTATION_T010');
        l_2_points  CONSTANT VARCHAR2(2 CHAR) := ': ';
        l_limit     CONSTANT NUMBER(4) := 1000;
    BEGIN
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE FUNCTION FOR I_DOC_AREA ' || l_critical_care_doc_area;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_doc_area_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_doc_area           => l_critical_care_doc_area,
                                                  i_current_episode    => i_id_episode,
                                                  i_scope              => i_id_episode,
                                                  i_scope_type         => pk_alert_constant.g_scope_type_episode,
                                                  i_fltr_status        => pk_alert_constant.g_active,
                                                  i_fltr_start_date    => NULL,
                                                  i_fltr_end_date      => NULL,
                                                  o_doc_area_register  => l_critical_care_da_reg,
                                                  o_doc_area_val       => l_cur_data,
                                                  o_template_layouts   => l_cur_data,
                                                  o_doc_area_component => l_cur_data,
                                                  o_record_count       => l_num_records,
                                                  o_error              => o_error)
        THEN
            RAISE g_exception;
        ELSE
            l_critical_care_da_col_val   := t_coll_crit_doc_area_val();
            l_rec_crit                   := t_rec_crit_doc_area_val(NULL, NULL, NULL, NULL);
            l_critical_care_da_rec_count := 0;
            g_error                      := 'FETCH CURSOR FOR DOC_AREA';
            pk_alertlog.log_debug(g_error);
            LOOP
                FETCH l_critical_care_da_reg BULK COLLECT
                    INTO l_tbl_crit_care_da_register LIMIT l_limit;
            
                l_num_records := l_tbl_crit_care_da_register.count;
                FOR i IN 1 .. l_num_records
                LOOP
                    g_error := 'CALL PK_SUMMARY_PAGE.GET_SUMM_LAST_DOC_AREA id_epis_documentation: ' || l_tbl_crit_care_da_register(i).id_epis_documentation;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_summary_page.get_summ_last_doc_area(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_epis_documentation => l_tbl_crit_care_da_register(i).id_epis_documentation,
                                                                  i_doc_area           => l_critical_care_doc_area,
                                                                  o_documentation      => l_cur_data,
                                                                  o_error              => o_error)
                    THEN
                        RAISE g_exception;
                    ELSE
                    
                        LOOP
                            g_error := 'EXTEND l_critical_care_da_col_val';
                            pk_alertlog.log_debug(g_error);
                            l_critical_care_da_col_val.extend();
                            l_critical_care_da_rec_count := l_critical_care_da_rec_count + 1;
                        
                            g_error := 'FETCH l_cur_data';
                            pk_alertlog.log_debug(g_error);
                            FETCH l_cur_data
                                INTO l_rec_crit.id_doc_component,
                                     l_rec_crit.id_epis_documentation,
                                     l_rec_crit.desc_doc_component,
                                     l_rec_crit.desc_element,
                                     l_desc_info;
                            IF NOT l_cur_data%FOUND
                            THEN
                                EXIT;
                            END IF;
                        
                            l_rec_crit.id_epis_documentation := l_tbl_crit_care_da_register(i).id_epis_documentation;
                            IF l_rec_crit.desc_doc_component IS NULL
                            THEN
                                l_rec_crit.desc_doc_component := l_msg_notes || l_2_points;
                            END IF;
                            l_critical_care_da_col_val(l_critical_care_da_rec_count) := l_rec_crit;
                        END LOOP;
                    
                    END IF;
                
                END LOOP;
                EXIT WHEN l_critical_care_da_reg%NOTFOUND;
            END LOOP;
            NULL;
        END IF;
    
        OPEN o_crit_data FOR
            SELECT t.id_epis_documentation, t.id_doc_component, t.desc_doc_component desc_component, t.desc_element
              FROM TABLE(l_critical_care_da_col_val) t
             WHERE t.id_epis_documentation IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_crit_data);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_SUMMARY',
                                              'GET_CRITICAL_CARE_NOTES',
                                              o_error);
            RETURN FALSE;
    END get_critical_care_notes;

    FUNCTION get_summary_list
    (
        i_lang        IN language.id_language%TYPE,
        i_epis        IN episode.id_episode%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        o_last_update OUT VARCHAR2,
        --
        o_title_complaint OUT VARCHAR2,
        o_complaint       OUT VARCHAR2,
        --
        o_title_chief_complaint OUT VARCHAR2,
        o_chief_complaint       OUT VARCHAR2,
        --
        o_title_vsignal OUT VARCHAR2,
        o_vsignal       OUT pk_types.cursor_type,
        --
        o_title_history OUT VARCHAR2,
        o_history       OUT pk_types.cursor_type,
        --
        o_title_review_sys OUT VARCHAR2,
        o_review_system    OUT pk_types.cursor_type,
        --
        o_title_pmhist  OUT VARCHAR2,
        o_past_med_hist OUT pk_types.cursor_type,
        --
        o_title_fam_hist OUT VARCHAR2,
        o_past_fam_hist  OUT pk_types.cursor_type,
        --
        o_title_soc_hist OUT VARCHAR2,
        o_past_soc_hist  OUT pk_types.cursor_type,
        --
        o_title_surg_hist OUT VARCHAR2,
        o_past_surg_hist  OUT pk_types.cursor_type,
        --
        o_title_allergies OUT VARCHAR2,
        o_allergies       OUT pk_types.cursor_type,
        --
        o_title_problems OUT VARCHAR2,
        o_problems       OUT pk_types.cursor_type,
        --
        o_title_habits OUT VARCHAR2,
        o_habits       OUT pk_types.cursor_type,
        --
        o_title_pmedicat OUT VARCHAR2,
        o_p_medication   OUT pk_types.cursor_type,
        --
        o_title_pexam   OUT VARCHAR2,
        o_physical_exam OUT pk_types.cursor_type,
        --
        o_title_passess  OUT VARCHAR2,
        o_nursing_assess OUT pk_types.cursor_type,
        --
        o_title_diff_diagnosis OUT VARCHAR2,
        o_diff_diagnosis       OUT pk_types.cursor_type,
        --
        o_title_interval_notes OUT VARCHAR2,
        o_interval_notes       OUT pk_types.cursor_type,
        --
        o_title_interval_notes_nur OUT VARCHAR2,
        o_interval_notes_nur       OUT pk_types.cursor_type,
        --
        o_title_interval_notes_tech OUT VARCHAR2,
        o_interval_notes_tech       OUT pk_types.cursor_type,
        --
        o_title_records_review OUT VARCHAR2,
        o_records_review       OUT pk_types.cursor_type,
        --
        o_title_tests_review OUT VARCHAR2,
        o_tests_review       OUT pk_types.cursor_type,
        --
        o_title_critical_care OUT VARCHAR2,
        o_critical_care       OUT pk_types.cursor_type,
        --
        o_title_attending_notes OUT VARCHAR2,
        o_attending_notes       OUT pk_types.cursor_type,
        --
        o_title_treatement_manag OUT VARCHAR2,
        o_treatement_manag       OUT pk_types.cursor_type,
        --
        o_title_diagnosis OUT VARCHAR2,
        o_diagnosis       OUT pk_types.cursor_type,
        --
        o_title_dispos OUT VARCHAR2,
        o_disposition  OUT pk_types.cursor_type,
        --
        o_title_trauma OUT pk_types.cursor_type,
        o_trauma       OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(16 CHAR) := 'GET_SUMMARY_LIST';
    
        l_cur_software          software.id_software%TYPE;
        l_id_episode            episode.id_episode%TYPE;
        l_id_visit              visit.id_visit%TYPE;
        l_desc_triage           VARCHAR2(2000);
        l_cur_epis_complaint    pk_complaint.epis_complaint_cur;
        l_row_epis_complaint    pk_complaint.epis_complaint_rec;
        l_msg_edis_summary_m001 sys_message.desc_message%TYPE;
    
        l_area_phys_asses     CONSTANT doc_area.id_doc_area%TYPE := 1045;
        l_summ_page_phys_exam CONSTANT summary_page.id_summary_page%TYPE := 3;
        l_separator           CONSTANT VARCHAR2(1 CHAR) := ':';
        l_count_abcde     NUMBER(6);
        l_decimal_symbol  VARCHAR2(1);
        l_use_epis_origin sys_config.value%TYPE;
        l_time_elapsed    sys_config.value%TYPE;
    
        l_last_epis_touch_option epis_documentation.id_epis_documentation%TYPE;
        l_last_date_touch_option epis_documentation.dt_creation_tstz%TYPE;
    
        l_sys_config_show_diag sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(pk_alert_constant.g_diag_area_sys_config,
                                                                                        i_prof);
    
    BEGIN
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf => 'DECIMAL_SYMBOL', i_prof => i_prof);
    
        g_error := 'GET PROF_CAT';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_msg_edis_summary_m001 := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M001');
        l_use_epis_origin       := pk_sysconfig.get_config(i_code_cf => 'EMERGENCY_EPISODE_SUMMARY', i_prof => i_prof);
        l_time_elapsed          := to_number(pk_sysconfig.get_config(i_code_cf => 'EMERGENCY_EPISODE_SUMMARY_INTERVAL',
                                                                     i_prof    => i_prof));
        --
        l_id_episode   := i_epis;
        l_cur_software := i_prof.software;
        --
        IF i_prof.software = g_soft_inp
           AND l_use_epis_origin = pk_alert_constant.g_yes
        THEN
            g_error := 'GET PREV EPIS';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            SELECT e2.id_episode, e2.id_visit
              INTO l_id_episode, l_id_visit
              FROM episode e1, episode e2
             WHERE e1.id_episode = l_id_episode
               AND e2.id_episode(+) = e1.id_prev_episode
               AND e2.id_epis_type(+) = g_epis_type_edis;
            --
            l_cur_software := g_soft_edis;
        ELSIF i_prof.software = g_soft_inp
              AND l_use_epis_origin = pk_alert_constant.g_no
        THEN
            BEGIN
                SELECT a.id_episode, a.id_visit
                  INTO l_id_episode, l_id_visit
                  FROM (SELECT e2.id_episode, e2.id_visit
                          FROM episode e1, episode e2
                         WHERE e1.id_episode = l_id_episode
                           AND e2.id_patient(+) = e1.id_patient
                           AND e2.id_epis_type(+) = g_epis_type_edis
                           AND e1.dt_begin_tstz <= pk_date_utils.add_to_ltstz(e2.dt_begin_tstz, l_time_elapsed, 'DAY')
                           AND e1.dt_begin_tstz > e2.dt_begin_tstz
                         ORDER BY e2.dt_begin_tstz DESC) a
                 WHERE rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_episode := NULL;
                    l_id_visit   := NULL;
            END;
            --
            l_cur_software := g_soft_edis;
        ELSE
            g_error := 'GET CUR VISIT';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            SELECT id_visit
              INTO l_id_visit
              FROM episode
             WHERE id_episode = l_id_episode;
        END IF;
        --
        IF l_id_episode IS NOT NULL
        THEN
        
            BEGIN
                g_error := 'GET O_LAST_UPDATE';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                SELECT l_msg_edis_summary_m001 || ' ' ||
                       pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || ', ' ||
                       pk_date_utils.date_char_tsz(i_lang, dt_last_tstz, i_prof.institution, l_cur_software)
                  INTO o_last_update
                  FROM (
                        --complaint
                        SELECT ec.adw_last_update_tstz dt_last_tstz, ec.id_professional
                          FROM epis_complaint ec
                         WHERE ec.id_episode = l_id_episode
                           AND ec.flg_status = g_complaint_act
                        UNION ALL
                        SELECT ea.dt_epis_anamnesis_tstz dt_last_tstz, ea.id_professional
                          FROM epis_anamnesis ea
                         WHERE ea.id_episode = l_id_episode
                           AND ea.flg_status = g_complaint_act
                        UNION ALL
                        -- triage (routine patients)
                        SELECT et.dt_begin_tstz dt_last_tstz, et.id_professional
                          FROM epis_triage et
                         WHERE et.id_episode = l_id_episode
                           AND et.id_triage_white_reason IS NOT NULL
                        UNION ALL
                        --vital sign
                        SELECT vs_ea.dt_vital_sign_read dt_last_tstz, vs_ea.id_prof_read id_professional
                          FROM vital_signs_ea vs_ea
                         WHERE vs_ea.id_episode = l_id_episode
                           AND vs_ea.flg_state != g_cancelled
                           AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
                        UNION ALL
                        --hpi,psirfamsoch,critical care
                        SELECT nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz) dt_last_tstz,
                                nvl2(ed.dt_last_update_tstz, ed.id_prof_last_update, ed.id_professional) id_professional
                          FROM epis_documentation ed
                         WHERE ed.id_episode = l_id_episode
                           AND ed.flg_status = g_epis_document_act
                        UNION ALL
                        --rev systems
                        SELECT ers.dt_creation_tstz dt_last_tstz, ers.id_professional
                          FROM epis_review_systems ers
                         WHERE ers.id_episode = l_id_episode
                           AND ers.flg_status != g_cancelled
                        UNION ALL
                        --pmh
                        SELECT phd.dt_pat_history_diagnosis_tstz dt_last_tstz, phd.id_professional
                          FROM pat_history_diagnosis phd
                         WHERE phd.id_patient = i_patient
                           AND phd.flg_status != g_cancelled
                           AND ((l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_all) OR
                               (l_sys_config_show_diag LIKE pk_alert_constant.g_diag_area_config_show_own AND
                               phd.flg_area IN
                               (pk_alert_constant.g_diag_area_past_history, pk_alert_constant.g_diag_area_not_defined)))
                        UNION ALL
                        --psirfamsoch
                        SELECT ps.dt_pat_fam_soc_hist_tstz dt_last_tstz, ps.id_prof_write id_professional
                          FROM pat_fam_soc_hist ps
                         WHERE ps.id_patient = i_patient
                           AND ps.flg_status != g_cancelled
                        UNION ALL
                        --allergies
                        SELECT pa.dt_pat_allergy_tstz dt_last_tstz, pa.id_prof_write id_professional
                          FROM pat_allergy pa
                         WHERE pa.id_patient = i_patient
                           AND pa.flg_status != g_cancelled
                        UNION ALL
                        --phys exam
                        SELECT eo.dt_epis_observation_tstz dt_last_tstz, eo.id_professional id_professional
                          FROM epis_observation eo
                         WHERE eo.id_episode = l_id_episode
                           AND eo.flg_status != g_cancelled
                        UNION ALL
                        --diagnosis despiste
                        SELECT ed.dt_epis_diagnosis_tstz dt_last_tstz, ed.id_professional_diag id_professional
                          FROM epis_diagnosis ed
                         WHERE ed.id_episode = l_id_episode
                           AND ed.flg_status != g_cancelled
                        UNION ALL
                        --diagnosis confirmado
                        SELECT ed.dt_confirmed_tstz dt_last_tstz, ed.id_prof_confirmed id_professional
                          FROM epis_diagnosis ed
                         WHERE ed.id_episode = l_id_episode
                           AND ed.flg_status != g_cancelled
                        UNION ALL
                        --diagnosis rejeitado
                        SELECT ed.dt_rulled_out_tstz dt_last_tstz, ed.id_prof_rulled_out id_professional
                          FROM epis_diagnosis ed
                         WHERE ed.id_episode = l_id_episode
                           AND ed.flg_status != g_cancelled
                        UNION ALL
                        --records review
                        SELECT rrr.dt_creation_tstz dt_last_tstz, rrr.id_professional
                          FROM records_review_read rrr
                         WHERE rrr.id_episode = l_id_episode
                           AND rrr.flg_status != g_cancelled
                        UNION ALL
                        --attending notes
                        SELECT nvl(ean.dt_reviewed_tstz, ean.dt_creation_tstz) dt_last_tstz,
                                nvl2(ean.dt_reviewed_tstz, ean.id_professional, ean.id_prof_reviewed) id_professional
                          FROM epis_attending_notes ean
                         WHERE ean.id_episode = l_id_episode
                        UNION ALL
                        --treatment and management
                        SELECT *
                          FROM TABLE(pk_api_pfh_in.get_summary_list_last_upd(i_lang => i_lang,
                                                                              i_prof => i_prof,
                                                                              i_epis => l_id_episode))
                        UNION ALL
                        SELECT tm.dt_creation_tstz dt_last_tstz, tm.id_professional
                          FROM interv_prescription ip, interv_presc_det ipd, treatment_management tm
                         WHERE ip.id_interv_prescription = ipd.id_interv_prescription
                           AND ipd.id_interv_presc_det = tm.id_treatment
                           AND l_id_episode IN (ip.id_episode, ip.id_prev_episode)
                        UNION ALL
                        --discharge
                        SELECT coalesce(pk_discharge_core.get_dt_admin(i_lang,
                                                                        i_prof,
                                                                        NULL,
                                                                        d.flg_status_adm,
                                                                        d.dt_admin_tstz),
                                         d.dt_med_tstz,
                                         d.dt_pend_active_tstz) dt_last_tstz,
                                nvl2(pk_discharge_core.get_dt_admin(i_lang,
                                                                    i_prof,
                                                                    NULL,
                                                                    d.flg_status_adm,
                                                                    d.dt_admin_tstz),
                                     d.id_prof_admin,
                                     nvl2(d.dt_med_tstz, d.id_prof_med, d.id_prof_pend_active)) id_professional
                          FROM discharge d
                         WHERE d.id_episode = l_id_episode
                           AND d.flg_status != g_cancelled
                        -- José Brito 21/04/2008 Check habits last update
                        --habits
                        UNION ALL
                        SELECT ph.dt_pat_habit_tstz dt_last_tstz, ph.id_prof_writes id_professional
                          FROM pat_habit ph
                         WHERE ph.id_patient = i_patient
                           AND ph.flg_status NOT IN (g_cancelled, g_cancel_u)
                        -- ABCDE Assessment
                        UNION ALL
                        SELECT eam.dt_create dt_last_tstz, eam.id_prof_create id_professional
                          FROM epis_abcde_meth eam
                         WHERE eam.id_episode = l_id_episode
                           AND eam.flg_status = g_flg_status_a
                         ORDER BY 1 DESC NULLS LAST)
                 WHERE rownum < 2;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            -- Check if episode has ABCDE assessments. Call to 'get_abcde_summary' has low performance, 
            -- so call that function only if necessary.
            g_error := 'GET ABCDE ASSESSMENT COUNT';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            SELECT COUNT(*)
              INTO l_count_abcde
              FROM epis_abcde_meth eam
             WHERE eam.id_episode = i_epis;
        
            IF l_count_abcde > 0
            THEN
                -- TRAUMA (ABCDE Assessment)
                g_error := 'GET ABCDE ASSESSMENT';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                IF NOT pk_abcde_methodology.get_abcde_summary(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_episode  => i_epis,
                                                              i_get_titles  => pk_alert_constant.g_yes,
                                                              i_most_recent => pk_alert_constant.g_yes,
                                                              o_titles      => o_title_trauma,
                                                              o_trauma_hist => o_trauma,
                                                              o_error       => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            -- COMPLAINT
            --
            g_error           := 'GET O_TITLE_COMPLAINT';
            o_title_complaint := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M030');
            --
            --
            g_error := 'GET SCOPE OF CHIEF COMPLAINT';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => l_id_episode,
                                                   i_epis_docum     => NULL,
                                                   i_flg_only_scope => pk_alert_constant.g_yes,
                                                   o_epis_complaint => l_cur_epis_complaint,
                                                   o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
            --
            g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            FETCH l_cur_epis_complaint
                INTO l_row_epis_complaint;
            CLOSE l_cur_epis_complaint;
        
            o_complaint := l_row_epis_complaint.desc_complaint;
            --
            g_error                 := 'GET O_TITLE_CHIEF_COMPLAINT';
            o_title_chief_complaint := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M002');
            --
            --
            g_error := 'GET SCOPE OF CHIEF COMPLAINT';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_complaint.get_epis_complaint(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_episode        => l_id_episode,
                                                   i_epis_docum     => NULL,
                                                   i_flg_only_scope => pk_alert_constant.g_no,
                                                   o_epis_complaint => l_cur_epis_complaint,
                                                   o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
            --
            g_error := 'FETCH L_CUR_EPIS_COMPLAINT';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            FETCH l_cur_epis_complaint
                INTO l_row_epis_complaint;
            CLOSE l_cur_epis_complaint;
        
            o_chief_complaint := l_row_epis_complaint.patient_complaint;
            --
            g_error := 'OPEN c_complaint_triage';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            BEGIN
                SELECT desc_triage
                  INTO l_desc_triage
                  FROM (SELECT nvl2(et.id_triage_white_reason,
                                    pk_translation.get_translation(i_lang,
                                                                   'TRIAGE_WHITE_REASON.CODE_TRIAGE_WHITE_REASON.' ||
                                                                   et.id_triage_white_reason) || ': ' || et.notes,
                                    '') desc_triage
                          FROM epis_triage et
                         WHERE et.id_episode = l_id_episode
                         ORDER BY et.dt_end_tstz DESC)
                 WHERE rownum < 2;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            IF l_desc_triage IS NOT NULL
               AND o_complaint IS NOT NULL
            THEN
                o_complaint := o_complaint || chr(13) || l_desc_triage;
            ELSIF l_desc_triage IS NOT NULL
            THEN
                o_complaint := l_desc_triage;
            END IF;
            --
            -- SINAIS VITAIS
            --
            g_error         := 'GET o_title_vsignal';
            o_title_vsignal := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M003');
            --
            g_error := 'OPEN o_vsignal';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_vsignal FOR
                SELECT decode(nvl(vs_ea.value, -999),
                              -999,
                              --pk_translation.get_translation(i_lang, vsd.code_vital_sign_desc),
                              pk_vital_sign.get_vs_alias(i_lang, vs_ea.id_patient, vsd.code_vital_sign_desc),
                              decode(vs_ea.id_unit_measure,
                                     (SELECT DISTINCT vsi.id_unit_measure
                                        FROM vs_soft_inst vsi
                                       WHERE vsi.id_institution = i_prof.institution
                                         AND vsi.id_software = l_cur_software
                                         AND vsi.id_vital_sign = vs_ea.id_vital_sign
                                         AND rownum = 1),
                                     to_char(vs_ea.value),
                                     nvl(to_char(pk_unit_measure.get_unit_mea_conversion(vs_ea.value, --CONVERSAO DAS UNITS
                                                                                         vs_ea.id_unit_measure,
                                                                                         (SELECT DISTINCT vsi.id_unit_measure
                                                                                            FROM vs_soft_inst vsi
                                                                                           WHERE vsi.id_institution =
                                                                                                 i_prof.institution
                                                                                             AND vsi.id_software =
                                                                                                 l_cur_software
                                                                                             AND vsi.id_vital_sign =
                                                                                                 vs_ea.id_vital_sign
                                                                                             AND rownum = 1))),
                                         to_char(vs_ea.value)))) VALUE,
                       pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                 vs_ea.id_unit_measure,
                                                                 vs_ea.id_vs_scales_element) ||
                       nvl2(nvl(vs_ea.id_unit_measure, vs_ea.id_vs_scales_element), ' ', '') ||
                       pk_vital_sign.get_vs_scale_shortdesc(i_lang, vs_ea.id_vs_scales_element) ||
                       nvl2(vs_ea.id_vs_scales_element, ' ', '') ||
                       decode(pk_vital_sign.check_vs_notes(vs_ea.id_vital_sign_read),
                              pk_alert_constant.g_yes,
                              pk_message.get_message(i_lang, i_prof, 'COMMON_M101'),
                              '') desc_unit_measure,
                       pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                       decode(vs.rank, 0, 1, vs.rank) rank
                  FROM vital_signs_ea vs_ea, vital_sign vs, vital_sign_desc vsd
                 WHERE vsd.id_vital_sign_desc(+) = vs_ea.id_vital_sign_desc
                   AND vs.id_vital_sign = vs_ea.id_vital_sign
                   AND vs.flg_available = g_vs_avail
                   AND vs_ea.id_episode = l_id_episode
                   AND vs_ea.flg_state = g_vs_read_active -------------- Sinais Vitais Activos
                   AND vs.id_vital_sign NOT IN (SELECT vr.id_vital_sign_detail
                                                  FROM vital_sign_relation vr
                                                 WHERE vr.relation_domain = g_vs_rel_conc)
                   AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
                UNION ALL -- PRESSÃO ARTERIAL
                SELECT DISTINCT decode(pk_vital_sign.get_bloodpressure_value(vsre.id_vital_sign_parent,
                                                                             vs_ea.id_patient,
                                                                             vs_ea.id_episode,
                                                                             vs_ea.dt_vital_sign_read,
                                                                             l_decimal_symbol),
                                       '/',
                                       NULL,
                                       pk_vital_sign.get_bloodpressure_value(vsre.id_vital_sign_parent,
                                                                             vs_ea.id_patient,
                                                                             vs_ea.id_episode,
                                                                             vs_ea.dt_vital_sign_read,
                                                                             l_decimal_symbol)) VALUE,
                                pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                          vs_ea.id_unit_measure,
                                                                          vs_ea.id_vs_scales_element) ||
                                nvl2(nvl(vs_ea.id_unit_measure, vs_ea.id_vs_scales_element), ' ', '') ||
                                decode(pk_vital_sign.check_vs_notes(vs_ea.id_vital_sign_read),
                                       pk_alert_constant.g_yes,
                                       pk_message.get_message(i_lang, i_prof, 'COMMON_M101'),
                                       '') desc_unit_measure,
                                pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                                decode(vs.rank, 0, 1, vs.rank) rank
                  FROM vital_signs_ea vs_ea, vital_sign vs, vital_sign_relation vsre
                 WHERE vs_ea.id_episode = l_id_episode
                   AND vsre.id_vital_sign_parent = vs.id_vital_sign
                   AND vs_ea.flg_state = g_vs_read_active
                   AND vsre.id_vital_sign_detail = vs_ea.id_vital_sign
                   AND vsre.relation_domain = g_vs_rel_conc
                   AND pk_delivery.check_vs_read_from_fetus(vs_ea.id_vital_sign_read) = 0
                -- José Brito 13/07/2009 ALERT-34222  Show Glasgow total in summary pages
                UNION ALL
                SELECT (SELECT to_char(SUM(a.value)) || ' ' || a.desc_notes
                          FROM (SELECT vsd.value,
                                       decode(pk_vital_sign.check_vs_notes(vea.id_vital_sign_read),
                                              pk_alert_constant.g_yes,
                                              pk_message.get_message(i_lang, i_prof, 'COMMON_M101'),
                                              '') desc_notes,
                                       vr.id_vital_sign_parent
                                  FROM vital_signs_ea vea, vital_sign_desc vsd, vital_sign_relation vr
                                 WHERE vea.id_vital_sign_desc = vsd.id_vital_sign_desc
                                   AND vea.id_vital_sign = vr.id_vital_sign_detail
                                   AND vea.flg_state = g_vs_read_active
                                   AND vea.relation_domain = g_vs_rel_sum
                                   AND vea.id_episode = l_id_episode
                                   AND pk_delivery.check_vs_read_from_fetus(vea.id_vital_sign_read) = 0) a
                         WHERE a.id_vital_sign_parent = vs.id_vital_sign
                         GROUP BY desc_notes) VALUE,
                       NULL desc_unit_measure,
                       pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                       decode(vs.rank, 0, 1, vs.rank) rank
                  FROM vital_sign vs
                 WHERE vs.id_vital_sign IN (SELECT vr1.id_vital_sign_parent
                                              FROM vital_sign_relation vr1
                                             WHERE vr1.id_vital_sign_parent = vs.id_vital_sign
                                               AND vr1.relation_domain = g_vs_rel_sum)
                   AND EXISTS (SELECT 1
                          FROM vital_signs_ea vea1, vital_sign_relation vr1
                         WHERE vea1.id_vital_sign = vr1.id_vital_sign_detail
                           AND vr1.relation_domain = g_vs_rel_sum
                           AND vea1.id_episode = l_id_episode
                           AND vea1.flg_state = g_vs_read_active
                           AND pk_delivery.check_vs_read_from_fetus(vea1.id_vital_sign_read) = 0)
                 ORDER BY rank ASC;
            --
            -- HISTORY OF PRESENT ILLNESS
            --
            g_error         := 'GET O_TITLE_HISTORY';
            o_title_history := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M004');
            --
            g_error := 'CALL PK_CLINICAL_INFO.GET_SUMM_LAST_ANAMNESIS - ' || g_anam_flg_type_a;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_clinical_info.get_summ_last_anamnesis(i_lang      => i_lang,
                                                            i_episode   => l_id_episode,
                                                            i_prof      => i_prof,
                                                            i_flg_type  => g_anam_flg_type_a,
                                                            o_anamnesis => o_history,
                                                            o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
            --
            -- REVIEW OF SYSTEMS
            --
            g_error            := 'GET O_TITLE_REVIEW_SYS';
            o_title_review_sys := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M005');
            --
            g_error := 'CALL PK_CLINICAL_INFO.GET_SUMM_LAST_REVIEW_SYSTEM';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_clinical_info.get_summ_last_review_system(i_lang       => i_lang,
                                                                i_episode    => l_id_episode,
                                                                i_prof       => i_prof,
                                                                o_rev_system => o_review_system,
                                                                o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
            --
            -- PAST MEDICAL HISTORY
            --
            g_error        := 'GET O_TITLE_PMHIST';
            o_title_pmhist := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M006');
            --
            g_error := 'OPEN O_PAST_MED_HIST';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_past_history_api.get_ph_summary_list(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_patient      => i_patient,
                                                           i_episode      => l_id_episode,
                                                           i_doc_area     => pk_past_history.g_doc_area_past_med,
                                                           o_past_history => o_past_med_hist,
                                                           o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
            --
        
            --
            -- PAST FAMILY AND SOCIAL HISTORY
            --
            --Family
            g_error := 'call PK_CLINICAL_INFO.GET_SUMM_LAST_SOC_FAM_SR_HIST';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            o_title_fam_hist := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M026');
            IF NOT pk_past_history_api.get_ph_summary_list(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_patient      => i_patient,
                                                           i_episode      => l_id_episode,
                                                           i_doc_area     => pk_past_history.g_doc_area_past_fam,
                                                           o_past_history => o_past_fam_hist,
                                                           o_error        => o_error)
            
            THEN
                RAISE g_exception;
            END IF;
            --Social
            o_title_soc_hist := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M027');
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_past_history_api.get_ph_summary_list(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_patient      => i_patient,
                                                           i_episode      => l_id_episode,
                                                           i_doc_area     => pk_past_history.g_doc_area_past_soc,
                                                           o_past_history => o_past_soc_hist,
                                                           o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
            --Surgical
            o_title_surg_hist := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M008');
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_past_history_api.get_ph_summary_list(i_lang         => i_lang,
                                                           i_prof         => i_prof,
                                                           i_patient      => i_patient,
                                                           i_episode      => l_id_episode,
                                                           i_doc_area     => pk_past_history.g_doc_area_past_surg,
                                                           o_past_history => o_past_surg_hist,
                                                           o_error        => o_error)
            
            THEN
                RAISE g_exception;
            END IF;
        
            --
            -- ALLERGIES
            --
            g_error           := 'GET o_title_allergies';
            o_title_allergies := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M009');
            --
            g_error := 'OPEN o_allergies';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF i_prof.software = g_soft_inp
               OR i_prof.software = g_soft_nutri
            THEN
                -- shows only allergies reported in the emergency episode
                OPEN o_allergies FOR
                    SELECT desc_allergy, dt_pat_allergy
                      FROM (SELECT decode(pa.id_allergy,
                                          NULL,
                                          pa.desc_allergy,
                                          pk_translation.get_translation(i_lang, 'ALLERGY.CODE_ALLERGY.' || pa.id_allergy)) desc_allergy,
                                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_pat_allergy,
                                   2 rank
                              FROM pat_allergy pa
                             WHERE pa.id_patient = i_patient
                               AND pa.id_episode = l_id_episode
                               AND pa.flg_status = g_allergies_stat
                            UNION
                            SELECT (SELECT pk_translation.get_translation(i_lang, au.code_unawareness_type)
                                      FROM allergy_unawareness au
                                     WHERE au.id_allergy_unawareness = pau.id_allergy_unawareness) AS desc_allergy,
                                   
                                   pk_date_utils.date_send_tsz(i_lang, pau.dt_creation, i_prof) dt_pat_allergy,
                                   1 rank
                              FROM pat_allergy_unawareness pau
                             WHERE pau.id_patient = i_patient
                               AND pau.flg_status = g_allergies_stat
                            
                             ORDER BY rank, dt_pat_allergy DESC)
                    UNION
                    SELECT pk_translation.get_translation(i_lang, au.code_unawareness_type) desc_allergy,
                           pk_date_utils.date_send_tsz(i_lang, pau.dt_creation, i_prof) dt_pat_allergy
                      FROM pat_allergy_unawareness pau
                      JOIN allergy_unawareness au
                        ON au.id_allergy_unawareness = pau.id_allergy_unawareness
                     WHERE pau.id_patient = i_patient
                       AND pau.flg_status != pk_allergy.g_unawareness_cancelled;
            ELSE
                -- shows all the patient allergies
                OPEN o_allergies FOR
                    SELECT desc_allergy, dt_pat_allergy
                      FROM (SELECT decode(pa.id_allergy,
                                          NULL,
                                          pa.desc_allergy,
                                          pk_translation.get_translation(i_lang, 'ALLERGY.CODE_ALLERGY.' || pa.id_allergy)) desc_allergy,
                                   pk_date_utils.date_send_tsz(i_lang, pa.dt_pat_allergy_tstz, i_prof) dt_pat_allergy,
                                   2 rank
                              FROM pat_allergy pa
                             WHERE pa.id_patient = i_patient
                               AND pa.flg_status = g_allergies_stat
                            UNION
                            SELECT (SELECT pk_translation.get_translation(i_lang, au.code_unawareness_type)
                                      FROM allergy_unawareness au
                                     WHERE au.id_allergy_unawareness = pau.id_allergy_unawareness) AS desc_allergy,
                                   pk_date_utils.date_send_tsz(i_lang, pau.dt_creation, i_prof) dt_pat_allergy,
                                   1 rank
                              FROM pat_allergy_unawareness pau
                             WHERE pau.id_patient = i_patient
                               AND pau.flg_status = g_allergies_stat
                             ORDER BY rank, dt_pat_allergy DESC)
                    UNION
                    SELECT pk_translation.get_translation(i_lang, au.code_unawareness_type) desc_allergy,
                           pk_date_utils.date_send_tsz(i_lang, pau.dt_creation, i_prof) dt_pat_allergy
                      FROM pat_allergy_unawareness pau
                      JOIN allergy_unawareness au
                        ON au.id_allergy_unawareness = pau.id_allergy_unawareness
                     WHERE pau.id_patient = i_patient
                       AND pau.flg_status != pk_allergy.g_unawareness_cancelled;
            
            END IF;
            --
            -- José Brito 21/04/2008 Get patient problems and habits 
            -- PROBLEMS
            --
            g_error          := 'GET o_title_problems';
            o_title_problems := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M028');
            --
            g_error := 'OPEN o_problems';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF i_prof.software = g_soft_inp
               OR i_prof.software = g_soft_nutri
            THEN
                -- shows problems reported in the emergency episode
                OPEN o_problems FOR
                    SELECT *
                      FROM (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                              i_id_diagnosis       => d.id_diagnosis,
                                                              i_id_task_type       => pk_alert_constant.g_task_problems,
                                                              i_code               => d.code_icd,
                                                              i_flg_other          => d.flg_other,
                                                              i_flg_std_diag       => ad.flg_icd9) desc_problem
                              FROM pat_history_diagnosis phd
                              JOIN diagnosis d
                                ON phd.id_diagnosis = d.id_diagnosis
                              JOIN alert_diagnosis ad
                                ON ad.id_alert_diagnosis = phd.id_alert_diagnosis
                             WHERE phd.id_episode = l_id_episode
                               AND phd.id_patient = i_patient
                               AND phd.flg_status NOT IN (g_cancelled, g_resolved)
                               AND phd.id_pat_history_diagnosis_new IS NULL
                               AND phd.flg_type = g_pat_hist_diag_type_med
                               AND phd.flg_area IN
                                   (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)
                               AND phd.id_pat_history_diagnosis =
                                   pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                             ORDER BY phd.dt_pat_history_diagnosis_tstz DESC)
                    UNION
                    SELECT pk_translation.get_translation(i_lang, pu.code_prob_unaware) desc_problem
                      FROM pat_prob_unaware ppu
                      LEFT JOIN prob_unaware pu
                        ON pu.id_prob_unaware = ppu.id_prob_unaware
                     WHERE ppu.id_patient = i_patient
                       AND ppu.flg_status = pk_problems.g_status_ppu_active;
            ELSE
                -- shows all patient's problems
                OPEN o_problems FOR
                    SELECT *
                      FROM (SELECT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_id_alert_diagnosis => ad.id_alert_diagnosis,
                                                              i_id_diagnosis       => d.id_diagnosis,
                                                              i_id_task_type       => pk_alert_constant.g_task_problems,
                                                              i_code               => d.code_icd,
                                                              i_flg_other          => d.flg_other,
                                                              i_flg_std_diag       => ad.flg_icd9) desc_problem
                              FROM pat_history_diagnosis phd
                              JOIN diagnosis d
                                ON phd.id_diagnosis = d.id_diagnosis
                              JOIN alert_diagnosis ad
                                ON ad.id_alert_diagnosis = phd.id_alert_diagnosis
                             WHERE phd.id_patient = i_patient
                               AND phd.flg_status NOT IN (g_cancelled, g_resolved)
                               AND phd.id_pat_history_diagnosis_new IS NULL
                               AND phd.flg_type = g_pat_hist_diag_type_med
                               AND phd.flg_area IN
                                   (pk_alert_constant.g_diag_area_problems, pk_alert_constant.g_diag_area_not_defined)
                               AND phd.id_pat_history_diagnosis =
                                   pk_problems.get_most_recent_phd_id(phd.id_pat_history_diagnosis)
                             ORDER BY phd.dt_pat_history_diagnosis_tstz DESC)
                    UNION
                    SELECT pk_translation.get_translation(i_lang, pu.code_prob_unaware) desc_problem
                      FROM pat_prob_unaware ppu
                      LEFT JOIN prob_unaware pu
                        ON pu.id_prob_unaware = ppu.id_prob_unaware
                     WHERE ppu.id_patient = i_patient
                       AND ppu.flg_status = pk_problems.g_status_ppu_active;
            END IF;
            --
            -- HABITS
            --
            g_error        := 'GET o_title_habits';
            o_title_habits := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M029');
            --
            IF i_prof.software = g_soft_nutri
            THEN
                g_error := 'OPEN o_habits';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                OPEN o_habits FOR
                    SELECT pk_translation.get_translation(i_lang, h.code_habit) desc_habit
                      FROM pat_habit ph, habit h
                     WHERE ph.id_habit = h.id_habit
                       AND ph.id_episode = l_id_episode
                       AND ph.id_patient = i_patient
                       AND ph.flg_status NOT IN (g_cancelled, g_cancel_u)
                     ORDER BY ph.dt_pat_habit_tstz DESC;
            
            ELSE
            
                g_error := 'OPEN o_habits';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                OPEN o_habits FOR
                    SELECT pk_translation.get_translation(i_lang, h.code_habit) desc_habit
                      FROM pat_habit ph, habit h
                     WHERE ph.id_habit = h.id_habit
                       AND ph.id_patient = i_patient
                       AND ph.flg_status NOT IN (g_cancelled, g_cancel_u)
                     ORDER BY ph.dt_pat_habit_tstz DESC;
            END IF;
            --
            -- PREVIOUS MEDICATIONS
            --
            g_error          := 'GET o_title_pmedicat';
            o_title_pmedicat := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M010');
            --
            g_error := 'OPEN O_P_MEDICATION';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            IF NOT pk_api_pfh_clindoc_in.get_previous_medication(i_lang                => i_lang,
                                                                 i_prof                => i_prof,
                                                                 i_id_episode          => l_id_episode,
                                                                 o_pat_medication_list => o_p_medication,
                                                                 o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --
            -- PHYSICAL EXAM
            --
            g_error := 'GET o_title_pexam';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            --
            o_title_pexam := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M011');
            --
            IF NOT pk_clinical_info.get_summ_last_physical_exam(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_episode       => l_id_episode,
                                                                i_prof_cat_type => g_cat_doctor,
                                                                o_physical_exam => o_physical_exam,
                                                                o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            --
            -- PHYSICAL ASSESSMENT
            --
            BEGIN
                o_title_passess := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M024');
                --            
                g_error := 'CALL pk_touch_option.get_last_doc_area';
                IF NOT pk_touch_option.get_last_doc_area(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_episode            => l_id_episode,
                                                         i_doc_area           => 5592,
                                                         o_last_epis_doc      => l_last_epis_touch_option,
                                                         o_last_date_epis_doc => l_last_date_touch_option,
                                                         o_error              => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                g_error := 'OPEN O_PHYSICAL_EXAM - Touch option';
                IF NOT pk_summary_page.get_summ_last_doc_area(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_epis_documentation => l_last_epis_touch_option,
                                                              i_doc_area           => 5592,
                                                              o_documentation      => o_nursing_assess,
                                                              o_error              => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    pk_types.open_my_cursor(o_nursing_assess);
                    o_title_passess := NULL;
            END;
            --
            -- DIAGNÓSTICOS DIFERENCIAIS
            --  
            g_error                := 'GET o_title_diff_diagnosis';
            o_title_diff_diagnosis := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M012');
            --
            g_error := 'OPEN o_diff_diagnosis';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_diff_diagnosis FOR
                SELECT -- ALERT-736 synonyms diagnosis
                 pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                            i_id_diagnosis        => d.id_diagnosis,
                                            i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                            i_code                => d.code_icd,
                                            i_flg_other           => d.flg_other,
                                            i_flg_std_diag        => ad.flg_icd9,
                                            i_epis_diag           => ed.id_epis_diagnosis) desc_diff_diag,
                 pk_date_utils.date_send_tsz(i_lang, dt_epis_diagnosis_tstz, i_prof) dt_epis_diagnosis
                  FROM epis_diagnosis ed, diagnosis d, alert_diagnosis ad
                 WHERE ed.id_episode = l_id_episode
                   AND ed.id_diagnosis = d.id_diagnosis
                   AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                   AND ed.flg_type = g_diag_type_p
                   AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                 ORDER BY ed.dt_epis_diagnosis_tstz DESC;
            --
            -- INTERVAL NOTES
            --
            g_error                     := 'GET o_title_interval_notes';
            o_title_interval_notes      := pk_message.get_message(i_lang, i_prof, 'PROG_NOTES_T001') || l_separator;
            o_title_interval_notes_nur  := pk_message.get_message(i_lang, i_prof, 'PROG_NOTES_T002') || l_separator;
            o_title_interval_notes_tech := pk_message.get_message(i_lang, i_prof, 'PROG_NOTES_T003') || l_separator;
            -- 
        
            g_error := 'Call pk_prog_notes_out.get_last_note_text';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT pk_prog_notes_out.get_last_note_text(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_software => l_cur_software,
                                                        i_id_episode  => l_id_episode,
                                                        i_id_pn_area  => pk_prog_notes_constants.g_area_pn_2,
                                                        o_note        => o_interval_notes,
                                                        o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'OPEN o_interval_notes (NUR)';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_interval_notes_nur FOR
                SELECT pk_string_utils.clob_to_sqlvarchar2(t.notes) desc_interval_notes,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) name_prof,
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_creation_tstz, i_prof.institution, l_cur_software) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang, t.dt_creation_tstz, i_prof.institution, l_cur_software) hour_target
                  FROM (SELECT ed.id_episode,
                               ed.id_professional,
                               ed.notes,
                               ed.dt_creation_tstz,
                               row_number() over(PARTITION BY ed.id_episode ORDER BY ed.dt_creation_tstz DESC) row_number
                          FROM epis_documentation ed
                         WHERE ed.id_doc_area = pk_summary_page.g_doc_area_nursing_notes -- Nursing notes
                           AND ed.flg_status = pk_alert_constant.g_active) t
                 WHERE t.id_episode = l_id_episode
                   AND t.row_number = 1;
        
            g_error := 'OPEN o_interval_notes (TECH)';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_interval_notes_tech FOR
                SELECT pk_string_utils.clob_to_sqlvarchar2(t.notes) desc_interval_notes,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) name_prof,
                       pk_date_utils.dt_chr_tsz(i_lang, t.dt_creation_tstz, i_prof.institution, l_cur_software) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang, t.dt_creation_tstz, i_prof.institution, l_cur_software) hour_target
                  FROM (SELECT ed.id_episode,
                               ed.id_professional,
                               ed.notes,
                               ed.dt_creation_tstz,
                               row_number() over(PARTITION BY ed.id_episode ORDER BY ed.dt_creation_tstz DESC) row_number
                          FROM epis_documentation ed
                         WHERE ed.id_doc_area = pk_summary_page.g_doc_area_prg_notes_tec -- Technician notes
                           AND ed.flg_status = pk_alert_constant.g_active) t
                 WHERE t.id_episode = l_id_episode
                   AND t.row_number = 1;
            --
            -- RECORD REVIEWS
            --
            g_error                := 'GET o_title_records_review';
            o_title_records_review := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M014');
            --
            g_error := 'OPEN O_RECORDS_REVIEW';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_records_review FOR
                SELECT pk_translation.get_translation(i_lang, r.code_records_review) desc_record,
                       pk_edis_summary.get_all_prof_rec_review(i_lang,
                                                               r.id_records_review,
                                                               profissional(i_prof.id,
                                                                            i_prof.institution,
                                                                            l_cur_software),
                                                               l_id_episode) all_prof_rr
                  FROM (SELECT rr.code_records_review, rr.id_records_review
                          FROM records_review rr, records_review_read rrr
                         WHERE rr.id_records_review = rrr.id_records_review
                           AND rrr.id_professional = i_prof.id
                           AND rr.flg_available = g_available
                           AND rrr.id_episode = l_id_episode
                           AND rrr.flg_status = g_rreview_read_stat
                         ORDER BY rrr.dt_creation_tstz DESC) r;
            --
            -- TESTS REVIEWS
            --
            g_error              := 'GET o_title_tests_review';
            o_title_tests_review := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M015');
            --
            g_error := 'OPEN o_tests_review';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_tests_review FOR
                SELECT pk_exams_api_db.get_alias_translation(i_lang, i_prof, code_exam, NULL) desc_test,
                       desc_tests_review,
                       pk_date_utils.date_send_tsz(i_lang, dt_creation_tstz, i_prof) dt_creation
                  FROM (SELECT DISTINCT test.code_exam,
                                        tr.desc_tests_review,
                                        tr.dt_creation_tstz,
                                        row_number() over(PARTITION BY tr.id_request ORDER BY tr.dt_creation_tstz DESC) rn
                          FROM tests_review tr,
                               (SELECT 'EXAM.CODE_EXAM.' || eea.id_exam code_exam,
                                       eea.id_exam_req_det id_request,
                                       eea.id_episode,
                                       g_tests_type_exam flg_type
                                  FROM exams_ea eea, episode epis_cur
                                 WHERE eea.flg_status_det IN (g_exam_status_final, g_exam_status_read)
                                   AND epis_cur.id_episode = l_id_episode
                                   AND epis_cur.id_visit = eea.id_visit
                                UNION ALL
                                SELECT 'ANALYSIS.CODE_ANALYSIS.' || ltea.id_analysis code_exam,
                                       ltea.id_analysis_req_det id_request,
                                       ltea.id_episode,
                                       g_tests_type_analisys flg_type
                                  FROM lab_tests_ea ltea, episode epis_cur
                                 WHERE ltea.flg_status_det IN (g_analisys_status_final, g_analisys_status_red)
                                   AND epis_cur.id_episode = l_id_episode
                                   AND epis_cur.id_visit = ltea.id_visit
                                UNION ALL
                                SELECT 'ANALYSIS.CODE_ANALYSIS.' || ar.id_analysis code_exam,
                                       ar.id_analysis_result id_request,
                                       epis.id_episode,
                                       g_tests_type_result flg_type
                                  FROM analysis_result ar, episode epis
                                 WHERE epis.id_visit = ar.id_visit
                                   AND epis.id_episode = l_id_episode
                                   AND ar.id_institution = i_prof.institution
                                   AND ar.dt_sample IS NOT NULL) test
                         WHERE tr.id_request = test.id_request
                           AND tr.flg_type = test.flg_type) tr
                 WHERE rn <= 1
                 ORDER BY 3 DESC;
            --
            -- CRITICAL CARE
            --
            g_error               := 'GET o_title_critical_care';
            o_title_critical_care := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M016');
            --
            g_error := 'CALL GET_CRITICAL_CARE_NOTES i_id_episode: ' || l_id_episode;
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF NOT get_critical_care_notes(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_episode => l_id_episode,
                                           o_crit_data  => o_critical_care,
                                           o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
            --
            -- ATTENDING NOTES
            g_error                 := 'GET o_title_attending_notes';
            o_title_attending_notes := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M017');
            --
            g_error := 'OPEN o_attending_notes';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_attending_notes FOR
                SELECT ean.id_epis_attending_notes,
                       pk_message.get_message(i_lang, i_prof, 'ATTENDING_NOTES_M001') desc_prof_reviewed, -- I have reviewed the notes of: 
                       pk_prof_utils.get_name_signature(i_lang, i_prof, pr.id_professional) name_prof_reviewed,
                       decode(ean.flg_agree,
                              'C',
                              decode(ean.notes_reviewed,
                                     NULL,
                                     pk_message.get_message(i_lang, 'ATTENDING_NOTES_M007'), -- I agree with all.
                                     pk_message.get_message(i_lang, 'ATTENDING_NOTES_M009')), -- I agree with all except
                              'D',
                              pk_message.get_message(i_lang, 'ATTENDING_NOTES_M008')) desc_attend_notes,
                       ean.notes_reviewed,
                       decode(ean.notes_additional,
                              NULL,
                              NULL,
                              pk_message.get_message(i_lang, i_prof, 'ATTENDING_NOTES_M004')) desc_notes_addit, --Additionally 
                       pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                       ean.notes_additional,
                       pk_prof_utils.get_spec_signature(i_lang,
                                                        i_prof,
                                                        ean.id_professional,
                                                        ean.dt_creation_tstz,
                                                        l_id_episode) desc_spec,
                       pk_date_utils.dt_chr_tsz(i_lang, ean.dt_reviewed_tstz, i_prof.institution, l_cur_software) date_target,
                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ean.dt_reviewed_tstz,
                                                        i_prof.institution,
                                                        l_cur_software) hour_target,
                       pk_date_utils.date_send_tsz(i_lang, ean.dt_creation_tstz, i_prof) dt_creation
                  FROM epis_attending_notes ean, professional pr, professional p, speciality s
                 WHERE ean.id_episode = l_id_episode
                   AND ean.id_prof_reviewed = pr.id_professional(+)
                   AND ean.id_professional = p.id_professional(+)
                   AND p.id_speciality = s.id_speciality(+)
                 ORDER BY ean.dt_creation_tstz DESC;
            --
            -- TREATMENT MANAGEMENT
            --
            g_error                  := 'GET o_title_treatement_manag';
            o_title_treatement_manag := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M018');
            --
            g_error := 'OPEN o_treatement_manag';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_treatement_manag FOR
                SELECT desc_treat_manag, desc_dosage, desc_treatment_management, dt_creation
                  FROM TABLE(pk_api_pfh_in.get_title_treatement_manag(i_lang => i_lang,
                                                                      i_prof => i_prof,
                                                                      i_epis => i_epis))
                UNION ALL
                SELECT pk_procedures_api_db.get_alias_translation(i_lang, i_prof, i.code_intervention, NULL) || ' ' ||
                       -- INTERVALO
                        '(' ||
                        decode(pea.flg_interv_type,
                               g_interv_type_uni,
                               pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_INTERV_TYPE', pea.flg_interv_type, i_lang),
                               g_interv_type_sos,
                               pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_INTERV_TYPE', pea.flg_interv_type, i_lang),
                               g_interv_type_ete,
                               pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_INTERV_TYPE', pea.flg_interv_type, i_lang) || ', ' ||
                               decode(pea.flg_time,
                                      pk_alert_constant.g_flg_time_b,
                                      to_char(trunc(pea.interval / 86400)),
                                      to_char(to_date(MOD(pea.interval, 86400), 'SSSSS'), 'HH24:MI')) || '/' ||
                               decode(pea.flg_time,
                                      pk_alert_constant.g_flg_time_b,
                                      to_char(trunc(pea.interval / 86400)) ||
                                      decode(trunc(pea.interval / 86400),
                                             1,
                                             pk_message.get_message(i_lang, i_prof, 'DRUG_PRESC_M008'),
                                             pk_message.get_message(i_lang, i_prof, 'DRUG_PRESC_M006')),
                                      to_char(to_date(MOD(pea.interval, 86400), 'SSSSS'), 'HH24:MI') || 'h'),
                               g_interv_type_nor,
                               pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_INTERV_TYPE', pea.flg_interv_type, i_lang) || ', ' ||
                               pea.num_take || ', ' ||
                               decode(pea.flg_time,
                                      pk_alert_constant.g_flg_time_b,
                                      to_char(trunc(pea.interval / 86400)),
                                      to_char(to_date(MOD(pea.interval, 86400), 'SSSSS'), 'HH24:MI')) || '/' ||
                               decode(pea.flg_time,
                                      pk_alert_constant.g_flg_time_b,
                                      to_char(trunc(pea.interval / 86400)) ||
                                      decode(trunc(pea.interval / 86400),
                                             1,
                                             pk_message.get_message(i_lang, i_prof, 'DRUG_PRESC_M008'),
                                             pk_message.get_message(i_lang, i_prof, 'DRUG_PRESC_M006')),
                                      to_char(to_date(MOD(pea.interval, 86400), 'SSSSS'), 'HH24:MI') || 'h')) || ')' desc_treat_manag,
                       NULL desc_dosage,
                       tm.desc_treatment_management,
                       pk_date_utils.date_send_tsz(i_lang, tm.dt_creation_tstz, i_prof) dt_creation
                  FROM intervention i, procedures_ea pea, treatment_management tm
                 WHERE pea.id_episode = l_id_episode
                   AND pea.flg_status_det IN (g_interv_status_final, g_interv_status_curso, g_interv_status_inter)
                   AND i.id_intervention = pea.id_intervention
                   AND tm.id_treatment = pea.id_interv_presc_det
                   AND tm.flg_type = g_treat_type_interv
                   AND tm.dt_creation_tstz = (SELECT MAX(tm1.dt_creation_tstz)
                                                FROM treatment_management tm1
                                               WHERE tm1.id_treatment = pea.id_interv_presc_det
                                                 AND tm1.flg_type = g_treat_type_interv)
                 ORDER BY dt_creation DESC;
            --
            -- DIAGNÓSTICOS FINAIS
            --
            g_error           := 'GET o_title_diagnosis';
            o_title_diagnosis := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M019');
            --
            g_error := 'OPEN o_diagnosis';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_diagnosis FOR
                SELECT -- ALERT-736 synonyms diagnosis
                 pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_alert_diagnosis  => ad.id_alert_diagnosis,
                                            i_id_diagnosis        => d.id_diagnosis,
                                            i_desc_epis_diagnosis => ed.desc_epis_diagnosis,
                                            i_code                => d.code_icd,
                                            i_flg_other           => d.flg_other,
                                            i_flg_std_diag        => ad.flg_icd9,
                                            i_epis_diag           => ed.id_epis_diagnosis) AS desc_diagnosis
                  FROM epis_diagnosis ed, diagnosis d, alert_diagnosis ad
                 WHERE ed.id_diagnosis = d.id_diagnosis(+)
                   AND ed.id_alert_diagnosis = ad.id_alert_diagnosis(+)
                   AND ed.id_episode = l_id_episode
                   AND ed.flg_type IN (g_diag_type_d, g_diag_type_b)
                   AND ed.flg_status IN (g_ed_flg_status_co, g_ed_flg_status_d)
                 ORDER BY nvl(ed.dt_confirmed_tstz, ed.dt_epis_diagnosis_tstz) DESC;
            --
            -- DISPOSITIONS
            --
            g_error        := 'GET o_title_dispos';
            o_title_dispos := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M020');
            --
            g_error := 'OPEN o_disposition';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            OPEN o_disposition FOR
                SELECT pk_translation.get_translation(i_lang, dr.code_discharge_reason) || ': ' ||
                       decode(nvl(drd.id_discharge_dest, 0),
                              0,
                              decode(nvl(drd.id_dep_clin_serv, 0),
                                     0,
                                     decode(nvl(drd.id_institution, 0),
                                            0,
                                            pk_translation.get_translation(i_lang, dpt.code_department),
                                            pk_translation.get_translation(i_lang, i.code_institution)),
                                     pk_translation.get_translation(i_lang, cs.code_clinical_service)),
                              pk_translation.get_translation(i_lang, dd.code_discharge_dest)) desc_discharge_dest
                  FROM discharge        d,
                       disch_reas_dest  drd,
                       discharge_reason dr,
                       discharge_dest   dd,
                       dep_clin_serv    dcs,
                       department       dpt,
                       clinical_service cs,
                       institution      i
                 WHERE d.id_episode = l_id_episode
                   AND d.flg_status IN (g_flg_status_a, g_flg_status_p)
                   AND d.id_disch_reas_dest = drd.id_disch_reas_dest
                   AND drd.id_discharge_reason = dr.id_discharge_reason
                   AND drd.id_department = dpt.id_department(+)
                   AND dd.id_discharge_dest(+) = drd.id_discharge_dest
                   AND dcs.id_dep_clin_serv(+) = drd.id_dep_clin_serv
                   AND cs.id_clinical_service(+) = dcs.id_clinical_service
                   AND i.id_institution(+) = drd.id_institution
                   AND ((d.dt_med_tstz = (SELECT MAX(d1.dt_med_tstz)
                                            FROM discharge d1
                                           WHERE d1.id_episode = l_id_episode) OR d.dt_med_tstz IS NULL) OR
                       (d.dt_admin_tstz =
                       (SELECT MAX(d1.dt_admin_tstz)
                            FROM discharge d1
                           WHERE d1.id_episode = l_id_episode
                             AND pk_discharge_core.check_admin_discharge(i_lang, i_prof, NULL, d.flg_status_adm) =
                                 pk_alert_constant.g_yes) OR d.dt_admin_tstz IS NULL));
        ELSE
            IF i_prof.software = g_soft_inp
            THEN
                o_last_update := pk_message.get_message(i_lang, i_prof, 'EDIS_SUMMARY_M001');
            END IF;
        END IF;
    
        pk_types.open_cursor_if_closed(o_vsignal);
        pk_types.open_cursor_if_closed(o_history);
        pk_types.open_cursor_if_closed(o_review_system);
        pk_types.open_cursor_if_closed(o_past_med_hist);
        pk_types.open_cursor_if_closed(o_past_fam_hist);
        pk_types.open_cursor_if_closed(o_past_soc_hist);
        pk_types.open_cursor_if_closed(o_past_surg_hist);
        pk_types.open_cursor_if_closed(o_allergies);
        pk_types.open_cursor_if_closed(o_problems);
        pk_types.open_cursor_if_closed(o_habits);
        pk_types.open_cursor_if_closed(o_p_medication);
        pk_types.open_cursor_if_closed(o_physical_exam);
        pk_types.open_cursor_if_closed(o_nursing_assess);
        pk_types.open_cursor_if_closed(o_diff_diagnosis);
        pk_types.open_cursor_if_closed(o_interval_notes);
        pk_types.open_cursor_if_closed(o_interval_notes_nur);
        pk_types.open_cursor_if_closed(o_interval_notes_tech);
        pk_types.open_cursor_if_closed(o_records_review);
        pk_types.open_cursor_if_closed(o_tests_review);
        pk_types.open_cursor_if_closed(o_critical_care);
        pk_types.open_cursor_if_closed(o_attending_notes);
        pk_types.open_cursor_if_closed(o_treatement_manag);
        pk_types.open_cursor_if_closed(o_diagnosis);
        pk_types.open_cursor_if_closed(o_disposition);
        pk_types.open_cursor_if_closed(o_title_trauma);
        pk_types.open_cursor_if_closed(o_trauma);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_vsignal);
            pk_types.open_my_cursor(o_history);
            pk_types.open_my_cursor(o_review_system);
            pk_types.open_my_cursor(o_past_med_hist);
            pk_types.open_my_cursor(o_past_fam_hist);
            pk_types.open_my_cursor(o_past_soc_hist);
            pk_types.open_my_cursor(o_past_surg_hist);
            pk_types.open_my_cursor(o_allergies);
            pk_types.open_my_cursor(o_problems);
            pk_types.open_my_cursor(o_habits);
            pk_types.open_my_cursor(o_p_medication);
            pk_types.open_my_cursor(o_physical_exam);
            pk_types.open_my_cursor(o_nursing_assess);
            pk_types.open_my_cursor(o_diff_diagnosis);
            pk_types.open_my_cursor(o_interval_notes);
            pk_types.open_my_cursor(o_interval_notes_nur);
            pk_types.open_my_cursor(o_interval_notes_tech);
            pk_types.open_my_cursor(o_records_review);
            pk_types.open_my_cursor(o_tests_review);
            pk_types.open_my_cursor(o_critical_care);
            pk_types.open_my_cursor(o_attending_notes);
            pk_types.open_my_cursor(o_treatement_manag);
            pk_types.open_my_cursor(o_diagnosis);
            pk_types.open_my_cursor(o_disposition);
            pk_types.open_my_cursor(o_title_trauma);
            pk_types.open_my_cursor(o_trauma);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_SUMMARY',
                                              'GET_SUMMARY_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_summary_grid
    (
        i_lang             IN language.id_language%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_prof             IN profissional,
        o_drug             OUT pk_types.cursor_type,
        o_analy            OUT pk_types.cursor_type,
        o_proc             OUT pk_types.cursor_type,
        o_exam             OUT pk_types.cursor_type,
        o_days_warning     OUT sys_message.desc_message%TYPE,
        o_flg_show_warning OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(16 CHAR) := 'GET_SUMMARY_GRID';
        l_epis_flg_status episode.flg_status%TYPE;
    
        l_screens   table_varchar;
        l_scr_alias table_varchar := table_varchar(g_list_ivfluids,
                                                   g_list_drug,
                                                   g_grid_oth_exam,
                                                   g_grid_image,
                                                   g_grid_analysis,
                                                   g_grid_harvest,
                                                   g_list_proc,
                                                   g_list_nurse_teach,
                                                   g_sr_clin_inf_sum_posit);
    
        CURSOR c_epis_status IS
            SELECT flg_status
              FROM episode
             WHERE id_episode = i_id_episode;
    
        l_cfg_closed_task_filter  sys_config.value%TYPE;
        l_closed_task_filter_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_closed_task_filt_medication INTERVAL DAY TO SECOND;
    
        l_exam_status table_varchar;
    
        l_analysis_status table_varchar;
    
        l_procedures_status      table_varchar;
        l_nursing_status         table_varchar;
        l_filter_status_sr_posit table_varchar;
    
    BEGIN
    
        g_error := 'GET STATUS OF EPISODE';
        OPEN c_epis_status;
        FETCH c_epis_status
            INTO l_epis_flg_status;
        CLOSE c_epis_status;
    
        IF i_prof.software = g_software_oris
        THEN
            l_screens := table_varchar(g_sr_clin_inf_sum_dr_pr, --LIST_IVFLUIDS
                                       g_sr_clin_inf_sum_dr_pr, --LIST_DRUG
                                       g_grid_oth_exam, --GRID_OTH_EXAM
                                       g_grid_image, --GRID_IMAGE
                                       g_grid_analysis, --GRID_ANALYSIS
                                       g_grid_harvest, --GRID_HARVEST
                                       g_sr_clin_inf_sum_int_pr, --LIST_PROC
                                       g_grid_teach, --LIST_NURSE_TEACH
                                       g_sr_clin_inf_sum_posit);
        ELSIF i_prof.software = g_software_outp
              OR i_prof.software = g_software_pp
        THEN
            l_screens := table_varchar(g_ivfluids_list, --LIST_IVFLUIDS
                                       g_grid_drug_admin, --LIST_DRUG
                                       g_grid_oth_exam, --GRID_OTH_EXAM
                                       g_grid_image, --GRID_IMAGE
                                       g_grid_analysis, --GRID_ANALYSIS
                                       g_grid_harvest, --GRID_HARVEST
                                       g_grid_proc, --LIST_PROC
                                       g_grid_teach --LIST_NURSE_TEACH
                                       );
        ELSIF i_prof.software = g_software_care
        THEN
            l_screens := table_varchar(g_ivfluids_list, --LIST_IVFLUIDS
                                       g_grid_drug_admin, --LIST_DRUG
                                       g_grid_oth_exam, --GRID_OTH_EXAM
                                       g_grid_image, --GRID_IMAGE
                                       g_grid_analysis, --GRID_ANALYSIS
                                       g_grid_analysis, --GRID_HARVEST - não existem colheitas
                                       g_grid_proc, --LIST_PROC
                                       g_grid_teach --LIST_NURSE_TEACH
                                       );
        ELSE
            l_screens := table_varchar(g_ivfluids_list, --LIST_IVFLUIDS
                                       g_sr_clin_inf_sum_dr_pr, --LIST_DRUG
                                       g_grid_oth_exam, --GRID_OTH_EXAM
                                       g_grid_image, --GRID_IMAGE
                                       g_grid_analysis, --GRID_ANALYSIS
                                       g_grid_harvest, --GRID_HARVEST
                                       g_grid_proc, --LIST_PROC
                                       g_grid_teach --LIST_NURSE_TEACH
                                       );
        END IF;
    
        g_error := 'CALL PK_SYSCONFIG.GET_CONFIG';
        IF NOT pk_sysconfig.get_config(g_cfg_closed_task_filter, i_prof, l_cfg_closed_task_filter)
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
        
            l_closed_task_filt_medication := numtodsinterval(to_number((l_cfg_closed_task_filter)), 'DAY');
            o_flg_show_warning            := 'Y';
        
            l_exam_status := g_exam_status;
        
            l_analysis_status := g_analysis_status;
        
            l_procedures_status      := g_procedures_status;
            l_nursing_status         := g_nursing_status;
            l_filter_status_sr_posit := pk_sr_clinical_info.g_filter_status_sr_posit;
        
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
            o_flg_show_warning        := 'N';
        
            l_exam_status := NULL;
        
            l_analysis_status := NULL;
        
            l_procedures_status      := NULL;
            l_nursing_status         := NULL;
            l_filter_status_sr_posit := NULL;
        
            o_days_warning := NULL;
        END IF;
    
        g_error := 'CALL PK_ACCESS.GET_SHORTCUTS_ARRAY';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_access.preload_shortcuts(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_screens   => l_screens,
                                           i_scr_alias => l_scr_alias,
                                           o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_MEDICATION_CURRENT.GET_CURRENT_MEDICATION_INT';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_api_pfh_clindoc_in.get_current_medication(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_episode          => i_id_episode,
                                                            i_filter_date         => l_closed_task_filt_medication,
                                                            o_pat_medication_list => o_drug,
                                                            o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_EDIS_SUMMARY.GET_SUMMARY_GRID_EXAM';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_edis_summary.get_summary_grid_exam(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_episode       => i_id_episode,
                                                     i_flg_stat_epis => l_epis_flg_status,
                                                     i_filter_tstz   => l_closed_task_filter_tstz,
                                                     i_filter_status => l_exam_status,
                                                     o_exam          => o_exam,
                                                     o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_EDIS_SUMMARY.GET_SUMMARY_GRID_ANALY';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_edis_summary.get_summary_grid_analy(i_lang          => i_lang,
                                                      i_prof          => i_prof,
                                                      i_episode       => i_id_episode,
                                                      i_flg_stat_epis => l_epis_flg_status,
                                                      i_filter_tstz   => l_closed_task_filter_tstz,
                                                      i_filter_status => l_analysis_status,
                                                      o_analy         => o_analy,
                                                      o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_EDIS_SUMMARY.GET_SUMMARY_GRID_PROC';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
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
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_cursor_if_closed(o_drug);
            pk_types.open_cursor_if_closed(o_exam);
            pk_types.open_cursor_if_closed(o_analy);
            pk_types.open_cursor_if_closed(o_proc);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_SUMMARY',
                                              'GET_SUMMARY_GRID',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_all_prof_rec_review
    (
        i_lang       IN language.id_language%TYPE,
        i_rec_review IN records_review.id_records_review%TYPE,
        i_prof       IN profissional,
        i_epis       IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_nicks table_varchar;
    BEGIN
        g_error := 'OPEN C_REC_REVIEW ';
        SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name
          BULK COLLECT
          INTO l_nicks
          FROM records_review_read rrr, professional p
         WHERE rrr.id_records_review = i_rec_review
           AND rrr.id_professional <> i_prof.id
           AND p.id_professional = rrr.id_professional
           AND rrr.id_episode = i_epis
         ORDER BY rrr.dt_creation_tstz DESC;
    
        RETURN pk_utils.concat_table(l_nicks, '; ');
    END;

    FUNCTION get_pat_hist_fam_soc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        o_pat_hist_fam_soc OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_PAT_HIST_FAM_SOC';
        OPEN o_pat_hist_fam_soc FOR
            SELECT pk_message.get_message(i_lang, 'EDIS_SUMMARY_M021') desc_component, desc_element
              FROM (SELECT pk_utils.concat_table(CAST(MULTISET (SELECT notes
                                                         FROM pat_fam_soc_hist
                                                        WHERE id_patient = i_patient
                                                          AND flg_type = g_pat_hfam_type
                                                          AND flg_status = g_active
                                                        ORDER BY dt_pat_fam_soc_hist_tstz) AS table_varchar),
                                                 ';') desc_element
                      FROM dual)
             WHERE desc_element IS NOT NULL
            UNION ALL
            SELECT pk_message.get_message(i_lang, 'EDIS_SUMMARY_M022') desc_component, desc_element
              FROM (SELECT pk_utils.concat_table(CAST(MULTISET (SELECT notes
                                                         FROM pat_fam_soc_hist
                                                        WHERE id_patient = i_patient
                                                          AND flg_type = g_pat_hsoc_type
                                                          AND flg_status = g_active
                                                        ORDER BY dt_pat_fam_soc_hist_tstz) AS table_varchar),
                                                 ';') desc_element
                      FROM dual)
             WHERE desc_element IS NOT NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_SUMMARY',
                                              'GET_PAT_HIST_FAM_SOC',
                                              o_error);
            pk_types.open_my_cursor(o_pat_hist_fam_soc);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_pat_problem
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
        l_probs table_varchar;
    BEGIN
        g_error := 'GET PAT_PROB ';
        SELECT pk_translation.get_translation(i_lang, ad.code_alert_diagnosis) ||
               decode(phd.desc_pat_history_diagnosis, NULL, '', ' - ' || phd.desc_pat_history_diagnosis) desc_diagnosis
          BULK COLLECT
          INTO l_probs
          FROM pat_history_diagnosis phd,
               alert_diagnosis ad,
               diagnosis d,
               (SELECT MAX(p2.dt_pat_history_diagnosis_tstz) dt_pat_history_diagnosis_tstz, p2.id_alert_diagnosis
                  FROM pat_history_diagnosis p2
                 WHERE p2.id_patient = i_patient
                   AND p2.flg_status != g_cancelled
                 GROUP BY p2.id_alert_diagnosis) filter
         WHERE phd.id_alert_diagnosis = ad.id_alert_diagnosis
           AND phd.id_diagnosis = d.id_diagnosis(+)
           AND phd.id_patient = i_patient
           AND phd.flg_status != g_cancelled
           AND phd.flg_type = g_pat_hist_diag_type_med
           AND phd.id_alert_diagnosis = filter.id_alert_diagnosis
           AND phd.dt_pat_history_diagnosis_tstz = filter.dt_pat_history_diagnosis_tstz
         ORDER BY phd.dt_pat_history_diagnosis_tstz DESC;
    
        RETURN pk_utils.concat_table(l_probs, '; ');
    
    END;

    FUNCTION get_summary_grid_analy
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_stat_epis IN episode.flg_status%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        o_analy         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_inst IS
            SELECT e.id_institution, e.id_visit, e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_inst                     visit.id_institution%TYPE;
        l_id_visit                 visit.id_visit%TYPE;
        l_epis_type                epis_type.id_epis_type%TYPE;
        l_table_summary_grid_analy t_table_summary_grid_analy;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'OPEN c_inst';
        OPEN c_inst;
        FETCH c_inst
            INTO l_inst, l_id_visit, l_epis_type;
        CLOSE c_inst;
    
        l_table_summary_grid_analy := pk_edis_summary.tf_summary_grid_analy(i_lang          => i_lang,
                                                                            i_prof          => i_prof,
                                                                            i_id_visit      => l_id_visit,
                                                                            i_epis_type     => l_epis_type,
                                                                            i_filter_tstz   => i_filter_tstz,
                                                                            i_filter_status => i_filter_status);
    
        OPEN o_analy FOR
            SELECT dt_req, rank_status, description, flg_status AS flg_status_det, dt_server, icon_name1, flg_external
              FROM TABLE(l_table_summary_grid_analy) t
             ORDER BY rank_status, dt_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_analy);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_SUMMARY',
                                              'GET_SUMMARY_GRID_ANALY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_summary_grid_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_stat_epis IN episode.flg_status%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        o_exam          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis IS
            SELECT e.id_visit, e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_id_visit                visit.id_visit%TYPE;
        l_epis_type               epis_type.id_epis_type%TYPE;
        l_table_summary_grid_exam t_table_summary_grid_exam;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'OPEN c_epis';
        OPEN c_epis;
        FETCH c_epis
            INTO l_id_visit, l_epis_type;
        CLOSE c_epis;
    
        l_table_summary_grid_exam := pk_edis_summary.tf_summary_grid_exam(i_lang          => i_lang,
                                                                          i_prof          => i_prof,
                                                                          i_id_visit      => l_id_visit,
                                                                          i_epis_type     => l_epis_type,
                                                                          i_filter_tstz   => i_filter_tstz,
                                                                          i_filter_status => i_filter_status);
        g_error                   := 'OPEN CURSOR O_EXAM';
        OPEN o_exam FOR
            SELECT dt_req AS dt, rank_status AS rank, description, flg_status AS flg_status_det, dt_server, icon_name1
              FROM TABLE(l_table_summary_grid_exam) t
             ORDER BY rank, dt;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_exam);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_SUMMARY',
                                              'GET_SUMMARY_GRID_EXAM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION get_summary_grid_proc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_stat_epis      IN episode.flg_status%TYPE,
        i_filter_tstz        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status_proc IN table_varchar,
        i_filter_status_nur  IN table_varchar,
        i_filter_status_oris IN table_varchar,
        o_proc               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_visit     visit.id_visit%TYPE;
        l_id_epis_type episode.id_epis_type%TYPE;
        l_id_patient   patient.id_patient%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        -- obter id da visita
        SELECT id_visit, id_epis_type, id_patient
          INTO l_id_visit, l_id_epis_type, l_id_patient
          FROM episode
         WHERE id_episode = i_episode;
    
        g_error := 'OPEN CURSOR O_PROC';
        OPEN o_proc FOR
            SELECT pk_sysdomain.get_rank(i_lang, 'INTERV_PRESC_DET.FLG_STATUS', t.flg_status_det) rank,
                   pk_date_utils.date_send_tsz(i_lang, nvl(t.dt_begin_req, t.dt_interv_prescription), i_prof) dt_interv_prescription,
                   pk_procedures_api_db.get_alias_translation(i_lang,
                                                              i_prof,
                                                              'INTERVENTION.CODE_INTERVENTION.' || t.id_intervention,
                                                              NULL) || ' ' || '(' ||
                   nvl(pk_order_recurrence_api_db.get_order_recurr_plan_desc(i_lang, i_prof, t.id_order_recurrence),
                       pk_translation.get_translation(i_lang, 'ORDER_RECURR_OPTION.CODE_ORDER_RECURR_OPTION.0')) || ')' ||
                   decode(l_id_epis_type,
                          nvl(t_ti_log.get_epis_type(i_lang,
                                                     i_prof,
                                                     t.id_epis_type,
                                                     t.flg_status_det,
                                                     t.id_interv_presc_det,
                                                     g_ti_log_interv),
                              t.id_epis_type),
                          '',
                          ' - (' || pk_message.get_message(i_lang,
                                                           profissional(i_prof.id,
                                                                        i_prof.institution,
                                                                        t_ti_log.get_epis_type_soft(i_lang,
                                                                                                    i_prof,
                                                                                                    t.id_epis_type,
                                                                                                    t.flg_status_det,
                                                                                                    t.id_interv_presc_det,
                                                                                                    g_ti_log_interv)),
                                                           'IMAGE_T009') || ')') description,
                   t.flg_status_det,
                   g_sysdate_char dt_server,
                   --In the nutritionist profile the physician can't access the procedures deepnav
                   decode(pk_prof_utils.get_prof_profile_template(i_prof),
                          g_nutritionist_profile,
                          g_default_shortcut,
                          g_shortcut_procedures) ||
                   pk_utils.get_status_string(i_lang, i_prof, t.status_str, t.status_msg, t.status_icon, t.status_flg) icon_name1
              FROM (SELECT pea.flg_status_det,
                           pea.dt_begin_req,
                           pea.dt_interv_prescription,
                           pea.id_intervention,
                           ipd.id_order_recurrence,
                           epi.id_epis_type,
                           pea.id_interv_presc_det,
                           pea.status_str,
                           pea.status_msg,
                           pea.status_icon,
                           pea.status_flg
                      FROM procedures_ea pea,
                           episode epi,
                           (SELECT *
                              FROM interv_presc_plan
                             WHERE flg_status IN (pk_procedures_constant.g_interv_plan_req,
                                                  pk_procedures_constant.g_interv_plan_pending)) ipp,
                           interv_presc_det ipd
                     WHERE epi.id_visit = l_id_visit
                       AND epi.id_episode IN (pea.id_episode, pea.id_episode_origin)
                       AND pea.flg_time NOT IN
                           (pk_procedures_constant.g_flg_time_a, pk_procedures_constant.g_flg_time_h)
                       AND pea.flg_status_det NOT IN (pk_procedures_constant.g_interv_not_ordered,
                                                      pk_procedures_constant.g_interv_expired,
                                                      pk_procedures_constant.g_interv_interrupted,
                                                      pk_procedures_constant.g_interv_cancel,
                                                      pk_procedures_constant.g_interv_draft)
                       AND pea.id_interv_presc_plan = ipp.id_interv_presc_plan(+)
                       AND pea.id_interv_presc_det = ipd.id_interv_presc_det
                       AND ipd.id_drug_presc_det IS NULL
                       AND pea.id_visit = epi.id_visit
                       AND (pea.flg_status_det NOT IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                        t.column_value
                                                         FROM TABLE(i_filter_status_proc) t) OR
                           pea.dt_begin_req > i_filter_tstz)
                    UNION
                    SELECT pea.flg_status_det,
                           pea.dt_begin_req,
                           pea.dt_interv_prescription,
                           pea.id_intervention,
                           ipd.id_order_recurrence,
                           epi.id_epis_type,
                           pea.id_interv_presc_det,
                           pea.status_str,
                           pea.status_msg,
                           pea.status_icon,
                           pea.status_flg
                      FROM procedures_ea pea,
                           episode epi,
                           (SELECT *
                              FROM interv_presc_plan
                             WHERE flg_status IN (pk_procedures_constant.g_interv_plan_req,
                                                  pk_procedures_constant.g_interv_plan_pending)) ipp,
                           interv_presc_det ipd
                     WHERE pea.id_patient = l_id_patient
                       AND pea.flg_time IN (pk_procedures_constant.g_flg_time_a, pk_procedures_constant.g_flg_time_h)
                       AND pea.flg_status_det NOT IN (pk_procedures_constant.g_interv_not_ordered,
                                                      pk_procedures_constant.g_interv_expired,
                                                      pk_procedures_constant.g_interv_interrupted,
                                                      pk_procedures_constant.g_interv_cancel,
                                                      pk_procedures_constant.g_interv_draft)
                       AND pea.id_interv_presc_plan = ipp.id_interv_presc_plan(+)
                       AND pea.id_interv_presc_det = ipd.id_interv_presc_det
                       AND ipd.id_drug_presc_det IS NULL
                       AND pea.id_episode = epi.id_episode
                       AND (pea.flg_status_det NOT IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                        t.column_value
                                                         FROM TABLE(i_filter_status_proc) t) OR
                           pea.dt_begin_req > i_filter_tstz)) t
            UNION ALL
            -- Ensinos de enfermagem
            SELECT pk_sysdomain.get_rank(i_lang, 'NURSE_TEA_REQ.FLG_STATUS', ntr.flg_status) rank,
                   pk_date_utils.date_send_tsz(i_lang, nvl(ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz), i_prof) dt_interv_prescription,
                   pk_message.get_message(i_lang, 'SUMMARY_M009') || chr(13) ||
                   decode(ntt.id_nurse_tea_topic,
                          1, --other
                          nvl(ntr.desc_topic_aux, pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic)),
                          pk_translation.get_translation(i_lang, ntt.code_nurse_tea_topic)) ||
                   decode(l_id_epis_type,
                          nvl(t_ti_log.get_epis_type(i_lang,
                                                     i_prof,
                                                     epi.id_epis_type,
                                                     ntr.flg_status,
                                                     ntr.id_nurse_tea_req,
                                                     g_ti_log_nurse_tea),
                              epi.id_epis_type),
                          '',
                          ' - (' || pk_message.get_message(i_lang,
                                                           profissional(i_prof.id,
                                                                        i_prof.institution,
                                                                        t_ti_log.get_epis_type_soft(i_lang,
                                                                                                    i_prof,
                                                                                                    epi.id_epis_type,
                                                                                                    ntr.flg_status,
                                                                                                    ntr.id_nurse_tea_req,
                                                                                                    g_ti_log_nurse_tea)),
                                                           'IMAGE_T009') || ')') description,
                   ntr.flg_status flg_status,
                   g_sysdate_char dt_server,
                   --In the nutritionist profile the physician can't access the procedures deepnav
                   decode(pk_prof_utils.get_prof_profile_template(i_prof),
                          g_nutritionist_profile,
                          g_default_shortcut,
                          g_shortcut_teach) || pk_utils.get_status_string(i_lang,
                                                                          i_prof,
                                                                          ntr.status_str,
                                                                          ntr.status_msg,
                                                                          ntr.status_icon,
                                                                          ntr.status_flg) icon_name1
              FROM nurse_tea_req ntr, episode epi, nurse_tea_topic ntt
             WHERE ntr.id_episode = epi.id_episode
               AND epi.id_visit = l_id_visit
               AND ntt.id_nurse_tea_topic = ntr.id_nurse_tea_topic
               AND ntr.flg_status NOT IN
                   (pk_patient_education_constant.g_nurse_tea_req_canc,
                    pk_patient_education_constant.g_nurse_tea_req_draft,
                    pk_patient_education_constant.g_nurse_tea_req_expired,
                    pk_patient_education_constant.g_nurse_tea_req_not_ord_reas)
               AND (ntr.flg_status NOT IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                            t.column_value
                                             FROM TABLE(i_filter_status_nur) t) OR
                   ntr.dt_nurse_tea_req_tstz > i_filter_tstz)
            UNION ALL
            SELECT pk_sysdomain.get_rank(i_lang, 'SR_POSIT_DET.FLG_STATUS', r.flg_status) rank,
                   pk_date_utils.date_send_tsz(i_lang, greatest(r.dt_posit_req_tstz, sr.dt_interv_preview_tstz), i_prof) dt_interv_prescription,
                   pk_translation.get_translation(i_lang, p.code_sr_posit) description,
                   r.flg_status,
                   g_sysdate_char dt_server,
                   --Estado da requisição: R - Requisitado, P - Executado, F- Executado e Verificado, C- Cancelado
                   pk_access.get_shortcut(g_sr_clin_inf_sum_posit) ||
                   decode(r.flg_status,
                          g_flg_status_r,
                          pk_utils.get_status_string(i_lang,
                                                     i_prof,
                                                     '|D|' ||
                                                     pk_date_utils.to_char_insttimezone(i_prof,
                                                                                        greatest(r.dt_posit_req_tstz,
                                                                                                 sr.dt_interv_preview_tstz),
                                                                                        pk_alert_constant.g_dt_yyyymmddhh24miss_tzr) ||
                                                     '|||' || pk_alert_constant.g_color_null || '||||&',
                                                     '',
                                                     '',
                                                     ''),
                          pk_utils.get_status_string(i_lang,
                                                     i_prof,
                                                     '|I|||#|||||&',
                                                     '',
                                                     'SR_POSIT_DET.FLG_STATUS',
                                                     r.flg_status)) icon_name1
              FROM sr_posit p
             INNER JOIN sr_posit_req r
                ON r.id_sr_posit = p.id_sr_posit
             INNER JOIN schedule_sr sr
                ON sr.id_episode = r.id_episode_context
             WHERE r.id_episode_context = i_episode --it makes sense to list ORIS's positions by id_episode and not by id_visit 
               AND (r.flg_status NOT IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                          t.column_value
                                           FROM TABLE(i_filter_status_oris) t) OR r.dt_posit_req_tstz > i_filter_tstz)
             ORDER BY rank, dt_interv_prescription;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_proc);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_EDIS_SUMMARY',
                                              'GET_SUMMARY_GRID_PROC',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    FUNCTION tf_summary_grid_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_visit      IN episode.id_visit%TYPE,
        i_epis_type     IN epis_type.id_epis_type%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar
    ) RETURN t_table_summary_grid_exam IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'tf_summary_grid_exam';
        l_tbl t_table_summary_grid_exam;
    
    BEGIN
        --Get list of values for summary grid exams
        g_error := 'FILL SUMMARY_GRID_EXAMS TABLE';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT t_rec_summary_grid_exam(t.dt, t.rank, t.description, t.flg_status_det, t.dt_server, t.icon_name1)
          BULK COLLECT
          INTO l_tbl
          FROM (SELECT DISTINCT pk_date_utils.date_send_tsz(i_lang, nvl(eea.dt_pend_req, eea.dt_begin), i_prof) dt,
                                decode(eea.flg_referral,
                                       g_flg_status_r,
                                       pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral),
                                       g_flg_status_s,
                                       pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral),
                                       g_flg_status_i,
                                       pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_REFERRAL', eea.flg_referral),
                                       pk_sysdomain.get_rank(i_lang, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det)) rank,
                                pk_exams_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'EXAM.CODE_EXAM.' || eea.id_exam,
                                                                      NULL) ||
                                decode(i_epis_type,
                                       nvl(t_ti_log.get_epis_type(i_lang,
                                                                  i_prof,
                                                                  epi.id_epis_type,
                                                                  eea.flg_status_req,
                                                                  eea.id_exam_req,
                                                                  g_exam_type_req),
                                           epi.id_epis_type),
                                       '',
                                       ' - (' || pk_message.get_message(i_lang,
                                                                        profissional(i_prof.id,
                                                                                     i_prof.institution,
                                                                                     t_ti_log.get_epis_type_soft(i_lang,
                                                                                                                 i_prof,
                                                                                                                 epi.id_epis_type,
                                                                                                                 eea.flg_status_req,
                                                                                                                 eea.id_exam_req,
                                                                                                                 g_exam_type_req)),
                                                                        'IMAGE_T009') || ')') description,
                                eea.flg_status_det,
                                g_sysdate_char dt_server,
                                pk_access.get_shortcut(decode(eea.flg_type,
                                                              g_exam_type_img,
                                                              g_grid_image,
                                                              g_grid_oth_exam)) ||
                                pk_utils.get_status_string(i_lang,
                                                           i_prof,
                                                           eea.status_str,
                                                           eea.status_msg,
                                                           eea.status_icon,
                                                           eea.status_flg) icon_name1,
                                NULL icon_name2,
                                NULL icon_name3,
                                nvl(eea.dt_pend_req, eea.dt_begin) dt_reg
                  FROM exams_ea eea, episode epi
                 WHERE epi.id_visit = i_id_visit
                   AND epi.id_episode IN (eea.id_episode, eea.id_prev_episode, eea.id_episode_origin)
                   AND eea.flg_status_det != g_cancel
                   AND eea.flg_status_req != g_cancel
                      --
                   AND (eea.flg_status_det NOT IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                    t.column_value
                                                     FROM TABLE(i_filter_status) t) OR eea.dt_req > i_filter_tstz)) t;
    
        RETURN l_tbl;
    END tf_summary_grid_exam;

    FUNCTION tf_summary_grid_analy
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_visit      IN episode.id_visit%TYPE,
        i_epis_type     IN epis_type.id_epis_type%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar
    ) RETURN t_table_summary_grid_analy IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'tf_summary_grid_analy';
        l_tbl t_table_summary_grid_analy;
    
    BEGIN
        g_error := 'FILL SUMMARY_GRID_ANALY TABLE';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        SELECT t_rec_summary_grid_analy(t.dt_req,
                                        t.rank_status,
                                        t.description,
                                        t.flg_status_det,
                                        t.dt_server,
                                        t.icon_name1,
                                        flg_external)
          BULK COLLECT
          INTO l_tbl
          FROM (SELECT (SELECT pk_date_utils.date_send_tsz(i_lang, nvl(v.dt_target, v.dt_req), i_prof)
                          FROM dual) dt_req,
                       decode(v.flg_referral,
                              g_flg_status_r,
                              (SELECT pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_REFERRAL', v.flg_referral)
                                 FROM dual),
                              g_flg_status_s,
                              (SELECT pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_REFERRAL', v.flg_referral)
                                 FROM dual),
                              g_flg_status_i,
                              (SELECT pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_REFERRAL', v.flg_referral)
                                 FROM dual),
                              decode(v.flg_status_det,
                                     g_flg_status_e,
                                     (SELECT pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', v.flg_status_harvest)
                                        FROM dual),
                                     (SELECT pk_sysdomain.get_rank(i_lang, 'ANALYSIS_REQ_DET.FLG_STATUS', v.flg_status_det)
                                        FROM dual))) rank_status,
                       (SELECT pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                         i_prof,
                                                                         'A',
                                                                         'ANALYSIS.CODE_ANALYSIS.' || v.id_analysis,
                                                                         'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                         v.id_sample_type,
                                                                         NULL)
                          FROM dual) || decode(i_epis_type,
                                               nvl(t_ti_log.get_epis_type(i_lang,
                                                                          i_prof,
                                                                          v.id_epis_type,
                                                                          v.flg_status_det,
                                                                          v.id_analysis_req_det,
                                                                          g_analysis_type_req_det),
                                                   v.id_epis_type),
                                               '',
                                               ' - (' || pk_message.get_message(i_lang,
                                                                                profissional(i_prof.id,
                                                                                             i_prof.institution,
                                                                                             t_ti_log.get_epis_type_soft(i_lang,
                                                                                                                         i_prof,
                                                                                                                         v.id_epis_type,
                                                                                                                         v.flg_status_det,
                                                                                                                         v.id_analysis_req_det,
                                                                                                                         g_analysis_type_req_det)),
                                                                                'IMAGE_T009') || ')') description,
                       v.flg_status_det,
                       g_sysdate_char dt_server,
                       (SELECT pk_access.get_shortcut(decode(v.flg_status_det,
                                                             g_flg_status_x,
                                                             g_grid_analysis,
                                                             decode(v.id_harvest, NULL, g_grid_harvest, g_grid_analysis)))
                          FROM dual) || (SELECT pk_utils.get_status_string(i_lang,
                                                                           i_prof,
                                                                           v.status_str,
                                                                           v.status_msg,
                                                                           v.status_icon,
                                                                           v.status_flg)
                                           FROM dual) icon_name1,
                       CASE
                            WHEN v.flg_status_det = pk_alert_constant.g_analysis_det_ext THEN
                             pk_alert_constant.g_yes
                            ELSE
                             pk_alert_constant.g_no
                        END flg_external,
                       nvl(v.dt_target, v.dt_req) dt_reg
                  FROM (SELECT DISTINCT row_number() over(PARTITION BY lte.id_analysis_req_det, h.id_harvest_group ORDER BY h.dt_harvest_tstz DESC NULLS LAST) rn,
                                        lte.dt_target,
                                        lte.dt_req,
                                        lte.flg_referral,
                                        lte.flg_status_det,
                                        lte.flg_status_harvest,
                                        lte.id_analysis,
                                        lte.id_sample_type,
                                        epis.id_epis_type,
                                        lte.id_analysis_req_det,
                                        ah.id_harvest,
                                        lte.status_str,
                                        lte.status_msg,
                                        lte.status_icon,
                                        lte.status_flg
                          FROM lab_tests_ea lte, analysis_req_det ard, analysis_harvest ah, harvest h, episode epis
                         WHERE epis.id_visit = i_id_visit
                           AND epis.id_episode = lte.id_episode
                           AND lte.flg_status_det != g_cancel
                           AND lte.id_analysis_req_det = ard.id_analysis_req_det
                           AND lte.id_analysis_req_det = ah.id_analysis_req_det
                           AND ah.flg_status != pk_lab_tests_constant.g_inactive
                           AND ah.id_harvest = h.id_harvest
                           AND h.flg_status NOT IN
                               (pk_lab_tests_constant.g_harvest_waiting, pk_lab_tests_constant.g_harvest_cancel)
                              -- 
                           AND (lte.flg_status_det NOT IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                            t.column_value
                                                             FROM TABLE(i_filter_status) t) OR
                               lte.dt_req > i_filter_tstz)
                           AND (SELECT pk_lab_tests_api_db.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                                  FROM dual) = pk_alert_constant.g_yes
                        UNION ALL
                        SELECT DISTINCT row_number() over(PARTITION BY lte.id_analysis_req_det, h.id_harvest_group ORDER BY h.dt_harvest_tstz DESC NULLS LAST) rn,
                                        lte.dt_target,
                                        lte.dt_req,
                                        lte.flg_referral,
                                        lte.flg_status_det,
                                        lte.flg_status_harvest,
                                        lte.id_analysis,
                                        lte.id_sample_type,
                                        epis.id_epis_type,
                                        lte.id_analysis_req_det,
                                        ah.id_harvest,
                                        lte.status_str,
                                        lte.status_msg,
                                        lte.status_icon,
                                        lte.status_flg
                          FROM lab_tests_ea lte, analysis_req_det ard, analysis_harvest ah, harvest h, episode epis
                         WHERE epis.id_visit = i_id_visit
                           AND epis.id_episode = lte.id_prev_episode
                           AND lte.flg_status_det != g_cancel
                           AND lte.id_analysis_req_det = ard.id_analysis_req_det
                           AND lte.id_analysis_req_det = ah.id_analysis_req_det
                           AND ah.flg_status != pk_lab_tests_constant.g_inactive
                           AND ah.id_harvest = h.id_harvest
                           AND h.flg_status NOT IN
                               (pk_lab_tests_constant.g_harvest_waiting, pk_lab_tests_constant.g_harvest_cancel)
                              -- 
                           AND (lte.flg_status_det NOT IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                            t.column_value
                                                             FROM TABLE(i_filter_status) t) OR
                               lte.dt_req > i_filter_tstz)
                           AND (SELECT pk_lab_tests_api_db.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                                  FROM dual) = pk_alert_constant.g_yes
                        UNION ALL
                        SELECT DISTINCT row_number() over(PARTITION BY lte.id_analysis_req_det, h.id_harvest_group ORDER BY h.dt_harvest_tstz DESC NULLS LAST) rn,
                                        lte.dt_target,
                                        lte.dt_req,
                                        lte.flg_referral,
                                        lte.flg_status_det,
                                        lte.flg_status_harvest,
                                        lte.id_analysis,
                                        lte.id_sample_type,
                                        epis.id_epis_type,
                                        lte.id_analysis_req_det,
                                        ah.id_harvest,
                                        lte.status_str,
                                        lte.status_msg,
                                        lte.status_icon,
                                        lte.status_flg
                          FROM lab_tests_ea lte, analysis_req_det ard, analysis_harvest ah, harvest h, episode epis
                         WHERE epis.id_visit = i_id_visit
                           AND epis.id_episode = ard.id_episode_origin
                           AND lte.flg_status_det != g_cancel
                           AND lte.id_analysis_req_det = ard.id_analysis_req_det
                           AND lte.id_analysis_req_det = ah.id_analysis_req_det
                           AND ah.flg_status != pk_lab_tests_constant.g_inactive
                           AND ah.id_harvest = h.id_harvest
                           AND h.flg_status NOT IN
                               (pk_lab_tests_constant.g_harvest_waiting, pk_lab_tests_constant.g_harvest_cancel)
                              -- 
                           AND (lte.flg_status_det NOT IN (SELECT /*+ opt_estimate (table t rows=1)*/
                                                            t.column_value
                                                             FROM TABLE(i_filter_status) t) OR
                               lte.dt_req > i_filter_tstz)
                           AND (SELECT pk_lab_tests_api_db.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                                  FROM dual) = pk_alert_constant.g_yes) v
                 WHERE v.rn = 1) t;
    
        RETURN l_tbl;
    END tf_summary_grid_analy;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
    --
    g_icon        := 'I';
    g_no_color    := 'X';
    g_color_red   := 'R';
    g_color_green := 'G';
    --
    g_cancel        := 'C';
    g_cancel_u      := 'U';
    g_resolved      := 'R';
    g_epis_inactive := 'I';
    g_available     := 'Y';
    g_active        := 'A';
    --
    g_flg_status_x     := 'X'; -- Para o exterior
    g_flg_status_pa    := 'PA'; -- Por agendar
    g_flg_status_a     := 'A'; -- Activo / agendado
    g_flg_status_r     := 'R'; -- Requisitado
    g_flg_status_d     := 'D'; -- Pendente
    g_flg_status_e     := 'E'; -- Em curso / em execução
    g_flg_status_ex    := 'EX'; -- Executado
    g_flg_status_cc    := 'CC'; -- Colheita em curso
    g_flg_status_h     := 'H'; -- Colhido
    g_flg_status_t     := 'T'; -- Transporte
    g_flg_status_end_t := 'M'; -- transporte terminado
    g_flg_status_p     := 'P'; -- Resultado parcial
    g_flg_status_f     := 'F'; -- Concluído
    g_flg_status_l     := 'L'; -- Lido
    g_flg_status_s     := 'S'; -- Suspenso / Sos
    g_flg_status_i     := 'I'; -- Interrompido
    g_flg_status_c     := 'C'; -- Anulado
    --
    g_text  := 'T';
    g_date  := 'D';
    g_read  := 'L';
    g_label := 'L';
    --
    g_flg_type_d := 'D';
    g_flg_type_e := 'E';
    g_flg_type_a := 'A';
    g_flg_type_i := 'I';
    g_flg_type_o := 'O';
    --
    -- procedimentos
    g_interv_status_final := 'F';
    g_interv_status_curso := 'E';
    g_interv_status_inter := 'I';
    --
    g_interv_plan_admt  := 'A';
    g_interv_plan_nadmt := 'N';
    g_interv_plan_req   := 'R';
    g_interv_plan_pend  := 'D';
    g_interv_plan_canc  := 'C';
    --
    g_interv_type_nor := 'N';
    g_interv_type_sos := 'S';
    g_interv_type_uni := 'U';
    g_interv_type_ete := 'A';
    g_interv_type_con := 'C';
    --
    g_complaint_act := 'A';
    --
    g_diag_type_p      := 'P';
    g_diag_type_d      := 'D';
    g_diag_type_b      := 'B';
    g_ed_flg_status_d  := 'D'; --despiste(ampulheta)
    g_ed_flg_status_co := 'F'; --confirmar  
    --
    -- Critical care
    g_flg_type_c := 'C';
    g_flg_type_h := 'H';
    --    
    g_exam_status_final := 'F';
    g_exam_status_read  := 'L';
    g_exam_can_req      := 'P';
    -- 
    g_exam_type             := 'E';
    g_exam_type_img         := 'I';
    g_analisys_status_final := 'F';
    g_analisys_status_red   := 'L';
    --
    g_tests_type_exam     := 'E';
    g_tests_type_analisys := 'A';
    g_tests_type_result   := 'R';
    --
    --
    g_treat_type_interv := 'I';
    g_treat_type_drug   := 'D';
    --
    g_allergies_stat := 'A';
    --
    g_vs_read_active := 'A';
    g_vs_read_cancel := 'C';
    g_vs_rel_sum     := 'S'; -- TOTAL GLASGOW
    g_vs_rel_conc    := 'C'; -- PRESSÃO ARTERIAL
    g_vs_rel_man     := 'M'; -- MANCHESTER 
    g_vs_avail       := 'Y';
    --
    g_epis_document_act := 'A';
    g_criteria          := 'I';

    g_icon_name := 'CheckIcon';
    --
    -- DOCUMENTATION
    g_area_complaint          := 20;
    g_area_history            := 21;
    g_area_review_system      := 22;
    g_area_past_med_hist      := 24;
    g_area_past_f_social_hist := 25;
    g_area_physical_exam_d    := 28;
    g_area_physical_exam_n    := 1045;
    --
    g_rreview_read_stat := 'A';
    g_flg_time_next     := 'N';
    g_document_n        := 'N';
    g_document_d        := 'D';
    --
    g_flg_temp := 'T';
    g_flg_def  := 'D';
    --
    g_anam_flg_type_c := 'C';
    g_anam_flg_type_a := 'A';
    g_pat_hfam_type   := 'F';
    g_pat_hsoc_type   := 'S';
    g_flg_temp_d      := 'D';
    g_flg_temp_t      := 'T';

    g_analysis_type_req     := 'AR';
    g_analysis_type_req_det := 'AD';
    g_analysis_type_harv    := 'AH';

END pk_edis_summary;
/
