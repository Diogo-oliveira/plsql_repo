/*-- Last Change Revision: $Rev: 2049207 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-11-04 17:55:50 +0000 (sex, 04 nov 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_periodic_observation IS

    g_error         VARCHAR2(1000 CHAR);
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_found         BOOLEAN;
    g_package_name  VARCHAR2(32 CHAR);
    g_package_owner VARCHAR2(32 CHAR);
    g_exception     EXCEPTION;
    g_fault         EXCEPTION;
    g_vs_exists     EXCEPTION; -- throw when registering an already read vital sign

    -- configurations
    g_cfg_enable_labs        CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_ENABLE_LAB_TEST_RESULTS';
    g_cfg_col_aggregate      CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_COL_AGGREGATE';
    g_cfg_col_create         CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_COL_CREATE';
    g_cfg_default_view       CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_DEFAULT_VIEW';
    g_cfg_default_view_pregn CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_PREGN_DEFAULT_VIEW';
    g_cvf_default_view_mo    CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_MEDICAL_ORDER_VIEW';
    g_cfg_value_scope        CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_VALUE_SCOPE';
    g_cfg_vs_sort            CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_VS_DATE_SORT';
    g_cfg_show_ref_vals      CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_SHOW_REF_VALS';
    g_cfg_time_filter_e      CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_TIME_FILTER_EXAM';
    g_cfg_time_filter_a      CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_TIME_FILTER_LAB';
    g_cfg_disable_parameter  CONSTANT sys_config.id_sys_config%TYPE := 'PER_OBS_DISABLE_PARAM';

    -- value scope
    g_scope_episode CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_scope_inst    CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_scope_group   CONSTANT VARCHAR2(1 CHAR) := 'G';

    -- value style
    g_style_normal CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_style_italic CONSTANT VARCHAR2(1 CHAR) := 'I';

    -- vital sign sort
    g_vs_sort_asc CONSTANT VARCHAR2(1 CHAR) := 'A';

    -- column origin
    g_orig_auto   CONSTANT po_param_reg.flg_origin%TYPE := 'A';
    g_orig_manual CONSTANT po_param_reg.flg_origin%TYPE := 'M';

    -- patient health programs exclude stats
    g_hpg_exc_status CONSTANT table_varchar := table_varchar(pk_health_program.g_flg_status_cancelled);

    TYPE t_coll_popmc IS TABLE OF po_param_mc%ROWTYPE;

    CURSOR c_pop_pk
    (
        i_param IN po_param.id_po_param%TYPE,
        i_owner IN po_param.id_inst_owner%TYPE
    ) IS
        SELECT pop.id_parameter, pop.flg_type
          FROM po_param pop
         WHERE pop.id_po_param = i_param
           AND pop.id_inst_owner = i_owner;

    CURSOR c_pop_param
    (
        i_type        IN po_param.flg_type%TYPE,
        i_parameter   IN po_param.id_parameter%TYPE,
        i_owner       IN po_param.id_inst_owner%TYPE,
        i_sample_type IN po_param.id_sample_type%TYPE
    ) IS
        SELECT pop.id_po_param, pop.id_inst_owner, pop.id_sample_type
          FROM po_param pop
         WHERE pop.flg_type = i_type
           AND pop.id_parameter = i_parameter
           AND pop.flg_available = pk_alert_constant.g_yes
           AND pop.id_inst_owner IN (i_owner, 0)
           AND (pop.id_sample_type = i_sample_type AND i_type = 'A' OR i_sample_type IS NULL)
         ORDER BY pop.id_inst_owner DESC;

    CURSOR c_popmc(i_popr IN po_param_reg.id_po_param_reg%TYPE) IS
        SELECT popmc.*
          FROM po_param_reg_mc poprmc
          JOIN po_param_mc popmc
            ON poprmc.id_po_param_mc = popmc.id_po_param_mc
         WHERE poprmc.id_po_param_reg = i_popr
         ORDER BY popmc.rank;

    /**
    * Get an habit record notes.
    *
    * @param i_lang         language identifier
    * @param i_value        record value
    * @param i_um           unit measure identifier
    * @param i_popmc        multichoice option identifiers
    *
    * @return               habit record notes
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/03/27
    */
    FUNCTION get_habit_notes
    (
        i_lang  IN language.id_language%TYPE,
        i_value IN po_param_reg.value%TYPE,
        i_um    IN po_param_reg.id_unit_measure%TYPE,
        i_popmc IN table_number
    ) RETURN pat_habit.notes%TYPE IS
        l_ret  pat_habit.notes%TYPE;
        l_opts table_varchar;
    
        CURSOR c_popmc IS
            SELECT pk_translation.get_translation(i_lang, popmc.code_po_param_mc) desc_pod
              FROM po_param_mc popmc
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.column_value id_po_param_mc
                      FROM TABLE(CAST(i_popmc AS table_number)) t) t
                ON popmc.id_po_param_mc = t.id_po_param_mc
             ORDER BY popmc.rank;
    BEGIN
        IF i_popmc IS NULL
           OR i_popmc.count < 1
        THEN
            l_ret := TRIM(i_value || ' ' ||
                          pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                       i_prof         => NULL,
                                                                       i_unit_measure => i_um));
        ELSE
            OPEN c_popmc;
            FETCH c_popmc BULK COLLECT
                INTO l_opts;
            CLOSE c_popmc;
        
            l_ret := pk_utils.to_string(i_input => l_opts);
        END IF;
    
        RETURN l_ret;
    END get_habit_notes;

    /**********************************************************************************************
    *   Retornar o id_clinical_service
    *
    * @param i_episode                ID DO EPISODIO
    
    *
    * @return                         id_clinical_setvice
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/08/17
    **********************************************************************************************/
    FUNCTION get_id_clinical_service(i_episode IN episode.id_episode%TYPE) RETURN NUMBER IS
    
        CURSOR c_id_clinical_service IS
            SELECT id_clinical_service
              FROM episode
             WHERE id_episode = i_episode;
    
        i_id_clinical_service clinical_service.id_clinical_service%TYPE;
    BEGIN
        IF i_episode IS NOT NULL
        THEN
            OPEN c_id_clinical_service;
            FETCH c_id_clinical_service
                INTO i_id_clinical_service;
            CLOSE c_id_clinical_service;
        
        END IF;
    
        RETURN i_id_clinical_service;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.error_handling('GET_ID_CLINICAL_SERVICE', g_package_name, g_error, SQLERRM);
            RETURN NULL;
    END;

    /**********************************************************************************************
    * Retornar os tipos de parametros disponíveis para as observações periódicas
    *
    * @param i_lang                   the id language
    * @param i_prof                   Profissional que requisita
    
    * @param o_param                  cursor
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/08/23
    **********************************************************************************************/

    FUNCTION get_periodic_param_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_param OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_PARAM';
        OPEN o_param FOR
            SELECT pk_translation.get_translation(i_lang, code_periodic_param_type) label,
                   flg_periodic_param_type data,
                   decode(flg_periodic_param_type,
                          g_analysis,
                          pk_alert_constant.g_yes,
                          g_med_local,
                          pk_alert_constant.g_yes,
                          g_med_ext,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) coluna
              FROM periodic_param_type p
             WHERE p.flg_available = pk_alert_constant.g_yes
               AND p.flg_periodic_param_type NOT IN (g_habit, g_exam)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PERIODIC_PARAM_TYPE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_periodic_param_type;

    FUNCTION get_periodic_param_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_param         OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_PARAM';
        IF i_owner = g_parameter_mother
        THEN
            OPEN o_param FOR
                SELECT pk_translation.get_translation(i_lang, code_periodic_param_type) label,
                       flg_periodic_param_type data,
                       decode(flg_periodic_param_type,
                              g_analysis,
                              pk_alert_constant.g_yes,
                              g_med_local,
                              pk_alert_constant.g_yes,
                              g_med_ext,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no) coluna,
                       i_pat_pregnancy id_pat_pregnancy,
                       i_owner woman_health_flg
                  FROM periodic_param_type p
                 WHERE p.flg_available = pk_alert_constant.g_yes
                 ORDER BY rank;
        ELSE
            OPEN o_param FOR
                SELECT pk_translation.get_translation(i_lang, code_periodic_param_type) label,
                       flg_periodic_param_type data,
                       decode(flg_periodic_param_type,
                              g_analysis,
                              pk_alert_constant.g_yes,
                              g_med_local,
                              pk_alert_constant.g_yes,
                              g_med_ext,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no) coluna,
                       i_pat_pregnancy id_pat_pregnancy,
                       i_owner woman_health_flg
                  FROM periodic_param_type p
                 WHERE p.flg_available = pk_alert_constant.g_yes
                   AND p.flg_periodic_param_type NOT IN (g_habit, g_analysis)
                 ORDER BY rank;
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
                                              'GET_PERIODIC_PARAM_TYPE',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_periodic_param_type;

    /**********************************************************************************************
    *  Retornar Ao adicionar um parametro novo retornar as analises/SV/Habitos/Biometris/Outros Parametros
    *
    * @param i_lang                       the id language
    * @param i_prof                       Profissional que requisita
    * @param i_flg_periodic_param_type    Tipo de parametro: A - Análises; VS - Sinais Vitais; PE - Biometria; O - Outros Parâmetros; H - Hábitos
    * @param i_patient                    id_do paciente
    * @param i_episode                    id_do episódio
    
    * @param o_param                      cursor dos parametros
    * @param o_error                      Error message
    *
    * @return                             TRUE if sucess, FALSE otherwise
    *
    * @author                             Teresa Coutinho
    * @version                            1.0
    * @since                              2008/01/23
    **********************************************************************************************/

    FUNCTION get_other_periodic_param
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_periodic_param_type IN periodic_param_type.flg_periodic_param_type%TYPE,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        o_param                   OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_t016    sys_message.desc_message%TYPE;
        l_msg_t017    sys_message.desc_message%TYPE;
        l_msg_t018    sys_message.desc_message%TYPE;
        l_params      t_coll_po_param;
        l_cursor      pk_types.cursor_type;
        l_habit_ids   table_number := table_number();
        l_habit_descs table_varchar := table_varchar();
        --        l_info        table_info;
        l_info t_tbl_lab_tests_cat_search;
    BEGIN
        l_msg_t016 := pk_message.get_message(i_lang, i_prof, 'PERIODIC_OBSERVATION_T016');
        l_msg_t017 := pk_message.get_message(i_lang, i_prof, 'PERIODIC_OBSERVATION_T017');
        l_msg_t018 := pk_message.get_message(i_lang, i_prof, 'PERIODIC_OBSERVATION_T018');
    
        IF i_flg_periodic_param_type = g_analysis -- analises
        THEN
            -- ALERT-154864 - Mário Mineiro - OK. Changed to call diff function than 2.5.      
            g_error := 'CALL PK_LAB_TESTS_API_DB.GET_LAB_TEST_CATEGORY_SEARCH';
            IF NOT pk_lab_tests_api_db.get_lab_test_category_search(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_patient         => i_patient,
                                                                    i_sample_type     => NULL,
                                                                    i_exam_cat_parent => NULL,
                                                                    i_codification    => NULL,
                                                                    o_list            => l_info,
                                                                    o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'OPEN o_param A';
            OPEN o_param FOR
                SELECT l_msg_t016       title,
                       l_msg_t017       title_det,
                       g_analysis       flg_periodic_param_type,
                       t.id_exam_cat    id_param,
                       t.desc_category  desc_param,
                       NULL             rank,
                       t.id_sample_type
                  FROM TABLE(l_info) t
                 ORDER BY t.desc_category;
        
        ELSE
        
            l_params := get_param(i_prof => i_prof, i_patient => i_patient, i_episode => i_episode);
        
            IF i_flg_periodic_param_type IN (g_vs_vs, g_vs_bio) -- sinais vitais, biometria
            THEN
                g_error := 'OPEN o_param VS';
                OPEN o_param FOR
                    SELECT l_msg_t018 title,
                           NULL title_det,
                           g_vital_sign flg_periodic_param_type,
                           vs.id_vital_sign id_param,
                           name_vs desc_param,
                           get_selected(i_prof, l_params, g_vital_sign, vs.id_vital_sign, NULL) selected
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang,
                                                                       i_prof,
                                                                       i_episode,
                                                                       NULL,
                                                                       i_flg_periodic_param_type)) vs
                     WHERE NOT EXISTS (SELECT 1
                              FROM vital_sign_relation vsr
                             WHERE (vsr.id_vital_sign_parent = vs.id_vital_sign OR
                                   vsr.id_vital_sign_detail = vs.id_vital_sign)
                               AND vsr.relation_domain = g_vs_rel_sum)
                     ORDER BY desc_param;
            
            ELSIF i_flg_periodic_param_type = g_habit -- habitos
            THEN
                g_error := 'CALL pk_list.get_habit_list';
                IF NOT
                    pk_list.get_habit_list(i_lang => i_lang, i_prof => i_prof, o_list => l_cursor, o_error => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error := 'FETCH l_cursor';
                FETCH l_cursor BULK COLLECT
                    INTO l_habit_ids, l_habit_descs;
                CLOSE l_cursor;
            
                g_error := 'OPEN o_param H';
                OPEN o_param FOR
                    SELECT l_msg_t018 title,
                           NULL title_det,
                           g_habit flg_periodic_param_type,
                           t1.id_habit id_param,
                           t2.desc_habit desc_param,
                           t1.rn rank,
                           get_selected(i_prof, l_params, g_habit, t1.id_habit, NULL) selected
                      FROM (SELECT t.column_value id_habit, rownum rn
                              FROM TABLE(l_habit_ids) t) t1,
                           (SELECT t.column_value desc_habit, rownum rn
                              FROM TABLE(l_habit_descs) t) t2
                     WHERE t1.rn = t2.rn
                     ORDER BY desc_param;
            
            ELSIF i_flg_periodic_param_type = g_others
            THEN
            
                g_error := 'OPEN o_param';
                OPEN o_param FOR
                    SELECT l_msg_t018 title,
                           NULL title_det,
                           g_others flg_periodic_param_type,
                           pp.id_parameter id_param,
                           pk_translation.get_translation(i_lang, pp.code_po_param) desc_param,
                           pp.rank rank,
                           get_selected(i_prof, l_params, g_others, pp.id_parameter, NULL) selected
                      FROM po_param pp
                     WHERE pp.id_inst_owner = i_prof.institution
                       AND pp.flg_type = g_others
                       AND pp.flg_available = pk_alert_constant.g_yes
                       AND pp.flg_domain IN (g_flg_domain_a, g_flg_domain_o)
                     ORDER BY desc_param;
            
            ELSE
                pk_types.open_my_cursor(o_param);
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_param);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_OTHER_PERIODIC_PARAM',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_param);
            RETURN FALSE;
    END get_other_periodic_param;

    FUNCTION get_other_periodic_param
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_periodic_param_type IN periodic_param_type.flg_periodic_param_type%TYPE,
        i_patient                 IN patient.id_patient%TYPE,
        i_episode                 IN episode.id_episode%TYPE,
        i_pat_pregnancy           IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner                   IN VARCHAR2,
        o_param                   OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_t016    sys_message.desc_message%TYPE;
        l_msg_t017    sys_message.desc_message%TYPE;
        l_msg_t018    sys_message.desc_message%TYPE;
        l_msg_t019    sys_message.desc_message%TYPE;
        l_msg_t020    sys_message.desc_message%TYPE;
        l_params      t_coll_po_param;
        l_cursor      pk_types.cursor_type;
        l_habit_ids   table_number := table_number();
        l_habit_descs table_varchar := table_varchar();
        l_info        t_tbl_lab_tests_cat_search;
        l_flg_domain  po_param.flg_domain%TYPE;
    BEGIN
        l_msg_t016 := pk_message.get_message(i_lang, i_prof, 'PERIODIC_OBSERVATION_T016');
        l_msg_t017 := pk_message.get_message(i_lang, i_prof, 'PERIODIC_OBSERVATION_T017');
        l_msg_t018 := pk_message.get_message(i_lang, i_prof, 'PERIODIC_OBSERVATION_T018');
    
        l_msg_t019 := pk_message.get_message(i_lang, i_prof, 'EXAMS_T010');
        l_msg_t020 := pk_message.get_message(i_lang, i_prof, 'EXAMS_T011');
    
        IF i_flg_periodic_param_type = g_analysis -- analises
        THEN
            g_error := 'CALL PK_LAB_TESTS_API_DB.GET_LAB_TEST_CATEGORY_SEARCH';
            -- ALERT-154864           
            IF NOT pk_lab_tests_api_db.get_lab_test_category_search(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_patient         => i_patient,
                                                                    i_sample_type     => NULL,
                                                                    i_exam_cat_parent => NULL,
                                                                    i_codification    => NULL,
                                                                    o_list            => l_info,
                                                                    o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
            g_error := 'OPEN o_param A';
            OPEN o_param FOR
                SELECT l_msg_t016       title,
                       l_msg_t017       title_det,
                       g_analysis       flg_periodic_param_type,
                       t.id_exam_cat    id_param,
                       t.desc_category  desc_param,
                       NULL             rank,
                       i_pat_pregnancy  id_pat_pregnancy,
                       i_owner          woman_health_flg,
                       t.id_sample_type
                  FROM TABLE(l_info) t
                 ORDER BY t.desc_category;
        
        ELSE
        
            l_params := get_param_wp(i_prof          => i_prof,
                                     i_patient       => i_patient,
                                     i_episode       => i_episode,
                                     i_pat_pregnancy => i_pat_pregnancy,
                                     i_owner         => i_owner);
        
            IF i_flg_periodic_param_type IN (g_vs_vs, g_vs_bio) -- sinais vitais, biometria
            THEN
                g_error := 'OPEN o_param VS';
                OPEN o_param FOR
                    SELECT l_msg_t018 title,
                           NULL title_det,
                           g_vital_sign flg_periodic_param_type,
                           vs.id_vital_sign id_param,
                           name_vs desc_param,
                           get_selected(i_prof, l_params, g_vital_sign, vs.id_vital_sign, NULL) selected
                      FROM TABLE(pk_vital_sign_core.tf_get_vital_signs(i_lang,
                                                                       i_prof,
                                                                       i_episode,
                                                                       NULL,
                                                                       i_flg_periodic_param_type)) vs
                     WHERE NOT EXISTS (SELECT 1
                              FROM vital_sign_relation vsr
                             WHERE (vsr.id_vital_sign_parent = vs.id_vital_sign OR
                                   vsr.id_vital_sign_detail = vs.id_vital_sign)
                               AND vsr.relation_domain = g_vs_rel_sum)
                     ORDER BY desc_param;
            
            ELSIF i_flg_periodic_param_type = g_habit -- habitos
            THEN
                g_error := 'CALL pk_list.get_habit_list';
                IF NOT
                    pk_list.get_habit_list(i_lang => i_lang, i_prof => i_prof, o_list => l_cursor, o_error => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error := 'FETCH l_cursor';
                FETCH l_cursor BULK COLLECT
                    INTO l_habit_ids, l_habit_descs;
                CLOSE l_cursor;
            
                g_error := 'OPEN o_param H';
                OPEN o_param FOR
                    SELECT l_msg_t018 title,
                           NULL title_det,
                           g_habit flg_periodic_param_type,
                           t1.id_habit id_param,
                           t2.desc_habit desc_param,
                           t1.rn rank,
                           get_selected(i_prof, l_params, g_habit, t1.id_habit, NULL) selected,
                           i_pat_pregnancy id_pat_pregnancy,
                           i_owner woman_health_flg
                      FROM (SELECT t.column_value id_habit, rownum rn
                              FROM TABLE(l_habit_ids) t) t1,
                           (SELECT t.column_value desc_habit, rownum rn
                              FROM TABLE(l_habit_descs) t) t2
                     WHERE t1.rn = t2.rn
                     ORDER BY desc_param;
            
            ELSIF i_flg_periodic_param_type = g_exam
            THEN
            
                g_error := 'OPEN O_PARAM';
                OPEN o_param FOR
                    SELECT l_msg_t020 title,
                           NULL title_det,
                           g_exam flg_periodic_param_type,
                           ex.id_exam id_param,
                           pk_translation.get_translation(i_lang, ex.code_exam) desc_param,
                           1 rank,
                           'false' selected,
                           i_pat_pregnancy id_pat_pregnancy,
                           i_owner woman_health_flg
                      FROM exam ex
                     WHERE ex.id_content = 'TMP2.181050'
                       AND ex.flg_available = pk_alert_constant.g_yes
                     ORDER BY desc_param;
            
            ELSIF i_flg_periodic_param_type = g_others
            THEN
            
                CASE
                    WHEN i_owner = g_parameter_mother THEN
                        l_flg_domain := g_flg_domain_m;
                    WHEN i_owner = g_parameter_fetus THEN
                        l_flg_domain := g_flg_domain_f;
                    ELSE
                        l_flg_domain := g_flg_domain_a;
                END CASE;
            
                g_error := 'OPEN o_param';
                OPEN o_param FOR
                    SELECT l_msg_t018 title,
                           NULL title_det,
                           g_others flg_periodic_param_type,
                           pp.id_parameter id_param,
                           pk_translation.get_translation(i_lang, pp.code_po_param) desc_param,
                           pp.rank rank,
                           get_selected(i_prof, l_params, g_others, pp.id_parameter, NULL) selected,
                           i_pat_pregnancy id_pat_pregnancy,
                           i_owner woman_health_flg
                      FROM po_param pp
                     WHERE pp.id_inst_owner = i_prof.institution
                       AND pp.flg_type = g_others
                       AND pp.flg_available = pk_alert_constant.g_yes
                       AND pp.flg_domain IN (g_flg_domain_a, l_flg_domain)
                     ORDER BY desc_param;
            
            ELSE
                pk_types.open_my_cursor(o_param);
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_param);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_OTHER_PERIODIC_PARAM',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_param);
            RETURN FALSE;
    END get_other_periodic_param;

    /**********************************************************************************************
    * Adds a new column to the periodic observation grid.
    *
    * @param i_lang                    language identifier.
    * @param i_prof                    logged professional structure.
    * @param i_flg_type_param          type of parameters ('O'ther or 'P'arametrized).
    * @param i_patient                 patient identifier.
    * @param i_episode                 episode identifier.
    * @param i_dt_begin_str            new column date.
    * @param i_prof_req                requesting professional identifier.
    *
    * @author                         Teresa Coutinho
    * @version                        1.0
    * @since                          2007/08/30
    **********************************************************************************************/
    PROCEDURE set_pat_periodic_observation
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_type_param IN periodic_observation_reg.flg_type_param%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_dt_begin_str   IN VARCHAR2,
        i_prof_req       IN periodic_observation_reg.id_prof_writes%TYPE
    ) IS
        i_dt_begin po_param_reg.dt_creation%TYPE;
        l_epis_cs  clinical_service.id_clinical_service%TYPE;
    BEGIN
        l_epis_cs  := pk_periodic_observation.get_id_clinical_service(i_episode);
        i_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin_str, NULL);
    
        IF i_flg_type_param = 'O' -- insere um novo parametro
        THEN
            NULL;
        ELSE
            -- insere uma nova coluna
            INSERT INTO periodic_observation_reg
                (id_periodic_observation_reg,
                 flg_status,
                 id_patient,
                 id_episode,
                 id_prof_writes,
                 dt_periodic_observation_reg,
                 id_institution,
                 flg_type_param,
                 id_clinical_service,
                 flg_ref,
                 flg_type_reg,
                 flg_mig)
            VALUES
                (seq_periodic_observation_reg.nextval,
                 pk_alert_constant.g_active,
                 i_patient,
                 i_episode,
                 i_prof_req,
                 i_dt_begin,
                 i_prof.institution,
                 i_flg_type_param,
                 l_epis_cs,
                 'N',
                 'O',
                 'N');
        END IF;
    END set_pat_periodic_observation;

    PROCEDURE cancel_pat_periodic_obs
    (
        i_prof IN profissional,
        i_por  IN periodic_observation_reg.id_periodic_observation_reg%TYPE
    ) IS
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        UPDATE periodic_observation_reg
           SET flg_status = 'C', dt_canc = g_sysdate_tstz, id_prof_canc = i_prof.id
         WHERE id_periodic_observation_reg = i_por;
    END cancel_pat_periodic_obs;

    PROCEDURE delete_pat_periodic_obs(i_por IN periodic_observation_reg.id_periodic_observation_reg%TYPE) IS
    BEGIN
        DELETE periodic_observation_reg
         WHERE id_periodic_observation_reg = i_por;
    END delete_pat_periodic_obs;

    /**
    * Set value for habit parameters.
    *
    * @param i_lang         language identifier
    * @param i_epis         episode identifier
    * @param i_id_patient   patient identifier
    * @param i_id_habit     habit identifier
    * @param i_prof         logged professional structure
    * @param i_notes        habit notes
    * @param i_dt_begin     habit clinical date
    * @param o_error        error
    *
    * @author               Teresa Coutinho
    * @version               2.4.3
    * @since                2007/08/30
    */
    PROCEDURE set_pat_habit_obs_per
    (
        i_lang       IN language.id_language%TYPE,
        i_epis       IN episode.id_episode%TYPE,
        i_id_patient IN pat_habit.id_patient%TYPE,
        i_id_habit   IN pat_habit.id_habit%TYPE,
        i_prof       IN profissional,
        i_notes      IN pat_habit.notes%TYPE,
        i_dt_begin   IN pat_habit.dt_pat_habit_tstz%TYPE,
        o_error      OUT t_error_out
    ) IS
        l_next      pat_habit.id_pat_habit%TYPE;
        l_msg       sys_message.desc_message%TYPE;
        l_pat_habit pat_habit.id_pat_habit%TYPE;
        l_rowids    table_varchar;
    BEGIN
        g_error := 'CALL pk_patient.check_pat_habit';
        IF NOT pk_patient.check_pat_habit(i_lang   => i_lang,
                                          i_habit  => i_id_habit,
                                          i_id_pat => i_id_patient,
                                          o_msg    => l_msg,
                                          o_error  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_msg IS NOT NULL
        THEN
            -- se já tem mais que um registo para o mesmo hábito
            g_error := 'SELECT l_pat_habit';
            SELECT ph.id_pat_habit
              INTO l_pat_habit
              FROM pat_habit ph
             WHERE ph.id_patient = i_id_patient
               AND ph.id_habit = i_id_habit
               AND ph.flg_status = pk_alert_constant.g_active;
        
            g_error := 'CALL pk_review.set_review';
            IF NOT pk_review.set_review(i_lang           => i_lang,
                                        i_prof           => i_prof,
                                        i_id_record_area => l_pat_habit,
                                        i_flg_context    => pk_review.get_habits_context,
                                        i_dt_review      => i_dt_begin,
                                        i_review_notes   => i_notes,
                                        o_error          => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            --Verifica se é um novo registo para inserir ou um registo já existente para actualizar.
            IF i_id_habit IS NOT NULL
            THEN
                --Insere novo registo
            
                -- *********************************
                -- PT 18/09/2008 2.4.3.d
                g_error := 'INSERT NEW HABIT';
                ts_pat_habit.ins(id_pat_habit_out     => l_next,
                                 id_patient_in        => i_id_patient,
                                 id_habit_in          => i_id_habit,
                                 dt_pat_habit_tstz_in => i_dt_begin,
                                 flg_status_in        => pk_alert_constant.g_active,
                                 id_prof_writes_in    => i_prof.id,
                                 notes_in             => i_notes,
                                 id_institution_in    => i_prof.institution,
                                 id_episode_in        => i_epis,
                                 rows_out             => l_rowids);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_HABIT',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
                -- *********************************
            
                l_rowids := table_varchar();
            
                g_error := 'INSERT INTO PAT_PROBLEM';
                ts_pat_problem.ins(id_pat_problem_in      => ts_pat_problem.next_key,
                                   id_patient_in          => i_id_patient,
                                   id_professional_ins_in => i_prof.id,
                                   dt_pat_problem_tstz_in => i_dt_begin,
                                   flg_status_in          => pk_alert_constant.g_active,
                                   notes_in               => i_notes,
                                   id_institution_in      => i_prof.institution,
                                   id_habit_in            => i_id_habit,
                                   id_pat_habit_in        => l_next,
                                   id_episode_in          => i_epis,
                                   rows_out               => l_rowids);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PROBLEM',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        END IF;
    END set_pat_habit_obs_per;

    /**********************************************************************************************
    *  Obter a lista de análises realizadas na sala indicada e cujo tipo de amostra é o indicado
    *
    * @param i_lang         the id language
    * @param i_sample_type  tipo de amostra para colheita
    * @param i_room         ID da sala
    * @param i_patient      id do paciente
    * @param i_prof         profissional
    
    * @param  o_analysis    lista de análises
    * @return               TRUE if sucess, FALSE otherwise
    *
    * @author               Teresa Coutinho
    * @version              1.0
    * @since                2008/01/23
    **********************************************************************************************/

    FUNCTION get_periodic_observation_an
    (
        i_lang          IN language.id_language%TYPE,
        i_room          IN room.id_room%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_analysis      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_info   t_tbl_lab_tests_for_selection;
        l_params t_coll_po_param;
    BEGIN
        -- ALERT-154864
        IF NOT pk_lab_tests_api_db.get_lab_test_for_selection(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_patient         => i_patient,
                                                              i_sample_type     => NULL,
                                                              i_exam_cat        => NULL,
                                                              i_exam_cat_parent => i_room,
                                                              i_codification    => NULL,
                                                              o_list            => l_info,
                                                              o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        l_params := get_param(i_prof => i_prof, i_patient => i_patient, i_episode => i_episode);
    
        g_error := 'GET CURSOR';
        OPEN o_analysis FOR
            SELECT t.desc_analysis code_analysis,
                   t.id_analysis,
                   t.type,
                   t.id_sample_type,
                   get_selected(i_prof, l_params, t.type, t.id_analysis, t.id_sample_type) selected
              FROM TABLE(l_info) t
             WHERE t.type = g_analysis
               AND t.id_sample_type IS NOT NULL
             ORDER BY t.desc_analysis;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PERIODIC_OBSERVATION_AN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_analysis);
            RETURN FALSE;
        
    END;

    FUNCTION get_periodic_observation_an
    (
        i_lang          IN language.id_language%TYPE,
        i_room          IN room.id_room%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        o_analysis      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_info   t_tbl_lab_tests_for_selection;
        l_params t_coll_po_param;
    
    BEGIN
    
        g_error := 'CALL PK_LAB_TESTS_API_DB.GET_LAB_TEST_FOR_SELECTION';
        -- ALERT-154864       
        IF NOT pk_lab_tests_api_db.get_lab_test_for_selection(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_patient         => i_patient,
                                                              i_sample_type     => NULL,
                                                              i_exam_cat        => NULL,
                                                              i_exam_cat_parent => i_room,
                                                              i_codification    => NULL,
                                                              o_list            => l_info,
                                                              o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
        l_params := get_param_wp(i_prof          => i_prof,
                                 i_patient       => i_patient,
                                 i_episode       => i_episode,
                                 i_pat_pregnancy => i_pat_pregnancy,
                                 i_owner         => i_owner);
    
        g_error := 'GET CURSOR';
        OPEN o_analysis FOR
            SELECT t.desc_analysis code_analysis,
                   t.id_analysis,
                   t.type,
                   get_selected(i_prof, l_params, t.type, t.id_analysis, t.id_sample_type) selected,
                   i_pat_pregnancy id_pat_pregnancy,
                   i_owner woman_health_flg,
                   t.id_sample_type
              FROM TABLE(l_info) t
             WHERE t.type = g_analysis
               AND t.id_sample_type IS NOT NULL
             ORDER BY t.desc_analysis;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PERIODIC_OBSERVATION_AN',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_analysis);
            RETURN FALSE;
        
    END;
    /**
    * Get maximum result date.
    *
    * @param i_values       values collection
    * @param i_episode      episode identifier
    *
    * @return               maximum result date
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/19
    */
    FUNCTION get_dt_result_max
    (
        i_values  IN t_coll_po_value,
        i_episode IN episode.id_episode%TYPE := NULL
    ) RETURN po_param_reg.dt_result%TYPE IS
        l_ret po_param_reg.dt_result%TYPE;
    BEGIN
        IF i_values IS NULL
           OR i_values.count < 1
        THEN
            l_ret := NULL;
        ELSE
            FOR i IN i_values.first .. i_values.last
            LOOP
                IF i_values(i).id_episode = i_episode
                    OR i_episode IS NULL
                THEN
                    l_ret := nvl(l_ret, i_values(i).dt_result);
                
                    IF l_ret < i_values(i).dt_result
                    THEN
                        l_ret := i_values(i).dt_result;
                    END IF;
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_dt_result_max;

    /**
    * Get parameters cursor for hpg view.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_params       parameter identifiers
    * @param i_med_data     medication data
    * @param i_values       values collection
    * @param i_cancel       can parameters be canceled? Y/N
    * @param o_param        parameters
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    PROCEDURE get_param_cursor_sets
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN t_coll_po_param,
        i_med_data IN t_tbl_rec_sum_act_meds,
        o_param    OUT pk_types.cursor_type
    ) IS
        l_dcs epis_info.id_dep_clin_serv%TYPE;
    BEGIN
    
        l_dcs := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        g_error := 'OPEN o_param';
        OPEN o_param FOR
            SELECT pop.id_po_param parameter_id,
                   pop.id_inst_owner parameter_owner_id,
                   pop.id_parameter parameter_external_id,
                   (SELECT get_param_desc(i_lang,
                                          i_prof,
                                          pop.id_po_param,
                                          pop.id_inst_owner,
                                          pop.flg_type,
                                          pop.id_parameter,
                                          l_dcs)
                      FROM dual) parameter_desc,
                   pop.flg_type parameter_flg_type,
                   pop.flg_fill_type parameter_flg_fill_type,
                   CASE
                        WHEN pop.flg_type IN (g_vital_sign) THEN
                         get_param_create(i_prof, pop.flg_type, pop.id_po_param, pop.id_parameter)
                        ELSE
                         get_param_create(i_prof, pop.flg_type, pop.id_po_param, NULL)
                    END parameter_flg_create,
                   pop.id_sample_type parameter_sample_type_id,
                   CASE
                        WHEN pop.flg_type IN (g_others) THEN
                         pk_alert_constant.g_yes
                        WHEN pop.flg_type IN (g_vital_sign) THEN
                         has_vital_sign_val_ref(pop.id_parameter)
                        ELSE
                         pk_alert_constant.g_no
                    END parameter_ref_value
              FROM (SELECT pop.id_po_param,
                           pop.id_inst_owner,
                           pop.flg_type,
                           pop.id_parameter,
                           pop.flg_fill_type,
                           (SELECT get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank)
                              FROM dual) rank,
                           pop.id_sample_type
                      FROM po_param pop
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                            t.id_po_param, t.id_inst_owner
                             FROM TABLE(CAST(i_params AS t_coll_po_param)) t) t
                        ON pop.id_po_param = t.id_po_param
                       AND pop.id_inst_owner = t.id_inst_owner) pop
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.*
                           FROM TABLE(CAST(i_med_data AS t_tbl_rec_sum_act_meds)) t) med
                ON pop.flg_type IN (g_med_local, g_med_ext)
               AND pop.id_parameter = to_number(med.drug)
             ORDER BY pop.rank, parameter_desc;
    END get_param_cursor_sets;

    PROCEDURE get_param_cursor_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_params        IN t_coll_po_param,
        i_med_data      IN t_tbl_rec_sum_act_meds,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_values        IN t_coll_po_value,
        o_param         OUT pk_types.cursor_type
    ) IS
        l_dcs epis_info.id_dep_clin_serv%TYPE;
    BEGIN
        l_dcs := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        g_error := 'OPEN o_param';
        OPEN o_param FOR
            SELECT pop.id_po_param parameter_id,
                   decode((SELECT COUNT(*)
                            FROM TABLE(i_values) t
                           WHERE t.id_po_param = pop.id_po_param
                             AND t.id_inst_owner = pop.id_inst_owner
                             AND t.flg_status = pk_alert_constant.g_active),
                          0,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) parameter_flg_cancel,
                   pop.id_inst_owner parameter_owner_id,
                   pop.id_parameter parameter_external_id,
                   (SELECT get_param_desc(i_lang,
                                          i_prof,
                                          pop.id_po_param,
                                          pop.id_inst_owner,
                                          pop.flg_type,
                                          pop.id_parameter,
                                          l_dcs)
                      FROM dual) parameter_desc,
                   pop.flg_type parameter_flg_type,
                   pop.flg_fill_type parameter_flg_fill_type,
                   CASE
                        WHEN pop.flg_type IN (g_vital_sign) THEN
                         get_param_create(i_prof, pop.flg_type, pop.id_po_param, pop.id_parameter)
                        ELSE
                         get_param_create(i_prof, pop.flg_type, pop.id_po_param, NULL)
                    END parameter_flg_create,
                   pop.id_sample_type parameter_sample_type_id,
                   CASE
                        WHEN pop.flg_type IN (g_others) THEN
                         pk_alert_constant.g_yes
                        WHEN pop.flg_type IN (g_vital_sign) THEN
                         has_vital_sign_val_ref(pop.id_parameter)
                        ELSE
                         pk_alert_constant.g_no
                    END parameter_ref_value
              FROM (SELECT pop.id_po_param,
                           pop.id_inst_owner,
                           pop.flg_type,
                           pop.id_parameter,
                           pop.flg_fill_type,
                           (SELECT get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank)
                              FROM dual) rank,
                           pop.id_sample_type
                      FROM po_param pop
                      JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                            t.id_po_param, t.id_inst_owner
                             FROM TABLE(CAST(i_params AS t_coll_po_param)) t) t
                        ON pop.id_po_param = t.id_po_param
                       AND pop.id_inst_owner = t.id_inst_owner) pop
              LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                          t.*
                           FROM TABLE(CAST(i_med_data AS t_tbl_rec_sum_act_meds)) t) med
                ON pop.flg_type IN (g_med_local, g_med_ext)
               AND pop.id_parameter = to_number(med.drug)
             ORDER BY pop.rank, parameter_desc;
    END get_param_cursor_wh;
    /**
    * Get parameters cursor.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_params       parameter identifiers
    * @param i_med_data     medication data
    * @param i_values       values collection
    * @param i_cancel       can parameters be canceled? Y/N
    * @param o_param        parameters
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    PROCEDURE get_param_cursor
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN t_coll_po_param,
        i_med_data IN t_tbl_rec_sum_act_meds,
        i_values   IN t_coll_po_value,
        i_cancel   IN VARCHAR2 := pk_alert_constant.g_yes,
        i_dt_begin IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_dt_end   IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_num_reg  IN NUMBER DEFAULT NULL,
        o_param    OUT pk_types.cursor_type
    ) IS
        l_dcs     epis_info.id_dep_clin_serv%TYPE;
        l_patient patient.id_patient%TYPE;
    BEGIN
        l_dcs := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        g_error := 'OPEN o_param';
    
        IF i_num_reg IS NOT NULL
        THEN
            OPEN o_param FOR
                SELECT *
                  FROM (SELECT pop.id_po_param parameter_id,
                               pop.id_inst_owner parameter_owner_id,
                               pop.id_parameter parameter_external_id,
                               (SELECT get_param_desc(i_lang,
                                                      i_prof,
                                                      pop.id_po_param,
                                                      pop.id_inst_owner,
                                                      pop.flg_type,
                                                      pop.id_parameter,
                                                      l_dcs)
                                  FROM dual) parameter_desc,
                               pop.flg_type parameter_flg_type,
                               pop.flg_fill_type parameter_flg_fill_type,
                               decode(i_cancel,
                                      pk_alert_constant.g_yes,
                                      decode((SELECT COUNT(*)
                                               FROM TABLE(CAST(i_values AS t_coll_po_value)) t
                                              WHERE t.id_po_param = pop.id_po_param
                                                AND t.id_inst_owner = pop.id_inst_owner
                                                AND t.flg_status = pk_alert_constant.g_active),
                                             0,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no),
                                      pk_alert_constant.g_no) parameter_flg_cancel,
                               CASE
                                    WHEN pop.flg_type IN (g_vital_sign) THEN
                                     get_param_create(i_prof, pop.flg_type, pop.id_po_param, pop.id_parameter)
                                    ELSE
                                     get_param_create(i_prof, pop.flg_type, pop.id_po_param, NULL)
                                END parameter_flg_create,
                               pop.id_sample_type parameter_sample_type_id,
                               CASE
                                    WHEN pop.flg_type IN (g_others) THEN
                                     pk_alert_constant.g_yes
                                    WHEN pop.flg_type IN (g_vital_sign) THEN
                                     has_vital_sign_val_ref(pop.id_parameter)
                                    ELSE
                                     pk_alert_constant.g_no
                                END parameter_ref_value
                          FROM (SELECT pop.id_po_param,
                                       pop.id_inst_owner,
                                       pop.flg_type,
                                       pop.id_parameter,
                                       pop.flg_fill_type,
                                       (SELECT get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank)
                                          FROM dual) rank,
                                       pop.id_sample_type
                                  FROM po_param pop
                                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                        t.id_po_param, t.id_inst_owner
                                         FROM TABLE(CAST(i_params AS t_coll_po_param)) t) t
                                    ON pop.id_po_param = t.id_po_param
                                   AND pop.id_inst_owner = t.id_inst_owner
                                 WHERE NOT ( --tem dados
                                         NOT EXISTS (SELECT 1
                                                          FROM TABLE(CAST(i_values AS t_coll_po_value)) t
                                                         WHERE t.id_po_param = pop.id_po_param
                                                           AND t.id_inst_owner = pop.id_inst_owner
                                                           AND t.flg_status = pk_alert_constant.g_active)
                                        --tem o parametro num plano retirado
                                         AND EXISTS (SELECT 1
                                                          FROM po_param_sets pps
                                                          JOIN health_program hp
                                                            ON hp.id_content = pps.task_type_content
                                                          JOIN pat_health_program phpg
                                                            ON hp.id_health_program = phpg.id_health_program
                                                         WHERE pps.id_institution IN (i_prof.institution, 0)
                                                           AND pps.id_software IN (i_prof.software, 0)
                                                           AND pps.id_task_type = pk_periodic_observation.g_task_type_hpg
                                                           AND pps.flg_available = pk_alert_constant.g_yes
                                                           AND pps.id_po_param = pop.id_po_param
                                                           AND pps.id_inst_owner = pop.id_inst_owner
                                                           AND phpg.id_patient = l_patient
                                                           AND phpg.id_institution IN
                                                               (SELECT /*+opt_estimate(table t rows=1)*/
                                                                 t.column_value id_institution
                                                                  FROM TABLE(CAST(pk_list.tf_get_all_inst_group(i_prof.institution,
                                                                                                                pk_adt.g_inst_grp_flg_rel_adt) AS
                                                                                  table_number)) t)
                                                           AND phpg.flg_status = 'I'))
                                
                                ) pop
                          LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                     t.*
                                      FROM TABLE(CAST(i_med_data AS t_tbl_rec_sum_act_meds)) t) med
                            ON pop.flg_type IN (g_med_local, g_med_ext)
                           AND pop.id_parameter = to_number(med.drug)
                         ORDER BY pop.id_po_param DESC) tt
                 WHERE rownum <= i_num_reg;
        ELSE
        
            OPEN o_param FOR
                SELECT pop.id_po_param parameter_id,
                       pop.id_inst_owner parameter_owner_id,
                       pop.id_parameter parameter_external_id,
                       (SELECT get_param_desc(i_lang,
                                              i_prof,
                                              pop.id_po_param,
                                              pop.id_inst_owner,
                                              pop.flg_type,
                                              pop.id_parameter,
                                              l_dcs)
                          FROM dual) parameter_desc,
                       pop.flg_type parameter_flg_type,
                       pop.flg_fill_type parameter_flg_fill_type,
                       decode(i_cancel,
                              pk_alert_constant.g_yes,
                              decode((SELECT COUNT(*)
                                       FROM TABLE(CAST(i_values AS t_coll_po_value)) t
                                      WHERE t.id_po_param = pop.id_po_param
                                        AND t.id_inst_owner = pop.id_inst_owner
                                        AND t.flg_status = pk_alert_constant.g_active),
                                     0,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_no),
                              pk_alert_constant.g_no) parameter_flg_cancel,
                       CASE
                            WHEN pop.flg_type IN (g_vital_sign) THEN
                             get_param_create(i_prof, pop.flg_type, pop.id_po_param, pop.id_parameter)
                            ELSE
                             get_param_create(i_prof, pop.flg_type, pop.id_po_param, NULL)
                        END parameter_flg_create,
                       pop.id_sample_type parameter_sample_type_id,
                       CASE
                            WHEN pop.flg_type IN (g_others) THEN
                             pk_alert_constant.g_yes
                            WHEN pop.flg_type IN (g_vital_sign) THEN
                             has_vital_sign_val_ref(pop.id_parameter)
                            ELSE
                             pk_alert_constant.g_no
                        END parameter_ref_value
                  FROM (SELECT pop.id_po_param,
                               pop.id_inst_owner,
                               pop.flg_type,
                               pop.id_parameter,
                               pop.flg_fill_type,
                               (SELECT get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank)
                                  FROM dual) rank,
                               pop.id_sample_type
                          FROM po_param pop
                          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                t.id_po_param, t.id_inst_owner
                                 FROM TABLE(CAST(i_params AS t_coll_po_param)) t) t
                            ON pop.id_po_param = t.id_po_param
                           AND pop.id_inst_owner = t.id_inst_owner
                         WHERE NOT ( --tem dados
                                 NOT EXISTS (SELECT 1
                                                  FROM TABLE(CAST(i_values AS t_coll_po_value)) t
                                                 WHERE t.id_po_param = pop.id_po_param
                                                   AND t.id_inst_owner = pop.id_inst_owner
                                                   AND t.flg_status = pk_alert_constant.g_active)
                                --tem o parametro num plano retirado
                                 AND EXISTS (SELECT 1
                                                  FROM po_param_sets pps
                                                  JOIN health_program hp
                                                    ON hp.id_content = pps.task_type_content
                                                  JOIN pat_health_program phpg
                                                    ON hp.id_health_program = phpg.id_health_program
                                                 WHERE pps.id_institution IN (i_prof.institution, 0)
                                                   AND pps.id_software IN (i_prof.software, 0)
                                                   AND pps.id_task_type = pk_periodic_observation.g_task_type_hpg
                                                   AND pps.flg_available = pk_alert_constant.g_yes
                                                   AND pps.id_po_param = pop.id_po_param
                                                   AND pps.id_inst_owner = pop.id_inst_owner
                                                   AND phpg.id_patient = l_patient
                                                   AND phpg.id_institution IN
                                                       (SELECT /*+opt_estimate(table t rows=1)*/
                                                         t.column_value id_institution
                                                          FROM TABLE(CAST(pk_list.tf_get_all_inst_group(i_prof.institution,
                                                                                                        pk_adt.g_inst_grp_flg_rel_adt) AS
                                                                          table_number)) t)
                                                   AND phpg.flg_status = 'I'))
                        
                        ) pop
                  LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                              t.*
                               FROM TABLE(CAST(i_med_data AS t_tbl_rec_sum_act_meds)) t) med
                    ON pop.flg_type IN (g_med_local, g_med_ext)
                   AND pop.id_parameter = to_number(med.drug)
                 ORDER BY parameter_flg_create DESC, pop.rank, parameter_desc;
        END IF;
    END get_param_cursor;

    /**
    * Get parameters value for create option.
    *
    * @param flg_type       Parameter Type ('A' - Analysis, 'E' -Exames...)
    * @param i_idParam      Parameter register id
    * @param i_id_parameter Parameter id 
    *
    * @author               Jorge Silva
    * @version               2.5
    * @since                2013/10/08
    */
    FUNCTION get_param_create
    (
        i_prof         IN profissional,
        i_flg_type     IN po_param.flg_type%TYPE,
        i_id_param     IN po_param.id_po_param%TYPE,
        i_id_parameter IN po_param.id_parameter%TYPE
    ) RETURN VARCHAR2 IS
        l_enable_labs sys_config.value%TYPE;
        l_value       VARCHAR2(1);
    
        l_disable_parameter_table table_number := pk_utils.str_split_n(pk_sysconfig.get_config(i_code_cf => g_cfg_disable_parameter,
                                                                                               i_prof    => i_prof),
                                                                       '|');
    BEGIN
    
        l_enable_labs := pk_sysconfig.get_config(i_code_cf => g_cfg_enable_labs, i_prof => i_prof);
    
        IF (pk_utils.search_table_number(l_disable_parameter_table, i_id_param) > 0)
        THEN
            l_value := pk_alert_constant.g_no;
        ELSE
        
            IF i_flg_type = g_analysis
            THEN
                l_value := l_enable_labs;
            
            ELSIF i_flg_type = g_vital_sign
            THEN
                BEGIN
                    SELECT pk_alert_constant.g_no
                      INTO l_value
                      FROM vital_sign_relation vsr
                     WHERE vsr.id_vital_sign_detail = i_id_parameter
                       AND vsr.relation_domain IN (g_vs_rel_sum, g_vs_rel_conc);
                EXCEPTION
                    WHEN no_data_found THEN
                        l_value := pk_alert_constant.g_yes;
                END;
            
            ELSIF i_flg_type = g_habit
                  OR i_flg_type = g_others
                  OR i_flg_type = g_exam
            THEN
                l_value := pk_alert_constant.g_yes;
            ELSE
                l_value := pk_alert_constant.g_no;
            END IF;
        
        END IF;
        RETURN l_value;
    END get_param_create;

    /**
    * Get medication parameters.
    *
    * @param i_params       parameter identifiers
    *
    * @return               medication parameters
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    FUNCTION get_param_med(i_params IN t_coll_po_param) RETURN table_index_varchar IS
        l_ret table_index_varchar;
    
        CURSOR c_param_med IS
            SELECT index_varchar(to_char(pop.id_parameter),
                                 decode(pop.flg_type,
                                        g_med_local,
                                        pk_medication_core.g_int_drug,
                                        g_med_ext,
                                        pk_medication_core.g_ext_drug))
              FROM po_param pop
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.id_po_param, t.id_inst_owner
                      FROM TABLE(i_params) t) t
                ON pop.id_po_param = t.id_po_param
               AND pop.id_inst_owner = t.id_inst_owner
             WHERE pop.flg_type IN (g_med_local, g_med_ext);
    
    BEGIN
    
        OPEN c_param_med;
        FETCH c_param_med BULK COLLECT
            INTO l_ret;
        CLOSE c_param_med;
    
        RETURN l_ret;
    END get_param_med;

    /**
    * Get time cursor.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_values       values collection
    * @param o_time         times
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/16
    */
    PROCEDURE get_time_cursor
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_values           IN t_coll_po_value,
        i_dt_begin         IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_dt_end           IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_tbl_po_param_reg IN table_number DEFAULT NULL,
        o_time             OUT pk_types.cursor_type
    ) IS
        l_aggregate         sys_config.value%TYPE;
        l_dates             table_timestamp_tz := table_timestamp_tz();
        l_extend_values     VARCHAR2(1) := pk_alert_constant.g_no;
        l_current_dt_result VARCHAR2(100);
    BEGIN
        l_aggregate := pk_sysconfig.get_config(i_code_cf => g_cfg_col_aggregate, i_prof => i_prof);
    
        BEGIN
            FOR i IN i_values.first .. i_values.last
            LOOP
                IF i_values(i).flg_status <> 'C'
                THEN
                    l_extend_values := pk_alert_constant.g_yes;
                    EXIT;
                END IF;
            END LOOP;
        EXCEPTION
            WHEN OTHERS THEN
                l_extend_values := pk_alert_constant.g_yes;
        END;
    
        IF l_extend_values = pk_alert_constant.g_yes
        THEN
            IF i_values IS NOT NULL
               AND i_values.count > 0
            THEN
                IF l_aggregate = pk_alert_constant.g_yes
                THEN
                    -- in aggregate mode, show columns created on demand only
                    -- plus the "up to now" column, if needed
                
                    l_dates.extend;
                
                    FOR i IN i_values.first .. i_values.last
                    LOOP
                        IF i_values(i).flg_ref_value = pk_alert_constant.g_no
                        THEN
                            l_dates(1) := nvl(l_dates(1), i_values(i).dt_result_aggr);
                        
                            IF l_dates(1) < i_values(i).dt_result_aggr
                            THEN
                                l_dates(1) := i_values(i).dt_result_aggr;
                            END IF;
                        END IF;
                    END LOOP;
                ELSE
                    -- otherwise, show columns for every result date
                    --l_dates.extend(i_values.count);                
                    FOR i IN i_values.first .. i_values.last
                    LOOP
                        IF i_values(i).flg_ref_value = pk_alert_constant.g_no
                        THEN
                            l_dates.extend(1);
                            l_dates(l_dates.count) := i_values(i).dt_result;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        END IF;
    
        --When on the Communication/Medical orders Flowsheet's screen,
        --it is necessarty to assure that only the most recent column
        --may receive values (flg_editable = Y)
        IF i_tbl_po_param_reg IS NOT NULL
        THEN
            SELECT pk_date_utils.date_send_tsz(i_lang, dt_result, i_prof)
              INTO l_current_dt_result
              FROM po_param_reg ppr
             WHERE ppr.id_po_param_reg = (SELECT MAX(t.column_value)
                                            FROM TABLE(i_tbl_po_param_reg) t);
        END IF;
    
        g_error := 'OPEN o_time';
        OPEN o_time FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, dt_result, i_prof) time_id,
                   pk_date_utils.date_year_tsz(i_lang, dt_result, i_prof.institution, i_prof.software) time_year,
                   pk_date_utils.date_daymonth_tsz(i_lang, dt_result, i_prof.institution, i_prof.software) time_date,
                   CASE
                        WHEN columns_per_day > 1 THEN
                         pk_date_utils.dt_chr_hour_tsz(i_lang, dt_result, i_prof.institution, i_prof.software)
                        ELSE
                         NULL
                    END time_hour,
                   flg_origin time_manual,
                   pk_date_utils.dt_chr_tsz(i_lang, dt_result, i_prof) time_rep,
                   CASE
                        WHEN i_tbl_po_param_reg IS NULL THEN
                         pk_alert_constant.g_yes
                        ELSE
                         CASE --Flag used on the flowsheets' screen from the Communication/Medical orders
                             WHEN l_current_dt_result = pk_date_utils.date_send_tsz(i_lang, dt_result, i_prof) THEN
                              pk_alert_constant.g_yes
                             ELSE
                              pk_alert_constant.g_no
                         END
                    END flg_editable
              FROM (SELECT dt_result, flg_origin, COUNT(*) over(PARTITION BY time_day) columns_per_day
                      FROM (SELECT dt_result,
                                   flg_origin,
                                   (SELECT pk_date_utils.date_yearmonthday_tsz(i_lang,
                                                                               dt_result,
                                                                               i_prof.institution,
                                                                               i_prof.software)
                                      FROM dual) time_day,
                                   row_number() over(PARTITION BY dt_result ORDER BY flg_origin DESC NULLS LAST) rn
                              FROM (SELECT popr.dt_result,
                                           decode(popr.flg_origin, g_orig_manual, g_orig_manual) flg_origin
                                      FROM po_param_reg popr
                                     WHERE popr.id_po_param IS NULL
                                       AND popr.id_patient = i_patient
                                       AND popr.flg_status = pk_alert_constant.g_active
                                       AND popr.id_pat_pregn_fetus IS NULL
                                       AND nvl(popr.flg_screen, g_flg_screen_po) IN (g_flg_screen_po, g_flg_screen_wh)
                                       AND nvl(popr.flg_ref_value, pk_alert_constant.g_no) = pk_alert_constant.g_no
                                       AND (i_dt_begin IS NULL OR popr.dt_result >= i_dt_begin)
                                       AND (i_dt_end IS NULL OR popr.dt_result <= i_dt_end)
                                       AND (i_tbl_po_param_reg IS NULL OR
                                           popr.id_po_param_reg IN
                                           (SELECT /*+opt_estimate(table t rows=1)*/
                                              t.column_value
                                               FROM TABLE(i_tbl_po_param_reg) t))
                                    UNION ALL
                                    SELECT t.column_value dt_result, NULL flg_origin
                                      FROM TABLE(l_dates) t
                                     WHERE t.column_value IS NOT NULL
                                       AND i_tbl_po_param_reg IS NULL))
                     WHERE rn = 1)
             ORDER BY dt_result;
    END get_time_cursor;

    PROCEDURE get_time_cursor_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_values        IN t_coll_po_value,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_ini        IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_fim        IN pat_pregnancy.dt_init_pregnancy%TYPE,
        o_time          OUT pk_types.cursor_type
    ) IS
    
        l_dates table_timestamp_tz := table_timestamp_tz();
    
    BEGIN
    
        IF i_values IS NOT NULL
           AND i_values.count > 0
        THEN
        
            FOR i IN i_values.first .. i_values.last
            LOOP
                IF i_values(i).flg_ref_value = pk_alert_constant.g_no
                THEN
                    l_dates.extend(1);
                    l_dates(l_dates.count) := i_values(i).dt_result;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'OPEN o_time';
        OPEN o_time FOR
            SELECT get_po_param_reg_date(i_lang,
                                         i_prof,
                                         i_patient,
                                         pk_date_utils.date_send_tsz(i_lang, aux3.dt_result, i_prof)) time_id,
                   pk_date_utils.date_year_tsz(i_lang, aux3.dt_result, i_prof.institution, i_prof.software) time_year,
                   pk_date_utils.date_daymonth_tsz(i_lang, aux3.dt_result, i_prof.institution, i_prof.software) time_date,
                   get_pregnancy_week(i_lang, i_prof, i_dt_ini - 1, aux3.dt_result) time_week,
                   aux3.flg_origin time_manual,
                   pk_date_utils.dt_chr_tsz(i_lang, aux3.dt_result, i_prof) time_rep,
                   pk_alert_constant.g_yes flg_editable
              FROM (SELECT aux2.dt_result,
                           aux2.flg_origin,
                           row_number() over(PARTITION BY aux2.time_day ORDER BY aux2.dt_result) columns_per_day
                      FROM (SELECT aux1.dt_result,
                                   aux1.flg_origin,
                                   (SELECT pk_date_utils.date_yearmonthday_tsz(i_lang,
                                                                               aux1.dt_result,
                                                                               i_prof.institution,
                                                                               i_prof.software)
                                      FROM dual) time_day,
                                   row_number() over(PARTITION BY aux1.dt_result ORDER BY aux1.flg_origin DESC NULLS LAST) rn
                              FROM (SELECT popr.dt_result,
                                           decode(popr.flg_origin, g_orig_manual, g_orig_manual) flg_origin
                                      FROM po_param_reg popr
                                     WHERE popr.id_po_param IS NULL
                                       AND popr.id_patient = i_patient
                                       AND popr.flg_status = pk_alert_constant.g_active
                                       AND popr.dt_result BETWEEN i_dt_ini AND i_dt_fim
                                       AND nvl(popr.flg_screen, g_flg_screen_wh) IN (g_flg_screen_wh, g_flg_screen_po)
                                       AND nvl(popr.flg_ref_value, pk_alert_constant.g_no) = pk_alert_constant.g_no
                                    UNION ALL
                                    SELECT t.column_value dt_result, NULL flg_origin
                                      FROM TABLE(l_dates) t
                                     WHERE t.column_value BETWEEN i_dt_ini AND i_dt_fim) aux1) aux2
                     WHERE aux2.rn = 1) aux3
             WHERE aux3.columns_per_day = 1
             ORDER BY aux3.dt_result;
    
    END get_time_cursor_wh;
    /**
    * Get values collection.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_params       parameter identifiers
    * @param i_med_data     medication data
    *
    * @return               values collection
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    FUNCTION get_value_coll
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_params   IN t_coll_po_param,
        i_dt_begin IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_dt_end   IN TIMESTAMP WITH TIME ZONE DEFAULT NULL
    ) RETURN t_coll_po_value IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_VALUE_COLL';
        l_ret            t_coll_po_value;
        l_value_scope    sys_config.value%TYPE;
        l_time_filter_e  po_param_reg.dt_result%TYPE;
        l_time_filter_a  po_param_reg.dt_result%TYPE;
        l_episode        episode.id_episode%TYPE;
        l_insts          table_number;
        l_prev_epis_date episode.dt_end_tstz%TYPE;
        l_dates_aggr     table_timestamp_tz;
        l_dt_max         po_param_reg.dt_result%TYPE := NULL; -- date of the "up to now" column
        l_dt_max_epis    po_param_reg.dt_result%TYPE := NULL; -- max episode date
    
        --****
        l_dt_begin po_param_reg.dt_result%TYPE;
        l_dt_end   po_param_reg.dt_result%TYPE;
        --***********
        PROCEDURE set_dates IS
            l_max_days_back NUMBER;
        BEGIN
        
            l_max_days_back := pk_sysconfig.get_config(i_code_cf => 'PO_MAX_DAYS_BACK', i_prof => i_prof);
            IF l_max_days_back > 0
            THEN
            
                l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
                l_dt_begin := l_dt_end - numtodsinterval(l_max_days_back, 'DAY');
            
                l_dt_end := l_dt_end + numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND');
            
            ELSE
            
                l_dt_begin := i_dt_begin;
                l_dt_end   := i_dt_end;
            
            END IF;
        END set_dates;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_value_scope  := pk_sysconfig.get_config(i_code_cf => g_cfg_value_scope, i_prof => i_prof);
    
        set_dates();
    
        l_time_filter_e  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_e,
                                                                                                  i_prof    => i_prof) * -1);
        l_time_filter_a  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_a,
                                                                                                  i_prof    => i_prof) * -1);
        l_prev_epis_date := get_prev_epis_date(i_prof => i_prof, i_patient => i_patient, i_episode => i_episode);
    
        -- set minimum filter dates
        IF l_prev_epis_date > l_time_filter_e
        THEN
            l_time_filter_e := l_prev_epis_date;
        END IF;
        IF l_prev_epis_date > l_time_filter_a
        THEN
            l_time_filter_a := l_prev_epis_date;
        END IF;
    
        -- set scope filter variables
        IF l_value_scope = g_scope_episode
        THEN
            l_episode := i_episode;
        ELSIF l_value_scope = g_scope_inst
        THEN
            l_insts := table_number(i_prof.institution);
        ELSIF l_value_scope = g_scope_group
        THEN
            l_insts := pk_list.tf_get_all_inst_group(i_institution  => i_prof.institution,
                                                     i_flg_relation => pk_adt.g_inst_grp_flg_rel_adt);
        END IF;
    
        -- get values
        g_error := 'SELECT l_ret';
        SELECT t_rec_po_value(pop.id_po_param,
                              pop.id_inst_owner,
                              v.id_result,
                              v.id_episode,
                              v.id_institution,
                              ei.id_software,
                              v.id_prof_reg,
                              v.dt_result,
                              NULL,
                              v.dt_reg,
                              v.flg_status,
                              v.desc_result,
                              (SELECT nvl(v.desc_unit_measure,
                                          pk_unit_measure.get_unit_measure_description(i_lang, i_prof, v.id_unit_measure))
                                 FROM dual),
                              v.icon,
                              v.lab_param_count,
                              v.lab_param_id,
                              v.lab_param_rank,
                              v.val_min,
                              v.val_max,
                              v.abnorm_value,
                              v.option_codes,
                              v.flg_cancel,
                              v.dt_cancel,
                              v.id_prof_cancel,
                              v.id_cancel_reason,
                              to_clob(v.notes_cancel),
                              NULL,
                              v.flg_ref_value,
                              v.dt_harvest,
                              v.dt_execution,
                              to_clob(v.notes),
                              v.id_sample_type)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT /*+opt_estimate (table vs rows=1)*/
                 *
                  FROM TABLE(get_value_coll_pl(i_lang, i_prof, i_patient))) v
          JOIN po_param pop
            ON v.flg_type = pop.flg_type
           AND v.id_parameter = nvl(pop.id_parameter, pop.id_po_param)
           AND ((v.id_sample_type = pop.id_sample_type AND pop.flg_fill_type = 'A') OR pop.flg_fill_type <> 'A')
          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                 t.id_po_param, t.id_inst_owner
                  FROM TABLE(CAST(i_params AS t_coll_po_param)) t) t
            ON pop.id_po_param = t.id_po_param
           AND pop.id_inst_owner = t.id_inst_owner
          JOIN epis_info ei
            ON v.id_episode = ei.id_episode
         WHERE (v.id_episode = l_episode OR
               v.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      t.column_value id_institution
                                       FROM TABLE(CAST(l_insts AS table_number)) t))
           AND ((pop.flg_type NOT IN (g_exam, g_analysis)) OR --
               (pop.flg_type = g_exam AND v.dt_result > l_time_filter_e) OR --
               (pop.flg_type = g_analysis AND v.dt_result > l_time_filter_a))
              --AND (i_dt_begin IS NULL OR v.dt_result >= i_dt_begin)
              --AND (i_dt_end IS NULL OR v.dt_result <= i_dt_end)
           AND (l_dt_begin IS NULL OR v.dt_result >= l_dt_begin)
           AND (l_dt_end IS NULL OR v.dt_result <= l_dt_end);
    
        -- get maximum result date
        l_dt_max := get_dt_result_max(i_values => l_ret);
    
        -- get episode maximum result date
        l_dt_max_epis := get_dt_result_max(i_values => l_ret, i_episode => i_episode);
    
        -- "move" "up to now" column
        IF l_dt_max_epis IS NOT NULL
        THEN
            UPDATE po_param_reg popr
               SET popr.dt_result = l_dt_max_epis
             WHERE popr.id_po_param IS NULL
               AND popr.id_patient = i_patient
               AND popr.id_episode = i_episode
               AND popr.dt_result < l_dt_max_epis
               AND popr.flg_origin = g_orig_auto
               AND popr.flg_status = pk_alert_constant.g_active
               AND popr.id_pat_pregn_fetus IS NULL
               AND nvl(popr.flg_ref_value, pk_alert_constant.g_no) = pk_alert_constant.g_no;
        
            g_error := SQL%ROWCOUNT || ' column(s) moved...';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        END IF;
    
        -- get aggregated dates
        g_error := 'SELECT l_dates_aggr';
        SELECT popr.dt_result
          BULK COLLECT
          INTO l_dates_aggr
          FROM po_param_reg popr
         WHERE popr.id_po_param IS NULL
           AND popr.id_patient = i_patient
           AND popr.flg_status = pk_alert_constant.g_active
           AND popr.id_pat_pregn_fetus IS NULL
           AND nvl(popr.flg_ref_value, pk_alert_constant.g_no) = pk_alert_constant.g_no
         ORDER BY popr.dt_result;
    
        FOR i IN 1 .. l_ret.count
        LOOP
            -- fill aggregated result date
            FOR j IN 1 .. l_dates_aggr.count
            LOOP
                IF l_ret(i).dt_result <= l_dates_aggr(j)
                THEN
                    l_ret(i).dt_result_aggr := l_dates_aggr(j);
                    EXIT;
                END IF;
            END LOOP;
        
            -- set missing agregated result dates
            IF l_ret(i).dt_result_aggr IS NULL
            THEN
                l_ret(i).dt_result_aggr := l_dt_max;
            END IF;
        END LOOP;
    
        RETURN l_ret;
    END get_value_coll;

    FUNCTION get_value_coll_comm_order
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_params           IN t_coll_po_param,
        i_dt_begin         IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_dt_end           IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_tbl_po_param_reg IN table_number
    ) RETURN t_coll_po_value IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_VALUE_COLL';
        l_ret            t_coll_po_value;
        l_value_scope    sys_config.value%TYPE;
        l_time_filter_e  po_param_reg.dt_result%TYPE;
        l_time_filter_a  po_param_reg.dt_result%TYPE;
        l_episode        episode.id_episode%TYPE;
        l_insts          table_number;
        l_prev_epis_date episode.dt_end_tstz%TYPE;
        l_dates_aggr     table_timestamp_tz;
        l_dt_max         po_param_reg.dt_result%TYPE := NULL; -- date of the "up to now" column
        l_dt_max_epis    po_param_reg.dt_result%TYPE := NULL; -- max episode date
    BEGIN
        g_sysdate_tstz := current_timestamp;
        l_value_scope  := pk_sysconfig.get_config(i_code_cf => g_cfg_value_scope, i_prof => i_prof);
    
        l_time_filter_e  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_e,
                                                                                                  i_prof    => i_prof) * -1);
        l_time_filter_a  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_a,
                                                                                                  i_prof    => i_prof) * -1);
        l_prev_epis_date := get_prev_epis_date(i_prof => i_prof, i_patient => i_patient, i_episode => i_episode);
    
        -- set minimum filter dates
        IF l_prev_epis_date > l_time_filter_e
        THEN
            l_time_filter_e := l_prev_epis_date;
        END IF;
        IF l_prev_epis_date > l_time_filter_a
        THEN
            l_time_filter_a := l_prev_epis_date;
        END IF;
    
        -- set scope filter variables
        IF l_value_scope = g_scope_episode
        THEN
            l_episode := i_episode;
        ELSIF l_value_scope = g_scope_inst
        THEN
            l_insts := table_number(i_prof.institution);
        ELSIF l_value_scope = g_scope_group
        THEN
            l_insts := pk_list.tf_get_all_inst_group(i_institution  => i_prof.institution,
                                                     i_flg_relation => pk_adt.g_inst_grp_flg_rel_adt);
        END IF;
    
        -- get values
        g_error := 'SELECT l_ret';
        SELECT t_rec_po_value(pop.id_po_param,
                              pop.id_inst_owner,
                              v.id_result,
                              v.id_episode,
                              v.id_institution,
                              ei.id_software,
                              v.id_prof_reg,
                              v.dt_result,
                              NULL,
                              v.dt_reg,
                              v.flg_status,
                              v.desc_result,
                              (SELECT nvl(v.desc_unit_measure,
                                          pk_unit_measure.get_unit_measure_description(i_lang, i_prof, v.id_unit_measure))
                                 FROM dual),
                              v.icon,
                              v.lab_param_count,
                              v.lab_param_id,
                              v.lab_param_rank,
                              v.val_min,
                              v.val_max,
                              v.abnorm_value,
                              v.option_codes,
                              v.flg_cancel,
                              v.dt_cancel,
                              v.id_prof_cancel,
                              v.id_cancel_reason,
                              to_clob(v.notes_cancel),
                              NULL,
                              v.flg_ref_value,
                              v.dt_harvest,
                              v.dt_execution,
                              to_clob(v.notes),
                              v.id_sample_type)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT /*+opt_estimate (table vs rows=1)*/
                 *
                  FROM TABLE(get_value_coll_pl(i_lang, i_prof, i_patient))) v
          JOIN po_param pop
            ON v.flg_type = pop.flg_type
           AND v.id_parameter = nvl(pop.id_parameter, pop.id_po_param)
           AND ((v.id_sample_type = pop.id_sample_type AND pop.flg_fill_type = 'A') OR pop.flg_fill_type <> 'A')
          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                 t.id_po_param, t.id_inst_owner
                  FROM TABLE(CAST(i_params AS t_coll_po_param)) t) t
            ON pop.id_po_param = t.id_po_param
           AND pop.id_inst_owner = t.id_inst_owner
          JOIN (SELECT ppr.id_episode, ppr.dt_result
                  FROM po_param_reg ppr
                 WHERE ppr.id_po_param_reg IN (SELECT /*+opt_estimate(table t rows=1)*/
                                                t.column_value
                                                 FROM TABLE(i_tbl_po_param_reg) t)) reg
            ON reg.id_episode = v.id_episode
           AND reg.dt_result = v.dt_result
          JOIN epis_info ei
            ON v.id_episode = ei.id_episode
         WHERE (v.id_episode = l_episode OR
               v.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      t.column_value id_institution
                                       FROM TABLE(CAST(l_insts AS table_number)) t))
           AND ((pop.flg_type NOT IN (g_exam, g_analysis)) OR --
               (pop.flg_type = g_exam AND v.dt_result > l_time_filter_e) OR --
               (pop.flg_type = g_analysis AND v.dt_result > l_time_filter_a))
           AND (i_dt_begin IS NULL OR v.dt_result >= i_dt_begin)
           AND (i_dt_end IS NULL OR v.dt_result <= i_dt_end);
    
        -- get maximum result date
        l_dt_max := get_dt_result_max(i_values => l_ret);
    
        -- get episode maximum result date
        l_dt_max_epis := get_dt_result_max(i_values => l_ret, i_episode => i_episode);
    
        -- "move" "up to now" column
        IF l_dt_max_epis IS NOT NULL
        THEN
            UPDATE po_param_reg popr
               SET popr.dt_result = l_dt_max_epis
             WHERE popr.id_po_param IS NULL
               AND popr.id_patient = i_patient
               AND popr.id_episode = i_episode
               AND popr.dt_result < l_dt_max_epis
               AND popr.flg_origin = g_orig_auto
               AND popr.flg_status = pk_alert_constant.g_active
               AND popr.id_pat_pregn_fetus IS NULL
               AND nvl(popr.flg_ref_value, pk_alert_constant.g_no) = pk_alert_constant.g_no;
        
            g_error := SQL%ROWCOUNT || ' column(s) moved...';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        END IF;
    
        -- get aggregated dates
        g_error := 'SELECT l_dates_aggr';
        SELECT popr.dt_result
          BULK COLLECT
          INTO l_dates_aggr
          FROM po_param_reg popr
         WHERE popr.id_po_param IS NULL
           AND popr.id_patient = i_patient
           AND popr.flg_status = pk_alert_constant.g_active
           AND popr.id_pat_pregn_fetus IS NULL
           AND nvl(popr.flg_ref_value, pk_alert_constant.g_no) = pk_alert_constant.g_no
         ORDER BY popr.dt_result;
    
        FOR i IN 1 .. l_ret.count
        LOOP
            -- fill aggregated result date
            FOR j IN 1 .. l_dates_aggr.count
            LOOP
                IF l_ret(i).dt_result <= l_dates_aggr(j)
                THEN
                    l_ret(i).dt_result_aggr := l_dates_aggr(j);
                    EXIT;
                END IF;
            END LOOP;
        
            -- set missing agregated result dates
            IF l_ret(i).dt_result_aggr IS NULL
            THEN
                l_ret(i).dt_result_aggr := l_dt_max;
            END IF;
        END LOOP;
    
        RETURN l_ret;
    END get_value_coll_comm_order;

    /**
    * Get values cursor.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_values       values collection
    * @param o_value        values
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/15
    */
    FUNCTION get_value_cursor
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_values IN t_coll_po_value
    ) RETURN t_coll_wh_values IS
        l_aggregate       sys_config.value%TYPE;
        l_vs_sort         sys_config.value%TYPE;
        l_lab_result      sys_domain.desc_val%TYPE;
        l_lab_result_icon sys_domain.img_name%TYPE;
        l_ret             t_coll_wh_values;
    BEGIN
        --ALERT-154864 - FALTA    g_arq_status_with_result CONSTANT analysis_req.flg_status%TYPE := 'F'; -- With Results    
        --ALERT-154864 - FALTA    pk_lab_tests_constant.g_arq_status_with_result 
    
        l_aggregate       := pk_sysconfig.get_config(i_code_cf => g_cfg_col_aggregate, i_prof => i_prof);
        l_vs_sort         := pk_sysconfig.get_config(i_code_cf => g_cfg_vs_sort, i_prof => i_prof);
        l_lab_result      := pk_sysdomain.get_domain(i_code_dom => g_ana_req_det_domain, i_val => 'F', i_lang => i_lang);
        l_lab_result_icon := pk_sysdomain.get_img(i_lang => i_lang, i_code_dom => g_ana_req_det_domain, i_val => 'F');
    
        g_error := g_error || '|i_values: ' || i_values.count;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => 'get_value_cursor');
    
        g_error := 'OPEN o_value';
        SELECT t_rec_wh_values(aux.time_id,
                               aux.parameter_id,
                               aux.value_id,
                               aux.value_status,
                               to_clob(aux.value_text),
                               aux.value_units,
                               aux.value_icon,
                               aux.value_flg_cancel,
                               aux.value_abnormal,
                               aux.value_elem_count,
                               aux.value_style,
                               NULL,
                               NULL)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT v.time_id time_id,
                       v.id_po_param parameter_id,
                       v.id_result value_id,
                       v.flg_status value_status,
                       htf.escape_sc(decode(v.option_count,
                                             0,
                                             CASE
                                                 WHEN v.lab_param_count > 1 THEN
                                                  to_clob(l_lab_result)
                                                 ELSE
                                                  v.desc_result
                                             END,
                                             1,
                                             pk_translation.get_translation(i_lang, v.option_code),
                                             get_reg_opt_value(i_lang, v.option_codes))) value_text,
                       htf.escape_sc(v.desc_unit_measure) value_units,
                       CASE
                            WHEN v.lab_param_count > 1 THEN
                             l_lab_result_icon
                            ELSE
                             v.icon
                        END value_icon,
                       v.flg_cancel value_flg_cancel,
                       v.abnorm_value value_abnormal,
                       v.cnt value_elem_count,
                       decode(v.own_soft, 1, g_style_normal, 0, g_style_italic) value_style
                  FROM (SELECT t.*,
                               row_number() over(PARTITION BY t.time_id, t.id_po_param, t.id_inst_owner --
                               ORDER BY t.own_soft DESC, t.dt_vs_sort ASC, t.dt_result_real DESC, t.dt_reg DESC) rn,
                               COUNT(t.id_result) over(PARTITION BY t.lab_param_id, t.time_id, t.id_po_param, t.id_inst_owner, t.own_soft) cnt
                          FROM (SELECT t.id_po_param,
                                       t.id_inst_owner,
                                       t.id_result,
                                       (SELECT decode(t.id_software, i_prof.software, 1, 0)
                                          FROM dual) own_soft, -- result from own software? 1/0
                                       CASE
                                            WHEN t.flg_ref_value = pk_alert_constant.g_yes THEN
                                             g_ref_value
                                            ELSE
                                             pk_date_utils.date_send_tsz(i_lang,
                                                                         decode(l_aggregate,
                                                                                pk_alert_constant.g_yes,
                                                                                t.dt_result_aggr,
                                                                                t.dt_result),
                                                                         i_prof)
                                        END time_id,
                                       (SELECT decode(l_aggregate, pk_alert_constant.g_yes, t.dt_result_aggr, t.dt_result)
                                          FROM dual) dt_result,
                                       CASE
                                            WHEN l_vs_sort = g_vs_sort_asc
                                                 AND (SELECT pop.flg_type
                                                        FROM po_param pop
                                                       WHERE pop.id_po_param = t.id_po_param
                                                         AND pop.id_inst_owner = t.id_inst_owner) = g_vital_sign THEN
                                             t.dt_result
                                        END dt_vs_sort,
                                       t.dt_result dt_result_real,
                                       t.flg_status,
                                       t.desc_result,
                                       t.desc_unit_measure,
                                       t.icon,
                                       t.lab_param_count,
                                       t.get_opt_count() option_count,
                                       t.get_opt_code_first() option_code,
                                       t.option_codes,
                                       t.abnorm_value,
                                       t.flg_cancel,
                                       t.flg_ref_value,
                                       t.dt_reg,
                                       t.lab_param_id
                                  FROM TABLE(CAST(i_values AS t_coll_po_value)) t
                                 WHERE t.flg_status = pk_alert_constant.g_active) t) v
                 WHERE v.rn = 1) aux;
    
        g_error := g_error || '|l_ret: ' || l_ret.count;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => 'get_value_cursor');
    
        RETURN l_ret;
    
    END get_value_cursor;

    /**
    * Cancel parameter for patient.
    *
    * @param i_patient      patient identifier
    * @param i_params       parameter identifiers
    * @param i_owners       owner identifiers
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/22
    */
    PROCEDURE cancel_parameter
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_params        IN table_number,
        i_owners        IN table_number,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2
    ) IS
    BEGIN
        set_parameter_int(i_lang          => i_lang,
                          i_prof          => i_prof,
                          i_patient       => i_patient,
                          i_params        => i_params,
                          i_owners        => i_owners,
                          i_flg_visible   => pk_alert_constant.g_no,
                          i_pat_pregnancy => i_pat_pregnancy,
                          i_owner         => i_owner);
    END cancel_parameter;

    /**
    * Cancels registered values for parameters.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_episode      episode identifier
    * @param i_patient      patient identifier
    * @param i_values       value identifiers
    * @param i_types        parameter types
    * @param i_canc_reason  cancellation reason identifier
    * @param i_canc_notes   cancellation notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5
    * @since                2010/12/23
    */
    FUNCTION cancel_value
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_cat    IN category.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_values      IN table_number,
        i_types       IN table_varchar,
        i_canc_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_canc_notes  IN VARCHAR2,
        i_ref_value   IN VARCHAR2 DEFAULT 'N',
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CANCEL_VALUE';
        l_arp_ids table_number := table_number();
        l_rows    table_varchar;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- debug arguments
        g_error := 'i_values: ' || pk_utils.to_string(i_input => i_values);
        g_error := g_error || '|i_types: ' || pk_utils.to_string(i_input => i_types);
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        -- validate arguments
        IF i_values IS NULL
           OR i_values.count < 1
           OR i_types IS NULL
           OR i_types.count < 1
           OR i_values.count != i_types.count
        THEN
            g_error := 'Invalid arguments!';
            RAISE g_fault;
        END IF;
    
        FOR i IN i_types.first .. i_types.last
        LOOP
            g_error := i || ': cancelling value ' || i_values(i) || ' of type ' || i_types(i);
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        
            -- set parameter specific cancel information
            IF i_types(i) = g_analysis
               AND i_ref_value = pk_alert_constant.g_no
            THEN
                -- get lab test result parameter identifiers
                g_error := 'SELECT l_arp_ids';
                SELECT arp.id_analysis_result_par
                  BULK COLLECT
                  INTO l_arp_ids
                  FROM analysis_result_par arp
                 WHERE arp.id_analysis_result = i_values(i);
            
                g_error := 'l_arp_ids: ' || pk_utils.to_string(i_input => l_arp_ids);
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            
                -- cancel all lab test result parameters
                FOR j IN 1 .. l_arp_ids.count
                LOOP
                    g_error := j || ': cancelling parameter ' || l_arp_ids(j);
                    pk_alertlog.log_debug(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
                
                    g_error := 'CALL PK_LAB_TESTS_API_DB.CANCEL_LAB_TEST_RESULT';
                    IF NOT pk_lab_tests_api_db.cancel_lab_test_result(i_lang                => i_lang,
                                                                      i_prof                => i_prof,
                                                                      i_analysis_result_par => l_arp_ids(j),
                                                                      i_cancel_reason       => i_canc_reason,
                                                                      i_notes_cancel        => i_canc_notes,
                                                                      o_error               => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END LOOP;
            
            ELSIF i_types(i) = g_vital_sign
            THEN
                IF i_ref_value = pk_alert_constant.g_no
                THEN
                    -- cancel vital sign read
                    g_error := 'CALL pk_clinical_info.cancel_epis_vs_read';
                    RAISE g_exception;
                    /*ALERT-154864                    
                                        IF NOT pk_clinical_info.cancel_epis_vs_read(i_lang    => i_lang,
                                                                                    i_episode => i_episode,
                                                                                    i_vs      => i_values(i),
                                                                                    i_prof    => i_prof,
                                                                                    o_error   => o_error)
                                        THEN
                                            RAISE g_exception;
                                        END IF;
                    */
                ELSE
                    g_error := 'call ts_event_most_freq.upd';
                
                    ts_event_most_freq.upd(id_event_most_freq_in => i_values(i),
                                           dt_cancel_in          => g_sysdate_tstz,
                                           id_prof_cancel_in     => i_prof.id,
                                           flg_status_in         => pk_alert_constant.g_cancelled,
                                           rows_out              => l_rows);
                
                    g_error := 'call t_data_gov_mnt.process_update';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'EVENT_MOST_FREQ',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                END IF;
            
            ELSIF i_types(i) = g_others
            THEN
                g_error := 'CALL ts_po_param_reg.upd';
                ts_po_param_reg.upd(id_po_param_reg_in   => i_values(i),
                                    flg_status_in        => pk_alert_constant.g_cancelled,
                                    flg_status_nin       => FALSE,
                                    id_cancel_reason_in  => i_canc_reason,
                                    id_cancel_reason_nin => FALSE,
                                    dt_cancel_in         => g_sysdate_tstz,
                                    dt_cancel_nin        => FALSE,
                                    id_prof_cancel_in    => i_prof.id,
                                    id_prof_cancel_nin   => FALSE,
                                    notes_cancel_in      => to_clob(i_canc_notes),
                                    notes_cancel_nin     => FALSE,
                                    rows_out             => l_rows);
                g_error := 'CALL t_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'PO_PARAM_REG',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS',
                                                                              'ID_CANCEL_REASON',
                                                                              'DT_CANCEL',
                                                                              'ID_PROF_CANCEL',
                                                                              'NOTES_CANCEL'));
            ELSE
                -- unsupported parameter type
                g_error := 'Unsupported parameter type (' || nvl(i_types(i), 'NULL') || ')!';
                RAISE g_fault;
            END IF;
        END LOOP;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_value;

    /**
    * Create periodic observation column.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_dt           column date
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/14
    */
    PROCEDURE create_column
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt      IN VARCHAR2,
        o_error   OUT t_error_out
    ) IS
        l_dt_result po_param_reg.dt_result%TYPE;
        l_popr      po_param_reg.id_po_param_reg%TYPE;
        l_rows      table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        l_dt_result    := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt,
                                                        i_timezone  => NULL);
    
        g_error := 'CALL ts_po_param_reg.ins';
        ts_po_param_reg.ins(id_patient_in       => i_patient,
                            id_episode_in       => i_episode,
                            dt_creation_in      => g_sysdate_tstz,
                            dt_result_in        => l_dt_result,
                            flg_origin_in       => g_orig_manual,
                            id_professional_in  => i_prof.id,
                            flg_status_in       => pk_alert_constant.g_active,
                            id_po_param_reg_out => l_popr,
                            flg_screen_in       => g_flg_screen_po,
                            flg_ref_value_in    => pk_alert_constant.g_no,
                            rows_out            => l_rows);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PO_PARAM_REG',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'create_column',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END create_column;

    FUNCTION cancel_column
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_po_param_reg IN po_param_reg.id_po_param_reg%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows table_varchar;
    BEGIN
    
        g_error := 'CALL ts_po_param_reg.del';
        --ts_po_param_reg.del(id_po_param_reg_in => i_id_po_param_reg, handle_error_in => FALSE);
        DELETE FROM po_param_reg ppr
         WHERE ppr.id_po_param_reg = i_id_po_param_reg;
    
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PO_PARAM_REG',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'cancel_column',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_column;

    PROCEDURE create_column_comm_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        o_id_po_param_reg OUT po_param_reg.id_po_param_reg%TYPE,
        o_error           OUT t_error_out
    ) IS
        l_dt_result po_param_reg.dt_result%TYPE;
        l_rows      table_varchar;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        l_dt_result    := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt,
                                                        i_timezone  => NULL);
    
        l_dt_result := pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => l_dt_result, i_format => 'MI');
    
        g_error := 'CALL ts_po_param_reg.ins';
        ts_po_param_reg.ins(id_patient_in       => i_patient,
                            id_episode_in       => i_episode,
                            dt_creation_in      => g_sysdate_tstz,
                            dt_result_in        => l_dt_result,
                            flg_origin_in       => g_orig_manual,
                            id_professional_in  => i_prof.id,
                            flg_status_in       => pk_alert_constant.g_active,
                            id_po_param_reg_out => o_id_po_param_reg,
                            flg_screen_in       => g_flg_screen_po,
                            flg_ref_value_in    => pk_alert_constant.g_no,
                            rows_out            => l_rows);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PO_PARAM_REG',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'create_column_comm_order',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
    END create_column_comm_order;
    /**
    * Create periodic observation column.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_dt           column date
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/14
    */
    FUNCTION create_column
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        i_pat_pregnancy   IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_show_warning    OUT VARCHAR2,
        o_title_warning   OUT VARCHAR2,
        o_message_warning OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_result po_param_reg.dt_result%TYPE;
        l_popr      po_param_reg.id_po_param_reg%TYPE;
        l_dt_ini    pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_fim    pat_pregnancy.dt_init_pregnancy%TYPE;
    
        l_time_id       VARCHAR2(50 CHAR);
        l_time_year     VARCHAR2(50 CHAR);
        l_time_date     VARCHAR2(50 CHAR);
        l_time_week     VARCHAR2(50 CHAR);
        l_time_manual   VARCHAR2(50 CHAR);
        l_time_rep      VARCHAR2(50 CHAR);
        l_flg_edit      VARCHAR2(1 CHAR);
        l_dup_date      EXCEPTION;
        l_interval_date EXCEPTION;
    
        o_wh        pk_types.cursor_type;
        o_param     pk_types.cursor_type;
        o_wh_param  pk_types.cursor_type;
        o_time      pk_types.cursor_type;
        o_value_aux pk_types.cursor_type;
        o_ref       pk_types.cursor_type;
        o_values_wh t_coll_wh_values;
    
        l_rows table_varchar;
    
    BEGIN
    
        o_show_warning := pk_alert_constant.g_no;
    
        g_error := 'CALL GET_PREGN_INTERVAL_DATES';
        IF NOT get_pregn_interval_dates(i_pat_pregnancy => i_pat_pregnancy, o_dt_ini => l_dt_ini, o_dt_fim => l_dt_fim)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL GET_GRID_WH';
        IF NOT get_grid_wh(i_lang          => i_lang,
                           i_prof          => i_prof,
                           i_patient       => i_patient,
                           i_episode       => i_episode,
                           i_pat_pregnancy => i_pat_pregnancy,
                           i_cursor_out    => 'T',
                           o_wh            => o_wh,
                           o_param         => o_param,
                           o_wh_param      => o_wh_param,
                           o_time          => o_time,
                           o_value         => o_value_aux,
                           o_values_wh     => o_values_wh,
                           o_ref           => o_ref,
                           o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH O_TIME';
        LOOP
            FETCH o_time
                INTO l_time_id, l_time_year, l_time_date, l_time_week, l_time_manual, l_time_rep, l_flg_edit;
            EXIT WHEN o_time%NOTFOUND;
            IF substr(l_time_id, 1, 8) = substr(i_dt, 1, 8)
            THEN
                RAISE l_dup_date;
            END IF;
        END LOOP;
        CLOSE o_time;
    
        g_sysdate_tstz := current_timestamp;
        l_dt_result    := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt,
                                                        i_timezone  => NULL);
    
        IF l_dt_result < l_dt_ini
        THEN
            RAISE l_interval_date;
        END IF;
    
        g_error := 'INSERT INTO PO_PARAM_REG';
        ts_po_param_reg.ins(id_patient_in       => i_patient,
                            id_episode_in       => i_episode,
                            dt_creation_in      => g_sysdate_tstz,
                            dt_result_in        => l_dt_result,
                            flg_origin_in       => g_orig_manual,
                            id_professional_in  => i_prof.id,
                            flg_status_in       => pk_alert_constant.g_active,
                            id_po_param_reg_out => l_popr,
                            flg_screen_in       => g_flg_screen_wh,
                            flg_ref_value_in    => pk_alert_constant.g_no,
                            rows_out            => l_rows);
    
        g_error := 'CALL PROCESS_INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PO_PARAM_REG',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_dup_date THEN
            o_show_warning    := pk_alert_constant.g_yes;
            o_message_warning := pk_message.get_message(i_lang, i_prof, 'PREGNANCY_PO_T001');
            o_title_warning   := pk_message.get_message(i_lang, i_prof, 'PREGNANCY_PO_T003');
            RETURN TRUE;
        WHEN l_interval_date THEN
            o_show_warning    := pk_alert_constant.g_yes;
            o_message_warning := pk_message.get_message(i_lang, i_prof, 'PREGNANCY_PO_T002');
            o_title_warning   := pk_message.get_message(i_lang, i_prof, 'PREGNANCY_PO_T003');
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'create_column',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END create_column;

    /* Não sei se é preciso isto .. ou usar a create_column normal */
    FUNCTION create_column_comm_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_dt              IN VARCHAR2,
        i_task_type       IN task_type.id_task_type%TYPE,
        i_id_concept      IN comm_order_ea.id_concept%TYPE,
        o_show_warning    OUT VARCHAR2,
        o_title_warning   OUT VARCHAR2,
        o_message_warning OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_result     po_param_reg.dt_result%TYPE;
        l_popr          po_param_reg.id_po_param_reg%TYPE;
        l_rows          table_varchar;
        l_time_id       VARCHAR2(50 CHAR);
        l_time_year     VARCHAR2(50 CHAR);
        l_time_date     VARCHAR2(50 CHAR);
        l_time_week     VARCHAR2(50 CHAR);
        l_time_manual   VARCHAR2(50 CHAR);
        l_time_rep      VARCHAR2(50 CHAR);
        l_dup_date      EXCEPTION;
        l_interval_date EXCEPTION;
        l_title         VARCHAR2(300 CHAR);
        l_sets          pk_types.cursor_type;
        l_param         pk_types.cursor_type;
        l_sets_param    pk_types.cursor_type;
        l_time          pk_types.cursor_type;
        l_value_aux     pk_types.cursor_type;
        l_ref           pk_types.cursor_type;
        l_values_wh     t_coll_wh_values;
    BEGIN
        o_show_warning := pk_alert_constant.g_no;
    
        /* g_error := 'CALL get_grid_wh';
        IF NOT get_grid_comm_order(i_lang          => i_lang,
                           i_prof          => i_prof,
                           i_patient       => i_patient,
                           i_episode       => i_episode,
                           i_task_type     => i_task_type,
                           i_id_concept    => i_id_concept,
                           o_title    => l_title,
                           o_sets            => l_sets,
                           o_param         => l_param,
                           o_sets_param      => l_sets_param,
                           o_time          => l_time,
                           o_value         => l_value_aux,
                           o_values_wh     => l_values_wh,
                           o_ref           => l_ref,
                           o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        
        LOOP
            FETCH l_time
                INTO l_time_id, l_time_year, l_time_date, l_time_week, l_time_manual, l_time_rep;
            EXIT WHEN o_time%NOTFOUND;
            IF substr(l_time_id, 1, 8) = substr(i_dt, 1, 8)
            THEN
                RAISE l_dup_date;
            END IF;
        END LOOP;
        CLOSE o_time;*/
    
        g_sysdate_tstz := current_timestamp;
        l_dt_result    := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt,
                                                        i_timezone  => NULL);
    
        g_error := 'CALL ts_po_param_reg.ins';
        ts_po_param_reg.ins(id_patient_in       => i_patient,
                            id_episode_in       => i_episode,
                            dt_creation_in      => g_sysdate_tstz,
                            dt_result_in        => l_dt_result,
                            flg_origin_in       => g_orig_manual,
                            id_professional_in  => i_prof.id,
                            flg_status_in       => pk_alert_constant.g_active,
                            id_po_param_reg_out => l_popr,
                            flg_screen_in       => g_flg_screen_po,
                            flg_ref_value_in    => pk_alert_constant.g_no,
                            rows_out            => l_rows);
        g_error := 'CALL t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PO_PARAM_REG',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_COLUMN_COMM_ORDER',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END create_column_comm_order;

    /**
    * Create automatic periodic observation column (to use on episode creation only).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/13
    */
    PROCEDURE create_column_auto
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) IS
        l_create     sys_config.value%TYPE;
        l_count      PLS_INTEGER;
        l_popr       po_param_reg.id_po_param_reg%TYPE;
        l_rows       table_varchar;
        l_begin_date TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        l_create     := pk_sysconfig.get_config(i_code_cf => g_cfg_col_create, i_prof => i_prof);
        l_begin_date := NULL;
    
        IF l_create = pk_alert_constant.g_yes
        THEN
            g_error := 'SELECT l_count';
            SELECT COUNT(*)
              INTO l_count
              FROM po_param_reg popr
             WHERE popr.id_po_param IS NULL
               AND popr.id_patient = i_patient
               AND popr.id_episode = i_episode
               AND popr.flg_origin = g_orig_auto
               AND popr.flg_status = pk_alert_constant.g_active
               AND popr.id_pat_pregn_fetus IS NULL
               AND nvl(popr.flg_ref_value, pk_alert_constant.g_no) = pk_alert_constant.g_no;
        
            IF (pk_hand_off_core.is_ambulatory_product(i_software => i_prof.software) = 1)
            THEN
                SELECT ei.dt_init
                  INTO l_begin_date
                  FROM epis_info ei
                 WHERE ei.id_episode = i_episode;
            ELSE
                SELECT e.dt_begin_tstz
                  INTO l_begin_date
                  FROM episode e
                 WHERE e.id_episode = i_episode;
            END IF;
        
            IF (l_count = 0 AND l_begin_date IS NOT NULL)
            THEN
                -- g_sysdate_tstz := l_begin_date;
            
                g_error := 'CALL ts_po_param_reg.ins';
                ts_po_param_reg.ins(id_patient_in       => i_patient,
                                    id_episode_in       => i_episode,
                                    dt_creation_in      => l_begin_date,
                                    dt_result_in        => l_begin_date,
                                    flg_origin_in       => g_orig_auto,
                                    id_professional_in  => i_prof.id,
                                    flg_status_in       => pk_alert_constant.g_active,
                                    id_po_param_reg_out => l_popr,
                                    flg_ref_value_in    => pk_alert_constant.g_no,
                                    rows_out            => l_rows);
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PO_PARAM_REG',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            END IF;
        END IF;
    END create_column_auto;

    /**
    * Get actions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_actions      actions
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/12/13
    */
    FUNCTION get_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_subject CONSTANT action.subject%TYPE := 'PER_OBS_ACTION';
    BEGIN
        RETURN pk_action.get_actions(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_subject    => l_subject,
                                     i_from_state => NULL,
                                     o_actions    => o_actions,
                                     o_error      => o_error);
    END get_actions;

    /**
    * Get "create" button options.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_create       create options
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/13
    */
    FUNCTION get_create
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_create        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_subject action.subject%TYPE := 'PER_OBS_WH_CREATE';
    BEGIN
    
        IF i_pat_pregnancy IS NULL
        THEN
            l_subject := 'PER_OBS_CREATE';
        ELSE
            l_subject := 'PER_OBS_WH_CREATE';
        END IF;
    
        RETURN pk_action.get_actions(i_lang       => i_lang,
                                     i_prof       => i_prof,
                                     i_subject    => l_subject,
                                     i_from_state => NULL,
                                     o_actions    => o_create,
                                     o_error      => o_error);
    END get_create;

    /**
    * Get detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_date         date to get results from
    * @param o_detail       detail
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_date      IN VARCHAR2,
        i_task_type IN VARCHAR2,
        o_detail    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DETAIL';
        l_cr_code   CONSTANT translation.code_translation%TYPE := 'CANCEL_REASON.CODE_CANCEL_REASON.';
        l_dcs       epis_info.id_dep_clin_serv%TYPE;
        l_aggregate sys_config.value%TYPE;
        l_ref_vals  sys_config.value%TYPE;
        l_canceled  sys_message.desc_message%TYPE;
        l_sets_coll t_coll_sets;
        l_params    t_coll_po_param;
        l_med_data  t_tbl_rec_sum_act_meds;
        l_values    t_coll_po_value;
        l_task_type table_varchar2 := table_varchar2();
        l_ret       t_coll_sets := t_coll_sets();
    
    BEGIN
    
        l_dcs       := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        l_aggregate := pk_sysconfig.get_config(i_code_cf => g_cfg_col_aggregate, i_prof => i_prof);
        l_ref_vals  := pk_sysconfig.get_config(i_code_cf => g_cfg_show_ref_vals, i_prof => i_prof);
        l_canceled  := pk_message.get_message(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_code_mess => 'PERIODIC_OBSERVATION_T063');
    
        -- get health program related data
        g_error := 'CALL pk_health_program.get_pat_hpgs_cursor';
    
        IF i_task_type IS NOT NULL
        THEN
        
            l_task_type := pk_utils.str_split(i_task_type, '|');
        
            IF l_task_type.count > 0
            THEN
                FOR i IN 1 .. l_task_type.count
                LOOP
                    g_error     := 'CALL get_sets_coll';
                    l_sets_coll := get_sets_coll(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_patient   => i_patient,
                                                 i_episode   => i_episode,
                                                 i_task_type => l_task_type);
                END LOOP;
            
            END IF;
            SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
              BULK COLLECT
              INTO l_ret
              FROM (SELECT t.*
                      FROM TABLE(l_sets_coll) t);
        
        END IF;
    
        -- get parameter related data
        l_params := get_param(i_prof => i_prof, i_patient => i_patient, i_episode => i_episode);
    
        -- get value related data
        l_values := get_value_coll(i_lang    => i_lang,
                                   i_prof    => i_prof,
                                   i_patient => i_patient,
                                   i_episode => i_episode,
                                   i_params  => l_params);
    
        g_error := 'OPEN o_detail';
    
        OPEN o_detail FOR
            SELECT parameter_id,
                   parameter_flg_type,
                   parameter_desc,
                   parameter_sub_desc,
                   parameter_health_programs,
                   value_id,
                   value_status,
                   value_cancel_label,
                   value_text,
                   value_units,
                   value_dt_result,
                   value_signature,
                   value_min,
                   value_max,
                   value_cancel_signature,
                   value_cancel_reason,
                   value_cancel_notes,
                   value_elem_count,
                   value_reg_count,
                   parameter_active_value_count,
                   value_dt_harvest,
                   value_dt_execution,
                   value_notes,
                   value_abnormal
              FROM (SELECT v.id_po_param parameter_id,
                           pop.flg_type parameter_flg_type,
                           (SELECT get_param_desc(i_lang,
                                                  i_prof,
                                                  pop.id_po_param,
                                                  pop.id_inst_owner,
                                                  pop.flg_type,
                                                  pop.id_parameter,
                                                  l_dcs)
                              FROM dual) parameter_desc,
                           CASE
                                WHEN v.lab_param_count > 1 THEN
                                 (SELECT pk_translation.get_translation(i_lang,
                                                                        'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                        v.lab_param_id)
                                    FROM dual)
                                ELSE
                                 NULL
                            END parameter_sub_desc,
                           (SELECT get_param_sets(i_lang, i_prof, pop.id_po_param, pop.id_inst_owner, l_ret, l_task_type)
                              FROM dual) parameter_health_programs,
                           v.id_result value_id,
                           v.flg_status value_status,
                           decode(v.flg_status, pk_alert_constant.g_cancelled, l_canceled) value_cancel_label,
                           (SELECT to_clob(decode(v.option_count,
                                                  0,
                                                  v.desc_result,
                                                  1,
                                                  htf.escape_sc(pk_translation.get_translation(i_lang, v.option_code)),
                                                  htf.escape_sc(get_reg_opt_value(i_lang, v.option_codes))))
                              FROM dual) value_text,
                           htf.escape_sc(v.desc_unit_measure) value_units,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, v.dt_result_real, i_prof) value_dt_result,
                           (SELECT get_signature(i_lang, i_prof, v.id_prof_reg, v.dt_reg, v.id_episode, v.id_institution)
                              FROM dual) value_signature,
                           decode(l_ref_vals, pk_alert_constant.g_yes, v.val_min) value_min,
                           decode(l_ref_vals, pk_alert_constant.g_yes, v.val_max) value_max,
                           (SELECT get_signature(i_lang,
                                                 i_prof,
                                                 v.id_prof_cancel,
                                                 v.dt_cancel,
                                                 v.id_episode,
                                                 v.id_institution,
                                                 'C')
                              FROM dual) value_cancel_signature,
                           (SELECT nvl2(v.id_cancel_reason,
                                        pk_translation.get_translation(i_lang, l_cr_code || v.id_cancel_reason),
                                        NULL)
                              FROM dual) value_cancel_reason,
                           v.notes_cancel value_cancel_notes,
                           COUNT(DISTINCT v.id_result) over(PARTITION BY v.id_po_param, v.id_inst_owner) value_elem_count,
                           COUNT(*) over(PARTITION BY v.id_po_param, v.id_inst_owner, v.id_result) value_reg_count,
                           COUNT(DISTINCT v.id_result) over(PARTITION BY v.id_po_param, v.id_inst_owner, v.flg_status) parameter_active_value_count,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, v.dt_harvest, i_prof) value_dt_harvest,
                           pk_date_utils.dt_chr_date_hour_tsz(i_lang, v.dt_execution, i_prof) value_dt_execution,
                           v.notes value_notes,
                           abnorm_value value_abnormal
                      FROM (SELECT /*+opt_estimate(table t rows=1)*/
                             t.id_po_param,
                             t.id_inst_owner,
                             t.id_result,
                             t.id_episode,
                             t.id_institution,
                             t.id_software,
                             t.id_prof_reg,
                             t.dt_result dt_result_real,
                             t.dt_reg,
                             t.flg_status,
                             t.desc_result,
                             t.desc_unit_measure,
                             t.lab_param_count,
                             t.lab_param_id,
                             t.lab_param_rank,
                             t.abnorm_value,
                             t.val_min,
                             t.val_max,
                             t.option_codes,
                             t.flg_cancel,
                             t.dt_cancel,
                             t.id_prof_cancel,
                             t.id_cancel_reason,
                             t.notes_cancel notes_cancel,
                             (SELECT pk_date_utils.date_send_tsz(i_lang,
                                                                 decode(l_aggregate,
                                                                        pk_alert_constant.g_yes,
                                                                        t.dt_result_aggr,
                                                                        t.dt_result),
                                                                 i_prof)
                                FROM dual) dt_result,
                             substr(pk_date_utils.date_send_tsz(i_lang, t.dt_reg, i_prof), 1, 12) dt_register,
                             t.get_opt_count() option_count,
                             t.get_opt_code_first() option_code,
                             t.flg_ref_value,
                             t.dt_harvest,
                             t.dt_execution,
                             --ALERT-154864                             
                             t.notes notes
                              FROM TABLE(CAST(l_values AS t_coll_po_value)) t) v
                      JOIN po_param pop
                        ON v.id_po_param = pop.id_po_param
                       AND v.id_inst_owner = pop.id_inst_owner
                      LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 t.*
                                  FROM TABLE(CAST(l_med_data AS t_tbl_rec_sum_act_meds)) t) med
                        ON pop.flg_type IN (g_med_local, g_med_ext)
                       AND pop.id_parameter = to_number(med.drug)
                     WHERE ((v.flg_ref_value = pk_alert_constant.g_no AND v.dt_result = i_date) OR
                           (v.flg_ref_value = pk_alert_constant.g_yes AND i_date = g_ref_value))
                     ORDER BY get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank),
                              parameter_desc,
                              v.flg_status,
                              dt_result DESC,
                              dt_register DESC,
                              parameter_sub_desc,
                              v.lab_param_rank)
             WHERE (parameter_health_programs IS NOT NULL AND i_task_type IS NOT NULL)
                OR i_task_type IS NULL;
    
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_detail;

    FUNCTION get_detail_comm_order
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        i_po_param_reg    IN po_param_reg.id_po_param_reg%TYPE,
        o_parameter_desc  OUT table_varchar,
        o_parameter_value OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DETAIL_COMM_ORDER';
        l_cr_code   CONSTANT translation.code_translation%TYPE := 'CANCEL_REASON.CODE_CANCEL_REASON.';
        l_dcs               epis_info.id_dep_clin_serv%TYPE;
        l_aggregate         sys_config.value%TYPE;
        l_ref_vals          sys_config.value%TYPE;
        l_canceled          sys_message.desc_message%TYPE;
        l_sets_coll         t_coll_sets;
        l_params            t_coll_po_param;
        l_med_data          t_tbl_rec_sum_act_meds;
        l_values            t_coll_po_value;
        l_task_type         task_type.id_task_type%TYPE;
        l_task_type_content po_param_sets.task_type_content%TYPE;
        l_ret               t_coll_sets := t_coll_sets();
        l_patient           patient.id_patient%TYPE;
        l_episode           episode.id_episode%TYPE;
    
    BEGIN
    
        SELECT cor.id_patient, cor.id_episode
          INTO l_patient, l_episode
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_comm_order_req;
    
        l_dcs       := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => l_episode);
        l_aggregate := pk_sysconfig.get_config(i_code_cf => g_cfg_col_aggregate, i_prof => i_prof);
        l_ref_vals  := pk_sysconfig.get_config(i_code_cf => g_cfg_show_ref_vals, i_prof => i_prof);
        l_canceled  := pk_message.get_message(i_lang      => i_lang,
                                              i_prof      => i_prof,
                                              i_code_mess => 'PERIODIC_OBSERVATION_T063');
    
        SELECT cor.id_task_type, coe.concept_code
          INTO l_task_type, l_task_type_content
          FROM comm_order_req cor
          JOIN comm_order_ea coe
            ON cor.id_concept_version = coe.id_concept_version
           AND cor.id_cncpt_vrs_inst_owner = coe.id_cncpt_vrs_inst_owner
           AND cor.id_concept_term = coe.id_concept_term
           AND cor.id_cncpt_trm_inst_owner = coe.id_cncpt_trm_inst_owner
           AND cor.id_concept_type = coe.id_concept_type
           AND cor.id_task_type = coe.id_task_type_conc_term
           AND coe.id_software_conc_term = i_prof.software
           AND coe.id_institution_conc_term = i_prof.institution
         WHERE cor.id_comm_order_req = i_comm_order_req;
    
        g_error     := 'CALL get_sets_coll';
        l_sets_coll := get_sets_coll(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_patient   => l_patient,
                                     i_episode   => l_episode,
                                     i_task_type => table_varchar2(l_task_type),
                                     i_value     => l_task_type_content);
    
        SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.*
                  FROM TABLE(l_sets_coll) t);
    
        SELECT DISTINCT t_rec_po_param(id_po_param, id_inst_owner)
          BULK COLLECT
          INTO l_params
          FROM (SELECT pps.id_po_param, pps.id_inst_owner
                  FROM po_param_sets pps
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        t.sets_id sets_id
                         FROM TABLE(l_ret) t) s
                    ON pps.task_type_content = s.sets_id
                  JOIN po_param pop
                    ON pps.id_po_param = pop.id_po_param
                   AND pps.id_inst_owner = pop.id_inst_owner
                 WHERE pps.id_institution IN (i_prof.institution, 0)
                   AND pps.id_software IN (i_prof.software, 0)
                   AND pps.id_task_type = l_task_type
                   AND pps.flg_available = pk_alert_constant.g_yes
                   AND pop.flg_available = pk_alert_constant.g_yes
                MINUS
                SELECT patpop.id_po_param, patpop.id_inst_owner
                  FROM pat_po_param patpop
                 WHERE patpop.id_patient = l_patient
                   AND patpop.flg_visible = pk_alert_constant.g_no);
    
        --Obtaining registered values
        g_error  := 'Obtaining registered values';
        l_values := get_value_coll_comm_order(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_patient          => l_patient,
                                              i_episode          => l_episode,
                                              i_params           => l_params,
                                              i_tbl_po_param_reg => table_number(i_po_param_reg));
    
        g_error := 'OPEN o_detail';
        SELECT parameter_desc, --,
               value_text || ' ' || value_units
          BULK COLLECT
          INTO o_parameter_desc, o_parameter_value
          FROM (SELECT (SELECT get_param_desc(i_lang,
                                              i_prof,
                                              pop.id_po_param,
                                              pop.id_inst_owner,
                                              pop.flg_type,
                                              pop.id_parameter,
                                              l_dcs)
                          FROM dual) parameter_desc,
                       v.id_result value_id,
                       v.flg_status value_status,
                       (SELECT to_clob(decode(v.option_count,
                                              0,
                                              v.desc_result,
                                              1,
                                              htf.escape_sc(pk_translation.get_translation(i_lang, v.option_code)),
                                              htf.escape_sc(get_reg_opt_value(i_lang, v.option_codes))))
                          FROM dual) value_text,
                       htf.escape_sc(v.desc_unit_measure) value_units,
                       v.notes value_notes
                  FROM (SELECT /*+opt_estimate(table t rows=1)*/
                         t.id_po_param,
                         t.id_inst_owner,
                         t.id_result,
                         t.id_episode,
                         t.id_institution,
                         t.id_software,
                         t.id_prof_reg,
                         t.dt_result dt_result_real,
                         t.dt_reg,
                         t.flg_status,
                         t.desc_result,
                         t.desc_unit_measure,
                         t.lab_param_count,
                         t.lab_param_id,
                         t.lab_param_rank,
                         t.abnorm_value,
                         t.val_min,
                         t.val_max,
                         t.option_codes,
                         t.flg_cancel,
                         t.dt_cancel,
                         t.id_prof_cancel,
                         t.id_cancel_reason,
                         t.notes_cancel notes_cancel,
                         (SELECT pk_date_utils.date_send_tsz(i_lang,
                                                             decode(l_aggregate,
                                                                    pk_alert_constant.g_yes,
                                                                    t.dt_result_aggr,
                                                                    t.dt_result),
                                                             i_prof)
                            FROM dual) dt_result,
                         substr(pk_date_utils.date_send_tsz(i_lang, t.dt_reg, i_prof), 1, 12) dt_register,
                         t.get_opt_count() option_count,
                         t.get_opt_code_first() option_code,
                         t.flg_ref_value,
                         t.dt_harvest,
                         t.dt_execution,
                         --ALERT-154864                             
                         t.notes notes
                          FROM TABLE(CAST(l_values AS t_coll_po_value)) t) v
                  JOIN po_param pop
                    ON v.id_po_param = pop.id_po_param
                   AND v.id_inst_owner = pop.id_inst_owner
                 ORDER BY get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank),
                          parameter_desc,
                          v.flg_status,
                          v.dt_result DESC,
                          dt_register DESC,
                          --parameter_sub_desc,
                          v.lab_param_rank);
    
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_detail_comm_order;

    FUNCTION get_count_comm_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_po_param_reg   IN po_param_reg.id_po_param_reg%TYPE,
        o_error          OUT t_error_out
    ) RETURN NUMBER IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_COUNT_COMM_ORDER';
        l_sets_coll         t_coll_sets;
        l_params            t_coll_po_param;
        l_values            t_coll_po_value;
        l_task_type         task_type.id_task_type%TYPE;
        l_task_type_content po_param_sets.task_type_content%TYPE;
        l_ret               t_coll_sets := t_coll_sets();
        l_patient           patient.id_patient%TYPE;
        l_episode           episode.id_episode%TYPE;
    
        l_count NUMBER := 0;
    BEGIN
    
        SELECT cor.id_patient, cor.id_episode
          INTO l_patient, l_episode
          FROM comm_order_req cor
         WHERE cor.id_comm_order_req = i_comm_order_req;
    
        SELECT cor.id_task_type, coe.concept_code
          INTO l_task_type, l_task_type_content
          FROM comm_order_req cor
          JOIN comm_order_ea coe
            ON cor.id_concept_version = coe.id_concept_version
           AND cor.id_cncpt_vrs_inst_owner = coe.id_cncpt_vrs_inst_owner
           AND cor.id_concept_term = coe.id_concept_term
           AND cor.id_cncpt_trm_inst_owner = coe.id_cncpt_trm_inst_owner
           AND cor.id_concept_type = coe.id_concept_type
           AND cor.id_task_type = coe.id_task_type_conc_term
           AND coe.id_software_conc_term = i_prof.software
           AND coe.id_institution_conc_term = i_prof.institution
         WHERE cor.id_comm_order_req = i_comm_order_req;
    
        g_error     := 'CALL get_sets_coll';
        l_sets_coll := get_sets_coll(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_patient   => l_patient,
                                     i_episode   => l_episode,
                                     i_task_type => table_varchar2(l_task_type),
                                     i_value     => l_task_type_content);
    
        SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.*
                  FROM TABLE(l_sets_coll) t);
    
        SELECT DISTINCT t_rec_po_param(id_po_param, id_inst_owner)
          BULK COLLECT
          INTO l_params
          FROM (SELECT pps.id_po_param, pps.id_inst_owner
                  FROM po_param_sets pps
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        t.sets_id sets_id
                         FROM TABLE(l_ret) t) s
                    ON pps.task_type_content = s.sets_id
                  JOIN po_param pop
                    ON pps.id_po_param = pop.id_po_param
                   AND pps.id_inst_owner = pop.id_inst_owner
                 WHERE pps.id_institution IN (i_prof.institution, 0)
                   AND pps.id_software IN (i_prof.software, 0)
                   AND pps.id_task_type = l_task_type
                   AND pps.flg_available = pk_alert_constant.g_yes
                   AND pop.flg_available = pk_alert_constant.g_yes
                MINUS
                SELECT patpop.id_po_param, patpop.id_inst_owner
                  FROM pat_po_param patpop
                 WHERE patpop.id_patient = l_patient
                   AND patpop.flg_visible = pk_alert_constant.g_no);
    
        --Obtaining registered values
        g_error  := 'Obtaining registered values';
        l_values := get_value_coll_comm_order(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_patient          => l_patient,
                                              i_episode          => l_episode,
                                              i_params           => l_params,
                                              i_tbl_po_param_reg => table_number(i_po_param_reg));
    
        g_error := 'COUNT';
        SELECT /*+opt_estimate(table t rows=1)*/
         COUNT(1)
          INTO l_count
          FROM TABLE(CAST(l_values AS t_coll_po_value)) t;
    
        RETURN l_count;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN 0;
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
            RETURN 0;
    END get_count_comm_order;

    /**
    * Get detail.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_date         date to get results from
    * @param o_detail       detail
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_detail_by_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_date          IN VARCHAR2,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_detail        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DETAIL';
        l_cr_code   CONSTANT translation.code_translation%TYPE := 'CANCEL_REASON.CODE_CANCEL_REASON.';
        l_dcs      epis_info.id_dep_clin_serv%TYPE;
        l_ref_vals sys_config.value%TYPE;
        l_canceled sys_message.desc_message%TYPE;
        l_params   t_coll_po_param;
        l_values   t_coll_po_value;
        l_dt_ini   pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_fim   pat_pregnancy.dt_init_pregnancy%TYPE;
        l_date     VARCHAR2(14 CHAR);
    BEGIN
        g_error := 'call get_pregn_interval_dates';
        IF NOT get_pregn_interval_dates(i_pat_pregnancy => i_pat_pregnancy, o_dt_ini => l_dt_ini, o_dt_fim => l_dt_fim)
        THEN
            RAISE g_exception;
        END IF;
    
        l_dcs      := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        l_ref_vals := pk_sysconfig.get_config(i_code_cf => g_cfg_show_ref_vals, i_prof => i_prof);
        l_canceled := pk_message.get_message(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_code_mess => 'PERIODIC_OBSERVATION_T063');
    
        -- get parameter related data
        l_params := get_param_wp(i_prof          => i_prof,
                                 i_patient       => i_patient,
                                 i_episode       => i_episode,
                                 i_pat_pregnancy => i_pat_pregnancy,
                                 i_owner         => 'BOTH');
    
        -- get value related data
        l_values := get_value_coll_wh(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => i_patient,
                                      i_episode       => i_episode,
                                      i_params        => l_params,
                                      i_pat_pregnancy => i_pat_pregnancy,
                                      i_dt_ini        => l_dt_ini,
                                      i_dt_fim        => l_dt_fim);
    
        l_date := substr(i_date, 1, 8);
    
        g_error := 'OPEN o_detail';
        --ALERT-154864
    
        OPEN o_detail FOR
            SELECT v.id_po_param parameter_id,
                   pop.flg_type parameter_flg_type,
                   (SELECT get_param_desc(i_lang,
                                          i_prof,
                                          pop.id_po_param,
                                          pop.id_inst_owner,
                                          pop.flg_type,
                                          pop.id_parameter,
                                          l_dcs)
                      FROM dual) parameter_desc,
                   CASE
                        WHEN v.lab_param_count > 1 THEN
                         (SELECT pk_translation.get_translation(i_lang,
                                                                'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' ||
                                                                v.lab_param_id)
                            FROM dual)
                        ELSE
                         NULL
                    END parameter_sub_desc,
                   get_woman_health_desc(i_lang, i_prof, v.woman_health_id) parameter_health_programs,
                   v.id_result value_id,
                   v.flg_status value_status,
                   decode(v.flg_status, pk_alert_constant.g_cancelled, l_canceled) value_cancel_label,
                   (SELECT to_clob(decode(htf.escape_sc(v.option_count),
                                          0,
                                          htf.escape_sc(v.desc_result),
                                          1,
                                          htf.escape_sc(pk_translation.get_translation(i_lang, v.option_code)),
                                          htf.escape_sc(get_reg_opt_value(i_lang, v.option_codes))))
                      FROM dual) value_text,
                   htf.escape_sc(v.desc_unit_measure) value_units,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, v.dt_result_real, i_prof) value_dt_result,
                   (SELECT get_signature(i_lang, i_prof, v.id_prof_reg, v.dt_reg, v.id_episode, v.id_institution)
                      FROM dual) value_signature,
                   decode(l_ref_vals, pk_alert_constant.g_yes, v.val_min) value_min,
                   decode(l_ref_vals, pk_alert_constant.g_yes, v.val_max) value_max,
                   (SELECT get_signature(i_lang,
                                         i_prof,
                                         v.id_prof_cancel,
                                         v.dt_cancel,
                                         v.id_episode,
                                         v.id_institution,
                                         'C')
                      FROM dual) value_cancel_signature,
                   (SELECT nvl2(v.id_cancel_reason,
                                pk_translation.get_translation(i_lang, l_cr_code || v.id_cancel_reason),
                                NULL)
                      FROM dual) value_cancel_reason,
                   v.notes_cancel value_cancel_notes,
                   COUNT(DISTINCT v.id_result) over(PARTITION BY v.id_po_param, v.id_inst_owner, v.woman_health_id) value_elem_count,
                   COUNT(*) over(PARTITION BY v.id_po_param, v.id_inst_owner, v.woman_health_id, v.id_result) value_reg_count,
                   COUNT(DISTINCT v.id_result) over(PARTITION BY v.id_po_param, v.id_inst_owner, v.woman_health_id, v.flg_status) parameter_active_value_count,
                   v.woman_health_id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, v.dt_harvest, i_prof) value_dt_harvest,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, v.dt_execution, i_prof) value_dt_execution,
                   v.notes value_notes,
                   abnorm_value value_abnormal
              FROM (SELECT /*+opt_estimate(table t rows=1)*/
                     t.id_po_param,
                     t.id_inst_owner,
                     t.id_result,
                     t.id_episode,
                     t.id_institution,
                     t.id_software,
                     t.id_prof_reg,
                     t.dt_result dt_result_real,
                     t.dt_reg,
                     substr(pk_date_utils.date_send_tsz(i_lang, t.dt_reg, i_prof), 1, 12) dt_register,
                     t.flg_status,
                     t.desc_result,
                     t.desc_unit_measure,
                     t.lab_param_count,
                     t.lab_param_id,
                     t.lab_param_rank,
                     t.abnorm_value,
                     t.val_min,
                     t.val_max,
                     t.option_codes,
                     t.flg_cancel,
                     t.dt_cancel,
                     t.id_prof_cancel,
                     t.id_cancel_reason,
                     t.notes_cancel,
                     t.dt_result dt_result,
                     t.get_opt_count() option_count,
                     t.get_opt_code_first() option_code,
                     t.woman_health_id,
                     t.flg_ref_value,
                     t.dt_harvest,
                     t.dt_execution,
                     t.notes
                      FROM TABLE(CAST(l_values AS t_coll_po_value)) t) v
              JOIN po_param pop
                ON v.id_po_param = pop.id_po_param
               AND v.id_inst_owner = pop.id_inst_owner
             WHERE ((v.flg_ref_value = pk_alert_constant.g_no AND
                   substr(pk_date_utils.date_send_tsz(i_lang, v.dt_result, i_prof), 1, 8) = l_date) OR
                   (v.flg_ref_value = pk_alert_constant.g_yes AND i_date = g_ref_value))
             ORDER BY v.woman_health_id,
                      get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank),
                      parameter_desc,
                      dt_result DESC,
                      dt_register DESC,
                      parameter_sub_desc,
                      v.lab_param_rank;
    
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_detail_by_wh;
    /**
    * Get the episode's periodic observations.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_per_obs      episode's periodic observations
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7
    * @since                2010/01/06
    */
    PROCEDURE get_epis_per_obs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_per_obs OUT pk_types.cursor_type
    ) IS
        CURSOR c_pat IS
            SELECT e.id_patient
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_patient patient.id_patient%TYPE;
        l_dcs     epis_info.id_dep_clin_serv%TYPE;
        l_params  t_coll_po_param;
        l_values  t_coll_po_value;
    BEGIN
        l_dcs := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
    
        OPEN c_pat;
        FETCH c_pat
            INTO l_patient;
        CLOSE c_pat;
    
        l_params := get_param(i_prof => i_prof, i_patient => l_patient, i_episode => i_episode);
    
        l_values := get_value_coll(i_lang    => i_lang,
                                   i_prof    => i_prof,
                                   i_patient => l_patient,
                                   i_episode => i_episode,
                                   i_params  => l_params);
        OPEN o_per_obs FOR
            SELECT (SELECT get_param_desc(i_lang,
                                           i_prof,
                                           pop.id_po_param,
                                           pop.id_inst_owner,
                                           pop.flg_type,
                                           pop.id_parameter,
                                           l_dcs)
                       FROM dual) || CASE
                        WHEN v.lab_param_count > 1 THEN
                         ' - ' ||
                         pk_translation.get_translation(i_lang,
                                                        'ANALYSIS_PARAMETER.CODE_ANALYSIS_PARAMETER.' || v.lab_param_id)
                        ELSE
                         NULL
                    END || ': ' || decode(v.option_count,
                                          0,
                                          v.desc_result,
                                          1,
                                          pk_translation.get_translation(i_lang, v.option_code),
                                          get_reg_opt_value(i_lang, v.option_codes)) || ' ' || v.desc_unit_measure description,
                   v.id_prof_reg,
                   v.dt_reg
              FROM (SELECT t.id_po_param,
                           t.id_inst_owner,
                           t.id_episode,
                           t.id_prof_reg,
                           t.dt_reg,
                           t.flg_status,
                           t.desc_result,
                           t.desc_unit_measure,
                           t.lab_param_count,
                           t.lab_param_id,
                           t.lab_param_rank,
                           t.option_codes,
                           t.get_opt_count() option_count,
                           t.get_opt_code_first() option_code
                      FROM TABLE(CAST(l_values AS t_coll_po_value)) t) v
              JOIN po_param pop
                ON v.id_po_param = pop.id_po_param
               AND v.id_inst_owner = pop.id_inst_owner
             WHERE v.id_episode = i_episode
               AND pop.flg_type IN (g_analysis, g_habit, g_others)
             ORDER BY v.dt_reg DESC;
    END get_epis_per_obs;
    /**
    * Get parameters grid.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_param        parameters
    * @param o_time         times
    * @param o_value        values
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/09
    */
    FUNCTION get_grid_param
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_cursor_out IN VARCHAR2 DEFAULT 'A',
        i_dt_begin   IN VARCHAR2 DEFAULT NULL,
        i_dt_end     IN VARCHAR2 DEFAULT NULL,
        i_num_reg    IN NUMBER DEFAULT NULL,
        o_param      OUT pk_types.cursor_type,
        o_time       OUT pk_types.cursor_type,
        o_value      OUT pk_types.cursor_type,
        o_values_wh  OUT t_coll_wh_values,
        o_ref        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_GRID_PARAM';
        l_params         t_coll_po_param;
        l_med_data       t_tbl_rec_sum_act_meds;
        l_values         t_coll_po_value;
        l_show_ref_value sys_config.value%TYPE;
        l_dt_begin       TIMESTAMP WITH TIME ZONE;
        l_dt_end         TIMESTAMP WITH TIME ZONE;
    
        --***********
        PROCEDURE set_dates IS
            l_max_days_back NUMBER;
        BEGIN
        
            l_max_days_back := pk_sysconfig.get_config(i_code_cf => 'PO_MAX_DAYS_BACK', i_prof => i_prof);
            IF l_max_days_back > 0
            THEN
            
                l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
                l_dt_begin := l_dt_end - numtodsinterval(l_max_days_back, 'DAY');
            
                l_dt_end := l_dt_end + numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND');
            
            ELSE
            
                l_dt_begin := l_dt_begin;
                l_dt_end   := l_dt_end;
            
            END IF;
        END set_dates;
    
    BEGIN
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_begin,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_begin,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_end,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_end,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- CMF
        set_dates();
    
        -- create a periodic observation column for the episode
        g_error := 'CALL pk_periodic_observation.create_column_auto';
        create_column_auto(i_lang    => i_lang,
                           i_prof    => i_prof,
                           i_patient => i_patient,
                           i_episode => i_episode,
                           o_error   => o_error);
    
        l_params := get_param(i_prof => i_prof, i_patient => i_patient, i_episode => i_episode);
    
        g_error  := 'call get_value_coll';
        l_values := get_value_coll(i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   i_patient  => i_patient,
                                   i_episode  => i_episode,
                                   i_params   => l_params,
                                   i_dt_begin => l_dt_begin,
                                   i_dt_end   => l_dt_end);
    
        IF i_cursor_out IN ('A', 'VW')
        THEN
            g_error     := 'call get_value_cursor';
            o_values_wh := get_value_cursor(i_lang => i_lang, i_prof => i_prof, i_values => l_values);
        
        ELSE
            o_values_wh := t_coll_wh_values();
        END IF;
    
        g_error := 'OPEN o_value';
        OPEN o_value FOR
            SELECT *
              FROM TABLE(CAST(o_values_wh AS t_coll_wh_values));
    
        IF i_cursor_out = 'A'
        THEN
            g_error := 'call get_param_cursor';
        
            get_param_cursor(i_lang     => i_lang,
                             i_prof     => i_prof,
                             i_episode  => i_episode,
                             i_params   => l_params,
                             i_med_data => l_med_data,
                             i_values   => l_values,
                             i_cancel   => pk_alert_constant.g_yes,
                             i_dt_begin => l_dt_begin,
                             i_dt_end   => l_dt_end,
                             i_num_reg  => i_num_reg,
                             o_param    => o_param);
        
            g_error := 'call get_time_cursor';
            get_time_cursor(i_lang     => i_lang,
                            i_prof     => i_prof,
                            i_patient  => i_patient,
                            i_values   => l_values,
                            i_dt_begin => l_dt_begin,
                            i_dt_end   => l_dt_end,
                            o_time     => o_time);
        
            l_show_ref_value := pk_sysconfig.get_config('FLOW_SHEETS_SHOW_REF_VALUE', i_prof);
            IF l_show_ref_value = pk_alert_constant.g_yes
            THEN
                g_error := 'open o_ref';
                OPEN o_ref FOR
                    SELECT g_ref_value time_id
                      FROM dual;
            ELSE
                pk_types.open_my_cursor(o_ref);
            END IF;
        ELSE
            pk_types.open_my_cursor(o_value);
            pk_types.open_my_cursor(o_param);
            pk_types.open_my_cursor(o_ref);
            pk_types.open_my_cursor(o_time);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            pk_types.open_my_cursor(o_param);
            pk_types.open_my_cursor(o_ref);
            pk_types.open_my_cursor(o_time);
            RETURN FALSE;
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
            pk_types.open_my_cursor(o_value);
            pk_types.open_my_cursor(o_param);
            pk_types.open_my_cursor(o_ref);
            pk_types.open_my_cursor(o_time);
            RETURN FALSE;
    END get_grid_param;

    /**
    * Get keypad.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param o_keypad       keypad
    * @param o_units        measurement units
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/20
    */
    PROCEDURE get_keypad
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_param  IN po_param.id_po_param%TYPE,
        i_owner  IN po_param.id_inst_owner%TYPE,
        o_keypad OUT pk_types.cursor_type
    ) IS
        l_parameter po_param.id_parameter%TYPE;
        l_flg_type  po_param.flg_type%TYPE;
    BEGIN
        -- get parameter identifier and type
        g_error := 'OPEN c_pop_pk';
        OPEN c_pop_pk(i_param => i_param, i_owner => i_owner);
        FETCH c_pop_pk
            INTO l_parameter, l_flg_type;
        CLOSE c_pop_pk;
    
        g_error := 'OPEN o_keypad popum';
        OPEN o_keypad FOR
            SELECT default_value,
                   default_unit_id,
                   val_min,
                   val_max,
                   format_num,
                   format_separator,
                   unit_type_id,
                   unit_subtype_id,
                   default_value_2,
                   min_value_2,
                   max_value_2
              FROM (SELECT NULL                          default_value,
                           NULL                          default_unit_id,
                           popum.val_min                 val_min,
                           popum.val_max                 val_max,
                           popum.format_num              format_num,
                           NULL                          format_separator,
                           popum.id_unit_measure_type    unit_type_id,
                           popum.id_unit_measure_subtype unit_subtype_id,
                           NULL                          default_value_2,
                           NULL                          min_value_2,
                           NULL                          max_value_2,
                           popum.id_institution,
                           popum.id_software
                      FROM po_param_um popum
                     WHERE popum.id_po_param = i_param
                       AND popum.id_inst_owner = i_owner
                       AND popum.id_institution IN (i_prof.institution, 0)
                       AND popum.id_software IN (i_prof.software, 0)
                       AND popum.flg_available = pk_alert_constant.g_yes) um
             ORDER BY um.id_institution DESC, um.id_software DESC;
    
    END get_keypad;

    /**
    * Get multichoice.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param o_mc           multichoice
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/19
    */
    FUNCTION get_multichoice
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_param   IN po_param.id_po_param%TYPE,
        i_owner   IN po_param.id_inst_owner%TYPE,
        o_mc      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_MULTICHOICE';
    BEGIN
        g_error := 'OPEN o_mc popmc';
        OPEN o_mc FOR
            SELECT popmc.id_po_param_mc data,
                   pk_translation.get_translation(i_lang, popmc.code_po_param_mc) label,
                   pk_translation.get_translation(i_lang, popmc.code_icon) icon,
                   popmc.rank
              FROM po_param_mc popmc
             WHERE popmc.id_po_param = i_param
               AND popmc.id_inst_owner = i_owner
               AND popmc.flg_available = pk_alert_constant.g_yes
             ORDER BY popmc.rank, label;
    
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_multichoice;

    /**
    * Get full parameters list (as used in parameters grid).
    *
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               parameters collection
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/27
    */
    FUNCTION get_param
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN t_coll_po_param IS
        l_ret  t_coll_po_param;
        l_cs   episode.id_clinical_service%TYPE;
        l_hpgs table_number;
    BEGIN
        l_cs := get_id_clinical_service(i_episode => i_episode);
        -- ALERT-154864       
        l_hpgs := pk_health_program.get_pat_hpgs(i_prof       => i_prof,
                                                 i_patient    => i_patient,
                                                 i_exc_status => g_hpg_exc_status);
    
        g_error := 'SELECT l_params';
        SELECT t_rec_po_param(id_po_param, id_inst_owner)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT pop.id_po_param,
                       pop.id_inst_owner,
                       pop.id_sample_type,
                       row_number() over(PARTITION BY pop.flg_type, pop.id_parameter, pop.id_sample_type ORDER BY pop.id_inst_owner DESC) rn
                  FROM po_param pop
                  JOIN (SELECT popcs.id_po_param, popcs.id_inst_owner
                         FROM po_param_cs popcs
                        WHERE popcs.id_clinical_service = l_cs
                          AND popcs.id_institution IN (i_prof.institution, 0)
                          AND popcs.id_software IN (i_prof.software, 0)
                          AND popcs.flg_available = pk_alert_constant.g_yes
                       UNION -- health programs
                       SELECT pps.id_po_param, pps.id_inst_owner
                         FROM po_param_sets pps
                         JOIN health_program hp
                           ON pps.task_type_content = hp.id_content
                         JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                               t.column_value id_health_program
                                FROM TABLE(CAST(l_hpgs AS table_number)) t) hpg
                           ON hp.id_health_program = hpg.id_health_program
                        WHERE pps.id_institution IN (i_prof.institution, 0)
                          AND pps.id_software IN (i_prof.software, 0)
                          AND pps.id_task_type = pk_periodic_observation.g_task_type_hpg
                          AND pps.flg_available = pk_alert_constant.g_yes
                       UNION -- sets of indicators - procedures
                       SELECT pps.id_po_param, pps.id_inst_owner
                         FROM po_param_sets pps
                         JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                               id_content, description
                                FROM TABLE(pk_procedures_external_api_db.get_procedure_flowsheets(1,
                                                                                                  i_prof,
                                                                                                  pk_alert_constant.g_scope_type_episode,
                                                                                                  i_episode)) t) proc
                           ON pps.task_type_content = proc.id_content
                        WHERE pps.id_institution IN (i_prof.institution, 0)
                          AND pps.id_software IN (i_prof.software, 0)
                          AND pps.id_task_type = pk_periodic_observation.g_task_type_interv
                          AND pps.flg_available = pk_alert_constant.g_yes
                       UNION -- sets of indicators - imaging
                       SELECT pps.id_po_param, pps.id_inst_owner
                         FROM po_param_sets pps
                         JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                               id_content, description
                                FROM TABLE(pk_exams_external_api_db.get_exam_flowsheets(1,
                                                                                        i_prof,
                                                                                        pk_alert_constant.g_scope_type_episode,
                                                                                        i_episode)) t) ex
                           ON pps.task_type_content = ex.id_content
                        WHERE pps.id_institution IN (i_prof.institution, 0)
                          AND pps.id_software IN (i_prof.software, 0)
                          AND pps.id_task_type IN
                              (pk_periodic_observation.g_task_type_exam, pk_periodic_observation.g_task_type_oth_exams)
                          AND pps.flg_available = pk_alert_constant.g_yes
                       UNION
                       SELECT patpop.id_po_param, patpop.id_inst_owner
                         FROM pat_po_param patpop
                        WHERE patpop.id_patient = i_patient
                          AND patpop.flg_visible = pk_alert_constant.g_yes
                       
                       MINUS
                       SELECT patpop.id_po_param, patpop.id_inst_owner
                         FROM pat_po_param patpop
                        WHERE patpop.id_patient = i_patient
                          AND patpop.flg_visible = pk_alert_constant.g_no) p
                    ON pop.id_po_param = p.id_po_param
                   AND pop.id_inst_owner = p.id_inst_owner
                 WHERE pop.id_inst_owner IN (i_prof.institution, 0)
                   AND pop.flg_available = pk_alert_constant.g_yes
                   AND (pop.flg_type != g_analysis OR
                       (pop.flg_type = g_analysis AND EXISTS
                        (SELECT 1
                            FROM analysis_instit_soft ais
                           WHERE ais.id_institution = i_prof.institution
                             AND ais.id_software = i_prof.software
                             AND ais.id_analysis = pop.id_parameter
                             AND ais.id_sample_type = pop.id_sample_type
                             AND ais.flg_available = pk_alert_constant.g_yes))))
         WHERE rn = 1;
    
        RETURN l_ret;
    END get_param;

    /**
    * Get parameter alias translation.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param i_dcs          service/specialty identifier
    *
    * @return               parameter translation
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    FUNCTION get_param_alias
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_param IN po_param.id_po_param%TYPE,
        i_owner IN po_param.id_inst_owner%TYPE,
        i_dcs   IN po_param_alias.id_dep_clin_serv%TYPE := NULL
    ) RETURN pk_translation.t_desc_translation IS
        l_ret  pk_translation.t_desc_translation;
        l_code translation.code_translation%TYPE;
    
        CURSOR c_alias IS
            SELECT popa.code_po_param_alias
              FROM po_param_alias popa
             WHERE popa.id_po_param = i_param
               AND popa.id_inst_owner = i_owner
               AND popa.id_institution IN (i_prof.institution, 0)
               AND popa.id_software IN (i_prof.software, 0)
               AND (popa.id_dep_clin_serv IS NULL OR popa.id_dep_clin_serv = i_dcs)
               AND (popa.id_professional IS NULL OR popa.id_professional = i_prof.id)
             ORDER BY popa.id_institution   DESC,
                      popa.id_software      DESC,
                      popa.id_dep_clin_serv DESC NULLS LAST,
                      popa.id_professional  DESC NULLS LAST;
    BEGIN
        IF i_param IS NULL
           OR i_owner IS NULL
        THEN
            l_ret := NULL;
        ELSE
            OPEN c_alias;
            FETCH c_alias
                INTO l_code;
            CLOSE c_alias;
        
            l_ret := pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_code);
        
            IF l_ret IS NULL
            THEN
                l_code := 'PO_PARAM.CODE_PO_PARAM.' || i_param;
                l_ret  := pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_code);
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_param_alias;

    /**
    * Get parameter description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param i_flg_type     parameter type flag
    * @param i_parameter    local parameter identifier   
    * @param i_dcs          service/specialty identifier
    *
    * @return               parameter translation
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/12/11
    */
    FUNCTION get_param_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_param     IN po_param.id_po_param%TYPE,
        i_owner     IN po_param.id_inst_owner%TYPE,
        i_flg_type  IN po_param.flg_type%TYPE,
        i_parameter IN po_param.id_parameter%TYPE,
        i_dcs       IN po_param_alias.id_dep_clin_serv%TYPE := NULL
    ) RETURN pk_translation.t_desc_translation IS
    
        l_ret        pk_translation.t_desc_translation;
        l_code       translation.code_translation%TYPE;
        l_sampletype po_param.id_sample_type%TYPE;
    BEGIN
        SELECT pp.id_sample_type
          INTO l_sampletype
          FROM po_param pp
         WHERE pp.id_parameter = i_parameter
           AND pp.id_inst_owner = i_owner
           AND pp.id_po_param = i_param;
    
        IF i_flg_type IS NULL
           OR i_parameter IS NULL
        THEN
            l_ret := NULL;
        ELSE
            IF i_flg_type = g_analysis
            THEN
                l_code := 'ANALYSIS.CODE_ANALYSIS.' || i_parameter;
                l_ret  := pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                    i_prof,
                                                                    pk_lab_tests_constant.g_analysis_alias,
                                                                    l_code,
                                                                    'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || l_sampletype,
                                                                    i_dcs);
            
            ELSIF i_flg_type = g_exam
            THEN
                l_code := 'EXAM.CODE_EXAM.' || i_parameter;
                l_ret  := pk_exams_api_db.get_alias_translation(i_lang          => i_lang,
                                                                i_prof          => i_prof,
                                                                i_code_exam     => l_code,
                                                                i_dep_clin_serv => i_dcs);
            ELSIF i_flg_type = g_habit
            THEN
                l_code := 'HABIT.CODE_HABIT.' || i_parameter;
                l_ret  := pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_code);
            ELSIF i_flg_type = g_others
            THEN
                l_ret := get_param_alias(i_lang  => i_lang,
                                         i_prof  => i_prof,
                                         i_param => i_param,
                                         i_owner => i_owner,
                                         i_dcs   => i_dcs);
            
            ELSIF i_flg_type = g_vital_sign
            THEN
                l_code := 'VITAL_SIGN.CODE_VITAL_SIGN.' || i_parameter;
                l_ret  := pk_translation.get_translation(i_lang => i_lang, i_code_mess => l_code);
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_param_desc;

    /**
    * Get parameter rank.
    *
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param i_rank         parameter self rank
    *
    * @return               parameter rank
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_param_rank
    (
        i_prof  IN profissional,
        i_param IN po_param.id_po_param%TYPE,
        i_owner IN po_param.id_inst_owner%TYPE,
        i_rank  IN po_param.rank%TYPE := NULL
    ) RETURN po_param_rank.rank%TYPE IS
        l_ret po_param_rank.rank%TYPE;
    
        CURSOR c_rank IS
            SELECT poprk.rank
              FROM po_param_rank poprk
             WHERE poprk.id_po_param = i_param
               AND poprk.id_inst_owner = i_owner
               AND poprk.id_institution IN (i_prof.institution, 0)
               AND poprk.id_software IN (i_prof.software, 0)
               AND poprk.flg_available = pk_alert_constant.g_yes
             ORDER BY poprk.id_institution DESC, poprk.id_software DESC;
    BEGIN
        IF i_param IS NULL
           OR i_owner IS NULL
        THEN
            l_ret := NULL;
        ELSE
            OPEN c_rank;
            FETCH c_rank
                INTO l_ret;
            CLOSE c_rank;
        END IF;
    
        l_ret := nvl(l_ret, i_rank);
    
        RETURN l_ret;
    END get_param_rank;

    /**
    * Get previous appointment date.
    *
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               previous appointment date
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/30
    */
    FUNCTION get_prev_epis_date
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN episode.dt_end_tstz%TYPE IS
        l_ret episode.dt_end_tstz%TYPE;
        l_et  epis_type.id_epis_type%TYPE;
    
        CURSOR c_ped IS
            SELECT e.dt_end_tstz
              FROM episode e
             WHERE e.id_episode < i_episode
               AND e.flg_status = pk_alert_constant.g_epis_status_inactive
               AND e.id_epis_type = l_et
               AND e.flg_ehr = pk_alert_constant.g_flg_ehr_n
               AND e.id_patient = i_patient
               AND e.id_institution = i_prof.institution
             ORDER BY e.id_episode DESC;
    BEGIN
        l_et := pk_episode.get_epis_type(i_lang => NULL, i_id_epis => i_episode);
    
        OPEN c_ped;
        FETCH c_ped
            INTO l_ret;
        CLOSE c_ped;
    
        RETURN l_ret;
    END get_prev_epis_date;

    /**
    * Get record multichoice option codes.
    *
    * @param i_popr         parameter record identifier
    *
    * @return               multichoice option codes
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/23
    */
    FUNCTION get_reg_opt_codes(i_popr IN po_param_reg.id_po_param_reg%TYPE) RETURN table_varchar IS
        l_ret        table_varchar := table_varchar();
        l_popmc_rows t_coll_popmc;
    BEGIN
        IF i_popr IS NOT NULL
        THEN
            OPEN c_popmc(i_popr => i_popr);
            FETCH c_popmc BULK COLLECT
                INTO l_popmc_rows;
            CLOSE c_popmc;
        
            FOR i IN 1 .. l_popmc_rows.count
            LOOP
                l_ret.extend;
                l_ret(l_ret.last) := l_popmc_rows(i).code_po_param_mc;
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_reg_opt_codes;

    /**
    * Get record multichoice option icon.
    *
    * @param i_lang         language identifier
    * @param i_popr         parameter record identifier
    *
    * @return               multichoice first option icon
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_reg_opt_icon
    (
        i_lang IN language.id_language%TYPE,
        i_popr IN po_param_reg.id_po_param_reg%TYPE
    ) RETURN pk_translation.t_desc_translation IS
        l_ret        pk_translation.t_desc_translation;
        l_popmc_rows t_coll_popmc;
    BEGIN
        IF i_popr IS NOT NULL
        THEN
            OPEN c_popmc(i_popr => i_popr);
            FETCH c_popmc BULK COLLECT
                INTO l_popmc_rows;
            CLOSE c_popmc;
        
            IF l_popmc_rows IS NOT NULL
               AND l_popmc_rows.first IS NOT NULL
               AND l_popmc_rows.count = 1
            THEN
                l_ret := pk_translation.get_translation(i_lang      => i_lang,
                                                        i_code_mess => l_popmc_rows(l_popmc_rows.first).code_icon);
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_reg_opt_icon;

    /**
    * Get record multichoice option value.
    *
    * @param i_lang         language identifier
    * @param i_codes        multichoice option codes
    *
    * @return               multichoice option value
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_reg_opt_value
    (
        i_lang  IN language.id_language%TYPE,
        i_codes IN table_varchar
    ) RETURN pk_translation.t_desc_translation IS
        l_ret pk_translation.t_desc_translation := NULL;
    BEGIN
        IF i_codes IS NOT NULL
           AND i_codes.count > 0
        THEN
            FOR i IN i_codes.first .. i_codes.last
            LOOP
                l_ret := l_ret || pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_codes(i)) || '; ';
            END LOOP;
        END IF;
    
        RETURN l_ret;
    END get_reg_opt_value;
    /**
    * Checks if a parameter is shown in the parameters grid.
    *
    * @param i_prof         logged professional structure
    * @param i_params       parameters collection
    * @param i_type         parameter type flag
    * @param i_parameter    local parameter identifier
    * @param i_sample_type  sample type Id
    *
    * @return               'true'/'false'
    *
    * @author               Teresa Coutinho
    * @version               2.4.3
    * @since                2008/01/23
    */
    FUNCTION get_selected
    (
        i_prof        IN profissional,
        i_params      IN t_coll_po_param,
        i_type        IN po_param.flg_type%TYPE,
        i_parameter   IN po_param.id_parameter%TYPE,
        i_sample_type IN po_param.id_sample_type%TYPE
    ) RETURN VARCHAR2 IS
        l_ret   VARCHAR2(5 CHAR) := 'false';
        r_param c_pop_param%ROWTYPE;
    BEGIN
        OPEN c_pop_param(i_type        => i_type,
                         i_parameter   => i_parameter,
                         i_owner       => i_prof.institution,
                         i_sample_type => i_sample_type);
        FETCH c_pop_param
            INTO r_param;
        CLOSE c_pop_param;
    
        FOR i IN 1 .. i_params.count
        LOOP
            IF i_params(i).id_po_param = r_param.id_po_param
                AND i_params(i).id_inst_owner = r_param.id_inst_owner
                AND (i_sample_type IS NULL OR i_sample_type = r_param.id_sample_type)
            THEN
                l_ret := 'true';
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_ret;
    END get_selected;

    /**
    * Get record signature.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_id      professional identifier
    * @param i_dt_reg       registry date
    * @param i_episode      episode identifier
    * @param i_inst         institution identifier
    *
    * @return               record signature
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/28
    */
    FUNCTION get_signature
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_id    IN professional.id_professional%TYPE,
        i_dt_reg     IN po_param_reg.dt_creation%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_inst       IN institution.id_institution%TYPE,
        i_flg_status IN VARCHAR2 DEFAULT 'A'
    ) RETURN pk_translation.t_desc_translation IS
        l_ret pk_translation.t_desc_translation;
    BEGIN
        IF i_flg_status = 'C'
        THEN
            l_ret := pk_message.get_message(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_code_mess => 'PERIODIC_OBSERVATION_T038') || ': ';
        ELSE
            l_ret := pk_message.get_message(i_lang      => i_lang,
                                            i_prof      => i_prof,
                                            i_code_mess => 'PERIODIC_OBSERVATION_T052') || ': ';
        END IF;
    
        l_ret := l_ret || pk_tools.get_prof_description(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_prof_id => i_prof_id,
                                                        i_date    => i_dt_reg,
                                                        i_episode => i_episode) || '; ';
        l_ret := l_ret || pk_utils.get_institution_name(i_lang => i_lang, i_id_institution => i_inst) || '; ';
        l_ret := l_ret || pk_date_utils.dt_chr_date_hour_tsz(i_lang => i_lang, i_date => i_dt_reg, i_prof => i_prof);
        RETURN l_ret;
    END get_signature;

    /**
    * Get multichoice of values to cancel.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param i_dt           parameter observation date
    * @param o_values       values to cancel
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/26
    */
    FUNCTION get_values_cancel
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_param   IN po_param.id_po_param%TYPE,
        i_owner   IN po_param.id_inst_owner%TYPE,
        i_dt      IN VARCHAR2,
        o_values  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_VALUES_CANCEL';
        l_aggregate  sys_config.value%TYPE;
        l_vs_sort    sys_config.value%TYPE;
        l_lab_result sys_domain.desc_val%TYPE;
        l_params     t_coll_po_param;
        l_values     t_coll_po_value;
    BEGIN
        --ALERT-154864    
        --pk_lab_tests_constant.g_arq_status_with_result
        l_aggregate  := pk_sysconfig.get_config(i_code_cf => g_cfg_col_aggregate, i_prof => i_prof);
        l_vs_sort    := pk_sysconfig.get_config(i_code_cf => g_cfg_vs_sort, i_prof => i_prof);
        l_lab_result := pk_sysdomain.get_domain(i_code_dom => g_ana_req_det_domain, i_val => 'F', i_lang => i_lang);
        l_params     := t_coll_po_param(t_rec_po_param(id_po_param => i_param, id_inst_owner => i_owner));
    
        l_values := get_value_coll(i_lang    => i_lang,
                                   i_prof    => i_prof,
                                   i_patient => i_patient,
                                   i_episode => i_episode,
                                   i_params  => l_params);
    
        g_error := 'OPEN o_values';
        OPEN o_values FOR
            SELECT v.id_result value_id,
                   decode(v.option_count,
                           0,
                           CASE
                               WHEN v.lab_param_count > 1 THEN
                                to_clob(l_lab_result)
                               ELSE
                                v.desc_result
                           END,
                           1,
                           pk_translation.get_translation(i_lang, v.option_code),
                           get_reg_opt_value(i_lang, v.option_codes)) value_text,
                   CASE
                        WHEN v.lab_param_count > 1 THEN
                         NULL
                        ELSE
                         v.desc_unit_measure
                    END value_units,
                   get_signature(i_lang, i_prof, v.id_prof_reg, v.dt_reg, v.id_episode, v.id_institution) value_signature
              FROM (SELECT t.id_result,
                           t.id_episode,
                           t.id_institution,
                           t.id_prof_reg,
                           (SELECT pk_date_utils.date_send_tsz(i_lang,
                                                               decode(l_aggregate,
                                                                      pk_alert_constant.g_yes,
                                                                      t.dt_result_aggr,
                                                                      t.dt_result),
                                                               i_prof)
                              FROM dual) dt_result,
                           CASE
                                WHEN l_vs_sort = g_vs_sort_asc
                                     AND (SELECT pop.flg_type
                                            FROM po_param pop
                                           WHERE pop.id_po_param = t.id_po_param
                                             AND pop.id_inst_owner = t.id_inst_owner) = g_vital_sign THEN
                                 t.dt_result
                            END dt_vs_sort,
                           t.dt_result dt_result_real,
                           t.dt_reg,
                           t.desc_result,
                           t.desc_unit_measure,
                           t.lab_param_count,
                           t.get_opt_count() option_count,
                           t.get_opt_code_first() option_code,
                           t.option_codes
                      FROM TABLE(CAST(l_values AS t_coll_po_value)) t
                     WHERE t.flg_status = pk_alert_constant.g_active
                       AND t.flg_ref_value = pk_alert_constant.g_no
                       AND (t.lab_param_rank IS NULL OR t.lab_param_rank = 1)) v
             WHERE v.dt_result = i_dt
             ORDER BY v.dt_vs_sort ASC, v.dt_result_real DESC;
    
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_values_cancel;
    ----------------------------------------
    FUNCTION get_values_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_param           IN po_param.id_po_param%TYPE,
        i_owner           IN po_param.id_inst_owner%TYPE,
        i_dt              IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_values          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_VALUES_CANCEL';
        l_params             t_coll_po_param;
        l_id_pat_pregnancy   pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
        l_values             t_coll_po_value;
        l_dt_ini             pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_fim             pat_pregnancy.dt_init_pregnancy%TYPE;
        l_vs_sort            sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => g_cfg_vs_sort,
                                                                              i_prof    => i_prof);
        --ALERT-154864    
        --pk_lab_tests_constant.g_arq_status_with_result                                                                              
        l_lab_result sys_domain.desc_val%TYPE := pk_sysdomain.get_domain(i_code_dom => g_ana_req_det_domain,
                                                                         i_val      => 'F',
                                                                         i_lang     => i_lang);
    
    BEGIN
        g_error := 'CALL split_woman_health_id';
        IF NOT split_woman_health_id(i_woman_health_id    => i_woman_health_id,
                                     o_id_pat_pregnancy   => l_id_pat_pregnancy,
                                     o_id_pat_pregn_fetus => l_id_pat_pregn_fetus)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'call get_pregn_interval_dates';
        IF NOT
            get_pregn_interval_dates(i_pat_pregnancy => l_id_pat_pregnancy, o_dt_ini => l_dt_ini, o_dt_fim => l_dt_fim)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error  := 'call get_param_wp';
        l_params := get_param_wp(i_prof          => i_prof,
                                 i_patient       => i_patient,
                                 i_episode       => i_episode,
                                 i_pat_pregnancy => l_id_pat_pregnancy,
                                 i_owner         => 'BOTH');
    
        g_error  := 'call get_value_coll';
        l_values := get_value_coll_wh(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => i_patient,
                                      i_episode       => i_episode,
                                      i_params        => l_params,
                                      i_pat_pregnancy => l_id_pat_pregnancy,
                                      i_dt_ini        => l_dt_ini,
                                      i_dt_fim        => l_dt_fim);
    
        OPEN o_values FOR
            SELECT v.id_result value_id,
                   decode(v.option_count,
                           0,
                           CASE
                               WHEN v.lab_param_count > 1 THEN
                                to_clob(l_lab_result)
                               ELSE
                                v.desc_result
                           END,
                           1,
                           pk_translation.get_translation(i_lang, v.option_code),
                           get_reg_opt_value(i_lang, v.option_codes)) value_text,
                   CASE
                        WHEN v.lab_param_count > 1 THEN
                         NULL
                        ELSE
                         v.desc_unit_measure
                    END value_units,
                   get_signature(i_lang, i_prof, v.id_prof_reg, v.dt_reg, v.id_episode, v.id_institution) value_signature
              FROM (SELECT t.id_result,
                           t.id_episode,
                           t.id_institution,
                           t.id_prof_reg,
                           (SELECT pk_date_utils.date_send_tsz(i_lang, t.dt_result, i_prof)
                              FROM dual) dt_result,
                           CASE
                                WHEN l_vs_sort = g_vs_sort_asc
                                     AND (SELECT pop.flg_type
                                            FROM po_param pop
                                           WHERE pop.id_po_param = t.id_po_param
                                             AND pop.id_inst_owner = t.id_inst_owner) = g_vital_sign THEN
                                 t.dt_result
                            END dt_vs_sort,
                           t.dt_result dt_result_real,
                           t.dt_reg,
                           t.desc_result,
                           t.desc_unit_measure,
                           t.lab_param_count,
                           t.get_opt_count() option_count,
                           t.get_opt_code_first() option_code,
                           t.option_codes
                      FROM TABLE(CAST(l_values AS t_coll_po_value)) t
                     WHERE substr(get_po_param_reg_date(i_lang,
                                                        i_prof,
                                                        i_patient,
                                                        pk_date_utils.date_send_tsz(i_lang, t.dt_result, i_prof)),
                                  1,
                                  8) = substr(i_dt, 1, 8)
                       AND t.flg_ref_value = pk_alert_constant.g_no
                       AND t.woman_health_id = i_woman_health_id
                       AND i_param = t.id_po_param
                       AND t.flg_status = pk_alert_constant.g_active
                       AND (t.lab_param_rank IS NULL OR t.lab_param_rank = 1)) v
             ORDER BY v.dt_vs_sort ASC, v.dt_result_real DESC;
    
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
            pk_types.open_my_cursor(o_values);
            RETURN FALSE;
    END get_values_cancel;
    /**
    * Get views.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_loader       the current loader (per obs, pregnant)
    * @param o_views        views
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/05
    */
    FUNCTION get_views
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_loader  IN application_file.file_name%TYPE,
        o_views   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             CONSTANT VARCHAR2(30 CHAR) := 'GET_VIEWS';
        l_af_view_hpg           CONSTANT application_file.id_application_file%TYPE := 5011;
        l_af_view_graph         CONSTANT application_file.id_application_file%TYPE := 2001;
        l_per_obs_subject       CONSTANT action.subject%TYPE := 'PER_OBS_VIEW';
        l_per_obs_pregn_subject CONSTANT action.subject%TYPE := 'PER_OBS_PREGN_VIEW';
        l_per_obs_medical_order CONSTANT action.subject%TYPE := 'PER_OBS_MEDICAL_ORDER_VIEW';
    
        l_subject     action.subject%TYPE;
        l_actions     t_coll_action;
        l_af_view_def sys_config.value%TYPE;
        l_view_def    application_file.file_name%TYPE;
        l_view_hpg    application_file.file_name%TYPE;
        l_view_graph  application_file.file_name%TYPE;
        l_temp        table_number;
        l_hpg_cnt     PLS_INTEGER;
        l_graph_cnt   PLS_INTEGER;
    BEGIN
        IF i_loader IS NOT NULL
        THEN
            --check the correct subject based on the provided loader
            l_subject := CASE i_loader
                             WHEN g_per_obs_loader THEN
                              l_per_obs_subject
                             WHEN g_per_obs_preg_loader THEN
                              l_per_obs_pregn_subject
                             WHEN g_per_obs_medical_order THEN
                              l_per_obs_medical_order
                         END;
        ELSE
            l_subject := 'PER_OBS_VIEW';
        END IF;
    
        IF i_loader IS NOT NULL
        THEN
            --check the correct deafult view based on the provided loader
            g_error       := 'get default view';
            l_af_view_def := CASE i_loader
                                 WHEN g_per_obs_loader THEN
                                  pk_sysconfig.get_config(i_code_cf => g_cfg_default_view, i_prof => i_prof)
                                 WHEN g_per_obs_preg_loader THEN
                                  pk_sysconfig.get_config(i_code_cf => g_cfg_default_view_pregn, i_prof => i_prof)
                                 WHEN g_per_obs_medical_order THEN
                                  pk_sysconfig.get_config(i_code_cf => g_cfg_default_view, i_prof => i_prof)
                             END;
        ELSE
            -- get the default view's file identifier
            g_error       := 'CALL pk_sysconfig.get_config';
            l_af_view_def := pk_sysconfig.get_config(i_code_cf => g_cfg_default_view, i_prof => i_prof);
        END IF;
    
        -- get actions (the views buttons is based on the action framework)
        g_error   := 'CALL pk_action.tf_get_actions';
        l_actions := pk_action.tf_get_actions(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_subject    => l_subject,
                                              i_from_state => NULL);
    
        -- get the views files
        g_error := 'CALL pk_progress_notes.get_swf_file';
    
        l_view_def   := pk_progress_notes_upd.get_app_file(i_app_file => l_af_view_def);
        l_view_hpg   := pk_progress_notes_upd.get_app_file(i_app_file => l_af_view_hpg);
        l_view_graph := pk_progress_notes_upd.get_app_file(i_app_file => l_af_view_graph);
    
        -- get health programs count
        g_error := 'CALL pk_health_program.get_pat_hpgs';
    
        l_temp := pk_health_program.get_pat_hpgs(i_prof       => i_prof,
                                                 i_patient    => i_patient,
                                                 i_exc_status => table_varchar(pk_health_program.g_flg_status_cancelled,
                                                                               pk_health_program.g_flg_status_inactive));
    
        l_hpg_cnt := l_temp.count;
    
        -- get available growth charts count
        g_error := 'CALL pk_vital_sign.get_graphics_by_patient';
        IF NOT pk_vital_sign.get_graphics_by_patient(i_lang    => i_lang,
                                                     i_prof    => i_prof,
                                                     i_patient => i_patient,
                                                     o_graphs  => l_temp,
                                                     o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
        l_graph_cnt := l_temp.count;
    
        g_error := 'OPEN o_views';
    
        OPEN o_views FOR
            SELECT a.id_action,
                   a.id_parent,
                   a.level_nr "LEVEL",
                   NULL from_state,
                   a.to_state,
                   a.desc_action,
                   a.icon,
                   CASE
                        WHEN a.action = l_view_def THEN
                         CASE
                             WHEN a.action = l_view_hpg
                                  AND a.flg_active = pk_alert_constant.g_active
                                  AND l_hpg_cnt < 1 THEN
                              pk_alert_constant.g_no
                             ELSE
                              pk_alert_constant.g_yes
                         END
                        ELSE
                         a.flg_default
                    END flg_default,
                   CASE
                        WHEN a.action = l_view_hpg
                             AND a.flg_active = pk_alert_constant.g_active
                             AND l_hpg_cnt < 1 THEN
                         pk_alert_constant.g_inactive
                        WHEN a.action = l_view_graph
                             AND a.flg_active = pk_alert_constant.g_active
                             AND l_graph_cnt < 1 THEN
                         pk_alert_constant.g_inactive
                        ELSE
                         a.flg_active
                    END flg_active,
                   a.action action
              FROM TABLE(l_actions) a;
    
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_views;

    /**
    * Set parameter for patient.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_parameters   local parameter identifiers
    * @param i_types        parameter type flags
    * @param i_sample_type  Analysis parameter
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/22
    */
    FUNCTION set_parameter
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_parameters    IN table_number,
        i_types         IN table_varchar,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2,
        i_sample_type   IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PARAMETER';
        l_params table_number;
        l_owners table_number;
        l_rows   table_varchar;
    
        CURSOR c_local
        (
            i_type        IN po_param.flg_type%TYPE,
            i_parameter   IN po_param.id_parameter%TYPE,
            i_sample_type IN po_param.id_sample_type%TYPE
        ) IS
            SELECT g_ft_adv_input flg_fill_type, a.rank, a.id_content
              FROM analysis_sample_type ast
              JOIN analysis a
                ON a.id_analysis = ast.id_analysis
             WHERE a.id_analysis = i_parameter
               AND a.flg_available = pk_alert_constant.g_yes
               AND i_type = g_analysis
               AND ast.id_sample_type = i_sample_type
            UNION ALL
            SELECT g_ft_multichoice flg_fill_type, e.rank, e.id_content
              FROM exam e
             WHERE e.id_exam = i_parameter
               AND e.flg_available = pk_alert_constant.g_yes
               AND i_type = g_exam
            UNION ALL
            SELECT decode(vs.flg_fill_type,
                          pk_alert_constant.g_vs_ft_bar_keypad,
                          g_ft_keypad,
                          pk_alert_constant.g_vs_ft_keypad,
                          g_ft_keypad,
                          pk_alert_constant.g_vs_ft_scale,
                          g_ft_scale,
                          pk_alert_constant.g_vs_ft_multichoice,
                          g_ft_multichoice) flg_fill_type,
                   vs.rank,
                   vs.id_content
              FROM vital_sign vs
             WHERE vs.id_vital_sign = i_parameter
               AND vs.flg_available = pk_alert_constant.g_yes
               AND i_type = g_vital_sign
            UNION ALL
            SELECT g_ft_keypad flg_fill_type, h.rank, h.id_content
              FROM habit h
             WHERE h.id_habit = i_parameter
               AND h.flg_available = pk_alert_constant.g_yes
               AND i_type = g_habit
            UNION ALL
            SELECT pp.flg_fill_type, pp.rank, pp.id_content
              FROM po_param pp
             WHERE pp.id_po_param = i_parameter
               AND pp.flg_available = pk_alert_constant.g_yes
               AND i_type = g_others;
    
        r_param c_pop_param%ROWTYPE;
        r_local c_local%ROWTYPE;
    BEGIN
        -- validate arguments
        IF i_parameters IS NULL
           OR i_parameters.count < 1
           OR i_types IS NULL
           OR i_types.count < 1
           OR i_parameters.count != i_types.count
        THEN
            RAISE g_fault;
        END IF;
    
        -- extend collections
        l_params := table_number();
        l_params.extend(i_parameters.count);
        l_owners := table_number();
        l_owners.extend(i_parameters.count);
    
        FOR i IN i_parameters.first .. i_parameters.last
        LOOP
            -- check if parameter is registered in per.obs. model
            g_error := 'OPEN c_pop_param';
            OPEN c_pop_param(i_type        => i_types(i),
                             i_parameter   => i_parameters(i),
                             i_owner       => i_prof.institution,
                             i_sample_type => i_sample_type(i));
            FETCH c_pop_param
                INTO r_param;
            g_found := c_pop_param%FOUND;
            CLOSE c_pop_param;
        
            IF g_found
            THEN
                -- if registered, push to collections
                l_params(i) := r_param.id_po_param;
                l_owners(i) := r_param.id_inst_owner;
            ELSE
                -- if not registered, create it and push to collections
                g_error := 'OPEN c_local';
                OPEN c_local(i_type => i_types(i), i_parameter => i_parameters(i), i_sample_type => i_sample_type(i));
                FETCH c_local
                    INTO r_local;
                CLOSE c_local;
            
                g_error := 'SELECT l_params(i)';
                SELECT seq_po_param.nextval
                  INTO l_params(i)
                  FROM dual;
                l_owners(i) := i_prof.institution;
            
                g_error := 'CALL ts_po_param.ins';
                ts_po_param.ins(id_po_param_in    => l_params(i),
                                id_inst_owner_in  => l_owners(i),
                                code_po_param_in  => 'PO_PARAM.CODE_PO_PARAM.' || l_params(i),
                                flg_type_in       => i_types(i),
                                id_parameter_in   => i_parameters(i),
                                flg_fill_type_in  => r_local.flg_fill_type,
                                rank_in           => r_local.rank,
                                flg_available_in  => pk_alert_constant.g_yes,
                                id_content_in     => r_local.id_content,
                                id_sample_type_in => i_sample_type(i),
                                rows_out          => l_rows);
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PO_PARAM',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            END IF;
        END LOOP;
    
        -- set parameters visible for patient
        set_parameter_int(i_lang          => i_lang,
                          i_prof          => i_prof,
                          i_patient       => i_patient,
                          i_params        => l_params,
                          i_owners        => l_owners,
                          i_flg_visible   => pk_alert_constant.g_yes,
                          i_pat_pregnancy => i_pat_pregnancy,
                          i_owner         => i_owner);
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_parameter;

    /**
    * Set parameters for patient. Internal use only.
    *
    * @param i_patient      patient identifier
    * @param i_params       parameter identifiers
    * @param i_owners       owner identifiers
    * @param i_flg_visible  parameter visibility (Y/N)
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/22
    */
    PROCEDURE set_parameter_int
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_params        IN table_number,
        i_owners        IN table_number,
        i_flg_visible   IN pat_po_param.flg_visible%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2
    ) IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PARAMETER_INT';
        l_rows      table_varchar;
        l_flg_owner preg_po_param.flg_owner%TYPE;
        l_error     t_error_out;
    BEGIN
        -- validate arguments
        IF i_params IS NULL
           OR i_params.count < 1
           OR i_owners IS NULL
           OR i_owners.count < 1
           OR i_params.count != i_owners.count
        THEN
            g_error := 'Invalid arguments!';
            RAISE g_fault;
        END IF;
    
        IF i_owner = g_parameter_mother
        THEN
            l_flg_owner := g_flg_owner_m;
        ELSIF i_owner = g_parameter_fetus
        THEN
            l_flg_owner := g_flg_owner_f;
        ELSIF i_pat_pregnancy IS NOT NULL
        THEN
            g_error := 'Invalid arguments!';
            RAISE g_fault;
        END IF;
    
        -- debug arguments
        g_error := 'i_patient: ' || i_patient;
        g_error := g_error || ', i_flg_visible: ' || i_flg_visible;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        FOR i IN i_params.first .. i_params.last
        LOOP
            -- debug collection arguments
            g_error := 'i_params(i): ' || i_params(i);
            g_error := g_error || ', i_owners(i): ' || i_owners(i);
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            IF i_pat_pregnancy IS NOT NULL
            THEN
                g_error := 'CALL ts_preg_po_param.upd_ins';
                ts_preg_po_param.upd_ins(id_pat_pregnancy_in => i_pat_pregnancy,
                                         id_po_param_in      => i_params(i),
                                         id_inst_owner_in    => i_owners(i),
                                         flg_visible_in      => i_flg_visible,
                                         flg_owner_in        => l_flg_owner,
                                         rows_out            => l_rows);
            
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PREG_PO_PARAM',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            
            ELSE
                g_error := 'CALL ts_pat_po_param.upd_ins';
                ts_pat_po_param.upd_ins(id_patient_in    => i_patient,
                                        id_po_param_in   => i_params(i),
                                        id_inst_owner_in => i_owners(i),
                                        flg_visible_in   => i_flg_visible,
                                        rows_out         => l_rows);
            
                g_error := 'CALL t_data_gov_mnt.process_insert';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PAT_PO_PARAM',
                                              i_rowids     => l_rows,
                                              o_error      => l_error);
            END IF;
        END LOOP;
    END set_parameter_int;

    /**
    * Set values with keypad.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_params       parameter identifiers
    * @param i_owners       owner identifiers
    * @param i_results      result descriptions list
    * @param i_unit_mea     measurement units list
    * @param i_date         observation date
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/26
    */
    FUNCTION set_value_k
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_results         IN table_varchar,
        i_unit_mea        IN table_number,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_K';
        l_parameter          po_param.id_parameter%TYPE;
        l_flg_type           po_param.flg_type%TYPE;
        l_dt_result          po_param_reg.dt_result%TYPE;
        l_popr               po_param_reg.id_po_param_reg%TYPE;
        l_rows               table_varchar;
        l_notes              pat_habit.notes%TYPE;
        l_ref                VARCHAR(1 CHAR) := pk_alert_constant.g_no;
        l_id_pat_pregnancy   pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
        tb_id_po_param_reg   table_number;
        tb_flg_type          table_varchar;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        IF i_date = g_ref_value
        THEN
            l_ref := pk_alert_constant.g_yes;
        ELSE
            l_dt_result := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_timestamp => i_date,
                                                         i_timezone  => NULL);
        END IF;
    
        -- validate arguments
        IF i_params IS NULL
           OR i_params.count < 1
           OR i_owners IS NULL
           OR i_owners.count < 1
           OR i_params.count != i_owners.count
        THEN
            g_error := 'Invalid arguments!';
            RAISE g_fault;
        END IF;
    
        IF i_woman_health_id IS NOT NULL
        THEN
            g_error := 'CALL split_woman_health_id';
            IF NOT split_woman_health_id(i_woman_health_id    => i_woman_health_id,
                                         o_id_pat_pregnancy   => l_id_pat_pregnancy,
                                         o_id_pat_pregn_fetus => l_id_pat_pregn_fetus)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        FOR i IN i_params.first .. i_params.last
        LOOP
            -- get parameter identifier and type
            g_error := 'OPEN c_pop_pk';
            OPEN c_pop_pk(i_param => i_params(i), i_owner => i_owners(i));
            FETCH c_pop_pk
                INTO l_parameter, l_flg_type;
            CLOSE c_pop_pk;
        
            IF l_flg_type IN (g_habit, g_others)
            THEN
                l_rows := table_varchar();
                l_popr := ts_po_param_reg.next_key;
            
                IF i_date = g_ref_value
                THEN
                    g_error := 'get tb_id_po_param_reg';
                    BEGIN
                        SELECT ppr.id_po_param_reg, g_others
                          BULK COLLECT
                          INTO tb_id_po_param_reg, tb_flg_type
                          FROM po_param_reg ppr
                         WHERE ppr.id_po_param = i_params(i)
                           AND ppr.id_inst_owner = i_owners(i)
                           AND ppr.id_patient = i_patient
                           AND ppr.flg_ref_value = l_ref
                           AND ppr.flg_status = pk_alert_constant.g_active
                           AND nvl(ppr.id_pat_pregn_fetus, -1) = nvl(l_id_pat_pregn_fetus, -1);
                    EXCEPTION
                        WHEN no_data_found THEN
                            tb_id_po_param_reg := table_number();
                            tb_flg_type        := table_varchar();
                    END;
                
                    IF tb_id_po_param_reg.count > 0
                    THEN
                        g_error := 'call cancel_value';
                        IF NOT cancel_value(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_prof_cat    => i_prof_cat,
                                            i_episode     => i_episode,
                                            i_patient     => i_patient,
                                            i_values      => tb_id_po_param_reg,
                                            i_types       => tb_flg_type,
                                            i_canc_reason => NULL,
                                            i_canc_notes  => NULL,
                                            i_ref_value   => pk_alert_constant.g_yes,
                                            o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                END IF;
            
                -- create value record
                g_error := 'CALL ts_po_param_reg.ins';
                ts_po_param_reg.ins(id_po_param_reg_in    => l_popr,
                                    id_po_param_in        => i_params(i),
                                    id_inst_owner_in      => i_owners(i),
                                    id_patient_in         => i_patient,
                                    id_episode_in         => i_episode,
                                    dt_creation_in        => g_sysdate_tstz,
                                    dt_result_in          => l_dt_result,
                                    flg_origin_in         => g_orig_manual,
                                    value_in              => i_results(i),
                                    id_unit_measure_in    => i_unit_mea(i),
                                    id_professional_in    => i_prof.id,
                                    flg_status_in         => pk_alert_constant.g_active,
                                    flg_screen_in         => CASE
                                                                 WHEN i_woman_health_id IS NULL THEN
                                                                  g_flg_screen_po
                                                                 ELSE
                                                                  g_flg_screen_wh
                                                             END,
                                    id_pat_pregn_fetus_in => l_id_pat_pregn_fetus,
                                    flg_ref_value_in      => l_ref,
                                    rows_out              => l_rows);
                g_error := 'CALL t_data_gov_mnt.process_insert 1';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PO_PARAM_REG',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
                IF l_flg_type = g_habit
                THEN
                    l_notes := get_habit_notes(i_lang  => i_lang,
                                               i_value => i_results(i),
                                               i_um    => i_unit_mea(i),
                                               i_popmc => NULL);
                
                    set_pat_habit_obs_per(i_lang       => i_lang,
                                          i_epis       => i_episode,
                                          i_id_patient => i_patient,
                                          i_id_habit   => l_parameter,
                                          i_prof       => i_prof,
                                          i_notes      => l_notes,
                                          i_dt_begin   => l_dt_result,
                                          o_error      => o_error);
                END IF;
            
            ELSE
                -- specified type is not supported in this function
                g_error := 'Unsupported type: ' || nvl(l_flg_type, 'NULL') || '!';
                RAISE g_fault;
            END IF;
        END LOOP;
    
        IF NOT get_values_return(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_patient         => i_patient,
                                 i_episode         => i_episode,
                                 i_params          => i_params,
                                 i_date            => i_date,
                                 i_woman_health_id => i_woman_health_id,
                                 o_value           => o_value,
                                 o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_k;
    -----------------------------------------
    FUNCTION set_value_t
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_results         IN table_clob,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_T';
        l_parameter          po_param.id_parameter%TYPE;
        l_flg_type           po_param.flg_type%TYPE;
        l_dt_result          po_param_reg.dt_result%TYPE;
        l_popr               po_param_reg.id_po_param_reg%TYPE;
        l_rows               table_varchar;
        l_ref                VARCHAR(1 CHAR) := pk_alert_constant.g_no;
        l_id_pat_pregnancy   pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
        tb_id_po_param_reg   table_number;
        tb_flg_type          table_varchar;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        IF i_date = g_ref_value
        THEN
            l_ref := pk_alert_constant.g_yes;
        ELSE
            l_dt_result := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_timestamp => i_date,
                                                         i_timezone  => NULL);
        END IF;
    
        -- validate arguments
        IF i_params IS NULL
           OR i_params.count < 1
           OR i_owners IS NULL
           OR i_owners.count < 1
           OR i_params.count != i_owners.count
        THEN
            g_error := 'Invalid arguments!';
            RAISE g_fault;
        END IF;
    
        IF i_woman_health_id IS NOT NULL
        THEN
            g_error := 'CALL split_woman_health_id';
            IF NOT split_woman_health_id(i_woman_health_id    => i_woman_health_id,
                                         o_id_pat_pregnancy   => l_id_pat_pregnancy,
                                         o_id_pat_pregn_fetus => l_id_pat_pregn_fetus)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        FOR i IN i_params.first .. i_params.last
        LOOP
            -- get parameter identifier and type
            g_error := 'OPEN c_pop_pk';
            OPEN c_pop_pk(i_param => i_params(i), i_owner => i_owners(i));
            FETCH c_pop_pk
                INTO l_parameter, l_flg_type;
            CLOSE c_pop_pk;
        
            IF l_flg_type IN (g_others)
            THEN
                l_rows := table_varchar();
                l_popr := ts_po_param_reg.next_key;
            
                IF i_date = g_ref_value
                THEN
                    g_error := 'get tb_id_po_param_reg';
                    BEGIN
                        SELECT ppr.id_po_param_reg, g_others
                          BULK COLLECT
                          INTO tb_id_po_param_reg, tb_flg_type
                          FROM po_param_reg ppr
                         WHERE ppr.id_po_param = i_params(i)
                           AND ppr.id_inst_owner = i_owners(i)
                           AND ppr.id_patient = i_patient
                           AND ppr.flg_ref_value = l_ref
                           AND ppr.flg_status = pk_alert_constant.g_active
                           AND nvl(ppr.id_pat_pregn_fetus, -1) = nvl(l_id_pat_pregn_fetus, -1);
                    EXCEPTION
                        WHEN no_data_found THEN
                            tb_id_po_param_reg := table_number();
                            tb_flg_type        := table_varchar();
                    END;
                
                    IF tb_id_po_param_reg.count > 0
                    THEN
                        g_error := 'call cancel_value';
                        IF NOT cancel_value(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_prof_cat    => i_prof_cat,
                                            i_episode     => i_episode,
                                            i_patient     => i_patient,
                                            i_values      => tb_id_po_param_reg,
                                            i_types       => tb_flg_type,
                                            i_canc_reason => NULL,
                                            i_canc_notes  => NULL,
                                            i_ref_value   => pk_alert_constant.g_yes,
                                            o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                END IF;
            
                -- create value record
                g_error := 'CALL ts_po_param_reg.ins';
                ts_po_param_reg.ins(id_po_param_reg_in    => l_popr,
                                    id_po_param_in        => i_params(i),
                                    id_inst_owner_in      => i_owners(i),
                                    id_patient_in         => i_patient,
                                    id_episode_in         => i_episode,
                                    dt_creation_in        => g_sysdate_tstz,
                                    dt_result_in          => l_dt_result,
                                    flg_origin_in         => g_orig_manual,
                                    free_text_in          => i_results(i),
                                    id_professional_in    => i_prof.id,
                                    flg_status_in         => pk_alert_constant.g_active,
                                    flg_screen_in         => CASE
                                                                 WHEN i_woman_health_id IS NULL THEN
                                                                  g_flg_screen_po
                                                                 ELSE
                                                                  g_flg_screen_wh
                                                             END,
                                    id_pat_pregn_fetus_in => l_id_pat_pregn_fetus,
                                    flg_ref_value_in      => l_ref,
                                    rows_out              => l_rows);
                g_error := 'CALL t_data_gov_mnt.process_insert 1';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PO_PARAM_REG',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            ELSE
                -- specified type is not supported in this function
                g_error := 'Unsupported type: ' || nvl(l_flg_type, 'NULL') || '!';
                RAISE g_fault;
            END IF;
        END LOOP;
    
        IF NOT get_values_return(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_patient         => i_patient,
                                 i_episode         => i_episode,
                                 i_params          => i_params,
                                 i_date            => i_date,
                                 i_woman_health_id => i_woman_health_id,
                                 o_value           => o_value,
                                 o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_t;
    -------------------------------------------------------------
    FUNCTION set_value_d
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_dates           IN table_varchar,
        i_dates_mask      IN table_varchar,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_value_d';
        l_parameter          po_param.id_parameter%TYPE;
        l_flg_type           po_param.flg_type%TYPE;
        l_dt_result          po_param_reg.dt_result%TYPE;
        l_popr               po_param_reg.id_po_param_reg%TYPE;
        l_rows               table_varchar;
        l_ref                VARCHAR(1 CHAR) := pk_alert_constant.g_no;
        l_id_pat_pregnancy   pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE := NULL;
        tb_id_po_param_reg   table_number;
        tb_flg_type          table_varchar;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        IF i_date = g_ref_value
        THEN
            l_ref := pk_alert_constant.g_yes;
        ELSE
            l_dt_result := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_timestamp => i_date,
                                                         i_timezone  => NULL);
        END IF;
    
        -- validate arguments
        IF i_params IS NULL
           OR i_params.count < 1
           OR i_owners IS NULL
           OR i_owners.count < 1
           OR i_params.count != i_owners.count
        THEN
            g_error := 'Invalid arguments!';
            RAISE g_fault;
        END IF;
    
        IF i_woman_health_id IS NOT NULL
        THEN
            g_error := 'CALL split_woman_health_id';
            IF NOT split_woman_health_id(i_woman_health_id    => i_woman_health_id,
                                         o_id_pat_pregnancy   => l_id_pat_pregnancy,
                                         o_id_pat_pregn_fetus => l_id_pat_pregn_fetus)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        FOR i IN i_params.first .. i_params.last
        LOOP
            -- get parameter identifier and type
            g_error := 'OPEN c_pop_pk';
            OPEN c_pop_pk(i_param => i_params(i), i_owner => i_owners(i));
            FETCH c_pop_pk
                INTO l_parameter, l_flg_type;
            CLOSE c_pop_pk;
        
            IF l_flg_type IN (g_others)
            THEN
                l_rows := table_varchar();
                l_popr := ts_po_param_reg.next_key;
            
                IF i_date = g_ref_value
                THEN
                    g_error := 'get tb_id_po_param_reg';
                    BEGIN
                        SELECT ppr.id_po_param_reg, g_others
                          BULK COLLECT
                          INTO tb_id_po_param_reg, tb_flg_type
                          FROM po_param_reg ppr
                         WHERE ppr.id_po_param = i_params(i)
                           AND ppr.id_inst_owner = i_owners(i)
                           AND ppr.id_patient = i_patient
                           AND ppr.flg_ref_value = l_ref
                           AND ppr.flg_status = pk_alert_constant.g_active
                           AND nvl(ppr.id_pat_pregn_fetus, -1) = nvl(l_id_pat_pregn_fetus, -1);
                    EXCEPTION
                        WHEN no_data_found THEN
                            tb_id_po_param_reg := table_number();
                            tb_flg_type        := table_varchar();
                    END;
                
                    IF tb_id_po_param_reg.count > 0
                    THEN
                        g_error := 'call cancel_value';
                        IF NOT cancel_value(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_prof_cat    => i_prof_cat,
                                            i_episode     => i_episode,
                                            i_patient     => i_patient,
                                            i_values      => tb_id_po_param_reg,
                                            i_types       => tb_flg_type,
                                            i_canc_reason => NULL,
                                            i_canc_notes  => NULL,
                                            i_ref_value   => pk_alert_constant.g_yes,
                                            o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                END IF;
            
                -- create value record
                g_error := 'CALL ts_po_param_reg.ins';
                ts_po_param_reg.ins(id_po_param_reg_in    => l_popr,
                                    id_po_param_in        => i_params(i),
                                    id_inst_owner_in      => i_owners(i),
                                    id_patient_in         => i_patient,
                                    id_episode_in         => i_episode,
                                    dt_creation_in        => g_sysdate_tstz,
                                    dt_result_in          => l_dt_result,
                                    flg_origin_in         => g_orig_manual,
                                    free_date_in          => i_dates(i),
                                    free_date_mask_in     => i_dates_mask(i),
                                    id_professional_in    => i_prof.id,
                                    flg_status_in         => pk_alert_constant.g_active,
                                    flg_screen_in         => CASE
                                                                 WHEN i_woman_health_id IS NULL THEN
                                                                  g_flg_screen_po
                                                                 ELSE
                                                                  g_flg_screen_wh
                                                             END,
                                    id_pat_pregn_fetus_in => l_id_pat_pregn_fetus,
                                    flg_ref_value_in      => l_ref,
                                    rows_out              => l_rows);
                g_error := 'CALL t_data_gov_mnt.process_insert 1';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PO_PARAM_REG',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            ELSE
                -- specified type is not supported in this function
                g_error := 'Unsupported type: ' || nvl(l_flg_type, 'NULL') || '!';
                RAISE g_fault;
            END IF;
        END LOOP;
    
        IF NOT get_values_return(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_patient         => i_patient,
                                 i_episode         => i_episode,
                                 i_params          => i_params,
                                 i_date            => i_date,
                                 i_woman_health_id => i_woman_health_id,
                                 o_value           => o_value,
                                 o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_d;
    /**
    * Set values with multichoice.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_params       parameter identifiers
    * @param i_owners       owner identifiers
    * @param i_options      multichoice options list
    * @param i_a_req_dets   lab test request details
    * @param i_date         observation date
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/27
    */
    FUNCTION set_value_m
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_owners          IN table_number,
        i_options         IN table_table_number,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE';
        l_parameter          po_param.id_parameter%TYPE;
        l_flg_type           po_param.flg_type%TYPE;
        l_dt_result          po_param_reg.dt_result%TYPE;
        l_popr               po_param_reg.id_po_param_reg%TYPE;
        l_poprmc_row         po_param_reg_mc%ROWTYPE;
        l_poprmc_rows        ts_po_param_reg_mc.po_param_reg_mc_tc;
        l_notes              pat_habit.notes%TYPE;
        l_rows               table_varchar;
        l_ref                VARCHAR(1 CHAR) := pk_alert_constant.g_no;
        l_id_pat_pregnancy   pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
        tb_id_po_param_reg   table_number;
        tb_flg_type          table_varchar;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        IF i_date = g_ref_value
        THEN
            l_ref := pk_alert_constant.g_yes;
        ELSE
            l_dt_result := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                         i_prof      => i_prof,
                                                         i_timestamp => i_date,
                                                         i_timezone  => NULL);
        END IF;
    
        -- validate arguments
        IF i_params IS NULL
           OR i_params.count < 1
           OR i_owners IS NULL
           OR i_owners.count < 1
           OR i_params.count != i_owners.count
        THEN
            g_error := 'Invalid arguments!';
            RAISE g_fault;
        END IF;
    
        IF i_woman_health_id IS NOT NULL
        THEN
            g_error := 'CALL split_woman_health_id';
            IF NOT split_woman_health_id(i_woman_health_id    => i_woman_health_id,
                                         o_id_pat_pregnancy   => l_id_pat_pregnancy,
                                         o_id_pat_pregn_fetus => l_id_pat_pregn_fetus)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        FOR i IN i_params.first .. i_params.last
        LOOP
            -- get parameter identifier and type
            g_error := 'OPEN c_pop_pk';
            OPEN c_pop_pk(i_param => i_params(i), i_owner => i_owners(i));
            FETCH c_pop_pk
                INTO l_parameter, l_flg_type;
            CLOSE c_pop_pk;
        
            IF l_flg_type IN (g_habit, g_others)
            THEN
                l_popr := ts_po_param_reg.next_key;
                l_rows := table_varchar();
            
                IF i_date = g_ref_value
                THEN
                    g_error := 'get tb_id_po_param_reg';
                    BEGIN
                        SELECT ppr.id_po_param_reg, g_others
                          BULK COLLECT
                          INTO tb_id_po_param_reg, tb_flg_type
                          FROM po_param_reg ppr
                         WHERE ppr.id_po_param = i_params(i)
                           AND ppr.id_inst_owner = i_owners(i)
                           AND ppr.id_patient = i_patient
                           AND ppr.flg_ref_value = l_ref
                           AND ppr.flg_status = pk_alert_constant.g_active
                           AND nvl(ppr.id_pat_pregn_fetus, -1) = nvl(l_id_pat_pregn_fetus, -1);
                    EXCEPTION
                        WHEN no_data_found THEN
                            tb_id_po_param_reg := table_number();
                            tb_flg_type        := table_varchar();
                    END;
                
                    IF tb_id_po_param_reg.count > 0
                    THEN
                        g_error := 'call cancel_value';
                        IF NOT cancel_value(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_prof_cat    => i_prof_cat,
                                            i_episode     => i_episode,
                                            i_patient     => i_patient,
                                            i_values      => tb_id_po_param_reg,
                                            i_types       => tb_flg_type,
                                            i_canc_reason => NULL,
                                            i_canc_notes  => NULL,
                                            i_ref_value   => pk_alert_constant.g_yes,
                                            o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                END IF;
            
                -- create value record
                g_error := 'CALL ts_po_param_reg.ins';
                ts_po_param_reg.ins(id_po_param_reg_in    => l_popr,
                                    id_po_param_in        => i_params(i),
                                    id_inst_owner_in      => i_owners(i),
                                    id_patient_in         => i_patient,
                                    id_episode_in         => i_episode,
                                    dt_creation_in        => g_sysdate_tstz,
                                    dt_result_in          => l_dt_result,
                                    flg_origin_in         => g_orig_manual,
                                    id_professional_in    => i_prof.id,
                                    flg_status_in         => pk_alert_constant.g_active,
                                    flg_screen_in         => CASE
                                                                 WHEN i_woman_health_id IS NULL THEN
                                                                  g_flg_screen_po
                                                                 ELSE
                                                                  g_flg_screen_wh
                                                             END,
                                    id_pat_pregn_fetus_in => l_id_pat_pregn_fetus,
                                    flg_ref_value_in      => l_ref,
                                    rows_out              => l_rows);
                g_error := 'CALL t_data_gov_mnt.process_insert 1';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'PO_PARAM_REG',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
                -- create options records
                IF i_options IS NOT NULL
                   AND i_options.exists(i)
                THEN
                    l_poprmc_rows.delete;
                    l_poprmc_row.id_po_param_reg := l_popr;
                
                    FOR j IN 1 .. i_options(i).count
                    LOOP
                        l_poprmc_row.id_po_param_mc := i_options(i) (j);
                    
                        l_poprmc_rows(j) := l_poprmc_row;
                    END LOOP;
                
                    l_rows  := table_varchar();
                    g_error := 'CALL ts_po_param_reg_mc.ins';
                    ts_po_param_reg_mc.ins(rows_in => l_poprmc_rows, rows_out => l_rows);
                    g_error := 'CALL t_data_gov_mnt.process_insert 2';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PO_PARAM_REG_MC',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                
                    IF l_flg_type = g_habit
                    THEN
                        l_notes := get_habit_notes(i_lang  => i_lang,
                                                   i_value => NULL,
                                                   i_um    => NULL,
                                                   i_popmc => i_options(i));
                    
                        set_pat_habit_obs_per(i_lang       => i_lang,
                                              i_epis       => i_episode,
                                              i_id_patient => i_patient,
                                              i_id_habit   => l_parameter,
                                              i_prof       => i_prof,
                                              i_notes      => l_notes,
                                              i_dt_begin   => l_dt_result,
                                              o_error      => o_error);
                    END IF;
                END IF;
            
            ELSE
                -- specified type is not supported in this function
                g_error := 'Unsupported type: ' || nvl(l_flg_type, 'NULL') || '!';
                RAISE g_fault;
            END IF;
        END LOOP;
    
        IF NOT get_values_return(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_patient         => i_patient,
                                 i_episode         => i_episode,
                                 i_params          => i_params,
                                 i_date            => i_date,
                                 i_woman_health_id => i_woman_health_id,
                                 o_value           => o_value,
                                 o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL  pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => i_prof_cat,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            RETURN FALSE;
    END set_value_m;

    /*
    * Creates an order with a result for a given exam
    *
    * @param     i_lang                Language id
    * @param     i_prof                Professional
    * @param     i_patient             Patient id
    * @param     i_episode             Episode id
    * @param     i_exam_req_det        Exam detail order id
    * @param     i_reg                 Periodic observation id
    * @param     i_exam                Exams' id
    * @param     i_test                Flag that indicates if the exam is really to be ordered
    * @param     i_prof_performed      Professional perform id
    * @param     i_start_time          Exams' start time
    * @param     i_end_time            Exams' end time
    * @param     i_flg_result_origin   Flag that indicates what is the result's origin
    * @param     i_notes               Result notes
    * @param     i_flg_import          Flag that indicates if there is a document to import
    * @param     i_id_doc              Closing document id
    * @param     i_doc_type            Document type id
    * @param     i_desc_doc_type       Document type description
    * @param     i_dt_doc              Original document date
    * @param     i_dest                Destination id
    * @param     i_desc_dest           Destination description
    * @param     i_ori_type            Document type id
    * @param     i_desc_ori_doc_type   Document type description
    * @param     i_original            Original document id
    * @param     i_desc_original       Original document description
    * @param     i_btn                 Context
    * @param     i_title               Document description
    * @param     i_desc_perf_by        Performed by description
    * @param     i_woman_health_id     Woman health id
    * @param     o_flg_show            Flag that indicates if there is a message to be shown
    * @param     o_msg_title           Message title
    * @param     o_msg_req             Message to be shown
    * @param     o_button              Buttons to show
    * @param     o_exam_req            Exams' order id
    * @param     o_exam_req_det        Exams' order details id
    * @param     o_value               Value object,
    * @param     o_error               Error message
    *
    * @author               Jorge Silva
    * @version               2.5
    * @since                2013/04/09
    */
    FUNCTION set_value_exams
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN exam_req.id_episode%TYPE,
        i_exam_req_det        IN exam_req_det.id_exam_req_det%TYPE,
        i_reg                 IN periodic_observation_reg.id_periodic_observation_reg%TYPE,
        i_exam                IN exam.id_exam%TYPE,
        i_prof_performed      IN exam_req_det.id_prof_performed%TYPE,
        i_start_time          IN VARCHAR2,
        i_end_time            IN VARCHAR2,
        i_result_status       IN result_status.id_result_status%TYPE,
        i_abnormality         IN exam_result.id_abnormality%TYPE,
        i_flg_result_origin   IN exam_result.flg_result_origin%TYPE,
        i_result_origin_notes IN exam_result.result_origin_notes%TYPE,
        i_notes               IN exam_result.notes%TYPE,
        i_flg_import          IN table_varchar,
        i_id_doc              IN table_number,
        i_doc_type            IN table_number,
        i_desc_doc_type       IN table_varchar,
        i_dt_doc              IN table_varchar,
        i_dest                IN table_number,
        i_desc_dest           IN table_varchar,
        i_ori_doc_type        IN table_number,
        i_desc_ori_doc_type   IN table_varchar,
        i_original            IN table_number,
        i_desc_original       IN table_varchar,
        i_title               IN table_varchar,
        i_desc_perf_by        IN table_varchar,
        i_po_param            IN table_number,
        i_woman_health_id     IN VARCHAR2,
        o_exam_req            OUT exam_req.id_exam_req%TYPE,
        o_exam_req_det        OUT exam_req_det.id_exam_req_det%TYPE,
        o_value               OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_EXAMS';
    
    BEGIN
        g_error := 'CALL CREATE_EXAM_REQUEST';
    
        IF NOT pk_exam_core.create_exam_with_result(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_patient             => i_patient,
                                                    i_episode             => i_episode,
                                                    i_exam_req_det        => i_exam_req_det,
                                                    i_reg                 => i_reg,
                                                    i_exam                => i_exam,
                                                    i_prof_performed      => i_prof_performed,
                                                    i_start_time          => i_start_time,
                                                    i_end_time            => i_end_time,
                                                    i_result_status       => i_result_status,
                                                    i_abnormality         => i_abnormality,
                                                    i_flg_result_origin   => i_flg_result_origin,
                                                    i_result_origin_notes => i_result_origin_notes,
                                                    i_notes               => i_notes,
                                                    i_flg_import          => i_flg_import,
                                                    i_id_doc              => i_id_doc,
                                                    i_doc_type            => i_doc_type,
                                                    i_desc_doc_type       => i_desc_doc_type,
                                                    i_dt_doc              => i_dt_doc,
                                                    i_dest                => i_dest,
                                                    i_desc_dest           => i_desc_dest,
                                                    i_ori_doc_type        => i_ori_doc_type,
                                                    i_desc_ori_doc_type   => i_desc_ori_doc_type,
                                                    i_original            => i_original,
                                                    i_desc_original       => i_desc_original,
                                                    i_title               => i_title,
                                                    i_desc_perf_by        => i_desc_perf_by,
                                                    o_exam_req            => o_exam_req,
                                                    o_exam_req_det        => o_exam_req_det,
                                                    o_error               => o_error)
        
        THEN
            RAISE g_exception;
        END IF;
    
        IF NOT get_values_return(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_patient         => i_patient,
                                 i_episode         => i_episode,
                                 i_params          => i_po_param,
                                 i_date            => i_start_time,
                                 i_woman_health_id => i_woman_health_id,
                                 o_value           => o_value,
                                 o_error           => o_error)
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
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_value_exams;

    /******************************************************************************
    *
    * Create analysis results with/without analysis req also updates de results values
    * This development is for the complex analysis, inserting the results values partially
    *
    * @param i_lang                language
    * @param i_patient             id patient
    * @param i_analysis_req_par    id parameter request
    * @param i_par_analysis        id parameter analysis
    * @param i_prof                professional register
    * @param i_results             results
    * @param i_unit_measure        unit measure
    * @param i_ref_val_min         minimum reference value
    * @param i_ref_val_max         maximum reference value
    * @param i_date_str            date result
    * @param i_notes_doctor_registry   parameter notes
    * @param i_notes_results        result notes
    * @param i_episode              id episode
    * @param i_analysis_result_par  id results parameters
    * @param i_analysis             id analysis
    * @param i_parameter_notes      parameter notes
    * @param i_result_date          date results
    * @param i_prof_req             Id professional
    * @param i_flg_res_origin       flag of the analysis result origin
    * @param i_status               Status of the record N-New, E-Edited
    * @param i_analysis_req_det_id  analysis requisition detail id
    * @param i_orig                 origin of the screen: R request, H Timeline screen
    * @param i_woman_health_id      IN VARCHAR2,
    * @param o_value                Value object,
    * @param o_result               OUT VARCHAR2,
    * @param o_error                OUT t_error_out
    *
    * @return true/false
    *
    * @AUTHOR Jorge Silva
    * @VERSION 2.5.2
    * @SINCE 22/4/2013
    *
    *******************************************************************************/
    FUNCTION set_value_analysis
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN analysis_result.id_patient%TYPE,
        i_episode                IN analysis_result.id_episode%TYPE,
        i_analysis               IN analysis.id_analysis%TYPE,
        i_sample_type            IN sample_type.id_sample_type%TYPE,
        i_analysis_parameter     IN table_number,
        i_analysis_param         IN table_number,
        i_analysis_req_det       IN analysis_req_det.id_analysis_req_det%TYPE,
        i_analysis_req_par       IN table_number,
        i_analysis_result_par    IN table_number,
        i_flg_type               IN table_varchar,
        i_harvest                IN harvest.id_harvest%TYPE,
        i_dt_sample              IN VARCHAR2,
        i_prof_req               IN analysis_result.id_prof_req%TYPE,
        i_dt_analysis_result     IN VARCHAR2,
        i_flg_result_origin      IN analysis_result.flg_result_origin%TYPE,
        i_result_origin_notes    IN analysis_result.result_origin_notes%TYPE,
        i_result_notes           IN analysis_result.notes%TYPE,
        i_result                 IN table_varchar,
        i_analysis_desc          IN table_number,
        i_unit_measure           IN table_number,
        i_result_status          IN table_number,
        i_ref_val_min            IN table_varchar,
        i_ref_val_max            IN table_varchar,
        i_parameter_notes        IN table_varchar,
        i_flg_orig_analysis      IN VARCHAR2,
        i_clinical_decision_rule IN NUMBER,
        i_po_param               IN table_number,
        i_woman_health_id        IN VARCHAR2,
        o_value                  OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_VALUE_ANALYSIS';
        o_result VARCHAR2(5000);
    
    BEGIN
        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_RESULT';
        IF NOT pk_lab_tests_core.set_lab_test_result(i_lang                       => i_lang,
                                                     i_prof                       => i_prof,
                                                     i_patient                    => i_patient,
                                                     i_episode                    => i_episode,
                                                     i_analysis                   => i_analysis,
                                                     i_sample_type                => i_sample_type,
                                                     i_analysis_parameter         => i_analysis_parameter,
                                                     i_analysis_param             => i_analysis_param,
                                                     i_analysis_req_det           => i_analysis_req_det,
                                                     i_analysis_req_par           => i_analysis_req_par,
                                                     i_analysis_result_par        => i_analysis_result_par,
                                                     i_analysis_result_par_parent => NULL,
                                                     i_flg_type                   => i_flg_type,
                                                     i_harvest                    => i_harvest,
                                                     i_dt_sample                  => i_dt_sample,
                                                     i_prof_req                   => i_prof_req,
                                                     i_dt_analysis_result         => i_dt_analysis_result,
                                                     i_flg_result_origin          => i_flg_result_origin,
                                                     i_result_origin_notes        => i_result_origin_notes,
                                                     i_result_notes               => i_result_notes,
                                                     i_loinc_code                 => NULL,
                                                     i_dt_ext_registry            => NULL,
                                                     i_instit_origin              => NULL,
                                                     i_result_value_1             => i_result,
                                                     i_analysis_desc              => i_analysis_desc,
                                                     i_unit_measure               => i_unit_measure,
                                                     i_desc_unit_measure          => NULL,
                                                     i_result_status              => i_result_status,
                                                     i_ref_val                    => NULL,
                                                     i_ref_val_min                => i_ref_val_min,
                                                     i_ref_val_max                => i_ref_val_max,
                                                     i_parameter_notes            => i_parameter_notes,
                                                     i_interface_notes            => NULL,
                                                     i_laboratory_desc            => NULL,
                                                     i_laboratory_short_desc      => NULL,
                                                     i_coding_system              => NULL,
                                                     i_method                     => NULL,
                                                     i_equipment                  => NULL,
                                                     i_abnormality                => NULL,
                                                     i_abnormality_nature         => NULL,
                                                     i_prof_validation            => NULL,
                                                     i_dt_validation              => NULL,
                                                     i_flg_orig_analysis          => i_flg_orig_analysis,
                                                     i_clinical_decision_rule     => i_clinical_decision_rule,
                                                     o_result                     => o_result,
                                                     o_error                      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        IF NOT get_values_return(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_patient         => i_patient,
                                 i_episode         => i_episode,
                                 i_params          => i_po_param,
                                 i_date            => i_dt_analysis_result,
                                 i_woman_health_id => i_woman_health_id,
                                 o_value           => o_value,
                                 o_error           => o_error)
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
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_value_analysis;

    /**
    * Get woman health grid.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param o_wh           woman health
    * @param o_param        parameters
    * @param o_wh_param     woman health parameters
    * @param o_time         times
    * @param o_value        values
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.5
    * @since                2013/02/18
    */
    FUNCTION get_grid_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_cursor_out    IN VARCHAR2 DEFAULT 'A',
        o_wh            OUT pk_types.cursor_type,
        o_param         OUT pk_types.cursor_type,
        o_wh_param      OUT pk_types.cursor_type,
        o_time          OUT pk_types.cursor_type,
        o_value         OUT pk_types.cursor_type,
        o_values_wh     OUT t_coll_wh_values,
        o_ref           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_GRID_WH';
        l_params         t_coll_po_param;
        l_med_data       t_tbl_rec_sum_act_meds;
        l_values         t_coll_po_value;
        l_dt_ini         pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_fim         pat_pregnancy.dt_init_pregnancy%TYPE;
        l_mother         sys_message.desc_message%TYPE;
        l_fetu           sys_message.desc_message%TYPE;
        l_show_ref_value sys_config.value%TYPE;
        l_dcs            epis_info.id_dep_clin_serv%TYPE;
    BEGIN
    
        g_error := 'call get_pregn_interval_dates';
        IF NOT get_pregn_interval_dates(i_pat_pregnancy => i_pat_pregnancy, o_dt_ini => l_dt_ini, o_dt_fim => l_dt_fim)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error  := 'call get_param_wp';
        l_params := get_param_wp(i_prof          => i_prof,
                                 i_patient       => i_patient,
                                 i_episode       => i_episode,
                                 i_pat_pregnancy => i_pat_pregnancy,
                                 i_owner         => 'BOTH');
    
        g_error  := 'call get_value_coll';
        l_values := get_value_coll_wh(i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_patient       => i_patient,
                                      i_episode       => i_episode,
                                      i_params        => l_params,
                                      i_pat_pregnancy => i_pat_pregnancy,
                                      i_dt_ini        => l_dt_ini,
                                      i_dt_fim        => l_dt_fim);
    
        IF i_cursor_out IN ('A', 'VW')
        THEN
            g_error     := 'call get_value_cursor_wh';
            o_values_wh := get_value_cursor_wh(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_patient => i_patient,
                                               i_values  => l_values);
        ELSE
            o_values_wh := t_coll_wh_values();
        END IF;
    
        IF i_cursor_out IN ('A', 'T')
        THEN
            g_error := 'call get_time_cursor_wh';
            get_time_cursor_wh(i_lang          => i_lang,
                               i_prof          => i_prof,
                               i_patient       => i_patient,
                               i_values        => l_values,
                               i_pat_pregnancy => i_pat_pregnancy,
                               i_dt_ini        => l_dt_ini,
                               i_dt_fim        => l_dt_fim,
                               o_time          => o_time);
        ELSE
            pk_types.open_my_cursor(o_time);
        END IF;
    
        IF i_cursor_out = 'A'
        THEN
            l_dcs := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        
            g_error := 'call get_param_cursor_hpg';
            get_param_cursor_wh(i_lang          => i_lang,
                                i_prof          => i_prof,
                                i_episode       => i_episode,
                                i_params        => l_params,
                                i_med_data      => l_med_data,
                                i_pat_pregnancy => i_pat_pregnancy,
                                i_values        => l_values,
                                o_param         => o_param);
        
            g_error := 'OPEN o_value';
            OPEN o_value FOR
                SELECT *
                  FROM TABLE(CAST(o_values_wh AS t_coll_wh_values));
        
            l_mother := pk_message.get_message(i_lang, i_prof, 'PREGNANCY_PO_T004');
            l_fetu   := pk_message.get_message(i_lang, i_prof, 'PREGNANCY_PO_T005');
        
            g_error := 'open o_wh';
            OPEN o_wh FOR
                SELECT aux.woman_health_id, aux.woman_health_desc, aux.woman_health_flg
                  FROM (SELECT to_char(i_pat_pregnancy) woman_health_id,
                               l_mother woman_health_desc,
                               0 rank,
                               g_parameter_mother woman_health_flg,
                               NULL fetus_number
                          FROM dual
                        UNION ALL
                        SELECT to_char(pp.id_pat_pregnancy || '|' || ppf.id_pat_pregn_fetus) woman_health_id,
                               l_fetu || ' ' || ppf.fetus_number woman_health_desc,
                               ppf.fetus_number rank,
                               g_parameter_fetus woman_health_flg,
                               ppf.fetus_number fetus_number
                          FROM pat_pregnancy pp
                          JOIN pat_pregn_fetus ppf
                            ON ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                           AND nvl(ppf.flg_status, pk_alert_constant.g_active) <> pk_alert_constant.g_cancelled
                         WHERE pp.id_patient = i_patient
                           AND pp.id_pat_pregnancy = i_pat_pregnancy
                           AND pp.flg_status <> pk_alert_constant.g_cancelled) aux
                 ORDER BY aux.rank ASC;
        
            g_error := 'open o_wh_param';
            OPEN o_wh_param FOR
                SELECT p.parameter_id, p.woman_health_id, parameter_flg_cancel
                  FROM (SELECT pop.id_po_param parameter_id,
                               to_char(i_pat_pregnancy) woman_health_id,
                               decode((SELECT COUNT(*)
                                        FROM TABLE(l_values) t
                                       WHERE t.id_po_param = pop.id_po_param
                                         AND t.id_inst_owner = pop.id_inst_owner
                                         AND t.flg_status = pk_alert_constant.g_active),
                                      0,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_no) parameter_flg_cancel,
                               (SELECT get_param_desc(i_lang,
                                                      i_prof,
                                                      pop.id_po_param,
                                                      pop.id_inst_owner,
                                                      pop.flg_type,
                                                      pop.id_parameter,
                                                      l_dcs)
                                  FROM dual) parameter_desc,
                               (SELECT get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank)
                                  FROM dual) rank_param,
                               0 rank_wh
                          FROM po_param pop
                          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                t.id_po_param, t.id_inst_owner
                                 FROM TABLE(CAST(l_params AS t_coll_po_param)) t) t
                            ON pop.id_po_param = t.id_po_param
                           AND pop.id_inst_owner = t.id_inst_owner
                          JOIN preg_po_param ppp
                            ON ppp.id_po_param = pop.id_po_param
                           AND ppp.id_inst_owner = pop.id_inst_owner
                           AND ppp.flg_visible = pk_alert_constant.g_yes
                           AND ppp.flg_owner = g_flg_owner_m
                           AND ppp.id_pat_pregnancy = i_pat_pregnancy
                        UNION ALL
                        SELECT pop.id_po_param parameter_id,
                               to_char(i_pat_pregnancy || '|' || ppf2.id_pat_pregn_fetus) woman_health_id,
                               decode((SELECT COUNT(*)
                                        FROM TABLE(l_values) t
                                       WHERE t.id_po_param = pop.id_po_param
                                         AND t.id_inst_owner = pop.id_inst_owner
                                         AND t.flg_status = pk_alert_constant.g_active),
                                      0,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_no) parameter_flg_cancel,
                               (SELECT get_param_desc(i_lang,
                                                      i_prof,
                                                      pop.id_po_param,
                                                      pop.id_inst_owner,
                                                      pop.flg_type,
                                                      pop.id_parameter,
                                                      l_dcs)
                                  FROM dual) parameter_desc,
                               (SELECT get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank)
                                  FROM dual) rank_param,
                               ppf2.fetus_number rank_wh
                          FROM po_param pop
                          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                t.id_po_param, t.id_inst_owner
                                 FROM TABLE(CAST(l_params AS t_coll_po_param)) t) t
                            ON pop.id_po_param = t.id_po_param
                           AND pop.id_inst_owner = t.id_inst_owner
                          JOIN preg_po_param ppp
                            ON ppp.id_po_param = pop.id_po_param
                           AND ppp.id_inst_owner = pop.id_inst_owner
                           AND ppp.flg_visible = pk_alert_constant.g_yes
                           AND ppp.flg_owner = g_flg_owner_f
                           AND pop.flg_type <> g_habit
                           AND ppp.id_pat_pregnancy = i_pat_pregnancy
                         CROSS JOIN (SELECT ppf.id_pat_pregn_fetus, ppf.fetus_number
                                      FROM pat_pregnancy pp
                                      JOIN pat_pregn_fetus ppf
                                        ON ppf.id_pat_pregnancy = pp.id_pat_pregnancy
                                       AND nvl(ppf.flg_status, pk_alert_constant.g_active) <>
                                           pk_alert_constant.g_cancelled
                                     WHERE pp.id_patient = i_patient
                                       AND pp.id_pat_pregnancy = i_pat_pregnancy
                                       AND pp.flg_status <> pk_alert_constant.g_cancelled) ppf2
                         ORDER BY rank_wh, rank_param, parameter_desc) p;
        
            l_show_ref_value := pk_sysconfig.get_config('WOMEN_HEALTH_SHOW_REF_VALUE', i_prof);
            IF l_show_ref_value = pk_alert_constant.g_yes
            THEN
                g_error := 'open o_ref';
                OPEN o_ref FOR
                    SELECT g_ref_value time_id
                      FROM dual;
            ELSE
                pk_types.open_my_cursor(o_ref);
            END IF;
        
        ELSE
            pk_types.open_my_cursor(o_value);
            pk_types.open_my_cursor(o_wh_param);
            pk_types.open_my_cursor(o_wh);
            pk_types.open_my_cursor(o_param);
            pk_types.open_my_cursor(o_ref);
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
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_wh);
            pk_types.open_my_cursor(o_param);
            pk_types.open_my_cursor(o_wh_param);
            pk_types.open_my_cursor(o_time);
            pk_types.open_my_cursor(o_value);
            pk_types.open_my_cursor(i_cursor => o_ref);
            RETURN FALSE;
    END get_grid_wh;

    /**
    * Get full parameters list (as used in parameters grid).
    *
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    *
    * @return               parameters collection
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/27
    */
    FUNCTION get_param_wp
    (
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_owner         IN VARCHAR2
    ) RETURN t_coll_po_param IS
        l_ret       t_coll_po_param;
        l_flg_owner preg_po_param.flg_owner%TYPE;
    
    BEGIN
    
        IF i_owner = g_parameter_mother
        THEN
            l_flg_owner := g_flg_owner_m;
        ELSIF i_owner = g_parameter_fetus
        THEN
            l_flg_owner := g_flg_owner_f;
        ELSE
            l_flg_owner := NULL;
        END IF;
    
        g_error := 'SELECT l_params';
        SELECT t_rec_po_param(id_po_param, id_inst_owner)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT pop.id_po_param,
                       pop.id_inst_owner,
                       row_number() over(PARTITION BY pop.flg_type, pop.id_parameter, pop.id_sample_type ORDER BY pop.id_inst_owner DESC) rn
                  FROM po_param pop
                  JOIN (SELECT ppp.id_po_param, ppp.id_inst_owner
                         FROM preg_po_param ppp
                        WHERE ppp.id_pat_pregnancy = i_pat_pregnancy
                          AND ppp.flg_visible = pk_alert_constant.g_yes
                          AND ppp.flg_owner = nvl(l_flg_owner, ppp.flg_owner)) p
                    ON pop.id_po_param = p.id_po_param
                   AND pop.id_inst_owner = p.id_inst_owner
                 WHERE pop.id_inst_owner IN (i_prof.institution, pk_alert_constant.g_inst_all)
                   AND pop.flg_available = pk_alert_constant.g_yes)
         WHERE rn = 1;
    
        RETURN l_ret;
    END get_param_wp;

    /**
    * get_permissions
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_pat_pregnancy        pat_pregnancy identifier
    * @param o_read_only        read_only Y/N
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.5
    * @since                2013/02/18
    */
    FUNCTION get_permissions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_read_only     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'get_permissions';
    BEGIN
        BEGIN
            SELECT pk_alert_constant.g_no
              INTO o_read_only
              FROM pat_pregnancy pp
             WHERE id_pat_pregnancy = i_pat_pregnancy
               AND flg_status = pk_alert_constant.g_active;
        EXCEPTION
            WHEN no_data_found THEN
                o_read_only := pk_alert_constant.g_yes;
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
    END get_permissions;
    /********************************************************************************************
    * get_pregnancy_week
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_dt_ini       begin date
    * @param i_dt_fim       end date
    *
    * @return               pregnancy_week
    *
    * @author               Paulo Teixeira
    * @version               2.5
    * @since                2013/02/18
    *
    **********************************************************************************************/
    FUNCTION get_pregnancy_week
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_dt_ini IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_fim IN pat_pregnancy.dt_intervention%TYPE
    ) RETURN VARCHAR2 IS
    
        l_weeks NUMBER;
        l_days  NUMBER;
        l_age   VARCHAR2(50);
    
    BEGIN
    
        g_error := 'call pk_pregnancy_api.get_pregnancy_weeks';
        l_weeks := pk_pregnancy_api.get_pregnancy_weeks(i_prof, i_dt_ini, i_dt_fim, NULL);
        g_error := 'call pk_pregnancy_api.get_pregnancy_days';
        l_days  := pk_pregnancy_api.get_pregnancy_days(i_prof, i_dt_ini, i_dt_fim, NULL);
    
        IF l_days > 0
        THEN
            l_age := l_days || pk_message.get_message(i_lang, i_prof, 'DAY_SIGN');
        END IF;
    
        IF l_weeks > 0
        THEN
            l_age := l_weeks || pk_message.get_message(i_lang, i_prof, 'WOMAN_HEALTH_T063') || ' ' || l_age;
        END IF;
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_pregnancy_week;

    /**
    * Get values collection.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_params       parameter identifiers
    * @param i_med_data     medication data
    *
    * @return               values collection
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    FUNCTION get_value_coll_wh
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_params        IN t_coll_po_param,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_ini        IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_fim        IN pat_pregnancy.dt_init_pregnancy%TYPE
    ) RETURN t_coll_po_value IS
    
        l_ret            t_coll_po_value;
        l_value_scope    sys_config.value%TYPE;
        l_decimal_symbol sys_config.value%TYPE;
        l_time_filter_e  po_param_reg.dt_result%TYPE;
        l_time_filter_a  po_param_reg.dt_result%TYPE;
        l_episode        episode.id_episode%TYPE;
        l_insts          table_number;
        l_prev_epis_date episode.dt_end_tstz%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_value_scope    := pk_sysconfig.get_config(i_code_cf => 'WOMAN_HEALTH_PER_OBS_VALUE_SCOPE', i_prof => i_prof);
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf => pk_touch_option.g_scfg_decimal_separator,
                                                    i_prof    => i_prof);
        l_time_filter_e  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_e,
                                                                                                  i_prof    => i_prof) * -1);
        l_time_filter_a  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_a,
                                                                                                  i_prof    => i_prof) * -1);
        l_prev_epis_date := get_prev_epis_date(i_prof => i_prof, i_patient => i_patient, i_episode => i_episode);
    
        -- set minimum filter dates
        IF l_prev_epis_date > l_time_filter_e
        THEN
            l_time_filter_e := l_prev_epis_date;
        END IF;
        IF l_prev_epis_date > l_time_filter_a
        THEN
            l_time_filter_a := l_prev_epis_date;
        END IF;
    
        -- set scope filter variables
        IF l_value_scope = g_scope_episode
        THEN
            l_episode := i_episode;
        ELSIF l_value_scope = g_scope_inst
        THEN
            l_insts := table_number(i_prof.institution);
        ELSIF l_value_scope = g_scope_group
        THEN
            l_insts := pk_list.tf_get_all_inst_group(i_institution  => i_prof.institution,
                                                     i_flg_relation => pk_adt.g_inst_grp_flg_rel_adt);
        END IF;
    
        --ALERT-154864    
        -- get values
        g_error := 'SELECT l_ret';
        SELECT t_rec_po_value(pop.id_po_param,
                              pop.id_inst_owner,
                              v.id_result,
                              v.id_episode,
                              v.id_institution,
                              ei.id_software,
                              v.id_prof_reg,
                              v.dt_result,
                              NULL,
                              v.dt_reg,
                              v.flg_status,
                              --ALERT-154864                              
                              v.desc_result,
                              (SELECT nvl(v.desc_unit_measure,
                                          pk_unit_measure.get_unit_measure_description(i_lang, i_prof, v.id_unit_measure))
                                 FROM dual),
                              v.icon,
                              v.lab_param_count,
                              v.lab_param_id,
                              v.lab_param_rank,
                              v.val_min,
                              v.val_max,
                              v.abnorm_value,
                              v.option_codes,
                              v.flg_cancel,
                              v.dt_cancel,
                              v.id_prof_cancel,
                              v.id_cancel_reason,
                              v.notes_cancel,
                              v.woman_health_id,
                              v.flg_ref_value,
                              v.dt_harvest,
                              v.dt_execution,
                              v.notes,
                              v.id_sample_type)
          BULK COLLECT
          INTO l_ret
          FROM (
                --analysis
                SELECT ar.id_analysis id_parameter,
                        g_analysis flg_type,
                        ar.id_analysis_result id_result,
                        ar.id_episode_orig id_episode,
                        ar.id_institution,
                        ar.id_professional id_prof_reg,
                        nvl(arp.dt_analysis_result_par_upd, arp.dt_analysis_result_par_tstz) dt_result,
                        coalesce(arp.dt_ins_result_tstz,
                                 lte.dt_harvest,
                                 arp.dt_analysis_result_par_upd,
                                 ar.dt_sample,
                                 ar.dt_analysis_result_tstz) dt_reg,
                        nvl(ar.flg_status, pk_alert_constant.g_active) flg_status,
                        to_clob((SELECT nvl(TRIM(arp.desc_analysis_result),
                                           pk_utils.to_str(arp.analysis_result_value, l_decimal_symbol))
                                  FROM dual)) desc_result,
                        arp.desc_unit_measure,
                        arp.id_unit_measure,
                        NULL icon,
                        pk_lab_tests_external_api_db.get_lab_test_param_count(i_prof, ar.id_analysis, ar.id_sample_type) lab_param_count,
                        arp.id_analysis_parameter lab_param_id,
                        row_number() over(PARTITION BY ar.id_analysis_result ORDER BY apr.rank) lab_param_rank,
                        nvl(TRIM(arp.ref_val_min_str), arp.ref_val_min) val_min,
                        nvl(TRIM(arp.ref_val_max_str), arp.ref_val_max) val_max,
                        CASE
                         --ALERT-154864                            
                             WHEN pk_utils.is_number(arp.desc_analysis_result) = 'Y' THEN
                              CASE
                                  WHEN nvl(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                     '999999999999999999999999D999',
                                                     'NLS_NUMERIC_CHARACTERS='', '''),
                                           arp.analysis_result_value) < arp.ref_val_min THEN
                                   'D'
                                  WHEN nvl(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                     '999999999999999999999999D999',
                                                     'NLS_NUMERIC_CHARACTERS='', '''),
                                           arp.analysis_result_value) > arp.ref_val_max THEN
                                   'U'
                                  ELSE
                                   NULL
                              END
                             ELSE
                              NULL
                         END abnorm_value,
                        table_varchar() option_codes,
                        decode(ar.flg_status,
                               pk_alert_constant.g_cancelled,
                               pk_alert_constant.g_no,
                               pk_alert_constant.g_yes) flg_cancel,
                        arp.dt_cancel,
                        arp.id_professional_cancel id_prof_cancel,
                        arp.id_cancel_reason,
                        to_clob(arp.notes_cancel) notes_cancel,
                        to_char(i_pat_pregnancy) woman_health_id,
                        pk_alert_constant.g_no flg_ref_value,
                        ar.dt_sample dt_harvest,
                        NULL dt_execution,
                        arp.parameter_notes notes,
                        ar.id_sample_type
                  FROM analysis_result ar
                  JOIN analysis_result_par arp
                    ON ar.id_analysis_result = arp.id_analysis_result
                  JOIN analysis_parameter apr
                    ON arp.id_analysis_parameter = apr.id_analysis_parameter
                  LEFT JOIN lab_tests_ea lte
                    ON ar.id_analysis_req_det = lte.id_analysis_req_det
                  LEFT JOIN abnormality a
                    ON arp.id_abnormality = a.id_abnormality
                 WHERE ar.id_patient = i_patient
                   AND coalesce(ar.dt_sample, ar.dt_analysis_result_tstz, lte.dt_harvest) BETWEEN i_dt_ini AND i_dt_fim
                UNION ALL
                --vital signs simples gravida
                SELECT vsr.id_vital_sign id_parameter,
                        g_vital_sign flg_type,
                        vsr.id_vital_sign_read id_result,
                        vsr.id_episode,
                        vsr.id_institution_read id_institution,
                        vsr.id_prof_read id_prof_reg,
                        vsr.dt_vital_sign_read_tstz dt_result,
                        vsr.dt_registry dt_reg,
                        vsr.flg_state flg_status,
                        to_clob(pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_patient            => vsr.id_patient,
                                                           i_episode            => vsr.id_episode,
                                                           i_vital_sign         => vsr.id_vital_sign,
                                                           i_value              => vsr.value,
                                                           i_vs_unit_measure    => vsr.id_unit_measure,
                                                           i_vital_sign_desc    => vsr.id_vital_sign_desc,
                                                           i_vs_scales_element  => vsr.id_vs_scales_element,
                                                           i_dt_vital_sign_read => vsr.dt_vital_sign_read_tstz,
                                                           i_ea_unit_measure    => vsr.id_unit_measure,
                                                           i_short_desc         => pk_alert_constant.g_no,
                                                           i_decimal_symbol     => l_decimal_symbol,
                                                           i_dt_registry        => vsr.dt_registry)) desc_result,
                        (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                          vsr.id_unit_measure,
                                                                          vsr.id_vs_scales_element)
                           FROM dual) desc_unit_measure,
                        vsr.id_unit_measure,
                        vsd.icon,
                        NULL lab_param_count,
                        NULL lab_param_id,
                        NULL lab_param_rank,
                        NULL val_min,
                        NULL val_max,
                        NULL abnorm_value,
                        table_varchar() option_codes,
                        decode(vsr.flg_state,
                               pk_alert_constant.g_cancelled,
                               pk_alert_constant.g_no,
                               pk_alert_constant.g_yes) flg_cancel,
                        vsr.dt_cancel_tstz dt_cancel,
                        vsr.id_prof_cancel,
                        NULL id_cancel_reason,
                        to_clob(vsr.notes_cancel) notes_cancel,
                        to_char(i_pat_pregnancy) woman_health_id,
                        pk_alert_constant.g_no flg_ref_value,
                        NULL dt_harvest,
                        NULL dt_execution,
                        NULL notes,
                        NULL id_sample_type
                  FROM vital_sign_read vsr
                  LEFT JOIN vital_sign_desc vsd
                    ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
                 WHERE vsr.id_patient = i_patient
                   AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                   AND vsr.dt_vital_sign_read_tstz BETWEEN i_dt_ini AND i_dt_fim
                UNION ALL
                SELECT t.id_parameter,
                        t.flg_type,
                        t.id_result,
                        t.id_episode,
                        t.id_institution,
                        t.id_prof_reg,
                        t.dt_result,
                        t.dt_reg,
                        t.flg_status,
                        t.desc_result,
                        t.desc_unit_measure,
                        t.id_unit_measure,
                        t.icon,
                        t.lab_param_count,
                        t.lab_param_id,
                        t.lab_param_rank,
                        t.val_min,
                        t.val_max,
                        t.abnorm_value,
                        t.option_codes,
                        t.flg_cancel,
                        t.dt_cancel,
                        t.id_prof_cancel,
                        t.id_cancel_reason,
                        t.notes_cancel,
                        t.woman_health_id,
                        t.flg_ref_value,
                        t.dt_harvest,
                        t.dt_execution,
                        t.notes,
                        t.id_sample_type
                  FROM TABLE(get_value_coll_fetus_pl(i_lang, i_prof, i_patient, i_pat_pregnancy, i_dt_ini, i_dt_fim)) t
                -- vital signs compostos gravida
                UNION ALL
                SELECT vs_comp.id_vital_sign_parent id_parameter,
                        g_vital_sign flg_type,
                        vs_comp.id_vital_sign_read id_result,
                        vs_comp.id_episode,
                        vs_comp.id_institution_read id_institution,
                        vs_comp.id_prof_read id_prof_reg,
                        vs_comp.dt_vital_sign_read_tstz dt_result,
                        vs_comp.dt_registry dt_reg,
                        vs_comp.flg_state flg_status,
                        to_clob(decode(relation_domain,
                                       g_vs_rel_conc,
                                       pk_vital_sign.get_bloodpressure_value(i_vital_sign         => vs_comp.id_vital_sign_parent,
                                                                             i_patient            => i_patient,
                                                                             i_episode            => vs_comp.id_episode,
                                                                             i_dt_vital_sign_read => vs_comp.dt_vital_sign_read_tstz,
                                                                             i_decimal_symbol     => l_decimal_symbol,
                                                                             i_dt_registry        => vs_comp.dt_registry),
                                       pk_vital_sign.get_glasgowtotal_value_hist(vs_comp.id_vital_sign_parent,
                                                                                 i_patient,
                                                                                 vs_comp.id_episode,
                                                                                 vs_comp.dt_vital_sign_read_tstz,
                                                                                 vs_comp.dt_registry))) desc_result,
                        (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                          vs_comp.id_unit_measure,
                                                                          vs_comp.id_vs_scales_element)
                           FROM dual) desc_unit_measure,
                        vs_comp.id_unit_measure,
                        NULL icon,
                        NULL lab_param_count,
                        NULL lab_param_id,
                        NULL lab_param_rank,
                        NULL val_min,
                        NULL val_max,
                        NULL abnorm_value,
                        table_varchar() option_codes,
                        decode(vs_comp.flg_state,
                               pk_alert_constant.g_cancelled,
                               pk_alert_constant.g_no,
                               pk_alert_constant.g_yes) flg_cancel,
                        vs_comp.dt_cancel_tstz dt_cancel,
                        vs_comp.id_prof_cancel,
                        NULL id_cancel_reason,
                        to_clob(vs_comp.notes_cancel) notes_cancel,
                        to_char(i_pat_pregnancy) woman_health_id,
                        pk_alert_constant.g_no flg_ref_value,
                        NULL dt_harvest,
                        NULL dt_execution,
                        NULL notes,
                        NULL id_sample_type
                  FROM (SELECT vsre.id_vital_sign_parent,
                                vsr.id_vital_sign_read,
                                vsr.id_episode,
                                vsr.id_institution_read,
                                vsr.id_prof_read,
                                vsr.dt_vital_sign_read_tstz,
                                vsr.dt_registry,
                                vsr.flg_state,
                                vsr.id_unit_measure,
                                vsr.id_vs_scales_element,
                                vsr.dt_cancel_tstz,
                                vsr.id_prof_cancel,
                                vsr.notes_cancel,
                                vsre.relation_domain,
                                row_number() over(PARTITION BY vsr.dt_registry ORDER BY vsr.id_vital_sign_read DESC) rn
                           FROM vital_sign_read vsr
                           JOIN vital_sign_relation vsre
                             ON vsr.id_vital_sign = vsre.id_vital_sign_detail
                          WHERE vsr.id_patient = i_patient
                            AND vsre.relation_domain IN (g_vs_rel_conc, g_vs_rel_sum)
                            AND vsr.dt_vital_sign_read_tstz BETWEEN i_dt_ini AND i_dt_fim) vs_comp
                 WHERE vs_comp.rn = 1
                   AND pk_delivery.check_vs_read_from_fetus(vs_comp.id_vital_sign_read) = 0
                --sinais vitais ref value
                UNION ALL
                SELECT emf.id_group id_parameter,
                        g_vital_sign flg_type,
                        emf.id_event_most_freq id_result,
                        emf.id_episode,
                        emf.id_institution_read id_institution,
                        emf.id_prof_read id_prof_reg,
                        emf.dt_event_most_freq_tstz dt_result,
                        emf.dt_event_most_freq_tstz dt_reg,
                        nvl(emf.flg_status, pk_alert_constant.g_active) flg_status,
                        to_clob(decode(vs.flg_fill_type,
                                       'V',
                                       pk_vital_sign.get_vsd_desc(i_lang            => i_lang,
                                                                  i_vital_sign_desc => emf.value,
                                                                  i_patient         => i_patient),
                                       emf.value)) desc_result,
                        (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, emf.id_unit_measure, NULL)
                           FROM dual) desc_unit_measure,
                        emf.id_unit_measure id_unit_measure,
                        NULL icon,
                        NULL lab_param_count,
                        NULL lab_param_id,
                        NULL lab_param_rank,
                        NULL val_min,
                        NULL val_max,
                        NULL abnorm_value,
                        table_varchar() option_codes,
                        decode(emf.flg_status,
                               pk_alert_constant.g_cancelled,
                               pk_alert_constant.g_no,
                               pk_alert_constant.g_yes) flg_cancel,
                        emf.dt_cancel dt_cancel,
                        emf.id_prof_cancel id_prof_cancel,
                        NULL id_cancel_reason,
                        NULL notes_cancel,
                        CASE
                            WHEN emf.id_pat_pregn_fetus IS NULL THEN
                             to_char(emf.id_pat_pregnancy)
                            ELSE
                             emf.id_pat_pregnancy || '|' || emf.id_pat_pregn_fetus
                        END woman_health_id,
                        pk_alert_constant.g_yes flg_ref_value,
                        NULL dt_harvest,
                        NULL dt_execution,
                        NULL notes,
                        NULL id_sample_type
                  FROM event_most_freq emf
                  JOIN vital_sign vs
                    ON emf.id_group = vs.id_vital_sign
                 WHERE emf.id_pat_pregnancy = i_pat_pregnancy
                   AND emf.flg_group = g_vital_sign
                   AND emf.dt_event_most_freq_tstz BETWEEN i_dt_ini AND i_dt_fim
                UNION ALL
                --exames
                SELECT ea.id_exam id_parameter,
                        g_exam flg_type,
                        ea.id_exam_result id_result,
                        er.id_episode_write id_episode,
                        er.id_institution,
                        er.id_professional id_prof_reg,
                        nvl(ea.start_time, ea.dt_result) dt_result,
                        er.dt_exam_result_tstz dt_reg,
                        er.flg_status,
                        --ALERT-154864
                        decode(dbms_lob.getlength(ea.desc_result), 0, empty_clob(), ea.desc_result) desc_result,
                        NULL desc_unit_measure,
                        NULL id_unit_measure,
                        decode(length(to_char(ea.desc_result)),
                               NULL,
                               pk_sysdomain.get_img(i_lang, 'EXAM_REQ.FLG_STATUS', ea.flg_status_req)) icon,
                        NULL lab_param_count,
                        NULL lab_param_id,
                        NULL lab_param_rank,
                        NULL val_min,
                        NULL val_max,
                        NULL abnorm_value,
                        table_varchar() option_codes,
                        pk_alert_constant.g_no flg_cancel,
                        er.dt_exam_result_cancel_tstz dt_cancel,
                        er.id_prof_cancel,
                        NULL id_cancel_reason,
                        NULL notes_cancel,
                        to_char(i_pat_pregnancy) woman_health_id,
                        pk_alert_constant.g_no flg_ref_value,
                        NULL dt_harvest,
                        nvl(ea.start_time, ea.dt_result) dt_execution,
                        NULL notes,
                        NULL id_sample_type
                  FROM exams_ea ea
                  JOIN exam_result er
                    ON ea.id_exam_result = er.id_exam_result
                 WHERE er.id_patient = i_patient
                UNION ALL
                --others params
                SELECT nvl(pop.id_parameter, pop.id_po_param) id_parameter,
                        pop.flg_type,
                        popr.id_po_param_reg id_result,
                        popr.id_episode,
                        e.id_institution,
                        popr.id_professional id_prof_reg,
                        popr.dt_result,
                        popr.dt_creation dt_reg,
                        popr.flg_status,
                        CASE
                            WHEN pop.flg_fill_type = g_free_text THEN
                             popr.free_text
                            WHEN pop.flg_fill_type = g_free_date THEN
                             to_clob(get_dt_str(i_lang, i_prof, popr.free_date, popr.free_date_mask))
                            ELSE
                             to_clob(popr.value)
                        END desc_result,
                        NULL desc_unit_measure,
                        popr.id_unit_measure,
                        (SELECT get_reg_opt_icon(i_lang, popr.id_po_param_reg)
                           FROM dual) icon,
                        NULL lab_param_count,
                        NULL lab_param_id,
                        NULL lab_param_rank,
                        NULL val_min,
                        NULL val_max,
                        NULL abnorm_value,
                        popr.option_codes,
                        decode(pop.flg_type,
                               g_others,
                               decode(popr.flg_status,
                                      pk_alert_constant.g_cancelled,
                                      pk_alert_constant.g_no,
                                      decode(popr.id_professional,
                                             i_prof.id,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no)),
                               pk_alert_constant.g_no) flg_cancel,
                        popr.dt_cancel,
                        popr.id_prof_cancel,
                        popr.id_cancel_reason,
                        popr.notes_cancel notes_cancel,
                        CASE
                            WHEN popr.id_pat_pregn_fetus IS NULL THEN
                             to_char(i_pat_pregnancy)
                            ELSE
                             i_pat_pregnancy || '|' || popr.id_pat_pregn_fetus
                        END woman_health_id,
                        nvl(popr.flg_ref_value, pk_alert_constant.g_no) flg_ref_value,
                        NULL dt_harvest,
                        NULL dt_execution,
                        NULL notes,
                        NULL id_sample_type
                  FROM (SELECT (SELECT get_reg_opt_codes(popr.id_po_param_reg)
                                   FROM dual) option_codes,
                                popr.*
                           FROM po_param_reg popr
                          WHERE popr.id_patient = i_patient
                            AND nvl(popr.dt_result, i_dt_ini) BETWEEN i_dt_ini AND i_dt_fim) popr
                  JOIN po_param pop
                    ON popr.id_po_param = pop.id_po_param
                   AND popr.id_inst_owner = pop.id_inst_owner
                  JOIN episode e
                    ON popr.id_episode = e.id_episode
                 WHERE popr.id_patient = i_patient) v
          JOIN po_param pop
            ON v.flg_type = pop.flg_type
           AND ((v.id_sample_type = pop.id_sample_type AND pop.flg_fill_type = 'A') OR pop.flg_fill_type <> 'A')
           AND v.id_parameter = nvl(pop.id_parameter, pop.id_po_param)
          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                 t.id_po_param, t.id_inst_owner
                  FROM TABLE(CAST(i_params AS t_coll_po_param)) t) t
            ON pop.id_po_param = t.id_po_param
           AND pop.id_inst_owner = t.id_inst_owner
          JOIN epis_info ei
            ON v.id_episode = ei.id_episode
         WHERE (v.id_episode = l_episode OR
               v.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      t.column_value id_institution
                                       FROM TABLE(CAST(l_insts AS table_number)) t))
           AND (pop.flg_type = g_vital_sign OR --
               (pop.flg_type = g_exam AND v.dt_result > l_time_filter_e) OR --
               (pop.flg_type = g_analysis AND v.dt_result > l_time_filter_a) OR (pop.flg_type = g_others));
    
        RETURN l_ret;
    END get_value_coll_wh;
    /**
    * Get values cursor.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_values       values collection
    * @param o_value        values
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/15
    */
    FUNCTION get_value_cursor_wh
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_values  IN t_coll_po_value
    ) RETURN t_coll_wh_values IS
        l_vs_sort         sys_config.value%TYPE;
        l_lab_result      sys_domain.desc_val%TYPE;
        l_lab_result_icon sys_domain.img_name%TYPE;
        l_ret             t_coll_wh_values;
    BEGIN
    
        l_vs_sort         := pk_sysconfig.get_config(i_code_cf => g_cfg_vs_sort, i_prof => i_prof);
        l_lab_result      := pk_sysdomain.get_domain(i_code_dom => g_ana_req_det_domain,
                                                     --ALERT-154864                                                     i_val      => pk_lab_tests_constant.g_arq_status_with_result,        
                                                     i_val  => 'F',
                                                     i_lang => i_lang);
        l_lab_result_icon := pk_sysdomain.get_img(i_lang     => i_lang,
                                                  i_code_dom => g_ana_req_det_domain,
                                                  --ALERT-154864                                                     i_val      => pk_lab_tests_constant.g_arq_status_with_result,        
                                                  i_val => 'F');
    
        g_error := 'OPEN o_value';
        SELECT t_rec_wh_values(aux.time_id,
                               aux.parameter_id,
                               aux.value_id,
                               aux.value_status,
                               to_clob(aux.value_text),
                               aux.value_units,
                               aux.value_icon,
                               aux.value_flg_cancel,
                               aux.value_abnormal,
                               aux.value_elem_count,
                               aux.value_style,
                               aux.woman_health_id,
                               aux.dt_result_real)
        
          BULK COLLECT
          INTO l_ret
          FROM (SELECT v.time_id time_id,
                       v.id_po_param parameter_id,
                       v.id_result value_id,
                       v.flg_status value_status,
                       htf.escape_sc(decode(v.option_count,
                                             0,
                                             CASE
                                                 WHEN v.lab_param_count > 1 THEN
                                                  to_clob(l_lab_result)
                                                 ELSE
                                                  v.desc_result
                                             END,
                                             1,
                                             pk_translation.get_translation(i_lang, v.option_code),
                                             get_reg_opt_value(i_lang, v.option_codes))) value_text,
                       htf.escape_sc(v.desc_unit_measure) value_units,
                       CASE
                            WHEN v.lab_param_count > 1 THEN
                             l_lab_result_icon
                            ELSE
                             v.icon
                        END value_icon,
                       v.flg_cancel value_flg_cancel,
                       v.abnorm_value value_abnormal,
                       v.cnt value_elem_count,
                       decode(v.own_soft, 1, g_style_normal, 0, g_style_italic) value_style,
                       v.woman_health_id,
                       pk_date_utils.date_send_tsz(i_lang, v.dt_result_real, i_prof) dt_result_real
                  FROM (SELECT t.*,
                               row_number() over(PARTITION BY t.time_id, t.id_po_param, t.woman_health_id, t.id_inst_owner ORDER BY t.own_soft DESC, t.dt_vs_sort ASC, t.dt_result_real DESC, t.dt_reg DESC) rn,
                               COUNT(t.id_result) over(PARTITION BY t.lab_param_id, t.time_id, t.id_po_param, t.woman_health_id, t.id_inst_owner, t.own_soft) cnt
                          FROM (SELECT t.id_po_param,
                                       t.id_inst_owner,
                                       t.id_result,
                                       (SELECT decode(t.id_software, i_prof.software, 1, 0)
                                          FROM dual) own_soft, -- result from own software? 1/0
                                       CASE
                                            WHEN t.flg_ref_value = pk_alert_constant.g_yes THEN
                                             g_ref_value
                                            ELSE
                                             get_po_param_reg_date(i_lang,
                                                                   i_prof,
                                                                   i_patient,
                                                                   pk_date_utils.date_send_tsz(i_lang, t.dt_result, i_prof))
                                        END time_id,
                                       t.dt_result dt_result,
                                       CASE
                                            WHEN l_vs_sort = g_vs_sort_asc
                                                 AND (SELECT pop.flg_type
                                                        FROM po_param pop
                                                       WHERE pop.id_po_param = t.id_po_param
                                                         AND pop.id_inst_owner = t.id_inst_owner) = g_vital_sign THEN
                                             t.dt_result
                                        END dt_vs_sort,
                                       t.dt_result dt_result_real,
                                       t.flg_status,
                                       t.desc_result,
                                       t.desc_unit_measure,
                                       t.icon,
                                       t.lab_param_count,
                                       t.get_opt_count() option_count,
                                       t.get_opt_code_first() option_code,
                                       t.option_codes,
                                       t.abnorm_value,
                                       t.flg_cancel,
                                       t.woman_health_id,
                                       t.dt_reg,
                                       t.lab_param_id
                                  FROM TABLE(CAST(i_values AS t_coll_po_value)) t
                                 WHERE t.flg_status = pk_alert_constant.g_active
                                   AND (t.lab_param_rank IS NULL OR t.lab_param_rank = 1)) t) v
                 WHERE v.rn = 1) aux;
    
        RETURN l_ret;
    
    END get_value_cursor_wh;

    FUNCTION split_woman_health_id
    (
        i_woman_health_id    IN VARCHAR2,
        o_id_pat_pregnancy   OUT pat_pregnancy.id_pat_pregnancy%TYPE,
        o_id_pat_pregn_fetus OUT pat_pregn_fetus.id_pat_pregn_fetus%TYPE
    ) RETURN BOOLEAN IS
        l_instr NUMBER(12) := instr(i_woman_health_id, '|');
    BEGIN
        o_id_pat_pregnancy   := NULL;
        o_id_pat_pregn_fetus := NULL;
        IF l_instr = 0
        THEN
            o_id_pat_pregnancy := i_woman_health_id;
        
        ELSE
            o_id_pat_pregnancy   := substr(i_woman_health_id, 1, l_instr - 1);
            o_id_pat_pregn_fetus := substr(i_woman_health_id, l_instr + 1);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_id_pat_pregnancy   := NULL;
            o_id_pat_pregn_fetus := NULL;
            RETURN TRUE;
    END split_woman_health_id;
    ----------------------------------------
    FUNCTION get_pregn_interval_dates
    (
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_dt_ini        OUT pat_pregnancy.dt_init_pregnancy%TYPE,
        o_dt_fim        OUT pat_pregnancy.dt_init_pregnancy%TYPE
    ) RETURN BOOLEAN IS
        l_dt_dif NUMBER(12);
    BEGIN
        BEGIN
            SELECT a.dt_init_pregnancy + 1, trunc(dt_intervention) - trunc(dt_init_pregnancy)
              INTO o_dt_ini, l_dt_dif
              FROM pat_pregnancy a
             WHERE a.id_pat_pregnancy = i_pat_pregnancy;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE g_exception;
        END;
    
        IF l_dt_dif IS NULL
           OR l_dt_dif <= 0
           OR l_dt_dif >= 314
        THEN
            o_dt_fim := o_dt_ini + 314; -- 44semanas e 6 dias
        ELSE
            o_dt_fim := o_dt_ini + l_dt_dif;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_dt_ini := NULL;
            o_dt_fim := NULL;
            RETURN TRUE;
    END get_pregn_interval_dates;
    ----------------------------------------
    FUNCTION get_po_param_reg_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient patient.id_patient%TYPE,
        i_date       VARCHAR2
    ) RETURN VARCHAR2 IS
        l_date     VARCHAR2(14 CHAR);
        l_date_aux VARCHAR2(14 CHAR) := substr(i_date, 1, 8);
    BEGIN
    
        BEGIN
            SELECT pk_date_utils.date_send_tsz(i_lang, a.dt_result, i_prof)
              INTO l_date
              FROM (SELECT b.dt_result, row_number() over(PARTITION BY b.dt_result_send ORDER BY b.dt_result DESC) rn
                      FROM (SELECT ppr.dt_result,
                                   substr(pk_date_utils.date_send_tsz(i_lang, ppr.dt_result, i_prof), 1, 8) dt_result_send
                              FROM po_param_reg ppr
                             WHERE ppr.id_po_param IS NULL
                               AND ppr.id_patient = i_id_patient
                               AND ppr.flg_status = pk_alert_constant.g_active) b
                     WHERE b.dt_result_send = l_date_aux) a
             WHERE rn = 1
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
            
                SELECT pk_date_utils.date_send_tsz(i_lang, a.dt_result, i_prof)
                  INTO l_date
                  FROM (SELECT b.dt_result,
                               row_number() over(PARTITION BY b.dt_result_send ORDER BY b.dt_result DESC) rn
                          FROM (SELECT ppr.dt_result,
                                       substr(pk_date_utils.date_send_tsz(i_lang, ppr.dt_result, i_prof), 1, 8) dt_result_send
                                  FROM po_param_reg ppr
                                 WHERE ppr.id_patient = i_id_patient
                                   AND ppr.flg_status = pk_alert_constant.g_active) b
                         WHERE b.dt_result_send = l_date_aux) a
                 WHERE rn = 1
                   AND rownum = 1;
        END;
    
        RETURN l_date;
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN l_date_aux || '000000';
    END get_po_param_reg_date;

    FUNCTION set_vital_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_episode            IN vital_sign_read.id_episode%TYPE,
        i_prof               IN profissional,
        i_pat                IN vital_sign_read.id_patient%TYPE,
        i_vs_id              IN table_number,
        i_vs_val             IN table_number,
        i_id_monit           IN monitorization_vs_plan.id_monitorization_vs_plan%TYPE,
        i_unit_meas          IN table_number,
        i_vs_scales_elements IN table_number,
        i_notes              IN vital_sign_notes.notes%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_dt_vs_read         IN VARCHAR2,
        i_params             IN table_number,
        i_woman_health_id    IN VARCHAR2,
        o_vital_sign_read    OUT table_number,
        o_value              OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_vital_sign';
        l_id_pat_pregnancy   pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
        l_fetus_number       pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
        l_fetus_number_tab   table_number := table_number();
        l_dt_vs_read         table_varchar := table_varchar();
        l_id_vital_sign      vital_sign_relation.id_vital_sign_parent%TYPE;
        l_tb_event_most_freq table_number;
        tb_g_vital_sign      table_varchar;
        l_dt_registry        VARCHAR2(20 CHAR);
        l_exception          EXCEPTION;
    BEGIN
    
        g_error := 'call split_woman_health_id';
        IF NOT split_woman_health_id(i_woman_health_id    => i_woman_health_id,
                                     o_id_pat_pregnancy   => l_id_pat_pregnancy,
                                     o_id_pat_pregn_fetus => l_id_pat_pregn_fetus)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_dt_vs_read = g_ref_value
        THEN
            CASE i_vs_id.count
                WHEN 1 THEN
                
                    g_error := 'get id_event_most_freq';
                    BEGIN
                        SELECT emf.id_event_most_freq, g_vital_sign
                          BULK COLLECT
                          INTO l_tb_event_most_freq, tb_g_vital_sign
                          FROM event_most_freq emf
                         WHERE emf.id_group = i_vs_id(1)
                           AND emf.flg_group = g_vital_sign
                           AND emf.id_patient = i_pat
                           AND nvl(emf.id_pat_pregnancy, -9999) = nvl(l_id_pat_pregnancy, -9999)
                           AND nvl(emf.id_pat_pregn_fetus, -9999) = nvl(l_id_pat_pregn_fetus, -9999)
                           AND nvl(emf.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_tb_event_most_freq := table_number();
                            tb_g_vital_sign      := table_varchar();
                    END;
                
                    IF l_tb_event_most_freq.count > 0
                    THEN
                        g_error := 'call cancel_value';
                        IF NOT cancel_value(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_prof_cat    => pk_prof_utils.get_category(i_lang, i_prof),
                                            i_episode     => i_episode,
                                            i_patient     => i_pat,
                                            i_values      => l_tb_event_most_freq,
                                            i_types       => tb_g_vital_sign,
                                            i_canc_reason => NULL,
                                            i_canc_notes  => NULL,
                                            i_ref_value   => pk_alert_constant.g_yes,
                                            o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                
                    g_error := 'CALL TO set_epis_vital_sign_nc';
                    --ALERT-154864                    
                    IF NOT pk_woman_health.set_event_most_freq(i_lang            => i_lang,
                                                               i_patient         => i_pat,
                                                               i_id_group        => i_vs_id,
                                                               i_flg_group       => table_varchar(g_vital_sign),
                                                               i_value           => table_varchar(i_vs_val(1)),
                                                               i_id_unit_meas    => i_unit_meas,
                                                               i_pat_pregnancy   => l_id_pat_pregnancy,
                                                               i_prof            => i_prof,
                                                               i_episode         => i_episode,
                                                               i_pat_pregn_fetus => l_id_pat_pregn_fetus,
                                                               o_error           => o_error)
                    
                    THEN
                        RAISE g_exception;
                    END IF;
                
                WHEN 2 THEN
                    BEGIN
                        SELECT DISTINCT a.id_vital_sign_parent
                          INTO l_id_vital_sign
                          FROM vital_sign_relation a
                         WHERE a.id_vital_sign_detail IN (i_vs_id(1), i_vs_id(2))
                           AND flg_available = pk_alert_constant.g_yes
                           AND rownum = 1;
                    EXCEPTION
                        WHEN OTHERS THEN
                            RAISE g_exception;
                    END;
                
                    g_error := 'get id_event_most_freq';
                    BEGIN
                        SELECT emf.id_event_most_freq, g_vital_sign
                          BULK COLLECT
                          INTO l_tb_event_most_freq, tb_g_vital_sign
                          FROM event_most_freq emf
                         WHERE emf.id_group = l_id_vital_sign
                           AND emf.flg_group = g_vital_sign
                           AND emf.id_patient = i_pat
                           AND nvl(emf.id_pat_pregnancy, -9999) = nvl(l_id_pat_pregnancy, -9999)
                           AND nvl(emf.id_pat_pregn_fetus, -9999) = nvl(l_id_pat_pregn_fetus, -9999)
                           AND nvl(emf.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_tb_event_most_freq := table_number();
                            tb_g_vital_sign      := table_varchar();
                    END;
                
                    IF l_tb_event_most_freq.count > 0
                    THEN
                        g_error := 'call cancel_value';
                        IF NOT cancel_value(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_prof_cat    => pk_prof_utils.get_category(i_lang, i_prof),
                                            i_episode     => i_episode,
                                            i_patient     => i_pat,
                                            i_values      => l_tb_event_most_freq,
                                            i_types       => tb_g_vital_sign,
                                            i_canc_reason => NULL,
                                            i_canc_notes  => NULL,
                                            i_ref_value   => pk_alert_constant.g_yes,
                                            o_error       => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                
                    g_error := 'CALL TO set_epis_vital_sign_nc';
                    --ALERT-154864                    
                    IF NOT pk_woman_health.set_event_most_freq(i_lang            => i_lang,
                                                               i_patient         => i_pat,
                                                               i_id_group        => table_number(l_id_vital_sign),
                                                               i_flg_group       => table_varchar(g_vital_sign),
                                                               i_value           => table_varchar(nvl(to_char(i_vs_val(1)),
                                                                                                      '---') || '/' ||
                                                                                                  nvl(to_char(i_vs_val(2)),
                                                                                                      '---')),
                                                               i_id_unit_meas    => table_number(i_unit_meas(1)),
                                                               i_pat_pregnancy   => l_id_pat_pregnancy,
                                                               i_prof            => i_prof,
                                                               i_episode         => i_episode,
                                                               i_pat_pregn_fetus => l_id_pat_pregn_fetus,
                                                               o_error           => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    g_error := 'parameter error';
                    RAISE g_exception;
            END CASE;
        ELSE
            l_dt_vs_read.extend(i_vs_id.count);
            FOR i IN 1 .. i_vs_id.count
            LOOP
                l_dt_vs_read(i) := i_dt_vs_read;
            END LOOP;
        
            IF l_id_pat_pregn_fetus IS NULL
            THEN
                g_error := 'call pk_vital_sign.set_epis_vital_sign';
            
                IF NOT pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                         i_episode            => i_episode,
                                                         i_prof               => i_prof,
                                                         i_pat                => i_pat,
                                                         i_vs_id              => i_vs_id,
                                                         i_vs_val             => i_vs_val,
                                                         i_id_monit           => i_id_monit,
                                                         i_unit_meas          => i_unit_meas,
                                                         i_vs_scales_elements => i_vs_scales_elements,
                                                         i_notes              => i_notes,
                                                         i_prof_cat_type      => i_prof_cat_type,
                                                         i_dt_vs_read         => l_dt_vs_read,
                                                         i_epis_triage        => NULL,
                                                         i_unit_meas_convert  => i_unit_meas,
                                                         -- ALERT-154864 - falta campo flag.                                                                        
                                                         --i_source             => 'D',
                                                         o_vital_sign_read => o_vital_sign_read,
                                                         o_dt_registry     => l_dt_registry,
                                                         o_error           => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            ELSE
            
                BEGIN
                    SELECT ppf.fetus_number
                      INTO l_fetus_number
                      FROM pat_pregn_fetus ppf
                     WHERE ppf.id_pat_pregn_fetus = l_id_pat_pregn_fetus;
                EXCEPTION
                    WHEN no_data_found THEN
                        RAISE g_exception;
                END;
            
                l_fetus_number_tab.extend(i_vs_id.count);
                FOR i IN 1 .. i_vs_id.count
                LOOP
                    l_fetus_number_tab(i) := l_fetus_number;
                END LOOP;
            
                g_error := 'call pk_delivery.set_delivery_vital_sign';
                IF NOT pk_delivery.set_delivery_vital_sign(i_lang            => i_lang,
                                                           i_episode         => i_episode,
                                                           i_prof            => i_prof,
                                                           i_patient         => i_pat,
                                                           i_pat_pregnancy   => l_id_pat_pregnancy,
                                                           i_flg_type        => 'S',
                                                           i_vs_id           => i_vs_id,
                                                           i_vs_val          => i_vs_val,
                                                           i_unit_meas       => i_unit_meas,
                                                           i_vs_date         => l_dt_vs_read,
                                                           i_fetus_number    => l_fetus_number_tab,
                                                           i_prof_cat_type   => i_prof_cat_type,
                                                           o_vital_sign_read => o_vital_sign_read,
                                                           o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        END IF;
    
        FOR i IN i_vs_id.first .. i_vs_id.last
        LOOP
            IF pk_vital_sign.get_vs_parent(i_vital_sign => i_vs_id(i)) IS NOT NULL
            THEN
                pk_types.open_my_cursor(o_value);
                RETURN TRUE;
            END IF;
        END LOOP;
    
        IF NOT get_values_return(i_lang            => i_lang,
                                 i_prof            => i_prof,
                                 i_patient         => i_pat,
                                 i_episode         => i_episode,
                                 i_params          => i_params,
                                 i_date            => i_dt_vs_read,
                                 i_woman_health_id => i_woman_health_id,
                                 o_value           => o_value,
                                 o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_value);
            pk_utils.undo_changes;
            RETURN FALSE;
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
            pk_types.open_my_cursor(o_value);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_vital_sign;
    ---------------------------------
    FUNCTION get_dt_str
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_date      IN VARCHAR2,
        i_date_mask IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN --
        CASE --
        WHEN i_date_mask = 'YYYY' AND length(i_date) >= 4 --
        THEN substr(i_date, 1, 4) --
        WHEN i_date_mask = 'YYYYMM' AND length(i_date) >= 6 --
        THEN pk_date_utils.get_month_year(i_lang, i_prof, to_date(substr(i_date, 1, 6), i_date_mask)) --
        WHEN i_date_mask = 'YYYYMMDD' AND length(i_date) >= 8 --
        THEN pk_date_utils.dt_chr(i_lang, to_date(substr(i_date, 1, 8), i_date_mask), i_prof) --
        WHEN i_date_mask = 'YYYYMMDDHH24MI' AND length(i_date) >= 12 --
        THEN pk_date_utils.dt_chr_date_hour(i_lang, to_date(substr(i_date, 1, 12), i_date_mask), i_prof) --
        ELSE NULL --
        END;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dt_str;
    ---------------------------------
    FUNCTION get_woman_health_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_woman_health_id IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_id_pat_pregnancy   pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
        l_return             sys_message.desc_message%TYPE;
    BEGIN
    
        IF NOT split_woman_health_id(i_woman_health_id    => i_woman_health_id,
                                     o_id_pat_pregnancy   => l_id_pat_pregnancy,
                                     o_id_pat_pregn_fetus => l_id_pat_pregn_fetus)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_id_pat_pregn_fetus IS NULL
        THEN
            l_return := pk_message.get_message(i_lang, i_prof, 'PREGNANCY_PO_T004');
        ELSE
            SELECT pk_message.get_message(i_lang, i_prof, 'PREGNANCY_PO_T005') || ' ' || ppf.fetus_number
              INTO l_return
              FROM pat_pregn_fetus ppf
             WHERE ppf.id_pat_pregn_fetus = l_id_pat_pregn_fetus;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_woman_health_desc;
    -------------------------------------------------------
    FUNCTION set_preg_po_param
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PREG_PO_PARAM';
        l_women_health_hpg_id sys_config.value%TYPE;
        l_flg_visible         preg_po_param.flg_visible%TYPE;
        l_rows                table_varchar;
    BEGIN
        l_women_health_hpg_id := pk_sysconfig.get_config('WOMEN_HEALTH_HPG_ID', i_prof);
    
        IF l_women_health_hpg_id IS NOT NULL
        THEN
            g_error := 'loop po_param_sets';
            FOR r_pph IN (SELECT pps.id_po_param, pps.id_inst_owner
                            FROM po_param_sets pps
                           WHERE pps.task_type_content = l_women_health_hpg_id
                             AND pps.id_institution = i_prof.institution
                             AND pps.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                             AND pps.flg_available = pk_alert_constant.g_yes)
            LOOP
                BEGIN
                    l_flg_visible := NULL;
                
                    SELECT ppp.flg_visible
                      INTO l_flg_visible
                      FROM preg_po_param ppp
                     WHERE ppp.id_pat_pregnancy = i_pat_pregnancy
                       AND ppp.id_po_param = r_pph.id_po_param
                       AND ppp.id_inst_owner = r_pph.id_inst_owner
                       AND ppp.flg_owner = g_flg_domain_m;
                EXCEPTION
                    WHEN no_data_found THEN
                    
                        ts_preg_po_param.ins(id_pat_pregnancy_in => i_pat_pregnancy,
                                             id_po_param_in      => r_pph.id_po_param,
                                             id_inst_owner_in    => r_pph.id_inst_owner,
                                             flg_owner_in        => g_flg_domain_m,
                                             flg_visible_in      => pk_alert_constant.g_yes,
                                             rows_out            => l_rows);
                    
                        g_error := 'CALL t_data_gov_mnt.process_insert ts_preg_po_param';
                        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'TS_PREG_PO_PARAM',
                                                      i_rowids     => l_rows,
                                                      o_error      => o_error);
                END;
            
                IF l_flg_visible = pk_alert_constant.g_no
                THEN
                    ts_preg_po_param.upd(id_pat_pregnancy_in => i_pat_pregnancy,
                                         id_po_param_in      => r_pph.id_po_param,
                                         id_inst_owner_in    => r_pph.id_inst_owner,
                                         flg_owner_in        => g_flg_domain_m,
                                         flg_visible_in      => pk_alert_constant.g_yes,
                                         rows_out            => l_rows);
                
                    g_error := 'CALL t_data_gov_mnt.process_update ts_preg_po_param';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'TS_PREG_PO_PARAM',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
                END IF;
            
            END LOOP;
        END IF;
    
        g_error := 'loop po_param_wh';
        FOR r_ppw IN (SELECT ppw.id_po_param, ppw.id_inst_owner, ppw.flg_owner
                        FROM po_param_wh ppw
                       WHERE ppw.id_institution = i_prof.institution
                         AND ppw.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                         AND ppw.flg_available = pk_alert_constant.g_yes)
        LOOP
            BEGIN
                l_flg_visible := NULL;
            
                SELECT ppp.flg_visible
                  INTO l_flg_visible
                  FROM preg_po_param ppp
                 WHERE ppp.id_pat_pregnancy = i_pat_pregnancy
                   AND ppp.id_po_param = r_ppw.id_po_param
                   AND ppp.id_inst_owner = r_ppw.id_inst_owner
                   AND ppp.flg_owner = r_ppw.flg_owner;
            EXCEPTION
                WHEN no_data_found THEN
                
                    ts_preg_po_param.ins(id_pat_pregnancy_in => i_pat_pregnancy,
                                         id_po_param_in      => r_ppw.id_po_param,
                                         id_inst_owner_in    => r_ppw.id_inst_owner,
                                         flg_owner_in        => r_ppw.flg_owner,
                                         flg_visible_in      => pk_alert_constant.g_yes,
                                         rows_out            => l_rows);
                
                    g_error := 'CALL t_data_gov_mnt.process_insert ts_preg_po_param';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'TS_PREG_PO_PARAM',
                                                  i_rowids     => l_rows,
                                                  o_error      => o_error);
            END;
        
            IF l_flg_visible = pk_alert_constant.g_no
            THEN
                ts_preg_po_param.upd(id_pat_pregnancy_in => i_pat_pregnancy,
                                     id_po_param_in      => r_ppw.id_po_param,
                                     id_inst_owner_in    => r_ppw.id_inst_owner,
                                     flg_owner_in        => r_ppw.flg_owner,
                                     flg_visible_in      => pk_alert_constant.g_yes,
                                     rows_out            => l_rows);
            
                g_error := 'CALL t_data_gov_mnt.process_update ts_preg_po_param';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'TS_PREG_PO_PARAM',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            END IF;
        
        END LOOP;
    
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_preg_po_param;
    -------------------------------------------------------
    FUNCTION has_vital_sign_val_ref(i_id_vital_sign IN vital_sign.id_vital_sign%TYPE) RETURN VARCHAR2 IS
        l_return VARCHAR2(1 CHAR);
    BEGIN
    
        SELECT pk_alert_constant.g_yes
          INTO l_return
          FROM event e
          JOIN time_event_group teg
            ON e.id_event_group = teg.id_event_group
           AND teg.intern_name = g_woman_health_det
         WHERE e.flg_group = g_vital_sign
           AND e.flg_most_freq = pk_alert_constant.g_yes
           AND e.id_group = i_id_vital_sign
           AND rownum = 1;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END has_vital_sign_val_ref;

    FUNCTION get_values_return
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_params          IN table_number,
        i_date            IN VARCHAR2,
        i_woman_health_id IN VARCHAR2,
        o_value           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_pat_pregnancy   pat_pregnancy.id_pat_pregnancy%TYPE;
        l_id_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_VALUES_RETURN';
    
        o_wh        pk_types.cursor_type;
        o_param     pk_types.cursor_type;
        o_wh_param  pk_types.cursor_type;
        o_time      pk_types.cursor_type;
        o_value_aux pk_types.cursor_type;
        o_ref       pk_types.cursor_type;
        o_values_wh t_coll_wh_values;
    BEGIN
    
        IF i_woman_health_id IS NOT NULL
        THEN
            g_error := 'CALL split_woman_health_id';
            IF NOT split_woman_health_id(i_woman_health_id    => i_woman_health_id,
                                         o_id_pat_pregnancy   => l_id_pat_pregnancy,
                                         o_id_pat_pregn_fetus => l_id_pat_pregn_fetus)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'CALL get_grid_wh';
            IF NOT get_grid_wh(i_lang          => i_lang,
                               i_prof          => i_prof,
                               i_patient       => i_patient,
                               i_episode       => i_episode,
                               i_pat_pregnancy => l_id_pat_pregnancy,
                               i_cursor_out    => 'VW',
                               o_wh            => o_wh,
                               o_param         => o_param,
                               o_wh_param      => o_wh_param,
                               o_time          => o_time,
                               o_value         => o_value_aux,
                               o_values_wh     => o_values_wh,
                               o_ref           => o_ref,
                               o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'OPEN o_value';
            OPEN o_value FOR
                SELECT *
                  FROM TABLE(CAST(o_values_wh AS t_coll_wh_values)) t
                 WHERE substr(t.time_id, 1, 8) = substr(i_date, 1, 8)
                   AND t.woman_health_id = i_woman_health_id
                   AND pk_utils.search_table_number(i_params, t.parameter_id) > 0;
        
        ELSE
            g_error := 'CALL get_grid_wh';
            IF NOT get_grid_param(i_lang       => i_lang,
                                  i_prof       => i_prof,
                                  i_patient    => i_patient,
                                  i_episode    => i_episode,
                                  i_cursor_out => 'VW',
                                  o_param      => o_param,
                                  o_time       => o_time,
                                  o_value      => o_value_aux,
                                  o_values_wh  => o_values_wh,
                                  o_ref        => o_ref,
                                  o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'OPEN o_value';
            OPEN o_value FOR
                SELECT t.time_id, i_date, t.*
                  FROM TABLE(CAST(o_values_wh AS t_coll_wh_values)) t
                 WHERE t.time_id = i_date
                   AND pk_utils.search_table_number(i_params, t.parameter_id) > 0;
        
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_values_return;

    /*****************************************************************************
    * Retrieve a collection with all mapped events, given the patient's current
    * health program inscriptions. Medication events are retrieved externally,
    * and therefore, separated.
    *
    * @param i_prof        logged professional structure
    * @param i_patient     patient identifier
    * @param o_hpg         table_info collection (other events
    * @param o_med         table_index_varchar collection (g_med_local and g_med_ext events)
    *
    * @author              Pedro Carneiro
    * @version              1.0
    * @since               2009/05/22
    *******************************************************************************/
    PROCEDURE get_health_programs_events
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_hpg     OUT table_info,
        o_med     OUT table_index_varchar
    ) IS
        l_hpg_event  table_number := table_number();
        l_hpg_group  table_number := table_number();
        l_hpg_flg    table_varchar := table_varchar();
        l_hpg_events table_info := table_info();
        l_med        table_index_varchar := table_index_varchar();
        l_med_idx    PLS_INTEGER := 1;
    
        CURSOR c_hpg IS
            SELECT id_event, e.id_group, e.flg_group
              FROM pat_health_program phpg
              JOIN health_program_event hpe
             USING (id_health_program)
              JOIN event e
             USING (id_event)
             WHERE phpg.id_patient = i_patient
               AND phpg.id_software = i_prof.software
               AND phpg.id_institution = i_prof.institution
               AND phpg.flg_status != pk_health_program.g_flg_status_cancelled
               AND hpe.id_software IN (0, i_prof.software)
               AND hpe.id_institution IN (0, i_prof.institution)
               AND hpe.flg_active = g_yes;
    
    BEGIN
        g_error := 'OPEN c_hpg';
        OPEN c_hpg;
        FETCH c_hpg BULK COLLECT
            INTO l_hpg_event, l_hpg_group, l_hpg_flg;
        CLOSE c_hpg;
    
        g_error := 'LOOP fill collections';
        FOR i IN 1 .. l_hpg_event.count
        LOOP
            IF l_hpg_flg(i) = g_med_local
            THEN
                l_med.extend;
                l_med(l_med_idx) := index_varchar(to_char(l_hpg_group(i)), pk_api_pfh_in.g_int_drug);
                l_med_idx := l_med_idx + 1;
            ELSIF l_hpg_flg(i) = g_med_ext
            THEN
                l_med.extend;
                l_med(l_med_idx) := index_varchar(to_char(l_hpg_group(i)), pk_api_pfh_in.g_ext_drug);
                l_med_idx := l_med_idx + 1;
            END IF;
        
            l_hpg_events.extend;
            l_hpg_events(i) := info(l_hpg_event(i), l_hpg_flg(i), NULL);
        END LOOP;
    
        o_hpg := l_hpg_events;
        o_med := l_med;
    END get_health_programs_events;

    /************************************************************************************************************
    * Réplica da função get_periodic_observation_all mas o cursor o_periodic_observation_val retorna os campos
    * separados em vez de unidos por pipes
    *
    * @param      i_lang                Língua registada como preferência do profissional
    * @param      i_patient             ID do paciente
    * @param      i_prof                ID do profissional
    * @param      i_episode             ID do episode
    *
    * @param      o_periodic_observation_time      Cursor com a informação dos tempos (colunas)
    * @param      o_periodic_observation_par       Cursor com a informação dos parâmetros (linhas)
    * @param      o_periodic_observation_val       Cursor com a informação dos valores
    * @param      o_error              Erro
    *
    * @return     true em caso de sucesso e false caso contrário
    * @author     Pedro Teixeira
    * @version    0.1
    * @since      2009/07/14
    ***********************************************************************************************************/
    FUNCTION get_periodic_observation_rep
    (
        i_lang                      IN language.id_language%TYPE,
        i_patient                   IN patient.id_patient%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        o_periodic_observation_time OUT pk_types.cursor_type,
        o_periodic_observation_par  OUT pk_types.cursor_type,
        o_periodic_observation_val  OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PERIODIC_OBSERVATION_REP';
        l_times    pk_types.cursor_type;
        l_vals     pk_types.cursor_type;
        l_vals_wh  t_coll_wh_values;
        l_time_tmp table_table_varchar;
        o_ref      pk_types.cursor_type;
    
        l_dummy_1 table_varchar := table_varchar();
        l_dummy_2 table_varchar := table_varchar();
        l_dummy_3 table_varchar := table_varchar();
        l_dummy_4 table_varchar := table_varchar();
        ----------------------------------------------
        l_pipe_1 table_varchar := table_varchar();
        l_pipe_2 table_varchar := table_varchar();
        l_pipe_3 table_varchar := table_varchar();
        l_pipe_4 table_varchar := table_varchar();
        l_pipe_5 table_varchar := table_varchar();
        l_pipe_6 table_varchar := table_varchar();
        ----------------------------------------------
        l_last_pipe_pos NUMBER;
    
    BEGIN
    
        g_error := 'CALL get_grid_param';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF NOT get_grid_param(i_lang       => i_lang,
                              i_prof       => i_prof,
                              i_patient    => i_patient,
                              i_episode    => i_episode,
                              i_cursor_out => 'A',
                              o_param      => o_periodic_observation_par,
                              o_time       => l_times,
                              o_value      => l_vals,
                              o_values_wh  => l_vals_wh,
                              o_ref        => o_ref,
                              o_error      => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        l_time_tmp := table_table_varchar();
        l_time_tmp.extend(5);
    
        g_error := 'FETCH l_times';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        FETCH l_times BULK COLLECT
            INTO l_time_tmp(1), l_time_tmp(2), l_time_tmp(3), l_time_tmp(4), l_time_tmp(5);
        CLOSE l_times;
    
        g_error := 'OPEN o_periodic_observation_time';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_periodic_observation_time FOR
            SELECT t1.name time_var,
                   t2.name dt_periodic_observation_reg,
                   t3.name hour_read,
                   pk_date_utils.dt_chr_str(i_lang, t4.name, i_prof, NULL) date_read,
                   t5.name header_desc
              FROM (SELECT rownum rnum, column_value name
                      FROM TABLE(l_time_tmp(1))) t1,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_time_tmp(2))) t2,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_time_tmp(3))) t3,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_time_tmp(4))) t4,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_time_tmp(5))) t5
             WHERE t1.rnum = t2.rnum
               AND t1.rnum = t3.rnum
               AND t1.rnum = t4.rnum
               AND t1.rnum = t5.rnum;
    
        g_error := 'FETCH l_vals';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        FETCH l_vals BULK COLLECT
            INTO l_dummy_1, l_dummy_2, l_dummy_3, l_dummy_4;
        CLOSE l_vals;
    
        FOR i IN 1 .. l_dummy_3.count
        LOOP
            l_last_pipe_pos := 0;
            IF l_dummy_3(i) IS NOT NULL
            THEN
                l_pipe_1.extend;
                l_pipe_1(i) := substr(l_dummy_3(i), l_last_pipe_pos, instr(l_dummy_3(i), '|', 1, 1) - 1);
                --------------------------------------------------------
                l_last_pipe_pos := instr(l_dummy_3(i), '|', 1, 1) + 1;
                l_pipe_2.extend;
                l_pipe_2(i) := substr(l_dummy_3(i),
                                      l_last_pipe_pos,
                                      instr(l_dummy_3(i), '|', 1, 2) - instr(l_dummy_3(i), '|', 1, 1) - 1);
                --------------------------------------------------------
                l_last_pipe_pos := instr(l_dummy_3(i), '|', 1, 2) + 1;
                l_pipe_3.extend;
                l_pipe_3(i) := substr(l_dummy_3(i),
                                      l_last_pipe_pos,
                                      instr(l_dummy_3(i), '|', 1, 3) - instr(l_dummy_3(i), '|', 1, 2) - 1);
                --------------------------------------------------------
                l_last_pipe_pos := instr(l_dummy_3(i), '|', 1, 3) + 1;
                l_pipe_4.extend;
                l_pipe_4(i) := substr(l_dummy_3(i),
                                      l_last_pipe_pos,
                                      instr(l_dummy_3(i), '|', 1, 4) - instr(l_dummy_3(i), '|', 1, 3) - 1);
                --------------------------------------------------------
                l_last_pipe_pos := instr(l_dummy_3(i), '|', 1, 4) + 1;
                l_pipe_5.extend;
                l_pipe_5(i) := substr(l_dummy_3(i),
                                      l_last_pipe_pos,
                                      instr(l_dummy_3(i), '|', 1, 5) - instr(l_dummy_3(i), '|', 1, 4) - 1);
                --------------------------------------------------------
                l_last_pipe_pos := instr(l_dummy_3(i), '|', 1, 5) + 1;
                l_pipe_6.extend;
                l_pipe_6(i) := substr(l_dummy_3(i),
                                      l_last_pipe_pos,
                                      instr(l_dummy_3(i), '|', 1, 6) - instr(l_dummy_3(i), '|', 1, 5) - 1);
                --------------------------------------------------------
            END IF;
        END LOOP;
    
        g_error := 'OPEN o_periodic_observation_val';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_periodic_observation_val FOR
            SELECT a.name  time_var,
                   b.name  par_var,
                   p1.name p1,
                   p2.name p2,
                   p3.name p3,
                   p4.name p4,
                   p5.name p5,
                   p6.name p6
              FROM (SELECT rownum rnum, column_value name
                      FROM TABLE(l_dummy_1)) a,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_dummy_2)) b,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_pipe_1)) p1,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_pipe_2)) p2,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_pipe_3)) p3,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_pipe_4)) p4,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_pipe_5)) p5,
                   (SELECT rownum rnum, column_value name
                      FROM TABLE(l_pipe_6)) p6
             WHERE a.rnum = b.rnum
               AND a.rnum = p1.rnum
               AND a.rnum = p2.rnum
               AND a.rnum = p3.rnum
               AND a.rnum = p4.rnum
               AND a.rnum = p5.rnum
               AND a.rnum = p6.rnum;
    
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
            pk_types.open_cursor_if_closed(i_cursor => o_periodic_observation_time);
            pk_types.open_cursor_if_closed(i_cursor => o_periodic_observation_par);
            pk_types.open_cursor_if_closed(i_cursor => o_periodic_observation_val);
            RETURN FALSE;
    END get_periodic_observation_rep;
    FUNCTION get_value_coll_pl
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_po_value_pl IS
    
        l_ret t_coll_po_value_pl;
    
        l_decimal_symbol sys_config.value%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf => pk_touch_option.g_scfg_decimal_separator,
                                                    i_prof    => i_prof);
    
        -- get values
        g_error := 'SELECT l_ret';
        SELECT t_rec_po_value_pl(t.id_parameter,
                                 t.flg_type,
                                 t.id_result,
                                 t.id_episode,
                                 t.id_institution,
                                 t.id_prof_reg,
                                 t.dt_result,
                                 t.dt_reg,
                                 t.flg_status,
                                 t.desc_result,
                                 t.id_unit_measure,
                                 t.desc_unit_measure,
                                 t.icon,
                                 t.lab_param_count,
                                 t.lab_param_id,
                                 t.lab_param_rank,
                                 t.val_min,
                                 t.val_max,
                                 t.abnorm_value,
                                 t.option_codes,
                                 t.flg_cancel,
                                 t.dt_cancel,
                                 t.id_prof_cancel,
                                 t.id_cancel_reason,
                                 to_clob(t.notes_cancel),
                                 t.woman_health_id,
                                 t.flg_ref_value,
                                 t.dt_harvest,
                                 t.dt_execution,
                                 to_clob(t.notes),
                                 t.id_sample_type)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT ar.id_analysis id_parameter,
                       g_analysis flg_type,
                       ar.id_analysis_result id_result,
                       ar.id_episode_orig id_episode,
                       ar.id_institution,
                       ar.id_professional id_prof_reg,
                       nvl(arp.dt_analysis_result_par_upd, arp.dt_analysis_result_par_tstz) dt_result,
                       coalesce(arp.dt_ins_result_tstz,
                                lte.dt_harvest,
                                arp.dt_analysis_result_par_upd,
                                ar.dt_sample,
                                ar.dt_analysis_result_tstz) dt_reg,
                       nvl(ar.flg_status, pk_alert_constant.g_active) flg_status,
                       to_clob((SELECT nvl(TRIM(arp.desc_analysis_result),
                                          pk_utils.to_str(arp.analysis_result_value, l_decimal_symbol))
                                 FROM dual)) desc_result,
                       arp.desc_unit_measure,
                       arp.id_unit_measure,
                       NULL icon,
                       pk_lab_tests_external_api_db.get_lab_test_param_count(i_prof, ar.id_analysis, ar.id_sample_type) lab_param_count,
                       arp.id_analysis_parameter lab_param_id,
                       row_number() over(PARTITION BY ar.id_analysis_result, arp.id_analysis_parameter ORDER BY apr.rank) lab_param_rank,
                       nvl(TRIM(arp.ref_val_min_str), arp.ref_val_min) val_min,
                       nvl(TRIM(arp.ref_val_max_str), arp.ref_val_max) val_max,
                       CASE
                            WHEN pk_utils.is_number(pk_string_utils.clob_to_sqlvarchar2(arp.desc_analysis_result)) = 'Y' THEN
                             CASE
                             
                                 WHEN nvl(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                    '999999999999999999999999D999',
                                                    'NLS_NUMERIC_CHARACTERS='', '''),
                                          arp.analysis_result_value) < arp.ref_val_min THEN
                                  'D'
                                 WHEN nvl(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                    '999999999999999999999999D999',
                                                    'NLS_NUMERIC_CHARACTERS='', '''),
                                          arp.analysis_result_value) > arp.ref_val_max THEN
                                  'U'
                                 ELSE
                                  NULL
                             END
                            ELSE
                             NULL
                        END abnorm_value,
                       table_varchar() option_codes,
                       decode(ar.flg_status,
                              pk_alert_constant.g_cancelled,
                              pk_alert_constant.g_no,
                              pk_alert_constant.g_yes) flg_cancel,
                       arp.dt_cancel,
                       arp.id_professional_cancel id_prof_cancel,
                       arp.id_cancel_reason,
                       arp.notes_cancel,
                       NULL woman_health_id,
                       pk_alert_constant.g_no flg_ref_value,
                       ar.dt_sample dt_harvest,
                       NULL dt_execution,
                       ar.notes notes,
                       ar.id_sample_type id_sample_type
                  FROM analysis_result ar
                  JOIN analysis_result_par arp
                    ON ar.id_analysis_result = arp.id_analysis_result
                  JOIN analysis_parameter apr
                    ON arp.id_analysis_parameter = apr.id_analysis_parameter
                  LEFT JOIN lab_tests_ea lte
                    ON ar.id_analysis_req_det = lte.id_analysis_req_det
                 WHERE ar.id_patient = i_patient
                UNION ALL
                SELECT vsr.id_vital_sign id_parameter,
                       g_vital_sign flg_type,
                       vsr.id_vital_sign_read id_result,
                       vsr.id_episode,
                       vsr.id_institution_read id_institution,
                       vsr.id_prof_read id_prof_reg,
                       vsr.dt_vital_sign_read_tstz dt_result,
                       vsr.dt_registry dt_reg,
                       vsr.flg_state flg_status,
                       to_clob(pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                                          i_prof               => i_prof,
                                                          i_patient            => vsr.id_patient,
                                                          i_episode            => vsr.id_episode,
                                                          i_vital_sign         => vsr.id_vital_sign,
                                                          i_value              => vsr.value,
                                                          i_vs_unit_measure    => vsr.id_unit_measure,
                                                          i_vital_sign_desc    => vsr.id_vital_sign_desc,
                                                          i_vs_scales_element  => vsr.id_vs_scales_element,
                                                          i_dt_vital_sign_read => vsr.dt_vital_sign_read_tstz,
                                                          i_ea_unit_measure    => vsr.id_unit_measure,
                                                          i_short_desc         => pk_alert_constant.g_no,
                                                          i_decimal_symbol     => l_decimal_symbol,
                                                          i_dt_registry        => vsr.dt_registry)) desc_result,
                       (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                         vsr.id_unit_measure,
                                                                         vsr.id_vs_scales_element)
                          FROM dual) desc_unit_measure,
                       vsr.id_unit_measure,
                       vsd.icon,
                       NULL lab_param_count,
                       NULL lab_param_id,
                       NULL lab_param_rank,
                       NULL val_min,
                       NULL val_max,
                       NULL abnorm_value,
                       table_varchar() option_codes,
                       CASE
                           WHEN vsr.flg_state = pk_alert_constant.g_cancelled THEN
                            pk_alert_constant.g_no
                           ELSE
                            decode(pk_vital_sign.get_vs_parent(i_vital_sign => vsr.id_vital_sign),
                                   NULL,
                                   pk_alert_constant.g_yes,
                                   pk_alert_constant.g_no)
                       END flg_cancel,
                       vsr.dt_cancel_tstz dt_cancel,
                       vsr.id_prof_cancel,
                       NULL id_cancel_reason,
                       vsr.notes_cancel,
                       NULL woman_health_id,
                       pk_alert_constant.g_no flg_ref_value,
                       NULL dt_harvest,
                       NULL dt_execution,
                       NULL notes,
                       NULL id_sample_type
                  FROM vital_sign_read vsr
                  LEFT JOIN vital_sign_desc vsd
                    ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
                 WHERE vsr.id_patient = i_patient
                   AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                UNION ALL
                SELECT vs_comp.id_vital_sign_parent id_parameter,
                       g_vital_sign flg_type,
                       vs_comp.id_vital_sign_read id_result,
                       vs_comp.id_episode,
                       vs_comp.id_institution_read id_institution,
                       vs_comp.id_prof_read id_prof_reg,
                       vs_comp.dt_vital_sign_read_tstz dt_result,
                       vs_comp.dt_registry dt_reg,
                       vs_comp.flg_state flg_status,
                       to_clob(decode(relation_domain,
                                      g_vs_rel_conc,
                                      pk_vital_sign.get_bloodpressure_value(i_vital_sign         => vs_comp.id_vital_sign_parent,
                                                                            i_patient            => i_patient,
                                                                            i_episode            => vs_comp.id_episode,
                                                                            i_dt_vital_sign_read => vs_comp.dt_vital_sign_read_tstz,
                                                                            i_decimal_symbol     => l_decimal_symbol,
                                                                            i_dt_registry        => vs_comp.dt_registry),
                                      pk_vital_sign.get_glasgowtotal_value_hist(vs_comp.id_vital_sign_parent,
                                                                                i_patient,
                                                                                vs_comp.id_episode,
                                                                                vs_comp.dt_vital_sign_read_tstz,
                                                                                vs_comp.dt_registry))) desc_result,
                       (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                         vs_comp.id_unit_measure,
                                                                         vs_comp.id_vs_scales_element)
                          FROM dual) desc_unit_measure,
                       vs_comp.id_unit_measure,
                       NULL icon,
                       NULL lab_param_count,
                       NULL lab_param_id,
                       NULL lab_param_rank,
                       NULL val_min,
                       NULL val_max,
                       NULL abnorm_value,
                       table_varchar() option_codes,
                       decode(vs_comp.flg_state,
                              pk_alert_constant.g_cancelled,
                              pk_alert_constant.g_no,
                              pk_alert_constant.g_yes) flg_cancel,
                       vs_comp.dt_cancel_tstz dt_cancel,
                       vs_comp.id_prof_cancel,
                       NULL id_cancel_reason,
                       vs_comp.notes_cancel,
                       NULL woman_health_id,
                       pk_alert_constant.g_no flg_ref_value,
                       NULL dt_harvest,
                       NULL dt_execution,
                       NULL notes,
                       NULL id_sample_type
                  FROM (SELECT vsre.id_vital_sign_parent,
                               vsr.id_vital_sign_read,
                               vsr.id_episode,
                               vsr.id_institution_read,
                               vsr.id_prof_read,
                               vsr.dt_vital_sign_read_tstz,
                               vsr.dt_registry,
                               vsr.flg_state,
                               vsr.id_unit_measure,
                               vsr.id_vs_scales_element,
                               vsr.dt_cancel_tstz,
                               vsr.id_prof_cancel,
                               vsr.notes_cancel,
                               vsre.relation_domain,
                               --row_number() over(PARTITION BY vsr.dt_registry ORDER BY vsr.id_vital_sign_read DESC) rn
                               row_number() over(PARTITION BY vsr.dt_registry, vsre.id_vital_sign_parent ORDER BY vsre.rank ASC) rn
                          FROM vital_sign_read vsr
                          JOIN vital_sign_relation vsre
                            ON vsr.id_vital_sign = vsre.id_vital_sign_detail
                         WHERE vsr.id_patient = i_patient
                           AND vsre.relation_domain IN (g_vs_rel_conc, g_vs_rel_sum)) vs_comp
                 WHERE vs_comp.rn = 1
                   AND pk_delivery.check_vs_read_from_fetus(vs_comp.id_vital_sign_read) = 0
                UNION ALL
                --sinais vitais ref value
                SELECT emf.id_group id_parameter,
                       g_vital_sign flg_type,
                       emf.id_event_most_freq id_result,
                       emf.id_episode,
                       emf.id_institution_read id_institution,
                       emf.id_prof_read id_prof_reg,
                       emf.dt_event_most_freq_tstz dt_result,
                       emf.dt_event_most_freq_tstz dt_reg,
                       nvl(emf.flg_status, pk_alert_constant.g_active) flg_status,
                       to_clob(emf.value) desc_result,
                       (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang, emf.id_unit_measure, NULL)
                          FROM dual) desc_unit_measure,
                       emf.id_unit_measure id_unit_measure,
                       NULL icon,
                       NULL lab_param_count,
                       NULL lab_param_id,
                       NULL lab_param_rank,
                       NULL val_min,
                       NULL val_max,
                       NULL abnorm_value,
                       table_varchar() option_codes,
                       decode(emf.flg_status,
                              pk_alert_constant.g_cancelled,
                              pk_alert_constant.g_no,
                              pk_alert_constant.g_yes) flg_cancel,
                       emf.dt_cancel dt_cancel,
                       emf.id_prof_cancel id_prof_cancel,
                       NULL id_cancel_reason,
                       NULL notes_cancel,
                       NULL woman_health_id,
                       pk_alert_constant.g_yes flg_ref_value,
                       NULL dt_harvest,
                       NULL dt_execution,
                       NULL notes,
                       NULL id_sample_type
                  FROM event_most_freq emf
                 WHERE emf.id_patient = i_patient
                   AND emf.flg_group = g_vital_sign
                   AND emf.id_pat_pregn_fetus IS NULL
                   AND emf.id_pat_pregnancy IS NULL
                UNION ALL
                SELECT ea.id_exam id_parameter,
                       g_exam flg_type,
                       ea.id_exam_result id_result,
                       er.id_episode_write id_episode,
                       er.id_institution,
                       er.id_professional id_prof_reg,
                       nvl(ea.start_time, ea.dt_result) dt_result,
                       er.dt_exam_result_tstz dt_reg,
                       er.flg_status,
                       --ALERT-154864                       
                       to_clob(nvl(ea.desc_result,
                                   pk_sysdomain.get_domain(g_exam_req_status_domain, ea.flg_status_req, i_lang))) desc_result,
                       NULL desc_unit_measure,
                       NULL id_unit_measure,
                       pk_sysdomain.get_img(i_lang, g_exam_req_status_domain, ea.flg_status_req) icon,
                       NULL lab_param_count,
                       NULL lab_param_id,
                       NULL lab_param_rank,
                       NULL val_min,
                       NULL val_max,
                       NULL abnorm_value,
                       table_varchar() option_codes,
                       pk_alert_constant.g_no flg_cancel,
                       er.dt_exam_result_cancel_tstz dt_cancel,
                       er.id_prof_cancel,
                       NULL id_cancel_reason,
                       NULL notes_cancel,
                       NULL woman_health_id,
                       pk_alert_constant.g_no flg_ref_value,
                       NULL dt_harvest,
                       nvl(ea.start_time, ea.dt_result) dt_execution,
                       NULL notes,
                       NULL id_sample_type
                  FROM exams_ea ea
                  JOIN exam_result er
                    ON ea.id_exam_result = er.id_exam_result
                 WHERE er.id_patient = i_patient
                UNION ALL
                SELECT nvl(pop.id_parameter, pop.id_po_param) id_parameter,
                       pop.flg_type,
                       popr.id_po_param_reg id_result,
                       popr.id_episode,
                       e.id_institution,
                       popr.id_professional id_prof_reg,
                       popr.dt_result,
                       popr.dt_creation dt_reg,
                       popr.flg_status,
                       CASE
                           WHEN pop.flg_fill_type = g_free_text THEN
                            popr.free_text
                           WHEN pop.flg_fill_type = g_free_date THEN
                            to_clob(get_dt_str(i_lang, i_prof, popr.free_date, popr.free_date_mask))
                           ELSE
                            to_clob(popr.value)
                       END desc_result,
                       NULL desc_unit_measure,
                       popr.id_unit_measure,
                       (SELECT get_reg_opt_icon(i_lang, popr.id_po_param_reg)
                          FROM dual) icon,
                       NULL lab_param_count,
                       NULL lab_param_id,
                       NULL lab_param_rank,
                       NULL val_min,
                       NULL val_max,
                       NULL abnorm_value,
                       popr.option_codes,
                       decode(pop.flg_type,
                              g_others,
                              decode(popr.flg_status,
                                     pk_alert_constant.g_cancelled,
                                     pk_alert_constant.g_no,
                                     decode(popr.id_professional,
                                            i_prof.id,
                                            pk_alert_constant.g_yes,
                                            pk_alert_constant.g_no)),
                              pk_alert_constant.g_no) flg_cancel,
                       popr.dt_cancel,
                       popr.id_prof_cancel,
                       popr.id_cancel_reason,
                       pk_string_utils.clob_to_sqlvarchar2(popr.notes_cancel) notes_cancel,
                       NULL woman_health_id,
                       nvl(popr.flg_ref_value, pk_alert_constant.g_no) flg_ref_value,
                       NULL dt_harvest,
                       NULL dt_execution,
                       NULL notes,
                       NULL id_sample_type
                  FROM (SELECT (SELECT get_reg_opt_codes(popr.id_po_param_reg)
                                  FROM dual) option_codes,
                               popr.*
                          FROM po_param_reg popr
                         WHERE popr.id_patient = i_patient
                           AND popr.id_pat_pregn_fetus IS NULL) popr
                  JOIN po_param pop
                    ON popr.id_po_param = pop.id_po_param
                   AND popr.id_inst_owner = pop.id_inst_owner
                  JOIN episode e
                    ON popr.id_episode = e.id_episode
                 WHERE popr.id_patient = i_patient) t;
    
        RETURN l_ret;
    END get_value_coll_pl;

    FUNCTION get_value_coll_fetus_pl
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_pat_pregnancy IN pat_pregnancy.id_pat_pregnancy%TYPE,
        i_dt_ini        IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_fim        IN pat_pregnancy.dt_init_pregnancy%TYPE
    ) RETURN t_coll_po_value_pl IS
    
        l_ret t_coll_po_value_pl;
    
        l_decimal_symbol sys_config.value%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf => pk_touch_option.g_scfg_decimal_separator,
                                                    i_prof    => i_prof);
    
        -- get values
        g_error := 'SELECT l_ret';
        SELECT t_rec_po_value_pl(t.id_parameter,
                                 t.flg_type,
                                 t.id_result,
                                 t.id_episode,
                                 t.id_institution,
                                 t.id_prof_reg,
                                 t.dt_result,
                                 t.dt_reg,
                                 t.flg_status,
                                 to_clob(t.desc_result),
                                 t.id_unit_measure,
                                 t.desc_unit_measure,
                                 t.icon,
                                 t.lab_param_count,
                                 t.lab_param_id,
                                 t.lab_param_rank,
                                 t.val_min,
                                 t.val_max,
                                 t.abnorm_value,
                                 t.option_codes,
                                 t.flg_cancel,
                                 t.dt_cancel,
                                 t.id_prof_cancel,
                                 t.id_cancel_reason,
                                 to_clob(t.notes_cancel),
                                 t.woman_health_id,
                                 t.flg_ref_value,
                                 t.dt_harvest,
                                 t.dt_execution,
                                 to_clob(t.notes),
                                 t.id_sample_type)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT vsr.id_vital_sign id_parameter,
                       g_vital_sign flg_type,
                       vsr.id_vital_sign_read id_result,
                       vsr.id_episode,
                       vsr.id_institution_read id_institution,
                       vsr.id_prof_read id_prof_reg,
                       vsr.dt_vital_sign_read_tstz dt_result,
                       vsr.dt_registry dt_reg,
                       vsr.flg_state flg_status,
                       pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                                  i_prof               => i_prof,
                                                  i_patient            => vsr.id_patient,
                                                  i_episode            => vsr.id_episode,
                                                  i_vital_sign         => vsr.id_vital_sign,
                                                  i_value              => vsr.value,
                                                  i_vs_unit_measure    => vsr.id_unit_measure,
                                                  i_vital_sign_desc    => vsr.id_vital_sign_desc,
                                                  i_vs_scales_element  => vsr.id_vs_scales_element,
                                                  i_dt_vital_sign_read => vsr.dt_vital_sign_read_tstz,
                                                  i_ea_unit_measure    => vsr.id_unit_measure,
                                                  i_short_desc         => pk_alert_constant.g_no,
                                                  i_decimal_symbol     => l_decimal_symbol,
                                                  i_dt_registry        => vsr.dt_registry) desc_result,
                       (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                         vsr.id_unit_measure,
                                                                         vsr.id_vs_scales_element)
                          FROM dual) desc_unit_measure,
                       vsr.id_unit_measure,
                       vsd.icon,
                       NULL lab_param_count,
                       NULL lab_param_id,
                       NULL lab_param_rank,
                       NULL val_min,
                       NULL val_max,
                       NULL abnorm_value,
                       table_varchar() option_codes,
                       decode(vsr.flg_state,
                              pk_alert_constant.g_cancelled,
                              pk_alert_constant.g_no,
                              pk_alert_constant.g_yes) flg_cancel,
                       vsr.dt_cancel_tstz dt_cancel,
                       vsr.id_prof_cancel,
                       NULL id_cancel_reason,
                       vsr.notes_cancel,
                       i_pat_pregnancy || '|' || ppf.id_pat_pregn_fetus woman_health_id,
                       pk_alert_constant.g_no flg_ref_value,
                       NULL dt_harvest,
                       NULL dt_execution,
                       NULL notes,
                       NULL id_sample_type
                  FROM vital_sign_read vsr
                  LEFT JOIN vital_sign_desc vsd
                    ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
                  JOIN vital_sign_pregnancy vsp
                    ON vsp.id_pat_pregnancy = i_pat_pregnancy
                   AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
                  JOIN pat_pregn_fetus ppf
                    ON ppf.id_pat_pregnancy = vsp.id_pat_pregnancy
                   AND ppf.fetus_number = vsp.fetus_number
                 WHERE vsr.id_patient = i_patient
                   AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 1
                   AND vsr.dt_vital_sign_read_tstz BETWEEN i_dt_ini AND i_dt_fim
                UNION ALL
                SELECT vs_comp.id_vital_sign_parent id_parameter,
                       g_vital_sign flg_type,
                       vs_comp.id_vital_sign_read id_result,
                       vs_comp.id_episode,
                       vs_comp.id_institution_read id_institution,
                       vs_comp.id_prof_read id_prof_reg,
                       vs_comp.dt_vital_sign_read_tstz dt_result,
                       vs_comp.dt_registry dt_reg,
                       vs_comp.flg_state flg_status,
                       pk_vital_sign.get_bloodpressure_value(i_vital_sign         => vs_comp.id_vital_sign_parent,
                                                             i_patient            => i_patient,
                                                             i_episode            => vs_comp.id_episode,
                                                             i_dt_vital_sign_read => vs_comp.dt_vital_sign_read_tstz,
                                                             i_decimal_symbol     => l_decimal_symbol,
                                                             i_pat_pregn_fetus    => vs_comp.id_pat_pregn_fetus,
                                                             i_dt_registry        => vs_comp.dt_registry) desc_result,
                       (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                         vs_comp.id_unit_measure,
                                                                         vs_comp.id_vs_scales_element)
                          FROM dual) desc_unit_measure,
                       vs_comp.id_unit_measure,
                       NULL icon,
                       NULL lab_param_count,
                       NULL lab_param_id,
                       NULL lab_param_rank,
                       NULL val_min,
                       NULL val_max,
                       NULL abnorm_value,
                       table_varchar() option_codes,
                       decode(vs_comp.flg_state,
                              pk_alert_constant.g_cancelled,
                              pk_alert_constant.g_no,
                              pk_alert_constant.g_yes) flg_cancel,
                       vs_comp.dt_cancel_tstz dt_cancel,
                       vs_comp.id_prof_cancel,
                       NULL id_cancel_reason,
                       vs_comp.notes_cancel,
                       i_pat_pregnancy || '|' || vs_comp.id_pat_pregn_fetus woman_health_id,
                       pk_alert_constant.g_no flg_ref_value,
                       NULL dt_harvest,
                       NULL dt_execution,
                       NULL notes,
                       NULL id_sample_type
                  FROM (SELECT vsre.id_vital_sign_parent,
                               vsr.id_vital_sign_read,
                               vsr.id_episode,
                               vsr.id_institution_read,
                               vsr.id_prof_read,
                               vsr.dt_vital_sign_read_tstz,
                               vsr.dt_registry,
                               vsr.flg_state,
                               vsr.id_unit_measure,
                               vsr.id_vs_scales_element,
                               vsr.dt_cancel_tstz,
                               vsr.id_prof_cancel,
                               vsr.notes_cancel,
                               row_number() over(PARTITION BY vsr.dt_registry ORDER BY vsr.id_vital_sign_read DESC) rn,
                               ppf.id_pat_pregn_fetus
                          FROM vital_sign_read vsr
                          JOIN vital_sign_relation vsre
                            ON vsr.id_vital_sign = vsre.id_vital_sign_detail
                          JOIN vital_sign_pregnancy vsp
                            ON vsp.id_pat_pregnancy = i_pat_pregnancy
                           AND vsp.id_vital_sign_read = vsr.id_vital_sign_read
                          JOIN pat_pregn_fetus ppf
                            ON ppf.id_pat_pregnancy = vsp.id_pat_pregnancy
                           AND ppf.fetus_number = vsp.fetus_number
                         WHERE vsr.id_patient = i_patient
                           AND vsre.relation_domain = g_vs_rel_conc
                           AND vsr.dt_vital_sign_read_tstz BETWEEN i_dt_ini AND i_dt_fim) vs_comp
                 WHERE vs_comp.rn = 1
                   AND pk_delivery.check_vs_read_from_fetus(vs_comp.id_vital_sign_read) = 1) t;
    
        RETURN l_ret;
    END get_value_coll_fetus_pl;

    FUNCTION set_po_param_reg_inactive
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_po_param_reg table_number;
        l_rows         table_varchar;
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'set_po_param_reg_inactive';
        l_dt_ini           pat_pregnancy.dt_init_pregnancy%TYPE;
        l_dt_fim           pat_pregnancy.dt_init_pregnancy%TYPE;
        l_id_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE;
    BEGIN
    
        BEGIN
            BEGIN
                SELECT pp.id_pat_pregnancy
                  INTO l_id_pat_pregnancy
                  FROM pat_pregnancy pp
                 WHERE pp.id_patient = i_patient
                   AND pp.flg_status = pk_pregnancy_core.g_pat_pregn_active
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            IF l_id_pat_pregnancy IS NOT NULL
            THEN
                g_error := 'call get_pregn_interval_dates';
                IF NOT get_pregn_interval_dates(i_pat_pregnancy => l_id_pat_pregnancy,
                                                o_dt_ini        => l_dt_ini,
                                                o_dt_fim        => l_dt_fim)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END;
    
        -- get parameter related data
    
        SELECT popr.id_po_param_reg
          BULK COLLECT
          INTO l_po_param_reg
          FROM po_param_reg popr
         WHERE popr.id_po_param IS NULL
           AND popr.id_episode = i_episode
           AND popr.flg_status = pk_alert_constant.g_active
           AND nvl(popr.flg_ref_value, pk_alert_constant.g_no) = pk_alert_constant.g_no
           AND NOT EXISTS (SELECT 1
                  FROM TABLE(get_value_coll_pl(i_lang, i_prof, popr.id_patient)) t
                 WHERE t.dt_result = popr.dt_result
                   AND t.id_episode = popr.id_episode)
           AND NOT EXISTS (SELECT 1
                  FROM TABLE(get_value_coll_fetus_pl(i_lang,
                                                     i_prof,
                                                     popr.id_patient,
                                                     l_id_pat_pregnancy,
                                                     l_dt_ini,
                                                     l_dt_fim)) t
                 WHERE t.dt_result = popr.dt_result
                   AND t.id_episode = popr.id_episode);
    
        FOR i IN 1 .. l_po_param_reg.count
        LOOP
            g_error := 'CALL ts_po_param_reg.upd';
            ts_po_param_reg.upd(id_po_param_reg_in => l_po_param_reg(i),
                                flg_status_in      => pk_alert_constant.g_inactive,
                                flg_status_nin     => FALSE,
                                dt_cancel_in       => g_sysdate_tstz,
                                dt_cancel_nin      => FALSE,
                                id_prof_cancel_in  => i_prof.id,
                                id_prof_cancel_nin => FALSE,
                                rows_out           => l_rows);
        
            g_error := 'CALL t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'PO_PARAM_REG',
                                          i_rowids       => l_rows,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS', 'DT_CANCEL', 'ID_PROF_CANCEL'));
        END LOOP;
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
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_po_param_reg_inactive;
    /**
    * Get grid sets.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_task_type    id task types
    * @param o_sets         Sets of indicators
    * @param o_param        parameters
    * @param o_sets_param   Sets of indicators parameters
    * @param o_time         times
    * @param o_value        values
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Teresa Coutinho
    * @version               2.6.4.3
    * @since                2014/12/15
    */
    FUNCTION get_grid_sets
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_task_type  IN VARCHAR2,
        o_title      OUT VARCHAR2,
        o_sets       OUT pk_types.cursor_type,
        o_param      OUT pk_types.cursor_type,
        o_sets_param OUT pk_types.cursor_type,
        o_time       OUT pk_types.cursor_type,
        o_value      OUT pk_types.cursor_type,
        o_values_wh  OUT t_coll_wh_values,
        o_ref        OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_GRID_SETS';
        l_dcs            epis_info.id_dep_clin_serv%TYPE;
        l_sets_coll      t_coll_sets;
        l_params         t_coll_po_param;
        l_med_data       t_tbl_rec_sum_act_meds;
        l_values         t_coll_po_value;
        l_show_ref_value sys_config.value%TYPE;
        l_task_type      table_varchar2;
        l_ret            t_coll_sets;
        l_id_software    epis_info.id_software%TYPE;
    BEGIN
        o_title := '';
    
        l_task_type := pk_utils.str_split(i_task_type, '|');
    
        l_dcs := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_episode,
                                               o_id_software => l_id_software,
                                               o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_task_type.count > 0
        THEN
            FOR i IN 1 .. l_task_type.count
            LOOP
                g_error     := 'CALL get_sets_coll';
                l_sets_coll := get_sets_coll(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_patient   => i_patient,
                                             i_episode   => i_episode,
                                             i_task_type => l_task_type);
            END LOOP;
        END IF;
    
        SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.*
                  FROM TABLE(l_sets_coll) t);
    
        g_error := 'OPEN o_sets';
        OPEN o_sets FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             t.sets_id, t.sets_desc, t.sets_institutions
              FROM TABLE(l_ret) t
             WHERE EXISTS (SELECT NULL
                      FROM po_param_sets pps
                     WHERE pps.task_type_content = t.sets_id
                       AND pps.id_task_type IN (SELECT t.column_value
                                                  FROM TABLE(l_task_type) t)
                       AND pps.id_institution IN (i_prof.institution, 0)
                       AND pps.id_software IN (l_id_software, 0)
                       AND pps.flg_available = pk_alert_constant.g_yes
                       AND NOT EXISTS (SELECT 1
                              FROM pat_po_param patpop
                             WHERE patpop.id_patient = i_patient
                               AND patpop.flg_visible = pk_alert_constant.g_no
                               AND patpop.id_po_param = pps.id_po_param));
    
        g_error := 'SELECT l_params';
        SELECT DISTINCT t_rec_po_param(id_po_param, id_inst_owner)
          BULK COLLECT
          INTO l_params
          FROM (SELECT pps.id_po_param, pps.id_inst_owner
                  FROM po_param_sets pps
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        t.sets_id sets_id
                         FROM TABLE(l_ret) t) s
                    ON pps.task_type_content = s.sets_id
                  JOIN po_param pop
                    ON pps.id_po_param = pop.id_po_param
                   AND pps.id_inst_owner = pop.id_inst_owner
                 WHERE pps.id_institution IN (i_prof.institution, 0)
                   AND pps.id_software IN (l_id_software, 0)
                   AND pps.id_task_type IN (SELECT t.column_value
                                              FROM TABLE(l_task_type) t)
                   AND pps.flg_available = pk_alert_constant.g_yes
                   AND pop.flg_available = pk_alert_constant.g_yes
                   AND (pop.flg_type != pk_periodic_observation.g_analysis OR
                       (pop.flg_type = pk_periodic_observation.g_analysis AND EXISTS
                        (SELECT 1
                            FROM analysis_instit_soft ais
                           WHERE ais.id_institution = i_prof.institution
                             AND ais.id_software = i_prof.software
                             AND ais.id_analysis = pop.id_parameter
                             AND ais.id_sample_type = pop.id_sample_type
                             AND ais.flg_available = pk_alert_constant.g_yes)))
                MINUS
                SELECT patpop.id_po_param, patpop.id_inst_owner
                  FROM pat_po_param patpop
                 WHERE patpop.id_patient = i_patient
                   AND patpop.flg_visible = pk_alert_constant.g_no);
    
        l_values := get_value_coll(i_lang    => i_lang,
                                   i_prof    => i_prof,
                                   i_patient => i_patient,
                                   i_episode => i_episode,
                                   i_params  => l_params);
    
        g_error := 'OPEN o_sets_param';
        OPEN o_sets_param FOR
            SELECT pps.id_po_param parameter_id,
                   pps.task_type_content sets_id,
                   decode((SELECT COUNT(*)
                            FROM TABLE(CAST(l_values AS t_coll_po_value)) t
                           WHERE t.id_po_param = pop.id_po_param
                             AND t.id_inst_owner = pop.id_inst_owner
                             AND t.flg_status = pk_alert_constant.g_active),
                          0,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) parameter_flg_cancel
              FROM po_param_sets pps
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.sets_id, t.sets_desc
                      FROM TABLE(l_ret) t) t
                ON pps.task_type_content = t.sets_id
              JOIN po_param pop
                ON pps.id_po_param = pop.id_po_param
               AND pps.id_inst_owner = pop.id_inst_owner
               AND pop.flg_available = pk_alert_constant.g_yes
            /*LEFT JOIN (SELECT \*+opt_estimate(table t rows=1)*\
                       t.*
                        FROM TABLE(CAST(l_med_data AS t_tbl_rec_sum_act_meds)) t) med
             ON pop.flg_type IN (g_med_local, g_med_ext)
            AND pop.id_parameter = to_number(med.drug)
            AND pop.flg_available = pk_alert_constant.g_yes*/
             WHERE pps.id_institution IN (i_prof.institution, 0)
               AND pps.id_software IN (l_id_software, 0)
               AND pps.flg_available = pk_alert_constant.g_yes
               AND pps.id_task_type IN (SELECT t.column_value
                                          FROM TABLE(l_task_type) t)
               AND NOT EXISTS (SELECT 1
                      FROM pat_po_param patpop
                     WHERE patpop.id_patient = i_patient
                       AND patpop.flg_visible = pk_alert_constant.g_no
                       AND patpop.id_po_param = pps.id_po_param)
             ORDER BY t.sets_desc,
                      (SELECT get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank)
                         FROM dual),
                      (SELECT get_param_desc(i_lang,
                                             i_prof,
                                             pop.id_po_param,
                                             pop.id_inst_owner,
                                             pop.flg_type,
                                             pop.id_parameter,
                                             l_dcs)
                         FROM dual);
    
        get_param_cursor_sets(i_lang     => i_lang,
                              i_prof     => i_prof,
                              i_episode  => i_episode,
                              i_params   => l_params,
                              i_med_data => l_med_data,
                              o_param    => o_param);
    
        get_time_cursor(i_lang    => i_lang,
                        i_prof    => i_prof,
                        i_patient => i_patient,
                        i_values  => l_values,
                        o_time    => o_time);
    
        o_values_wh := get_value_cursor(i_lang => i_lang, i_prof => i_prof, i_values => l_values);
        g_error     := 'OPEN o_value';
        OPEN o_value FOR
            SELECT *
              FROM TABLE(CAST(o_values_wh AS t_coll_wh_values));
    
        l_show_ref_value := pk_sysconfig.get_config('FLOW_SHEETS_SETS_SHOW_REF_VALUE', i_prof);
        IF l_show_ref_value = pk_alert_constant.g_yes
        THEN
            g_error := 'open o_ref';
            OPEN o_ref FOR
                SELECT g_ref_value time_id
                  FROM dual;
        ELSE
            pk_types.open_my_cursor(o_ref);
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_grid_sets;

    FUNCTION get_sets_coll
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_task_type IN table_varchar2,
        i_value     IN VARCHAR2 DEFAULT NULL
    ) RETURN t_coll_sets IS
        l_ret         t_coll_sets := t_coll_sets();
        l_ret_i       t_coll_sets := t_coll_sets();
        l_ret_e       t_coll_sets := t_coll_sets();
        l_ret_hpg     t_coll_sets := t_coll_sets();
        l_hpg_coll    t_coll_sets := t_coll_sets();
        l_ret_med_ord t_coll_sets := t_coll_sets();
        o_error       t_error_out;
    BEGIN
        IF i_task_type.count > 0
        THEN
            FOR i IN 1 .. i_task_type.count
            LOOP
                IF i_task_type(i) = g_task_type_interv
                THEN
                    SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
                      BULK COLLECT
                      INTO l_ret_i
                      FROM (SELECT g_task_type_interv id_task_type,
                                   id_content sets_id,
                                   description sets_desc,
                                   '' sets_institutions
                              FROM TABLE(pk_procedures_external_api_db.get_procedure_flowsheets(i_lang,
                                                                                                i_prof,
                                                                                                pk_alert_constant.g_scope_type_episode,
                                                                                                i_episode)));
                
                ELSIF i_task_type(i) IN (g_task_type_exam, g_task_type_oth_exams)
                THEN
                
                    SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
                      BULK COLLECT
                      INTO l_ret_e
                      FROM (SELECT g_task_type_exam id_task_type,
                                   id_content sets_id,
                                   description sets_desc,
                                   '' sets_institutions
                              FROM TABLE(pk_exams_external_api_db.get_exam_flowsheets(i_lang,
                                                                                      i_prof,
                                                                                      pk_alert_constant.g_scope_type_episode,
                                                                                      i_episode)));
                
                ELSIF i_task_type(i) = g_task_type_hpg
                THEN
                    g_error    := 'CALL pk_health_program.get_pat_hpgs_cursor';
                    l_hpg_coll := pk_health_program.get_pat_hpgs_coll(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_patient    => i_patient,
                                                                      i_exc_status => table_varchar(pk_health_program.g_flg_status_cancelled,
                                                                                                    pk_health_program.g_flg_status_inactive));
                
                    SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
                      BULK COLLECT
                      INTO l_ret_hpg
                      FROM (SELECT id_task_type, sets_id, sets_desc, sets_institutions
                              FROM TABLE(CAST(l_hpg_coll AS t_coll_sets)));
                
                ELSIF i_task_type(i) IN (g_task_type_medical_order, g_task_type_comm_order)
                THEN
                    SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
                      BULK COLLECT
                      INTO l_ret_med_ord
                      FROM (SELECT i_task_type(i) id_task_type,
                                   i_value sets_id,
                                   to_char(pk_comm_orders.get_comm_order_desc(i_lang                     => i_lang,
                                                                              i_prof                     => i_prof,
                                                                              i_concept_type             => cor.id_concept_type,
                                                                              i_concept_term             => cor.id_concept_term,
                                                                              i_cncpt_trm_inst_owner     => cor.id_cncpt_trm_inst_owner,
                                                                              i_concept_version          => cor.id_concept_version,
                                                                              i_cncpt_vrs_inst_owner     => cor.id_cncpt_vrs_inst_owner,
                                                                              i_flg_free_text            => NULL,
                                                                              i_desc_concept_term        => NULL,
                                                                              i_notes                    => NULL,
                                                                              i_flg_priority             => NULL,
                                                                              i_flg_prn                  => NULL,
                                                                              i_prn_condition            => NULL,
                                                                              i_dt_begin                 => NULL,
                                                                              i_task_type                => cor.id_task_type_conc_term,
                                                                              i_flg_bold_title           => pk_alert_constant.g_yes,
                                                                              i_flg_show_comm_order_type => pk_alert_constant.g_yes,
                                                                              i_flg_trunc_clobs          => pk_alert_constant.g_yes,
                                                                              i_flg_report               => pk_alert_constant.g_no)) sets_desc,
                                   '' sets_institutions
                            
                              FROM comm_order_ea cor
                             WHERE cor.concept_code = i_value
                               AND cor.id_institution_term_vers = i_prof.institution
                               AND cor.id_software_term_vers = i_prof.software
                               AND cor.id_task_type_conc_term = i_task_type(i));
                END IF;
            END LOOP;
        END IF;
    
        l_ret := l_ret_e MULTISET UNION l_ret_i MULTISET UNION l_ret_hpg MULTISET UNION l_ret_med_ord;
    
        RETURN l_ret;
    END get_sets_coll;

    /**
    * Get Sets association.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_param        parameter identifier
    * @param i_owner        owner identifier
    * @param i_sets         patient sets data
    * @param i_task_type    task types    
    *
    * @return               Sets association
    *
    * @author               Teresa Coutinho
    * @version              2.6.4.3
    * @since                2014/12/22
    */
    FUNCTION get_param_sets
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_param     IN po_param.id_po_param%TYPE,
        i_owner     IN po_param.id_inst_owner%TYPE,
        i_sets      IN t_coll_sets,
        i_task_type IN table_varchar2
    ) RETURN pk_translation.t_desc_translation IS
        l_ret      pk_translation.t_desc_translation;
        l_sets_ids table_varchar;
    
        CURSOR c_sets IS
            SELECT DISTINCT pps.task_type_content
              FROM po_param_sets pps
             WHERE pps.id_po_param = i_param
               AND pps.id_inst_owner = i_owner
               AND pps.id_institution IN (i_prof.institution, 0)
               AND pps.id_software IN (i_prof.software, 0)
               AND pps.flg_available = pk_alert_constant.g_yes
               AND pps.id_task_type IN (SELECT *
                                          FROM TABLE(i_task_type));
    BEGIN
    
        IF i_param IS NULL
           OR i_owner IS NULL
           OR i_sets IS NULL
           OR i_sets.count < 1
        THEN
            l_ret := NULL;
        ELSE
            OPEN c_sets;
            FETCH c_sets BULK COLLECT
                INTO l_sets_ids;
            CLOSE c_sets;
        
            IF l_sets_ids.count > 0
            THEN
                l_ret := pk_message.get_message(i_lang      => i_lang,
                                                i_prof      => i_prof,
                                                i_code_mess => 'PERIODIC_OBSERVATION_T058') || ': ';
                FOR i IN i_sets.first .. i_sets.last
                LOOP
                    IF pk_utils.search_table_varchar(i_table => l_sets_ids, i_search => to_char(i_sets(i).sets_id)) > 0
                    THEN
                        IF i_sets(i).id_task_type = g_task_type_hpg
                        THEN
                            l_ret := l_ret || i_sets(i).sets_desc || ' (' || i_sets(i).sets_institutions || '); ';
                        ELSE
                            l_ret := i_sets(i).sets_desc;
                        END IF;
                    END IF;
                END LOOP;
            ELSE
                l_ret := NULL;
            END IF;
        END IF;
    
        RETURN l_ret;
    END get_param_sets;

    FUNCTION get_grid_comm_order
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        i_id_po_param_reg    IN po_param_reg.id_po_param_reg%TYPE DEFAULT NULL,
        i_id_comm_order_req  IN comm_order_req.id_comm_order_req%TYPE,
        o_title              OUT VARCHAR2,
        o_sets               OUT pk_types.cursor_type,
        o_param              OUT pk_types.cursor_type,
        o_sets_param         OUT pk_types.cursor_type,
        o_time               OUT pk_types.cursor_type,
        o_value              OUT pk_types.cursor_type,
        o_values_wh          OUT t_coll_wh_values,
        o_ref                OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_GRID_COMM_ORDER';
        l_dcs            epis_info.id_dep_clin_serv%TYPE;
        l_sets_coll      t_coll_sets;
        l_params         t_coll_po_param;
        l_med_data       t_tbl_rec_sum_act_meds;
        l_values         t_coll_po_value;
        l_show_ref_value sys_config.value%TYPE;
        l_task_type      task_type.id_task_type%TYPE;
        l_ret            t_coll_sets;
        l_id_software    epis_info.id_software%TYPE;
        --l_id_concept_term  comm_order_req.id_concept_term%TYPE;
        l_task_type_content po_param_sets.task_type_content%TYPE;
        l_tbl_po_param_reg  table_number := table_number();
    BEGIN
        o_title := '';
    
        g_error := 'Getting task type/concept term';
        IF i_id_comm_order_plan IS NOT NULL
        THEN
            SELECT cor.id_task_type, coe.concept_code
              INTO l_task_type, l_task_type_content
              FROM comm_order_plan cop
              JOIN comm_order_req cor
                ON cor.id_comm_order_req = cop.id_comm_order_req
              JOIN comm_order_ea coe
                ON cor.id_concept_version = coe.id_concept_version
               AND cor.id_cncpt_vrs_inst_owner = coe.id_cncpt_vrs_inst_owner
               AND cor.id_concept_term = coe.id_concept_term
               AND cor.id_cncpt_trm_inst_owner = coe.id_cncpt_trm_inst_owner
               AND cor.id_concept_type = coe.id_concept_type
               AND cor.id_task_type = coe.id_task_type_conc_term
               AND coe.id_software_conc_term = i_prof.software
               AND coe.id_institution_conc_term = i_prof.institution
             WHERE cop.id_comm_order_plan = i_id_comm_order_plan
               AND rownum = 1;
        ELSE
            SELECT cor.id_task_type, coe.concept_code
              INTO l_task_type, l_task_type_content
              FROM comm_order_req cor
              JOIN comm_order_ea coe
                ON cor.id_concept_version = coe.id_concept_version
               AND cor.id_cncpt_vrs_inst_owner = coe.id_cncpt_vrs_inst_owner
               AND cor.id_concept_term = coe.id_concept_term
               AND cor.id_cncpt_trm_inst_owner = coe.id_cncpt_trm_inst_owner
               AND cor.id_concept_type = coe.id_concept_type
               AND cor.id_task_type = coe.id_task_type_conc_term
               AND coe.id_software_conc_term = i_prof.software
               AND coe.id_institution_conc_term = i_prof.institution
             WHERE cor.id_comm_order_req = i_id_comm_order_req
               AND rownum = 1;
        END IF;
    
        l_dcs := pk_episode.get_dep_clin_serv(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_episode,
                                               o_id_software => l_id_software,
                                               o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Getting list of po_param_reg';
        SELECT id_po_param_reg
          BULK COLLECT
          INTO l_tbl_po_param_reg
          FROM (SELECT cop.id_po_param_reg
                  FROM comm_order_plan cop
                 WHERE cop.id_comm_order_plan = i_id_comm_order_plan
                   AND cop.flg_status = pk_comm_orders.g_comm_order_plan_ongoing
                   AND cop.id_po_param_reg IS NOT NULL
                UNION
                SELECT coph.id_po_param_reg
                  FROM comm_order_plan_hist coph
                 WHERE coph.id_comm_order_plan = i_id_comm_order_plan
                   AND coph.flg_status = pk_comm_orders.g_comm_order_plan_ongoing
                   AND coph.id_po_param_reg IS NOT NULL);
    
        IF i_id_po_param_reg IS NOT NULL
        THEN
            l_tbl_po_param_reg.extend();
            l_tbl_po_param_reg(l_tbl_po_param_reg.count) := i_id_po_param_reg;
        END IF;
    
        g_error     := 'CALL get_sets_coll';
        l_sets_coll := get_sets_coll(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_patient   => i_patient,
                                     i_episode   => i_episode,
                                     i_task_type => table_varchar2(l_task_type),
                                     i_value     => l_task_type_content);
    
        SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.*
                  FROM TABLE(l_sets_coll) t);
    
        g_error := 'OPEN o_sets';
        OPEN o_sets FOR
            SELECT /*+opt_estimate(table t rows=1)*/
             t.sets_id, t.sets_desc, t.sets_institutions
              FROM TABLE(l_ret) t
             WHERE EXISTS (SELECT NULL
                      FROM po_param_sets pps
                     WHERE pps.task_type_content = t.sets_id
                       AND pps.id_task_type = l_task_type
                       AND pps.id_institution IN (i_prof.institution, 0)
                       AND pps.id_software IN (l_id_software, 0)
                       AND pps.flg_available = pk_alert_constant.g_yes
                       AND NOT EXISTS (SELECT 1
                              FROM pat_po_param patpop
                             WHERE patpop.id_patient = i_patient
                               AND patpop.flg_visible = pk_alert_constant.g_no
                               AND patpop.id_po_param = pps.id_po_param));
    
        g_error := 'SELECT l_params';
        SELECT DISTINCT t_rec_po_param(id_po_param, id_inst_owner)
          BULK COLLECT
          INTO l_params
          FROM (SELECT pps.id_po_param, pps.id_inst_owner
                  FROM po_param_sets pps
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        t.sets_id sets_id
                         FROM TABLE(l_ret) t) s
                    ON pps.task_type_content = s.sets_id
                  JOIN po_param pop
                    ON pps.id_po_param = pop.id_po_param
                   AND pps.id_inst_owner = pop.id_inst_owner
                 WHERE pps.id_institution IN (i_prof.institution, 0)
                   AND pps.id_software IN (l_id_software, 0)
                   AND pps.id_task_type = l_task_type
                   AND pps.flg_available = pk_alert_constant.g_yes
                   AND pop.flg_available = pk_alert_constant.g_yes
                MINUS
                SELECT patpop.id_po_param, patpop.id_inst_owner
                  FROM pat_po_param patpop
                 WHERE patpop.id_patient = i_patient
                   AND patpop.flg_visible = pk_alert_constant.g_no);
    
        --Obtaining registered values
        g_error  := 'Obtaining registered values';
        l_values := get_value_coll_comm_order(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_patient          => i_patient,
                                              i_episode          => i_episode,
                                              i_params           => l_params,
                                              i_tbl_po_param_reg => l_tbl_po_param_reg);
    
        g_error := 'OPEN o_sets_param';
        OPEN o_sets_param FOR
            SELECT pps.id_po_param parameter_id,
                   pps.task_type_content sets_id,
                   decode((SELECT COUNT(*)
                            FROM TABLE(CAST(l_values AS t_coll_po_value)) t
                           WHERE t.id_po_param = pop.id_po_param
                             AND t.id_inst_owner = pop.id_inst_owner
                             AND t.flg_status = pk_alert_constant.g_active),
                          0,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) parameter_flg_cancel
              FROM po_param_sets pps
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.sets_id, t.sets_desc
                      FROM TABLE(l_ret) t) t
                ON pps.task_type_content = t.sets_id
              JOIN po_param pop
                ON pps.id_po_param = pop.id_po_param
               AND pps.id_inst_owner = pop.id_inst_owner
               AND pop.flg_available = pk_alert_constant.g_yes
            /*LEFT JOIN (SELECT \*+opt_estimate(table t rows=1)*\
                       t.*
                        FROM TABLE(CAST(l_med_data AS t_tbl_rec_sum_act_meds)) t) med
             ON pop.flg_type IN (g_med_local, g_med_ext)
            AND pop.id_parameter = to_number(med.drug)
            AND pop.flg_available = pk_alert_constant.g_yes*/
             WHERE pps.id_institution IN (i_prof.institution, 0)
               AND pps.id_software IN (l_id_software, 0)
               AND pps.flg_available = pk_alert_constant.g_yes
               AND pps.id_task_type = l_task_type
               AND NOT EXISTS (SELECT 1
                      FROM pat_po_param patpop
                     WHERE patpop.id_patient = i_patient
                       AND patpop.flg_visible = pk_alert_constant.g_no
                       AND patpop.id_po_param = pps.id_po_param)
             ORDER BY t.sets_desc,
                      (SELECT get_param_rank(i_prof, pop.id_po_param, pop.id_inst_owner, pop.rank)
                         FROM dual),
                      (SELECT get_param_desc(i_lang,
                                             i_prof,
                                             pop.id_po_param,
                                             pop.id_inst_owner,
                                             pop.flg_type,
                                             pop.id_parameter,
                                             l_dcs)
                         FROM dual);
    
        get_param_cursor_sets(i_lang     => i_lang,
                              i_prof     => i_prof,
                              i_episode  => i_episode,
                              i_params   => l_params,
                              i_med_data => l_med_data,
                              o_param    => o_param);
    
        get_time_cursor(i_lang             => i_lang,
                        i_prof             => i_prof,
                        i_patient          => i_patient,
                        i_values           => l_values,
                        i_tbl_po_param_reg => l_tbl_po_param_reg,
                        o_time             => o_time);
    
        o_values_wh := get_value_cursor(i_lang => i_lang, i_prof => i_prof, i_values => l_values);
        g_error     := 'OPEN o_value';
        OPEN o_value FOR
            SELECT *
              FROM TABLE(CAST(o_values_wh AS t_coll_wh_values));
    
        l_show_ref_value := pk_sysconfig.get_config('FLOW_SHEETS_SETS_SHOW_REF_VALUE', i_prof);
        IF l_show_ref_value = pk_alert_constant.g_yes
        THEN
            g_error := 'open o_ref';
            OPEN o_ref FOR
                SELECT g_ref_value time_id
                  FROM dual;
        ELSE
            pk_types.open_my_cursor(o_ref);
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_grid_comm_order;

    /**
    * set_parameter_comm_order - Configures a set of parameters on the patient's flowsheet
    *
    * @param i_prof               logged professional structure
    * @param i_patient            patient identifier
    * @param i_episode            episode identifier
    * @param i_id_comm_order_plan communication order plan identifier
    * @param i_id_po_param_reg    parameter reg identifier
    *
    * @return                     true/false
    *
    * @version                    2.8.0.0
    * @since                      2019/09/02
    */
    FUNCTION set_parameter_comm_order
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_id_comm_order_plan IN comm_order_plan.id_comm_order_plan%TYPE,
        i_id_po_param_reg    IN po_param_reg.id_po_param_reg%TYPE DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_PARAMETER_COMM_ORDER';
        l_sets_coll         t_coll_sets;
        l_params            t_coll_po_param;
        l_values            t_coll_po_value;
        l_task_type         task_type.id_task_type%TYPE;
        l_ret               t_coll_sets;
        l_id_software       epis_info.id_software%TYPE;
        l_task_type_content po_param_sets.task_type_content%TYPE;
        l_tbl_po_param_reg  table_number := table_number();
        l_id_patient        patient.id_patient%TYPE;
    
        l_tbl_po_param    table_number;
        l_tbl_flg_type    table_varchar;
        l_tbl_sample_type table_number;
    BEGIN
    
        g_error := 'Getting task type/concept term';
        SELECT cor.id_task_type, coe.concept_code, cor.id_patient
          INTO l_task_type, l_task_type_content, l_id_patient
          FROM comm_order_plan cop
          JOIN comm_order_req cor
            ON cor.id_comm_order_req = cop.id_comm_order_req
          JOIN comm_order_ea coe
            ON cor.id_concept_version = coe.id_concept_version
           AND cor.id_cncpt_vrs_inst_owner = coe.id_cncpt_vrs_inst_owner
           AND cor.id_concept_term = coe.id_concept_term
           AND cor.id_cncpt_trm_inst_owner = coe.id_cncpt_trm_inst_owner
           AND cor.id_concept_type = coe.id_concept_type
           AND cor.id_task_type = coe.id_task_type_conc_term
           AND coe.id_software_conc_term = i_prof.software
           AND coe.id_institution_conc_term = i_prof.institution
         WHERE cop.id_comm_order_plan = i_id_comm_order_plan
           AND rownum = 1;
    
        IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_episode  => i_episode,
                                               o_id_software => l_id_software,
                                               o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        SELECT id_po_param_reg
          BULK COLLECT
          INTO l_tbl_po_param_reg
          FROM (SELECT cop.id_po_param_reg
                  FROM comm_order_plan cop
                 WHERE cop.id_comm_order_plan = i_id_comm_order_plan
                   AND cop.flg_status = pk_comm_orders.g_comm_order_plan_ongoing
                   AND cop.id_po_param_reg IS NOT NULL
                UNION
                SELECT coph.id_po_param_reg
                  FROM comm_order_plan_hist coph
                 WHERE coph.id_comm_order_plan = i_id_comm_order_plan
                   AND coph.flg_status = pk_comm_orders.g_comm_order_plan_ongoing
                   AND coph.id_po_param_reg IS NOT NULL);
    
        IF i_id_po_param_reg IS NOT NULL
        THEN
            l_tbl_po_param_reg.extend();
            l_tbl_po_param_reg(l_tbl_po_param_reg.count) := i_id_po_param_reg;
        END IF;
    
        g_error     := 'CALL get_sets_coll';
        l_sets_coll := get_sets_coll(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_patient   => l_id_patient,
                                     i_episode   => i_episode,
                                     i_task_type => table_varchar2(l_task_type),
                                     i_value     => l_task_type_content);
    
        SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.*
                  FROM TABLE(l_sets_coll) t);
    
        g_error := 'SELECT l_params';
        SELECT DISTINCT t_rec_po_param(id_po_param, id_inst_owner)
          BULK COLLECT
          INTO l_params
          FROM (SELECT pps.id_po_param, pps.id_inst_owner
                  FROM po_param_sets pps
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        t.sets_id sets_id
                         FROM TABLE(l_ret) t) s
                    ON pps.task_type_content = s.sets_id
                  JOIN po_param pop
                    ON pps.id_po_param = pop.id_po_param
                   AND pps.id_inst_owner = pop.id_inst_owner
                 WHERE pps.id_institution IN (i_prof.institution, 0)
                   AND pps.id_software IN (l_id_software, 0)
                   AND pps.id_task_type = l_task_type
                   AND pps.flg_available = pk_alert_constant.g_yes
                   AND pop.flg_available = pk_alert_constant.g_yes
                MINUS
                SELECT patpop.id_po_param, patpop.id_inst_owner
                  FROM pat_po_param patpop
                 WHERE patpop.id_patient = l_id_patient
                   AND patpop.flg_visible = pk_alert_constant.g_no);
    
        l_values := get_value_coll_comm_order(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_patient          => l_id_patient,
                                              i_episode          => i_episode,
                                              i_params           => l_params,
                                              i_tbl_po_param_reg => l_tbl_po_param_reg);
    
        IF l_values.count > 0
        THEN
        
            SELECT DISTINCT pop.id_parameter, pop.flg_type, pop.id_sample_type
              BULK COLLECT
              INTO l_tbl_po_param, l_tbl_flg_type, l_tbl_sample_type
              FROM po_param pop
              JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                     t.id_po_param, t.id_inst_owner
                      FROM TABLE(CAST(l_params AS t_coll_po_param)) t) t
                ON pop.id_po_param = t.id_po_param
               AND pop.id_inst_owner = t.id_inst_owner
              JOIN TABLE(get_value_cursor(i_lang => i_lang, i_prof => i_prof, i_values => l_values)) vc
                ON vc.parameter_id = pop.id_po_param;
        
            IF l_tbl_po_param.count > 0
            THEN
                IF NOT set_parameter(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_patient       => l_id_patient,
                                     i_parameters    => l_tbl_po_param,
                                     i_types         => l_tbl_flg_type,
                                     i_pat_pregnancy => NULL,
                                     i_owner         => NULL,
                                     i_sample_type   => l_tbl_sample_type,
                                     o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_parameter_comm_order;

    FUNCTION cancel_values_coll
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_po_param_reg   IN po_param_reg.id_po_param_reg%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CANCEL_VALUES_COLL';
    
        l_time_filter_e  po_param_reg.dt_result%TYPE;
        l_time_filter_a  po_param_reg.dt_result%TYPE;
        l_insts          table_number;
        l_prev_epis_date episode.dt_end_tstz%TYPE;
        l_dates_aggr     table_timestamp_tz;
        l_dt_max         po_param_reg.dt_result%TYPE := NULL; -- date of the "up to now" column
        l_dt_max_epis    po_param_reg.dt_result%TYPE := NULL; -- max episode date
    
        l_tbl_po_param        table_number;
        l_tbl_param_type      table_varchar;
        l_tbl_param_id_result table_number;
        l_params              t_coll_po_param;
    
        l_task_type         task_type.id_task_type%TYPE;
        l_task_type_content po_param_sets.task_type_content%TYPE;
        l_ret               t_coll_sets := t_coll_sets();
        l_sets_coll         t_coll_sets;
    
        l_patient     patient.id_patient%TYPE;
        l_episode     episode.id_episode%TYPE;
        l_value_scope sys_config.value%TYPE;
    
        l_rowids table_varchar;
    
        PROCEDURE delete_po_param_reg_mc(i_id_po_param_reg IN po_param_reg.id_po_param_reg%TYPE) IS
            l_tbl_po_param_mc table_number;
        BEGIN
            SELECT pprm.id_po_param_mc
              BULK COLLECT
              INTO l_tbl_po_param_mc
              FROM po_param_reg_mc pprm
             WHERE pprm.id_po_param_reg = i_id_po_param_reg;
        
            IF l_tbl_po_param_mc IS NOT NULL
               AND l_tbl_po_param_mc.exists(1)
            THEN
                FOR i IN l_tbl_po_param_mc.first .. l_tbl_po_param_mc.last
                LOOP
                    ts_po_param_reg_mc.del(id_po_param_reg_in => i_id_po_param_reg,
                                           id_po_param_mc_in  => l_tbl_po_param_mc(i));
                END LOOP;
            END IF;
        
            ts_po_param_reg.del(id_po_param_reg_in => i_id_po_param_reg);
        
        END delete_po_param_reg_mc;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        SELECT cor.id_task_type, coe.concept_code, cor.id_patient, cor.id_episode
          INTO l_task_type, l_task_type_content, l_patient, l_episode
          FROM comm_order_req cor
          JOIN comm_order_ea coe
            ON cor.id_concept_version = coe.id_concept_version
           AND cor.id_cncpt_vrs_inst_owner = coe.id_cncpt_vrs_inst_owner
           AND cor.id_concept_term = coe.id_concept_term
           AND cor.id_cncpt_trm_inst_owner = coe.id_cncpt_trm_inst_owner
           AND cor.id_concept_type = coe.id_concept_type
           AND cor.id_task_type = coe.id_task_type_conc_term
           AND coe.id_software_conc_term = i_prof.software
           AND coe.id_institution_conc_term = i_prof.institution
         WHERE cor.id_comm_order_req = i_comm_order_req;
    
        l_value_scope := pk_sysconfig.get_config(i_code_cf => g_cfg_value_scope, i_prof => i_prof);
    
        l_time_filter_e  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_e,
                                                                                                  i_prof    => i_prof) * -1);
        l_time_filter_a  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_a,
                                                                                                  i_prof    => i_prof) * -1);
        l_prev_epis_date := get_prev_epis_date(i_prof => i_prof, i_patient => l_patient, i_episode => l_episode);
    
        -- set scope filter variables
        IF l_value_scope = g_scope_inst
        THEN
            l_insts := table_number(i_prof.institution);
        ELSIF l_value_scope = g_scope_group
        THEN
            l_insts := pk_list.tf_get_all_inst_group(i_institution  => i_prof.institution,
                                                     i_flg_relation => pk_adt.g_inst_grp_flg_rel_adt);
        END IF;
    
        -- set minimum filter dates
        IF l_prev_epis_date > l_time_filter_e
        THEN
            l_time_filter_e := l_prev_epis_date;
        END IF;
        IF l_prev_epis_date > l_time_filter_a
        THEN
            l_time_filter_a := l_prev_epis_date;
        END IF;
    
        g_error     := 'CALL get_sets_coll';
        l_sets_coll := get_sets_coll(i_lang      => i_lang,
                                     i_prof      => i_prof,
                                     i_patient   => l_patient,
                                     i_episode   => l_episode,
                                     i_task_type => table_varchar2(l_task_type),
                                     i_value     => l_task_type_content);
    
        SELECT t_rec_sets(id_task_type, sets_id, sets_desc, sets_institutions)
          BULK COLLECT
          INTO l_ret
          FROM (SELECT t.*
                  FROM TABLE(l_sets_coll) t);
    
        SELECT DISTINCT t_rec_po_param(id_po_param, id_inst_owner)
          BULK COLLECT
          INTO l_params
          FROM (SELECT pps.id_po_param, pps.id_inst_owner
                  FROM po_param_sets pps
                  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                        t.sets_id sets_id
                         FROM TABLE(l_ret) t) s
                    ON pps.task_type_content = s.sets_id
                  JOIN po_param pop
                    ON pps.id_po_param = pop.id_po_param
                   AND pps.id_inst_owner = pop.id_inst_owner
                 WHERE pps.id_institution IN (i_prof.institution, 0)
                   AND pps.id_software IN (i_prof.software, 0)
                   AND pps.id_task_type = l_task_type
                   AND pps.flg_available = pk_alert_constant.g_yes
                   AND pop.flg_available = pk_alert_constant.g_yes
                MINUS
                SELECT patpop.id_po_param, patpop.id_inst_owner
                  FROM pat_po_param patpop
                 WHERE patpop.id_patient = l_patient
                   AND patpop.flg_visible = pk_alert_constant.g_no);
    
        -- get values
        g_error := 'SELECT l_ret';
        SELECT pop.id_po_param, pop.flg_type, v.id_result
          BULK COLLECT
          INTO l_tbl_po_param, l_tbl_param_type, l_tbl_param_id_result
          FROM (SELECT /*+opt_estimate (table vs rows=1)*/
                 *
                  FROM TABLE(get_value_coll_pl(i_lang, i_prof, l_patient))) v
          JOIN po_param pop
            ON v.flg_type = pop.flg_type
           AND v.id_parameter = nvl(pop.id_parameter, pop.id_po_param)
           AND ((v.id_sample_type = pop.id_sample_type AND pop.flg_fill_type = 'A') OR pop.flg_fill_type <> 'A')
          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                 t.id_po_param, t.id_inst_owner
                  FROM TABLE(CAST(l_params AS t_coll_po_param)) t) t
            ON pop.id_po_param = t.id_po_param
           AND pop.id_inst_owner = t.id_inst_owner
          JOIN (SELECT ppr.id_episode, ppr.dt_result
                  FROM po_param_reg ppr
                 WHERE ppr.id_po_param_reg IN (i_po_param_reg)) reg
            ON reg.id_episode = v.id_episode
           AND reg.dt_result = v.dt_result
          JOIN epis_info ei
            ON v.id_episode = ei.id_episode
         WHERE (v.id_episode = l_episode OR
               v.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      t.column_value id_institution
                                       FROM TABLE(CAST(l_insts AS table_number)) t))
           AND ((pop.flg_type NOT IN (g_exam, g_analysis)) OR --
               (pop.flg_type = g_exam AND v.dt_result > l_time_filter_e) OR --
               (pop.flg_type = g_analysis AND v.dt_result > l_time_filter_a));
    
        IF l_tbl_param_type.exists(1)
        THEN
            FOR i IN l_tbl_param_type.first .. l_tbl_param_type.last
            LOOP
                IF l_tbl_param_type(i) = 'VS'
                   AND l_tbl_param_id_result(i) IS NOT NULL
                THEN
                    IF NOT pk_vital_sign.cancel_biometric_read(i_lang  => i_lang,
                                                               i_vs    => l_tbl_param_id_result(i),
                                                               i_prof  => i_prof,
                                                               o_error => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSIF l_tbl_param_type(i) = 'O'
                THEN
                    delete_po_param_reg_mc(i_id_po_param_reg => l_tbl_param_id_result(i));
                END IF;
            END LOOP;
        END IF;
    
        IF NOT
            cancel_column(i_lang => i_lang, i_prof => i_prof, i_id_po_param_reg => i_po_param_reg, o_error => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'cancel_values_coll',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END cancel_values_coll;

    FUNCTION get_value_coll_comm_order
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_params         IN t_coll_po_param,
        i_comm_order_req IN comm_order_req.id_comm_order_req%TYPE,
        i_dt_ini         IN pat_pregnancy.dt_init_pregnancy%TYPE,
        i_dt_fim         IN pat_pregnancy.dt_init_pregnancy%TYPE,
        o_time           OUT pk_types.cursor_type
    ) RETURN t_coll_po_value IS
        l_ret            t_coll_po_value;
        l_value_scope    sys_config.value%TYPE;
        l_decimal_symbol sys_config.value%TYPE;
        l_time_filter_e  po_param_reg.dt_result%TYPE;
        l_time_filter_a  po_param_reg.dt_result%TYPE;
        l_episode        episode.id_episode%TYPE;
        l_insts          table_number;
        l_prev_epis_date episode.dt_end_tstz%TYPE;
    BEGIN
        g_sysdate_tstz   := current_timestamp;
        l_value_scope    := pk_sysconfig.get_config(i_code_cf => g_cfg_value_scope, i_prof => i_prof);
        l_decimal_symbol := pk_sysconfig.get_config(i_code_cf => pk_touch_option.g_scfg_decimal_separator,
                                                    i_prof    => i_prof);
        l_time_filter_e  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_e,
                                                                                                  i_prof    => i_prof) * -1);
        l_time_filter_a  := pk_date_utils.add_days_to_tstz(i_timestamp => g_sysdate_tstz,
                                                           i_days      => pk_sysconfig.get_config(i_code_cf => g_cfg_time_filter_a,
                                                                                                  i_prof    => i_prof) * -1);
        l_prev_epis_date := get_prev_epis_date(i_prof => i_prof, i_patient => i_patient, i_episode => i_episode);
    
        -- set minimum filter dates
        IF l_prev_epis_date > l_time_filter_e
        THEN
            l_time_filter_e := l_prev_epis_date;
        END IF;
        IF l_prev_epis_date > l_time_filter_a
        THEN
            l_time_filter_a := l_prev_epis_date;
        END IF;
    
        -- set scope filter variables
        IF l_value_scope = g_scope_episode
        THEN
            l_episode := i_episode;
        ELSIF l_value_scope = g_scope_inst
        THEN
            l_insts := table_number(i_prof.institution);
        ELSIF l_value_scope = g_scope_group
        THEN
            l_insts := pk_list.tf_get_all_inst_group(i_institution  => i_prof.institution,
                                                     i_flg_relation => pk_adt.g_inst_grp_flg_rel_adt);
        END IF;
    
        --ALERT-154864    
        -- get values
        g_error := 'SELECT l_ret';
        SELECT t_rec_po_value(pop.id_po_param,
                              pop.id_inst_owner,
                              v.id_result,
                              v.id_episode,
                              v.id_institution,
                              ei.id_software,
                              v.id_prof_reg,
                              v.dt_result,
                              NULL,
                              v.dt_reg,
                              v.flg_status,
                              --ALERT-154864                              
                              v.desc_result,
                              (SELECT nvl(v.desc_unit_measure,
                                          pk_unit_measure.get_unit_measure_description(i_lang, i_prof, v.id_unit_measure))
                                 FROM dual),
                              v.icon,
                              v.lab_param_count,
                              v.lab_param_id,
                              v.lab_param_rank,
                              v.val_min,
                              v.val_max,
                              v.abnorm_value,
                              v.option_codes,
                              v.flg_cancel,
                              v.dt_cancel,
                              v.id_prof_cancel,
                              v.id_cancel_reason,
                              v.notes_cancel,
                              v.woman_health_id,
                              v.flg_ref_value,
                              v.dt_harvest,
                              v.dt_execution,
                              v.notes,
                              v.id_sample_type)
          BULK COLLECT
          INTO l_ret
          FROM (
                --analysis
                SELECT ar.id_analysis id_parameter,
                        g_analysis flg_type,
                        ar.id_analysis_result id_result,
                        ar.id_episode_orig id_episode,
                        ar.id_institution,
                        ar.id_professional id_prof_reg,
                        nvl(arp.dt_analysis_result_par_upd, arp.dt_analysis_result_par_tstz) dt_result,
                        coalesce(arp.dt_ins_result_tstz,
                                 lte.dt_harvest,
                                 arp.dt_analysis_result_par_upd,
                                 ar.dt_sample,
                                 ar.dt_analysis_result_tstz) dt_reg,
                        nvl(ar.flg_status, pk_alert_constant.g_active) flg_status,
                        to_clob((SELECT nvl(TRIM(arp.desc_analysis_result),
                                           pk_utils.to_str(arp.analysis_result_value, l_decimal_symbol))
                                  FROM dual)) desc_result,
                        arp.desc_unit_measure,
                        arp.id_unit_measure,
                        NULL icon,
                        pk_lab_tests_external_api_db.get_lab_test_param_count(i_prof, ar.id_analysis, ar.id_sample_type) lab_param_count,
                        arp.id_analysis_parameter lab_param_id,
                        row_number() over(PARTITION BY ar.id_analysis_result ORDER BY apr.rank) lab_param_rank,
                        nvl(TRIM(arp.ref_val_min_str), arp.ref_val_min) val_min,
                        nvl(TRIM(arp.ref_val_max_str), arp.ref_val_max) val_max,
                        CASE
                         --ALERT-154864                            
                             WHEN pk_utils.is_number(arp.desc_analysis_result) = 'Y' THEN
                              CASE
                                  WHEN nvl(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                     '999999999999999999999999D999',
                                                     'NLS_NUMERIC_CHARACTERS='', '''),
                                           arp.analysis_result_value) < arp.ref_val_min THEN
                                   'D'
                                  WHEN nvl(to_number(TRIM(REPLACE(arp.desc_analysis_result, '.', ',')),
                                                     '999999999999999999999999D999',
                                                     'NLS_NUMERIC_CHARACTERS='', '''),
                                           arp.analysis_result_value) > arp.ref_val_max THEN
                                   'U'
                                  ELSE
                                   NULL
                              END
                             ELSE
                              NULL
                         END abnorm_value,
                        table_varchar() option_codes,
                        decode(ar.flg_status,
                               pk_alert_constant.g_cancelled,
                               pk_alert_constant.g_no,
                               pk_alert_constant.g_yes) flg_cancel,
                        arp.dt_cancel,
                        arp.id_professional_cancel id_prof_cancel,
                        arp.id_cancel_reason,
                        to_clob(arp.notes_cancel) notes_cancel,
                        to_char(i_comm_order_req) woman_health_id,
                        pk_alert_constant.g_no flg_ref_value,
                        ar.dt_sample dt_harvest,
                        NULL dt_execution,
                        arp.parameter_notes notes,
                        ar.id_sample_type
                  FROM analysis_result ar
                  JOIN analysis_result_par arp
                    ON ar.id_analysis_result = arp.id_analysis_result
                  JOIN analysis_parameter apr
                    ON arp.id_analysis_parameter = apr.id_analysis_parameter
                  LEFT JOIN lab_tests_ea lte
                    ON ar.id_analysis_req_det = lte.id_analysis_req_det
                  LEFT JOIN abnormality a
                    ON arp.id_abnormality = a.id_abnormality
                 WHERE ar.id_patient = i_patient
                   AND coalesce(ar.dt_sample, ar.dt_analysis_result_tstz, lte.dt_harvest) BETWEEN i_dt_ini AND i_dt_fim
                UNION ALL
                --vital signs simples gravida
                SELECT vsr.id_vital_sign id_parameter,
                        g_vital_sign flg_type,
                        vsr.id_vital_sign_read id_result,
                        vsr.id_episode,
                        vsr.id_institution_read id_institution,
                        vsr.id_prof_read id_prof_reg,
                        vsr.dt_vital_sign_read_tstz dt_result,
                        vsr.dt_registry dt_reg,
                        vsr.flg_state flg_status,
                        to_clob(pk_vital_sign.get_vs_value(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_patient            => vsr.id_patient,
                                                           i_episode            => vsr.id_episode,
                                                           i_vital_sign         => vsr.id_vital_sign,
                                                           i_value              => vsr.value,
                                                           i_vs_unit_measure    => vsr.id_unit_measure,
                                                           i_vital_sign_desc    => vsr.id_vital_sign_desc,
                                                           i_vs_scales_element  => vsr.id_vs_scales_element,
                                                           i_dt_vital_sign_read => vsr.dt_vital_sign_read_tstz,
                                                           i_ea_unit_measure    => vsr.id_unit_measure,
                                                           i_short_desc         => pk_alert_constant.g_no,
                                                           i_decimal_symbol     => l_decimal_symbol,
                                                           i_dt_registry        => vsr.dt_registry)) desc_result,
                        (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                          vsr.id_unit_measure,
                                                                          vsr.id_vs_scales_element)
                           FROM dual) desc_unit_measure,
                        vsr.id_unit_measure,
                        vsd.icon,
                        NULL lab_param_count,
                        NULL lab_param_id,
                        NULL lab_param_rank,
                        NULL val_min,
                        NULL val_max,
                        NULL abnorm_value,
                        table_varchar() option_codes,
                        decode(vsr.flg_state,
                               pk_alert_constant.g_cancelled,
                               pk_alert_constant.g_no,
                               pk_alert_constant.g_yes) flg_cancel,
                        vsr.dt_cancel_tstz dt_cancel,
                        vsr.id_prof_cancel,
                        NULL id_cancel_reason,
                        to_clob(vsr.notes_cancel) notes_cancel,
                        to_char(i_comm_order_req) woman_health_id,
                        pk_alert_constant.g_no flg_ref_value,
                        NULL dt_harvest,
                        NULL dt_execution,
                        NULL notes,
                        NULL id_sample_type
                  FROM vital_sign_read vsr
                  LEFT JOIN vital_sign_desc vsd
                    ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
                 WHERE vsr.id_patient = i_patient
                      --AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                   AND vsr.dt_vital_sign_read_tstz BETWEEN i_dt_ini AND i_dt_fim
                UNION ALL
                /* SELECT t.id_parameter,
                        t.flg_type,
                        t.id_result,
                        t.id_episode,
                        t.id_institution,
                        t.id_prof_reg,
                        t.dt_result,
                        t.dt_reg,
                        t.flg_status,
                        t.desc_result,
                        t.desc_unit_measure,
                        t.id_unit_measure,
                        t.icon,
                        t.lab_param_count,
                        t.lab_param_id,
                        t.lab_param_rank,
                        t.val_min,
                        t.val_max,
                        t.abnorm_value,
                        t.option_codes,
                        t.flg_cancel,
                        t.dt_cancel,
                        t.id_prof_cancel,
                        t.id_cancel_reason,
                        t.notes_cancel,
                        t.woman_health_id,
                        t.flg_ref_value,
                        t.dt_harvest,
                        t.dt_execution,
                        t.notes,
                        t.id_sample_type
                  FROM TABLE(get_value_coll_fetus_pl(i_lang, i_prof, i_patient, i_pat_pregnancy, i_dt_ini, i_dt_fim)) t
                -- vital signs compostos gravida
                UNION ALL*/
                SELECT vs_comp.id_vital_sign_parent id_parameter,
                        g_vital_sign flg_type,
                        vs_comp.id_vital_sign_read id_result,
                        vs_comp.id_episode,
                        vs_comp.id_institution_read id_institution,
                        vs_comp.id_prof_read id_prof_reg,
                        vs_comp.dt_vital_sign_read_tstz dt_result,
                        vs_comp.dt_registry dt_reg,
                        vs_comp.flg_state flg_status,
                        to_clob(decode(relation_domain,
                                       g_vs_rel_conc,
                                       pk_vital_sign.get_bloodpressure_value(i_vital_sign         => vs_comp.id_vital_sign_parent,
                                                                             i_patient            => i_patient,
                                                                             i_episode            => vs_comp.id_episode,
                                                                             i_dt_vital_sign_read => vs_comp.dt_vital_sign_read_tstz,
                                                                             i_decimal_symbol     => l_decimal_symbol,
                                                                             i_dt_registry        => vs_comp.dt_registry),
                                       pk_vital_sign.get_glasgowtotal_value_hist(vs_comp.id_vital_sign_parent,
                                                                                 i_patient,
                                                                                 vs_comp.id_episode,
                                                                                 vs_comp.dt_vital_sign_read_tstz,
                                                                                 vs_comp.dt_registry))) desc_result,
                        (SELECT pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                                          vs_comp.id_unit_measure,
                                                                          vs_comp.id_vs_scales_element)
                           FROM dual) desc_unit_measure,
                        vs_comp.id_unit_measure,
                        NULL icon,
                        NULL lab_param_count,
                        NULL lab_param_id,
                        NULL lab_param_rank,
                        NULL val_min,
                        NULL val_max,
                        NULL abnorm_value,
                        table_varchar() option_codes,
                        decode(vs_comp.flg_state,
                               pk_alert_constant.g_cancelled,
                               pk_alert_constant.g_no,
                               pk_alert_constant.g_yes) flg_cancel,
                        vs_comp.dt_cancel_tstz dt_cancel,
                        vs_comp.id_prof_cancel,
                        NULL id_cancel_reason,
                        to_clob(vs_comp.notes_cancel) notes_cancel,
                        to_char(i_comm_order_req) woman_health_id,
                        pk_alert_constant.g_no flg_ref_value,
                        NULL dt_harvest,
                        NULL dt_execution,
                        NULL notes,
                        NULL id_sample_type
                  FROM (SELECT vsre.id_vital_sign_parent,
                                vsr.id_vital_sign_read,
                                vsr.id_episode,
                                vsr.id_institution_read,
                                vsr.id_prof_read,
                                vsr.dt_vital_sign_read_tstz,
                                vsr.dt_registry,
                                vsr.flg_state,
                                vsr.id_unit_measure,
                                vsr.id_vs_scales_element,
                                vsr.dt_cancel_tstz,
                                vsr.id_prof_cancel,
                                vsr.notes_cancel,
                                vsre.relation_domain,
                                row_number() over(PARTITION BY vsr.dt_registry ORDER BY vsr.id_vital_sign_read DESC) rn
                           FROM vital_sign_read vsr
                           JOIN vital_sign_relation vsre
                             ON vsr.id_vital_sign = vsre.id_vital_sign_detail
                          WHERE vsr.id_patient = i_patient
                            AND vsre.relation_domain IN (g_vs_rel_conc, g_vs_rel_sum)) vs_comp
                 WHERE vs_comp.rn = 1
                --sinais vitais ref value
                UNION ALL
                --exames
                SELECT ea.id_exam id_parameter,
                        g_exam flg_type,
                        ea.id_exam_result id_result,
                        er.id_episode_write id_episode,
                        er.id_institution,
                        er.id_professional id_prof_reg,
                        nvl(ea.start_time, ea.dt_result) dt_result,
                        er.dt_exam_result_tstz dt_reg,
                        er.flg_status,
                        --ALERT-154864                       
                        to_clob((nvl(ea.desc_result,
                                     pk_sysdomain.get_domain(g_exam_req_status_domain, ea.flg_status_req, i_lang)))) desc_result,
                        NULL desc_unit_measure,
                        NULL id_unit_measure,
                        --pk_sysdomain.get_img(i_lang, g_exam_req_status_domain, ea.flg_status_req) icon,
                        NULL icon,
                        NULL lab_param_count,
                        NULL lab_param_id,
                        NULL lab_param_rank,
                        NULL val_min,
                        NULL val_max,
                        NULL abnorm_value,
                        table_varchar() option_codes,
                        pk_alert_constant.g_no flg_cancel,
                        er.dt_exam_result_cancel_tstz dt_cancel,
                        er.id_prof_cancel,
                        NULL id_cancel_reason,
                        NULL notes_cancel,
                        to_char(i_comm_order_req) woman_health_id,
                        pk_alert_constant.g_no flg_ref_value,
                        NULL dt_harvest,
                        nvl(ea.start_time, ea.dt_result) dt_execution,
                        NULL notes,
                        NULL id_sample_type
                  FROM exams_ea ea
                  JOIN exam_result er
                    ON ea.id_exam_result = er.id_exam_result
                 WHERE er.id_patient = i_patient
                UNION ALL
                --others params
                SELECT nvl(pop.id_parameter, pop.id_po_param) id_parameter,
                        pop.flg_type,
                        popr.id_po_param_reg id_result,
                        popr.id_episode,
                        e.id_institution,
                        popr.id_professional id_prof_reg,
                        popr.dt_result,
                        popr.dt_creation dt_reg,
                        popr.flg_status,
                        CASE
                            WHEN pop.flg_fill_type = g_free_text THEN
                             popr.free_text
                            WHEN pop.flg_fill_type = g_free_date THEN
                             to_clob(get_dt_str(i_lang, i_prof, popr.free_date, popr.free_date_mask))
                            ELSE
                             to_clob(popr.value)
                        END desc_result,
                        NULL desc_unit_measure,
                        popr.id_unit_measure,
                        (SELECT get_reg_opt_icon(i_lang, popr.id_po_param_reg)
                           FROM dual) icon,
                        NULL lab_param_count,
                        NULL lab_param_id,
                        NULL lab_param_rank,
                        NULL val_min,
                        NULL val_max,
                        NULL abnorm_value,
                        popr.option_codes,
                        decode(pop.flg_type,
                               g_others,
                               decode(popr.flg_status,
                                      pk_alert_constant.g_cancelled,
                                      pk_alert_constant.g_no,
                                      decode(popr.id_professional,
                                             i_prof.id,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no)),
                               pk_alert_constant.g_no) flg_cancel,
                        popr.dt_cancel,
                        popr.id_prof_cancel,
                        popr.id_cancel_reason,
                        popr.notes_cancel notes_cancel,
                        CASE
                            WHEN popr.id_pat_pregn_fetus IS NULL THEN
                             to_char(i_comm_order_req)
                            ELSE
                             i_comm_order_req || '|' || popr.id_pat_pregn_fetus
                        END woman_health_id,
                        nvl(popr.flg_ref_value, pk_alert_constant.g_no) flg_ref_value,
                        NULL dt_harvest,
                        NULL dt_execution,
                        NULL notes,
                        NULL id_sample_type
                  FROM (SELECT (SELECT get_reg_opt_codes(popr.id_po_param_reg)
                                   FROM dual) option_codes,
                                popr.*
                           FROM po_param_reg popr
                          WHERE popr.id_patient = i_patient
                            AND nvl(popr.dt_result, i_dt_ini) BETWEEN i_dt_ini AND i_dt_fim) popr
                  JOIN po_param pop
                    ON popr.id_po_param = pop.id_po_param
                   AND popr.id_inst_owner = pop.id_inst_owner
                  JOIN episode e
                    ON popr.id_episode = e.id_episode
                 WHERE popr.id_patient = i_patient) v
          JOIN po_param pop
            ON v.flg_type = pop.flg_type
           AND ((v.id_sample_type = pop.id_sample_type AND pop.flg_fill_type = 'A') OR pop.flg_fill_type <> 'A')
           AND v.id_parameter = nvl(pop.id_parameter, pop.id_po_param)
          JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                 t.id_po_param, t.id_inst_owner
                  FROM TABLE(CAST(i_params AS t_coll_po_param)) t) t
            ON pop.id_po_param = t.id_po_param
           AND pop.id_inst_owner = t.id_inst_owner
          JOIN epis_info ei
            ON v.id_episode = ei.id_episode
         WHERE (v.id_episode = l_episode OR
               v.id_institution IN (SELECT /*+opt_estimate(table t rows=1)*/
                                      t.column_value id_institution
                                       FROM TABLE(CAST(l_insts AS table_number)) t))
           AND (pop.flg_type = g_vital_sign OR --
               (pop.flg_type = g_exam AND v.dt_result > l_time_filter_e) OR --
               (pop.flg_type = g_analysis AND v.dt_result > l_time_filter_a) OR (pop.flg_type = g_others));
    
        RETURN l_ret;
    END get_value_coll_comm_order;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
END pk_periodic_observation;
/
