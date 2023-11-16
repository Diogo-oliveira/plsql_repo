/*-- Last Change Revision: $Rev: 2027701 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_search IS

    g_overlimit  BOOLEAN;
    g_no_results BOOLEAN;

    g_package_name VARCHAR2(30 CHAR);
    g_owner_name   VARCHAR2(30 CHAR);
    g_retval       BOOLEAN;

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        o_error          OUT VARCHAR2
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_alert_exceptions.error_handling(i_lang,
                                                  i_func_proc_name,
                                                  g_package_name,
                                                  i_error,
                                                  i_sqlerror,
                                                  o_error);
    END error_handling;

    FUNCTION get_overlimit_message
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_flg_has_action IN VARCHAR2,
        i_limit          IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_error_message sys_message.desc_message%TYPE;
        l_code_message  sys_message.code_message%TYPE;
        l_limit         sys_config.value%TYPE;
        l_token         VARCHAR2(5 CHAR) := '150';
    
    BEGIN
    
        IF i_flg_has_action = pk_alert_constant.g_yes
        THEN
            l_code_message := 'SEARCH_CRITERIA_M003';
        ELSE
            l_code_message := 'SEARCH_CRITERIA_M006';
        END IF;
    
        IF i_limit IS NULL
        THEN
            l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        ELSE
            l_limit := to_char(i_limit);
        END IF;
    
        l_error_message := REPLACE(pk_message.get_message(i_lang, l_code_message), '@1', l_limit);
    
        RETURN REPLACE(l_error_message, l_token, l_limit);
    END get_overlimit_message;

    FUNCTION noresult_handler
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pck_name IN VARCHAR2,
        i_unitname IN VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret           BOOLEAN;
        l_error_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M015');
        l_error_title   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
    BEGIN
    
        l_ret := pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                   i_sqlcode     => '',
                                                   i_sqlerrm     => l_error_message,
                                                   i_message     => g_error,
                                                   i_owner       => g_owner_name,
                                                   i_package     => i_pck_name,
                                                   i_function    => i_unitname,
                                                   i_action_type => 'D',
                                                   i_action_msg  => l_error_title,
                                                   i_msg_title   => l_error_message,
                                                   i_msg_type    => NULL,
                                                   o_error       => o_error);
    
        pk_alert_exceptions.reset_error_state();
        RETURN l_ret;
    END noresult_handler;

    FUNCTION invalid_number_handler
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pck_name IN VARCHAR2,
        i_unitname IN VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error_in t_error_in := t_error_in();
    
        l_ret           BOOLEAN;
        l_error_message sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M015');
        l_error_title   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
    BEGIN
    
        l_error_in.set_all(i_lang,
                           'COMMON_M015',
                           l_error_message,
                           g_error,
                           g_owner_name,
                           i_pck_name,
                           i_unitname,
                           l_error_title,
                           'D');
    
        l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
        pk_alert_exceptions.reset_error_state();
        RETURN FALSE;
    END invalid_number_handler;

    FUNCTION overlimit_handler
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_pck_name IN VARCHAR2,
        i_unitname IN VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_error_in t_error_in := t_error_in();
    
        l_ret           BOOLEAN;
        l_error_message sys_message.desc_message%TYPE;
        l_error_title   sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_A001');
    
    BEGIN
        l_error_message := get_overlimit_message(i_lang, i_prof, pk_alert_constant.g_no);
    
        l_ret := pk_alert_exceptions.process_error(i_lang        => i_lang,
                                                   i_sqlcode     => '',
                                                   i_sqlerrm     => l_error_message,
                                                   i_message     => g_error,
                                                   i_owner       => g_owner_name,
                                                   i_package     => i_pck_name,
                                                   i_function    => i_unitname,
                                                   i_action_type => 'D',
                                                   i_action_msg  => l_error_title,
                                                   i_msg_title   => l_error_message,
                                                   i_msg_type    => NULL,
                                                   o_error       => o_error);
    
        pk_alert_exceptions.reset_error_state();
    
        RETURN l_ret;
    END overlimit_handler;

    /**
    * Set common context parameters.
    *
    * @param i_lang          language identifier
    * @param i_prof          logged professional structure
    *
    * @author                Pedro Carneiro
    * @version                2.5.1.4
    * @since                 2011/03/10
    */
    PROCEDURE set_context_parameters
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
    BEGIN
        pk_context_api.set_parameter(p_name => 'i_lang', p_value => i_lang);
        pk_context_api.set_parameter(p_name => 'i_prof_id', p_value => i_prof.id);
        pk_context_api.set_parameter(p_name => 'i_prof_institution', p_value => i_prof.institution);
        pk_context_api.set_parameter(p_name => 'i_prof_software', p_value => i_prof.software);
        pk_context_api.set_parameter(p_name  => 'ID_EXTERNAL_SYS',
                                     p_value => pk_sysconfig.get_config(i_code_cf => 'ID_EXTERNAL_SYS', i_prof => i_prof));
        pk_context_api.set_parameter(p_name  => 'EXTERNAL_SYSTEM_EXIST',
                                     p_value => pk_sysconfig.get_config(i_code_cf => 'EXTERNAL_SYSTEM_EXIST',
                                                                        i_prof    => i_prof));
    END set_context_parameters;

    /**
    * Get list of epis_types the user has access to.
    *
    * @param i_prof         logged professional structure
    * @param i_grp_inst     group of institutions
    *
    * @return               list of epis_types
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.2.1
    * @since                2011/01/12
    */
    FUNCTION get_epis_type_access
    (
        i_prof     IN profissional,
        i_grp_inst IN table_number
    ) RETURN table_number IS
        l_et_access        table_number := table_number();
        l_profile_template profile_template.id_profile_template%TYPE;
    BEGIN
        -- get local accesses to epis_types
        -- using all institutions in group
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
        g_error            := 'SELECT l_et_access';
        SELECT DISTINCT eta.id_epis_type
          BULK COLLECT
          INTO l_et_access
          FROM epis_type_access eta
         WHERE eta.id_institution IN (SELECT t.column_value id_institution
                                        FROM TABLE(i_grp_inst) t)
              
           AND eta.flg_add_remove = pk_alert_constant.g_flg_add
           AND eta.id_profile_template IN (l_profile_template, pk_alert_constant.g_profile_template_all)
           AND NOT EXISTS
         (SELECT 1
                  FROM epis_type_access eta1
                 WHERE eta1.id_institution = i_prof.institution
                   AND eta1.flg_add_remove = pk_alert_constant.g_flg_rem
                   AND eta1.id_epis_type = eta.id_epis_type
                   AND eta1.id_profile_template IN (l_profile_template, pk_alert_constant.g_profile_template_all));
    
        IF l_et_access.count < 1
        THEN
            -- when no local accesses are found,
            -- use default accesses
            g_error := 'SELECT l_et_access';
            SELECT DISTINCT eta.id_epis_type
              BULK COLLECT
              INTO l_et_access
              FROM epis_type_access eta
             WHERE eta.id_institution = pk_alert_constant.g_inst_all
               AND eta.id_profile_template IN (l_profile_template, pk_alert_constant.g_profile_template_all)
               AND eta.flg_add_remove = pk_alert_constant.g_flg_add;
        END IF;
    
        IF pk_utils.search_table_number(i_table => l_et_access, i_search => 0) > 0
        THEN
            -- has the user access to all epis_types?
            -- if so, return the "zero" epis_type only, to avoid duplicate search results
            l_et_access := table_number(0);
        END IF;
    
        -- print input and output
        pk_alertlog.log_debug(text            => pk_utils.to_string(i_input => i_prof) || '|l_et_access: ' ||
                                                 pk_utils.to_string(i_input => l_et_access),
                              object_name     => g_package_name,
                              sub_object_name => 'GET_EPIS_TYPE_ACCESS');
    
        RETURN l_et_access;
    END get_epis_type_access;

    FUNCTION get_pat_criteria
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_active          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE DOENTES, DE ACORDO C/ UM CRITÉRIO
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL
                   I_ID_CRITERIA - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA.
                   I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA
                 I_ACTIVE - A - ACTIVO, I - INACTIVO
                 I_INSTIT - INSTITUIÇÃO
                 I_PROF_CAT_TYPE - TIPO DE CATEGORIA DO PROFISSIONAL, TAL 
                       COMO É RETORNADA EM PK_LOGIN.GET_PROF_PREF 
                  SAIDA: O_PAT - DOENTES
                 O_ERROR - ERRO
        
          CRIAÇÃO: CRS 2005/03/30
         
          NOTAS:
        *********************************************************************************/
        l_where VARCHAR2(4000);
        l_error t_error_out;
    
        v_where_cond VARCHAR2(4000);
        id_doc       sys_config.value%TYPE;
        l_aux_sql    VARCHAR2(4000);
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
        
            --LÊ CRITÉRIOS DE PESQUISA E PREENCHE CLÁUSULA WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
            
                IF NOT get_criteria_condition(i_lang,
                                              -- JS, 2007-09-07 - Timezone
                                              i_prof,
                                              i_id_sys_btn_crit(i),
                                              REPLACE(i_crit_val(i), '''', '%'),
                                              v_where_cond,
                                              l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                
                END IF;
                l_where := l_where || v_where_cond;
            END IF;
        
        END LOOP;
    
        id_doc := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
    
        l_aux_sql := 'SELECT PAT.ID_PATIENT, PAT.NAME, E.ID_EPISODE,' ||
                     'nvl(r.desc_room, PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', R.CODE_ROOM)) DESC_ROOM,' ||
                     'PK_DATE_UTILS.GET_ELAPSED_SYSDATE_TSZ(' || i_lang || ', E.DT_BEGIN_TSTZ ) DT_ELAPSED,' ||
                     'PK_DATE_UTILS.DATE_CHAR_TSZ(' || i_lang || ', E.DT_BEGIN_TSTZ, ' || i_prof.institution || ', ' ||
                     i_prof.software || ') DT_BEGIN,' || 'PK_DATE_UTILS.DATE_CHAR_TSZ(' || i_lang ||
                     ', F.DT_FIRST_OBS_TSTZ, ' || i_prof.institution || ', ' || i_prof.software || ') DT_FIRST_OBS,' || '''' ||
                     g_sysdate_char || ''' DT_SERVER,' || 'CR.NUM_CLIN_RECORD ' ||
                     'FROM EPISODE E, EPIS_INFO F, VISIT V, PROFESSIONAL PROF,' ||
                     'PATIENT PAT, EPIS_EXT_SYS EES, ROOM R, CLIN_RECORD CR,' || 'PAT_SOC_ATTRIBUTES PSA, ' ||
                     '(SELECT DISTINCT DE.ID_DOC_TYPE, DE.FLG_STATUS, DE.ID_PATIENT, DE.NUM_DOC ' ||
                     ' FROM DOC_EXTERNAL DE ' || ' WHERE DE.ID_DOC_TYPE = ' || id_doc || ') DE ' ||
                     'WHERE E.ID_EPIS_TYPE = PK_SYSCONFIG.GET_CONFIG(''ID_EPIS_TYPE_CONSULT'', ' || i_prof.institution || ', ' ||
                     i_prof.software || ')' || ' AND E.FLG_STATUS = ''' || i_active || '''' ||
                     ' AND F.ID_EPISODE = E.ID_EPISODE' || ' AND F.ID_PROFESSIONAL = PROF.ID_PROFESSIONAL(+)' ||
                     ' AND E.ID_VISIT = V.ID_VISIT' || ' AND V.FLG_STATUS = ''' || i_active || '''' ||
                     ' AND PAT.ID_PATIENT = V.ID_PATIENT' || ' AND DE.ID_PATIENT = PAT.ID_PATIENT' ||
                     ' AND DE.ID_DOC_TYPE = PK_SYSCONFIG.GET_CONFIG(''DOC_TYPE_ID'', ' || i_prof.institution || ', ' ||
                     i_prof.software || ')' || ' AND DE.FLG_STATUS(+) = ''' || g_doc_active || '''' ||
                     ' AND E.ID_EPISODE = EES.ID_EPISODE' || ' and ees.id_institution = ' || i_prof.institution ||
                     ' AND EES.ID_EXTERNAL_SYS = PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'', ' || i_prof.institution || ', ' ||
                     i_prof.software || ')' || ' AND R.ID_ROOM = F.ID_ROOM' || ' AND CR.ID_PATIENT = PAT.ID_PATIENT' ||
                     ' AND CR.FLG_STATUS = ''' || g_clin_rec_active || '''' || ' AND CR.ID_INSTITUTION = ' ||
                     i_prof.institution || ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT ' ||
                     ' AND PSA.ID_INSTITUTION(+) = ' || i_prof.institution || l_where;
        g_error   := 'GET CURSOR';
        OPEN o_pat FOR l_aux_sql;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
        
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRITERIA',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRITERIA',
                                              'S',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
        
    END;

    /**********************************************************************************************
    * Diagnosis search using an input value
    *
    * @param i_lang                   language identifier
    * @param i_value                  search input
    * @param i_prof                   logged professional structure
    * @param i_patient                patient ID
    * @param o_flg_show               shows warning message: Y - yes, N - No
    * @param o_msg                    message text
    * @param o_msg_title              message title
    * @param o_button                 buttons to show: N-No, R-Read, C-Confirmed
    * @param o_diag                   search result
    * @param o_error                  error
    *
    * @return                         false, if errors occur, true otherwise
    *                        
    * @author                         CRS
    * @version                        1.0
    * @since                          2005/03/31
    *
    * @author                         José Silva
    * @version                        2.0 (LUCENE Text Index usage)
    * @since                          2009/10/28
    **********************************************************************************************/
    FUNCTION get_diag_criteria
    (
        i_lang      IN language.id_language%TYPE,
        i_value     IN VARCHAR2,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_diag      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_synonym_list_enable   sys_config.value%TYPE;
        l_synonym_search_enable sys_config.value%TYPE;
        l_other_diagnosis       sys_config.value%TYPE;
    
        l_count NUMBER;
        l_limit NUMBER;
    
        l_tbl_diags t_coll_diagnosis_config;
    
    BEGIN
        IF i_value IS NULL
        THEN
            pk_types.open_my_cursor(o_diag);
            RETURN TRUE;
        END IF;
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        l_limit        := to_number(pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof));
        o_flg_show     := 'N';
    
        g_error := 'GET CONFIG';
        --Flg for other diagnosis
        l_other_diagnosis := pk_sysconfig.get_config('PERMISSION_FOR_OTHER_DIAGNOSIS', i_prof);
        -- enable/disable synonyms in search and reply result sets
        l_synonym_list_enable := nvl(pk_sysconfig.get_config('DIAGNOSIS_SYNONYMS_LIST_ENABLE', i_prof), g_no);
        -- include the official diagnoses descriptions if search was done using a synonym
        l_synonym_search_enable := nvl(pk_sysconfig.get_config('DIAGNOSIS_SYNONYMS_SEARCH_ENABLE', i_prof), g_no);
    
        l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_patient                  => i_patient,
                                                               i_text_search              => i_value,
                                                               i_format_text              => pk_alert_constant.g_no,
                                                               i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                               i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                               i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                               i_synonym_list_enable      => l_synonym_list_enable,
                                                               i_synonym_search_enable    => l_synonym_search_enable,
                                                               i_include_other_diagnosis  => l_other_diagnosis,
                                                               i_row_limit                => l_limit + 10); --If I don't change the limit then the warning message bellow is never shown.
    
        -- check limit
        l_count := l_tbl_diags.count;
        IF l_count > l_limit
           AND pk_sysconfig.get_config('DIAGNOSIS_SHOW_SEARCH_ERROR', i_prof) = pk_alert_constant.g_yes
        THEN
            o_flg_show  := 'Y';
            o_msg       := get_overlimit_message(i_lang, i_prof, pk_alert_constant.g_yes, l_limit);
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
            o_button    := 'DW';
        ELSIF l_count = 0
        --AND l_other_diagnosis = g_no
        THEN
            RAISE pk_search.e_noresults;
        END IF;
        --
        g_error := 'GET CURSOR';
        OPEN o_diag FOR
            SELECT dc.desc_diagnosis     diag,
                   dc.id_diagnosis,
                   dc.code_icd,
                   0                     rank,
                   dc.avail_for_select   flg_select,
                   dc.flg_other,
                   dc.id_alert_diagnosis,
                   dc.flg_diag_type
              FROM TABLE(l_tbl_diags) dc
             WHERE rownum <= l_limit
                OR l_limit IS NULL;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_diag);
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE', o_error);
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_DIAG_CRITERIA',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_diag);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_diag_criteria;

    FUNCTION get_diag_criteria_death
    (
        i_lang      IN language.id_language%TYPE,
        i_value     IN VARCHAR2,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_section   IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_diag      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_synonym_list_enable   sys_config.value%TYPE;
        l_synonym_search_enable sys_config.value%TYPE;
        l_other_diagnosis       sys_config.value%TYPE;
    
        l_count NUMBER;
        l_limit NUMBER;
        l_num_a NUMBER;
    
        l_tbl_diags        t_coll_diagnosis_config;
        l_tbl_diags_a      t_coll_diagnosis_config;
        l_filter_diagnosis sys_config.value%TYPE;
    
    BEGIN
    
        IF i_value IS NULL
        THEN
            pk_types.open_my_cursor(o_diag);
            RETURN TRUE;
        END IF;
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        l_limit        := to_number(pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof));
        o_flg_show     := 'N';
    
        g_error := 'GET CONFIG';
        --Flg for other diagnosis
        l_other_diagnosis := pk_sysconfig.get_config('PERMISSION_FOR_OTHER_DIAGNOSIS', i_prof);
        -- enable/disable synonyms in search and reply result sets
        l_synonym_list_enable := nvl(pk_sysconfig.get_config('DIAGNOSIS_SYNONYMS_LIST_ENABLE', i_prof), g_no);
        -- include the official diagnoses descriptions if search was done using a synonym
        l_synonym_search_enable := nvl(pk_sysconfig.get_config('DIAGNOSIS_SYNONYMS_SEARCH_ENABLE', i_prof), g_no);
        l_filter_diagnosis      := pk_sysconfig.get_config('DEATH_REGISTRY_DIAG_FILTER_MX_CAT', i_prof);
    
        g_error     := 'CALL pk_terminology_search.tf_diagnoses_list';
        l_tbl_diags := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                               i_prof                     => i_prof,
                                                               i_patient                  => i_patient,
                                                               i_text_search              => i_value,
                                                               i_format_text              => pk_alert_constant.g_no,
                                                               i_terminologies_task_types => table_number(pk_alert_constant.g_task_diagnosis),
                                                               i_term_task_type           => pk_alert_constant.g_task_diagnosis,
                                                               i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                               i_synonym_list_enable      => l_synonym_list_enable,
                                                               i_synonym_search_enable    => l_synonym_search_enable,
                                                               i_include_other_diagnosis  => l_other_diagnosis,
                                                               i_row_limit                => l_limit + 10); --If I don't change the limit then the warning message bellow is never shown.
        IF l_filter_diagnosis = pk_alert_constant.g_yes
        THEN
            g_error       := 'CALL pk_terminology_search.tf_diagnoses_list (FILTER)';
            l_tbl_diags_a := pk_terminology_search.tf_diagnoses_list(i_lang                     => i_lang,
                                                                     i_prof                     => i_prof,
                                                                     i_patient                  => i_patient,
                                                                     i_text_search              => i_value,
                                                                     i_format_text              => pk_alert_constant.g_no,
                                                                     i_terminologies_task_types => table_number(pk_alert_constant.g_task_medical_history),
                                                                     i_term_task_type           => pk_alert_constant.g_task_medical_history, --pk_alert_constant.g_task_diagnosis,
                                                                     i_list_type                => pk_diagnosis_core.g_diag_list_searchable,
                                                                     i_synonym_list_enable      => l_synonym_list_enable,
                                                                     i_synonym_search_enable    => l_synonym_search_enable,
                                                                     i_include_other_diagnosis  => l_other_diagnosis,
                                                                     i_row_limit                => l_limit + 10); --If I don't change the limit then the warning message bellow is never shown.
        
            l_num_a := l_tbl_diags_a.count;
        END IF;
    
        -- check limit
        l_count := l_tbl_diags.count + l_num_a;
    
        g_error := 'CHECK LIMIT l_count:' || l_count || ' l_limit:' || l_limit;
        IF l_count > l_limit
           AND pk_sysconfig.get_config('DIAGNOSIS_SHOW_SEARCH_ERROR', i_prof) = pk_alert_constant.g_yes
        THEN
            o_flg_show  := 'Y';
            o_msg       := get_overlimit_message(i_lang, i_prof, pk_alert_constant.g_yes, l_limit);
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
            o_button    := 'DW';
        ELSIF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_filter_diagnosis = pk_alert_constant.g_yes
        THEN
            g_error := 'GET CURSOR filter';
            OPEN o_diag FOR
                SELECT dc.desc_diagnosis     diag,
                       dc.id_diagnosis,
                       dc.code_icd,
                       0                     rank,
                       dc.avail_for_select   flg_select,
                       dc.flg_other,
                       dc.id_alert_diagnosis,
                       dc.flg_diag_type
                  FROM TABLE(l_tbl_diags) dc
                  JOIN cat_diagnosis cd
                    ON cd.id_concept_term = dc.id_alert_diagnosis
                 WHERE (rownum <= l_limit OR l_limit IS NULL)
                   AND ((i_section = 'DEATH_DATA') OR (cd.fetal = 'SI' AND i_section = 'DEATH_DATA_FETAL'))
                   AND nvl(cd.flg_available, pk_alert_constant.g_yes) = 'Y'
                UNION
                SELECT dc.desc_diagnosis     diag,
                       dc.id_diagnosis,
                       dc.code_icd,
                       0                     rank,
                       dc.avail_for_select   flg_select,
                       dc.flg_other,
                       dc.id_alert_diagnosis,
                       dc.flg_diag_type
                  FROM TABLE(l_tbl_diags_a) dc
                  JOIN cat_diagnosis cd
                    ON cd.id_concept_term = dc.id_alert_diagnosis
                 WHERE (rownum <= l_limit OR l_limit IS NULL)
                   AND ((i_section = 'DEATH_DATA') OR (cd.fetal = 'SI' AND i_section = 'DEATH_DATA_FETAL'))
                   AND nvl(cd.flg_available, pk_alert_constant.g_yes) = 'Y'
                   AND (cd.lsup IS NOT NULL OR cd.linf IS NOT NULL);
        
        ELSE
            g_error := 'GET CURSOR';
            OPEN o_diag FOR
                SELECT dc.desc_diagnosis     diag,
                       dc.id_diagnosis,
                       dc.code_icd,
                       0                     rank,
                       dc.avail_for_select   flg_select,
                       dc.flg_other,
                       dc.id_alert_diagnosis,
                       dc.flg_diag_type
                  FROM TABLE(l_tbl_diags) dc
                 WHERE rownum <= l_limit
                    OR l_limit IS NULL;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_diag);
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_DIAG_CRITERIA_DEATH', o_error);
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_DIAG_CRITERIA_DEATH',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_diag);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_diag_criteria_death;

    FUNCTION get_diag_criteria2
    (
        i_lang      IN language.id_language%TYPE,
        i_value     IN VARCHAR2,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_diag      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO  :   EFECTUAR PESQUISA DE DIAGNÓSTICOS, DE ACORDO C/ UM CRITÉRIO 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL
                I_VALUE - VALOR DO CRITÉRIO DE PESQUISA 
             I_PROF - PROFISSIONAL Q PESQUISA 
               SAIDA: O_FLG_SHOW - Y - EXISTE MSG PARA MOSTRAR; N - Ñ EXISTE  
             O_MSG - MENSAGEM COM INDICAÇÃO DE Q ULTRAPASSOU O Nº LIMITE DE REGISTOS 
             O_MSG_TITLE - TÍTULO DA MSG A MOSTRAR AO UTILIZADOR, CASO 
             O_FLG_SHOW = Y 
             O_BUTTON - BOTÕES A MOSTRAR: N - NÃO, R - LIDO, C - CONFIRMADO 
              TB PODE MOSTRAR COMBINAÇÕES DESTES, QD É P/ MOSTRAR 
              + DO Q 1 BOTÃO 
             O_DIAG -  DIAGNÓSTICOS
             O_ERROR - ERRO
        
          CRIAÇÃO: CRS 2005/03/31 
          
          NOTAS: LG 2007-MAR-21 ENTRAR EM CONTA COM A CONFIGURAÇÃO DE TIPOS DE DIAGNÓSTICO EM USO NO SOFTWARE/INSTITUIÇÃO
        *********************************************************************************/
        l_diagnosis_type sys_config.value%TYPE;
    
        CURSOR c_pat IS
            SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', patient.gender, i_lang) gender,
                   months_between(SYSDATE, dt_birth) / 12 age --, (SYSDATE-DT_BIRTH) DAYS
              FROM patient
             WHERE id_patient = i_patient;
        r_pat c_pat%ROWTYPE;
    
        l_other_diagnosis sys_config.value%TYPE;
    
        l_tbl_flg_terminologies t_table_terminology;
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        --l_limit        := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        o_flg_show := 'N';
    
        --Flg for other diagnosis
        l_other_diagnosis := pk_sysconfig.get_config('PERMISSION_FOR_OTHER_DIAGNOSIS', i_prof);
    
        l_tbl_flg_terminologies := pk_diagnosis_core.tf_diag_terminologies(i_lang          => i_lang,
                                                                           i_prof          => i_prof,
                                                                           i_tbl_task_type => table_number(pk_alert_constant.g_task_diagnosis));
    
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
    
        g_error          := 'GET CONFIGURATIONS';
        g_diag_show_code := pk_sysconfig.get_config('DIAGNOSIS_SHOW_CODE', i_prof);
        --
        g_error := 'GET CURSOR';
        OPEN o_diag FOR
            SELECT pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_diagnosis => d.id_diagnosis,
                                              i_code         => d.code_icd,
                                              i_flg_other    => d.flg_other,
                                              i_flg_std_diag => pk_alert_constant.g_yes) diag,
                   d.id_diagnosis,
                   d.code_icd,
                   0 rank,
                   'Y' flg_select
              FROM diagnosis_content d
             WHERE d.flg_select = pk_alert_constant.g_yes
               AND translate(upper(pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                                              i_prof         => i_prof,
                                                              i_id_diagnosis => d.id_diagnosis,
                                                              i_code         => d.code_icd,
                                                              i_flg_other    => d.flg_other,
                                                              i_flg_std_diag => pk_alert_constant.g_yes)),
                             'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ',
                             'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
                   '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
               AND d.id_institution = i_prof.institution
               AND d.flg_other != g_diag_other
               AND d.id_software = i_prof.software
               AND d.flg_type IN (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                                   tdgc.flg_terminology
                                    FROM TABLE(l_tbl_flg_terminologies) tdgc)
               AND ((r_pat.gender IS NOT NULL AND nvl(d.gender, 'I') IN ('I', r_pat.gender)) OR r_pat.gender IS NULL OR
                   r_pat.gender = 'I')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(d.age_min, 0) AND nvl(d.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
            UNION
            SELECT pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_diagnosis => d.id_diagnosis,
                                              i_code         => d.code_icd,
                                              i_flg_other    => d.flg_other,
                                              i_flg_std_diag => pk_alert_constant.g_yes) diag,
                   d.id_diagnosis,
                   d.code_icd,
                   1 rank,
                   'N' flg_select
              FROM diagnosis_content d
             WHERE d.flg_other = g_diag_other
               AND l_other_diagnosis = 'Y'
               AND d.id_institution = i_prof.institution
               AND d.id_software = i_prof.software
               AND d.flg_type IN (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
                                   tdgc.flg_terminology
                                    FROM TABLE(l_tbl_flg_terminologies) tdgc)
               AND ((r_pat.gender IS NOT NULL AND nvl(d.gender, 'I') IN ('I', r_pat.gender)) OR r_pat.gender IS NULL OR
                   r_pat.gender = 'I')
               AND (nvl(r_pat.age, 0) BETWEEN nvl(d.age_min, 0) AND nvl(d.age_max, nvl(r_pat.age, 0)) OR
                   nvl(r_pat.age, 0) = 0)
             ORDER BY rank, diag;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_DIAG_CRITERIA2',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_DIAG_CRITERIA2',
                                              'S',
                                              o_error);
        
            -- open cursors for java                
            pk_types.open_my_cursor(o_diag);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END;

    PROCEDURE set_hand_off_ctx_param_int
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) IS
        l_prof_cat     category.flg_type%TYPE;
        l_handoff_type sys_config.value%TYPE;
    BEGIN
        g_error := 'GET PROF CAT';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name);
        l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'GET HANDOFF TYPE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_inst', i_prof.institution);
        pk_context_api.set_parameter('i_prof_soft', i_prof.software);
        pk_context_api.set_parameter('i_prof_cat', l_prof_cat);
        pk_context_api.set_parameter('i_handoff_type', l_handoff_type);
    END set_hand_off_ctx_param_int;

    FUNCTION get_criteria_condition(i_lang IN language.id_language%TYPE,
                                    -- JS, 2007-09-07 - Timezone
                                    i_prof           IN profissional,
                                    i_id_criteria    IN criteria.id_criteria%TYPE,
                                    i_criteria_value IN VARCHAR2,
                                    o_crit_condition OUT criteria.crit_condition%TYPE,
                                    --o_error          OUT VARCHAR2
                                    o_error OUT t_error_out) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE DETALHE DE CRITÉRIOS E VALIDA PREENCHIMENTO OBRIGATÓRIO 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL
                   I_ID_CRITERIA - ID DO CRITÉRIO DE PESQUISA
                 I_CRITERIA_VALUE - ID DO CRITÉRIO DE PESQUISA
                  SAIDA: O_DIAG -  DIAGNÓSTICOS
                 O_ERROR - ERRO
        
          CRIAÇÃO: CRS 2005/04/21
          
          NOTAS:
        *********************************************************************************/
        v_crit_condition criteria.crit_condition%TYPE;
    
        CURSOR c_crit IS
            SELECT crit_condition
              FROM criteria c
             WHERE c.id_criteria = i_id_criteria;
    BEGIN
        g_error := 'GET CRITERIA';
        OPEN c_crit;
        FETCH c_crit
            INTO v_crit_condition;
        g_found := c_crit%FOUND;
        CLOSE c_crit;
    
        IF NOT g_found
        THEN
            --o_error 
            g_error := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_M001') || chr(10) ||
                       'PK_SEARCH.GET_CRITERIA_CONDITION / ' || g_error;
            RETURN FALSE;
        END IF;
    
        IF nvl(i_criteria_value, '@') != '@'
        THEN
            o_crit_condition := REPLACE(v_crit_condition, '@1', i_criteria_value);
        END IF;
    
        -- JS, 2007-09-07 - Timezone
        o_crit_condition := REPLACE(o_crit_condition, '@PROFESSIONAL', i_prof.id);
        o_crit_condition := REPLACE(o_crit_condition, '@INSTITUTION', i_prof.institution);
        o_crit_condition := REPLACE(o_crit_condition, '@SOFTWARE', i_prof.software);
    
        -- Alexandre Santos, 2010-03-03 - ALERT-69467 - VIP
        o_crit_condition := REPLACE(o_crit_condition, '@I_LANG', i_lang);
    
        -- Alexandre Santos, 2010-11-03 - ALERT-726 - HandOff
        set_hand_off_ctx_param_int(i_lang => i_lang, i_prof => i_prof);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_CRITERIA_CONDITION',
                                              'S',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_CRITERIA_CONDITION',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
        
    END get_criteria_condition;

    /*
    * Gets the query for patient search
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional id, institution and software    
    * @param   i_id_criteria     Id Criteria 
    * @param   i_criteria_value  Criteria value       
    * @param   o_from_condition  Condition in SQL FROM Clause
    * @param   o_error           Error message    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   27-10-2010
    */
    FUNCTION get_from_condition
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_criteria    IN criteria.id_criteria%TYPE,
        i_criteria_value IN VARCHAR2,
        o_from_condition OUT criteria.from_condition%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        v_from_condition criteria.from_condition%TYPE;
        v_code_criteria  criteria.code_criteria%TYPE;
    
        CURSOR c_crit IS
            SELECT from_condition, code_criteria
              FROM criteria c
             WHERE c.id_criteria = i_id_criteria;
    
    BEGIN
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        o_from_condition := NULL;
    
        g_error := 'GET FROM CRITERIA';
        OPEN c_crit;
        FETCH c_crit
            INTO v_from_condition, v_code_criteria;
        g_found := c_crit%FOUND;
        CLOSE c_crit;
    
        IF NOT g_found
        THEN
            g_error := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_M001') || chr(10) ||
                       'PK_SEARCH.GET_CRITERIA_CONDITION / ' || g_error;
            RETURN FALSE;
        END IF;
    
        IF nvl(i_criteria_value, '@') != '@'
        THEN
            o_from_condition := REPLACE(v_from_condition, '@1', i_criteria_value);
        END IF;
    
        o_from_condition := REPLACE(o_from_condition, '@PROFESSIONAL', i_prof.id);
        o_from_condition := REPLACE(o_from_condition, '@INSTITUTION', i_prof.institution);
        o_from_condition := REPLACE(o_from_condition, '@SOFTWARE', i_prof.software);
        o_from_condition := REPLACE(o_from_condition, '@I_LANG', i_lang);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_FROM_CONDITION',
                                              'S',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_FROM_CONDITION',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_from_condition;

    /*
    * Gets the where clause to be used in the search
    *
    * @param   i_criteria        Id Criteria 
    * @param   i_crit_val        Criteria value       
    * @param   i_lang            Language ID
    * @param   i_prof            Logged professional structure
    
    * @param   o_where           Where clause
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Fábio Oliveira
    * @version 1.0
    * @since   2008/06/04
    */
    FUNCTION get_where
    (
        i_criteria IN table_number,
        i_crit_val IN table_varchar,
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_where    OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN IS
    
        g_crit_type_multivalue CONSTANT VARCHAR2(1) := 'C';
    
        CURSOR c_get IS
            SELECT c.id_criteria, crit_condition cc, c.flg_type
              FROM criteria c
             WHERE c.id_criteria IN (SELECT *
                                       FROM TABLE(i_criteria))
               AND c.crit_condition IS NOT NULL;
    
        -- tipo e collection para receber os resultados do cursor
        TYPE l_get_t IS TABLE OF c_get%ROWTYPE INDEX BY PLS_INTEGER;
        l_get l_get_t;
    
        l_aux    VARCHAR2(32000);
        l_vc_aux table_varchar;
    
    BEGIN
    
        IF (i_criteria.count = 0)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Alexandre Santos, 2010-11-03 - ALERT-726 - HandOff
        set_hand_off_ctx_param_int(i_lang => i_lang, i_prof => i_prof);
    
        -- abre cursor e faz bulk collect para dentro da collection
        OPEN c_get;
        FETCH c_get BULK COLLECT
            INTO l_get;
        CLOSE c_get;
    
        IF (l_get.count = 0)
        THEN
            RETURN TRUE;
        END IF;
    
        -- percorre a lista de critérios recebida
        FOR i IN i_criteria.first .. i_criteria.last
        LOOP
            -- percorre a lista de critérios obtida da base de dados
            FOR j IN l_get.first .. l_get.last
            LOOP
                -- chegamos ao critério pretendido...
                IF (i_criteria(i) = l_get(j).id_criteria AND i_crit_val(i) IS NOT NULL AND i_crit_val(i) != '-1')
                THEN
                    -- só permite pesquisar por valores separados por vírgulas para critérios multivalor
                    -- se retirarmos o if e aproveitarmos apenas o código para o caso em que retorna verdadeiro passa a aceitar para todos os tipos de critérios, ie. passamos a poder pesquisar por nome pacientes de vários profissionais digitando os nomes deles separados por vírgulas
                    IF (l_get(j).flg_type = g_crit_type_multivalue)
                    THEN
                        -- obtém os diferentes valores separados por vírgulas
                        -- pk_utils.str_split_c só pode ser usado em SQL
                        SELECT pk_utils.str_split_c(i_crit_val(i), ',')
                          INTO l_vc_aux
                          FROM dual;
                    
                        -- começa a percorrer os vários valores obtidos
                        l_aux := '(';
                        FOR k IN l_vc_aux.first .. l_vc_aux.last
                        LOOP
                            -- validar que não se tratam de valores vazios (caso em que se introduzem sequências de vírgulas e espaços vazios)
                            IF (TRIM(l_vc_aux(k)) IS NOT NULL)
                            THEN
                                -- definir uma variável de contexto com o valor inserido
                                -- o formato do nome da variável é 'SEARCH_P<id_criteria>_<# do elemento>
                                pk_context_api.set_parameter(p_name  => 'SEARCH_P' || l_get(j).id_criteria || '_' || k,
                                                             p_value => TRIM(l_vc_aux(k)));
                            
                                -- concatenar a string que validará os critérios introduzidos
                                -- os vários valores de um mesmo critério são concatenados com conjunções OR
                                -- neste momento usa-se substr e trim para eliminar os strings AND que os critérios contêm
                                IF l_aux = '('
                                THEN
                                    l_aux := l_aux || substr(TRIM(REPLACE(l_get(j).cc,
                                                                          'SEARCH_P' || l_get(j).id_criteria,
                                                                          'SEARCH_P' || l_get(j).id_criteria || '_' || k)),
                                                             5);
                                ELSE
                                    l_aux := l_aux || ' OR ' || substr(TRIM(REPLACE(l_get(j).cc,
                                                                                    'SEARCH_P' || l_get(j).id_criteria,
                                                                                    'SEARCH_P' || l_get(j).id_criteria || '_' || k)),
                                                                       5);
                                END IF;
                            END IF;
                        END LOOP;
                    
                        -- validar que se encontrou algum valor e se for o caso, concatenar com os restantes critérios inseridos
                        -- critérios diferentes são concatenados com conjunções AND
                        IF l_aux != '('
                        THEN
                            l_aux   := l_aux || ')';
                            o_where := o_where || ' AND ' || l_aux;
                        END IF;
                    ELSE
                        pk_context_api.set_parameter(p_name  => 'SEARCH_P' || l_get(j).id_criteria,
                                                     p_value => i_crit_val(i));
                        o_where := o_where || l_get(j).cc;
                    END IF;
                    -- ... visto já termos encontrado o critério pretendido, saltamos fora do loop
                    EXIT;
                END IF;
            END LOOP;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_where;

    /*
    * Gets the from clause to be used in the search
    *
    * @param   i_criteria        Id Criteria 
    * @param   i_crit_val        Criteria value       
    * @param   i_lang            Language ID
    * @param   i_prof            Logged professional structure
    
    * @param   o_from            From clause
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  José Silva
    * @version 2.6.0.5
    * @since   2011/02/15
    */
    FUNCTION get_from
    (
        i_criteria IN table_number,
        i_crit_val IN table_varchar,
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_from     OUT NOCOPY VARCHAR2,
        o_hint     OUT NOCOPY VARCHAR2
    ) RETURN BOOLEAN IS
    
        CURSOR c_get IS
            SELECT c.id_criteria, from_condition fc, hint_condition hc
              FROM criteria c
             WHERE c.id_criteria IN (SELECT *
                                       FROM TABLE(i_criteria))
               AND c.from_condition IS NOT NULL;
    
        -- tipo e collection para receber os resultados do cursor
        TYPE l_get_t IS TABLE OF c_get%ROWTYPE INDEX BY PLS_INTEGER;
        l_get l_get_t;
    
    BEGIN
    
        IF (i_criteria.count = 0)
        THEN
            RETURN FALSE;
        END IF;
    
        -- abre cursor e faz bulk collect para dentro da collection
        OPEN c_get;
        FETCH c_get BULK COLLECT
            INTO l_get;
        CLOSE c_get;
    
        IF (l_get.count = 0)
        THEN
            RETURN TRUE;
        END IF;
    
        -- percorre a lista de critérios recebida
        FOR i IN i_criteria.first .. i_criteria.last
        LOOP
            -- percorre a lista de critérios obtida da base de dados
            FOR j IN l_get.first .. l_get.last
            LOOP
                -- chegamos ao critério pretendido...
                IF (i_criteria(i) = l_get(j).id_criteria AND i_crit_val(i) IS NOT NULL)
                THEN
                    pk_context_api.set_parameter(p_name  => 'SEARCH_P' || l_get(j).id_criteria,
                                                 p_value => i_crit_val(i));
                    o_from := o_from || l_get(j).fc;
                    o_hint := l_get(j).hc;
                
                    -- ... visto já termos encontrado o critério pretendido, saltamos fora do loop
                    EXIT;
                END IF;
            END LOOP;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_from;

    /**
    * Get FROM and WHERE clauses to apply on searches.
    * Supports lucene text based index criterias.
    *
    * @param i_lang          language identifier
    * @param i_prof          logged professional structure
    * @param i_crit_id       criteria identifiers list
    * @param i_crit_val      criteria values list
    * @param o_from          from clause
    * @param o_from          query hint
    * @param o_where         where clause
    * @param o_error         error
    *
    * @return                false if errors occur, true otherwise
    *
    * @author                Pedro Carneiro
    * @version                2.5.1.4
    * @since                 2011/03/09
    */
    FUNCTION get_from_and_where
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_crit_id  IN table_number,
        i_crit_val IN table_varchar,
        o_from     OUT criteria.from_condition%TYPE,
        o_hint     OUT criteria.hint_condition%TYPE,
        o_where    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FROM_AND_WHERE';
    BEGIN
        -- get criteria related "from" clause
        g_error := 'CALL get_from';
        IF NOT get_from(i_criteria => i_crit_id,
                        i_crit_val => i_crit_val,
                        i_lang     => i_lang,
                        i_prof     => i_prof,
                        o_from     => o_from,
                        o_hint     => o_hint)
        THEN
            o_from := NULL;
            o_hint := NULL;
        END IF;
    
        -- get criteria related "where" clause
        g_error := 'CALL get_where';
        IF NOT get_where(i_criteria => i_crit_id,
                         i_crit_val => i_crit_val,
                         i_lang     => i_lang,
                         i_prof     => i_prof,
                         o_where    => o_where)
        THEN
            o_where := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_from_and_where;

    FUNCTION get_pat_criteria_active
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: EFECTUAR PESQUISA DE DOENTES ACTIVOS, DE ACORDO COM OS CRITÉRIOS 
                  SELECCIONADOS , PARA PESSOAL NÃO CLÍNICO. 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                   I_ID_SYS_BTN_CRIT - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
                   I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA              
                 I_INSTIT - INSTITUIÇÃO 
                 I_EPIS_TYPE - TIPO DE CONSULTA
                 I_DT - DATA A PESQUISAR. SE FOR NULL ASSUME A DATA DE SISTEMA
                   I_PROF - PROFISSIONAL Q REGISTA 
                  SAIDA: O_FLG_SHOW - Y - EXISTE MSG PARA MOSTRAR; N - Ñ EXISTE  
                 O_MSG - MENSAGEM COM INDICAÇÃO DE Q ULTRAPASSOU O Nº LIMITE DE REGISTOS 
                 O_MSG_TITLE - TÍTULO DA MSG A MOSTRAR AO UTILIZADOR, CASO 
                 O_FLG_SHOW = Y 
                 O_BUTTON - BOTÕES A MOSTRAR: N - NÃO, R - LIDO, C - CONFIRMADO 
                    TB PODE MOSTRAR COMBINAÇÕES DESTES, QD É P/ MOSTRAR 
                    + DO Q 1 BOTÃO 
                 O_PAT - DOENTES 
                 O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
                 O_ERROR - ERRO 
          
          CRIAÇÃO: RB 2005/04/22 
          ALTERAÇÃO: CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS
                     LG 2007/02/14 CRITÉRIO DE PESQUISA PELO ESTADO DO PAGAMENTO 
          
          NOTAS: 
        *********************************************************************************/
        l_where      VARCHAR2(32767);
        l_from       VARCHAR2(32767);
        l_hint       criteria.hint_condition%TYPE;
        l_order_by   VARCHAR2(12 CHAR);
        l_date_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_end   TIMESTAMP WITH LOCAL TIME ZONE;
        l_count      NUMBER;
        l_limit      sys_config.value%TYPE;
        l_sql        VARCHAR2(32767);
    BEGIN
        g_error        := 'BEGIN';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        o_flg_show     := 'N';
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof); -- Nº MÁXIMO DE REGISTOS A APRESENTAR
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        g_error := 'GET l_date';
        IF i_dt_str IS NULL
        THEN
            l_date_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
            l_date_end   := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz + INTERVAL '1' DAY);
        ELSE
            l_date_begin := pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_dt_str);
            l_date_end   := pk_date_utils.get_timestamp_insttimezone(i_lang, i_prof, i_dt_str) + INTERVAL '1' DAY;
        END IF;
    
        set_context_parameters(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'CALL get_from_and_where';
        IF NOT get_from_and_where(i_lang     => i_lang,
                                  i_prof     => i_prof,
                                  i_crit_id  => i_id_sys_btn_crit,
                                  i_crit_val => i_crit_val,
                                  o_from     => l_from,
                                  o_hint     => l_hint,
                                  o_where    => l_where,
                                  o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET COUNT';
        l_sql   := '
SELECT COUNT(*)
  FROM schedule_outp sp
  JOIN schedule s
    ON sp.id_schedule = s.id_schedule
  JOIN sch_group sg
    ON s.id_schedule = sg.id_schedule
  JOIN patient pat
    ON sg.id_patient = pat.id_patient
  JOIN clin_record cr
    ON pat.id_patient = cr.id_patient
  LEFT JOIN sch_prof_outp ps
    ON sp.id_schedule_outp = ps.id_schedule_outp
  LEFT JOIN epis_info ei
    ON s.id_schedule = ei.id_schedule
  LEFT JOIN episode epis
    ON ei.id_episode = epis.id_episode
   AND sg.id_patient = epis.id_patient
  LEFT JOIN clinical_service cs
    ON epis.id_cs_requested = cs.id_clinical_service
 ' || l_from || '
  LEFT JOIN professional p
    ON nvl(ei.id_professional, ps.id_professional) = p.id_professional
  LEFT JOIN discharge d
    ON epis.id_episode = d.id_episode
 WHERE sp.id_software = :i_prof_software
   AND sp.dt_target_tstz BETWEEN :l_date_begin AND :l_date_end
   AND s.id_instit_requested = :i_prof_institution
   AND s.flg_status NOT IN (:g_sched_cancel, :g_sched_status_cache)
   AND cr.id_institution = :i_prof_institution
   AND cr.flg_status = :g_clin_active
   AND (epis.flg_status IS NULL OR epis.flg_status NOT IN (:g_epis_inactive, :g_epis_canc))
   AND epis.flg_ehr != :g_flg_ehr_e
   AND (d.flg_status IS NULL OR d.flg_status NOT IN (:g_disch_status_cancel, :g_disch_status_reopen))
 ' || l_where || '
   AND rownum <= :l_limit + 1';
    
        g_error := 'GET EXECUTE IMMEDIATE ';
        EXECUTE IMMEDIATE l_sql
            INTO l_count
            USING --
        i_prof.software, --
        l_date_begin, --
        l_date_end, --
        i_prof.institution, --
        g_sched_cancel, --
        pk_schedule.g_sched_status_cache, --
        i_prof.institution, --
        g_clin_active, --
        g_epis_inactive, --
        g_epis_canc, --
        pk_visit.g_flg_ehr_e, --
        pk_discharge_core.g_disch_status_cancel, --
        pk_discharge_core.g_disch_status_reopen, --
        l_limit;
    
        g_error := 'COMPARE LIMIT';
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        ELSIF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_from IS NOT NULL
        THEN
            l_order_by := 'position, ';
        END IF;
    
        l_sql := '
SELECT s.id_schedule,
       sg.id_patient,
       cr.num_clin_record,
       epis.id_episode,
       ''Y'' flg_active,
       pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) name,
       pk_patient.get_pat_name_to_sort(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
       pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) pat_nd_icon,
       (SELECT pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, :i_lang)
          FROM dual) gender,
       pk_patient.get_pat_age(:i_lang, pat.id_patient, :i_prof_institution, :i_prof_software) pat_age,
       pk_patphoto.get_pat_photo(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) photo,
pk_hea_prv_aux.get_clin_service(:i_lang, :i_prof, ei.id_dep_clin_serv) cons_type,
					
       pk_date_utils.date_char_hour_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software) hour_target,
       pk_date_utils.trunc_dt_char_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software) date_target,
       pk_date_utils.to_char_insttimezone(:i_prof_institution, :i_prof_software, sp.dt_target_tstz, ''YYYYMMDDHH24MISS'') dt_ord1,
       (SELECT pk_prof_utils.get_name_signature(:i_lang, :i_prof, p.id_professional)
          FROM dual) nick_name,
       sp.flg_state,
       :g_sysdate_char dt_server,
       (SELECT lpad(to_char(pk_sysdomain.get_rank(:i_lang, :g_schdl_outp_sched_domain, sp.flg_sched)), 6, ''0'') ||
               pk_sysdomain.get_img(:i_lang, :g_schdl_outp_sched_domain, sp.flg_sched)
          FROM dual) img_sched,
       pk_date_utils.date_char_hour_tsz(:i_lang, epis.dt_begin_tstz, :i_prof_institution, :i_prof_software) dt_efectiv,
       NULL desc_speciality,
       decode(drt.id_discharge_dest,
              NULL,
              decode(drt.id_dep_clin_serv,
                     NULL,
                     (SELECT pk_translation.get_translation(:i_lang, inst.code_institution)
                        FROM dual),
                     (SELECT pk_translation.get_translation(:i_lang, dep.code_department)
                        FROM dual) || '' - '' || (SELECT pk_translation.get_translation(:i_lang, cs2.code_clinical_service)
                                                    FROM dual)),
              (SELECT pk_translation.get_translation(:i_lang, ddn.code_discharge_dest)
                 FROM dual)) disch_dest
  FROM schedule_outp sp
  JOIN schedule s
    ON sp.id_schedule = s.id_schedule
  JOIN sch_group sg
    ON s.id_schedule = sg.id_schedule
  JOIN patient pat
    ON sg.id_patient = pat.id_patient
  JOIN clin_record cr
    ON pat.id_patient = cr.id_patient
  LEFT JOIN sch_prof_outp ps
    ON sp.id_schedule_outp = ps.id_schedule_outp
  LEFT JOIN epis_info ei
    ON s.id_schedule = ei.id_schedule
  LEFT JOIN episode epis
    ON ei.id_episode = epis.id_episode
   AND sg.id_patient = epis.id_patient
  LEFT JOIN clinical_service cs
    ON epis.id_cs_requested = cs.id_clinical_service
 ' || l_from || '
  LEFT JOIN professional p
    ON nvl(ei.id_professional, ps.id_professional) = p.id_professional
  LEFT JOIN discharge d
    ON epis.id_episode = d.id_episode
  LEFT JOIN disch_reas_dest drt
    ON d.id_disch_reas_dest = drt.id_disch_reas_dest
  LEFT JOIN institution inst
    ON drt.id_institution = inst.id_institution
  LEFT JOIN dep_clin_serv dcs2
    ON drt.id_dep_clin_serv = dcs2.id_dep_clin_serv
  LEFT JOIN department dep
    ON dcs2.id_department = dep.id_department
  LEFT JOIN clinical_service cs2
    ON dcs2.id_clinical_service = cs2.id_clinical_service
  LEFT JOIN discharge_dest ddn
    ON drt.id_discharge_dest = ddn.id_discharge_dest
 WHERE sp.id_software = :i_prof_software
   AND sp.dt_target_tstz BETWEEN :l_date_begin AND :l_date_end
   AND s.id_instit_requested = :i_prof_institution
   AND s.flg_status NOT IN (:g_sched_cancel, :g_sched_status_cache)
   AND cr.id_institution = :i_prof_institution
   AND cr.flg_status = :g_clin_active
   AND (epis.flg_status IS NULL OR epis.flg_status NOT IN (:g_epis_inactive, :g_epis_canc))
    AND epis.flg_ehr != :g_flg_ehr_e
   AND (d.flg_status IS NULL OR d.flg_status NOT IN (:g_disch_status_cancel, :g_disch_status_reopen))
 ' || l_where || '
   AND rownum <= :l_limit + 1
 ORDER BY ' || l_order_by || 'sp.dt_target_tstz';
    
        g_error := 'OPEN o_pat';
        OPEN o_pat FOR l_sql
            USING --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof,
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof, --
                  g_sysdate_char, --
                  i_lang, --
                  pk_grid_amb.g_schdl_outp_sched_domain, --
                  i_lang, --
                  pk_grid_amb.g_schdl_outp_sched_domain, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_prof.software, --
                  l_date_begin, --
                  l_date_end, --
                  i_prof.institution, --
                  g_sched_cancel, --
                  pk_schedule.g_sched_status_cache, --
                  i_prof.institution, --
                  g_clin_active, --
                  g_epis_inactive, --
                  g_epis_canc, --
                  pk_visit.g_flg_ehr_e, --
                  pk_discharge_core.g_disch_status_cancel, --
                  pk_discharge_core.g_disch_status_reopen, --
                  l_limit;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE', o_error);
        
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_pat);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
        WHEN invalid_number THEN
            pk_types.open_my_cursor(o_pat);
            RETURN pk_search.invalid_number_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE', o_error);
        
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_ACTIVE',
                                              'S',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_pat_criteria_active;

    /**********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados, para pessoal clínico (médicos e enfermeiros)
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category   
    * @param o_flg_show                
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_pat                    array with patient active
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emília Taborda
    * @version                        1.0 
    * @since                          2006/06/05
    *
    * @author                         Sérgio Santos (Restructure)
    * @version                        1.0 
    * @since                          2009/01/27
    **********************************************************************************************/
    FUNCTION get_pat_criteria_active_clin_o
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where VARCHAR2(4000);
    
        l_no_results EXCEPTION;
    BEGIN
    
        o_flg_show := 'N';
        g_sysdate  := SYSDATE;
        --
        --
        l_where := NULL;
        --
    
        IF (NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                    i_crit_val => i_crit_val,
                                    o_where    => l_where,
                                    i_lang     => i_lang,
                                    i_prof     => i_prof))
        THEN
            l_where := NULL;
        END IF;
        --
        g_error      := 'CONCAT CURSOR O_PAT';
        g_no_results := FALSE;
        g_overlimit  := FALSE;
        --
    
        --
        OPEN o_pat FOR --
            SELECT *
              FROM TABLE(tf_pat_criteria_active_clin(i_lang, i_prof, l_where));
    
        IF (g_no_results = TRUE)
        THEN
            RAISE pk_search.e_noresults;
        END IF;
        IF (g_overlimit = TRUE)
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
        
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_owner_name,
                                                  i_package  => g_package_name,
                                                  i_function => 'GET_PAT_CRITERIA_ACTIVE_CLIN',
                                                  o_error    => o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_pat);
                RETURN FALSE;
            END;
    END;

    FUNCTION tf_pat_criteria_active_clin
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2
    ) RETURN t_coll_patcritactiveclin_amb IS
    
        dataset        pk_types.cursor_type;
        l_limit        sys_config.desc_sys_config%TYPE;
        l_sysdate_char VARCHAR2(32);
        l_prof_cat     category.flg_type%TYPE;
    
        l_external_sys sys_config.value%TYPE;
        l_nurse_et     sys_config.value%TYPE;
        str_aux        VARCHAR2(255);
        l_profile      VARCHAR2(50);
    
        out_obj t_rec_patcritactiveclin_amb := t_rec_patcritactiveclin_amb(NULL,
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
                                                                           NULL,
                                                                           NULL,
                                                                           NULL,
                                                                           NULL,
                                                                           NULL,
                                                                           NULL,
                                                                           NULL);
    
        TYPE dataset_tt IS TABLE OF v_src_amb_active_clin_d%ROWTYPE INDEX BY PLS_INTEGER;
        l_dataset dataset_tt;
        l_row     PLS_INTEGER := 1;
    
        RESULT t_coll_patcritactiveclin_amb := t_coll_patcritactiveclin_amb();
    
        TYPE t_rec_translation IS RECORD(
            desc_translation pk_translation.t_desc_translation);
        TYPE t_tbl_translation IS TABLE OF t_rec_translation INDEX BY translation.code_translation%TYPE;
    
        translation_cache t_tbl_translation;
    
        -- Função que faz cache das chamadas à pk_translation.get_translation
        FUNCTION get_translation(code_translation translation.code_translation%TYPE)
            RETURN pk_translation.t_desc_translation IS
        
        BEGIN
            IF (NOT translation_cache.exists(code_translation))
            THEN
                translation_cache(code_translation).desc_translation := pk_translation.get_translation(i_lang,
                                                                                                       code_translation);
            END IF;
            RETURN translation_cache(code_translation).desc_translation;
        END;
    
        -- Função que faz cache das chamadas à pk_translation.get_translation_dtchk
        FUNCTION get_translation_dtchk(code_translation translation.code_translation%TYPE)
            RETURN pk_translation.t_desc_translation IS
        
        BEGIN
            IF (NOT translation_cache.exists(code_translation))
            THEN
                translation_cache(code_translation).desc_translation := pk_translation.get_translation_dtchk(i_lang,
                                                                                                             code_translation);
            END IF;
            RETURN translation_cache(code_translation).desc_translation;
        END;
    
    BEGIN
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        l_prof_cat     := pk_prof_utils.get_category(i_lang, i_prof);
        --
        l_external_sys := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
        l_nurse_et     := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof.institution, i_prof.software);
        --
        g_error := 'GET LIMIT';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('id_ext_sys', l_external_sys);
        pk_context_api.set_parameter('id_nurse_et', l_nurse_et);
        pk_context_api.set_parameter('g_epis_active', g_epis_active);
        --
        SELECT cat.flg_type
          INTO l_profile
          FROM category cat, prof_cat pct
         WHERE cat.id_category = pct.id_category
           AND pct.id_professional = i_prof.id
           AND pct.id_institution = i_prof.institution;
        --
        g_error := 'OPEN CURSOR';
    
        /*IF l_prof_cat = g_flg_doctor
        THEN
            str_aux := ' AND T.ID_PROFESSIONAL(+) = ' || i_prof.id;
        ELSIF l_prof_cat = g_flg_nurse
        THEN
            str_aux := ' AND EXISTS (SELECT 1 FROM PROF_DEP_CLIN_SERV PDCS WHERE PDCS.ID_PROFESSIONAL = ' || i_prof.id ||
                       ' AND PDCS.ID_DEP_CLIN_SERV = T.ID_DEP_CLIN_SERV AND PDCS.FLG_STATUS = ''' || g_selected ||
                       ''')';
        END IF;
        
        OPEN dataset FOR 'SELECT * FROM V_PAT_CRIT_ACTIVE_CLIN_AMB t WHERE rownum <= :limit + 1 ' || str_aux || i_where || ' ' || 'ORDER BY t.dt_target_tstz'
            USING l_limit;*/
    
        IF l_prof_cat = g_flg_doctor
        THEN
            dbms_output.put_line('SELECT * FROM V_PAT_CRIT_ACTIVE_CLIN_AMB_D t WHERE rownum <= :limit + 1 ' || i_where || ' ' ||
                                 'ORDER BY t.dt_target_tstz');
            OPEN dataset FOR 'SELECT * FROM V_PAT_CRIT_ACTIVE_CLIN_AMB_D t WHERE rownum <= :limit + 1 ' || i_where || ' ' || 'ORDER BY t.dt_target_tstz'
                USING l_limit;ELSIF l_prof_cat = g_flg_nurse
        THEN
            dbms_output.put_line('SELECT * FROM V_PAT_CRIT_ACTIVE_CLIN_AMB_N t WHERE rownum <= :limit + 1 ' ||
                                 i_where || ' ' || 'ORDER BY t.dt_target_tstz');
            OPEN dataset FOR 'SELECT * FROM V_PAT_CRIT_ACTIVE_CLIN_AMB_N t WHERE rownum <= :limit + 1 ' || i_where || ' ' || 'ORDER BY t.dt_target_tstz'
                USING l_limit;
        END IF;
    
        g_error := 'FETCH FROM RESULTS CURSOR';
        FETCH dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        CLOSE dataset;
    
        g_error := 'COUNT RESULTS';
        IF l_dataset.count > l_limit
        THEN
            g_overlimit := TRUE;
            RETURN RESULT;
        ELSE
            IF (l_dataset.count = 0)
            THEN
                g_no_results := TRUE;
            END IF;
        END IF;
    
        g_error := 'EXTEND RESULT ARRAY';
        IF l_dataset.count < l_limit
        THEN
            result.extend(l_dataset.count);
        ELSE
            result.extend(l_limit);
        END IF;
    
        l_row := l_dataset.first;
    
        g_error := 'GET DATA';
        WHILE (l_row <= result.count)
        LOOP
            out_obj.id_schedule     := l_dataset(l_row).id_schedule;
            out_obj.id_patient      := l_dataset(l_row).id_patient;
            out_obj.num_clin_record := l_dataset(l_row).num_clin_record;
            out_obj.id_episode      := l_dataset(l_row).id_episode;
            out_obj.name            := pk_patient.get_pat_name(i_lang,
                                                               i_prof,
                                                               l_dataset(l_row).id_patient,
                                                               l_dataset(l_row).id_episode,
                                                               l_dataset(l_row).id_schedule);
            out_obj.pat_ndo         := pk_adt.get_pat_non_disc_options(i_lang, i_prof, l_dataset(l_row).id_patient);
            out_obj.pat_nd_icon     := pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, l_dataset(l_row).id_patient);
            -- cached
            out_obj.gender  := pk_patient.get_gender(i_lang, l_dataset(l_row).gender);
            out_obj.pat_age := pk_patient.get_pat_age(i_lang,
                                                      l_dataset         (l_row).dt_birth,
                                                      l_dataset         (l_row).age,
                                                      i_prof.institution,
                                                      i_prof.software);
            out_obj.photo   := pk_patphoto.get_pat_photo(i_lang,
                                                         i_prof,
                                                         l_dataset(l_row).id_patient,
                                                         l_dataset(l_row).id_episode,
                                                         l_dataset(l_row).id_schedule);
        
            out_obj.cons_type         := CASE l_dataset(l_row).code_clinical_service
                                             WHEN NULL THEN
                                              NULL
                                             ELSE
                                              pk_translation.get_translation(i_lang,
                                                                             l_dataset(l_row).code_clinical_service)
                                         END;
            out_obj.hour_target       := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                          l_dataset(l_row).dt_target_tstz,
                                                                          i_prof.institution,
                                                                          i_prof.software);
            out_obj.date_target       := pk_date_utils.trunc_dt_char_tsz(i_lang,
                                                                         l_dataset(l_row).dt_target_tstz,
                                                                         i_prof.institution,
                                                                         i_prof.software);
            out_obj.nick_name         := l_dataset(l_row).nick_name;
            out_obj.flg_state         := l_dataset(l_row).flg_state;
            out_obj.dt_server         := l_sysdate_char;
            out_obj.img_sched         := lpad(to_char(l_dataset(l_row).rank), 6, '0') || l_dataset(l_row).img_name;
            out_obj.dt_efectiv        := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                          l_dataset(l_row).dt_begin_tstz,
                                                                          i_prof.institution,
                                                                          i_prof.software);
            out_obj.desc_speciality   := CASE nvl(l_dataset(l_row).code_speciality1, l_dataset(l_row).code_speciality)
                                             WHEN NULL THEN
                                              NULL
                                             ELSE
                                              pk_translation.get_translation(i_lang,
                                                                             nvl(l_dataset(l_row).code_speciality1,
                                                                                 l_dataset(l_row).code_speciality))
                                         END;
            out_obj.disch_dest        := CASE l_dataset(l_row).id_discharge_dest
                                             WHEN '' THEN
                                              (CASE l_dataset(l_row).id_dep_clin_serv
                                                  WHEN '' THEN
                                                   (CASE l_dataset(l_row).id_institution_drt
                                                       WHEN '' THEN
                                                        ''
                                                       ELSE
                                                        (CASE l_dataset(l_row).code_institution
                                                            WHEN NULL THEN
                                                             NULL
                                                            ELSE
                                                             pk_translation.get_translation(i_lang,
                                                                                            l_dataset(l_row).code_institution)
                                                        END)
                                                   END)
                                                  ELSE
                                                   ((CASE l_dataset(l_row).code_department
                                                       WHEN NULL THEN
                                                        NULL
                                                       ELSE
                                                        pk_translation.get_translation(i_lang,
                                                                                       l_dataset(l_row).code_department)
                                                   END) || ' - ' || (CASE l_dataset(l_row).code_clinical_service2
                                                       WHEN NULL THEN
                                                        NULL
                                                       ELSE
                                                        pk_translation.get_translation(i_lang,
                                                                                       l_dataset(l_row).code_clinical_service2)
                                                   END))
                                              END)
                                             ELSE
                                              (CASE l_dataset(l_row).code_discharge_dest
                                                  WHEN NULL THEN
                                                   NULL
                                                  ELSE
                                                   pk_translation.get_translation(i_lang,
                                                                                  l_dataset(l_row).code_discharge_dest)
                                              END)
                                         END;
            out_obj.desc_drug_presc   := pk_grid.convert_grid_task_str(i_lang, i_prof, l_dataset(l_row).drug_presc);
            out_obj.desc_interv_presc := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                i_prof,
                                                                                l_dataset(l_row).intervention);
            out_obj.desc_analysis_req := pk_grid.visit_grid_task_str(i_lang,
                                                                     i_prof,
                                                                     l_dataset(l_row).id_visit,
                                                                     g_task_analysis,
                                                                     l_profile);
            out_obj.desc_exam_req     := pk_grid.visit_grid_task_str(i_lang,
                                                                     i_prof,
                                                                     l_dataset(l_row).id_visit,
                                                                     g_task_exam,
                                                                     l_profile);
            out_obj.dt_ord1           := pk_date_utils.to_char_insttimezone(i_prof.institution,
                                                                            i_prof.software,
                                                                            l_dataset(l_row).dt_target_tstz,
                                                                            'YYYYMMDDHH24MISS');
        
            RESULT(l_row) := out_obj;
        
            l_row := l_row + 1;
        END LOOP;
    
        RETURN(RESULT);
    
    END tf_pat_criteria_active_clin;

    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE DOENTES ACTIVOS, DE ACORDO COM OS CRITÉRIOS SELECCIONADOS , PARA PESSOAL
                            CLÍNICO (MÉDICOS E ENFERMEIROS) 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                   I_ID_SYS_BTN_CRIT - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
                   I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA              
                 I_INSTIT - INSTITUIÇÃO 
                 I_EPIS_TYPE - TIPO DE CONSULTA
                 I_DT - DATA A PESQUISAR. SE FOR NULL ASSUME A DATA DE SISTEMA
                   I_PROF - PROFISSIONAL Q REGISTA 
                 I_PROF_CAT_TYPE - TIPO DE CATEGORIA DO PROFISSIONAL, TAL 
                       COMO É RETORNADA EM PK_LOGIN.GET_PROF_PREF 
                  SAIDA: O_PAT - DOENTES 
                 O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
                 O_ERROR - ERRO 
          
          CRIAÇÃO: RB 2005/04/22 
          ALTERAÇÃO: CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS
             RDSN 2006/12/18 CORRECÇÃO DE ERRO NA COLOCAÇÃO DO PARENTESIS E DAS PLICAS NO STR_AUX
                 ASM 2006/12/27 LIGAÇÃO À TABELA DOC_EXTERNAL PARA OS DOCUMENTOS, EM VEZ DA PAT_DOC
                 FO 2008/05/30 VERIFICAÇÃO DOS TIPOS DE EPISÓDIOS VISÍVEIS PELO PROFISSIONAL E ICON DE CONSULTA DE ENFERMAGEM INSERIDO
          
          NOTAS:  
        *********************************************************************************/
        l_from                 VARCHAR2(32767);
        l_where                VARCHAR2(32767);
        l_hint                 criteria.hint_condition%TYPE;
        l_order_by             VARCHAR2(12 CHAR);
        l_count                NUMBER;
        l_limit                sys_config.value%TYPE;
        l_sql                  VARCHAR2(32767);
        l_date                 TIMESTAMP WITH LOCAL TIME ZONE;
        l_nurse_et             sys_config.value%TYPE;
        l_prof_cat             category.flg_type%TYPE;
        l_et_access            table_number := table_number();
        l_handoff_type         sys_config.value%TYPE;
        l_episode_access       sys_config.value%TYPE;
        l_appointment_type     VARCHAR2(1 CHAR);
        l_type_encounter_label pk_translation.t_desc_translation;
    
        l_epis_status_to_exclude table_varchar := table_varchar(g_epis_inactive, g_epis_canc);
    
    BEGIN
    
        g_error        := 'BEGIN';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        o_flg_show     := 'N';
    
        l_limit          := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_episode_access := pk_sysconfig.get_config('DOCTOR_NURSE_APPOINTMENT_ACCESS', i_prof);
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        g_error := 'GET l_date';
        IF i_dt_str IS NULL
        THEN
            l_date := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz);
        ELSE
            l_date := pk_date_utils.trunc_insttimezone(i_prof,
                                                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_str, NULL));
        
        END IF;
    
        set_context_parameters(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'CALL get_from_and_where';
        IF NOT get_from_and_where(i_lang     => i_lang,
                                  i_prof     => i_prof,
                                  i_crit_id  => i_id_sys_btn_crit,
                                  i_crit_val => i_crit_val,
                                  o_from     => l_from,
                                  o_hint     => l_hint,
                                  o_where    => l_where,
                                  o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- in the paramedical profiles when searching for follow ups it is necessary to search 
        -- for all kind of epis types with follow ups
        l_appointment_type := sys_context('ALERT_CONTEXT', 'SEARCH_P246');
        IF l_appointment_type = 'F'
        THEN
            g_error := 'Get all epis types list';
            SELECT e.id_epis_type
              BULK COLLECT
              INTO l_et_access
              FROM epis_type e
             WHERE e.id_epis_type > 0;
        
            l_epis_status_to_exclude := table_varchar(g_epis_canc);
        
        ELSE
            g_error     := 'CALL get_epis_type_access';
            l_et_access := get_epis_type_access(i_prof => i_prof, i_grp_inst => table_number(i_prof.institution));
        END IF;
    
        IF l_appointment_type IS NOT NULL
        THEN
            l_type_encounter_label := pk_sysdomain.get_domain(i_code_dom => 'TYPE_OF_ENCOUNTER',
                                                              i_val      => l_appointment_type,
                                                              i_lang     => i_lang);
        END IF;
    
        l_nurse_et := nvl(pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof.institution, i_prof.software), -2);
    
        g_error := 'GET COUNT';
        l_sql   := '
SELECT COUNT(1)
  FROM epis_info ei
  JOIN episode epis
    ON ei.id_episode = epis.id_episode
  LEFT JOIN clinical_service cs
    ON (epis.id_cs_requested = cs.id_clinical_service)
  LEFT JOIN clinical_service cs2
    ON epis.id_clinical_service = cs2.id_clinical_service
  JOIN patient pat
    ON epis.id_patient = pat.id_patient
  JOIN clin_record cr
    ON pat.id_patient = cr.id_patient
  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
         t.column_value id_epis_type
          FROM TABLE(:l_et_access) t) eta
    ON epis.id_epis_type = eta.id_epis_type
    OR eta.id_epis_type = 0
 ' || l_from || '
  LEFT JOIN professional p
    ON ei.id_professional = p.id_professional
  LEFT JOIN discharge d
    ON epis.id_episode = d.id_episode
  LEFT JOIN schedule s
    ON ei.id_schedule = s.id_schedule
   AND ei.id_schedule > 0
  LEFT JOIN schedule_outp sp
    ON s.id_schedule = sp.id_schedule
  LEFT JOIN sch_prof_outp spo
    ON spo.id_schedule_outp = sp.id_schedule_outp
  LEFT JOIN sch_group sg
    ON s.id_schedule = sg.id_schedule
   AND epis.id_patient = sg.id_patient
 WHERE (ei.id_software = :i_prof_software OR :i_prof_software = :g_soft_nutritionist OR :i_prof_software = :g_soft_social OR :i_prof_software = :g_soft_psychologist OR :i_prof_software = :g_soft_resptherap)
   AND epis.id_institution = :i_prof_institution
   AND epis.flg_status NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
         t.column_value flg_status
          FROM TABLE(:l_epis_status_to_exclude) t)
   AND epis.flg_ehr = :g_flg_ehr_n
   AND epis.id_epis_type NOT IN (:g_epis_type_rad, :g_epis_type_exm, :g_epis_type_lab, :g_epis_type_interv)
   AND cr.id_institution = :i_prof_institution
   AND cr.flg_status = :g_clin_active
   AND (d.flg_status IS NULL OR d.flg_status NOT IN (:g_disch_status_cancel, :g_disch_status_reopen))
   AND (s.flg_status IS NULL OR s.flg_status NOT IN (:g_sched_cancel, :g_sched_status_cache))
   AND ((epis.id_epis_type = :g_epis_nurse and :g_flg_access = :g_yes) OR epis.id_epis_type <> :g_epis_nurse )  
   AND ((sp.dt_target_tstz BETWEEN :l_date AND :l_date + INTERVAL ''1'' DAY) OR
       (sp.dt_target_tstz IS NULL AND epis.dt_begin_tstz IS NOT NULL))
 ' || l_where || '
   AND rownum <= :l_limit + 1';
    
        g_error := 'EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE l_sql
            INTO l_count
            USING --
        l_et_access, --
        i_prof.software, --
        i_prof.software, --
        pk_alert_constant.g_soft_nutritionist, --
        i_prof.software, pk_alert_constant.g_soft_social, --
        i_prof.software, pk_alert_constant.g_soft_psychologist, --
        i_prof.software, pk_alert_constant.g_soft_resptherap, i_prof.institution, --
        l_epis_status_to_exclude, --
        pk_visit.g_flg_ehr_n, --
        g_epis_type_rad, --
        g_epis_type_exm, --
        g_epis_type_lab, --
        g_epis_type_interv, --
        i_prof.institution, --
        g_clin_active, --
        pk_discharge_core.g_disch_status_cancel, --
        pk_discharge_core.g_disch_status_reopen, --
        g_sched_cancel, --
        pk_schedule.g_sched_status_cache, --
        l_nurse_et, l_episode_access, pk_alert_constant.g_yes, l_nurse_et, l_date, --
        l_date, --
        l_limit;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        ELSIF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        l_prof_cat := pk_tools.get_prof_cat(i_prof => i_prof);
    
        IF l_from IS NOT NULL
        THEN
            l_order_by := 'position, ';
        END IF;
    
        l_sql := '
SELECT s.id_schedule,
       pat.id_patient,
       cr.num_clin_record,
       epis.id_episode,
       pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) name,
       pk_patient.get_pat_name_to_sort(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
       pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) pat_nd_icon,
       pk_hand_off_api.get_resp_icons(:i_lang, :i_prof, epis.id_episode, :l_handoff_type) resp_icon,
       pk_patient.get_gender(:i_lang, pat.gender) gender,
       (SELECT pk_patient.get_pat_age(:i_lang, pat.dt_birth, pat.age, :i_prof_institution, :i_prof_software)
          FROM dual) pat_age,
       pk_patphoto.get_pat_photo(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) photo,
       nvl(:l_type_encounter_label, pk_hea_prv_aux.get_clin_service(:i_lang, :i_prof, ei.id_dep_clin_serv)) cons_type,          
       (SELECT pk_date_utils.date_char_hour_tsz(:i_lang,
                                                nvl(sp.dt_target_tstz, epis.dt_begin_tstz),
                                                :i_prof_institution,
                                                :i_prof_software)
          FROM dual) hour_target,
       (SELECT pk_date_utils.trunc_dt_char_tsz(:i_lang,
                                               nvl(sp.dt_target_tstz, epis.dt_begin_tstz),
                                               :i_prof_institution,
                                               :i_prof_software)
          FROM dual) date_target,
       (SELECT pk_prof_utils.get_name_signature(:i_lang, :i_prof, p.id_professional)
          FROM dual) nick_name,  
       (SELECT pk_grid_amb.get_responsibles_str(:i_lang,
                                                :i_prof,
                                                :g_cat_type_doc,
                                                ei.id_episode, 
                                                nvl(ei.id_professional, spo.id_professional), 
                                                :l_handoff_type, 
                                                ''G'') 
           FROM dual) name_prof,
        (SELECT pk_prof_utils.get_nickname(:i_lang, ei.id_first_nurse_resp) 
           FROM dual) name_nurse,
        (SELECT pk_grid_amb.get_responsibles_str(:i_lang,
                                                 :i_prof, 
                                                 :g_cat_type_doc, 
                                                 ei.id_episode, 
                                                 nvl(ei.id_professional, spo.id_professional), 
                                                 :l_handoff_type, 
                                                 ''T'') 
           FROM dual) name_prof_tooltip,
        (SELECT pk_grid_amb.get_responsibles_str(:i_lang, 
                                                 :i_prof, 
                                                 :g_cat_type_nurse,
                                                 ei.id_episode, 
                                                 ei.id_first_nurse_resp, 
                                                 :l_handoff_type, 
                                                 ''T'') 
           FROM dual) name_nurse_tooltip, 
       sp.flg_state,
       :g_sysdate_char dt_server,
       (SELECT decode(epis.id_epis_type,
                      :l_et_nurse,
                      lpad(to_char(pk_sysdomain.get_rank(:i_lang, :i_code_dom, :i_val)), 6, ''0'') ||
                      pk_sysdomain.get_img(:i_lang, :i_code_dom, :i_val),
                      lpad(to_char(pk_sysdomain.get_rank(:i_lang, :i_code_dom, nvl(sp.flg_sched, ''M''))), 6, ''0'') ||
                      pk_sysdomain.get_img(:i_lang, :i_code_dom, nvl(sp.flg_sched, ''M'')))
          FROM dual) img_sched,
       pk_date_utils.date_char_hour_tsz(:i_lang, epis.dt_begin_tstz, :i_prof_institution, :i_prof_software) dt_efectiv,
       pk_prof_utils.get_spec_signature(:i_lang, :i_prof, ei.id_professional, epis.dt_begin_tstz, ei.id_episode) desc_speciality,
       decode(drt.id_discharge_dest,
              NULL,
              decode(drt.id_dep_clin_serv,
                     NULL,
                     (SELECT pk_translation.get_translation(:i_lang, inst.code_institution)
                        FROM dual),
                     (SELECT pk_translation.get_translation(:i_lang, dep.code_department)
                        FROM dual) || '' - '' || (SELECT pk_translation.get_translation(:i_lang, cs2.code_clinical_service)
                                                    FROM dual)),
              (SELECT pk_translation.get_translation(:i_lang, ddn.code_discharge_dest)
                 FROM dual)) disch_dest,
       (SELECT pk_grid.convert_grid_task_dates_to_str(:i_lang, :i_prof, gt.drug_presc)
          FROM dual) desc_drug_presc,
       (SELECT pk_grid.convert_grid_task_dates_to_str(:i_lang,:i_prof,
              pk_grid.get_prioritary_task(:i_lang,:i_prof,gt.icnp_intervention,
                       pk_grid.get_prioritary_task(:i_lang,:i_prof,gt.nurse_activity,
                            pk_grid.get_prioritary_task(:i_lang,:i_prof,
                                        pk_grid.get_prioritary_task(:i_lang,:i_prof,gt.intervention,gt.monitorization,NULL,:g_flg_doctor),
                                        gt.teach_req,
                                        NULL,
                                        :g_flg_doctor),
                                     NULL,
                                     :g_flg_doctor),
                                     NULL,
                                     :g_flg_doctor))   
           FROM dual ) desc_interv_presc,        
       pk_grid.visit_grid_task_str(:i_lang, :i_prof, epis.id_visit, :g_task_analysis, :l_prof_cat) desc_analysis_req,
       pk_grid.visit_grid_task_str(:i_lang, :i_prof, epis.id_visit, :g_task_exam, :l_prof_cat) desc_exam_req,
       (SELECT pk_date_utils.to_char_insttimezone(:i_prof_institution,
                                                  :i_prof_software,
                                                  nvl(sp.dt_target_tstz, epis.dt_begin_tstz),
                                                  ''YYYYMMDDHH24MISS'')
          FROM dual) dt_ord1,
          decode(:i_prof_software, 312, decode(epis.id_epis_type, 50, pk_hhc_core.get_id_hhc_req_by_epis(epis.id_episode))) id_epis_hhc_req
  FROM epis_info ei
  JOIN episode epis
    ON ei.id_episode = epis.id_episode
  LEFT JOIN clinical_service cs
    ON (epis.id_cs_requested = cs.id_clinical_service)
  LEFT JOIN clinical_service cs2
    ON epis.id_clinical_service = cs2.id_clinical_service
  JOIN patient pat
    ON epis.id_patient = pat.id_patient
  JOIN clin_record cr
    ON pat.id_patient = cr.id_patient
  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
         t.column_value id_epis_type
          FROM TABLE(:l_et_access) t) eta
    ON epis.id_epis_type = eta.id_epis_type
    OR eta.id_epis_type = 0
 ' || l_from || '
  LEFT JOIN professional p
    ON ei.id_professional = p.id_professional
  LEFT JOIN discharge d
    ON epis.id_episode = d.id_episode
  LEFT JOIN schedule s
    ON ei.id_schedule = s.id_schedule
   AND ei.id_schedule > 0
  LEFT JOIN schedule_outp sp
    ON s.id_schedule = sp.id_schedule
  LEFT JOIN sch_prof_outp spo
    ON spo.id_schedule_outp = sp.id_schedule_outp
  LEFT JOIN sch_group sg
    ON s.id_schedule = sg.id_schedule
   AND epis.id_patient = sg.id_patient
  LEFT JOIN disch_reas_dest drt
    ON d.id_disch_reas_dest = drt.id_disch_reas_dest
  LEFT JOIN institution inst
    ON drt.id_institution = inst.id_institution
  LEFT JOIN dep_clin_serv dcs2
    ON drt.id_dep_clin_serv = dcs2.id_dep_clin_serv
  LEFT JOIN department dep
    ON dcs2.id_department = dep.id_department
  LEFT JOIN clinical_service cs2
    ON dcs2.id_clinical_service = cs2.id_clinical_service
  LEFT JOIN discharge_dest ddn
    ON drt.id_discharge_dest = ddn.id_discharge_dest
  LEFT JOIN grid_task gt
    ON epis.id_episode = gt.id_episode
 WHERE (ei.id_software = :i_prof_software OR :i_prof_software = :g_soft_nutritionist OR :i_prof_software = :g_soft_social OR :i_prof_software = :g_soft_psychologist OR :i_prof_software = :g_soft_resptherap)
   AND epis.id_institution = :i_prof_institution
   AND epis.flg_status NOT IN (SELECT /*+opt_estimate(table t rows=1)*/
         t.column_value flg_status
          FROM TABLE(:l_epis_status_to_exclude) t)
   AND epis.flg_ehr = :g_flg_ehr_n
   AND epis.id_epis_type NOT IN (:g_epis_type_rad, :g_epis_type_exm, :g_epis_type_lab, :g_epis_type_interv)
   AND cr.id_institution = :i_prof_institution
   AND cr.flg_status = :g_clin_active
   AND (d.flg_status IS NULL OR d.flg_status NOT IN (:g_disch_status_cancel, :g_disch_status_reopen))
   AND (s.flg_status IS NULL OR s.flg_status NOT IN (:g_sched_cancel, :g_sched_status_cache))
   AND ((epis.id_epis_type = :g_epis_nurse and :g_flg_access = :g_yes) OR epis.id_epis_type <> :g_epis_nurse )  
   AND ((sp.dt_target_tstz BETWEEN :l_date AND :l_date + INTERVAL ''1'' DAY) OR
       (sp.dt_target_tstz IS NULL AND epis.dt_begin_tstz IS NOT NULL))
 ' || l_where || '
   AND rownum <= :l_limit
 ORDER BY ' || l_order_by || 'nvl(sp.dt_target_tstz, epis.dt_begin_tstz)';
    
        --pk_alertlog.log_error(l_sql);
    
        g_error := 'OPEN o_pat';
        OPEN o_pat FOR l_sql
            USING --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  l_handoff_type, --
                  i_lang, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof, --
                  l_type_encounter_label,
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  pk_alert_constant.g_cat_type_doc, --
                  l_handoff_type, --
                  i_lang, --
                  i_lang, --
                  i_prof, --
                  pk_alert_constant.g_cat_type_doc, --
                  l_handoff_type, --
                  i_lang, --
                  i_prof, --
                  pk_alert_constant.g_cat_type_nurse, --
                  l_handoff_type, --
                  g_sysdate_char, --
                  l_nurse_et, --
                  i_lang, --
                  pk_grid_amb.g_schdl_nurse_state_domain, --
                  pk_grid_amb.g_sched_nurse, --
                  i_lang, --
                  pk_grid_amb.g_schdl_nurse_state_domain, --
                  pk_grid_amb.g_sched_nurse, --
                  i_lang, --
                  pk_grid_amb.g_schdl_outp_sched_domain, --
                  i_lang, --
                  pk_grid_amb.g_schdl_outp_sched_domain, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_prof, --
                  i_lang, -- desc_interv_presc
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  g_flg_doctor, --
                  g_flg_doctor, --
                  g_flg_doctor, --
                  g_flg_doctor, --
                  i_lang, --
                  i_prof, --
                  g_task_analysis, --
                  l_prof_cat, --
                  i_lang, --
                  i_prof, --
                  g_task_exam, --
                  l_prof_cat, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_prof.software, --
                  l_et_access, -- BIND FROM 
                  i_prof.software, --
                  i_prof.software,
                  pk_alert_constant.g_soft_nutritionist, --
                  i_prof.software,
                  pk_alert_constant.g_soft_social,
                  i_prof.software,
                  pk_alert_constant.g_soft_psychologist,
                  i_prof.software,
                  pk_alert_constant.g_soft_resptherap,
                  i_prof.institution, --
                  l_epis_status_to_exclude, --
                  pk_visit.g_flg_ehr_n, --
                  g_epis_type_rad, --
                  g_epis_type_exm, --
                  g_epis_type_lab, --
                  g_epis_type_interv, --
                  i_prof.institution, --
                  g_clin_active, --
                  pk_discharge_core.g_disch_status_cancel, --
                  pk_discharge_core.g_disch_status_reopen, --
                  g_sched_cancel, --
                  pk_schedule.g_sched_status_cache, --
                  l_nurse_et,
                  l_episode_access,
                  pk_alert_constant.g_yes,
                  l_nurse_et,
                  l_date, --
                  l_date, --
                  l_limit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
        
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
        WHEN invalid_number THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.invalid_number_handler(i_lang,
                                                    i_prof,
                                                    g_package_name,
                                                    'GET_PAT_CRITERIA_ACTIVE_CLIN',
                                                    o_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PAT_CRITERIA_ACTIVE_CLIN',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_criteria_active_clin;

    FUNCTION get_pat_criteria_inactive
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE DOENTES INACTIVOS, DE ACORDO COM OS CRITÉRIOS SELECCIONADOS 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                   I_ID_SYS_BTN_CRIT - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
                   I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA
                 I_INSTIT - INSTITUIÇÃO 
                   I_PROF - PROFISSIONAL 
                 I_PROF_CAT_TYPE - TIPO DE CATEGORIA DO PROFISSIONAL, TAL 
                       COMO É RETORNADA EM PK_LOGIN.GET_PROF_PREF 
                  SAIDA: O_PAT - DOENTES 
                 O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
                 O_ERROR - ERRO 
          
          CRIAÇÃO: RB 2005/04/22 
          
          NOTAS: 
        *********************************************************************************/
        l_where     VARCHAR2(32767);
        l_from      VARCHAR2(32767);
        l_hint      criteria.hint_condition%TYPE;
        l_order_by  VARCHAR2(12 CHAR);
        l_date      TIMESTAMP WITH LOCAL TIME ZONE;
        l_count     NUMBER;
        l_limit     sys_config.value%TYPE;
        l_sql       VARCHAR2(32767);
        l_grp_insts table_number;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        o_flg_show     := 'N';
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        --OBTER DATA DO SISTEMA PARA MOSTRAR APENAS EPISÓDIOS INACTIVOS FECHADOS HOJE 
        g_error := 'GET l_date';
        IF i_dt_str IS NULL
        THEN
            l_date := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz + INTERVAL '1' DAY);
        
        ELSE
            l_date := pk_date_utils.trunc_insttimezone(i_prof,
                                                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_str, NULL) +
                                                       INTERVAL '1' DAY);
        END IF;
    
        set_context_parameters(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'CALL get_from_and_where';
        IF NOT get_from_and_where(i_lang     => i_lang,
                                  i_prof     => i_prof,
                                  i_crit_id  => i_id_sys_btn_crit,
                                  i_crit_val => i_crit_val,
                                  o_from     => l_from,
                                  o_hint     => l_hint,
                                  o_where    => l_where,
                                  o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error     := 'GET INSTs GRP';
        l_grp_insts := pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt);
    
        g_error := 'GET COUNT';
        l_sql   := '
SELECT COUNT(sp.id_schedule)
  FROM schedule_outp sp
  JOIN schedule s
    ON sp.id_schedule = s.id_schedule
  JOIN sch_group sg
    ON sp.id_schedule = sg.id_schedule
  JOIN patient pat
    ON sg.id_patient = pat.id_patient
  JOIN clin_record cr
    ON pat.id_patient = cr.id_patient
  JOIN epis_info ei
    ON sp.id_schedule = ei.id_schedule
  JOIN episode epis
    ON ei.id_episode = epis.id_episode
   AND sg.id_patient = epis.id_patient
  JOIN clinical_service cs
    ON epis.id_cs_requested = cs.id_clinical_service
 ' || l_from || '
  LEFT JOIN professional p
    ON ei.id_professional = p.id_professional
  LEFT JOIN discharge d
    ON epis.id_episode = d.id_episode
   AND d.dt_cancel_tstz IS NULL
 WHERE sp.id_software IN (:i_prof_software, :g_soft_nutritionist)
   AND sp.dt_target_tstz <= :l_date
   AND s.id_instit_requested = :i_prof_institution
   AND cr.flg_status = :g_clin_active
   AND cr.id_institution = :i_prof_institution
   AND epis.flg_status NOT IN (:g_epis_active, :g_epis_canc)
   AND epis.flg_ehr != :g_flg_ehr_e
 ' || l_where || '
   AND rownum <= :l_limit + 1';
    
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE l_sql
            INTO l_count
            USING --
        i_prof.software, --
        pk_alert_constant.g_soft_nutritionist, --
        l_date, --
        i_prof.institution, --
        g_clin_active, --
        i_prof.institution, --
        g_epis_active, --
        g_epis_canc, --
        pk_visit.g_flg_ehr_e, --
        l_limit;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        ELSIF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_from IS NOT NULL
        THEN
            l_order_by := 'position, ';
        END IF;
    
        l_sql := '
SELECT s.id_schedule,
       sg.id_patient,
       cr.num_clin_record,
       pk_prof_utils.get_name_signature(:i_lang, :i_prof, ei.id_professional) nick_name,
       ei.id_episode,
       pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) name,
       pk_patient.get_pat_name_to_sort(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
       pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) pat_nd_icon,
       pk_patient.get_gender(:i_lang, pat.gender) gender,
       (SELECT pk_patient.get_pat_age(:i_lang, pat.dt_birth, pat.age, :i_prof_institution, :i_prof_software)
          FROM dual) pat_age,
       pk_patphoto.get_pat_photo(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) photo,
			 pk_hea_prv_aux.get_clin_service(:i_lang, :i_prof, ei.id_dep_clin_serv) cons_type,
       decode(pk_date_utils.trunc_insttimezone(:i_prof_institution, :i_prof_software, sp.dt_target_tstz, NULL),
              (SELECT pk_date_utils.trunc_insttimezone(:i_prof_institution, :i_prof_software, current_timestamp, NULL)
                 FROM dual),
              (SELECT pk_date_utils.date_char_hour_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software)
                 FROM dual),
              NULL) hour_target,
       (SELECT pk_date_utils.trunc_dt_char_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software)
          FROM dual) date_target,
       (SELECT lpad(to_char(pk_sysdomain.get_rank(:i_lang, :i_code_dom, sp.flg_sched)), 6, ''0'') ||
               pk_sysdomain.get_img(:i_lang, :i_code_dom, sp.flg_sched)
          FROM dual) img_sched,
				:g_sysdate_char dt_server,
       decode(drt.id_discharge_dest,
              NULL,
              decode(drt.id_dep_clin_serv,
                     NULL,
                     (SELECT pk_translation.get_translation(:i_lang, inst.code_institution)
                        FROM dual),
                     (SELECT pk_translation.get_translation(:i_lang, dep.code_department)
                        FROM dual) || '' - '' || (SELECT pk_translation.get_translation(:i_lang, cs2.code_clinical_service)
                                                    FROM dual)),
              (SELECT pk_translation.get_translation(:i_lang, ddn.code_discharge_dest)
                 FROM dual)) disch_dest,
       (SELECT pk_date_utils.to_char_insttimezone(:i_prof_institution,
                                                  :i_prof_software,
                                                  sp.dt_target_tstz,
                                                  ''YYYYMMDDHH24MISS'')
          FROM dual) dt_ord1
  FROM schedule_outp sp
  JOIN schedule s
    ON sp.id_schedule = s.id_schedule
  JOIN sch_group sg
    ON s.id_schedule = sg.id_schedule
  JOIN patient pat
    ON sg.id_patient = pat.id_patient
  JOIN clin_record cr
    ON pat.id_patient = cr.id_patient
  JOIN epis_info ei
    ON s.id_schedule = ei.id_schedule
  JOIN episode epis
    ON ei.id_episode = epis.id_episode
   AND sg.id_patient = epis.id_patient
  JOIN clinical_service cs
    ON epis.id_cs_requested = cs.id_clinical_service
 ' || l_from || '
  LEFT JOIN professional p
    ON ei.id_professional = p.id_professional
  LEFT JOIN discharge d
    ON epis.id_episode = d.id_episode
   AND d.dt_cancel_tstz IS NULL
  LEFT JOIN disch_reas_dest drt
    ON d.id_disch_reas_dest = drt.id_disch_reas_dest
  LEFT JOIN discharge_dest ddn
    ON drt.id_discharge_dest = ddn.id_discharge_dest
  LEFT JOIN dep_clin_serv dcs2
    ON drt.id_dep_clin_serv = dcs2.id_dep_clin_serv
  LEFT JOIN department dep
    ON dcs2.id_department = dep.id_department
  LEFT JOIN clinical_service cs2
    ON dcs2.id_clinical_service = cs2.id_clinical_service
  LEFT JOIN institution inst
    ON drt.id_institution = inst.id_institution
 WHERE sp.id_software IN (:i_prof_software, :g_soft_nutritionist)
   AND sp.dt_target_tstz <= :l_date
   AND s.id_instit_requested = :i_prof_institution
   AND cr.flg_status = :g_clin_active
   AND cr.id_institution = :i_prof_institution
   AND epis.flg_status NOT IN (:g_epis_active, :g_epis_canc)
   AND epis.flg_ehr != :g_flg_ehr_e
 ' || l_where || '
   AND rownum <= :l_limit
 ORDER BY ' || l_order_by || 'sp.dt_target_tstz';
    
        g_error := 'OPEN o_pat';
        OPEN o_pat FOR l_sql
            USING --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof,
                  i_prof.institution, --
                  i_prof.software, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  pk_grid_amb.g_schdl_outp_sched_domain, --
                  i_lang, --
                  pk_grid_amb.g_schdl_outp_sched_domain, --
                  g_sysdate_char, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_prof.software, --
                  pk_alert_constant.g_soft_nutritionist, --
                  l_date, --
                  i_prof.institution, --
                  --        g_sched_cancel, --
                  --        pk_schedule.g_sched_status_cache, --
                  g_clin_active, --
                  i_prof.institution, --
                  g_epis_active, --
                  g_epis_canc, --
                  pk_visit.g_flg_ehr_e, --
                  l_limit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_INACTIVE', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_INACTIVE', o_error);
        
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
        WHEN invalid_number THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.invalid_number_handler(i_lang,
                                                    i_prof,
                                                    g_package_name,
                                                    'GET_PAT_CRITERIA_INACTIVE',
                                                    o_error);
        
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_INACTIVE',
                                              'S',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_pat_criteria_inactive;

    FUNCTION get_epis_inact_tech
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE DOENTES INACTIVOS, DE ACORDO COM OS CRITÉRIOS SELECCIONADOS 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                   I_ID_SYS_BTN_CRIT - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
                   I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA
                 I_INSTIT - INSTITUIÇÃO 
                   I_PROF - PROFISSIONAL 
                 I_PROF_CAT_TYPE - TIPO DE CATEGORIA DO PROFISSIONAL, TAL 
                       COMO É RETORNADA EM PK_LOGIN.GET_PROF_PREF 
                  SAIDA: O_PAT - DOENTES 
                 O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
                 O_ERROR - ERRO 
          
          CRIAÇÃO: Teresa Coutinho 2008/03/28 
          ALTERAÇÃO: CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS 
               ASM 2006/12/27 INCLUIR NÃO SÓ OS EPISÓDIOS COM ALTA ADMINISTRATIVA, MAS TAMBÉM OS COM ALTA MÉDICA E OS EPISÓDIOS 
                            QUE FORAM FECHADOS AUTOMATICAMENTE 
                                    LIGAÇÃO À TABELA DOC_EXTERNAL PARA OS DOCUMENTOS, EM VEZ DA PAT_DOC 
        
          NOTAS: 
        *********************************************************************************/
        l_where     VARCHAR2(4300);
        l_from      VARCHAR2(4300);
        v_from_cond VARCHAR2(4000);
        l_hint      VARCHAR2(4300);
    
        l_ret BOOLEAN;
    
    BEGIN
        o_flg_show := 'N';
    
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        l_where := NULL;
    
        g_error := 'GET WHERE';
        IF NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                   i_crit_val => i_crit_val,
                                   o_where    => l_where,
                                   i_lang     => i_lang,
                                   i_prof     => i_prof)
        THEN
            l_where := NULL;
        END IF;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
                g_error := 'CALL PK_SEARCH.GET_FROM_CONDITION';
                IF NOT pk_search.get_from_condition(i_lang,
                                                    i_prof,
                                                    i_id_sys_btn_crit(i),
                                                    REPLACE(i_crit_val(i), '''', '%'),
                                                    v_from_cond,
                                                    o_error)
                THEN
                    RAISE g_exception;
                END IF;
                l_from := l_from || v_from_cond;
            END IF;
        END LOOP;
    
        g_error := 'OPEN O_PAT_ACTIVE';
    
        g_no_results := FALSE;
        g_overlimit  := FALSE;
    
        OPEN o_pat FOR
            SELECT *
              FROM TABLE(tf_epis_inact_tech(i_lang, i_prof, l_where, l_from));
    
        IF (g_no_results = TRUE)
        THEN
            RAISE pk_search.e_noresults;
        END IF;
        IF (g_overlimit = TRUE)
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_INACT_TECH', o_error);
        
            RETURN FALSE;
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_INACT_TECH', o_error);
        
            RETURN FALSE;
        
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_EPIS_INACT_TECH',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_EPIS_INACT_TECH',
                                              'S',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_epis_inact_tech;

    FUNCTION tf_epis_inact_tech
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2
    ) RETURN t_coll_episinactech IS
    
        l_sql VARCHAR2(4000);
    
        l_sysdate CONSTANT VARCHAR2(4000) := pk_date_utils.date_send_tsz(i_lang,
                                                                         current_timestamp,
                                                                         i_prof.institution,
                                                                         i_prof.software);
    
        dataset pk_types.cursor_type;
        l_limit sys_config.desc_sys_config%TYPE;
        out_obj t_rec_episinactech := t_rec_episinactech(NULL,
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
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL);
    
        TYPE dataset_tt IS TABLE OF v_epis_inact_etech_dummy%ROWTYPE INDEX BY PLS_INTEGER;
        l_dataset dataset_tt;
    
        l_row   PLS_INTEGER := 1;
        RESULT  t_coll_episinactech := t_coll_episinactech();
        l_color VARCHAR2(50);
        l_edis  sys_config.value%TYPE;
    
        l_view VARCHAR2(30);
    
    BEGIN
        g_error := 'GET LIMIT';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        pk_context_api.set_parameter('i_lang', i_lang);
    
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
    
        pk_context_api.set_parameter('ID_EXTERNAL_SYS',
                                     pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software));
    
        pk_context_api.set_parameter('EXTERNAL_SYSTEM_EXIST',
                                     pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST',
                                                             i_prof.institution,
                                                             i_prof.software));
    
        g_error := 'OPEN CURSOR';
        IF i_prof.software = pk_alert_constant.g_soft_labtech
        THEN
            l_view := 'v_src_ltech_inactive';
        ELSIF i_prof.software = pk_alert_constant.g_soft_imgtech
        THEN
            l_view := 'v_src_itech_inactive';
        ELSIF i_prof.software = pk_alert_constant.g_soft_extech
        THEN
            l_view := 'v_src_etech_inactive';
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_labtech
        THEN
            IF i_from IS NOT NULL
            THEN
                l_sql := 'SELECT /*+opt_estimate(table pat rows=1)*/ t.*, ' || --
                         'pk_lab_tech.get_col_request(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_status_ard, t.flg_time_harvest, t.flg_referral, t.flg_status_h, t.flg_status_result,
                t.dt_req_tstz, t.dt_pend_req_tstz,t.dt_target_tstz) col_request, ' || --
                         'pk_lab_tech.get_col_harvest(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_status_ard, t.flg_time_harvest, t.flg_status_h, t.dt_req_tstz, t.dt_pend_req_tstz, t.dt_target_tstz,
                t.dt_harvest_tstz, t.dt_begin_tstz_m, t.dt_mov_begin_tstz,t.dt_end_tstz, t.dt_lab_reception_tstz) col_harvest, ' || --
                         'pk_lab_tech.get_col_transport(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software || '), t.id_episode,
                t.flg_status_ard, t.flg_time_harvest, t.flg_status_h, t.dt_begin_tstz_m, t.dt_mov_begin_tstz,
                t.dt_harvest_tstz) col_transport, ' || --
                         'pk_lab_tech.get_col_execute(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_time_harvest, t.flg_status_h, t.dt_end_tstz, t.dt_lab_reception_tstz, t.dt_harvest_tstz) col_execute ' || --
                         ' FROM ' || l_view || ' t, ' || i_from || ' WHERE t.id_patient = pat.id_patient ' || i_where || ' ';
            ELSE
                l_sql := 'SELECT t.*, ' || --
                         'pk_lab_tech.get_col_request(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_status_ard, t.flg_time_harvest, t.flg_referral, t.flg_status_h, t.flg_status_result,
                t.dt_req_tstz, t.dt_pend_req_tstz,t.dt_target_tstz) col_request, ' || --
                         'pk_lab_tech.get_col_harvest(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_status_ard, t.flg_time_harvest, t.flg_status_h, t.dt_req_tstz, t.dt_pend_req_tstz, t.dt_target_tstz,
                t.dt_harvest_tstz, t.dt_begin_tstz_m, t.dt_mov_begin_tstz, t.dt_end_tstz, t.dt_lab_reception_tstz) col_harvest, ' || --
                         'pk_lab_tech.get_col_transport(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software || '), t.id_episode,
                t.flg_status_ard, t.flg_time_harvest, t.flg_status_h, t.dt_begin_tstz_m, t.dt_mov_begin_tstz,
                t.dt_harvest_tstz) col_transport, ' || --
                         'pk_lab_tech.get_col_execute(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_time_harvest, t.flg_status_h, t.dt_end_tstz, t.dt_lab_reception_tstz, t.dt_harvest_tstz) col_execute ' || --
                         ' FROM ' || l_view || ' t WHERE rownum <= :l_limit + 1 ' || i_where || ' ';
            END IF;
        
        ELSIF i_prof.software IN (pk_alert_constant.g_soft_imgtech)
        THEN
            IF i_from IS NOT NULL
            THEN
                l_sql := 'SELECT /*+opt_estimate(table pat rows=1)*/ t.*, ' || --
                         'pk_image_tech.get_col_request(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_status_req_det, t.flg_status_mov, t.flg_time_req, t.flg_referral, t.flg_status_r,
                t.dt_req_tstz, t.dt_pend_req_tstz,t.dt_begin_tstz_er) col_request, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) as col_harvest, ' || --
                         'pk_image_tech.get_col_transport(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software || '), t.id_episode,
                t.flg_status_req_det, t.flg_status_mov, t.flg_time_req, t.flg_referral, t.flg_status_r,
                t.dt_req_mov_tstz) col_transport, ' || --
                         'pk_image_tech.get_col_execute(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_status_req_det, t.flg_status_mov, t.flg_time_req , t.flg_referral, t.flg_status_r,
                t.dt_end_mov_tstz, t.dt_req_tstz, t.dt_pend_req_tstz, t.dt_begin_tstz_er) col_execute ' || --
                         ' FROM ' || l_view || ' t, ' || i_from || ' WHERE t.id_patient = pat.id_patient ' || i_where || ' ';
            ELSE
                l_sql := 'SELECT t.*, ' || --
                         'pk_image_tech.get_col_request(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_status_req_det, t.flg_status_mov, t.flg_time_req, t.flg_referral, t.flg_status_r,
                t.dt_req_tstz, t.dt_pend_req_tstz,t.dt_begin_tstz_er) col_request, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) as col_harvest, ' || --
                         'pk_image_tech.get_col_transport(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software || '), t.id_episode,
                t.flg_status_req_det, t.flg_status_mov, t.flg_time_req, t.flg_referral, t.flg_status_r,
                t.dt_req_mov_tstz) col_transport, ' || --
                         'pk_image_tech.get_col_execute(' || i_lang || ',
                profissional(' || i_prof.id || ',' || i_prof.institution || ', ' ||
                         i_prof.software ||
                         '), t.id_episode,
                t.flg_status_req_det, t.flg_status_mov, t.flg_time_req , t.flg_referral, t.flg_status_r,
                t.dt_end_mov_tstz, t.dt_req_tstz, t.dt_pend_req_tstz, t.dt_begin_tstz_er) col_execute ' || --
                         ' FROM ' || l_view || ' t WHERE rownum <= :l_limit + 1 ' || i_where || ' ';
            END IF;
            l_sql := l_sql || ' ORDER BY t.order_name ';
        ELSE
            IF i_from IS NOT NULL
            THEN
                l_sql := 'SELECT /*+opt_estimate(table pat rows=1)*/ t.*, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) col_request, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) col_harvest, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) col_transport, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) col_execute ' || --
                         '  FROM ' || l_view || ' t, ' || i_from || ' WHERE t.id_patient = pat.id_patient ' || i_where || ' ';
            ELSE
                l_sql := 'SELECT t.*, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) col_request, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) col_harvest, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) col_transport, ' || --
                         'CAST(NULL AS VARCHAR2(4000)) col_execute ' || --
                         ' FROM ' || l_view || ' t WHERE rownum <= :l_limit + 1 ' || i_where || ' ';
            END IF;
        END IF;
    
        dbms_output.put_line(l_sql);
        g_error := 'OPEN DATASET';
        pk_alertlog.log_debug(l_sql);
        IF i_from IS NOT NULL
        THEN
            OPEN dataset FOR l_sql;
        
        ELSE
            OPEN dataset FOR l_sql
                USING l_limit;
        END IF;
    
        g_error := 'FETCH FROM RESULTS CURSOR';
        FETCH dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        CLOSE dataset;
    
        g_error := 'COUNT RESULTS';
        IF l_dataset.count > l_limit
        THEN
            g_overlimit := TRUE;
            RETURN RESULT;
        ELSE
            IF l_dataset.count = 0
            THEN
                g_no_results := TRUE;
            END IF;
        END IF;
    
        g_error := 'EXTEND RESULT ARRAY';
        IF l_dataset.count < l_limit
        THEN
            result.extend(l_dataset.count);
        ELSE
            result.extend(l_limit);
        END IF;
    
        l_color := '0x919178';
        l_edis  := pk_sysconfig.get_config('SOFTWARE_ID_EDIS', i_prof);
    
        l_row   := l_dataset.first;
        g_error := 'GET DATA';
        WHILE (l_row <= result.count AND l_row <= l_limit)
        LOOP
        
            out_obj.rank             := l_dataset(l_row).rank;
            out_obj.acuity           := nvl(l_dataset(l_row).acuity, l_color);
            out_obj.rank_acuity      := l_dataset(l_row).rank;
            out_obj.epis_type        := pk_translation.get_translation(i_lang,
                                                                       'AB_SOFTWARE.CODE_SOFTWARE.' || l_dataset(l_row).id_software);
            out_obj.desc_institution := pk_translation.get_translation(i_lang,
                                                                       'AB_INSTITUTION.CODE_INSTITUTION.' || l_dataset(l_row).id_institution);
            out_obj.dt_first_obs     := pk_date_utils.date_send_tsz(i_lang, l_dataset(l_row).dt_first_obs_tstz, i_prof);
            out_obj.desc_patient     := pk_patient.get_pat_name(i_lang,
                                                                i_prof,
                                                                l_dataset(l_row).id_patient,
                                                                l_dataset(l_row).id_episode);
            out_obj.pat_ndo          := pk_adt.get_pat_non_disc_options(i_lang, i_prof, l_dataset(l_row).id_patient);
            out_obj.pat_nd_icon      := pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, l_dataset(l_row).id_patient);
            out_obj.id_patient       := l_dataset(l_row).id_patient;
        
            out_obj.gender := pk_patient.get_gender(i_lang, l_dataset(l_row).gender);
        
            out_obj.pat_age         := pk_patient.get_pat_age(i_lang,
                                                              l_dataset         (l_row).dt_birth,
                                                              l_dataset         (l_row).age,
                                                              i_prof.institution,
                                                              i_prof.software);
            out_obj.photo           := pk_patphoto.get_pat_photo(i_lang,
                                                                 i_prof,
                                                                 l_dataset(l_row).id_patient,
                                                                 l_dataset(l_row).id_episode,
                                                                 NULL);
            out_obj.num_clin_record := l_dataset(l_row).num_clin_record;
            out_obj.id_episode      := l_dataset(l_row).id_episode;
        
            out_obj.dt_server := l_sysdate;
        
            out_obj.dt_target := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                  l_dataset(l_row).dt_target,
                                                                  i_prof.institution,
                                                                  i_prof.software);
        
            out_obj.id_req := l_dataset(l_row).id_req;
        
            out_obj.id_harvest := l_dataset(l_row).id_harvest;
        
            IF i_prof.software = pk_alert_constant.g_soft_labtech
            THEN
                out_obj.desc_task := pk_translation.get_translation(i_lang,
                                                                    'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || l_dataset(l_row).id_task);
            
                out_obj.icon_name := pk_sysdomain.get_img(i_lang,
                                                          'ANALYSIS_REQ_DET.FLG_ORIGIN_MODULE',
                                                          l_dataset(l_row).flg_req_origin_module);
            
            ELSE
                out_obj.desc_task := pk_exams_api_db.get_alias_translation(i_lang,
                                                                           i_prof,
                                                                           'EXAM.CODE_EXAM.' || l_dataset(l_row).id_task,
                                                                           NULL);
            
                out_obj.icon_name := pk_sysdomain.get_img(i_lang,
                                                          'EXAM_REQ.FLG_ORIGIN_MODULE',
                                                          l_dataset(l_row).flg_req_origin_module);
            
            END IF;
        
            out_obj.priority := pk_sysdomain.get_img(i_lang, 'EXAM_REQ_DET.FLG_PRIORITY', l_dataset(l_row).priority);
        
            out_obj.col_request   := l_dataset(l_row).col_request;
            out_obj.col_harvest   := l_dataset(l_row).col_harvest;
            out_obj.col_transport := l_dataset(l_row).col_transport;
            out_obj.col_execute   := l_dataset(l_row).col_execute;
        
            IF l_dataset(l_row).flg_status = pk_alert_constant.g_exam_det_result
            THEN
                out_obj.col_complete := pk_sysdomain.get_img(i_lang,
                                                             (CASE i_prof.software
                                                                 WHEN pk_alert_constant.g_soft_labtech THEN
                                                                  'ANALYSIS_REQ_DET.FLG_STATUS'
                                                                 WHEN pk_alert_constant.g_soft_imgtech THEN
                                                                  'EXAM_REQ_DET.FLG_STATUS'
                                                                 WHEN pk_alert_constant.g_soft_extech THEN
                                                                  'EXAM_REQ_DET.FLG_STATUS'
                                                             END),
                                                             l_dataset(l_row).flg_status);
            ELSE
                out_obj.col_complete := NULL;
            END IF;
        
            out_obj.status_string := l_dataset(l_row).status_string;
        
            out_obj.flg_result := l_dataset(l_row).flg_result;
        
            out_obj.contact_state := CASE
                                         WHEN l_dataset(l_row).flg_status = pk_exam_constant.g_exam_cancel THEN
                                          pk_sysdomain.get_img(i_lang, 'EXAM_REQ.FLG_CONTACT', l_dataset(l_row).flg_contact)
                                         ELSE
                                          CASE
                                              WHEN nvl(l_dataset(l_row).id_schedule, -1) = -1 THEN
                                               pk_sysdomain.get_img(i_lang, 'EXAM_REQ.FLG_CONTACT', l_dataset(l_row).flg_contact)
                                              ELSE
                                               pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_STATE', l_dataset(l_row).flg_state)
                                          END
                                     END;
        
            out_obj.dept := pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || l_dataset(l_row).id_dept) ||
                            ' - ' ||
                            pk_translation.get_translation(i_lang,
                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || l_dataset(l_row).id_clinical_service);
        
            out_obj.fast_track_icon := pk_fast_track.get_fast_track_icon(i_lang,
                                                                         i_prof,
                                                                         l_dataset(l_row).id_episode,
                                                                         l_dataset(l_row).id_fast_track,
                                                                         l_dataset(l_row).id_triage_color,
                                                                         NULL,
                                                                         NULL);
        
            out_obj.fast_track_color := CASE l_dataset(l_row).acuity
                                            WHEN g_ft_color THEN
                                             g_ft_triage_white
                                            ELSE
                                             g_ft_color
                                        END;
        
            out_obj.fast_track_status := g_ft_status;
        
            IF NOT l_dataset(l_row).id_fast_track IS NULL
            THEN
                out_obj.fast_track_desc := pk_fast_track.get_fast_track_desc(i_lang,
                                                                             i_prof,
                                                                             l_dataset(l_row).id_fast_track,
                                                                             g_desc_grid);
            ELSE
                out_obj.fast_track_desc := NULL;
            END IF;
        
            out_obj.color_text := l_dataset(l_row).color_text;
        
            -- José Brito 26/02/2010 ALERT-721 ESI Level triage, when applicable
            IF l_dataset(l_row).id_triage_color IS NOT NULL
            THEN
                out_obj.esi_level := pk_edis_triage.get_epis_esi_level(i_lang,
                                                                       i_prof,
                                                                       l_dataset(l_row).id_episode,
                                                                       l_dataset(l_row).id_triage_color);
            ELSE
                out_obj.esi_level := NULL;
            END IF;
        
            out_obj.id_task_dependency := l_dataset(l_row).id_task_dependency;
        
            out_obj.order_name := l_dataset(l_row).order_name;
        
            RESULT(l_row) := out_obj;
        
            l_row := l_row + 1;
        END LOOP;
    
        RETURN(RESULT);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN RESULT;
            -- corrigir isto
    END tf_epis_inact_tech;

    FUNCTION get_pat_crit_sched_24h
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where        VARCHAR2(4000) := NULL;
        l_aux          VARCHAR2(1000 CHAR);
        v_where_cond   VARCHAR2(4000);
        l_dt_begin     schedule_outp.dt_target_tstz%TYPE;
        l_dt_end       schedule_outp.dt_target_tstz%TYPE;
        l_count        NUMBER;
        l_limit        sys_config.value%TYPE;
        l_sql          VARCHAR2(32767);
        l_handoff_type sys_config.value%TYPE;
        -- novas variáveis utilizadas para critério de pesquisa
        l_id_criteria    NUMBER;
        v_crit_condition criteria.crit_condition%TYPE;
    
        CURSOR c_crit IS
            SELECT crit_condition
              FROM criteria c
             WHERE c.id_criteria = l_id_criteria;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof); -- Nº MÁXIMO DE REGISTOS A APRESENTAR
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        --OBTER DATA DO SISTEMA PARA MOSTRAR APENAS CONSULTAS DE ONTEM
        g_error := 'GET dates';
        IF i_dt_str IS NULL
        THEN
            l_dt_end := pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => g_sysdate_tstz);
        ELSE
            l_dt_end := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                         i_timestamp => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                      i_prof      => i_prof,
                                                                                                      i_timestamp => i_dt_str,
                                                                                                      i_timezone  => NULL));
        END IF;
    
        l_dt_begin := pk_date_utils.add_days_to_tstz(i_timestamp => l_dt_end, i_days => -1);
    
        IF i_prof_cat_type IN (pk_alert_constant.g_cat_type_doc, pk_alert_constant.g_cat_type_nutritionist)
        THEN
            -- physicians and dietitians have no criteria, so they can't refine the search:
            -- present them no "please refine search" messages
            g_error := 'OPEN o_pat physician/dietitian';
            OPEN o_pat FOR
                WITH pat_inner AS
                 (SELECT s.id_schedule,
                         sg.id_patient,
                         cr.num_clin_record,
                         epis.id_episode,
                         pat.gender,
                         ei.id_dep_clin_serv,
                         sp.dt_target_tstz,
                         nvl(ei.id_professional, ei.sch_prof_outp_id_prof) id_professional,
                         ei.id_first_nurse_resp,
                         sp.flg_state,
                         sp.flg_sched,
                         epis.dt_begin_tstz,
                         decode(pk_edis_grid.get_label_follow_up_date(i_lang,
                                                                      i_prof,
                                                                      drt.id_disch_reas_dest,
                                                                      i_prof_cat_type),
                                NULL,
                                decode(drt.id_discharge_dest,
                                       NULL,
                                       decode(drt.id_dep_clin_serv,
                                              NULL,
                                              decode(drt.id_institution,
                                                     NULL,
                                                     NULL,
                                                     pk_translation.get_translation(i_lang, inst.code_institution)),
                                              pk_translation.get_translation(i_lang, dep.code_department) || ' - ' ||
                                              pk_translation.get_translation(i_lang, cs2.code_clinical_service)),
                                       pk_translation.get_translation(i_lang, ddn.code_discharge_dest)),
                                pk_edis_grid.get_label_follow_up_date(i_lang,
                                                                      i_prof,
                                                                      drt.id_disch_reas_dest,
                                                                      i_prof_cat_type)) disch_dest,
                         decode(pk_discharge_core.get_dt_admin(i_lang, i_prof, d.id_discharge), NULL, 'N', 'Y') disch_admin
                    FROM schedule_outp sp
                    JOIN schedule s
                      ON sp.id_schedule = s.id_schedule
                    JOIN sch_group sg
                      ON s.id_schedule = sg.id_schedule
                    JOIN patient pat
                      ON sg.id_patient = pat.id_patient
                    JOIN clin_record cr
                      ON pat.id_patient = cr.id_patient
                    JOIN epis_info ei
                      ON s.id_schedule = ei.id_schedule
                     AND pat.id_patient = ei.id_patient
                    JOIN episode epis
                      ON ei.id_episode = epis.id_episode
                    JOIN clinical_service cs
                      ON epis.id_clinical_service = cs.id_clinical_service
                    JOIN discharge d
                      ON epis.id_episode = d.id_episode
                    LEFT JOIN disch_reas_dest drt
                      ON d.id_disch_reas_dest = drt.id_disch_reas_dest
                    LEFT JOIN institution inst
                      ON drt.id_institution = inst.id_institution
                    LEFT JOIN dep_clin_serv dcs2
                      ON drt.id_dep_clin_serv = dcs2.id_dep_clin_serv
                    LEFT JOIN department dep
                      ON dcs2.id_department = dep.id_department
                    LEFT JOIN clinical_service cs2
                      ON dcs2.id_clinical_service = cs2.id_clinical_service
                    LEFT JOIN discharge_dest ddn
                      ON drt.id_discharge_dest = ddn.id_discharge_dest
                   WHERE sp.id_software IN (i_prof.software, g_software_nutri)
                     AND s.id_instit_requested = i_prof.institution
                     AND s.flg_status NOT IN (g_sched_cancel, pk_schedule.g_sched_status_cache)
                     AND (ei.sch_prof_outp_id_prof = i_prof.id OR ei.id_professional = i_prof.id)
                     AND cr.id_institution = i_prof.institution
                     AND epis.flg_status != g_epis_canc
                     AND epis.flg_ehr = pk_visit.g_flg_ehr_n
                     AND d.dt_cancel_tstz IS NULL
                     AND d.dt_med_tstz BETWEEN l_dt_begin AND l_dt_end)
                SELECT t.id_schedule,
                       t.id_patient,
                       t.num_clin_record,
                       t.id_episode,
                       (SELECT pk_patient.get_pat_name(i_lang, i_prof, t.id_patient, t.id_episode, t.id_schedule)
                          FROM dual) name,
                       (SELECT pk_patient.get_pat_name_to_sort(i_lang, i_prof, t.id_patient, t.id_episode, t.id_schedule)
                          FROM dual) name_to_sort,
                       (SELECT pk_adt.get_pat_non_disc_options(i_lang, i_prof, t.id_patient)
                          FROM dual) pat_ndo,
                       (SELECT pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, t.id_patient)
                          FROM dual) pat_nd_icon,
                       (SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', t.gender, i_lang)
                          FROM dual) gender,
                       (SELECT pk_patient.get_pat_age(i_lang, t.id_patient, i_prof)
                          FROM dual) pat_age,
                       (SELECT pk_patphoto.get_pat_photo(i_lang, i_prof, t.id_patient, t.id_episode, t.id_schedule)
                          FROM dual) photo,
                       (SELECT pk_hea_prv_aux.get_clin_service(i_lang, i_prof, t.id_dep_clin_serv)
                          FROM dual) cons_type,
                       (SELECT pk_date_utils.date_char_hour_tsz(i_lang,
                                                                t.dt_target_tstz,
                                                                i_prof.institution,
                                                                i_prof.software)
                          FROM dual) hour_target,
                       (SELECT pk_date_utils.trunc_dt_char_tsz(i_lang,
                                                               t.dt_target_tstz,
                                                               i_prof.institution,
                                                               i_prof.software)
                          FROM dual) date_target,
                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional)
                          FROM dual) nick_name,
                       (SELECT pk_grid_amb.get_responsibles_str(i_lang,
                                                                i_prof,
                                                                pk_alert_constant.g_cat_type_doc,
                                                                t.id_episode,
                                                                t.id_professional,
                                                                l_handoff_type,
                                                                'G')
                          FROM dual) name_prof,
                       (SELECT pk_prof_utils.get_nickname(i_lang, t.id_first_nurse_resp)
                          FROM dual) name_nurse,
                       (SELECT pk_grid_amb.get_responsibles_str(i_lang,
                                                                i_prof,
                                                                pk_alert_constant.g_cat_type_doc,
                                                                t.id_episode,
                                                                t.id_professional,
                                                                l_handoff_type,
                                                                'T')
                          FROM dual) name_prof_tooltip,
                       (SELECT pk_grid_amb.get_responsibles_str(i_lang,
                                                                i_prof,
                                                                pk_alert_constant.g_cat_type_nurse,
                                                                t.id_episode,
                                                                t.id_first_nurse_resp,
                                                                l_handoff_type,
                                                                'T')
                          FROM dual) name_nurse_tooltip,
                       t.flg_state,
                       g_sysdate_char dt_server,
                       (SELECT lpad(to_char(pk_sysdomain.get_rank(i_lang, g_domain_sch_outp_flg_sched, t.flg_sched)),
                                    6,
                                    '0') || pk_sysdomain.get_img(i_lang, g_domain_sch_outp_flg_sched, t.flg_sched)
                          FROM dual) img_sched,
                       (SELECT pk_date_utils.date_char_hour_tsz(i_lang,
                                                                t.dt_begin_tstz,
                                                                i_prof.institution,
                                                                i_prof.software)
                          FROM dual) dt_efectiv,
                       (SELECT pk_prof_utils.get_spec_signature(i_lang, i_prof, t.id_professional, NULL, t.id_episode)
                          FROM dual) desc_speciality,
                       t.disch_dest,
                       t.disch_admin,
                       (SELECT pk_date_utils.to_char_insttimezone(i_prof, t.dt_target_tstz, 'YYYYMMDDHH24MISS')
                          FROM dual) dt_ord1,
                       (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, t.id_episode, l_handoff_type)
                          FROM dual) resp_icon
                  FROM (SELECT id_schedule,
                               id_patient,
                               num_clin_record,
                               id_episode,
                               gender,
                               id_dep_clin_serv,
                               dt_target_tstz,
                               id_professional,
                               id_first_nurse_resp,
                               flg_state,
                               flg_sched,
                               dt_begin_tstz,
                               disch_dest,
                               disch_admin
                          FROM pat_inner pi
                         WHERE i_prof_cat_type = pk_alert_constant.g_cat_type_doc
                        UNION
                        SELECT id_schedule,
                               id_patient,
                               num_clin_record,
                               id_episode,
                               gender,
                               id_dep_clin_serv,
                               dt_target_tstz,
                               id_professional,
                               id_first_nurse_resp,
                               flg_state,
                               flg_sched,
                               dt_begin_tstz,
                               disch_dest,
                               disch_admin
                          FROM pat_inner pi
                         WHERE i_prof_cat_type = pk_alert_constant.g_cat_type_nutritionist
                        UNION
                        SELECT s.id_schedule,
                               sg.id_patient,
                               cr.num_clin_record,
                               epis.id_episode,
                               pat.gender,
                               ei.id_dep_clin_serv,
                               sp.dt_target_tstz,
                               nvl(ei.id_professional, ei.sch_prof_outp_id_prof) id_professional,
                               ei.id_first_nurse_resp,
                               sp.flg_state,
                               sp.flg_sched,
                               epis.dt_begin_tstz,
                               NULL disch_dest,
                               'N' disch_admin
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON sp.id_schedule = s.id_schedule
                          JOIN sch_group sg
                            ON s.id_schedule = sg.id_schedule
                          JOIN patient pat
                            ON sg.id_patient = pat.id_patient
                          JOIN clin_record cr
                            ON pat.id_patient = cr.id_patient
                          JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND pat.id_patient = ei.id_patient
                          JOIN episode epis
                            ON ei.id_episode = epis.id_episode
                          JOIN clinical_service cs
                            ON epis.id_clinical_service = cs.id_clinical_service
                         WHERE sp.id_software IN (i_prof.software, g_software_nutri)
                           AND s.id_instit_requested = i_prof.institution
                           AND s.flg_status NOT IN (g_sched_cancel, pk_schedule.g_sched_status_cache)
                           AND (ei.sch_prof_outp_id_prof = i_prof.id OR ei.id_professional = i_prof.id)
                           AND cr.id_institution = i_prof.institution
                           AND epis.flg_status != g_epis_canc
                           AND epis.flg_ehr = pk_visit.g_flg_ehr_n
                           AND epis.dt_end_tstz BETWEEN l_dt_begin AND l_dt_end
                           AND ei.flg_status = 'A'
                           AND NOT EXISTS (SELECT 1
                                  FROM discharge d
                                 WHERE d.id_episode = epis.id_episode
                                   AND d.dt_cancel_tstz IS NULL)) t
                 ORDER BY t.dt_target_tstz;
        
        ELSE
            -- registrars and nurses must have search criteria:
            -- set where condition
            IF i_id_sys_btn_crit.count = 0
            THEN
                l_where := '';
            ELSE
                FOR i IN 1 .. i_id_sys_btn_crit.count
                LOOP
                    g_error      := 'SET WHERE';
                    v_where_cond := NULL;
                    IF i_crit_val(i) IS NOT NULL
                    THEN
                        v_where_cond := '''' || TRIM(i_crit_val(i)) || ''',';
                        l_where      := l_where || v_where_cond;
                    END IF;
                END LOOP;
            
                l_where := TRIM(trailing ',' FROM l_where);
            
                IF i_id_sys_btn_crit(1) IS NOT NULL
                THEN
                    l_id_criteria := i_id_sys_btn_crit(1);
                ELSE
                    l_id_criteria := 14;
                END IF;
            
                g_error := 'GET CRITERIA';
                OPEN c_crit;
                FETCH c_crit
                    INTO v_crit_condition;
                g_found := c_crit%FOUND;
                CLOSE c_crit;
            
                IF NOT g_found
                THEN
                    g_error := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_M001');
                    RAISE g_exception_user;
                END IF;
            
                IF l_where IS NOT NULL
                THEN
                    l_where := REPLACE(v_crit_condition, '@1', l_where);
                END IF;
            END IF;
        
            -- set additional filters
            IF i_prof_cat_type = pk_alert_constant.g_cat_type_nurse
            THEN
                -- nurses results must be filtered by selected specialties
                l_aux := '
           AND EXISTS (SELECT 1
                  FROM prof_dep_clin_serv pdcs
                 WHERE pdcs.id_professional = ' || i_prof.id || '
                   AND pdcs.id_dep_clin_serv = ei.id_dep_clin_serv
                   AND pdcs.flg_status = ''' || g_selected || ''')';
            END IF;
        
            -- count results
            l_sql := 'SELECT COUNT(*) ' || --
                     '  FROM (SELECT sp.id_schedule ' || --
                     '          FROM schedule_outp sp ' || --
                     '          JOIN schedule s ' || --
                     '            ON sp.id_schedule = s.id_schedule ' || --
                     '          JOIN sch_group sg ' || --
                     '            ON s.id_schedule = sg.id_schedule ' || --
                     '          JOIN patient pat ' || --
                     '            ON sg.id_patient = pat.id_patient ' || --
                     '          JOIN clin_record cr ' || --
                     '            ON pat.id_patient = cr.id_patient ' || --
                     '          JOIN epis_info ei ' || --
                     '            ON s.id_schedule = ei.id_schedule ' || --
                     '           AND pat.id_patient = ei.id_patient ' || --
                     '          JOIN episode epis ' || --
                     '            ON ei.id_episode = epis.id_episode ' || --
                     '          JOIN clinical_service cs ' || --
                     '            ON epis.id_clinical_service = cs.id_clinical_service ' || --
                     '          JOIN discharge d ' || --
                     '            ON epis.id_episode = d.id_episode ' || --
                     '         WHERE sp.id_software = :i_prof_software ' || --
                     '           AND s.id_instit_requested = :i_prof_institution ' || --
                     '           AND s.flg_status NOT IN (:g_sched_cancel, :g_sched_status_cache) ' || l_aux || --
                     '           AND cr.id_institution = :i_prof_institution ' || --
                     '           AND epis.flg_status != :g_epis_canc ' || --
                     '           AND epis.flg_ehr = :g_flg_ehr_n ' || --
                     '           AND d.dt_cancel_tstz IS NULL ' || --
                     '           AND nvl(d.dt_med_tstz, d.dt_nurse) BETWEEN :l_dt_begin AND :l_dt_end ' || --
                     l_where || --
                     '        UNION ' || --
                     '        SELECT sp.id_schedule ' || --
                     '          FROM schedule_outp sp ' || --
                     '          JOIN schedule s ' || --
                     '            ON sp.id_schedule = s.id_schedule ' || --
                     '          JOIN sch_group sg ' || --
                     '            ON s.id_schedule = sg.id_schedule ' || --
                     '          JOIN patient pat ' || --
                     '            ON sg.id_patient = pat.id_patient ' || --
                     '          JOIN clin_record cr ' || --
                     '            ON pat.id_patient = cr.id_patient ' || --
                     '          JOIN epis_info ei ' || --
                     '            ON s.id_schedule = ei.id_schedule ' || --
                     '           AND pat.id_patient = ei.id_patient ' || --
                     '          JOIN episode epis ' || --
                     '            ON ei.id_episode = epis.id_episode ' || --
                     '          JOIN clinical_service cs ' || --
                     '            ON epis.id_clinical_service = cs.id_clinical_service ' || --
                     '         WHERE sp.id_software IN (:i_prof_software, :g_software_nutri) ' || --
                     '           AND s.id_instit_requested = :i_prof_institution ' || --
                     '           AND s.flg_status NOT IN (:g_sched_cancel, :g_sched_status_cache) ' || --
                     l_aux || '           AND cr.id_institution = :i_prof_institution ' || --
                     '           AND epis.flg_status != :g_epis_canc ' || --
                     '           AND epis.flg_ehr = :g_flg_ehr_n ' || --
                     '           AND epis.dt_end_tstz BETWEEN :l_dt_begin AND :l_dt_end ' || --
                     '           AND ei.flg_status = ''A'' ' || --
                     '           AND NOT EXISTS (SELECT 1 ' || --
                     '                  FROM discharge d ' || --
                     '                 WHERE d.id_episode = epis.id_episode ' || --
                     '                   AND d.dt_cancel_tstz IS NULL) ' || --
                     l_where || ')';
        
            g_error := 'GET EXECUTE IMMEDIATE';
            EXECUTE IMMEDIATE l_sql
                INTO l_count
                USING --
            i_prof.software, --
            i_prof.institution, --
            g_sched_cancel, --
            pk_schedule.g_sched_status_cache, --
            i_prof.institution, --
            g_epis_canc, --
            pk_visit.g_flg_ehr_n, --
            l_dt_begin, --
            l_dt_end, --
            i_prof.software, --
            pk_alert_constant.g_soft_nutritionist, --
            i_prof.institution, --
            g_sched_cancel, --
            pk_schedule.g_sched_status_cache, --
            i_prof.institution, --
            g_epis_canc, --
            pk_visit.g_flg_ehr_n, --
            l_dt_begin, --
            l_dt_end;
        
            IF l_count > l_limit
            THEN
                RAISE pk_search.e_overlimit;
            ELSIF l_count = 0
            THEN
                RAISE pk_search.e_noresults;
            END IF;
        
            -- open search results cursor
            l_sql := '
SELECT t.id_schedule,
       t.id_patient,
       t.num_clin_record,
       t.id_episode,
       pk_patient.get_pat_name(:i_lang, :i_prof, t.id_patient, t.id_episode, t.id_schedule) name,
       pk_patient.get_pat_name_to_sort(:i_lang, :i_prof, t.id_patient, t.id_episode, t.id_schedule) name_to_sort,
       pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, t.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, t.id_patient) pat_nd_icon,
       (SELECT pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', t.gender, :i_lang)
          FROM dual) gender,
       pk_patient.get_pat_age(:i_lang, t.id_patient, :i_prof) pat_age,
       pk_patphoto.get_pat_photo(:i_lang, :i_prof, t.id_patient, t.id_episode, t.id_schedule) photo,
			 pk_hea_prv_aux.get_clin_service(:i_lang, :i_prof, t.id_dep_clin_serv) cons_type,			 
       pk_date_utils.date_char_hour_tsz(:i_lang, t.dt_target_tstz, :i_prof_institution, :i_prof_software) hour_target,
       pk_date_utils.trunc_dt_char_tsz(:i_lang, t.dt_target_tstz, :i_prof_institution, :i_prof_software) date_target,
       pk_prof_utils.get_name_signature(:i_lang, :i_prof, t.id_professional) nick_name,
       (SELECT pk_grid_amb.get_responsibles_str(:i_lang,
																							  :i_prof,
																								:g_cat_type_doc,
																								t.id_episode, 
																								t.id_professional, 
																								:l_handoff_type, 
																								''G'') 
					 FROM dual) name_prof,
				(SELECT pk_prof_utils.get_nickname(:i_lang, t.id_first_nurse_resp) 
					 FROM dual) name_nurse,
				(SELECT pk_grid_amb.get_responsibles_str(:i_lang,
																								 :i_prof, 
																								 :g_cat_type_doc, 
																								 t.id_episode, 
																								 t.id_professional, 
																								 :l_handoff_type, 
																								 ''T'') 
					 FROM dual) name_prof_tooltip,
				(SELECT pk_grid_amb.get_responsibles_str(:i_lang, 
																								 :i_prof, 
																								 :g_cat_type_nurse,
																								 t.id_episode, 
																								 t.id_first_nurse_resp, 
																								 :l_handoff_type, 
																								 ''T'') 
					 FROM dual) name_nurse_tooltip, 
			 t.flg_state,
       :g_sysdate_char dt_server,
       (SELECT pk_sysdomain.get_ranked_img(:g_domain_sch_outp_flg_sched, t.flg_sched, :i_lang)
          FROM dual) img_sched,
       pk_date_utils.date_char_hour_tsz(:i_lang, t.dt_begin_tstz, :i_prof_institution, :i_prof_software) dt_efectiv,
       pk_prof_utils.get_spec_signature(:i_lang, :i_prof, t.id_professional, NULL, t.id_episode) desc_speciality,
       t.disch_dest,
       t.disch_admin,
       pk_date_utils.to_char_insttimezone(:i_prof, t.dt_target_tstz, ''YYYYMMDDHH24MISS'') dt_ord1,
       pk_hand_off_api.get_resp_icons(:i_lang, :i_prof, t.id_episode, :l_handoff_type) resp_icon
  FROM (SELECT s.id_schedule,
               pat.id_patient,
               cr.num_clin_record,
               epis.id_episode,
               pat.gender,
               cs.code_clinical_service,
							 ei.id_dep_clin_serv,							 
               sp.dt_target_tstz,
               nvl(ei.id_professional, ei.sch_prof_outp_id_prof) id_professional,
							 ei.id_first_nurse_resp,
               sp.flg_state,
               sp.flg_sched,
               epis.dt_begin_tstz,
               decode(pk_edis_grid.get_label_follow_up_date(:i_lang, :i_prof, drt.id_disch_reas_dest, :i_prof_cat_type),
                      NULL,
                      decode(drt.id_discharge_dest,
                             NULL,
                             decode(drt.id_dep_clin_serv,
                                    NULL,
                                    decode(drt.id_institution,
                                           NULL,
                                           NULL,
                                           pk_translation.get_translation(:i_lang, inst.code_institution)),
                                    pk_translation.get_translation(:i_lang, dep.code_department) || '' - '' ||
                                    pk_translation.get_translation(:i_lang, cs2.code_clinical_service)),
                             pk_translation.get_translation(:i_lang, ddn.code_discharge_dest)),
                      pk_edis_grid.get_label_follow_up_date(:i_lang, :i_prof, drt.id_disch_reas_dest, :i_prof_cat_type)) disch_dest,
               decode(d.dt_admin_tstz, NULL, ''N'', ''Y'') disch_admin
          FROM schedule_outp sp
          JOIN schedule s
            ON sp.id_schedule = s.id_schedule
          JOIN sch_group sg
            ON s.id_schedule = sg.id_schedule
          JOIN patient pat
            ON sg.id_patient = pat.id_patient
          JOIN clin_record cr
            ON pat.id_patient = cr.id_patient
          JOIN epis_info ei
            ON s.id_schedule = ei.id_schedule
           AND pat.id_patient = ei.id_patient
          JOIN episode epis
            ON ei.id_episode = epis.id_episode
          JOIN clinical_service cs
            ON epis.id_clinical_service = cs.id_clinical_service
          JOIN discharge d
            ON epis.id_episode = d.id_episode
          LEFT JOIN disch_reas_dest drt
            ON d.id_disch_reas_dest = drt.id_disch_reas_dest
          LEFT JOIN institution inst
            ON drt.id_institution = inst.id_institution
          LEFT JOIN dep_clin_serv dcs2
            ON drt.id_dep_clin_serv = dcs2.id_dep_clin_serv
          LEFT JOIN department dep
            ON dcs2.id_department = dep.id_department
          LEFT JOIN clinical_service cs2
            ON dcs2.id_clinical_service = cs2.id_clinical_service
          LEFT JOIN discharge_dest ddn
            ON drt.id_discharge_dest = ddn.id_discharge_dest
         WHERE sp.id_software = :i_prof_software
           AND s.id_instit_requested = :i_prof_institution
           AND s.flg_status NOT IN (:g_sched_cancel, :g_sched_status_cache)' || l_aux || '
           AND cr.id_institution = :i_prof_institution
           AND epis.flg_status != :g_epis_canc
           AND epis.flg_ehr = :g_flg_ehr_n
           AND d.dt_cancel_tstz IS NULL
           AND nvl(d.dt_med_tstz, d.dt_nurse) BETWEEN :l_dt_begin AND :l_dt_end
 ' || l_where || '
        UNION
        SELECT s.id_schedule,
               pat.id_patient,
               cr.num_clin_record,
               epis.id_episode,
               pat.gender,
               cs.code_clinical_service,
							 ei.id_dep_clin_serv,							 
               sp.dt_target_tstz,
               nvl(ei.id_professional, ei.sch_prof_outp_id_prof) id_professional,
							 ei.id_first_nurse_resp,
               sp.flg_state,
               sp.flg_sched,
               epis.dt_begin_tstz,
               NULL disch_dest,
               ''N'' disch_admin
          FROM schedule_outp sp
          JOIN schedule s
            ON sp.id_schedule = s.id_schedule
          JOIN sch_group sg
            ON s.id_schedule = sg.id_schedule
          JOIN patient pat
            ON sg.id_patient = pat.id_patient
          JOIN clin_record cr
            ON pat.id_patient = cr.id_patient
          JOIN epis_info ei
            ON s.id_schedule = ei.id_schedule
           AND pat.id_patient = ei.id_patient
          JOIN episode epis
            ON ei.id_episode = epis.id_episode
          JOIN clinical_service cs
            ON epis.id_clinical_service = cs.id_clinical_service
         WHERE sp.id_software IN (:i_prof_software, :g_software_nutri)
           AND s.id_instit_requested = :i_prof_institution
           AND s.flg_status NOT IN (:g_sched_cancel, :g_sched_status_cache)' || l_aux || '
           AND cr.id_institution = :i_prof_institution
           AND epis.flg_status != :g_epis_canc
           AND epis.flg_ehr = :g_flg_ehr_n
           AND epis.dt_end_tstz BETWEEN :l_dt_begin AND :l_dt_end
           AND ei.flg_status = ''A''
           AND NOT EXISTS (SELECT 1
                  FROM discharge d
                 WHERE d.id_episode = epis.id_episode
                   AND d.dt_cancel_tstz IS NULL)
 ' || l_where || ') t
 ORDER BY t.dt_target_tstz';
        
            g_error := 'OPEN o_pat nurse/registrar';
            OPEN o_pat FOR l_sql
                USING --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof.institution, --
                      i_prof.software, --
                      i_lang, --
                      i_prof.institution, --
                      i_prof.software, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      pk_alert_constant.g_cat_type_doc, --
                      l_handoff_type, --
                      i_lang, --
                      i_lang, --
                      i_prof, --
                      pk_alert_constant.g_cat_type_doc, --
                      l_handoff_type, --
                      i_lang, --
                      i_prof, --
                      pk_alert_constant.g_cat_type_nurse, --
                      l_handoff_type, --
                      g_sysdate_char, --
                      g_domain_sch_outp_flg_sched, --
                      i_lang, --
                      i_lang, --
                      i_prof.institution, --
                      i_prof.software, --
                      i_lang, --
                      i_prof, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      l_handoff_type, --
                      i_lang, --
                      i_prof, --
                      i_prof_cat_type, --
                      i_lang, --
                      i_lang, --
                      i_lang, --
                      i_lang, --
                      i_lang, --
                      i_prof, --
                      i_prof_cat_type, --
                      i_prof.software, --
                      i_prof.institution, --
                      g_sched_cancel, --
                      pk_schedule.g_sched_status_cache, --
                      i_prof.institution, --
                      g_epis_canc, --
                      pk_visit.g_flg_ehr_n, --
                      l_dt_begin, --
                      l_dt_end, --
                      i_prof.software, --
                      g_software_nutri, --
                      i_prof.institution, --
                      g_sched_cancel, --
                      pk_schedule.g_sched_status_cache, --
                      i_prof.institution, --
                      g_epis_canc, --
                      pk_visit.g_flg_ehr_n, --
                      l_dt_begin, --
                      l_dt_end;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRIT_SCHED_24H', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRIT_SCHED_24H', o_error);
        
        WHEN g_exception_user THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_SCHED_24H',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_SCHED_24H',
                                              'S',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_pat_crit_sched_24h;

    FUNCTION get_pat_crit_sched_today
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE CONSULTAS DE HOJE. SE O PROFISSINAL FOR UM MÉDICO OU ENFERMEIRO NÃO PEDE
                       CRITÉRIOS DE PESQUISA. SENÃO, OS CRITÉRIOS TÊM QUE SER OBSERVADOS 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                   I_ID_SYS_BTN_CRIT - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
                   I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA
                 I_INSTIT - INSTITUIÇÃO
                 I_PROF - ID DO PROFISSIONAL. SE NÃO ESTIVER PREENCHIDO DEVOLVE AS CONSULTAS DE TODOS
                      OS PROFISSIONAIS 
                 I_EPIS_TYPE - TIPO DE CONSULTA
                 I_DT - DATA A PESQUISAR. SE FOR NULL ASSUME A DATA DE SISTEMA      
                 I_PROF_CAT_TYPE - TIPO DE CATEGORIA DO PROFISSIONAL, TAL 
                       COMO É RETORNADA EM PK_LOGIN.GET_PROF_PREF                
                  SAIDA: O_PAT - DOENTES 
                 O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
                 O_ERROR - ERRO 
          
          CRIAÇÃO: RB 2005/05/03 
          ALTERAÇÃO: CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS 
               ASM 2006/12/27 LISTA NÃO SÓ AS CONSULTAS AGENDADAS PARA O UTILIZADOR, MAS TB OS EPISÓDIOS SOBRE OS QUAIS ASSUMIU RESPONSABILIDADE 
                                    LIGAÇÃO À TABELA DOC_EXTERNAL PARA OS DOCUMENTOS, EM VEZ DA PAT_DOC 
        
          NOTAS: 
        *********************************************************************************/
        l_where VARCHAR2(4000);
        straux  VARCHAR2(255);
        --l_error      VARCHAR2(4000);
        v_where_cond VARCHAR2(4000);
        l_date       TIMESTAMP WITH TIME ZONE;
        l_count      NUMBER;
        l_limit      sys_config.desc_sys_config%TYPE;
        --n1           NUMBER;
        aux_sql    VARCHAR2(32767);
        str_sql    VARCHAR2(10000);
        l_continue BOOLEAN := TRUE;
    
        --
        l_day_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_day_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        -- novas variáveis utilizadas para critério de pesquisa
        l_id_criteria    NUMBER;
        l_handoff_type   sys_config.value%TYPE;
        v_crit_condition criteria.crit_condition%TYPE;
        CURSOR c_crit IS
            SELECT crit_condition
              FROM criteria c
             WHERE c.id_criteria = l_id_criteria;
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof); -- Nº MÁXIMO DE REGISTOS A APRESENTAR
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_day_begin := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
        l_day_end   := l_day_begin + numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND');
    
        --OBTER DATA DO SISTEMA PARA MOSTRAR APENAS CONSULTAS DE ONTEM
        g_error := 'GET l_date';
        IF i_dt_str IS NULL
        THEN
            l_date := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
        
        ELSE
            l_date := pk_date_utils.trunc_insttimezone(i_prof,
                                                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_str, NULL));
        
        END IF;
    
        l_where := NULL;
    
        --SE O PROFISSIONAL FOR UM MÉDICO OU ENFERMEIRO NÃO PREENCHE CRITÉRIOS DE PESQUISA. SENÃO, PREENCHE E TÊM QUE SER
        --OBSERVADOS
        IF i_prof_cat_type NOT IN (g_flg_doctor, g_flg_nutri)
        THEN
            IF i_id_sys_btn_crit.count = 0
            THEN
                l_where := '';
            ELSE
                FOR i IN 1 .. i_id_sys_btn_crit.count
                LOOP
                    g_error      := 'SET WHERE';
                    v_where_cond := NULL;
                    IF i_crit_val(i) IS NOT NULL
                    THEN
                        v_where_cond := '''' || TRIM(i_crit_val(i)) || ''',';
                        l_where      := l_where || v_where_cond;
                    END IF;
                END LOOP;
            
                l_where := TRIM(trailing ',' FROM l_where);
            
                IF i_id_sys_btn_crit(1) IS NOT NULL
                THEN
                    l_id_criteria := i_id_sys_btn_crit(1);
                ELSE
                    l_id_criteria := 14;
                END IF;
            
                g_error := 'GET CRITERIA';
                OPEN c_crit;
                FETCH c_crit
                    INTO v_crit_condition;
                g_found := c_crit%FOUND;
                CLOSE c_crit;
            
                IF NOT g_found
                THEN
                    g_error := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_M001') || chr(10) ||
                               'PK_SEARCH.GET_CRITERIA_CONDITION / ' || g_error;
                    ROLLBACK;
                    RETURN FALSE;
                END IF;
            
                IF l_where IS NOT NULL
                THEN
                    l_where := REPLACE(v_crit_condition, '@1', l_where);
                END IF;
            END IF;
        END IF;
    
        IF i_prof_cat_type IN (g_flg_doctor, g_flg_nutri)
        THEN
            straux := 'AND (p.id_professional = ' || i_prof.id || 'OR  ei.id_professional = ' || i_prof.id || ')';
        ELSIF i_prof_cat_type = g_flg_nurse
        THEN
            straux := 'AND EXISTS (SELECT 1 FROM prof_dep_clin_serv pdcs ' || ' WHERE pdcs.id_professional =' ||
                      i_prof.id || ' AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv ' || ' AND pdcs.flg_status = ''' ||
                      g_selected || '''' || ')'; -- RDSN 2006/12/18 CORRECÇÃO DE ERRO NA COLOCAÇÃO DO PARENTESIS E DAS PLICAS
        END IF;
    
        g_error := 'GET COUNT';
        IF i_prof_cat_type IN (g_flg_doctor, g_flg_nutri)
        THEN
            aux_sql := 'SELECT SUM (X)' || ' FROM (';
        END IF;
    
        aux_sql := aux_sql || ' ' || --
                   'SELECT COUNT(sp.id_schedule) X ' || --
                   ' FROM schedule_outp sp, ' || --
                   '      schedule s, ' || --
                   '      sch_group sg, ' || --
                   '      patient pat, ' || --
                   '      speciality spec,  ' || --
                   '      dep_clin_serv dcs, ' || --
                   '      clinical_service cs, ' || --
                   '      professional p, ' || --
                   '      clin_record cr, ' || --
                   '      epis_info ei, ' || --
                   '      episode epis, ' || --
                   '      discharge d, ' || --
                   '      disch_reas_dest drt, ' || --
                   '      institution inst, ' || --
                   '      department dep, ' || --
                   '      discharge_dest ddn, ' || --
                   '      clinical_service cs2, ' || --
                   '      dep_clin_serv dcs2, ' || --
                   '      pat_soc_attributes psa ' || --
                   ' WHERE s.id_instit_requested = :1 ' || -- i_prof.institution
                   '   AND s.flg_status != :20 ' || -- g_sched_cancel 
                   '   AND s.flg_status != ''V''' || -- g_sched_cache
                   '   AND sp.id_schedule = s.id_schedule ' || --
                   '   AND sp.id_software IN (:2 , ' || g_software_nutri || ') ' || -- i_prof.software
                   straux || --
                   '   AND ei.sch_prof_outp_id_prof = p.id_professional(+)' || --
                   '   AND sg.id_schedule = s.id_schedule' || --
                   '   AND pat.id_patient = sg.id_patient' || --
                   '   AND psa.id_patient(+) = pat.id_patient ' || --
                   '   AND psa.id_institution(+) = :1 ' || --
                   '   AND dcs.id_dep_clin_serv = s.id_dcs_requested' || --
                   '   AND cs.id_clinical_service = dcs.id_clinical_service' || --
                   '   AND cr.id_patient = pat.id_patient' || --
                   '   AND cr.id_institution = :1 ' || -- i_prof.institution
                   '   AND ei.id_schedule = s.id_schedule' || --
                   '   AND epis.id_episode = ei.id_episode' || --
                   '   AND epis.flg_status != :4 ' || -- g_epis_canc
                   '   AND epis.flg_ehr IN (''N'', ''S'') ' || --
                   '   AND spec.id_speciality(+) = p.id_speciality ' || --
                   '   AND d.id_episode = epis.id_episode' || --
                   '   AND d.dt_cancel_tstz is null' || --
                   '   AND d.dt_med_tstz BETWEEN :5 AND :6 ' || -- 
                   '   AND drt.id_disch_reas_dest = d.id_disch_reas_dest' || --
                   '   AND inst.id_institution(+) = drt.id_institution ' || --
                   '   AND dep.id_department(+) = dcs2.id_department' || --
                   '   AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv' || --
                   '   AND cs2.id_clinical_service(+) = dcs2.id_clinical_service' || --
                   '   AND ddn.id_discharge_dest(+) = drt.id_discharge_dest' || --
                   l_where;
    
        IF i_prof_cat_type IN (g_flg_doctor, g_flg_nutri)
        THEN
            aux_sql := aux_sql || ' UNION ' || --
                       'SELECT COUNT(SP.ID_SCHEDULE) X ' || --
                       ' FROM schedule_outp sp, ' || --
                       '      schedule s, ' || --
                       '      sch_group sg, ' || --
                       '      patient pat, ' || --
                       '      speciality spec, ' || --
                       '      clinical_service cs,' || --
                       '      professional p, ' || --
                       '      clin_record cr, ' || --
                       '      epis_info ei, ' || --
                       '      episode epis, ' || --
                       '      discharge d, ' || --
                       '      disch_reas_dest drt, ' || --
                       '      institution inst, ' || --
                       '      department dep, ' || --
                       '      discharge_dest ddn, ' || --
                       '      clinical_service cs2, ' || --
                       '      dep_clin_serv dcs2, ' || --
                       '      pat_soc_attributes psa ' || --
                       ' WHERE s.id_instit_requested = :1 ' || -- i_prof.institution
                       ' AND s.flg_status != :20' || -- g_sched_cancel 
                       ' AND s.flg_status != ''V''' || -- g_sched_cache
                       ' AND sp.id_schedule = s.id_schedule' || --
                       ' AND sp.id_software = :2 ' || -- i_prof.software
                       ' AND p.id_professional != ' || i_prof.id ||
                       ' AND ei.sch_prof_outp_id_prof = p.id_professional(+)' || --
                       ' AND sg.id_schedule = s.id_schedule' || --
                       ' AND pat.id_patient = sg.id_patient' || --
                       ' AND psa.id_patient(+) = pat.id_patient ' || --
                       ' AND psa.id_institution(+) = :1 ' || --
                       ' AND cs.id_clinical_service = epis.id_cs_requested' || --
                       ' AND cr.id_patient = pat.id_patient' || --
                       ' AND cr.id_institution = :1 ' || -- i_prof.institution
                       ' AND ei.id_schedule = s.id_schedule' || --
                       ' AND ei.id_professional = ' || i_prof.id || --
                       ' AND epis.id_episode = ei.id_episode' || --
                       ' AND epis.flg_status != :4 ' || -- g_epis_canc
                       ' AND spec.id_speciality(+) = p.id_speciality ' || --
                       ' AND d.id_episode = epis.id_episode' || --
                       ' AND d.dt_cancel_tstz is null' || --
                       ' AND d.dt_med_tstz BETWEEN :7 AND :8 ' || ' AND drt.id_disch_reas_dest = d.id_disch_reas_dest' || --
                       ' AND inst.id_institution(+) = drt.id_institution ' || --
                       ' AND dep.id_department(+) = dcs2.id_department' || --
                       ' AND epis.flg_ehr IN (''N'', ''S'') ' || --
                       ' AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv' || --
                       ' AND cs2.id_clinical_service(+) = dcs2.id_clinical_service' || --
                       ' AND ddn.id_discharge_dest(+) = drt.id_discharge_dest)';
        ELSIF i_prof_cat_type = g_flg_nurse -- PT 06-08-2008
        THEN
            aux_sql := 'SELECT SUM (X)' || --
                       ' FROM (' || --
                       'SELECT COUNT(sp.id_schedule) x ' || --
                       ' FROM schedule_outp sp, ' || --
                       '      schedule s, ' || --
                       '      sch_group sg, ' || --
                       '      patient pat, ' || --
                       '      speciality spec, ' || --
                       '      dep_clin_serv dcs, ' || --
                       '      clinical_service cs, ' || --
                       '      professional p, ' || --
                       '      clin_record cr, ' || --
                       '      epis_info ei, ' || --
                       '      episode epis, ' || --
                       '      discharge d, ' || --
                       '      disch_reas_dest drt, ' || --
                       '      institution inst, ' || --
                       '      department dep, ' || --
                       '      discharge_dest ddn, ' || --
                       '      clinical_service cs2, ' || --
                       '      dep_clin_serv dcs2, ' || --
                       '      pat_soc_attributes psa ' || --
                       ' WHERE s.id_instit_requested = :1 ' || -- i_prof.institution
                       ' AND s.flg_status != :20' || -- g_sched_cancel 
                       ' AND s.flg_status != ''V''' || -- g_sched_cache
                       ' AND sp.id_schedule = s.id_schedule ' || --
                       ' AND sp.id_software = :2 ' || -- i_prof.software
                       straux || --
                       ' AND ei.sch_prof_outp_id_prof = p.id_professional(+) ' || --
                       ' AND sg.id_schedule = s.id_schedule' || --
                       ' AND pat.id_patient = sg.id_patient' || --
                       ' AND psa.id_patient(+) = pat.id_patient ' || --
                       ' AND psa.id_institution(+) = :1 ' || --
                       ' AND dcs.id_dep_clin_serv = s.id_dcs_requested' ||
                       ' AND cs.id_clinical_service = dcs.id_clinical_service' || --
                       ' AND cr.id_patient = pat.id_patient' || --
                       ' AND cr.id_institution = :1 ' || -- i_prof.institution
                       ' AND ei.id_schedule = s.id_schedule' || --
                       ' AND epis.id_episode = ei.id_episode' || --
                       ' AND epis.flg_status != :4 ' || -- g_epis_canc
                       ' AND epis.flg_ehr IN (''N'', ''S'') ' || --
                       ' AND spec.id_speciality(+) = p.id_speciality ' || --
                       ' AND d.id_episode = epis.id_episode' || --
                       ' AND d.dt_cancel_tstz IS NULL' || --
                       ' AND trunc(current_timestamp) = trunc(nvl(d.dt_med_tstz,d.dt_nurse)) ' || --
                       ' AND drt.id_disch_reas_dest = d.id_disch_reas_dest' || --
                       ' AND inst.id_institution(+) = drt.id_institution ' || --
                       ' AND dep.id_department(+) = dcs2.id_department' || --
                       ' AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv' || --
                       ' AND cs2.id_clinical_service(+) = dcs2.id_clinical_service' || --
                       ' AND ddn.id_discharge_dest(+) = drt.id_discharge_dest' || --
                       l_where || ' )';
        END IF;
    
        IF i_prof_cat_type IN (g_flg_doctor, g_flg_nutri)
        THEN
            g_error := 'GET EXECUTE IMMEDIATE 1 Query:' || aux_sql;
            EXECUTE IMMEDIATE aux_sql
                INTO l_count
                USING i_prof.institution, g_sched_cancel, i_prof.software, i_prof.institution, i_prof.institution, g_epis_canc, l_day_begin, l_day_end, -- l_date, g_doc_active,
            --
            i_prof.institution, g_sched_cancel, i_prof.software, i_prof.institution, i_prof.institution, g_epis_canc, l_day_begin, l_day_end; --, l_date, g_doc_active;
        ELSE
            g_error := 'GET EXECUTE IMMEDIATE 2 Query:' || aux_sql;
            EXECUTE IMMEDIATE aux_sql
                INTO l_count
                USING i_prof.institution, g_sched_cancel, i_prof.software, i_prof.institution, i_prof.institution, g_epis_canc; --, l_date, g_doc_active;
        END IF;
    
        IF l_count > l_limit
           AND i_prof_cat_type NOT IN (g_flg_doctor, g_flg_nutri)
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
           AND i_prof_cat_type NOT IN (g_flg_doctor, g_flg_nutri)
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_continue
        THEN
            g_error := 'GET CURSOR 1 ' || str_sql;
        
            str_sql := 'SELECT x.*, ' || --
                       ' (SELECT pk_hand_off_api.get_resp_icons(' || i_lang || ' ,profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software || '), x.id_episode,''' || l_handoff_type ||
                       ''') ' || '               FROM dual) resp_icon ' || --
                       'FROM (SELECT s.id_schedule, ' || --
                       ' sg.id_patient, ' || --
                       ' cr.num_clin_record, ' || --
                       ' epis.id_episode, ' || --
                       ' pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software ||
                       '), pat.id_patient, epis.id_episode, s.id_schedule) name,' || --
                       ' pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software ||
                       '), sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,  ' || --                      
                       ' pk_adt.get_pat_non_disc_options(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_ndo,' || --
                       ' pk_adt.get_pat_non_disclosure_icon(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_nd_icon,' || --
                       ' pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, ' || i_lang || ') gender, ' || --
                       ' pk_patient.get_pat_age(' || i_lang || ', pat.id_patient, ' || i_prof.institution || ', ' ||
                       i_prof.software || ') pat_age,' || --
                       ' pk_patphoto.get_pat_photo(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software ||
                       '), pat.id_patient, epis.id_episode, s.id_schedule) photo, ' || --
                       ' pk_hea_prv_aux.get_clin_service(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software || '), ei.id_dep_clin_serv) cons_type,' || --
                       ' pk_date_utils.date_char_hour_tsz(' || i_lang || ', sp.dt_target_tstz, ' || i_prof.institution || ', ' ||
                       i_prof.software || ') hour_target, ' || --
                       ' pk_date_utils.trunc_dt_char_tsz(' || i_lang || ', sp.dt_target_tstz, ' || i_prof.institution || ', ' ||
                       i_prof.software || ') date_target,' || --
                       ' pk_prof_utils.get_name_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software || '), p.id_professional) nick_name, ' || --
                       ' pk_grid_amb.get_responsibles_str( ' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software || '), ''' || pk_alert_constant.g_cat_type_doc ||
                       ''', ei.id_episode, nvl(ei.id_professional, ei.sch_prof_outp_id_prof), ''' || l_handoff_type ||
                       ''', ''G'') name_prof, ' || --
                       ' pk_prof_utils.get_nickname(' || i_lang || ', ei.id_first_nurse_resp) name_nurse, ' || --
                       ' pk_grid_amb.get_responsibles_str( ' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software || '), ''' || pk_alert_constant.g_cat_type_doc ||
                       ''', ei.id_episode, nvl(ei.id_professional, ei.sch_prof_outp_id_prof), ''' || l_handoff_type ||
                       ''', ''T'') name_prof_tooltip, ' || --
                       ' pk_grid_amb.get_responsibles_str(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software || '), ''' || pk_alert_constant.g_cat_type_nurse ||
                       ''', ei.id_episode, ei.id_first_nurse_resp, ''' || l_handoff_type ||
                       ''', ''T'') name_nurse_tooltip, ' || --
                       ' sp.flg_state, ' || --
                       '''' || g_sysdate_char || ''' dt_server, ' || --
                       ' lpad(to_char(pk_sysdomain.get_rank(' || i_lang ||
                       ', ''SCHEDULE_OUTP.FLG_SCHED'', sp.flg_sched)), 6, ''0'') || pk_sysdomain.get_img(' || i_lang ||
                       ', ''SCHEDULE_OUTP.FLG_SCHED'', sp.flg_sched) img_sched,' || --
                       ' pk_date_utils.date_char_hour_tsz(' || i_lang || ', epis.dt_begin_tstz, ' || i_prof.institution || ', ' ||
                       i_prof.software || ') dt_efectiv, ' || --
                       ' pk_prof_utils.get_spec_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software ||
                       '), p.id_professional , null, null) desc_speciality, ' || --
                       ' decode(pk_edis_grid.get_label_follow_up_date(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ', ' || i_prof.software || '), drt.id_disch_reas_dest,''' ||
                       i_prof_cat_type || '''), NULL, decode(drt.id_discharge_dest,' || ''''',' ||
                       ' decode(drt.id_dep_clin_serv, '''',' ||
                       ' decode(drt.id_institution, '''', '''', pk_translation.get_translation(' || i_lang ||
                       ', inst.code_institution)),' || ' pk_translation.get_translation(' || i_lang ||
                       ', dep.code_department)||'' - ''||' || ' pk_translation.get_translation(' || i_lang ||
                       ', cs2.code_clinical_service)),' || ' pk_translation.get_translation(' || i_lang ||
                       ', ddn.code_discharge_dest)), pk_edis_grid.get_label_follow_up_date(' || i_lang ||
                       ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software ||
                       '), drt.id_disch_reas_dest,''' || i_prof_cat_type || ''')) disch_dest, ' || --
                       ' decode (pk_discharge_core.get_dt_admin(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                       i_prof.institution || ',' || i_prof.software ||
                       '), d.id_discharge), NULL, ''N'', ''Y'') disch_admin, ' || --
                       ' pk_date_utils.to_char_insttimezone(' || i_prof.institution || ', ' || i_prof.software ||
                       ', sp.dt_target_tstz, ''YYYYMMDDHH24MISS'') dt_ord1 ' || --
                       ' FROM schedule_outp sp, ' || -- 
                       ' schedule s, ' || -- 
                       ' sch_group sg, ' || -- 
                       ' patient pat, ' || -- 
                       ' speciality spec, ' || -- 
                       ' dep_clin_serv dcs, ' || --
                       ' clinical_service cs, ' || -- 
                       ' professional p, ' || -- 
                       ' clin_record cr, ' || -- 
                       ' epis_info ei, ' || -- 
                       ' episode epis, ' || --
                       ' discharge d, ' || -- 
                       ' disch_reas_dest drt, ' || -- 
                       ' institution inst, ' || -- 
                       ' department dep, ' || -- 
                       ' discharge_dest ddn, ' || -- 
                       ' clinical_service cs2, ' || --
                       ' dep_clin_serv dcs2, ' || -- 
                       ' pat_soc_attributes psa ' || --
                       ' WHERE s.id_instit_requested = ' || i_prof.institution || --
                       ' AND s.flg_status != ''' || g_sched_cancel || '''' || --
                       ' AND s.flg_status != ''V''' || -- g_sched_cache
                       ' AND sp.id_schedule = s.id_schedule' || --
                       ' AND sp.id_software IN (' || i_prof.software || ' , ' || g_software_nutri || ') ' || --
                       straux || --
                       ' AND ei.sch_prof_outp_id_prof = p.id_professional(+) ' || --
                       ' AND sg.id_schedule = s.id_schedule ' || --
                       ' AND pat.id_patient = sg.id_patient ' || --
                       ' AND psa.id_patient(+) = pat.id_patient ' || --
                       ' AND psa.id_institution(+) = ' || i_prof.institution || --
                       ' AND dcs.id_dep_clin_serv = s.id_dcs_requested' || --
                       ' AND cs.id_clinical_service = dcs.id_clinical_service' || --
                       ' AND cr.id_patient = pat.id_patient' || --
                       ' AND cr.id_institution = ' || i_prof.institution || --
                       ' AND ei.id_schedule = s.id_schedule' || --
                       ' AND epis.id_episode = ei.id_episode' || --
                       ' AND epis.flg_status != ''' || g_epis_canc || '''' || --
                       ' AND spec.id_speciality(+) = p.id_speciality ' || --
                       ' AND d.id_episode = epis.id_episode' || --
                       ' AND epis.flg_ehr IN (''N'', ''S'') ' || --
                       ' AND d.dt_cancel_tstz is null' || --
                       ' AND d.dt_med_tstz BETWEEN :1 AND :2 ' || ' AND drt.id_disch_reas_dest = d.id_disch_reas_dest' ||
                       ' AND inst.id_institution(+) = drt.id_institution ' ||
                       ' AND dep.id_department(+) = dcs2.id_department' ||
                       ' AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv' ||
                       ' AND cs2.id_clinical_service(+) = dcs2.id_clinical_service' ||
                       ' AND ddn.id_discharge_dest(+) = drt.id_discharge_dest' || l_where;
        
            IF i_prof_cat_type IN (g_flg_doctor, g_flg_nutri)
            THEN
                str_sql := str_sql || ' UNION ' || --
                           ' SELECT s.id_schedule, ' || -- 
                           ' sg.id_patient, ' || -- 
                           ' cr.num_clin_record, ' || -- 
                           ' epis.id_episode,' || --
                           ' pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software ||
                           '), pat.id_patient, epis.id_episode, s.id_schedule) name,' || --
                           ' pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software ||
                           '), sg.id_patient, ei.id_episode,s.id_schedule) name_to_sort, ' || --                          
                           ' pk_adt.get_pat_non_disc_options(' || i_lang || ', profissional(' || i_prof.id || ',' || --
                           i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_ndo, ' || --
                           ' pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_nd_icon, ' || --
                           ' pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, ' || i_lang || ') gender, ' || --
                           ' pk_patient.get_pat_age(' || i_lang || ', pat.id_patient, ' || i_prof.institution || ', ' ||
                           i_prof.software || ') pat_age, ' || --
                           ' pk_patphoto.get_pat_photo(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software ||
                           '), pat.id_patient, epis.id_episode, s.id_schedule) photo, ' || --
                           ' pk_hea_prv_aux.get_clin_service(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), ei.id_dep_clin_serv) cons_type, ' || --
                           'pk_date_utils.date_char_hour_tsz(' || i_lang || ', sp.dt_target_tstz, ' ||
                           i_prof.institution || ', ' || i_prof.software || ') hour_target, ' || --
                           ' pk_date_utils.trunc_dt_char_tsz(' || i_lang || ', sp.dt_target_tstz, ' ||
                           i_prof.institution || ', ' || i_prof.software || ') date_target,' || --
                           ' pk_prof_utils.get_name_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), p.id_professional) nick_name, ' || --
                           ' pk_grid_amb.get_responsibles_str( ' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), ''' || pk_alert_constant.g_cat_type_doc ||
                           ''', ei.id_episode, nvl(ei.id_professional, ei.sch_prof_outp_id_prof), ''' || l_handoff_type ||
                           ''', ''G'') name_prof, ' || --
                           ' pk_prof_utils.get_nickname(' || i_lang || ', ei.id_first_nurse_resp) name_nurse, ' || --
                           ' pk_grid_amb.get_responsibles_str( ' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), ''' || pk_alert_constant.g_cat_type_doc ||
                           ''', ei.id_episode, nvl(ei.id_professional, ei.sch_prof_outp_id_prof), ''' || l_handoff_type ||
                           ''', ''T'') name_prof_tooltip, ' || --
                           ' pk_grid_amb.get_responsibles_str(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), ''' ||
                           pk_alert_constant.g_cat_type_nurse || ''', ei.id_episode, ei.id_first_nurse_resp, ''' ||
                           l_handoff_type || ''', ''T'') name_nurse_tooltip, ' || --
                           ' sp.flg_state, ' || --
                           '''' || g_sysdate_char || ''' dt_server, ' || --
                           ' lpad(to_char(pk_sysdomain.get_rank(' || i_lang ||
                           ', ''SCHEDULE_OUTP.FLG_SCHED'', sp.flg_sched)), 6, ''0'') || pk_sysdomain.get_img(' ||
                           i_lang || ', ''SCHEDULE_OUTP.FLG_SCHED'', sp.flg_sched) img_sched,' || --
                           ' pk_date_utils.date_char_hour_tsz(' || i_lang || ', epis.dt_begin_tstz, ' ||
                           i_prof.institution || ', ' || i_prof.software || ') dt_efectiv, ' || --
                           ' pk_prof_utils.get_spec_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software ||
                           ') , p.id_professional , NULL, NULL) desc_speciality, ' || --
                           ' decode(drt.id_discharge_dest, '''', ' || --
                           ' decode(drt.id_dep_clin_serv, '''',' || --
                           ' decode(drt.id_institution, '''', '''', pk_translation.get_translation(' || i_lang ||
                           ', inst.code_institution)), pk_translation.get_translation(' || i_lang ||
                           ', dep.code_department)||'' - ''||' || ' pk_translation.get_translation(' || i_lang ||
                           ', cs2.code_clinical_service)), ' || ' pk_translation.get_translation(' || i_lang ||
                           ', ddn.code_discharge_dest)) disch_dest, ' || ' decode (pk_discharge_core.get_dt_admin(' ||
                           i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                           i_prof.software || '), d.id_discharge), NULL, ''N'', ''Y'') disch_admin, ' || --
                           ' pk_date_utils.to_char_insttimezone(' || i_prof.institution || ', ' || i_prof.software ||
                           ', sp.dt_target_tstz, ''YYYYMMDDHH24MISS'') dt_ord1 ' || --
                           ' FROM schedule_outp sp, ' || --
                           ' schedule s, ' || --
                           ' sch_group sg, ' || --
                           ' patient pat, ' || --
                           ' speciality spec, ' || --
                           ' clinical_service cs, ' || --
                           ' professional p, ' || --
                           ' clin_record cr, ' || --
                           ' epis_info ei, ' || --
                           ' episode epis, ' || --
                           ' discharge d, ' || --
                           ' disch_reas_dest drt, ' || --
                           ' institution inst, ' || --
                           ' department dep, ' || --
                           ' discharge_dest ddn, ' || --
                           ' clinical_service cs2, ' || --
                           ' dep_clin_serv dcs2, ' || --
                           ' pat_soc_attributes psa ' || --
                           ' WHERE s.id_instit_requested = ' || i_prof.institution || --
                           ' AND s.flg_status != ''' || g_sched_cancel || '''' || --
                           ' AND s.flg_status != ''V''' || -- g_sched_cache
                           ' AND sp.id_schedule = s.id_schedule' || --
                           ' AND sp.id_software = ' || i_prof.software || --
                           ' AND p.id_professional != ' || i_prof.id || --
                           ' AND ei.sch_prof_outp_id_prof = p.id_professional(+)' || --
                           ' AND sg.id_schedule = s.id_schedule' || --
                           ' AND pat.id_patient = sg.id_patient' || --
                           ' AND psa.id_patient (+) = pat.id_patient ' || --
                           ' AND psa.id_institution(+) = ' || i_prof.institution || --
                           ' AND cs.id_clinical_service = epis.id_cs_requested' || --
                           ' AND cr.id_patient = pat.id_patient' || --
                           ' AND cr.id_institution = ' || i_prof.institution || --
                           ' AND ei.id_schedule = s.id_schedule' || --
                           ' AND ei.id_professional = ' || i_prof.id || --
                           ' AND epis.id_episode = ei.id_episode' || --
                           ' AND epis.flg_status != ''' || g_epis_canc || '''' ||
                           ' AND epis.flg_ehr IN (''N'', ''S'') ' || --
                           ' AND spec.id_speciality(+) = p.id_speciality ' || --
                           ' AND d.id_episode = epis.id_episode' || --
                           ' AND d.dt_cancel_tstz IS NULL' || --
                           ' AND d.dt_med_tstz BETWEEN :3 AND :4 ' ||
                           ' AND drt.id_disch_reas_dest = d.id_disch_reas_dest' || --
                           ' AND inst.id_institution(+) = drt.id_institution ' || --
                           ' AND dep.id_department(+) = dcs2.id_department' || --
                           ' AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv' || --
                           ' AND cs2.id_clinical_service(+) = dcs2.id_clinical_service' || --
                           ' AND ddn.id_discharge_dest(+) = drt.id_discharge_dest' || --
                           l_where;
            
            ELSIF i_prof_cat_type = g_flg_nurse -- PT 06-08-2008
            THEN
                g_error := 'GET CURSOR 2 ' || str_sql;
                str_sql := 'SELECT * ' || --
                           ' FROM (' || --
                           '  SELECT s.id_schedule, ' || --
                           ' sg.id_patient, ' || --
                           ' cr.num_clin_record, ' || --
                           ' epis.id_episode,' || --
                           ' pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software ||
                           '), pat.id_patient, epis.id_episode, s.id_schedule) name,' || --
                           ' pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software ||
                           '), sg.id_patient, ei.id_episode,s.id_schedule) name_to_sort, ' || --                          
                           ' pk_adt.get_pat_non_disc_options(' || i_lang || ', profissional(' || i_prof.id || ',' || --
                           i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_ndo,' || --
                           ' pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_nd_icon,' || --
                           ' pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, ' || i_lang || ') gender, ' || --
                           ' pk_patient.get_pat_age(' || i_lang || ', pat.id_patient, ' || i_prof.institution || ', ' ||
                           i_prof.software || ') pat_age,' || --
                           ' pk_patphoto.get_pat_photo(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software ||
                           '), pat.id_patient, epis.id_episode, s.id_schedule) photo, ' || --
                           ' pk_hea_prv_aux.get_clin_service(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), ei.id_dep_clin_serv) cons_type,' || --
                           'pk_date_utils.date_char_hour_tsz(' || i_lang || ', sp.dt_target_tstz, ' ||
                           i_prof.institution || ', ' || i_prof.software || ') hour_target,' || --
                           ' pk_date_utils.trunc_dt_char_tsz(' || i_lang || ', sp.dt_target_tstz, ' ||
                           i_prof.institution || ', ' || i_prof.software || ') date_target,' || --
                           ' pk_prof_utils.get_name_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), p.id_professional) nick_name, ' || --
                           ' pk_grid_amb.get_responsibles_str( ' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), ''' || pk_alert_constant.g_cat_type_doc ||
                           ''', ei.id_episode, nvl(ei.id_professional, ei.sch_prof_outp_id_prof), ''' || l_handoff_type ||
                           ''', ''G'') name_prof, ' || --
                           ' pk_prof_utils.get_nickname(' || i_lang || ', ei.id_first_nurse_resp) name_nurse, ' || --
                           ' pk_grid_amb.get_responsibles_str( ' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), ''' || pk_alert_constant.g_cat_type_doc ||
                           ''', ei.id_episode, nvl(ei.id_professional, ei.sch_prof_outp_id_prof), ''' || l_handoff_type ||
                           ''', ''T'') name_prof_tooltip, ' || --
                           ' pk_grid_amb.get_responsibles_str(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software || '), ''' ||
                           pk_alert_constant.g_cat_type_nurse || ''', ei.id_episode, ei.id_first_nurse_resp, ''' ||
                           l_handoff_type || ''', ''T'') name_nurse_tooltip, ' || --
                           ' sp.flg_state, ' || --
                           ' ''' || g_sysdate_char || ''' dt_server, ' || --
                           ' lpad(to_char(pk_sysdomain.get_rank(' || i_lang ||
                           ', ''SCHEDULE_OUTP.FLG_SCHED'', sp.flg_sched)), 6, ''0'') || pk_sysdomain.get_img(' ||
                           i_lang || ', ''SCHEDULE_OUTP.FLG_SCHED'', sp.flg_sched) img_sched,' || --
                           'pk_date_utils.date_char_hour_tsz(' || i_lang || ', epis.dt_begin_tstz, ' ||
                           i_prof.institution || ', ' || i_prof.software || ') dt_efectiv, ' || --
                           ' pk_prof_utils.get_spec_signature(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software ||
                           '), p.id_professional , null, null) desc_speciality, ' || --
                           ' decode(drt.id_discharge_dest,' || ''''',' || 'decode(drt.id_dep_clin_serv,' || ''''',' ||
                           'decode(drt.id_institution, '''', '''', pk_translation.get_translation(' || i_lang ||
                           ', inst.code_institution)),' || 'pk_translation.get_translation(' || i_lang ||
                           ', dep.code_department)||'' - ''||' || 'pk_translation.get_translation(' || i_lang ||
                           ', cs2.code_clinical_service)),' || 'pk_translation.get_translation(' || i_lang ||
                           ', ddn.code_discharge_dest)) disch_dest, ' || --
                           ' decode (pk_discharge_core.get_dt_admin(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                           i_prof.institution || ',' || i_prof.software ||
                           '), d.id_discharge), NULL, ''N'', ''Y'') disch_admin, ' || --
                           ' pk_date_utils.to_char_insttimezone(' || i_prof.institution || ', ' || i_prof.software ||
                           ', sp.dt_target_tstz, ''YYYYMMDDHH24MISS'') dt_ord1 ' || --
                           ' FROM schedule_outp sp, ' || -- 
                           ' schedule s, ' || -- 
                           ' sch_group sg, ' || -- 
                           ' patient pat, ' || -- 
                           ' speciality spec, ' || -- 
                           ' dep_clin_serv dcs, ' || -- 
                           ' clinical_service cs, ' || -- 
                           ' professional p, ' || -- 
                           ' clin_record cr, ' || -- 
                           ' epis_info ei, ' || -- 
                           ' episode epis, ' || --
                           ' discharge d, ' || -- 
                           ' disch_reas_dest drt, ' || -- 
                           ' institution inst, ' || -- 
                           ' department dep, ' || -- 
                           ' discharge_dest ddn, ' || -- 
                           ' clinical_service cs2, ' || --
                           ' dep_clin_serv dcs2, ' || -- 
                           ' pat_soc_attributes psa ' || --
                           ' WHERE s.id_instit_requested = ' || i_prof.institution || --
                           ' AND s.flg_status != ''' || g_sched_cancel || '''' || --
                           ' AND s.flg_status != ''V''' || -- G_SCHED_CACHE
                           ' AND sp.id_schedule = s.id_schedule' || --
                           ' AND sp.id_software = ' || i_prof.software || --
                           straux || --
                           ' AND ei.sch_prof_outp_id_prof = p.id_professional(+)' || --
                           ' AND sg.id_schedule = s.id_schedule' || --
                           ' AND pat.id_patient = sg.id_patient' || --
                           ' AND psa.id_patient (+) = pat.id_patient ' || --
                           ' AND psa.id_institution(+) = ' || i_prof.institution || --
                           ' AND dcs.id_dep_clin_serv = s.id_dcs_requested' || --
                           ' AND cs.id_clinical_service = dcs.id_clinical_service' || --
                           ' AND cr.id_patient = pat.id_patient' || --
                           ' AND cr.id_institution = ' || i_prof.institution || --
                           ' AND ei.id_schedule = s.id_schedule' || --
                           ' AND epis.id_episode = ei.id_episode' || --
                           ' AND epis.flg_status != ''' || g_epis_canc || '''' || --
                           ' AND spec.id_speciality(+) = p.id_speciality ' || --
                           ' AND d.id_episode = epis.id_episode' || --
                           ' AND epis.flg_ehr IN (''N'', ''S'') ' || --
                           ' AND d.dt_cancel_tstz IS NULL' || --
                           ' AND trunc(current_timestamp) = trunc(nvl(d.dt_med_tstz, d.dt_nurse)) ' || --
                           ' AND drt.id_disch_reas_dest = d.id_disch_reas_dest' || --
                           ' AND inst.id_institution(+) = drt.id_institution ' || --
                           ' AND dep.id_department(+) = dcs2.id_department' || --
                           ' AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv' || --
                           ' AND cs2.id_clinical_service(+) = dcs2.id_clinical_service' || --
                           ' AND ddn.id_discharge_dest(+) = drt.id_discharge_dest' || --
                           l_where;
            END IF;
        
            str_sql := str_sql || ' ORDER BY date_target) x ' || ' WHERE rownum <= ' || l_limit;
        
            g_error := 'GET CURSOR 3 ' || str_sql;
            IF i_prof_cat_type IN (g_flg_doctor, g_flg_nutri)
            THEN
                OPEN o_pat FOR str_sql
                    USING l_day_begin, l_day_end, l_day_begin, l_day_end;
            
            ELSE
                OPEN o_pat FOR str_sql;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRIT_SCHED_TODAY', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRIT_SCHED_TODAY', o_error);
        
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_SCHED_TODAY',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_SCHED_TODAY',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_pat_crit_sched_today;

    FUNCTION get_pat_crit_sched
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE DOENTES AGENDADOS DE ACORDO COM OS CRITÉRIOS SELECCIONADOS , PARA
                    PESSOAL NÃO CLÍNICO (ADMINISTRATITVOS, TÉCNICOS, ETC.) 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                   I_ID_SYS_BTN_CRIT - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
                   I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA              
                 I_INSTIT - INSTITUIÇÃO 
                 I_EPIS_TYPE - TIPO DE CONSULTA
                   I_PROF - PROFISSIONAL 
                 I_PROF_CAT_TYPE - TIPO DE CATEGORIA DO PROFISSIONAL, TAL 
                       COMO É RETORNADA EM PK_LOGIN.GET_PROF_PREF 
                  SAIDA: O_PAT - DOENTES 
                 O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
                 O_ERROR - ERRO 
          
          CRIAÇÃO: RB 2005/04/22 
          ALTERAÇÃO: CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS 
                     ASM 2007/03/27 Devolver também os agendamentos anteriores à data actual mas que nunca foram efectivados
          
          NOTAS: 
        *********************************************************************************/
        l_where      VARCHAR2(4000);
        l_error      t_error_out;
        v_where_cond VARCHAR2(4000);
        l_count      NUMBER;
        l_limit      sys_config.desc_sys_config%TYPE;
        aux_sql1     VARCHAR2(4000);
        aux_sql2     VARCHAR2(4000);
        id_doc       sys_config.value%TYPE;
        l_continue   BOOLEAN := TRUE;
    
    BEGIN
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof); -- Nº MÁXIMO DE REGISTOS A APRESENTAR
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --LÊ CRITÉRIOS DE PESQUISA E PREENCHE CLÁUSULA WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
            
                IF NOT get_criteria_condition(i_lang,
                                              -- JS, 2007-09-07 - Timezone
                                              i_prof,
                                              i_id_sys_btn_crit(i),
                                              REPLACE(i_crit_val(i), '''', '%'),
                                              v_where_cond,
                                              l_error)
                THEN
                    o_error := l_error;
                    RAISE g_exception;
                END IF;
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        id_doc := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
    
        g_error  := 'GET aux_sql1';
        aux_sql1 := 'SELECT ID_SCHEDULE ' || 'FROM ( ' || 'SELECT SP.ID_SCHEDULE ' || --(
                    'FROM SCHEDULE_OUTP SP, SCHEDULE S, SCH_PROF_OUTP PS, SCH_GROUP SG, PATIENT PAT, DEP_CLIN_SERV DCS, ' ||
                    'SPECIALITY SPC, CLINICAL_SERVICE CS, PROFESSIONAL P, CLIN_RECORD CR, PAT_SOC_ATTRIBUTES PSA, SYS_DOMAIN SD, ' ||
                    '(SELECT DISTINCT DE.ID_DOC_TYPE, DE.FLG_STATUS, DE.ID_PATIENT, DE.NUM_DOC ' || --(
                    ' FROM DOC_EXTERNAL DE ' || ' WHERE DE.ID_DOC_TYPE = ' || id_doc || ') DE ' || --)
                    'WHERE S.ID_INSTIT_REQUESTED = :1 ' || --I_PROF.INSTITUTION||
                    ' AND S.FLG_STATUS = :20 ' || -- G_SCHED_SCHEDULED 
                    ' AND S.FLG_STATUS != ''V''' || -- G_SCHED_CACHE
                    ' AND SP.ID_SCHEDULE = S.ID_SCHEDULE' || ' AND SP.ID_SOFTWARE = :2 ' || --I_PROF.SOFTWARE||
                    ' AND PK_DATE_UTILS.TRUNC_INSTTIMEZONE(:1, :2, SP.DT_TARGET_TSTZ) >= PK_DATE_UTILS.TRUNC_INSTTIMEZONE(:1, :2, :11) ' ||
                   --I_PROF.INSTITUTION || I_PROF.SOFTWARE || I_PROF.INSTITUTION || I_PROF.SOFTWARE || L_DATE
                    ' AND PS.ID_SCHEDULE_OUTP(+) = SP.ID_SCHEDULE_OUTP' ||
                    ' AND PS.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+)' || ' AND SG.ID_SCHEDULE = S.ID_SCHEDULE' ||
                    ' AND PAT.ID_PATIENT = SG.ID_PATIENT' || ' AND DCS.ID_DEP_CLIN_SERV = S.ID_DCS_REQUESTED' ||
                    ' AND CS.ID_CLINICAL_SERVICE = DCS.ID_CLINICAL_SERVICE' || ' AND CR.ID_PATIENT = PAT.ID_PATIENT' ||
                    ' AND CR.ID_INSTITUTION = :1 ' || --||I_PROF.INSTITUTION||
                    ' AND SPC.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' ||
                    ' AND DE.ID_DOC_TYPE(+) = :9' || ' AND DE.FLG_STATUS(+) = :10' || --ID_DOC || g_doc_active
                    ' AND PSA.ID_PATIENT(+) = PAT.ID_PATIENT ' || ' AND PSA.ID_INSTITUTION(+) = :1 ' ||
                    ' AND SD.CODE_DOMAIN = ''SCHEDULE_OUTP.FLG_SCHED''' || ' AND SD.VAL = SP.FLG_SCHED' ||
                    ' and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                    ' AND SD.ID_LANGUAGE = :15 ' || l_where || ' )';
    
        g_error  := 'GET aux_sql2';
        aux_sql2 := 'SELECT SP.ID_SCHEDULE ' ||
                    'FROM SCHEDULE_OUTP SP, SCHEDULE S, SCH_PROF_OUTP PS, SCH_GROUP SG, PATIENT PAT, DEP_CLIN_SERV DCS, ' ||
                    'SPECIALITY SPC, CLINICAL_SERVICE CS, PROFESSIONAL P, CLIN_RECORD CR, PAT_SOC_ATTRIBUTES PSA, SYS_DOMAIN SD, ' ||
                    '(SELECT DISTINCT DE.ID_DOC_TYPE, DE.FLG_STATUS, DE.ID_PATIENT, DE.NUM_DOC ' || --(
                    ' FROM DOC_EXTERNAL DE ' || ' WHERE DE.ID_DOC_TYPE = ' || id_doc || ') DE ' || --)
                    'WHERE S.ID_INSTIT_REQUESTED = :1 ' || --I_PROF.INSTITUTION||
                    ' AND S.FLG_STATUS = :20 ' || -- G_SCHED_SCHEDULED 
                    ' AND S.FLG_STATUS != ''V''' || -- G_SCHED_CACHE
                    ' AND SP.ID_SCHEDULE = S.ID_SCHEDULE' || ' AND SP.FLG_STATE = :20 ' || --g_sched_scheduled,
                    ' AND SP.ID_SOFTWARE = :2 ' || --I_PROF.SOFTWARE||
                    ' AND PK_DATE_UTILS.TRUNC_INSTTIMEZONE(:1, :2, SP.DT_TARGET_TSTZ) < PK_DATE_UTILS.TRUNC_INSTTIMEZONE(:1, :2, :11 ) ' ||
                    ' AND PS.ID_SCHEDULE_OUTP(+) = SP.ID_SCHEDULE_OUTP' ||
                    ' AND PS.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+)' || ' AND SG.ID_SCHEDULE = S.ID_SCHEDULE' ||
                    ' AND PAT.ID_PATIENT = SG.ID_PATIENT' || ' AND DCS.ID_DEP_CLIN_SERV = S.ID_DCS_REQUESTED' ||
                    ' AND CS.ID_CLINICAL_SERVICE = DCS.ID_CLINICAL_SERVICE' || ' AND CR.ID_PATIENT = PAT.ID_PATIENT' ||
                    ' AND CR.ID_INSTITUTION = :1 ' || --||I_PROF.INSTITUTION||
                    ' AND SPC.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' ||
                    ' AND DE.ID_DOC_TYPE(+) = :9' || ' AND DE.FLG_STATUS(+) = :10 ' || --id_doc, g_doc_active,
                    ' AND PSA.ID_PATIENT(+) = PAT.ID_PATIENT ' || ' AND PSA.ID_INSTITUTION(+) = :1 ' ||
                    ' AND SD.CODE_DOMAIN = ''SCHEDULE_OUTP.FLG_SCHED''' || ' AND SD.VAL = SP.FLG_SCHED' ||
                    ' and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                    ' AND SD.ID_LANGUAGE = :15 ' || l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE - COUNT()';
        EXECUTE IMMEDIATE 'SELECT count(1) FROM ( (' || aux_sql1 || ') UNION ALL (' || aux_sql2 ||
                          ') ) WHERE ROWNUM <= :l_limit + 1'
            INTO l_count
            USING i_prof.institution, g_sched_scheduled, i_prof.software, i_prof.institution, i_prof.software, i_prof.institution, i_prof.software, current_timestamp, i_prof.institution, id_doc, g_doc_active, i_prof.institution, i_lang,
        --
        i_prof.institution, g_sched_scheduled, g_sched_scheduled, i_prof.software, i_prof.institution, i_prof.software, i_prof.institution, i_prof.software, current_timestamp, i_prof.institution, id_doc, g_doc_active, i_prof.institution, i_lang, l_limit;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_continue
        THEN
            g_error  := 'GET CURSOR aux_sql1';
            aux_sql1 := 'SELECT * ' || 'FROM ( ' ||
                        'SELECT S.ID_SCHEDULE,epis.id_episode, SG.ID_PATIENT, CR.NUM_CLIN_RECORD,' ||
                       
                        ' PK_PATIENT.GET_PAT_NAME(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software || '), pat.ID_PATIENT, null, s.id_schedule) name,' || --
                        ' pk_patient.get_pat_name_to_sort(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software ||
                        ')  , sg.id_patient, null,s.id_schedule) name_to_sort,  ' || --                       
                        ' PK_ADT.GET_PAT_NON_DISC_OPTIONS(' || i_lang || ',profissional(' || i_prof.id || ',' || --
                        i_prof.institution || ',' || i_prof.software || '), pat.ID_PATIENT) pat_ndo,' || --
                        ' PK_ADT.GET_PAT_NON_DISCLOSURE_ICON(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software || '), pat.ID_PATIENT) pat_nd_icon,' ||
                       
                        ' pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, ' || i_lang ||
                        ') gender, PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.ID_PATIENT, ' || i_prof.institution || ', ' ||
                        i_prof.software || ') PAT_AGE,' || 'PK_PATPHOTO.GET_PAT_PHOTO(' || i_lang || ', profissional(' ||
                        i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                        '), PAT.ID_PATIENT, null, s.id_schedule) PHOTO, ' || 'PK_TRANSLATION.GET_TRANSLATION(' ||
                        i_lang || ', CS.CODE_CLINICAL_SERVICE) CONS_TYPE,' || 'PK_DATE_UTILS.DATE_CHAR_HOUR_TSZ(' ||
                        i_lang || ', SP.DT_TARGET_TSTZ, ' || i_prof.institution || ', ' || i_prof.software ||
                        ') HOUR_TARGET,' || 'PK_DATE_UTILS.TRUNC_DT_CHAR_TSZ(' || i_lang || ', SP.DT_TARGET_TSTZ, ' ||
                        i_prof.institution || ', ' || i_prof.software || ') DATE_TARGET,' ||
                        'pk_prof_utils.get_name_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software || '), p.ID_PROFESSIONAL) NICK_NAME,' ||
                        'SP.FLG_STATE,' || '''' || g_sysdate_char || ''' DT_SERVER,' ||
                        'LPAD(TO_CHAR(SD.RANK), 6, ''0'')||SD.IMG_NAME IMG_SCHED,' ||
                        'pk_prof_utils.get_spec_signature(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software ||
                        '), p.ID_PROFESSIONAL , null, null) DESC_SPECIALITY, ' ||
                        ' PK_DATE_UTILS.TO_CHAR_INSTTIMEZONE(' || i_prof.institution || ', ' || i_prof.software ||
                        ', SP.DT_TARGET_TSTZ, ''YYYYMMDDHH24MISS'') DT_ORD1, ' || ' pk_adt.is_contact(' || i_lang ||
                        ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                        '), pat.id_patient) flg_contact ' ||
                        'FROM SCHEDULE_OUTP SP, SCHEDULE S, SCH_PROF_OUTP PS, SCH_GROUP SG, PATIENT PAT, DEP_CLIN_SERV DCS, ' ||
                        '  epis_info ei,  episode epis, ' || --
                        'SPECIALITY SPC, CLINICAL_SERVICE CS, PROFESSIONAL P, CLIN_RECORD CR, PAT_SOC_ATTRIBUTES PSA, SYS_DOMAIN SD, ' ||
                        '(SELECT DISTINCT DE.ID_DOC_TYPE, DE.FLG_STATUS, DE.ID_PATIENT, DE.NUM_DOC ' ||
                        ' FROM DOC_EXTERNAL DE ' || ' WHERE DE.ID_DOC_TYPE = ' || id_doc || ') DE ' ||
                        'WHERE S.ID_INSTIT_REQUESTED = ' || i_prof.institution || ' AND S.FLG_STATUS = ''' ||
                        g_sched_scheduled || '''' || --------------- alterado ss: 2006/07/24 
                        ' AND S.FLG_STATUS != ''V''' || -- G_SCHED_CACHE
                        '   AND s.id_schedule = ei.id_schedule ' || --
                        '   AND ei.id_episode = epis.id_episode ' || --
                        ' AND SP.ID_SCHEDULE = S.ID_SCHEDULE' || ' AND SP.ID_SOFTWARE = ' || i_prof.software ||
                        ' AND PK_DATE_UTILS.TRUNC_INSTTIMEZONE(' || i_prof.institution || ', ' || i_prof.software ||
                        ', SP.DT_TARGET_TSTZ) >= PK_DATE_UTILS.TRUNC_INSTTIMEZONE(' || i_prof.institution || ', ' ||
                        i_prof.software || ', current_timestamp)' ||
                        ' AND PS.ID_SCHEDULE_OUTP(+) = SP.ID_SCHEDULE_OUTP' ||
                        ' AND PS.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+)' || ' AND SG.ID_SCHEDULE = S.ID_SCHEDULE' ||
                        ' AND PAT.ID_PATIENT = SG.ID_PATIENT' || ' AND DCS.ID_DEP_CLIN_SERV = S.ID_DCS_REQUESTED' ||
                        ' AND CS.ID_CLINICAL_SERVICE = DCS.ID_CLINICAL_SERVICE' ||
                        ' AND CR.ID_PATIENT = PAT.ID_PATIENT' || ' AND CR.ID_INSTITUTION = ' || i_prof.institution ||
                       --  ' AND S.ID_SCHEDULE NOT IN (SELECT EI.ID_SCHEDULE FROM EPIS_INFO EI WHERE EI.ID_SCHEDULE IS NOT NULL)' ||
                        ' AND SPC.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' ||
                        ' AND DE.ID_DOC_TYPE(+) = ' || id_doc || ' AND DE.FLG_STATUS(+) = ''' || g_doc_active || '''' ||
                        ' AND PSA.ID_PATIENT(+) = PAT.ID_PATIENT ' || ' AND PSA.ID_INSTITUTION(+) = ' ||
                        i_prof.institution || ' AND SD.CODE_DOMAIN = ''SCHEDULE_OUTP.FLG_SCHED''' ||
                        ' and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                        ' AND SD.VAL = SP.FLG_SCHED' || ' AND SD.ID_LANGUAGE = ' || i_lang || l_where;
        
            -- ASM 2007/03/27: Devolver também os agendamentos anteriores à data actual mas que nunca foram efectivados
            g_error  := 'GET CURSOR aux_sql2';
            aux_sql2 := 'SELECT S.ID_SCHEDULE, epis.id_episode, SG.ID_PATIENT, CR.NUM_CLIN_RECORD,' ||
                        ' PK_PATIENT.GET_PAT_NAME(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software || '), pat.ID_PATIENT, null, s.id_schedule) name,' || --
                        ' pk_patient.get_pat_name_to_sort(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software ||
                        ')  , sg.id_patient, null,s.id_schedule) name_to_sort,  ' || --                       
                        ' PK_ADT.GET_PAT_NON_DISC_OPTIONS(' || i_lang || ',profissional(' || i_prof.id || ',' || --
                        i_prof.institution || ',' || i_prof.software || '), pat.ID_PATIENT) pat_ndo,' || --
                        ' PK_ADT.GET_PAT_NON_DISCLOSURE_ICON(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software || '), pat.ID_PATIENT) pat_nd_icon,' ||
                        ' pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, ' || i_lang ||
                        ') gender, PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.ID_PATIENT, ' || i_prof.institution || ', ' ||
                        i_prof.software || ') PAT_AGE,' || 'PK_PATPHOTO.GET_PAT_PHOTO(' || i_lang || ', profissional(' ||
                        i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                        '), PAT.ID_PATIENT, null, s.id_schedule) PHOTO, ' || 'PK_TRANSLATION.GET_TRANSLATION(' ||
                        i_lang || ', CS.CODE_CLINICAL_SERVICE) CONS_TYPE,' || 'PK_DATE_UTILS.DATE_CHAR_HOUR_TSZ(' ||
                        i_lang || ', SP.DT_TARGET_TSTZ, ' || i_prof.institution || ', ' || i_prof.software ||
                        ') HOUR_TARGET,' || 'PK_DATE_UTILS.TRUNC_DT_CHAR_TSZ(' || i_lang || ', SP.DT_TARGET_TSTZ, ' ||
                        i_prof.institution || ', ' || i_prof.software || ') DATE_TARGET,' ||
                        'pk_prof_utils.get_name_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software || '), p.ID_PROFESSIONAL) NICK_NAME, ' ||
                        'SP.FLG_STATE,' || '''' || g_sysdate_char || ''' DT_SERVER,' ||
                        'LPAD(TO_CHAR(SD.RANK), 6, ''0'')||SD.IMG_NAME IMG_SCHED,' ||
                        'pk_prof_utils.get_spec_signature(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software ||
                        '), p.ID_PROFESSIONAL , null, null) DESC_SPECIALITY, ' ||
                        ' PK_DATE_UTILS.TO_CHAR_INSTTIMEZONE(' || i_prof.institution || ', ' || i_prof.software ||
                        ', SP.DT_TARGET_TSTZ, ''YYYYMMDDHH24MISS'') DT_ORD1 , ' || ' pk_adt.is_contact(' || i_lang ||
                        ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                        '), pat.id_patient) flg_contact ' ||
                        'FROM SCHEDULE_OUTP SP, SCHEDULE S, SCH_PROF_OUTP PS, SCH_GROUP SG, PATIENT PAT, DEP_CLIN_SERV DCS, ' ||
                        '  epis_info ei,  episode epis, ' || --
                        'SPECIALITY SPC, CLINICAL_SERVICE CS, PROFESSIONAL P, CLIN_RECORD CR, PAT_SOC_ATTRIBUTES PSA, SYS_DOMAIN SD, ' ||
                        '(SELECT DISTINCT DE.ID_DOC_TYPE, DE.FLG_STATUS, DE.ID_PATIENT, DE.NUM_DOC ' ||
                        ' FROM DOC_EXTERNAL DE ' || ' WHERE DE.ID_DOC_TYPE = ' || id_doc || ') DE ' ||
                        'WHERE S.ID_INSTIT_REQUESTED = ' || i_prof.institution || ' AND S.FLG_STATUS = ''' ||
                        g_sched_scheduled || '''' || --------------- alterado ss: 2006/07/24 
                        ' AND SP.ID_SCHEDULE = S.ID_SCHEDULE' || ' AND SP.FLG_STATE = ''' || g_sched_scheduled || '''' ||
                        ' AND S.FLG_STATUS != ''V''' || -- G_SCHED_CACHE
                        '   AND s.id_schedule = ei.id_schedule ' || --
                        '   AND ei.id_episode = epis.id_episode ' || --                        
                        ' AND SP.ID_SOFTWARE = ' || i_prof.software || ' AND PK_DATE_UTILS.TRUNC_INSTTIMEZONE(' ||
                        i_prof.institution || ', ' || i_prof.software ||
                        ', SP.DT_TARGET_TSTZ) < PK_DATE_UTILS.TRUNC_INSTTIMEZONE(' || i_prof.institution || ', ' ||
                        i_prof.software || ', current_timestamp) ' ||
                        ' AND PS.ID_SCHEDULE_OUTP(+) = SP.ID_SCHEDULE_OUTP' ||
                        ' AND PS.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+)' || ' AND SG.ID_SCHEDULE = S.ID_SCHEDULE' ||
                        ' AND PAT.ID_PATIENT = SG.ID_PATIENT' || ' AND DCS.ID_DEP_CLIN_SERV = S.ID_DCS_REQUESTED' ||
                        ' AND CS.ID_CLINICAL_SERVICE = DCS.ID_CLINICAL_SERVICE' ||
                        ' AND CR.ID_PATIENT = PAT.ID_PATIENT' || ' AND CR.ID_INSTITUTION = ' || i_prof.institution ||
                        ' AND SPC.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || ' AND DE.ID_PATIENT(+) = PAT.ID_PATIENT' ||
                        ' AND DE.ID_DOC_TYPE(+) = ' || id_doc || ' AND DE.FLG_STATUS(+) = ''' || g_doc_active || '''' ||
                        ' AND PSA.ID_PATIENT(+) = PAT.ID_PATIENT ' || ' AND PSA.ID_INSTITUTION(+) = ' ||
                        i_prof.institution || ' AND SD.CODE_DOMAIN = ''SCHEDULE_OUTP.FLG_SCHED''' ||
                        ' and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                        ' AND SD.VAL = SP.FLG_SCHED' || ' AND SD.ID_LANGUAGE = ' || i_lang || l_where || ' ) ';
        
            g_error := 'GET CURSOR';
            OPEN o_pat FOR 'SELECT x.* FROM ( ' || aux_sql1 || ' UNION ALL ' || aux_sql2 || ') x WHERE ROWNUM <= ' || l_limit || ' ORDER BY DATE_TARGET';
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRIT_SCHED', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRIT_SCHED', o_error);
        
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_SCHED',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_SCHED',
                                              'S',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
        
    END get_pat_crit_sched;

    FUNCTION get_pat_crit_sched_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE DOENTES AGENDADOS DE ACORDO COM OS CRITÉRIOS SELECCIONADOS , PARA
                    PESSOAL CLÍNICO (MÉDICOS E ENFERMEIROS)
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                   I_ID_CRITERIA - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
                   I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA              
                 I_INSTIT - INSTITUIÇÃO 
                 I_EPIS_TYPE - TIPO DE CONSULTA
                 I_DT - DATA A PESQUISAR. SE FOR NULL ASSUME A DATA DE SISTEMA
                   I_PROF - PROFISSIONAL 
                 I_PROF_CAT_TYPE - TIPO DE CATEGORIA DO PROFISSIONAL, TAL 
                       COMO É RETORNADA EM PK_LOGIN.GET_PROF_PREF 
                  SAIDA: O_PAT - DOENTES 
                 O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
                 O_ERROR - ERRO 
          
          CRIAÇÃO: RB 2005/05/04 
          ALTERAÇÃO: CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS 
               ASM 2006/12/27 INCLUIR NÃO SÓ OS EPISÓDIOS COM ALTA ADMINISTRATIVA, MAS TAMBÉM OS COM ALTA MÉDICA E OS EPISÓDIOS 
                            QUE FORAM FECHADOS AUTOMATICAMENTE 
                                    LIGAÇÃO À TABELA DOC_EXTERNAL PARA OS DOCUMENTOS, EM VEZ DA PAT_DOC 
                      ASM 2007/03/27 Devolver também os agendamentos anteriores à data actual mas que nunca foram efectivados
               RL 2008/03/25 Outer join com a tab clin_record
          NOTAS: 
        *********************************************************************************/
    
        l_where        VARCHAR2(4000);
        v_where_cond   VARCHAR2(4000);
        l_count        NUMBER;
        l_limit        sys_config.desc_sys_config%TYPE;
        aux_sql1       VARCHAR2(32767);
        l_continue     BOOLEAN := TRUE;
        l_date         TIMESTAMP WITH TIME ZONE;
        l_nurse_et     sys_config.value%TYPE;
        l_handoff_type sys_config.value%TYPE;
        l_et_access    table_number := table_number();
    
    BEGIN
    
        g_error        := 'DATES';
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'INIT get_pat_crit_sched_clin';
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof); -- Nº MÁXIMO DE REGISTOS A APRESENTAR
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := NULL;
    
        g_error := 'LOOP';
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
        
            --LÊ CRITÉRIOS DE PESQUISA E PREENCHE CLÁUSULA WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
                g_error := 'GET_CRIT_COND';
                IF NOT get_criteria_condition(i_lang,
                                              -- JS, 2007-09-07 - Timezone
                                              i_prof,
                                              i_id_sys_btn_crit(i),
                                              REPLACE(i_crit_val(i), '''', '%'),
                                              v_where_cond,
                                              o_error)
                THEN
                    RAISE g_exception;
                END IF;
                g_error := 'WHERE';
                l_where := l_where || v_where_cond;
            END IF;
        
        END LOOP;
    
        l_date := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL);
    
        l_nurse_et := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof.institution, i_prof.software);
    
        g_error     := 'CALL get_epis_type_access';
        l_et_access := get_epis_type_access(i_prof => i_prof, i_grp_inst => table_number(i_prof.institution));
    
        g_error  := 'GET COUNT aux_sql1';
        aux_sql1 := 'SELECT sp.id_schedule ' || --
                    '  FROM schedule_outp sp, ' || --
                    '       schedule s, ' || --
                    '       sch_prof_outp ps, ' || --
                    '       sch_group sg, ' || --
                    '       patient pat, ' || --
                    '       dep_clin_serv dcs, ' || --
                    '       clinical_service cs, ' || --
                    '       clin_record cr, ' || --
                    '       (SELECT /*+opt_estimate(table t rows=1)*/ t.column_value id_epis_type ' || --
                    '          FROM TABLE(:l_et_access) t) eta, ' || --
                    '       epis_info ei, ' || --
                    '       episode epis, ' || --
                    '       professional p' || --
                    ' WHERE s.id_instit_requested = :i_prof_institution ' || --
                    '   AND s.id_schedule = ei.id_schedule ' || --
                    '   AND ei.id_episode = epis.id_episode ' || --
                    '   AND sp.id_schedule = s.id_schedule ' || --
                    '   AND ps.id_schedule_outp(+) = sp.id_schedule_outp ' || --
                    '   AND sg.id_schedule = s.id_schedule ' || --
                    '   AND pat.id_patient = sg.id_patient ' || --
                    '   AND dcs.id_dep_clin_serv = s.id_dcs_requested ' || --
                    '   AND cs.id_clinical_service = dcs.id_clinical_service ' || --
                    '   AND cr.id_patient(+) = pat.id_patient ' || --
                    '   AND cr.id_institution(+) = :i_prof_institution ' || --
                    '   AND cr.flg_status(+) = ''A'' ' || --
                    '   AND S.FLG_STATUS not in (''V'',''C'')' || -- G_SCHED_CACHE
                    '   AND (eta.id_epis_type IN (sp.id_epis_type, 0))' || --
                    '   AND pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr) = :g_sched_scheduled ' || --  
                    '   AND ps.id_professional = p.id_professional ' || --
                    l_where || --
                    ' UNION SELECT s.id_schedule ' || --
                    '  FROM rehab_schedule rs, ' || --
                    '       schedule s, ' || --
                    '       rehab_sch_need rsn, ' || --
                    '       rehab_presc rp, ' || --
                    '       patient pat, ' || --
                    '       dep_clin_serv dcs, ' || --
                    '       clinical_service cs, ' || --
                    '       clin_record cr, ' || --
                    '       episode epis, ' || --
                    '       epis_info ei, ' || --
                    '       professional p,' || --
                    '       schedule_outp sp,' || --
                    '       (SELECT re.id_epis_type, re.id_institution from rehab_environment re WHERE re.id_rehab_environment IN (SELECT rep.id_rehab_environment
                                FROM rehab_environment_prof rep
                               WHERE rep.id_professional = :i_prof_id)) r ' || --
                    ' WHERE s.id_instit_requested = :i_prof_institution ' || --
                    '   AND s.id_schedule = rs.id_schedule ' || --
                    '   AND rsn.id_rehab_sch_need = rs.id_rehab_sch_need ' || --
                    '   AND rp.id_rehab_sch_need = rsn.id_rehab_sch_need ' || --
                    '   AND epis.id_episode = rsn.id_episode_origin ' || --
                    '   AND ei.id_episode = epis.id_episode ' || --
                    '   AND r.id_epis_type = epis.id_epis_type ' || -- 
                    '   AND r.id_institution = :i_prof_institution ' || --
                    '   AND sp.id_schedule(+) = s.id_schedule ' || --
                    '   AND pat.id_patient = epis.id_patient ' || --
                    '   AND dcs.id_dep_clin_serv = s.id_dcs_requested ' || --
                    '   AND cs.id_clinical_service = dcs.id_clinical_service ' || --
                    '   AND cr.id_patient(+) = pat.id_patient ' || --
                    '   AND cr.id_institution(+) = :i_prof_institution ' || --
                    '   AND cr.flg_status(+) = ''A'' ' || --
                    '   AND rs.flg_status = ''A'' ' || --
                    '   AND s.flg_status NOT IN (''V'',''C'')' || -- 
                    '   AND rp.flg_status NOT IN (''C'',''D'')' || --
                    '   AND rsn.id_resp_professional(+) = p.id_professional ' || --
                    l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE 'SELECT count(1) FROM ( ' || aux_sql1 || ') WHERE rownum <= :l_limit + 1'
            INTO l_count
            USING --
        l_et_access, i_prof.institution, i_prof.institution, g_sched_scheduled, i_prof.id, i_prof.institution, i_prof.institution, i_prof.institution, l_limit;
    
        g_error := 'count>l_limit';
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        g_error := 'count=0';
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_continue
        THEN
            g_error  := 'GET aux_sql1';
            aux_sql1 := 'SELECT s.id_schedule, ' || --
                        '       epis.id_episode, ' || --
                        '       sg.id_patient, ' || --
                        '       cr.num_clin_record, ' || --
                        '       (SELECT pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) FROM dual) name, ' || --
                        '       (SELECT pk_patient.get_pat_name_to_sort(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) FROM dual) name_to_sort, ' || --                        
                        '       (SELECT pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) FROM dual) pat_ndo, ' || --
                        '       (SELECT pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) FROM dual) pat_nd_icon, ' || --
                        '       (SELECT pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, :i_lang)FROM dual) gender, ' || --
                        '       (SELECT pk_patient.get_pat_age(:i_lang, pat.id_patient, :i_prof_institution, :i_prof_software) FROM dual) pat_age, ' || --
                        '       (SELECT pk_patphoto.get_pat_photo(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) FROM dual) photo, ' || --
                        '       (SELECT pk_hea_prv_aux.get_clin_service(:i_lang, :i_prof, ei.id_dep_clin_serv) FROM dual) cons_type, ' || --
                        '       (SELECT pk_date_utils.date_char_hour_tsz(:i_lang, s.dt_begin_tstz, :i_prof_institution, :i_prof_software) FROM dual) hour_target, ' || --
                        '       (SELECT pk_date_utils.trunc_dt_char_tsz(:i_lang, s.dt_begin_tstz, :i_prof_institution, :i_prof_software) FROM dual) date_target, ' || --
                        '       (SELECT pk_prof_utils.get_name_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software || '), ps.id_professional) FROM dual) nick_name, ' || --
                        '       sp.flg_state flg_state, ' || --
                        '       :g_sysdate_char dt_server, ' || --
                        '       lpad(to_char(sd.rank), 6, ''0'') || sd.img_name img_sched, ' || --
                        '       NULL desc_speciality, ' || --
                        '       pk_date_utils.to_char_insttimezone(:i_prof_institution, :i_prof_software, s.dt_begin_tstz, ''YYYYMMDDHH24MISS'') dt_ord1, ' || --
                        '       pk_adt.is_contact(:i_lang,:i_prof, pat.id_patient) flg_contact, ' || --
                        '       :l_count count,' || --
                        '       decode(:i_prof_software, 312, decode(epis.id_epis_type, 50, pk_hhc_core.get_id_hhc_req_by_epis(epis.id_episode))) id_epis_hhc_req' ||
                        '  FROM schedule_outp sp, ' || --
                        '       schedule s, ' || --
                        '       sch_prof_outp ps, ' || --
                        '       sch_group sg, ' || --
                        '       patient pat, ' || --
                        '       dep_clin_serv dcs, ' || --
                        '       clinical_service cs, ' || --
                        '       clin_record cr, ' || --
                        '       sys_domain sd, ' || --
                        '       (SELECT /*+opt_estimate(table t rows=1)*/ t.column_value id_epis_type ' || --
                        '          FROM TABLE(:l_et_access) t) eta, ' || --
                        '       epis_info ei, ' || --
                        '       episode epis,' || --
                        '       professional p ' || --
                        ' WHERE s.id_instit_requested = :i_prof_institution ' || --
                        '   AND s.id_schedule = ei.id_schedule ' || --
                        '   AND ei.id_episode = epis.id_episode ' || --
                        '   AND sp.id_schedule = s.id_schedule ' || --
                        '   AND s.flg_statuS NOT IN (''V'',''C'')' || -- G_SCHED_CACHE
                        '   AND ps.id_schedule_outp(+) = sp.id_schedule_outp ' || --
                        '   AND sg.id_schedule = s.id_schedule ' || --
                        '   AND pat.id_patient = sg.id_patient ' || --
                        '   AND dcs.id_dep_clin_serv = s.id_dcs_requested ' || --
                        '   AND cs.id_clinical_service = dcs.id_clinical_service ' || --
                        '   AND cr.id_patient(+) = pat.id_patient ' || --
                        '   AND cr.id_institution(+) = :i_prof_institution ' || --
                        '   AND cr.flg_status(+) = ''A'' ' || --
                        '   AND (eta.id_epis_type IN (sp.id_epis_type, 0))' || --
                        '   AND sd.code_domain = decode(sp.id_epis_type, :l_nurse_et, ''SCHEDULE_OUTP.FLG_NURSE_ACTION'', ''SCHEDULE_OUTP.FLG_STATE'') ' || --
                        '   and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                        '   AND sd.val = decode(sp.id_epis_type, :l_nurse_et, ''N'', (select pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr) from dual))' || --
                        '   AND sd.id_language = :i_lang ' || --
                        '   AND pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr) = :g_sched_scheduled ' || --
                        '   AND ps.id_professional = p.id_professional ' || --
                        l_where || --
                        ' UNION SELECT s.id_schedule, ' || --
                        '       epis.id_episode, ' || --
                        '       epis.id_patient, ' || --
                        '       cr.num_clin_record, ' || --
                        '       (SELECT pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) FROM dual) name, ' || --
                        '       (SELECT pk_patient.get_pat_name_to_sort(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) FROM dual) name_to_sort, ' || --                        
                        '       (SELECT pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) FROM dual) pat_ndo, ' || --
                        '       (SELECT pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) FROM dual) pat_nd_icon, ' || --
                        '       (SELECT pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, :i_lang) FROM dual) gender, ' || --
                        '       (SELECT pk_patient.get_pat_age(:i_lang, pat.id_patient, :i_prof_institution, :i_prof_software) FROM dual) pat_age, ' || --
                        '       (SELECT pk_patphoto.get_pat_photo(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) FROM dual) photo, ' || --
                        '       (SELECT pk_hea_prv_aux.get_clin_service(:i_lang, :i_prof, ei.id_dep_clin_serv) FROM dual) cons_type, ' || --
                        '       (SELECT pk_date_utils.date_char_hour_tsz(:i_lang, s.dt_begin_tstz, :i_prof_institution, :i_prof_software) FROM dual) hour_target, ' || --
                        '       (SELECT pk_date_utils.trunc_dt_char_tsz(:i_lang, s.dt_begin_tstz, :i_prof_institution, :i_prof_software) FROM dual) date_target, ' || --
                        '       (SELECT pk_prof_utils.get_name_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                        i_prof.institution || ',' || i_prof.software ||
                        '), rsn.id_resp_professional) FROM dual) nick_name,' || --
                        '       ''S'' flg_state, ' || --
                        '       :g_sysdate_char dt_server, ' || --
                        '       lpad(to_char(sd.rank), 6, ''0'') || sd.img_name img_sched, ' || --
                        '       NULL desc_speciality, ' || --
                        '       pk_date_utils.to_char_insttimezone(:i_prof_institution, :i_prof_software, s.dt_begin_tstz, ''YYYYMMDDHH24MISS'') dt_ord1, ' || --
                        '       pk_adt.is_contact(:i_lang,:i_prof, pat.id_patient) flg_contact, ' || --
                        '       :l_count count,' || --
                        '       decode(:i_prof_software, 312, decode(epis.id_epis_type, 50, pk_hhc_core.get_id_hhc_req_by_epis(epis.id_episode))) id_epis_hhc_req' ||
                        '  FROM rehab_schedule rs, ' || --
                        '       schedule s, ' || --
                        '       rehab_sch_need rsn, ' || --
                        '       rehab_presc rp, ' || --
                        '       patient pat, ' || --
                        '       dep_clin_serv dcs, ' || --
                        '       clinical_service cs, ' || --
                        '       clin_record cr, ' || --
                        '       sys_domain sd, ' || --
                        '       professional p,' || --
                        '       schedule_outp sp,' || --
                        '       episode epis, ' || --
                        '       epis_info ei, ' || --
                        '       (SELECT re.id_epis_type, re.id_institution from rehab_environment re WHERE re.id_rehab_environment IN (SELECT rep.id_rehab_environment
                                FROM rehab_environment_prof rep
                               WHERE rep.id_professional = :i_prof_id)) r ' || --
                        ' WHERE s.id_instit_requested = :i_prof_institution ' || --
                        '   AND s.id_schedule = rs.id_schedule ' || --
                        '   AND rsn.id_rehab_sch_need = rs.id_rehab_sch_need ' || --
                        '   AND rp.id_rehab_sch_need = rsn.id_rehab_sch_need ' || --
                        '   AND epis.id_episode = rsn.id_episode_origin ' || --
                        '   AND ei.id_episode = epis.id_episode ' || --
                        '   AND r.id_epis_type = epis.id_epis_type ' || -- 
                        '   AND r.id_institution = :i_prof_institution ' || --
                        '   AND sp.id_schedule(+) = s.id_schedule ' || --
                        '   AND pat.id_patient = epis.id_patient ' || --
                        '   AND dcs.id_dep_clin_serv = s.id_dcs_requested ' || --
                        '   AND cs.id_clinical_service = dcs.id_clinical_service ' || --
                        '   AND cr.id_patient(+) = pat.id_patient ' || --
                        '   AND cr.id_institution(+) = :i_prof_institution ' || --
                        '   AND cr.flg_status(+) = ''A'' ' || --
                        '   AND sd.code_domain = decode(epis.id_epis_type, :l_nurse_et, ''SCHEDULE_OUTP.FLG_NURSE_ACTION'', ''SCHEDULE_OUTP.FLG_STATE'') ' || --
                        '   and sd.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                        '   AND sd.val = decode(epis.id_epis_type, :l_nurse_et, ''N'', (SELECT pk_grid.get_schedule_real_state(''A'', epis.flg_ehr) FROM dual))' || --
                        '   AND sd.id_language = :i_lang ' || --
                        '   AND rs.flg_status = ''A'' ' || --
                        '   AND s.flg_status NOT IN (''V'',''C'')' || -- 
                        '   AND rp.flg_status NOT IN (''C'',''D'')' || --
                        '   AND rsn.id_resp_professional(+) = p.id_professional ' || --
                        l_where;
        
            g_error := 'GET CURSOR o_pat';
            OPEN o_pat FOR ' SELECT x.*, pk_hand_off_api.get_resp_icons(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ', ' || i_prof.software || '), null,''' || l_handoff_type || ''') ' || '  resp_icon FROM (SELECT DISTINCT * FROM ( ' || aux_sql1 || ' )) x WHERE rownum <= :l_limit ORDER BY dt_ord1 DESC'
                USING --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang,
                      i_lang,
                      i_prof.institution,
                      i_prof.software,
                      i_lang, --
                      i_prof, --
                      i_lang,
                      i_prof,
                      i_lang,
                      i_prof.institution,
                      i_prof.software,
                      i_lang,
                      i_prof.institution,
                      i_prof.software,
                      g_sysdate_char,
                      i_prof.institution,
                      i_prof.software,
                      i_lang,
                      i_prof,
                      l_count,
                      i_prof.software,
                      l_et_access,
                      i_prof.institution,
                      i_prof.institution,
                      l_nurse_et,
                      l_nurse_et,
                      i_lang, --
                      g_sched_scheduled, --
                      i_lang, -- union
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_lang,
                      i_lang,
                      i_prof.institution,
                      i_prof.software,
                      i_lang, --
                      i_prof, --
                      i_lang,
                      i_prof,
                      i_lang,
                      i_prof.institution,
                      i_prof.software,
                      i_lang,
                      i_prof.institution,
                      i_prof.software,
                      g_sysdate_char,
                      i_prof.institution,
                      i_prof.software,
                      i_lang,
                      i_prof,
                      l_count,
                      i_prof.software, --
                      i_prof.id,
                      i_prof.institution,
                      i_prof.institution,
                      i_prof.institution,
                      l_nurse_et,
                      l_nurse_et,
                      i_lang,
                      l_limit;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRIT_SCHED_CLIN', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRIT_SCHED_CLIN', o_error);
        
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_SCHED_CLIN',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_SCHED_CLIN',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_pat_crit_sched_clin;

    FUNCTION get_pat_crit_mchoice_mkt_rel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN ds_cmpt_mkt_rel.internal_name_child%TYPE
    ) RETURN t_tbl_core_domain IS
    
        l_id_criteria   criteria.id_criteria%TYPE;
        l_flg_mandatory VARCHAR2(2 CHAR) := 'N';
        l_cur           pk_types.cursor_type;
        l_data          VARCHAR2(200 CHAR);
        l_label         VARCHAR2(200 CHAR);
        l_rank          VARCHAR2(200 CHAR);
        l_icon          VARCHAR2(200 CHAR);
        l_ret           t_tbl_core_domain := t_tbl_core_domain();
        l_error         t_error_out;
    
        l_internal_name ds_cmpt_mkt_rel.internal_name_child%TYPE;
    
    BEGIN
    
        SELECT b.id_criteria, a.internal_name_child
          INTO l_id_criteria, l_internal_name
          FROM ds_cmpt_mkt_rel a
         INNER JOIN criteria_ds_cmpt_mkt b
            ON a.id_ds_cmpt_mkt_rel = b.id_ds_cmpt_mkt_rel
         WHERE a.internal_name_child = i_internal_name
           AND rownum = 1;
    
        IF NOT get_pat_crit_mchoice(i_lang          => i_lang,
                                    i_prof          => i_prof,
                                    i_id_criteria   => l_id_criteria,
                                    i_flg_mandatory => pk_alert_constant.g_yes,
                                    o_mchoice       => l_cur,
                                    o_error         => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        LOOP
            FETCH l_cur
                INTO l_data, l_label, l_rank, l_icon;
            EXIT WHEN l_cur%NOTFOUND;
        
            l_ret.extend;
            l_ret(l_ret.count) := t_row_core_domain(l_internal_name, l_label, l_data, l_rank, l_icon);
        END LOOP;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_MCHOICE_MKT_REL',
                                              l_error);
        
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN NULL;
    END get_pat_crit_mchoice_mkt_rel;

    FUNCTION get_pat_crit_mchoice
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_criteria   IN criteria.id_criteria%TYPE,
        i_flg_mandatory IN sscr_crit.flg_mandatory%TYPE,
        o_mchoice       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   MOSTRA LISTA DE VALORES A PREENCHER NOS CRITÉRIOS MULTI-CHOICE DA PESQUISA 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                                 I_PROF - PROFISSIONAL
                                 I_ID_CRITERIA - ID DO CRITÉRIO A MOSTRAR O MULTI-CHOICE
                                 I_FLG_MANDATORY - FLAG QUE INDICA SE O CRITÉRIO É OBRIGATÓRIO
                        SAIDA: O_MCHOICE - VALORES DO CAMPO MULTI-CHOICE
                               O_ERROR - ERRO 
          
          CRIAÇÃO: RB 2005/04/25
          
          NOTAS: 
        *********************************************************************************/
    
        v_select   criteria.crit_mchoice_select%TYPE;
        v_found    BOOLEAN;
        l_flg_type criteria.flg_type%TYPE;
    
        CURSOR c_crit IS
            SELECT crit_mchoice_select, flg_type
              FROM criteria
             WHERE id_criteria = i_id_criteria
               AND flg_type IN (g_multivalue_criteria, g_multichoice_criteria);
    
        l_msg_common_m059 sys_message.desc_message%TYPE;
        l_msg_common_m014 sys_message.desc_message%TYPE;
    
    BEGIN
    
        g_error := 'GET CRITERIA';
        --BUSCA SELECT QUE PREENCHE O MULTI-CHOICE PARA O CRITÉRIO SELECCIONADO
        OPEN c_crit;
        FETCH c_crit
            INTO v_select, l_flg_type;
        v_found := c_crit%FOUND;
        CLOSE c_crit;
    
        IF NOT v_found
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET DATA';
        --SUBSTITUI PARÂMETROS DO SELECT
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_cat', pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof));
    
        -- Se for multivalor adiciona a opção de selecção de todas as opções 'Todos'
        IF l_flg_type = g_multivalue_criteria
        THEN
            l_msg_common_m014 := pk_message.get_message(i_lang, g_commonmsg_all);
        
            pk_context_api.set_parameter('l_msg_common_m014', l_msg_common_m014);
        
            v_select := v_select || ' UNION ALL
     SELECT ''0'' data, sys_context(''ALERT_CONTEXT'', ''l_msg_common_m014'') label, 0 rank, '''' icon
       FROM dual';
            -- Se não for obrigatório adiciona a opção de selecção de nenhuma opção '<nenhum>'
        ELSIF (i_flg_mandatory = g_mandatory_false)
        THEN
            l_msg_common_m059 := pk_message.get_message(i_lang, g_commonmsg_any);
        
            pk_context_api.set_parameter('l_msg_common_m059', l_msg_common_m059);
        
            v_select := v_select || ' UNION ALL
     SELECT ''-1'' data, sys_context(''ALERT_CONTEXT'', ''l_msg_common_m059'') label, -1 rank, '''' icon
       FROM dual';
        END IF;
    
        -- Adiciona cláusula de ordenação por rank e label
        v_select := v_select || ' ORDER BY rank, label';
    
        -- Obtém os valores
        OPEN o_mchoice FOR v_select;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_MCHOICE',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_mchoice);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRIT_MCHOICE',
                                              o_error);
        
            -- open cursors for java                
            pk_types.open_my_cursor(o_mchoice);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_pat_crit_mchoice;

    FUNCTION get_exam_search
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        i_flg_search      IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_info            OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /**
        *  OBJECTIVO: EFECTUAR PESQUISA DE EXAMES AGENDADOS/CONCLUÍDOS, DE ACORDO COM OS CRITÉRIOS 
        *          SELECCIONADOS.
        *
        * @param ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
        * @param I_ID_SYS_BTN_CRIT - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
        * @param I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA              
        * @param I_PROF - PROFISSIONAL Q REGISTA 
        * @param I_FLG_SEARCH - FLAG Q INDICA QUAL A PESQUISA: 
        * @param SAIDA: O_FLG_SHOW - Y - EXISTE MSG PARA MOSTRAR; N - Ñ EXISTE  
        * @param O_MSG - MENSAGEM COM INDICAÇÃO DE Q ULTRAPASSOU O Nº LIMITE DE REGISTOS 
        * @param O_MSG_TITLE - TÍTULO DA MSG A MOSTRAR AO UTILIZADOR, CASO 
        * @param O_FLG_SHOW = Y 
        * @param O_BUTTON - BOTÕES A MOSTRAR: N - NÃO, R - LIDO, C - CONFIRMADO 
        *            TB PODE MOSTRAR COMBINAÇÕES DESTES, QD É P/ MOSTRAR 
        *            + DO Q 1 BOTÃO 
        * @param O_INFO - EXAMES 
        * @param O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
        * @param O_ERROR - ERRO 
        *
        * @value I_FLG_SEARCH (*) S - AGENDADOS (*) R - COM RESULTADOS
        *  
        * @since 2005/11/22 
        * @author  SS
        * @changed CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS
        * @changed ASM 2007/01/09 CORRECÇÃO DE ERRO NA COLOCAÇÃO DE PLICAS 
        * @changed RS  2007/12/13 PESQUISAS DEIXAM DE FAZER REFERENCIA AO SCHEDULE
        * 
        **/
    
        l_from           VARCHAR2(32767);
        l_where          VARCHAR2(32767);
        l_where_lab      VARCHAR2(32767);
        l_exam_type_cond VARCHAR2(100) := NULL;
        v_from_cond      VARCHAR2(32767);
        v_where_cond     VARCHAR2(32767);
        l_count          NUMBER;
        l_limit          sys_config.desc_sys_config%TYPE;
        aux_sql1         VARCHAR2(32767);
        aux_sql2         VARCHAR2(32767);
        l_doc_type       sys_config.value%TYPE;
        l_external_sys   sys_config.value%TYPE;
        l_continue       BOOLEAN := TRUE;
        l_cat            category.flg_type%TYPE;
        l_sched          BOOLEAN := FALSE;
        l_error          t_error_out;
    
    BEGIN
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show     := 'N';
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := NULL;
    
        l_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
        
            --LÊ CRITÉRIOS DE PESQUISA E PREENCHE CLÁUSULA WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
                g_error := 'CALL PK_SEARCH.GET_CRITERIA_CONDITION';
                IF NOT get_criteria_condition(i_lang,
                                              i_prof,
                                              i_id_sys_btn_crit(i),
                                              REPLACE(i_crit_val(i), '''', '%'),
                                              v_where_cond,
                                              o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                l_where := l_where || v_where_cond;
            
                g_error := 'CALL PK_SEARCH.GET_FROM_CONDITION';
                IF NOT pk_search.get_from_condition(i_lang,
                                                    i_prof,
                                                    i_id_sys_btn_crit(i),
                                                    REPLACE(i_crit_val(i), '''', '%'),
                                                    v_from_cond,
                                                    o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                l_from := l_from || v_from_cond;
            END IF;
        
            IF i_id_sys_btn_crit(i) IN (11, 13, 15, 42)
            THEN
                l_sched := TRUE;
            END IF;
        END LOOP;
    
        IF l_from IS NULL
        THEN
            l_from := 'patient pat';
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_imgtech
        THEN
            l_exam_type_cond := 'AND eea.flg_type = ''I'' ';
        ELSIF i_prof.software = pk_alert_constant.g_soft_extech
        THEN
            l_exam_type_cond := 'AND eea.flg_type = ''E'' ';
        END IF;
    
        l_doc_type     := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
        l_external_sys := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
    
        IF i_flg_search = g_exam_sched
        THEN
            IF l_cat <> g_flg_tech
               OR i_prof.software <> pk_alert_constant.g_soft_labtech
            THEN
                -- AGENDADOS  
                g_error  := 'GET COUNT1 - AUX_SQL1';
                aux_sql1 := 'SELECT SUM(x) ' || --
                            '          FROM (SELECT COUNT(1) x ' || --
                            '                  FROM (SELECT id_schedule, ' || --
                            '                               id_episode, ' || --
                            '                               id_patient, ' || --
                            '                               name, ' || --
                            '                               gender, ' || --
                            '                               num_clin_record, ' || --
                            '                               id_professional, ' || --
                            '                               code_clinical_service, ' || --
                            '                               dt_begin, ' || --
                            '                               id_exam, ' || --
                            '                               id_exam_result, ' || --
                            '                               id_exam_req, ' || --
                            '                               id_exam_cat ' || --
                            '                          FROM (SELECT DISTINCT ei.id_schedule, ' || --
                            '                                                epis.id_episode, ' || --
                            '                                                pat.id_patient, ' || --
                            '                                                pat.name, ' || --
                            '                                                pat.gender, ' || --
                            '                                                cr.num_clin_record, ' || --
                            '                                                p.id_professional, ' || --
                            '                                                cs.code_clinical_service, ' || --
                            '                                                eea.dt_begin, ' || --
                            '                                                eea.id_exam, ' || --
                            '                                                eea.id_exam_result, ' || --
                            '                                                eea.id_exam_req, ' || --
                            '                                                eea.id_exam_cat ' || --
                            '                                  FROM ' || l_from || ', ' || --
                            '                                       clinical_service cs, ' || --
                            '                                       professional p, ' || --
                            '                                       clin_record cr, ' || --
                            '                                       episode epis, ' || --
                            '                                       epis_info ei, ' || --
                            '                                       exams_ea eea, ' || --
                            '                                       schedule_exam se, ' || --
                            '                                       schedule_outp sp, ' || --
                            '                                       schedule s, ' || --
                            '                                       epis_ext_sys ees, ' || --
                            '                                       pat_soc_attributes psa, ' || --
                            '                                       (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                            '                                          FROM doc_external de ' || --
                            '                                         WHERE de.id_doc_type = ' || l_doc_type || ') de ' || --
                            '                                 WHERE eea.dt_begin IS NOT NULL ' || --
                            '                                   AND eea.flg_time IN (:60, :61) ' || --
                            '                                   AND (eea.id_episode IS NULL OR epis.id_epis_type IN (:113, :121)) ' || --
                            '                                   AND eea.flg_status_det NOT IN (:21, :22, :23) ' || --
                            '                                   AND p.id_professional = eea.id_prof_req ' || --
                            '                                   AND cs.id_clinical_service(+) = epis.id_clinical_service ' || --
                            '                                   AND epis.id_episode(+) = eea.id_episode ' || --
                            '                                   AND epis.flg_status(+) != :30 ' || --
                            '                                   AND epis.id_institution(+) = :1 ' || --
                            '                                   AND eea.id_exam_req = se.id_exam_req ' || --
                            '                                   AND se.id_schedule = s.id_schedule ' || --
                            '                                   AND ei.id_episode(+) = epis.id_episode ' || --
                            '                                   AND sp.id_schedule(+) = ei.id_schedule ' || --
                            '                                   AND s.id_instit_requested(+) = :1 ' || --
                            '                                   AND s.flg_status(+) != :20 ' || --
                            '                                   AND ees.id_episode(+) = epis.id_episode ' || --
                            '                                   AND ees.id_institution(+) = :1 ' || --
                            '                                   AND ((ees.id_external_sys = :15) OR (ees.id_external_sys IS NULL)) ' || --
                            '                                   AND de.id_patient(+) = pat.id_patient ' || --
                            '                                   AND ((de.id_doc_type = :7) OR (de.id_doc_type IS NULL)) ' || --
                            '                                   AND ((de.flg_status = :10) OR (de.flg_status IS NULL)) ' || --
                            '                                   AND psa.id_patient(+) = pat.id_patient ' || --
                            '                                   AND psa.id_institution(+) = :1 ' || --
                            '                                   AND pat.id_patient = eea.id_patient ' || --
                            '                                   AND cr.id_patient(+) = pat.id_patient ' || --
                            '                                   AND cr.id_institution(+) = :1 ' || --
                            l_exam_type_cond || l_where || ')) t ' || --
                            '                 WHERE id_exam_cat IN (SELECT id_exam_cat ' || --
                            '                                         FROM exam_cat_dcs ' || --
                            '                                        WHERE id_dep_clin_serv IN (SELECT id_dep_clin_serv ' || --
                            '                                                                     FROM prof_dep_clin_serv pdcs ' || --
                            '                                                                    WHERE pdcs.id_professional = :6 ' || --
                            '                                                                      AND pdcs.flg_status = :50 ' || --
                            '                                                                      AND pdcs.id_institution = :1))';
            END IF;
        
            -- Analises
            IF l_cat = g_flg_tech
               AND i_prof.software = pk_alert_constant.g_soft_labtech
            THEN
                g_error  := 'GET COUNT1 - AUX_SQL2 [TECHNICIAN]';
                aux_sql2 := 'SELECT COUNT(1) x ' || --
                            '                  FROM (SELECT id_schedule, ' || --
                            '                               id_episode, ' || --
                            '                               id_patient, ' || --
                            '                               name, ' || --
                            '                               gender, ' || --
                            '                               num_clin_record, ' || --
                            '                               id_professional, ' || --
                            '                               code_clinical_service, ' || --
                            '                               dt_target, ' || --
                            '                               id_analysis, ' || --
                            '                               id_analysis_result, ' || --
                            '                               id_analysis_req, ' || --
                            '                               id_exam_cat ' || --
                            '                          FROM (SELECT DISTINCT ei.id_schedule, ' || --
                            '                                                epis.id_episode, ' || --
                            '                                                pat.id_patient, ' || --
                            '                                                pat.name, ' || --
                            '                                                pat.gender, ' || --
                            '                                                cr.num_clin_record, ' || --
                            '                                                p.id_professional, ' || --
                            '                                                cs.code_clinical_service, ' || --
                            '                                                lte.dt_target, ' || --
                            '                                                lte.id_analysis, ' || --
                            '                                                lte.id_analysis_result, ' || --
                            '                                                lte.id_analysis_req, ' || --
                            '                                                lte.id_exam_cat ' || --
                            '                                  FROM ' || l_from || ', ' || --
                            '                                       clinical_service cs, ' || --
                            '                                       professional p, ' || --
                            '                                       clin_record cr, ' || --
                            '                                       episode epis, ' || --
                            '                                       epis_info ei, ' || --
                            '                                       lab_tests_ea lte, ' || --
                            '                                       epis_ext_sys ees, ' || --
                            '                                       pat_soc_attributes psa, ' || --
                            '                                       (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                            '                                          FROM doc_external de ' || --
                            '                                         WHERE de.id_doc_type = ' || l_doc_type || ') de ' || --
                            '                                 WHERE lte.dt_target IS NOT NULL ' || --
                            '                                   AND lte.flg_time_harvest != :60 ' || --
                            '                                   AND lte.flg_status_det NOT IN (:21, :22, :23) ' || --
                            '                                   AND p.id_professional = lte.id_prof_writes ' || --
                            '                                   AND cs.id_clinical_service(+) = epis.id_clinical_service ' || --
                            '                                   AND epis.id_episode(+) = lte.id_episode ' || --
                            '                                   AND epis.flg_status(+) != :30 ' || --
                            '                                   AND ei.id_episode(+) = epis.id_episode ' || --
                            '                                   AND ees.id_episode(+) = epis.id_episode ' || --
                            '                                   AND ees.id_institution(+) = :1 ' || --
                            '                                   AND ((ees.id_external_sys = :15) OR (ees.id_external_sys IS NULL)) ' || --
                            '                                   AND de.id_patient(+) = pat.id_patient ' || --
                            '                                   AND ((de.id_doc_type = :7) OR (de.id_doc_type IS NULL)) ' || --
                            '                                   AND ((de.flg_status = :10) OR (de.flg_status IS NULL)) ' || --
                            '                                   AND psa.id_patient(+) = pat.id_patient ' || --
                            '                                   AND psa.id_institution(+) = :1 ' || --
                            '                                   AND epis.id_institution(+) = :1 ' || --
                            '                                   AND pat.id_patient = lte.id_patient ' || --
                            '                                   AND cr.id_patient(+) = pat.id_patient ' || --
                            '                                   AND cr.id_institution(+) = :1 ' || --
                            l_where || ')) t ' || --
                            '                 WHERE id_exam_cat IN (SELECT id_exam_cat ' || --
                            '                                         FROM exam_cat_dcs ' || --
                            '                                        WHERE id_dep_clin_serv IN (SELECT id_dep_clin_serv ' || --
                            '                                                                     FROM prof_dep_clin_serv pdcs ' || --
                            '                                                                    WHERE pdcs.id_professional = :6 ' || --
                            '                                                                      AND pdcs.flg_status = :50 ' || --
                            '                                                                      AND pdcs.id_institution = :1)) ';
            END IF;
        
            IF l_cat = g_flg_tech
               AND i_prof.software = pk_alert_constant.g_soft_labtech
            THEN
                g_error := 'GET EXECUTE IMMEDIATE 2';
                EXECUTE IMMEDIATE 'SELECT * FROM ( ' || aux_sql2 || ')'
                    INTO l_count
                    USING g_flg_time_e, g_flg_canc, g_flg_fin, g_flg_read, g_epis_canc, --
                i_prof.institution, l_external_sys, l_doc_type, g_doc_active, --
                i_prof.institution, i_prof.institution, i_prof.institution, i_prof.id, g_selected, i_prof.institution;
            
            ELSE
                g_error := 'GET EXECUTE IMMEDIATE 3';
                EXECUTE IMMEDIATE 'SELECT * FROM ( ' || aux_sql1 || '))'
                    INTO l_count
                    USING g_flg_time_e, g_flg_time_b, g_epis_type_rad, g_epis_type_exm, g_flg_canc, g_flg_fin, g_flg_read, --
                g_epis_canc, i_prof.institution, i_prof.institution, g_sched_cancel, i_prof.institution, l_external_sys, --
                l_doc_type, g_doc_active, i_prof.institution, i_prof.institution, i_prof.id, g_selected, i_prof.institution;
            END IF;
        
        ELSIF i_flg_search = g_exam_result
        THEN
            -- COM RESULTADOS 
            IF l_sched = TRUE
            THEN
                IF l_cat <> g_flg_tech
                   OR i_prof.software <> pk_alert_constant.g_soft_labtech
                THEN
                    g_error  := 'GET COUNT2 - AUX_SQL1';
                    aux_sql1 := 'WITH pdcs AS (SELECT pdcs.Id_Dep_Clin_Serv ' || --
                                ' FROM prof_dep_clin_serv pdcs ' || --
                                ' WHERE pdcs.id_professional = :6  ' || --
                                ' AND pdcs.flg_status = :50 ' || --
                                ' AND pdcs.id_institution = :1) ' || --
                                ' SELECT SUM(x) ' || --
                                '          FROM (SELECT COUNT(1) x ' || --
                                '                  FROM (SELECT DISTINCT ei.id_schedule, ' || --
                                '                                        epis.id_episode, ' || --
                                '                                        pat.id_patient, ' || --
                                '                                        pat.name, ' || --
                                '                                        pat.gender, ' || --
                                '                                        cr.num_clin_record, ' || --
                                '                                        p.id_professional, ' || --
                                '                                        cs.code_clinical_service, ' || --
                                '                                        eea.dt_begin, ' || --
                                '                                        eea.id_exam, ' || --
                                '                                        eea.id_exam_result, ' || --
                                '                                        eea.id_exam_req ' || --
                                '                          FROM ' || l_from || ', ' || --
                                '                               clinical_service cs, ' || --
                                '                               professional p, ' || --
                                '                               clin_record cr, ' || --
                                '                               episode epis, ' || --
                                '                               epis_info ei, ' || --
                                '                               exams_ea eea, ' || --
                                '                               schedule_outp sp, ' || --
                                '                               schedule s, ' || --
                                '                               epis_ext_sys ees, ' || --
                                '                               pat_soc_attributes psa, ' || --
                                '                               exam_cat_dcs ecdcs, ' || --
                                '                               (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                '                                  FROM doc_external de ' || --
                                '                                 WHERE de.id_doc_type = ' || l_doc_type || ') de, ' || --
                                '                               pdcs ' || --
                                '                         WHERE eea.id_exam_result IS NOT NULL ' || --
                                '                           AND ecdcs.id_exam_cat = eea.id_exam_cat ' || --
                                '                           AND ecdcs.id_dep_clin_serv  = pdcs.id_dep_clin_serv' || --
                                '                           AND p.id_professional = eea.id_prof_req ' || --
                                '                           AND cs.id_clinical_service(+) = epis.id_clinical_service ' || --
                                '                           AND epis.id_episode = eea.id_episode ' || --
                                '                           AND epis.flg_status != :30 ' || --
                                '                           AND ei.id_episode = epis.id_episode ' || --
                                '                           AND sp.id_schedule = ei.id_schedule ' || --
                                '                           AND s.id_schedule = sp.id_schedule ' || --
                                '                           AND s.id_instit_requested = :1 ' || --
                                '                           AND s.flg_status != :20 ' || --
                                '                           AND ees.id_episode(+) = epis.id_episode ' || --
                                '                           AND ees.id_institution(+) = :1 ' || --
                                '                           AND ((ees.id_external_sys = :15) OR (ees.id_external_sys IS NULL)) ' || --
                                '                           AND de.id_patient(+) = pat.id_patient ' || --
                                '                           AND ((de.id_doc_type = :7) OR (de.id_doc_type IS NULL)) ' || --
                                '                           AND ((de.flg_status = :10) OR (de.flg_status IS NULL)) ' || --
                                '                           AND psa.id_patient(+) = pat.id_patient ' || --
                                '                           AND psa.id_institution(+) = :1 ' || --
                                '                           AND epis.id_institution = :1 ' || --
                                '                           AND pat.id_patient = eea.id_patient ' || --
                                '                           AND cr.id_patient(+) = pat.id_patient ' || --
                                '                           AND cr.id_institution(+) = :1 ' || --
                                l_where || ') ';
                END IF;
            
                IF (l_cat = g_flg_adm AND
                   i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_labtech))
                   OR (l_cat = g_flg_tech AND i_prof.software = pk_alert_constant.g_soft_labtech)
                THEN
                    -- Análises
                    IF l_cat = g_flg_adm
                    THEN
                        IF instr(l_where, 'eea.dt_begin') != 0
                        THEN
                            l_where_lab := REPLACE(l_where, 'eea.dt_begin', 'lte.dt_target');
                        END IF;
                    ELSE
                        l_where_lab := REPLACE(l_where, 'EPIS.DT_BEGIN_TSTZ', 'lte.dt_target');
                    END IF;
                
                    g_error  := 'GET COUNT2 - AUX_SQL2';
                    aux_sql2 := 'SELECT COUNT(1) x ' || --
                                '                  FROM (SELECT DISTINCT ei.id_schedule, ' || --
                                '                                        epis.id_episode, ' || --
                                '                                        pat.id_patient, ' || --
                                '                                        pat.name, ' || --
                                '                                        pat.gender, ' || --
                                '                                        cr.num_clin_record, ' || --
                                '                                        p.id_professional, ' || --
                                '                                        cs.code_clinical_service, ' || --
                                '                                        lte.dt_target, ' || --
                                '                                        lte.id_analysis, ' || --
                                '                                        lte.id_analysis_result, ' || --
                                '                                        lte.id_analysis_req ' || --
                                '                          FROM ' || l_from || ', ' || --
                                '                               clinical_service cs, ' || --
                                '                               professional p, ' || --
                                '                               clin_record cr, ' || --
                                '                               episode epis, ' || --
                                '                               epis_info ei, ' || --
                                '                               schedule_outp sp, ' || --
                                '                               schedule s, ' || --
                                '                               epis_ext_sys ees, ' || --
                                '                               pat_soc_attributes psa, ' || --
                                '                               exam_cat_dcs ecdcs, ' || --
                                '                               lab_tests_ea lte, ' || --
                                '                               (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                '                                  FROM doc_external de ' || --
                                '                                 WHERE de.id_doc_type = ' || l_doc_type || ') de ' || --
                                '                         WHERE lte.id_analysis_result IS NOT NULL ' || --
                                '                           AND lte.id_exam_cat = ecdcs.id_exam_cat ' || --
                                '                           AND EXISTS (SELECT 1 ' || --
                                '                                  FROM prof_dep_clin_serv pdcs ' || --
                                '                                 WHERE pdcs.id_professional = :6 ' || --
                                '                                   AND pdcs.flg_status = :50 ' || --
                                '                                   AND pdcs.id_institution = :1 ' || --
                                '                                   AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv) ' || --
                                '                           AND p.id_professional = lte.id_prof_writes ' || --
                                '                           AND cs.id_clinical_service(+) = epis.id_clinical_service ' || --
                                '                           AND epis.id_episode = lte.id_episode ' || --
                                '                           AND epis.flg_status != :30 ' || --
                                '                           AND ei.id_episode = epis.id_episode ' || --
                                '                           AND sp.id_schedule = ei.id_schedule ' || --
                                '                           AND s.id_instit_requested = :1 ' || --
                                '                           AND s.id_schedule = sp.id_schedule ' || --
                                '                           AND s.flg_status != :20 ' || --
                                '                           AND ees.id_episode(+) = epis.id_episode ' || --
                                '                           AND ees.id_institution(+) = :1 ' || --
                                '                           AND ((ees.id_external_sys = :15) OR (ees.id_external_sys IS NULL)) ' || --
                                '                           AND de.id_patient(+) = pat.id_patient ' || --
                                '                           AND ((de.id_doc_type = :7) OR (de.id_doc_type IS NULL)) ' || --
                                '                           AND ((de.flg_status = :10) OR (de.flg_status IS NULL)) ' || --
                                '                           AND psa.id_patient(+) = pat.id_patient ' || --
                                '                           AND psa.id_institution(+) = :1 ' || --
                                '                           AND epis.id_institution = :1 ' || --
                                '                           AND pat.id_patient = lte.id_patient ' || --
                                '                           AND cr.id_patient(+) = pat.id_patient ' || --
                                '                           AND cr.id_institution(+) = :1 ' || --
                                l_where_lab || ')) ';
                END IF;
            
                IF l_cat = g_flg_adm
                   AND i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_labtech)
                THEN
                    g_error := 'GET EXECUTE IMMEDIATE 5';
                    EXECUTE IMMEDIATE 'SELECT * FROM ( ' || aux_sql1 || ' UNION ALL ' || aux_sql2 || ')'
                        INTO l_count
                        USING i_prof.id, g_selected, i_prof.institution, g_epis_canc, i_prof.institution, g_sched_cancel, --
                    i_prof.institution, l_external_sys, l_doc_type, g_doc_active, i_prof.institution, i_prof.institution, --
                    i_prof.institution,
                    --
                    i_prof.id, g_selected, i_prof.institution, g_epis_canc, i_prof.institution, g_sched_cancel, --
                    i_prof.institution, l_external_sys, l_doc_type, g_doc_active, i_prof.institution, i_prof.institution, --
                    i_prof.institution;
                
                ELSIF l_cat = g_flg_tech
                      AND i_prof.software = pk_alert_constant.g_soft_labtech
                THEN
                    g_error := 'GET EXECUTE IMMEDIATE 6';
                    EXECUTE IMMEDIATE 'SELECT * FROM ( ' || aux_sql2 || ')'
                        INTO l_count
                        USING i_prof.id, g_selected, i_prof.institution, g_epis_canc, i_prof.institution, g_sched_cancel, --
                    i_prof.institution, l_external_sys, l_doc_type, g_doc_active, i_prof.institution, i_prof.institution, --
                    i_prof.institution;
                
                ELSE
                    g_error := 'GET EXECUTE IMMEDIATE 7';
                    EXECUTE IMMEDIATE 'SELECT * FROM ( ' || aux_sql1 || '))'
                        INTO l_count
                        USING i_prof.id, g_selected, i_prof.institution, g_epis_canc, i_prof.institution, g_sched_cancel, --
                    i_prof.institution, l_external_sys, l_doc_type, g_doc_active, i_prof.institution, i_prof.institution, --
                    i_prof.institution;
                END IF;
            ELSE
                IF l_cat <> g_flg_tech
                   OR i_prof.software <> pk_alert_constant.g_soft_labtech
                THEN
                    g_error  := 'GET COUNT2 - AUX_SQL1';
                    aux_sql1 := 'WITH pdcs AS (SELECT pdcs.Id_Dep_Clin_Serv ' || --
                                ' FROM prof_dep_clin_serv pdcs ' || --
                                ' WHERE pdcs.id_professional = :6  ' || --
                                ' AND pdcs.flg_status = :50 ' || --
                                ' AND pdcs.id_institution = :1) ' || --
                                ' SELECT SUM(x) ' || --
                                '          FROM (SELECT COUNT(1) x ' || --
                                '                  FROM (SELECT DISTINCT ei.id_schedule, ' || --
                                '                                        epis.id_episode, ' || --
                                '                                        pat.id_patient, ' || --
                                '                                        pat.name, ' || --
                                '                                        pat.gender, ' || --
                                '                                        cr.num_clin_record, ' || --
                                '                                        p.id_professional, ' || --
                                '                                        cs.code_clinical_service, ' || --
                                '                                        eea.dt_begin, ' || --
                                '                                        eea.id_exam, ' || --
                                '                                        eea.id_exam_result, ' || --
                                '                                        eea.id_exam_req ' || --
                                '                          FROM ' || l_from || ', ' || --
                                '                               clinical_service cs, ' || --
                                '                               professional p, ' || --
                                '                               clin_record cr, ' || --
                                '                               episode epis, ' || --
                                '                               epis_info ei, ' || --
                                '                               exams_ea eea, ' || --
                                '                               epis_ext_sys ees, ' || --
                                '                               pat_soc_attributes psa, ' || --
                                '                               exam_cat_dcs ecdcs, ' || --
                                '                               (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                '                                  FROM doc_external de ' || --
                                '                                 WHERE de.id_doc_type = ' || l_doc_type || ') de, ' || --
                                '                               pdcs ' || --
                                '                         WHERE eea.flg_status_det IN (''F'', ''L'', ''EP'', ''EX'')' || --
                                '                           AND ecdcs.id_exam_cat = eea.id_exam_cat ' || --
                                '                           AND ecdcs.id_dep_clin_serv  = pdcs.id_dep_clin_serv ' || --                                
                                '                           AND p.id_professional = eea.id_prof_req ' || --
                                '                           AND cs.id_clinical_service(+) = epis.id_clinical_service ' || --
                                '                           AND epis.id_episode = eea.id_episode ' || --
                                '                           AND epis.flg_status != :30 ' || --
                                '                           AND ei.id_episode = epis.id_episode ' || --
                                '                           AND ees.id_episode(+) = epis.id_episode ' || --
                                '                           AND ees.id_institution(+) = :1 ' || --
                                '                           AND ((ees.id_external_sys = :15) OR (ees.id_external_sys IS NULL)) ' || --
                                '                           AND de.id_patient(+) = pat.id_patient ' || --
                                '                           AND ((de.id_doc_type = :7) OR (de.id_doc_type IS NULL)) ' || --
                                '                           AND ((de.flg_status = :10) OR (de.flg_status IS NULL)) ' || --
                                '                           AND psa.id_patient(+) = pat.id_patient ' || --
                                '                           AND psa.id_institution(+) = :1 ' || --
                                '                           AND epis.id_institution = :1 ' || --
                                '                           AND pat.id_patient = eea.id_patient ' || --
                                '                           AND cr.id_patient(+) = pat.id_patient ' || --
                                '                           AND cr.id_institution(+) = :1 ' || l_exam_type_cond || --                            
                                l_where || ') ';
                END IF;
            
                IF (l_cat = g_flg_adm AND
                   i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_labtech))
                   OR (l_cat = g_flg_tech AND i_prof.software = pk_alert_constant.g_soft_labtech)
                THEN
                    -- Análises
                    IF l_cat = g_flg_adm
                    THEN
                        IF instr(l_where, 'eea.dt_begin') != 0
                        THEN
                            l_where_lab := REPLACE(l_where, 'eea.dt_begin', 'lte.dt_target');
                        END IF;
                    ELSE
                        l_where_lab := REPLACE(l_where, 'EPIS.DT_BEGIN_TSTZ', 'lte.dt_target');
                    END IF;
                
                    g_error  := 'GET COUNT2 - AUX_SQL2';
                    aux_sql2 := 'SELECT COUNT(1) x ' || --
                                '                  FROM (WITH prof_dep AS (SELECT pdcs.id_dep_clin_serv ' || --
                                '                                            FROM prof_dep_clin_serv pdcs ' || --
                                '                                           WHERE pdcs.id_professional = :6 ' || --
                                '                                             AND pdcs.flg_status = :50 ' || --
                                '                                             AND pdcs.id_institution = :1) ' || --
                                '                      SELECT DISTINCT ei.id_schedule, ' || --
                                '                                      epis.id_episode, ' || --
                                '                                      pat.id_patient, ' || --
                                '                                      pat.name, ' || --
                                '                                      pat.gender, ' || --
                                '                                      cr.num_clin_record, ' || --
                                '                                      p.id_professional, ' || --
                                '                                      cs.code_clinical_service, ' || --
                                '                                      lte.dt_target, ' || --
                                '                                      lte.id_analysis, ' || --
                                '                                      lte.id_analysis_result, ' || --
                                '                                      lte.id_analysis_req ' || --                                     
                                '                          FROM ' || l_from || ', ' || --
                                '                               clinical_service cs, ' || --
                                '                               professional p, ' || --
                                '                               clin_record cr, ' || --
                                '                               episode epis, ' || --
                                '                               epis_info ei, ' || --
                                '                               epis_ext_sys ees, ' || --
                                '                               pat_soc_attributes psa, ' || --
                                '                               exam_cat_dcs ecdcs, ' || --
                                '                               lab_tests_ea lte, ' || --
                                '                               (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                '                                  FROM doc_external de ' || --
                                '                                 WHERE (de.id_doc_type = ' || l_doc_type ||
                                ' or de.id_doc_type is null) ' || --
                                '                                   and (de.flg_status = :10 or de.flg_status is null)) de, ' || --
                                '                               prof_dep pd ' || --
                                '                         WHERE lte.id_analysis_result IS NOT NULL ' || --
                                '                           AND lte.id_exam_cat = ecdcs.id_exam_cat ' || --
                                '                           AND ecdcs.id_dep_clin_serv = pd.id_dep_clin_serv ' || --                                                                
                                '                           AND p.id_professional = lte.id_prof_writes ' || --
                                '                           AND lte.id_episode = epis.id_episode ' || --
                                '                           AND epis.flg_status != :30 ' || --                                
                                '                           AND ei.id_episode = epis.id_episode ' || --
                                '                           AND cs.id_clinical_service(+) = epis.id_clinical_service ' || --
                                '                           AND ees.id_episode(+) = epis.id_episode ' || --
                                '                           AND ees.id_institution(+) = :1 ' || --
                                '                           AND ((ees.id_external_sys = :15) OR (ees.id_external_sys IS NULL)) ' || --
                                '                           AND de.id_patient(+) = pat.id_patient ' || --
                                '                           AND psa.id_patient(+) = pat.id_patient ' || --
                                '                           AND psa.id_institution(+) = :1 ' || --
                                '                           AND epis.id_institution = :1 ' || --
                                '                           AND pat.id_patient = lte.id_patient ' || --
                                '                           AND cr.id_patient(+) = pat.id_patient ' || --
                                '                           AND cr.id_institution(+) = :1 ' || --
                                l_where_lab || ') ';
                
                    IF l_cat = g_flg_adm
                    THEN
                        aux_sql2 := aux_sql2 || ') ';
                    END IF;
                END IF;
            
                IF l_cat = g_flg_adm
                   AND i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_labtech)
                THEN
                    g_error := 'GET EXECUTE IMMEDIATE 8';
                    EXECUTE IMMEDIATE 'SELECT * FROM ( ' || aux_sql1 || ' UNION ALL ' || aux_sql2 || ')'
                        INTO l_count
                        USING i_prof.id, g_selected, i_prof.institution, g_epis_canc, i_prof.institution, l_external_sys, --
                    l_doc_type, g_doc_active, i_prof.institution, i_prof.institution, i_prof.institution,
                    --
                    i_prof.id, g_selected, i_prof.institution, g_epis_canc, i_prof.institution, l_external_sys, l_doc_type, --
                    g_doc_active, i_prof.institution, i_prof.institution, i_prof.institution;
                
                ELSIF l_cat = g_flg_tech
                      AND i_prof.software = pk_alert_constant.g_soft_labtech
                THEN
                    g_error := 'GET EXECUTE IMMEDIATE 9';
                    EXECUTE IMMEDIATE 'SELECT * FROM ( ' || aux_sql2 || ')'
                        INTO l_count
                        USING i_prof.id, g_selected, i_prof.institution, g_doc_active, g_epis_canc, --
                    i_prof.institution, l_external_sys, i_prof.institution, i_prof.institution, i_prof.institution;
                
                ELSE
                    g_error := 'GET EXECUTE IMMEDIATE 10';
                    EXECUTE IMMEDIATE 'SELECT * FROM ( ' || aux_sql1 || '))'
                        INTO l_count
                        USING i_prof.id, g_selected, i_prof.institution, g_epis_canc, i_prof.institution, l_external_sys, --
                    l_doc_type, g_doc_active, i_prof.institution, i_prof.institution, i_prof.institution;
                END IF;
            END IF;
        
        END IF;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_continue
        THEN
            IF i_flg_search = g_exam_sched
            THEN
                IF l_cat <> g_flg_tech
                   OR i_prof.software <> pk_alert_constant.g_soft_labtech
                THEN
                    -- AGENDADOS                
                    g_error  := 'GET CURSOR1.1';
                    aux_sql1 := 'SELECT id_schedule, ' || --
                                '       id_episode, ' || --
                                '       id_patient, ' || --
                                '       name, ' || --
                                '       pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', gender, ' || i_lang ||
                                ') gender, ' || --
                                '       pk_patient.get_pat_age(' || i_lang || ', id_patient, ' || i_prof.institution || ', ' ||
                                i_prof.software || ') pat_age, ' || --
                                '       pk_patphoto.get_pat_photo(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                                i_prof.institution || ', ' || i_prof.software ||
                                '), id_patient,id_episode, id_schedule) photo, ' || --                         
                                '       num_clin_record, ' || --
                                '       pk_prof_utils.get_name_signature(' || i_lang || ', ' || --
                                '                                        profissional(' || i_prof.id || ', ' ||
                                i_prof.institution || ', ' || i_prof.software || '), ' || --
                                '                                        id_professional) nick_name, ' || --
                                '       pk_hea_prv_aux.get_clin_service(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                                i_prof.institution || ',' || i_prof.software || '), id_dep_clin_serv) cons_type,' || --
                                '       pk_date_utils.trunc_dt_char_tsz (' || i_lang || ', dt_begin, ' ||
                                i_prof.institution || ', ' || i_prof.software || ') date_target,' || --
                                '       pk_date_utils.date_char_hour_tsz(' || i_lang || ', dt_begin, ' ||
                                i_prof.institution || ', ' || i_prof.software || ') hour_target,' || --
                                '       id_exam, ' || --
                                '       pk_exams_api_db.get_alias_translation(' || i_lang || ', ' || --
                                '                                             profissional(' || i_prof.id || ', ' ||
                                i_prof.institution || ', ' || i_prof.software || '), ' || --
                                '                                             ''EXAM.CODE_EXAM.'' || id_exam, ' || --
                                '                                             NULL) desc_exam, ' || --
                                '       decode(id_exam_result, NULL, ''N'', ''Y'') flg_result, ' || --
                                '       id_exam_req, ' || --
                                '       pk_date_utils.to_char_insttimezone(' || i_prof.institution || ', ' ||
                                i_prof.software || ', dt_begin, ''YYYYMMDDHH24MISS'') dt_ord1, ' || --
                                '       pk_adt.is_contact(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                                i_prof.institution || ',' || i_prof.software || '), id_patient) flg_contact ' ||
                                '  FROM (SELECT DISTINCT ei.id_schedule, ' || --
                                '                        epis.id_episode, ' || --
                                '                        pat.id_patient, ' || --
                                '                        pat.name, ' || --
                                '                        pat.gender, ' || --
                                '                        cr.num_clin_record, ' || --
                                '                        p.id_professional, ' || --
                                '                        ei.id_dep_clin_serv, ' || --
                                '                        eea.dt_begin, ' || --
                                '                        eea.id_exam, ' || --
                                '                        eea.id_exam_result, ' || --
                                '                        eea.id_exam_req, ' || --
                                '                        eea.id_exam_cat ' || --
                                '          FROM ' || l_from || ', ' || --
                                '               clinical_service cs, ' || --
                                '               professional p, ' || --
                                '               clin_record cr, ' || --
                                '               episode epis, ' || --
                                '               epis_info ei, ' || --
                                '               exams_ea eea, ' || --
                                '               schedule_exam se, ' || --
                                '               schedule_outp sp, ' || --
                                '               schedule s, ' || --
                                '               epis_ext_sys ees, ' || --
                                '               pat_soc_attributes psa, ' || --
                                '               (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                '                  FROM doc_external de ' || --
                                '                 WHERE de.id_doc_type = ' || l_doc_type || ') de ' || --
                                '         WHERE eea.dt_begin IS NOT NULL ' || --
                                '           AND eea.flg_time IN ( ''' || g_flg_time_e || ''', ''' || g_flg_time_b ||
                                ''') ' || --
                                '           AND (eea.id_episode IS NULL OR epis.id_epis_type IN ( ' || g_epis_type_exm || ', ' ||
                                g_epis_type_rad || ')) ' || --
                                '           AND eea.flg_status_det NOT IN (''' || g_flg_canc || ''', ''' || g_flg_fin ||
                                ''', ''' || g_flg_read || ''') ' || --
                                '           AND p.id_professional = eea.id_prof_req ' || --
                                '           AND cs.id_clinical_service(+) = epis.id_clinical_service' || --
                                '           AND epis.id_episode(+) = eea.id_episode' || --
                                '           AND epis.flg_status(+) != ''' || g_epis_canc || '''' || --
                                '           AND epis.id_institution(+) = ' || i_prof.institution || ' ' || --
                                '           AND eea.id_exam_req = se.id_exam_req' || --
                                '           AND se.id_schedule = s.id_schedule' || --
                                '           AND ei.id_episode(+) = epis.id_episode' || --
                                '           AND sp.id_schedule(+) = ei.id_schedule ' || --
                                '           AND s.id_instit_requested(+) = ' || i_prof.institution || ' ' || --
                                '           AND s.flg_status(+) != ''' || g_sched_cancel || '''' || --
                                '           AND ees.id_episode(+) = epis.id_episode ' || --
                                '           AND ees.id_institution(+) = ' || i_prof.institution || ' ' || --
                                '           AND ((ees.id_external_sys = ' || l_external_sys ||
                                ') OR (ees.id_external_sys IS NULL))' || --
                                '           AND de.id_patient(+) = pat.id_patient' || --
                                '           AND ((de.id_doc_type = ' || l_doc_type || ') OR (de.id_doc_type IS NULL)) ' || --
                                '           AND ((de.flg_status = ''' || g_doc_active ||
                                ''') OR (de.flg_status IS NULL))' || --
                                '           AND psa.id_patient(+) = pat.id_patient ' || --
                                '           AND psa.id_institution(+) = ' || i_prof.institution || ' ' || --
                                '           AND pat.id_patient = eea.id_patient' || --
                                '           AND cr.id_patient(+) = pat.id_patient' || --
                                '           AND cr.id_institution(+) = ' || i_prof.institution || ' ' ||
                                l_exam_type_cond || l_where || ') t ' || --
                                ' WHERE id_exam_cat IN (SELECT id_exam_cat' || --
                                '                         FROM exam_cat_dcs' || --
                                '                        WHERE id_dep_clin_serv IN (SELECT id_dep_clin_serv' || --
                                '                              FROM prof_dep_clin_serv pdcs' || --
                                '                             WHERE pdcs.id_professional = ' || i_prof.id || ' ' || --
                                '                               AND pdcs.flg_status = ''' || g_selected || ''' ' || --
                                '                               AND pdcs.id_institution = ' || i_prof.institution ||
                                ')) ';
                
                END IF;
            
                IF l_cat = g_flg_tech
                   AND i_prof.software = pk_alert_constant.g_soft_labtech
                THEN
                    -- Análises            
                    l_where := REPLACE(l_where, 'EPIS.DT_BEGIN_TSTZ', 'lte.dt_target');
                
                    g_error  := 'GET CURSOR1.3';
                    aux_sql2 := 'SELECT id_schedule, ' || --
                                '       id_episode, ' || --
                                '       id_patient, ' || --
                                '       name, ' || --
                                '       pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', gender, ' || i_lang ||
                                ') gender, ' || --
                                '       pk_patient.get_pat_age(' || i_lang || ', id_patient, ' || i_prof.institution || ', ' ||
                                i_prof.software || ') pat_age, ' || --
                                '       pk_patphoto.get_pat_photo(' || i_lang || ',' || 'profissional(' || i_prof.id || ', ' ||
                                i_prof.institution || ', ' || i_prof.software ||
                                '), id_patient, id_episode,id_schedule) photo, ' || --
                                '       num_clin_record, ' || --
                                '       pk_prof_utils.get_name_signature(' || i_lang || ', ' || --
                                '                                        profissional(' || i_prof.id || ', ' ||
                                i_prof.institution || ', ' || i_prof.software || '), ' || --
                                '                                        id_professional) nick_name, ' || --
                                '      pk_hea_prv_aux.get_clin_service(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                                i_prof.institution || ',' || i_prof.software || '), id_dep_clin_serv) cons_type,' || --
                                '       pk_date_utils.trunc_dt_char_tsz(' || i_lang || ', dt_target, ' ||
                                i_prof.institution || ', ' || i_prof.software || ') date_target, ' || --
                                '      pk_date_utils.date_char_hour_tsz (' || i_lang || ', dt_target, ' ||
                                i_prof.institution || ', ' || i_prof.software || ') hour_target, ' || --
                                '       id_analysis id_exam, ' || --
                                '       pk_lab_tests_api_db.get_alias_translation(' || i_lang || ', ' || --
                                '                                                 profissional(' || i_prof.id || ', ' ||
                                i_prof.institution || ', ' || i_prof.software || '), ''' ||
                                pk_lab_tests_constant.g_analysis_alias || ''', ' || --
                                '                                                 code_analysis, ' || --
                                '                                                 NULL) desc_exam, ' || --
                                '       decode(id_analysis_result, NULL, ''N'', ''Y'') flg_result, ' || --
                                '       id_analysis_req id_exam_req, ' || --
                                '       pk_date_utils.to_char_insttimezone(' || i_prof.institution || ', ' ||
                                i_prof.software || ', dt_target, ''YYYYMMDDHH24MISS'') dt_ord1, ' || --
                                '      pk_adt.is_contact(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                                i_prof.institution || ',' || i_prof.software || '), id_patient) flg_contact ' ||
                                '  FROM (SELECT DISTINCT ei.id_schedule, ' || --
                                '                        epis.id_episode, ' || --
                                '                        pat.id_patient, ' || --
                                '                        pat.name, ' || --
                                '                        pat.gender, ' || --
                                '                        cr.num_clin_record, ' || --
                                '                        p.id_professional, ' || --
                                '                        ei.id_dep_clin_serv,' || --
                                '                        lte.dt_target,' || -- 
                                '                        lte.id_analysis, ' || --
                                '                        ''ANALYSIS.CODE_ANALYSIS.'' || lte.id_analysis code_analysis, ' || --
                                '                        id_analysis_result, ' || --
                                '                        lte.id_analysis_req, ' || --
                                '                        ec.id_exam_cat ' || --
                                '          FROM ' || l_from || ', ' || --
                                '               clinical_service cs, ' || --
                                '               professional p, ' || --
                                '               clin_record cr, ' || --
                                '               episode epis, ' || --
                                '               epis_info ei, ' || --
                                '               lab_tests_ea lte, ' || --
                                '               epis_ext_sys ees, ' || --
                                '               pat_soc_attributes psa, ' || --
                                '               exam_cat ec, ' || --
                                '               (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                '                  FROM doc_external de ' || --
                                '                 WHERE de.id_doc_type = ' || l_doc_type || ') de ' || --
                                '         WHERE lte.dt_target IS NOT NULL ' || --
                                '           AND lte.flg_time_harvest != ''' || g_flg_time_e || ''' ' || --
                                '           AND lte.flg_status_det NOT IN (''' || g_flg_canc || ''', ''' || g_flg_fin ||
                                ''', ''' || g_flg_read || ''') ' || --
                                '           AND lte.id_exam_cat = ec.id_exam_cat ' || --
                                '           AND p.id_professional = lte.id_prof_writes ' || --
                                '           AND epis.id_episode(+) = lte.id_episode' || --                                
                                '           AND cs.id_clinical_service(+) = epis.id_clinical_service' || --
                                '           AND epis.flg_status(+) != ''' || g_epis_canc || '''' || --
                                '           AND ei.id_episode(+) = epis.id_episode  ' || --
                                '           AND ees.id_episode(+) = epis.id_episode' || --
                                '           AND ees.id_institution(+) = ' || i_prof.institution || ' ' || --
                                '           AND ((ees.id_external_sys = ' || l_external_sys ||
                                ') OR (ees.id_external_sys IS NULL)) ' || --
                                '           AND de.id_patient(+) = pat.id_patient' || --
                                '           AND ((de.id_doc_type = ' || l_doc_type || ') OR (de.id_doc_type IS NULL)) ' || --
                                '           AND ((de.flg_status = ''' || g_doc_active ||
                                ''') OR (de.flg_status IS NULL)) ' || --
                                '           AND psa.id_patient(+) = pat.id_patient ' || --
                                '           AND psa.id_institution(+) = ' || i_prof.institution || ' ' || --
                                '           AND epis.id_institution(+) = ' || i_prof.institution || ' ' || --
                                '           AND pat.id_patient = lte.id_patient' || --
                                '           AND cr.id_patient(+) = pat.id_patient' || --
                                '           AND cr.id_institution(+) = ' || i_prof.institution || ' ' || l_where ||
                                ') t ' || --
                                ' WHERE id_exam_cat IN (SELECT id_exam_cat' || --
                                '                         FROM exam_cat_dcs' || --
                                '                        WHERE id_dep_clin_serv IN (SELECT id_dep_clin_serv' || --
                                '                              FROM prof_dep_clin_serv pdcs' || --
                                '                             WHERE pdcs.id_professional = ' || i_prof.id || ' ' || --
                                '                               AND pdcs.flg_status = ''' || g_selected || ''' ' || --
                                '                               AND pdcs.id_institution = ' || i_prof.institution ||
                                ')) ';
                END IF;
            
                IF l_cat = g_flg_tech
                   AND i_prof.software = pk_alert_constant.g_soft_labtech
                THEN
                    g_error := 'GET CURSOR - TOTAL 1.3';
                    OPEN o_info FOR aux_sql2 || ' ORDER BY date_target, hour_target';
                
                ELSE
                    g_error := 'GET CURSOR - TOTAL 1.2';
                    OPEN o_info FOR aux_sql1 || ' ORDER BY date_target, hour_target';
                END IF;
            
            ELSIF i_flg_search = g_exam_result
            THEN
                -- COM RESULTADOS
                IF l_sched = TRUE
                THEN
                    IF l_cat <> g_flg_tech
                       OR i_prof.software <> pk_alert_constant.g_soft_labtech
                    THEN
                        g_error  := 'GET CURSOR3.1';
                        aux_sql1 := 'SELECT DISTINCT id_schedule, ' || --
                                    '                id_episode, ' || --
                                    '                id_patient, ' || --
                                    '                name, ' || --
                                    '                pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', gender, ' ||
                                    i_lang || ') gender, ' || --
                                    '                pk_patient.get_pat_age(' || i_lang || ', id_patient, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') PAT_AGE,' || --
                                    '                pk_patphoto.get_pat_photo(' || i_lang || ',' || 'profissional(' ||
                                    i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software ||
                                    '), id_patient, id_episode,id_schedule) photo, ' || --
                                    '                num_clin_record, ' || --
                                    '                pk_prof_utils.get_name_signature(' || i_lang || ', ' || --
                                    '                                                 profissional(' || i_prof.id || ', ' ||
                                    i_prof.institution || ', ' || i_prof.software || '), ' || --
                                    '                                                 id_professional) nick_name, ' || --
                                    '               pk_hea_prv_aux.get_clin_service(' || i_lang || ',profissional(' ||
                                    i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                                    '), id_dep_clin_serv) cons_type,' || --
                                    '                pk_date_utils.trunc_dt_char_tsz(' || i_lang || ', dt_begin, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') date_target, ' || --
                                    '                pk_date_utils.date_char_hour_tsz(' || i_lang || ', dt_begin, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') hour_target, ' || --
                                    '                id_exam, ' || --
                                    '                pk_exams_api_db.get_alias_translation(' || i_lang || ', ' || --
                                    '                                                      profissional(' || i_prof.id || ', ' ||
                                    i_prof.institution || ', ' || i_prof.software || '), ' || --
                                    '                                                      ''EXAM.CODE_EXAM.'' || id_exam, ' || --
                                    '                                                      NULL) desc_exam, ' || --
                                    '                flg_result, ' || --
                                    '                id_exam_req, ' || --
                                    '                pk_date_utils.to_char_insttimezone(' || i_prof.institution || ', ' ||
                                    i_prof.software || ', dt_begin, ''YYYYMMDDHH24MISS'') dt_ord1 ' || --
                                    '  FROM (SELECT DISTINCT ei.id_schedule, ' || --
                                    '                        epis.id_episode, ' || --
                                    '                        pat.id_patient, ' || --
                                    '                        pat.name, ' || --
                                    '                        pat.gender, ' || --
                                    '                        cr.num_clin_record, ' || --
                                    '                        p.id_professional, ' || --
                                    '                        ei.id_dep_clin_serv, ' || --
                                    '                        eea.dt_begin, ' || --
                                    '                        eea.id_exam, ' || --
                                    '                        decode(eea.id_exam_result, NULL, ''N'', ''Y'') flg_result, ' || --
                                    '                        eea.id_exam_req ' || --
                                    '          FROM ' || l_from || ', ' || --
                                    '               clinical_service cs, ' || --
                                    '               professional p, ' || --
                                    '               clin_record cr, ' || --
                                    '               episode epis, ' || --
                                    '               epis_info ei, ' || --
                                    '               exams_ea eea, ' || --
                                    '               schedule_outp sp, ' || --
                                    '               schedule s, ' || --
                                    '               epis_ext_sys ees, ' || --
                                    '               pat_soc_attributes psa, ' || --
                                    '               exam_cat_dcs ecdcs, ' || --
                                    '               (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                    '                  FROM doc_external de ' || --
                                    '                 WHERE de.id_doc_type = ' || l_doc_type || ') de ' || --
                                    '         WHERE eea.id_exam_result IS NOT NULL ' || --
                                    '           AND ecdcs.id_exam_cat = eea.id_exam_cat ' || --
                                    '           AND EXISTS (SELECT 1 ' || --
                                    '                         FROM prof_dep_clin_serv pdcs' || --
                                    '                        WHERE pdcs.id_professional = ' || i_prof.id || ' ' || --
                                    '                          AND pdcs.flg_status = ''' || g_selected || '''' || --
                                    '                          AND pdcs.id_institution = ' || i_prof.institution || ' ' || --
                                    '                          AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv) ' || --
                                    '           AND p.id_professional = eea.id_prof_req ' || --
                                    '           AND cs.id_clinical_service(+) = epis.id_clinical_service' || --
                                    '           AND epis.id_episode = eea.id_episode' || --
                                    '           AND epis.flg_status != ''' || g_epis_canc || '''' || --
                                    '           AND ei.id_episode = epis.id_episode' || --
                                    '           AND sp.id_schedule = ei.id_schedule ' || --
                                    '           AND s.id_instit_requested = ' || i_prof.institution || ' ' || --
                                    '           AND s.id_schedule = sp.id_schedule' || --
                                    '           AND s.flg_status != ''' || g_sched_cancel || '''' || --
                                    '           AND ees.id_episode(+) = epis.id_episode ' || --
                                    '           AND ees.id_institution(+) = ' || i_prof.institution || ' ' || --
                                    '           AND ((ees.id_external_sys = ' || l_external_sys ||
                                    ') OR (ees.id_external_sys IS NULL)) ' || --
                                    '           AND de.id_patient(+) = pat.id_patient' || --
                                    '           AND ((de.id_doc_type = ' || l_doc_type ||
                                    ') OR (de.id_doc_type IS NULL)) ' || --
                                    '           AND ((de.flg_status = ''' || g_doc_active ||
                                    ''') OR (de.flg_status IS NULL)) ' || --
                                    '           AND psa.id_patient(+) = pat.id_patient ' || --
                                    '           AND psa.id_institution(+) = ' || i_prof.institution || ' ' || --
                                    '           AND epis.id_institution = ' || i_prof.institution || ' ' || --
                                    '           AND pat.id_patient = eea.id_patient' || --
                                    '           AND cr.id_patient(+) = pat.id_patient' || --
                                    '           AND cr.id_institution(+) = ' || i_prof.institution || ' ' || l_where || ') ';
                    END IF;
                
                    IF (l_cat = g_flg_adm AND
                       i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_labtech))
                       OR (l_cat = g_flg_tech AND i_prof.software = pk_alert_constant.g_soft_labtech)
                    THEN
                        -- Análises 
                        IF l_cat = g_flg_adm
                        THEN
                            IF instr(l_where, 'eea.dt_begin') != 0
                            THEN
                                l_where_lab := REPLACE(l_where, 'eea.dt_begin', 'lte.dt_target');
                            END IF;
                        ELSE
                            l_where_lab := REPLACE(l_where, 'EPIS.DT_BEGIN_TSTZ', 'lte.dt_target');
                        END IF;
                    
                        g_error  := 'GET CURSOR3.2';
                        aux_sql2 := 'SELECT DISTINCT id_schedule, ' || --
                                    '                id_episode, ' || --
                                    '                id_patient, ' || --
                                    '                name, ' || --
                                    '                pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', gender, ' ||
                                    i_lang || ') gender, ' || --
                                    '                pk_patient.get_pat_age(' || i_lang || ', id_patient, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') pat_age,' || --
                                    '                pk_patphoto.get_pat_photo(' || i_lang || ',' || 'profissional(' ||
                                    i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software ||
                                    '), id_patient, id_episode,id_schedule) photo, ' || --                                   
                                    '                num_clin_record, ' || --
                                    '                pk_prof_utils.get_name_signature(' || i_lang || ', ' || --
                                    '                                                 profissional(' || i_prof.id || ', ' ||
                                    i_prof.institution || ', ' || i_prof.software || '), ' || --
                                    '                                                 id_professional) nick_name, ' || --
                                    '                pk_hea_prv_aux.get_clin_service(' || i_lang || ',profissional(' ||
                                    i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                                    '), id_dep_clin_serv) cons_type,' || --
                                    '                pk_date_utils.trunc_dt_char_tsz (' || i_lang || ', dt_target, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') date_target,' || --
                                    '                pk_date_utils.date_char_hour_tsz (' || i_lang || ', dt_target, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') hour_target, ' || --
                                    '                id_analysis id_exam, ' || --
                                    '                pk_lab_tests_api_db.get_alias_translation(' || i_lang || ', ' || --
                                    '                                                          profissional(' ||
                                    i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || '), ''' ||
                                    pk_lab_tests_constant.g_analysis_alias || ''', ' || --
                                    '                                                          code_analysis, ' || --
                                    '                                                          NULL) desc_exam, ' || --
                                    '                decode(id_analysis_result, NULL, ''N'', ''Y'') flg_result, ' || --
                                    '                id_analysis_req id_exam_req, ' || --
                                    '                pk_date_utils.to_char_insttimezone(' || i_prof.institution || ', ' ||
                                    i_prof.software || ', dt_target, ''YYYYMMDDHH24MISS'') dt_ord1   ' || --
                                    '  FROM (SELECT DISTINCT ei.id_schedule, ' || --
                                    '                        epis.id_episode, ' || --
                                    '                        pat.id_patient, ' || --
                                    '                        pat.name, ' || --
                                    '                        pat.gender, ' || --
                                    '                        cr.num_clin_record, ' || --
                                    '                        p.id_professional, ' || --
                                    '                        ei.id_dep_clin_serv,' || --
                                    '                        lte.dt_target,' || --
                                    '                        lte.id_analysis, ' || --
                                    '                        ''ANALYSIS.CODE_ANALYSIS.'' || lte.id_analysis code_analysis, ' || --
                                    '                        id_analysis_result, ' || --
                                    '                        lte.id_analysis_req ' || --
                                    '          FROM ' || l_from || ', ' || --
                                    '               clinical_service cs, ' || --
                                    '               professional p, ' || --
                                    '               clin_record cr, ' || --
                                    '               episode epis, ' || --
                                    '               epis_info ei, ' || --
                                    '               schedule_outp sp, ' || --
                                    '               schedule s, ' || --
                                    '               epis_ext_sys ees, ' || --
                                    '               pat_soc_attributes psa, ' || --
                                    '               lab_tests_ea lte, ' || --
                                    '               exam_cat ec, ' || --
                                    '               exam_cat_dcs ecdcs, ' || --
                                    '               (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                    '                  FROM doc_external de ' || --
                                    '                 WHERE de.id_doc_type = ' || l_doc_type || ') de ' || --
                                    '         WHERE lte.id_analysis_result IS NOT NULL ' || --
                                    '           AND ecdcs.id_exam_cat = ec.id_exam_cat' || --
                                    '           AND EXISTS (SELECT 1 ' || --
                                    '                         FROM prof_dep_clin_serv pdcs' || --
                                    '                        WHERE pdcs.id_professional = ' || i_prof.id || ' ' || --
                                    '                          AND pdcs.flg_status = ''' || g_selected || '''' || --
                                    '                          AND pdcs.id_institution = ' || i_prof.institution || ' ' || --
                                    '                          AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv) ' || --
                                    '           AND p.id_professional = lte.id_prof_writes ' || --
                                    '           AND cs.id_clinical_service(+) = epis.id_clinical_service' || --
                                    '           AND epis.id_episode = lte.id_episode' || --
                                    '           AND epis.flg_status != ''' || g_epis_canc || '''' || --
                                    '           AND ei.id_episode = epis.id_episode  ' || --
                                    '           AND sp.id_schedule = ei.id_schedule ' || --
                                    '           AND s.id_instit_requested = ' || i_prof.institution || ' ' || --
                                    '           AND s.id_schedule = sp.id_schedule' || --
                                    '           AND s.flg_status != ''' || g_sched_cancel || '''' || --
                                    '           AND ees.id_episode(+) = epis.id_episode' || --
                                    '           AND ees.id_institution(+) = ' || i_prof.institution || ' ' || --
                                    '           AND ((ees.id_external_sys = ' || l_external_sys ||
                                    ') OR (ees.id_external_sys IS NULL)) ' || --
                                    '           AND de.id_patient(+) = pat.id_patient' || --
                                    '           AND ((de.id_doc_type = ' || l_doc_type ||
                                    ') OR (de.id_doc_type IS NULL)) ' || --
                                    '           AND ((de.flg_status = ''' || g_doc_active ||
                                    ''') OR (de.flg_status IS NULL)) ' || --
                                    '           AND psa.id_patient(+) = pat.id_patient ' || --
                                    '           AND psa.id_institution(+) = ' || i_prof.institution || ' ' || --
                                    '           AND epis.id_institution = ' || i_prof.institution || ' ' || --
                                    '           AND pat.id_patient = lte.id_patient' || --
                                    '           AND cr.id_patient(+) = pat.id_patient' || --
                                    '           AND cr.id_institution(+) = ' || i_prof.institution || ' ' ||
                                    l_where_lab || ') ';
                    END IF;
                
                    IF l_cat = g_flg_adm
                       AND i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_labtech)
                    THEN
                        g_error := 'GET CURSOR2 - TOTAL 3.1';
                        OPEN o_info FOR aux_sql1 || ' UNION ALL ' || aux_sql2 || ' ORDER BY date_target, hour_target';
                    
                    ELSIF l_cat = g_flg_tech
                          AND i_prof.software = pk_alert_constant.g_soft_labtech
                    THEN
                        g_error := 'GET CURSOR2 - TOTAL 3.2 [TECHNICIAN]';
                        OPEN o_info FOR aux_sql2 || ' ORDER BY date_target, hour_target';
                    
                    ELSE
                        g_error := 'GET CURSOR2 - TOTAL 3.2';
                        OPEN o_info FOR aux_sql1 || ' ORDER BY date_target, hour_target';
                    END IF;
                ELSE
                    IF l_cat <> g_flg_tech
                       OR i_prof.software <> pk_alert_constant.g_soft_labtech
                    THEN
                        g_error  := 'GET CURSOR4.1';
                        aux_sql1 := 'WITH pdcs AS (SELECT pdcs.Id_Dep_Clin_Serv ' || --
                                    ' FROM prof_dep_clin_serv pdcs ' || --
                                    ' WHERE pdcs.id_professional = ' || i_prof.id || ' ' || --
                                    ' AND pdcs.flg_status = ''' || g_selected || '''' || --
                                    ' AND pdcs.id_institution = ' || i_prof.institution || ') ' || --
                                    ' SELECT DISTINCT id_schedule, ' || --
                                    '                id_episode, ' || --
                                    '                id_patient, ' || --
                                    '                name, ' || --
                                    '                pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', gender, ' ||
                                    i_lang || ') gender, ' || --
                                    '                pk_patient.get_pat_age(' || i_lang || ', id_patient, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') pat_age,' || --
                                    '                pk_patphoto.get_pat_photo(' || i_lang || ',' || 'profissional(' ||
                                    i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software ||
                                    '), id_patient, id_episode,id_schedule) photo, ' || --
                                    '                num_clin_record, ' || --
                                    '                pk_prof_utils.get_name_signature(' || i_lang || ', ' || --
                                    '                                                 profissional(' || i_prof.id || ', ' ||
                                    i_prof.institution || ', ' || i_prof.software || '), ' || --
                                    '                                                 id_professional) nick_name, ' || --
                                    '                pk_hea_prv_aux.get_clin_service(' || i_lang || ',profissional(' ||
                                    i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                                    '), id_dep_clin_serv) cons_type,' || --
                                    '                pk_date_utils.trunc_dt_char_tsz(' || i_lang || ', dt_begin, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') date_target, ' || --
                                    '                pk_date_utils.date_char_hour_tsz(' || i_lang || ', dt_begin, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') hour_target, ' || --
                                    '                id_exam, ' || --
                                    '                pk_exams_api_db.get_alias_translation(' || i_lang || ', ' || --
                                    '                                                      profissional(' || i_prof.id || ', ' ||
                                    i_prof.institution || ', ' || i_prof.software || '), ' || --
                                    '                                                      ''EXAM.CODE_EXAM.'' || id_exam, ' || --
                                    '                                                      NULL) desc_exam, ' || --
                                    '                decode(id_exam_result, NULL, ''N'', ''Y'') flg_result, ' || --
                                    '                id_exam_req, ' || --
                                    '                pk_date_utils.to_char_insttimezone(' || i_prof.institution || ', ' ||
                                    i_prof.software || ', dt_begin, ''YYYYMMDDHH24MISS'') dt_ord1 ' || --
                                    '  FROM (SELECT DISTINCT ei.id_schedule, ' || --
                                    '                        epis.id_episode, ' || --
                                    '                        pat.id_patient, ' || --
                                    '                        pat.name, ' || --
                                    '                        pat.gender, ' || --
                                    '                        cr.num_clin_record, ' || --
                                    '                        p.id_professional, ' || --
                                    '                        ei.id_dep_clin_serv, ' || --
                                    '                        eea.dt_begin, ' || --
                                    '                        eea.id_exam, ' || -- 
                                    '                        eea.id_exam_result, ' || --
                                    '                        eea.id_exam_req ' || --
                                    '          FROM ' || l_from || ', ' || --
                                    '               clinical_service cs, ' || --
                                    '               professional p, ' || --
                                    '               clin_record cr, ' || --
                                    '               episode epis, ' || --
                                    '               epis_info ei, ' || --
                                    '               exams_ea eea, ' || --
                                    '               epis_ext_sys ees, ' || --
                                    '               pat_soc_attributes psa, ' || --
                                    '               exam_cat_dcs ecdcs, ' || --
                                    '               (SELECT DISTINCT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                    '                  FROM doc_external de ' || --
                                    '                 WHERE de.id_doc_type = ' || l_doc_type || ') de, ' || --
                                    '                pdcs ' || --
                                    '         WHERE eea.flg_status_det IN (''F'', ''L'', ''EP'', ''EX'') ' || --
                                    '           AND ecdcs.id_exam_cat = eea.id_exam_cat ' || --
                                   
                                    '           AND ecdcs.id_dep_clin_serv  = pdcs.id_dep_clin_serv ' || --
                                    '           AND p.id_professional = eea.id_prof_req ' || --
                                    '           AND cs.id_clinical_service(+) = epis.id_clinical_service' || --
                                    '           AND epis.id_episode = eea.id_episode' || --
                                    '           AND epis.flg_status != ''' || g_epis_canc || '''' || --
                                    '           AND ei.id_episode = epis.id_episode' || --
                                    '           AND ees.id_episode(+) = epis.id_episode ' || --
                                    '           AND ees.id_institution(+) = ' || i_prof.institution || ' ' || --
                                    '           AND ((ees.id_external_sys = ' || l_external_sys ||
                                    ') OR (ees.id_external_sys IS NULL)) ' || --
                                    '           AND de.id_patient(+) = pat.id_patient' || --
                                    '           AND ((de.id_doc_type = ' || l_doc_type ||
                                    ') OR (de.id_doc_type IS NULL)) ' || --
                                    '           AND ((de.flg_status = ''' || g_doc_active ||
                                    ''') OR (de.flg_status IS NULL)) ' || --
                                    '           AND psa.id_patient(+) = pat.id_patient ' || --
                                    '           AND psa.id_institution(+) = ' || i_prof.institution || ' ' || --
                                    '           AND epis.id_institution = ' || i_prof.institution || ' ' || --
                                    '           AND pat.id_patient = eea.id_patient' || --
                                    '           AND cr.id_patient(+) = pat.id_patient' || --
                                    '           AND cr.id_institution(+) = ' || i_prof.institution || ' ' ||
                                    l_exam_type_cond || l_where || ') ';
                    END IF;
                
                    IF (l_cat = g_flg_adm AND
                       i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_labtech))
                       OR (l_cat = g_flg_tech AND i_prof.software = pk_alert_constant.g_soft_labtech)
                    THEN
                        -- Análises 
                        IF l_cat = g_flg_adm
                        THEN
                            IF instr(l_where, 'eea.dt_begin') != 0
                            THEN
                                l_where_lab := REPLACE(l_where, 'eea.dt_begin', 'lte.dt_target');
                            END IF;
                        ELSE
                            l_where_lab := REPLACE(l_where, 'EPIS.DT_BEGIN_TSTZ', 'lte.dt_target');
                        END IF;
                    
                        g_error  := 'GET CURSOR4.2';
                        aux_sql2 := 'SELECT DISTINCT id_schedule, ' || --
                                    '                id_episode, ' || --
                                    '                id_patient, ' || --
                                    '                name, ' || --
                                    '                pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', gender, ' ||
                                    i_lang || ') gender, ' || --
                                    '                pk_patient.get_pat_age(' || i_lang || ', id_patient, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') pat_age,' || --
                                    '                pk_patphoto.get_pat_photo(' || i_lang || ',' || 'profissional(' ||
                                    i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software ||
                                    '), id_patient, id_episode,id_schedule) photo, ' || --                                   
                                    '                num_clin_record, ' || --
                                    '                pk_prof_utils.get_name_signature(' || i_lang || ', ' || --
                                    '                                                 profissional(' || i_prof.id || ', ' ||
                                    i_prof.institution || ', ' || i_prof.software || '), ' || --
                                    '                                                 id_professional) nick_name, ' || --
                                    '                pk_hea_prv_aux.get_clin_service(' || i_lang || ',profissional(' ||
                                    i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                                    '), id_dep_clin_serv) cons_type,' || --
                                    '                pk_date_utils.trunc_dt_char_tsz (' || i_lang || ', dt_target, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') date_target,' || --
                                    '                pk_date_utils.date_char_hour_tsz (' || i_lang || ', dt_target, ' ||
                                    i_prof.institution || ', ' || i_prof.software || ') hour_target, ' || --
                                    '                id_analysis id_exam, ' || --
                                    '                pk_lab_tests_api_db.get_alias_translation(' || i_lang || ', ' || --
                                    '                                                          profissional(' ||
                                    i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || '), ''' ||
                                    pk_lab_tests_constant.g_analysis_alias || ''', ' || --
                                    '                                                          code_analysis, ' || --
                                    '                                                          NULL) desc_exam, ' || --
                                    '                decode(id_analysis_result, NULL, ''N'', ''Y'') flg_result, ' || --
                                    '                id_analysis_req id_exam_req, ' || --
                                    '                pk_date_utils.to_char_insttimezone(' || i_prof.institution || ', ' ||
                                    i_prof.software || ', dt_target, ''YYYYMMDDHH24MISS'') dt_ord1 ' || --
                                    '  FROM ( WITH prof_dep AS ' || --
                                    '         (SELECT pdcs.id_dep_clin_serv ' || --
                                    '            FROM prof_dep_clin_serv pdcs ' || --
                                    '           WHERE pdcs.id_professional = ' || i_prof.id || --
                                    '             AND pdcs.flg_status = ''' || g_selected || ''' ' || --
                                    '             AND pdcs.id_institution = ' || i_prof.institution || ') ' || --'
                                    '        SELECT DISTINCT ei.id_schedule, ' || --
                                    '                        epis.id_episode, ' || --
                                    '                        pat.id_patient, ' || --
                                    '                        pat.name, ' || --
                                    '                        pat.gender, ' || --
                                    '                        cr.num_clin_record, ' || --
                                    '                        p.id_professional, ' || --
                                    '                        ei.id_dep_clin_serv,' || --
                                    '                        lte.dt_target,' || --
                                    '                        lte.id_analysis, ' || --
                                    '                        ''ANALYSIS.CODE_ANALYSIS.'' || lte.id_analysis code_analysis, ' || --
                                    '                        id_analysis_result, ' || --
                                    '                        lte.id_analysis_req ' || --
                                    '          FROM ' || l_from || ', ' || --
                                    '               clinical_service cs, ' || --
                                    '               professional p, ' || --
                                    '               clin_record cr, ' || --
                                    '               episode epis, ' || --
                                    '               epis_info ei, ' || --
                                    '               epis_ext_sys ees, ' || --
                                    '               pat_soc_attributes psa, ' || --
                                    '               lab_tests_ea lte, ' || --
                                    '               exam_cat_dcs ecdcs, ' || --
                                    '               prof_dep pdcs, ' || --
                                    '               (SELECT de.id_doc_type, de.flg_status, de.id_patient, de.num_doc ' || --
                                    '                  FROM doc_external de ' || --
                                    '                 WHERE (de.id_doc_type = ' || l_doc_type ||
                                    ' OR de.id_doc_type IS NULL) ' || --
                                    '                   AND (de.flg_status = ''' || g_doc_active ||
                                    ''' OR de.flg_status IS NULL)) de ' || --
                                    '         WHERE lte.id_analysis_result IS NOT NULL ' || --
                                    '           AND ecdcs.id_exam_cat = lte.id_exam_cat ' || --
                                    '           AND ecdcs.id_dep_clin_serv = pdcs.id_dep_clin_serv ' || --
                                    '           AND p.id_professional = lte.id_prof_writes ' || --
                                    '           AND cs.id_clinical_service(+) = epis.id_clinical_service' || --
                                    '           AND epis.id_episode = lte.id_episode' || --
                                    '           AND epis.flg_status != ''' || g_epis_canc || '''' || --
                                    '           AND ei.id_episode = epis.id_episode ' || --
                                    '           AND ees.id_episode(+) = epis.id_episode ' || --
                                    '           AND ees.id_institution(+) = ' || i_prof.institution || ' ' || --
                                    '           AND ((ees.id_external_sys = ' || l_external_sys ||
                                    ') OR (ees.id_external_sys IS NULL))' || --
                                    '           AND de.id_patient(+) = pat.id_patient' || --
                                    '           AND psa.id_patient(+) = pat.id_patient ' || --
                                    '           AND psa.id_institution(+) = ' || i_prof.institution || ' ' || --
                                    '           AND epis.id_institution = ' || i_prof.institution || ' ' || --
                                    '           AND pat.id_patient = lte.id_patient' || --
                                    '           AND cr.id_patient(+) = pat.id_patient' || --
                                    '           AND cr.id_institution(+) = ' || i_prof.institution || ' ' ||
                                    l_where_lab || ') ';
                    END IF;
                
                    IF l_cat = g_flg_adm
                       AND i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_labtech)
                    THEN
                        g_error := 'GET CURSOR2 - TOTAL 4.1';
                        OPEN o_info FOR aux_sql1 || ' UNION ALL ' || aux_sql2 || ' ORDER BY date_target, hour_target';
                    
                    ELSIF l_cat = 'T'
                          AND i_prof.software = pk_alert_constant.g_soft_labtech
                    THEN
                        g_error := 'GET CURSOR2 - TOTAL 4.2 [TECHNICIAN]';
                        OPEN o_info FOR aux_sql2 || ' ORDER BY date_target, hour_target';
                    
                    ELSE
                        g_error := 'GET CURSOR2 - TOTAL 4.2';
                        OPEN o_info FOR aux_sql1 || ' ORDER BY date_target, hour_target';
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_info);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_EXAM_SEARCH', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_info);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_EXAM_SEARCH', o_error);
        
        WHEN invalid_number THEN
            pk_types.open_my_cursor(o_info);
        
            RETURN pk_search.invalid_number_handler(i_lang, i_prof, g_package_name, 'GET_EXAM_SEARCH', o_error);
        
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_EXAM_SEARCH',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_EXAM_SEARCH',
                                              'S',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_info);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_exam_search;

    FUNCTION get_cod_diag_criteria
    (
        i_lang      IN language.id_language%TYPE,
        i_value     IN VARCHAR2,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_diag      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE DIAGNÓSTICOS ATRAVES DO CODIGO 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                I_VALUE - VALOR DO CRITÉRIO DE PESQUISA 
             I_PROF - PROFISSIONAL Q PESQUISA 
                  SAIDA: O_FLG_SHOW - Y - EXISTE MSG PARA MOSTRAR; N - Ñ EXISTE  
                 O_MSG - MENSAGEM COM INDICAÇÃO DE Q ULTRAPASSOU O Nº LIMITE DE REGISTOS 
                 O_MSG_TITLE - TÍTULO DA MSG A MOSTRAR AO UTILIZADOR, CASO 
                 O_FLG_SHOW = Y 
                 O_BUTTON - BOTÕES A MOSTRAR: N - NÃO, R - LIDO, C - CONFIRMADO 
                    TB PODE MOSTRAR COMBINAÇÕES DESTES, QD É P/ MOSTRAR 
                    + DO Q 1 BOTÃO 
             O_DIAG -  DIAGNÓSTICOS
                 O_ERROR - ERRO 
          
          CRIAÇÃO: Teresa Coutinho 05/06/2007 
          
          NOTAS: LG 2007-MAR-21 ENTRAR EM CONTA COM A CONFIGURAÇÃO DE TIPOS DE DIAGNÓSTICO EM USO NO SOFTWARE/INSTITUIÇÃO
        *********************************************************************************/
        l_diagnosis_type      sys_config.value%TYPE;
        l_synonym_list_enable sys_config.value%TYPE;
    
        CURSOR c_pat IS
            SELECT pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', patient.gender, i_lang) gender,
                   months_between(SYSDATE, dt_birth) / 12 age --, (SYSDATE-DT_BIRTH) DAYS
              FROM patient
             WHERE id_patient = i_patient;
        r_pat c_pat%ROWTYPE;
    
        CURSOR c_adiag_rowids IS
            SELECT DISTINCT dc.rowid_alert_diag
              FROM diagnosis_content dc
             WHERE -- show only available diagnoses
             dc.flg_available = g_diag_available
            -- show only available alert diagnoses
             AND dc.flg_available_alert_diagnosis = g_diag_available
            -- depending on synonym list enable cfg's, show diagnosis synonyms or not
             AND (dc.flg_icd9 = g_yes OR l_synonym_list_enable = g_yes)
            -- show only selectable diagnoses
             AND dc.flg_select = pk_alert_constant.g_yes
            -- show only "medical past history" type of diagnoses 
             AND dc.flg_type_alert_diagnosis = 'M'
            -- allow only searchable diagnoses
             AND dc.flg_type_dep_clin = 'P'
             AND translate(upper(dc.code_icd), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ', 'AEIOUAEIOUAEIOUAOCAEIOUN') LIKE
             '%' || translate(upper(i_value), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ ', 'AEIOUAEIOUAEIOUAOCAEIOUN%') || '%'
             AND dc.id_institution = i_prof.institution
             AND dc.id_software = i_prof.software
             AND dc.flg_type IN
             (SELECT /*+opt_estimate(table,tdgc,scale_rows=1))*/
               column_value flg_terminology
                FROM TABLE(pk_diagnosis_core.get_diag_terminologies(i_lang      => i_lang,
                                                                    i_prof      => i_prof,
                                                                    i_task_type => pk_alert_constant.g_task_diagnosis)) tdgc)
             AND ((r_pat.gender IS NOT NULL AND nvl(dc.gender, 'I') IN ('I', r_pat.gender)) OR r_pat.gender IS NULL OR
             r_pat.gender = 'I')
             AND (nvl(r_pat.age, 0) BETWEEN nvl(dc.age_min, 0) AND nvl(dc.age_max, nvl(r_pat.age, 0)) OR
             nvl(r_pat.age, 0) = 0)
             AND ((r_pat.gender IS NOT NULL AND nvl(dc.gender_alert_diagnosis, 'I') IN ('I', r_pat.gender)) OR
             r_pat.gender IS NULL OR r_pat.gender IN ('I', 'U', 'N'))
             AND (nvl(r_pat.age, 0) BETWEEN nvl(dc.age_min_alert_diagnosis, 0) AND
             nvl(dc.age_max_alert_diagnosis, nvl(r_pat.age, 0)) OR nvl(r_pat.age, 0) = 0)
             AND dc.code_alert_diagnosis IS NOT NULL;
    
        l_count        NUMBER;
        l_adiag_rowids table_varchar;
        l_limit        sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        l_limit        := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        o_flg_show     := 'N';
    
        -- enable/disable synonyms in search and reply result sets
        l_synonym_list_enable := nvl(pk_sysconfig.get_config('DIAGNOSIS_SYNONYMS_LIST_ENABLE', i_prof), g_no);
    
        g_error := 'OPEN C_PAT';
        OPEN c_pat;
        FETCH c_pat
            INTO r_pat;
        CLOSE c_pat;
    
        BEGIN
            g_error := 'OPEN C_ADIAG_ROWIDS';
            OPEN c_adiag_rowids;
            FETCH c_adiag_rowids BULK COLLECT
                INTO l_adiag_rowids;
            CLOSE c_adiag_rowids;
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
        END;
    
        -- check the limit
        l_count := l_adiag_rowids.count;
        IF l_count > l_limit
        THEN
            o_flg_show  := 'Y';
            o_msg       := get_overlimit_message(i_lang, i_prof, pk_alert_constant.g_yes, l_limit);
            o_msg_title := pk_message.get_message(i_lang, 'SEARCH_CRITERIA_T011');
            o_button    := 'DW';
        ELSIF l_count = 0
        THEN
            o_flg_show := '0';
        END IF;
    
        g_error := 'GET CURSOR';
        OPEN o_diag FOR
            SELECT /*+ordered use_nl(adiag dc)*/
            DISTINCT pk_diagnosis.std_diag_desc(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_alert_diagnosis => dc.id_alert_diagnosis,
                                                i_code               => dc.code_icd,
                                                i_flg_other          => dc.flg_other,
                                                i_flg_std_diag       => dc.flg_icd9) diag,
                     dc.id_diagnosis,
                     dc.code_icd,
                     0 rank,
                     'Y' flg_select,
                     dc.flg_other,
                     dc.id_alert_diagnosis
              FROM (SELECT column_value
                      FROM TABLE(l_adiag_rowids)) adiag
              JOIN diagnosis_content dc
                ON dc.rowid_alert_diag = adiag.column_value
             WHERE rownum <= l_limit
             ORDER BY diag;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_COD_DIAG_CRITERIA',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_diag);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_COD_DIAG_CRITERIA',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_diag);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_cod_diag_criteria;

    /**********************************************************************************************
    * Efectuar pesquisa de doentes INACTIVOS,de acordo com os critérios seleccionados, para pessoal clínico (médicos e enfermeiros)
    *
    * @param i_lang                   the id language
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_instit                 institution id
    * @param i_epis_type              episode type
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_cat_type          professional category   
    * @param o_flg_show                
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_pat                    array with patient active
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    *  @author RB 2005/04/22 
    *      ALTERAÇÃO: CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS 
    *           ASM 2006/12/27 INCLUIR NÃO SÓ OS EPISÓDIOS COM ALTA ADMINISTRATIVA, MAS TAMBÉM OS COM ALTA MÉDICA E OS EPISÓDIOS 
    *                        QUE FORAM FECHADOS AUTOMATICAMENTE 
    *                                LIGAÇÃO À TABELA DOC_EXTERNAL PARA OS DOCUMENTOS, EM VEZ DA PAT_DOC 
    *
    * @author                         Sérgio Santos (Restructure)
    * @since                          2009/02/03
    **********************************************************************************************/
    FUNCTION get_pat_criteria_inact_clin_o
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where VARCHAR2(4000);
    
    BEGIN
    
        o_flg_show := 'N';
        g_sysdate  := SYSDATE;
    
        l_where := NULL;
    
        IF NOT pk_search.get_where(i_criteria => i_id_sys_btn_crit,
                                   i_crit_val => i_crit_val,
                                   o_where    => l_where,
                                   i_lang     => i_lang,
                                   i_prof     => i_prof)
        THEN
            l_where := NULL;
        END IF;
    
        g_error      := 'CONCAT CURSOR O_PAT';
        g_no_results := FALSE;
        g_overlimit  := FALSE;
    
        OPEN o_pat FOR
            SELECT *
              FROM TABLE(tf_pat_criteria_inactive_clin(i_lang, i_prof, l_where, i_dt_str));
    
        IF g_no_results = TRUE
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF g_overlimit = TRUE
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang,
                                               i_prof,
                                               g_package_name,
                                               'GET_PAT_CRITERIA_INACTIVE_CLI',
                                               o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_INACTIVE_CLI', o_error);
        
        WHEN OTHERS THEN
            DECLARE
                l_id PLS_INTEGER;
            BEGIN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => g_owner_name,
                                                  i_package  => g_package_name,
                                                  i_function => 'GET_PAT_CRITERIA_INACTIVE_CLI',
                                                  o_error    => o_error);
                pk_alert_exceptions.reset_error_state;
                pk_types.open_my_cursor(o_pat);
                RETURN FALSE;
            END;
    END get_pat_criteria_inact_clin_o;

    FUNCTION tf_pat_criteria_inactive_clin
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_where  IN VARCHAR2,
        i_dt_str IN VARCHAR2
    ) RETURN t_coll_patcritinactiveclin IS
    
        dataset        pk_types.cursor_type;
        l_limit        sys_config.desc_sys_config%TYPE;
        l_sysdate_char VARCHAR2(32);
        l_prof_cat     category.flg_type%TYPE;
        l_date         TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_external_sys sys_config.value%TYPE;
        l_nurse_et     sys_config.value%TYPE;
        l_profile      VARCHAR2(50);
    
        out_obj t_rec_patcritinactiveclin := t_rec_patcritinactiveclin(NULL,
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
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL,
                                                                       NULL);
    
        TYPE dataset_tt IS TABLE OF v_src_inactive_clin%ROWTYPE INDEX BY PLS_INTEGER;
        l_dataset dataset_tt;
        l_row     PLS_INTEGER := 1;
    
        RESULT t_coll_patcritinactiveclin := t_coll_patcritinactiveclin();
    
        TYPE t_rec_translation IS RECORD(
            desc_translation pk_translation.t_desc_translation);
        TYPE t_tbl_translation IS TABLE OF t_rec_translation INDEX BY translation.code_translation%TYPE;
    
        translation_cache t_tbl_translation;
    
        -- Função que faz cache das chamadas à pk_translation.get_translation
        FUNCTION get_translation(code_translation translation.code_translation%TYPE)
            RETURN pk_translation.t_desc_translation IS
        
        BEGIN
            IF (NOT translation_cache.exists(code_translation))
            THEN
                translation_cache(code_translation).desc_translation := pk_translation.get_translation(i_lang,
                                                                                                       code_translation);
            END IF;
            RETURN translation_cache(code_translation).desc_translation;
        END;
    
        -- Função que faz cache das chamadas à pk_translation.get_translation_dtchk
        FUNCTION get_translation_dtchk(code_translation translation.code_translation%TYPE)
            RETURN pk_translation.t_desc_translation IS
        
        BEGIN
            IF (NOT translation_cache.exists(code_translation))
            THEN
                translation_cache(code_translation).desc_translation := pk_translation.get_translation_dtchk(i_lang,
                                                                                                             code_translation);
            END IF;
            RETURN translation_cache(code_translation).desc_translation;
        END;
    
    BEGIN
    
        l_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        l_prof_cat     := pk_prof_utils.get_category(i_lang, i_prof);
    
        IF i_dt_str IS NULL
        THEN
            l_date := pk_date_utils.trunc_insttimezone(i_prof,
                                                       
                                                       current_timestamp + INTERVAL '1' DAY);
        
        ELSE
            l_date := pk_date_utils.trunc_insttimezone(i_prof,
                                                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_str, NULL) +
                                                       INTERVAL '1' DAY);
        
        END IF;
    
        l_external_sys := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
        l_nurse_et     := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof.institution, i_prof.software);
    
        g_error := 'GET LIMIT';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('id_ext_sys', l_external_sys);
        pk_context_api.set_parameter('id_nurse_et', l_nurse_et);
        pk_context_api.set_parameter('g_epis_active', g_epis_active);
        pk_context_api.set_parameter('l_date', l_date);
    
        SELECT cat.flg_type
          INTO l_profile
          FROM category cat, prof_cat pct
         WHERE cat.id_category = pct.id_category
           AND pct.id_professional = i_prof.id
           AND pct.id_institution = i_prof.institution;
    
        g_error := 'OPEN CURSOR';
    
        OPEN dataset FOR 'SELECT * FROM V_PAT_CRIT_INACTIVE_CLIN t WHERE rownum <= :limit + 1 ' || i_where || ' ' || 'ORDER BY t.dt_target_tstz'
            USING l_limit;
    
        g_error := 'FETCH FROM RESULTS CURSOR';
        FETCH dataset BULK COLLECT
            INTO l_dataset;
        g_error := 'CLOSE RESULTS CURSOR';
        CLOSE dataset;
    
        g_error := 'COUNT RESULTS';
        IF (l_dataset.count > l_limit)
        THEN
            g_overlimit := TRUE;
            RETURN RESULT;
        ELSE
            IF (l_dataset.count = 0)
            THEN
                g_no_results := TRUE;
            END IF;
        END IF;
    
        g_error := 'EXTEND RESULT ARRAY';
        IF (l_dataset.count < l_limit)
        THEN
            result.extend(l_dataset.count);
        ELSE
            result.extend(l_limit);
        END IF;
    
        l_row := l_dataset.first;
    
        g_error := 'GET DATA';
        WHILE (l_row <= result.count)
        LOOP
            out_obj.id_schedule     := l_dataset(l_row).id_schedule;
            out_obj.id_patient      := l_dataset(l_row).id_patient;
            out_obj.num_clin_record := l_dataset(l_row).num_clin_record;
            out_obj.id_episode      := l_dataset(l_row).id_episode;
            out_obj.name            := pk_patient.get_pat_name(i_lang,
                                                               i_prof,
                                                               l_dataset(l_row).id_patient,
                                                               l_dataset(l_row).id_episode,
                                                               l_dataset(l_row).id_schedule);
            out_obj.pat_ndo         := pk_adt.get_pat_non_disc_options(i_lang, i_prof, l_dataset(l_row).id_patient);
            out_obj.pat_nd_icon     := pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, l_dataset(l_row).id_patient);
            -- cached
            out_obj.gender      := pk_patient.get_gender(i_lang, l_dataset(l_row).gender);
            out_obj.pat_age     := pk_patient.get_pat_age(i_lang,
                                                          l_dataset         (l_row).dt_birth,
                                                          l_dataset         (l_row).age,
                                                          i_prof.institution,
                                                          i_prof.software);
            out_obj.photo       := pk_patphoto.get_pat_photo(i_lang,
                                                             i_prof,
                                                             l_dataset(l_row).id_patient,
                                                             l_dataset(l_row).id_episode,
                                                             l_dataset(l_row).id_schedule);
            out_obj.cons_type   := CASE l_dataset(l_row).code_clinical_service
                                       WHEN NULL THEN
                                        NULL
                                       ELSE
                                        pk_translation.get_translation(i_lang, l_dataset(l_row).code_clinical_service)
                                   END;
            out_obj.hour_target := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    l_dataset(l_row).dt_target_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software);
            out_obj.date_target := pk_date_utils.trunc_dt_char_tsz(i_lang,
                                                                   l_dataset(l_row).dt_target_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software);
            out_obj.nick_name   := l_dataset(l_row).nick_name;
            out_obj.flg_state   := l_dataset(l_row).flg_state;
            out_obj.dt_server   := l_sysdate_char;
            out_obj.img_sched   := lpad(to_char(l_dataset(l_row).rank), 6, '0') || l_dataset(l_row).img_name;
            out_obj.dt_efectiv  := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                    l_dataset(l_row).dt_begin_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software);
            --out_obj.desc_speciality   := CASE nvl(l_dataset(l_row).code_speciality1, l_dataset(l_row).code_speciality) WHEN NULL THEN NULL ELSE pk_translation.get_translation(i_lang, nvl(l_dataset(l_row).code_speciality1, l_dataset(l_row).code_speciality)) END;
            out_obj.disch_dest        := CASE l_dataset(l_row).id_discharge_dest
                                             WHEN '' THEN
                                              (CASE l_dataset(l_row).id_dep_clin_serv
                                                  WHEN '' THEN
                                                   (CASE l_dataset(l_row).id_institution_drt
                                                       WHEN '' THEN
                                                        ''
                                                       ELSE
                                                        (CASE l_dataset(l_row).code_institution
                                                            WHEN NULL THEN
                                                             NULL
                                                            ELSE
                                                             pk_translation.get_translation(i_lang,
                                                                                            l_dataset(l_row).code_institution)
                                                        END)
                                                   END)
                                                  ELSE
                                                   ((CASE l_dataset(l_row).code_department
                                                       WHEN NULL THEN
                                                        NULL
                                                       ELSE
                                                        pk_translation.get_translation(i_lang,
                                                                                       l_dataset(l_row).code_department)
                                                   END) || ' - ' || (CASE l_dataset(l_row).code_clinical_service2
                                                       WHEN NULL THEN
                                                        NULL
                                                       ELSE
                                                        pk_translation.get_translation(i_lang,
                                                                                       l_dataset(l_row).code_clinical_service2)
                                                   END))
                                              END)
                                             ELSE
                                              (CASE l_dataset(l_row).code_discharge_dest
                                                  WHEN NULL THEN
                                                   NULL
                                                  ELSE
                                                   pk_translation.get_translation(i_lang,
                                                                                  l_dataset(l_row).code_discharge_dest)
                                              END)
                                         END;
            out_obj.desc_drug_presc   := pk_grid.convert_grid_task_str(i_lang, i_prof, l_dataset(l_row).drug_presc);
            out_obj.desc_interv_presc := pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                i_prof,
                                                                                l_dataset(l_row).intervention);
            out_obj.desc_analysis_req := pk_grid.visit_grid_task_str(i_lang,
                                                                     i_prof,
                                                                     l_dataset(l_row).id_visit,
                                                                     g_task_analysis,
                                                                     l_profile);
            out_obj.desc_exam_req     := pk_grid.visit_grid_task_str(i_lang,
                                                                     i_prof,
                                                                     l_dataset(l_row).id_visit,
                                                                     g_task_exam,
                                                                     l_profile);
            out_obj.dt_ord1           := pk_date_utils.to_char_insttimezone(i_prof.institution,
                                                                            i_prof.software,
                                                                            l_dataset(l_row).dt_target_tstz,
                                                                            'YYYYMMDDHH24MISS');
        
            RESULT(l_row) := out_obj;
        
            l_row := l_row + 1;
        END LOOP;
    
        RETURN(RESULT);
    
    END tf_pat_criteria_inactive_clin;

    FUNCTION get_pat_criteria_inactive_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt_str          IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   EFECTUAR PESQUISA DE DOENTES INACTIVOS, DE ACORDO COM OS CRITÉRIOS SELECCIONADOS 
           PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                   I_ID_SYS_BTN_CRIT - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
                   I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA
                 I_INSTIT - INSTITUIÇÃO 
                   I_PROF - PROFISSIONAL 
                 I_PROF_CAT_TYPE - TIPO DE CATEGORIA DO PROFISSIONAL, TAL 
                       COMO É RETORNADA EM PK_LOGIN.GET_PROF_PREF 
                  SAIDA: O_PAT - DOENTES 
                 O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
                 O_ERROR - ERRO 
          
          CRIAÇÃO: RB 2005/04/22 
          ALTERAÇÃO: CRS 2006/07/20 EXCLUIR EPISÓDIOS CANCELADOS 
               ASM 2006/12/27 INCLUIR NÃO SÓ OS EPISÓDIOS COM ALTA ADMINISTRATIVA, MAS TAMBÉM OS COM ALTA MÉDICA E OS EPISÓDIOS 
                            QUE FORAM FECHADOS AUTOMATICAMENTE 
                                    LIGAÇÃO À TABELA DOC_EXTERNAL PARA OS DOCUMENTOS, EM VEZ DA PAT_DOC 
        
          NOTAS: 
        *********************************************************************************/
        l_where                VARCHAR2(32767);
        l_from                 VARCHAR2(32767);
        l_hint                 criteria.hint_condition%TYPE;
        l_order_by             VARCHAR2(12 CHAR);
        l_date                 TIMESTAMP WITH LOCAL TIME ZONE;
        l_count                NUMBER;
        l_limit                sys_config.value%TYPE;
        l_sql                  VARCHAR2(32767);
        l_nurse_et             sys_config.value%TYPE;
        l_prof_cat             category.flg_type%TYPE;
        l_et_access            table_number := table_number();
        l_handoff_type         sys_config.value%TYPE;
        l_episode_access       sys_config.value%TYPE;
        l_validate_epis_status VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_appointment_type     VARCHAR2(1 CHAR);
        l_type_encounter_label pk_translation.t_desc_translation;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        o_flg_show     := 'N';
    
        l_limit          := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_episode_access := pk_sysconfig.get_config('DOCTOR_NURSE_APPOINTMENT_ACCESS', i_prof);
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        --OBTEM MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER DADOS
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        --OBTER DATA DO SISTEMA PARA MOSTRAR APENAS EPISÓDIOS INACTIVOS FECHADOS HOJE 
        g_error := 'GET l_date';
        IF i_dt_str IS NULL
        THEN
            l_date := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz + INTERVAL '1' DAY);
        
        ELSE
            l_date := pk_date_utils.trunc_insttimezone(i_prof,
                                                       pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_str, NULL) +
                                                       INTERVAL '1' DAY);
        
        END IF;
    
        l_nurse_et := nvl(pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof), -2);
    
        set_context_parameters(i_lang => i_lang, i_prof => i_prof);
    
        g_error := 'CALL get_from_and_where';
        IF NOT get_from_and_where(i_lang     => i_lang,
                                  i_prof     => i_prof,
                                  i_crit_id  => i_id_sys_btn_crit,
                                  i_crit_val => i_crit_val,
                                  o_from     => l_from,
                                  o_hint     => l_hint,
                                  o_where    => l_where,
                                  o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- in the paramedical profiles when searching for follow ups it is necessary to search 
        -- for all kind of epis types with follow ups
        l_appointment_type := sys_context('ALERT_CONTEXT', 'SEARCH_P250');
        IF (l_appointment_type = 'F')
        THEN
            g_error := 'Get all epis types list';
            SELECT e.id_epis_type
              BULK COLLECT
              INTO l_et_access
              FROM epis_type e
             WHERE e.id_epis_type > 0;
        
            l_validate_epis_status := pk_alert_constant.g_no;
        ELSE
            g_error     := 'CALL get_epis_type_access';
            l_et_access := get_epis_type_access(i_prof => i_prof, i_grp_inst => table_number(i_prof.institution));
        END IF;
    
        IF l_appointment_type IS NOT NULL
        THEN
            l_type_encounter_label := pk_sysdomain.get_domain(i_code_dom => 'TYPE_OF_ENCOUNTER',
                                                              i_val      => l_appointment_type,
                                                              i_lang     => i_lang);
        END IF;
    
        g_error := 'GET COUNT';
        l_sql   := '
SELECT COUNT(1)
  FROM epis_info ei
  JOIN episode epis
    ON ei.id_episode = epis.id_episode
   JOIN patient pat
    ON epis.id_patient = pat.id_patient
  JOIN clin_record cr
    ON pat.id_patient = cr.id_patient
  LEFT JOIN clinical_service cs
    ON (epis.id_cs_requested = cs.id_clinical_service)
  LEFT JOIN clinical_service cs2
    ON epis.id_clinical_service = cs2.id_clinical_service
  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
         t.column_value id_epis_type
          FROM TABLE(:l_et_access) t) eta
    ON epis.id_epis_type = eta.id_epis_type
    OR (eta.id_epis_type = 0 AND pk_utils.search_table_number(:l_et_access, epis.id_epis_type) = -1)
  LEFT JOIN  schedule_outp sp
    ON sp.id_schedule = ei.id_schedule
  LEFT JOIN schedule s
    ON sp.id_schedule = s.id_schedule
  LEFT JOIN sch_group sg
    ON sp.id_schedule = sg.id_schedule
    AND sg.id_patient = epis.id_patient
 ' || l_from || '
  LEFT JOIN professional p
    ON ei.id_professional = p.id_professional
  LEFT JOIN discharge d
    ON epis.id_episode = d.id_episode
   AND d.dt_cancel_tstz IS NULL
 WHERE (ei.id_software = :i_prof_software OR :i_prof_software = :g_soft_nutritionist OR :i_prof_software = :g_soft_social OR :i_prof_software = :g_soft_psychologist OR :i_prof_software = :g_soft_resptherap)
   AND (sp.dt_target_tstz <= :l_date OR
       sp.dt_target_tstz IS NULL)
   AND epis.id_institution = :i_prof_institution

   AND cr.flg_status = :g_clin_active
   AND cr.id_institution = :i_prof_institution
   AND (epis.flg_status NOT IN (:g_epis_active, :g_epis_canc))
   AND epis.id_epis_type NOT IN (:g_epis_type_rad, :g_epis_type_exm, :g_epis_type_lab, :g_epis_type_interv)
   AND epis.flg_ehr != :g_flg_ehr_e
   AND ((epis.id_epis_type = :g_epis_nurse and :g_flg_access = :g_yes) OR epis.id_epis_type <> :g_epis_nurse ) 
 ' || l_where || '
   AND rownum <= :l_limit + 1';
    
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE l_sql
            INTO l_count
            USING --
        l_et_access, --
        l_et_access, --
        i_prof.software, --
        i_prof.software, --
        pk_alert_constant.g_soft_nutritionist, --
        i_prof.software, pk_alert_constant.g_soft_social, --
        i_prof.software, pk_alert_constant.g_soft_psychologist, --
        i_prof.software, pk_alert_constant.g_soft_resptherap, --
        l_date, --
        i_prof.institution, --
        g_clin_active, --
        i_prof.institution, --
        g_epis_active, --
        g_epis_canc, --
        g_epis_type_rad, --
        g_epis_type_exm, --
        g_epis_type_lab, --
        g_epis_type_interv, --
        pk_visit.g_flg_ehr_e, l_nurse_et, l_episode_access, pk_alert_constant.g_yes, l_nurse_et, l_limit;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        ELSIF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        l_prof_cat := pk_tools.get_prof_cat(i_prof => i_prof);
    
        IF l_from IS NOT NULL
        THEN
            l_order_by := 'position, ';
        END IF;
    
        l_sql := '
SELECT s.id_schedule,
       epis.id_patient,
       cr.num_clin_record,
       pk_prof_utils.get_name_signature(:i_lang, :i_prof, ei.id_professional) nick_name,
       ei.id_episode,
       pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) name,
       pk_patient.get_pat_name_to_sort(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
       pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) pat_ndo,
       pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) pat_nd_icon,
       pk_hand_off_api.get_resp_icons(:i_lang, :i_prof, epis.id_episode, :l_handoff_type) resp_icon,
       pk_patient.get_gender(:i_lang, pat.gender) gender,
       (SELECT pk_patient.get_pat_age(:i_lang, pat.dt_birth, pat.age, :i_prof_institution, :i_prof_software)
          FROM dual) pat_age,
       pk_patphoto.get_pat_photo(:i_lang, :i_prof, pat.id_patient, epis.id_episode, s.id_schedule) photo,
       nvl(:l_type_encounter_label, pk_hea_prv_aux.get_clin_service(:i_lang, :i_prof, ei.id_dep_clin_serv)) cons_type,
       decode(pk_date_utils.trunc_insttimezone(:i_prof_institution, :i_prof_software, sp.dt_target_tstz, NULL),
              (SELECT pk_date_utils.trunc_insttimezone(:i_prof_institution, :i_prof_software, current_timestamp, NULL)
                 FROM dual),
              (SELECT pk_date_utils.date_char_hour_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software)
                 FROM dual),
              NULL) hour_target,
       (SELECT pk_date_utils.trunc_dt_char_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software)
          FROM dual) date_target,
       (SELECT decode(epis.id_epis_type,
                      :l_et_nurse,
                      lpad(to_char(pk_sysdomain.get_rank(:i_lang, :i_code_dom, :i_val)), 6, ''0'') ||
                      pk_sysdomain.get_img(:i_lang, :i_code_dom, :i_val),
                      lpad(to_char(pk_sysdomain.get_rank(:i_lang, :i_code_dom, sp.flg_sched)), 6, ''0'') ||
                      pk_sysdomain.get_img(:i_lang, :i_code_dom, sp.flg_sched))
          FROM dual) img_sched,
       (SELECT pk_grid_amb.get_responsibles_str(:i_lang,
																							  :i_prof,
																								:g_cat_type_doc,
																								ei.id_episode, 
																								nvl(ei.id_professional, spo.id_professional), 
																								:l_handoff_type, 
																								''G'') 
					 FROM dual) name_prof,
				(SELECT pk_prof_utils.get_nickname(:i_lang, ei.id_first_nurse_resp) 
					 FROM dual) name_nurse,
				(SELECT pk_grid_amb.get_responsibles_str(:i_lang,
																								 :i_prof, 
																								 :g_cat_type_doc, 
																								 ei.id_episode, 
																								 nvl(ei.id_professional, spo.id_professional), 
																								 :l_handoff_type, 
																								 ''T'') 
					 FROM dual) name_prof_tooltip,
				(SELECT pk_grid_amb.get_responsibles_str(:i_lang, 
																								 :i_prof, 
																								 :g_cat_type_nurse,
																								 ei.id_episode, 
																								 ei.id_first_nurse_resp, 
																								 :l_handoff_type, 
																								 ''T'') 
					 FROM dual) name_nurse_tooltip, 
       :g_sysdate_char dt_server,
       decode(drt.id_discharge_dest,
              NULL,
              decode(drt.id_dep_clin_serv,
                     NULL,
                     (SELECT pk_translation.get_translation(:i_lang, inst.code_institution)
                        FROM dual),
                     (SELECT pk_translation.get_translation(:i_lang, dep.code_department)
                        FROM dual) || '' - '' || (SELECT pk_translation.get_translation(:i_lang, cs2.code_clinical_service)
                                                    FROM dual)),
              (SELECT pk_translation.get_translation(:i_lang, ddn.code_discharge_dest)
                 FROM dual)) disch_dest,
       decode(gt.drug_presc,
              NULL,
              NULL,
              (SELECT pk_grid.convert_grid_task_dates_to_str(:i_lang, :i_prof, gt.drug_presc)
                 FROM dual)) desc_drug_presc,
       decode(gt.intervention,
              NULL,
              NULL,
              (SELECT pk_grid.convert_grid_task_dates_to_str(:i_lang, :i_prof, gt.intervention)
                 FROM dual)) desc_interv_presc,
       pk_grid.visit_grid_task_str(:i_lang, :i_prof, epis.id_visit, :g_task_analysis, :l_prof_cat) desc_analysis_req,
       pk_grid.visit_grid_task_str(:i_lang, :i_prof, epis.id_visit, :g_task_exam, :l_prof_cat) desc_exam_req,
       (SELECT pk_date_utils.to_char_insttimezone(:i_prof_institution,
                                                  :i_prof_software,
                                                  sp.dt_target_tstz,
                                                  ''YYYYMMDDHH24MISS'')
          FROM dual) dt_ord1,
           decode(:i_prof_software, 312, decode(epis.id_epis_type, 50, pk_hhc_core.get_id_hhc_req_by_epis(epis.id_episode))) id_epis_hhc_req
  FROM epis_info ei
  JOIN episode epis
    ON ei.id_episode = epis.id_episode
   JOIN patient pat
    ON epis.id_patient = pat.id_patient
  JOIN clin_record cr
    ON pat.id_patient = cr.id_patient
  LEFT JOIN clinical_service cs
    ON (epis.id_cs_requested = cs.id_clinical_service)
  LEFT JOIN clinical_service cs2
    ON epis.id_clinical_service = cs2.id_clinical_service
  JOIN (SELECT /*+opt_estimate(table t rows=1)*/
         t.column_value id_epis_type
          FROM TABLE(:l_et_access) t) eta
    ON epis.id_epis_type = eta.id_epis_type
    OR (eta.id_epis_type = 0 AND pk_utils.search_table_number(:l_et_access, epis.id_epis_type) = -1)
  LEFT JOIN schedule_outp sp
    ON sp.id_schedule = ei.id_schedule
  LEFT JOIN schedule s
    ON sp.id_schedule = s.id_schedule
  LEFT JOIN sch_group sg
    ON s.id_schedule = sg.id_schedule
  AND sg.id_patient = epis.id_patient 
 ' || l_from || '
  LEFT JOIN sch_prof_outp spo
    ON spo.id_schedule_outp = sp.id_schedule_outp
  LEFT JOIN professional p
    ON ei.id_professional = p.id_professional
  LEFT JOIN discharge d
    ON epis.id_episode = d.id_episode
   AND d.dt_cancel_tstz IS NULL
  LEFT JOIN disch_reas_dest drt
    ON d.id_disch_reas_dest = drt.id_disch_reas_dest
  LEFT JOIN discharge_dest ddn
    ON drt.id_discharge_dest = ddn.id_discharge_dest
  LEFT JOIN dep_clin_serv dcs2
    ON drt.id_dep_clin_serv = dcs2.id_dep_clin_serv
  LEFT JOIN department dep
    ON dcs2.id_department = dep.id_department
  LEFT JOIN clinical_service cs2
    ON dcs2.id_clinical_service = cs2.id_clinical_service
  LEFT JOIN institution inst
    ON drt.id_institution = inst.id_institution
  LEFT JOIN grid_task gt
    ON epis.id_episode = gt.id_episode
WHERE (ei.id_software = :i_prof_software OR :i_prof_software = :g_soft_nutritionist OR :i_prof_software = :g_soft_social OR :i_prof_software = :g_soft_psychologist OR :i_prof_software = :g_soft_resptherap)   AND (sp.dt_target_tstz <= :l_date OR
       sp.dt_target_tstz IS NULL)
   AND epis.id_institution = :i_prof_institution
   AND cr.flg_status = :g_clin_active
   AND cr.id_institution = :i_prof_institution
    AND (epis.flg_status NOT IN (:g_epis_active, :g_epis_canc))
   AND epis.id_epis_type NOT IN (:g_epis_type_rad, :g_epis_type_exm, :g_epis_type_lab, :g_epis_type_interv)
   AND epis.flg_ehr != :g_flg_ehr_e	 
   AND ((epis.id_epis_type = :g_epis_nurse and :g_flg_access = :g_yes) OR epis.id_epis_type <> :g_epis_nurse ) 	 
 ' || l_where || '
   AND rownum <= :l_limit
 ORDER BY ' || l_order_by || 'sp.dt_target_tstz';
    
        g_error := 'OPEN o_pat';
        OPEN o_pat FOR l_sql
            USING --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  l_handoff_type, --
                  i_lang, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof, --
                  l_type_encounter_label, --
                  i_lang, --
                  i_prof,
                  i_prof.institution, --
                  i_prof.software, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  l_nurse_et, --
                  i_lang, --
                  pk_grid_amb.g_schdl_nurse_state_domain, --
                  pk_grid_amb.g_sched_nurse, --
                  i_lang, --
                  pk_grid_amb.g_schdl_nurse_state_domain, --
                  pk_grid_amb.g_sched_nurse, --
                  i_lang, --
                  pk_grid_amb.g_schdl_outp_sched_domain, --
                  i_lang, --
                  pk_grid_amb.g_schdl_outp_sched_domain, --
                  i_lang, --
                  i_prof, --
                  pk_alert_constant.g_cat_type_doc, --
                  l_handoff_type, --
                  i_lang, --
                  i_lang, --
                  i_prof, --
                  pk_alert_constant.g_cat_type_doc, --
                  l_handoff_type, --
                  i_lang, --
                  i_prof, --
                  pk_alert_constant.g_cat_type_nurse, --
                  l_handoff_type, --
                  g_sysdate_char, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  g_task_analysis, --
                  l_prof_cat, --
                  i_lang, --
                  i_prof, --
                  g_task_exam, --
                  l_prof_cat, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_prof.software, --
                  l_et_access, -- BIND FROM 
                  l_et_access, --
                  i_prof.software, --
                  i_prof.software, --
                  pk_alert_constant.g_soft_nutritionist,
                  i_prof.software,
                  pk_alert_constant.g_soft_social, --
                  i_prof.software,
                  pk_alert_constant.g_soft_psychologist, --
                  i_prof.software,
                  pk_alert_constant.g_soft_resptherap, --
                  l_date, --
                  i_prof.institution, --
                  g_clin_active, --
                  i_prof.institution, --
                  g_epis_active, --
                  g_epis_canc, --
                  g_epis_type_rad, --
                  g_epis_type_exm, --
                  g_epis_type_lab, --
                  g_epis_type_interv, --
                  pk_visit.g_flg_ehr_e, --
                  l_nurse_et,
                  l_episode_access,
                  pk_alert_constant.g_yes,
                  l_nurse_et,
                  l_limit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang,
                                               i_prof,
                                               g_package_name,
                                               'GET_PAT_CRITERIA_INACTIVE_CLIN',
                                               o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang,
                                              i_prof,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_INACTIVE_CLIN',
                                              o_error);
        
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
        WHEN invalid_number THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.invalid_number_handler(i_lang,
                                                    i_prof,
                                                    g_package_name,
                                                    'GET_PAT_CRITERIA_INACTIVE_CLIN',
                                                    o_error);
        
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_INACTIVE_CLIN',
                                              'S',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_pat_criteria_inactive_clin;

    FUNCTION get_all_patients
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_prof            IN profissional,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
                OBJECTIVO:   EFECTUAR PESQUISA POR TODOS OS PACIENTES DE TODAS AS INSTITUIÇÕES (ESTÁ A SER USADO NO MANCHESTER BRASIL) 
                PARAMETROS:  ENTRADA: I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL 
                        I_ID_SYS_BTN_CRIT - LISTA DE ID'S DE CRITÉRIOS DE PESQUISA. 
                        I_CRIT_VAL - LISTA DE VALORES DOS CRITÉRIOS DE PESQUISA
                      I_PROF - PROFISSIONAL 
                       SAIDA: O_PAT - DOENTES 
                      O_MESS_NO_RESULT - MENSAGEM A MOSTRAR QUANDO A PESQUISA NÃO DEVOLVER RESULTADOS
                      O_ERROR - ERRO 
               
               CRIAÇÃO: FO 2008/05/16
             
               NOTAS: 
        *********************************************************************************/
    
        l_where      VARCHAR2(4000);
        v_where_cond VARCHAR2(32767);
        l_count      NUMBER;
        l_limit      sys_config.desc_sys_config%TYPE;
        l_aux_sql    VARCHAR2(32767);
    
        l_continue BOOLEAN := TRUE;
    
        l_id_health_plan health_plan.id_health_plan%TYPE;
        l_id_cnt_hp      health_plan.id_content%TYPE;
        l_id_doc_type    doc_type.id_doc_type%TYPE;
    
        l_grp_insts table_number;
        l_id_market market.id_market%TYPE;
    
    BEGIN
    
        o_flg_show := 'N';
        g_sysdate  := SYSDATE;
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_id_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
                g_error      := 'SET WHERE ' || i_id_sys_btn_crit(i);
                v_where_cond := NULL;
            
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        -- JS, 2007-09-07 - Timezone
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', ''''''),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    pk_types.open_my_cursor(o_pat);
                    RETURN FALSE;
                END IF;
            
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        l_id_cnt_hp := pk_sysconfig.get_config('ADT_NATIONAL_HEALTH_PLAN_ID', i_prof);
        BEGIN
            SELECT hp.id_health_plan
              INTO l_id_health_plan
              FROM health_plan hp
             WHERE hp.id_content = l_id_cnt_hp
               AND hp.flg_available = 'Y';
        EXCEPTION
            WHEN no_data_found THEN
                l_id_health_plan := NULL;
        END;
    
        l_id_doc_type := pk_sysconfig.get_config('DOC_TYPE_PID', i_prof);
    
        g_error     := 'GET INSTs GRP';
        l_grp_insts := pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt);
    
        g_error   := 'CONCAT EPIS COUNT';
        l_aux_sql := 'SELECT COUNT(DISTINCT pat.id_patient) ' || --
                     '  FROM patient pat, ' || --
                     '       (SELECT id_patient, num_health_plan ' || --
                     '          FROM pat_health_plan php ' || --
                     '         WHERE id_health_plan = :l_id_health_plan ' || --
                     '           AND id_institution in (select * from table(:l_grp_insts))) php, ' || --
                     '       (SELECT num_doc, id_patient ' || --
                     '          FROM doc_external d ' || --
                     '         WHERE id_doc_type = :l_id_doc_type ' || --
                     '           AND flg_status = ''A'') de, ' || --
                     '       (SELECT id_visit, ' || --
                     '               epis.id_patient, ' || --
                     '               epis.dt_begin_tstz, ' || --
                     '               epis.barcode, ' || --
                     '               epis.id_episode, ' || --
                     '               epis.id_epis_type, ' || --
                     '               epis.id_institution ' || --
                     '          FROM episode epis ' || --
                     '         WHERE epis.flg_status != ''T'') epis, ' || --
                     '        pat_soc_attributes psa ' || --
                     ' WHERE epis.id_patient(+) = pat.id_patient ' || --
                     ' AND psa.id_patient = pat.id_patient ' || --
                     '   AND de.id_patient(+) = pat.id_patient ' || --
                     '   AND php.id_patient(+) = pat.id_patient ' || --
                     '   AND EXISTS (SELECT 1 ' || --
                     '                 FROM TABLE(:l_grp_insts) ig ' || --
                     '                WHERE ig.column_value = psa.id_institution) ' || --
                     l_where;
    
        g_error := 'GET EPIS COUNT';
        EXECUTE IMMEDIATE l_aux_sql
            INTO l_count
            USING --
        l_id_health_plan, --
        l_grp_insts, --
        l_id_doc_type, l_grp_insts;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_continue
        THEN
            g_error := 'CONCAT CURSOR O_PAT';
            OPEN o_pat FOR --
             'SELECT id_patient, ' || --
             '       name, ' || --
             '       name_pat_sort, ' || --            
             '       pat_ndo, ' || --
             '       pat_nd_icon, ' || --
             '       pk_patphoto.get_pat_foto(id_patient, :i_prof) photo, ' || --
             '       (SELECT pk_patient.get_pat_age(:i_lang, dt_birth, age, :i_prof_institution, :i_prof_software) ' || --
             '          FROM dual) pat_age, ' || --
             '       pk_patient.get_gender(:i_lang, gender) gender, ' || --
             '       (SELECT pk_date_utils.dt_chr(:i_lang, dt_birth, :i_prof_institution, :i_prof_software) ' || --
             '          FROM dual) dt_birth_print, ' || --
             '       decode(:l_id_market, 16, (SELECT php.affiliation_number
                            FROM  pat_health_plan php                              
                           WHERE  php.institution_key = :i_prof_institution
                             AND php.flg_status = ''A''
                             and php.id_patient = pat.id_patient
                             and rownum = 1), num_health_plan) num_health_plan, ' || --
             '      decode(:l_id_market,16,(SELECT ca.location
                            FROM v_contact_address_mx ca
                           WHERE ca.id_contact_entity = pat.id_person
                            AND ca.flg_main_address = ''Y''
                           and rownum =1), location) location, ' || --
             '      decode(:l_id_market,16,(SELECT social_security_number
                            FROM person pe
                           WHERE pe.id_person = pat.id_person
                             AND rownum = 1), num_doc) num_doc_id, ' || --
             '       (SELECT first_value(id_episode) over(ORDER BY epis2.dt_begin_tstz) ' || --
             '          FROM episode epis2' || --
             '           WHERE epis2.flg_status = ''A'' ' || --
             '           AND epis2.id_institution in (select * from table(:l_grp_insts)) ' || --
             '           AND epis2.id_patient = pat.id_patient ' || --
             '           AND rownum < 2) id_episode ' || --
             '  FROM (SELECT DISTINCT pat.id_patient, ' || --
             '                        pat.id_person, ' || --
             '                        pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, epis.id_episode) name, ' || --
             '                        pk_patient.get_pat_name_to_sort(:i_lang, :i_prof, pat.id_patient, epis.id_episode) name_pat_sort, ' || --
             '                        pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) pat_ndo, ' || --
             '                        pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) pat_nd_icon, ' || --
             '                        pat.dt_birth, ' || --
             '                        pat.age, ' || --
             '                        pat.gender, ' || --
             '                        php.num_health_plan, ' || --
             '                        pk_patient.get_pat_location(:i_prof_institution, :g_inst_grp_flg_rel_adt, pat.id_patient) location, ' || --
             '                        de.num_doc ' || --
             '          FROM patient pat, ' || --
             '               (SELECT id_patient, num_health_plan ' || --
             '                  FROM pat_health_plan php ' || --
             '                 WHERE id_health_plan = :l_id_health_plan ' || --
             '                   AND id_institution in (select * from table(:l_grp_insts))) php, ' || --
             '               (SELECT num_doc, id_patient ' || --
             '                  FROM doc_external d ' || --
             '                 WHERE id_doc_type = :l_id_doc_type ' || --
             '                   AND flg_status = ''A'') de, ' || --
             '               (SELECT id_visit, ' || --
             '                       epis.id_patient, ' || --
             '                       epis.dt_begin_tstz, ' || --
             '                       epis.barcode, ' || --
             '                       epis.id_episode, ' || --
             '                       epis.id_epis_type, ' || --
             '                       epis.id_institution ' || --
             '                  FROM episode epis ' || --
             '                 WHERE epis.flg_status != ''T'') epis, ' || --
             '            pat_soc_attributes psa ' || --
             '         WHERE epis.id_patient(+) = pat.id_patient ' || --
             '           AND de.id_patient(+) = pat.id_patient ' || --
             '           AND php.id_patient(+) = pat.id_patient ' || --
             '           AND psa.id_patient = pat.id_patient ' || --
             '           AND EXISTS (SELECT 1 ' || --
             '                         FROM TABLE(:l_grp_insts) ig ' || --
             '                        WHERE ig.column_value = psa.id_institution) ' || --
            l_where || --
             '         ORDER BY name) pat ' || --
             ' WHERE rownum <= :l_limit '
                USING --
                      i_prof, --
                      i_lang, --
                      i_prof.institution, --
                      i_prof.software, --
                      i_lang, --
                      i_lang, --
                      i_prof.institution, --
                      i_prof.software, --
                      l_id_market, --
                      i_prof.institution, --
                      l_id_market, --
                      l_id_market, --
                      l_grp_insts, --
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --            
                      i_lang, --
                      i_prof, --
                      i_lang, --
                      i_prof, --
                      i_prof.institution, --
                      g_inst_grp_flg_rel_adt, --
                      l_id_health_plan, --
                      l_grp_insts, --
                      l_id_doc_type, --
                      l_grp_insts, --
                      l_limit;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_ALL_PATIENTS', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_ALL_PATIENTS', o_error);
        
        WHEN g_exception_user THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_ALL_PATIENTS',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_ALL_PATIENTS',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_ALL_PATIENTS',
                                              'S',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- open cursors for java                
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_all_patients;

    /**********************************************************************************************
    * Listar os agendamentos cancelados
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_sys_btn_crit        Lista de ID'S de critérios de pesquisa.             
    * @param i_crit_val               Lista de valores dos critérios de pesquisa
    * @param i_dt                     Data a pesquisar. Se for null assume a data de sistema
    * @param o_msg    
    * @param o_msg_title
    * @param o_button   
    * @param o_epis_inact             array with inactive episodes
    * @param o_mess_no_result         Mensagem quando a pesquisa não devolver resultados  
    * @param o_flg_show                
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Teresa Coutinho
    * @version                        1.0 
    * @since                          2008/12/23
    **********************************************************************************************/
    FUNCTION get_sched_canc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_dt              IN VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_sched_canc      OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(32767);
        v_where_cond VARCHAR2(4000);
        l_limit      sys_config.desc_sys_config%TYPE;
    
        g_epis_type_nurse sys_config.value%TYPE;
    
        aux_sql1   VARCHAR2(32767);
        l_count    NUMBER;
        l_continue BOOLEAN := TRUE;
    
    BEGIN
    
        o_flg_show := 'N';
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --LÊ CRITÉRIOS DE PESQUISA E PREENCHE CLÁUSULA WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
                IF NOT get_criteria_condition(i_lang,
                                              i_prof,
                                              i_id_sys_btn_crit(i),
                                              REPLACE(i_crit_val(i), '''', '%'),
                                              v_where_cond,
                                              o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_no_results := FALSE;
        g_overlimit  := FALSE;
    
        g_error           := 'GET LIMIT';
        l_limit           := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        g_error  := 'GET COUNT';
        aux_sql1 := 'SELECT COUNT(1) FROM (SELECT DISTINCT  sp.id_schedule,  ' || --
                    ' pk_date_utils.date_char_hour_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software) dt_target,' || --
                    '    (SELECT decode(pk_grid.get_schedule_real_state(sp.flg_state, ei.flg_ehr),
                         :g_sched_scheduled,
                         '''',
                         pk_date_utils.date_char_hour_tsz(1,
                         epis.dt_begin_tstz,
                         :i_prof_institution,
                         :i_prof_software))
                         FROM episode epis
                         WHERE epis.id_episode = ei.id_episode) dt_efectiv,' || --
                    ' lpad(to_char(sd1.rank), 6, ''0'') || sd1.img_name img_state, ' || --
                    ' pk_date_utils.trunc_dt_char_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software) date_target,' || --
                    ' pat.id_patient, ' || --
                    ' pat.name, ' || --
                    ' pat.gender, ' || --
                    ' pk_patient.get_pat_age(1, pat.id_patient, profissional(:i_prof_id,:i_prof_institution,:i_prof_software)) pat_age, ' || --
                    ' decode(pk_patphoto.check_blob(pat.id_patient), ' || '''N'', ' || ''''', ' || --
                    ' pk_patphoto.get_pat_foto(pat.id_patient, profissional(:i_prof_id,:i_prof_institution,:i_prof_software))) photo ,' || --
                    ' decode(s.flg_status, ''C'', ''C'', pk_grid.get_schedule_real_state(sp.flg_state, ei.flg_ehr)) flg_state,' || --
                    ' decode(s.schedule_cancel_notes, NULL, pk_hea_prv_aux.get_clin_service(:i_lang, :i_prof, ei.id_dep_clin_serv),
                                         pk_hea_prv_aux.get_clin_service(:i_lang, :i_prof, ei.id_dep_clin_serv) || chr(10) ||
                                         pk_message.get_message(:i_lang, ''GRID_NURSE_T010'')) cons_type,' || --
                    ' nvl(r.desc_room, PK_TRANSLATION.GET_TRANSLATION(:i_lang, R.CODE_ROOM)) DESC_ROOM,' || --
                    ' pk_translation.get_translation(:i_lang, scr.code_cancel_reason) || decode(s.schedule_cancel_notes, NULL, '' '', ''; '' || s.schedule_cancel_notes) cancel_notes,' || --
                    ' pk_prof_utils.get_name_signature(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                    i_prof.institution || ',' || i_prof.software || '), p.ID_PROFESSIONAL) prof_name, ' || --
                    ' sp.flg_sched ' || --
                    'FROM schedule_outp sp,' || --
                    '     sch_group          sg, ' || --
                    '     DEP_CLIN_SERV DCS, ' || --
                    '     schedule           s, ' || --   
                    '     professional       p, ' || --
                    '     sch_prof_outp      ps, ' || --
                    '     clinical_service   cs, ' || --
                    '     episode            epis, ' || --
                    '     v_episode_act      ei, ' || --
                    '     sys_domain         sd1,  ' || --
                    '     room r,  ' || --
                    '     sch_cancel_reason scr ,  ' || --
                    '     patient            pat,  ' || --
                    '     clin_record        cr   ' || --
                    ' where sp.id_epis_type =:g_epis_type_nurse ' || --
                    '   AND pat.id_patient = sg.id_patient ' || --
                    '   AND pat.id_patient = cr.id_patient  ' || --                 
                    '   AND s.id_schedule = sp.id_schedule ' || --
                    '   AND ei.id_schedule(+) = s.id_schedule ' || --
                    '   AND s.id_room = r.id_room(+)  ' || --
                    '   AND epis.id_episode(+) = ei.id_episode ' || --
                    '   AND ps.id_professional = p.id_professional(+) ' || --
                    '   AND ps.id_schedule_outp(+) = sp.id_schedule_outp ' || --
                    '   AND dcs.id_dep_clin_serv = s.id_dcs_requested' || --
                    '   AND cs.id_clinical_service = dcs.id_clinical_service' || --                                      
                    '   AND s.id_cancel_reason = scr.id_sch_cancel_reason(+) ' || --      
                    '   AND sd1.code_domain = ''SCHEDULE_OUTP.FLG_NURSE_ACTION''' || --
                    ' and sd1.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' ||
                    '   AND sd1.val = decode(s.flg_status, ''C'', s.flg_status, pk_grid.get_schedule_real_state(sp.flg_state, ei.flg_ehr))  ' || --
                    '   AND s.flg_status =''C''' || --
                    '   AND s.flg_status != ''V''' || -- G_SCHED_CACHE
                    '   AND sg.id_schedule = sp.id_schedule ' || --
                    '   AND rownum <= :l_limit + 1 ' || --
                    l_where || ' )';
    
        g_error := 'EXECUTE IMMEDIATE';
    
        EXECUTE IMMEDIATE aux_sql1
            INTO l_count
            USING i_lang, i_prof.institution, i_prof.software, g_sched_scheduled, i_prof.institution, i_prof.software, i_lang, i_prof.institution, i_prof.software, i_prof.id, i_prof.institution, i_prof.software, i_prof.id, i_prof.institution, i_prof.software, i_lang, --
        i_prof, i_lang, --
        i_prof, i_lang, i_lang, i_lang, g_epis_type_nurse, l_limit;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        IF l_continue
        THEN
            g_error := 'OPEN o_sched_canc';
            OPEN o_sched_canc FOR 'SELECT DISTINCT sp.id_schedule,  ' || --
             ' pk_date_utils.date_char_hour_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software) dt_target,' || --
             '    (SELECT decode(pk_grid.get_schedule_real_state(sp.flg_state, ei.flg_ehr),
                  :g_sched_scheduled,
                  '''',
                  pk_date_utils.date_char_hour_tsz(1,
                  epis.dt_begin_tstz,
                  :i_prof_institution,
                  :i_prof_software))
                  FROM episode epis
                  WHERE epis.id_episode = ei.id_episode) dt_efectiv,' || --
             ' lpad(to_char(sd1.rank), 6, ''0'') || sd1.img_name img_state, ' || --
             ' pk_date_utils.trunc_dt_char_tsz(:i_lang, sp.dt_target_tstz, :i_prof_institution, :i_prof_software) date_target,' || --
             ' pat.id_patient, ' || --
             ' pat.name, ' || --
             ' pk_patient.get_pat_name_to_sort(' || i_lang || ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')  , sg.id_patient, ei.id_episode,s.id_schedule) name_to_sort,  ' || --
             ' pat.gender, ' || --
             ' pk_patient.get_pat_age(:i_lang, pat.id_patient, profissional(:i_prof_id,:i_prof_institution,:i_prof_software)) pat_age, ' || --
             ' pk_patphoto.get_pat_photo(' || i_lang || ',profissional(:i_prof_id,:i_prof_institution,:i_prof_software), pat.id_patient, ei.id_episode,s.id_schedule) photo ,' || --
             ' decode(s.flg_status, ''C'', ''C'', pk_grid.get_schedule_real_state(sp.flg_state, ei.flg_ehr)) flg_state,' || --
             ' decode(s.schedule_cancel_notes, NULL, pk_hea_prv_aux.get_clin_service(:i_lang, profissional(:i_prof_id,:i_prof_institution,:i_prof_software), ei.id_dep_clin_serv),
                                         pk_hea_prv_aux.get_clin_service(:i_lang, profissional(:i_prof_id,:i_prof_institution,:i_prof_software), ei.id_dep_clin_serv) || chr(10) ||
                                         pk_message.get_message(:i_lang, ''GRID_NURSE_T010'')) cons_type,' || --
             ' nvl(r.desc_room, pk_translation.get_translation(:i_lang, r.code_room)) desc_room,' || --
             ' pk_translation.get_translation(:i_lang, scr.code_cancel_reason) || decode(s.schedule_cancel_notes, NULL, '' '', ''; '' || s.schedule_cancel_notes) cancel_notes,' || --
             ' pk_prof_utils.get_name_signature(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), p.id_professional) prof_name, ' || --
             ' sp.flg_sched ' || --
             'FROM schedule_outp sp,' || --
             '     sch_group          sg, ' || --
             '     dep_clin_serv      dcs, ' || --
             '     schedule           s, ' || --   
             '     professional       p, ' || --
             '     sch_prof_outp      ps, ' || --
             '     clinical_service   cs, ' || --
             '     v_episode_act      ei, ' || --            
             '     episode            epis, ' || --
             '     sys_domain         sd1,  ' || --
             '     room r,  ' || --
             '     sch_cancel_reason scr ,  ' || --
             '     patient            pat,  ' || --
             '     clin_record        cr   ' || --
             ' WHERE sp.id_epis_type =:g_epis_type_nurse ' || --
             '   AND pat.id_patient = sg.id_patient ' || --
             '   AND pat.id_patient = cr.id_patient  ' || --                 
             '   AND s.id_schedule = sp.id_schedule ' || --
             '   AND ei.id_schedule(+) = s.id_schedule ' || --
             '   AND epis.id_episode(+) = ei.id_episode ' || --
             '   AND s.id_room = r.id_room(+)  ' || --
             '   AND ps.id_professional = p.id_professional(+) ' || --
             '   AND ps.id_schedule_outp(+) = sp.id_schedule_outp ' || --
             '   AND dcs.id_dep_clin_serv = s.id_dcs_requested ' || --
             '   AND cs.id_clinical_service = dcs.id_clinical_service	 ' || --
             '   AND s.id_cancel_reason = scr.id_sch_cancel_reason(+) ' || --
             '   AND sd1.code_domain = ''SCHEDULE_OUTP.FLG_NURSE_ACTION''' || --
             ' and sd1.domain_owner = ' || '''' || pk_sysdomain.k_default_schema || '''' || '   AND sd1.val = decode(s.flg_status, ''C'', s.flg_status, pk_grid.get_schedule_real_state(sp.flg_state, ei.flg_ehr))  ' || --
             '   AND s.flg_status =''C''' || --
             '   AND s.flg_status != ''V''' || -- G_SCHED_CACHE
             '   AND sg.id_schedule = sp.id_schedule ' || --
             '   AND rownum <= :l_limit + 1 ' || --
            l_where
                USING i_lang,
                      i_prof.institution,
                      i_prof.software,
                      g_sched_scheduled,
                      i_prof.institution,
                      i_prof.software,
                      i_lang,
                      i_prof.institution,
                      i_prof.software,
                      i_lang,
                      i_prof.id,
                      i_prof.institution,
                      i_prof.software,
                      i_prof.id,
                      i_prof.institution,
                      i_prof.software,
                      i_lang,
                      i_prof.id,
                      i_prof.institution,
                      i_prof.software,
                      i_lang,
                      i_prof.id,
                      i_prof.institution,
                      i_prof.software,
                      i_lang,
                      i_lang,
                      i_lang,
                      g_epis_type_nurse,
                      l_limit;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_sched_canc);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_SCHED_CANC', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_sched_canc);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_SCHED_CANC', o_error);
        
        WHEN g_exception_user THEN
            pk_types.open_my_cursor(o_sched_canc);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_SCHED_CANC',
                                              'S',
                                              o_error);
        WHEN g_exception THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_types.open_my_cursor(o_sched_canc);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_SCHED_CANC',
                                              'S',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_types.open_my_cursor(o_sched_canc);
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_SCHED_CANC',
                                              'S',
                                              o_error);
            RETURN FALSE;
    END get_sched_canc;

    /**********************************************************************************************
    * Case management episodes search.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_crit_id                criteria identifier list
    * @param i_crit_val               criteria value list
    * @param i_type                   'A' for active episode search, 'I' for inactive episode search
    * @param o_epis                   results cursor
    * @param o_error                  error
    *
    * @return                         false, if errors occur, true otherwise
    *                        
    * @author                         Pedro Carneiro
    * @version                         2.5.0.7
    * @since                          2009/09/07
    **********************************************************************************************/
    FUNCTION get_cm_epis_criteria
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_crit_id  IN table_number,
        i_crit_val IN table_varchar,
        i_type     IN VARCHAR2,
        o_epis     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where       VARCHAR2(4000) := NULL;
        l_count_sql   VARCHAR2(32767);
        l_count       PLS_INTEGER;
        l_limit       sys_config.value%TYPE;
        l_epis_type   episode.id_epis_type%TYPE;
        l_epis_status episode.flg_status%TYPE := NULL;
    
    BEGIN
    
        l_limit     := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_epis_type := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
    
        g_error := 'CALL get_where';
        IF NOT get_where(i_criteria => i_crit_id,
                         i_crit_val => i_crit_val,
                         o_where    => l_where,
                         i_lang     => i_lang,
                         i_prof     => i_prof)
        THEN
            l_where := NULL;
        END IF;
    
        IF i_type = pk_alert_constant.g_active
        THEN
            l_epis_status := g_epis_active;
        ELSIF i_type = pk_alert_constant.g_inactive
        THEN
            l_epis_status := g_epis_inactive;
        END IF;
    
        pk_context_api.set_parameter('ID_EXTERNAL_SYS',
                                     pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software));
    
        pk_context_api.set_parameter('EXTERNAL_SYSTEM_EXIST',
                                     pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST',
                                                             i_prof.institution,
                                                             i_prof.software));
    
        g_error     := 'set results count sql';
        l_count_sql := 'SELECT COUNT(1) ' || --
                       '  FROM (SELECT pat.id_patient, ' || --
                       '               e.id_episode, ' || --
                       '               cr.num_clin_record, ' || --
                       '              pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, e.id_episode, null) name_pat, ' ||
                       '              pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) pat_ndo, ' ||
                       '              pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) pat_nd_icon, ' ||
                       '               pk_patient.get_gender(:i_lang, pat.gender) gender, ' || --
                       '               (SELECT pk_patient.get_pat_age(:i_lang, pat.dt_birth, pat.dt_deceased, pat.age, :i_prof_institution, :i_prof_software) ' || --
                       '                  FROM dual) pat_age, ' || --
                       '               pat.dt_birth, ' || --
                       '               pk_patphoto.get_pat_photo(:i_lang, :i_prof, pat.id_patient, e.id_episode, null) photo, ' || --                      
                       '               p.name name_prof, ' || --
                       '               (SELECT pk_prof_utils.get_name_signature(1, :i_prof, ei.id_professional) ' || --
                       '                  FROM dual) case_manager, ' || --
                       '               pk_date_utils.dt_chr_tsz(:i_lang, e.dt_begin_tstz, :i_prof) start_date, ' || --
                       '               pk_date_utils.dt_chr_hour_tsz(:i_lang, e.dt_begin_tstz, :i_prof) start_hour, ' || --
                       '               e.id_institution, ' || --
                       '               ei.id_software, ' || --
                       '               e.barcode, ' || --
                       '               e.dt_begin_tstz, ' || --
                       '               pk_opinion.get_cm_req_reason(:i_lang, :i_prof, o.id_opinion) reason_desc, ' || --
                       '               pk_opinion.get_cm_req_origin(:i_lang, :i_prof, o.id_episode) origin_desc, ' || --
                       '               ei.id_professional ' || --
                       '          FROM episode e ' || --
                       '          JOIN patient pat ON (pat.id_patient = e.id_patient) ' || --
                       '          JOIN epis_info ei ON (ei.id_episode = e.id_episode) ' || --
                       '          JOIN clin_record cr ON (cr.id_patient = e.id_patient) ' || --
                       '          JOIN opinion o ON (o.id_episode_answer = e.id_episode) ' || --
                       '          JOIN professional p ON (p.id_professional = o.id_prof_questions) ' || --
                       '         WHERE e.id_epis_type = :l_epis_type ' || --
                       '           AND e.flg_status = :g_epis_status ' || --
                       '           AND e.id_institution = :i_prof_institution ' || --
                       '           AND cr.flg_status = :g_clin_active ' || --
                       '           AND cr.id_institution = :i_prof_institution) t ' || --
                       ' WHERE rownum <= :l_limit ' || --
                       l_where;
    
        g_error := 'EXECUTE results count';
        EXECUTE IMMEDIATE l_count_sql
            INTO l_count
            USING --
        i_lang, i_prof, i_lang, i_prof, i_lang, i_prof, i_lang, --
        i_lang, --
        i_prof.institution, --
        i_prof.software, --
        i_lang, --
        i_prof, --
        i_prof, --
        i_lang, --
        i_prof, --
        i_lang, --
        i_prof, --
        i_lang, --
        i_prof, --
        i_lang, --
        i_prof, --
        l_epis_type, --
        l_epis_status, --
        i_prof.institution, --
        g_clin_active, --
        i_prof.institution, --
        l_limit;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        ELSIF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'OPEN o_epis';
        OPEN o_epis FOR --
         'SELECT * ' || --
         '  FROM (SELECT pat.id_patient, ' || --
         '               e.id_episode, ' || --
         '               cr.num_clin_record, ' || --
         '               pk_patient.get_pat_name(:i_lang, :i_prof, pat.id_patient, e.id_episode, null) name_pat, ' || --
         '               pk_patient.get_pat_name_to_sort(' || i_lang || ',profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')  , pat.id_patient, e.id_episode,ei.id_schedule) name_to_sort,  ' || --         
         '               pk_adt.get_pat_non_disc_options(:i_lang, :i_prof, pat.id_patient) pat_ndo, ' || --
         '               pk_adt.get_pat_non_disclosure_icon(:i_lang, :i_prof, pat.id_patient) pat_nd_icon, ' || --
         '               pk_patient.get_gender(:i_lang, pat.gender) gender, ' || --
         '               (SELECT pk_patient.get_pat_age(:i_lang, pat.dt_birth, pat.dt_deceased, pat.age, :i_prof_institution, :i_prof_software) ' || --
         '                  FROM dual) pat_age, ' || --
         '               pat.dt_birth, ' || --
         '               pk_patphoto.get_pat_photo(:i_lang, :i_prof, pat.id_patient, e.id_episode, null) photo, ' || --        
         '               p.name name_prof, ' || --
         '               (SELECT pk_prof_utils.get_name_signature(1, :i_prof, ei.id_professional) ' || --
         '                  FROM dual) case_manager, ' || --
         '               pk_date_utils.dt_chr_tsz(:i_lang, e.dt_begin_tstz, :i_prof) start_date, ' || --
         '               pk_date_utils.dt_chr_hour_tsz(:i_lang, e.dt_begin_tstz, :i_prof) start_hour, ' || --
         '               e.id_institution, ' || --
         '               ei.id_software, ' || --
         '               e.barcode, ' || --
         '               e.dt_begin_tstz, ' || --
         '               pk_opinion.get_cm_req_reason(:i_lang, :i_prof, o.id_opinion) reason_desc, ' || --
         '               pk_opinion.get_cm_req_origin(:i_lang, :i_prof, o.id_episode) origin_desc, ' || --
         '               ei.id_professional ' || --
         '          FROM episode e ' || --
         '          JOIN patient pat ON (pat.id_patient = e.id_patient) ' || --
         '          JOIN epis_info ei ON (ei.id_episode = e.id_episode) ' || --
         '          JOIN clin_record cr ON (cr.id_patient = e.id_patient) ' || --
         '          JOIN opinion o ON (o.id_episode_answer = e.id_episode) ' || --
         '          JOIN professional p ON (p.id_professional = o.id_prof_questions) ' || --
         '         WHERE e.id_epis_type = :l_epis_type ' || --
         '           AND e.flg_status = :g_epis_status ' || --
         '           AND e.id_institution = :i_prof_institution ' || --
         '           AND cr.flg_status = :g_clin_active ' || --
         '           AND cr.id_institution = :i_prof_institution) t ' || --
         ' WHERE rownum <= :l_limit ' || --
        l_where || --
         ' ORDER BY t.dt_begin_tstz'
            USING --
                  i_lang,
                  i_prof,
                  i_lang,
                  i_prof,
                  i_lang,
                  i_prof,
                  i_lang, --
                  i_lang, --
                  i_prof.institution, --
                  i_prof.software, --
                  i_lang, --
                  i_prof, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  i_lang, --
                  i_prof, --
                  l_epis_type, --
                  l_epis_status, --
                  i_prof.institution, --
                  g_clin_active, --
                  i_prof.institution, --
                  l_limit;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_epis);
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_CM_EPIS_CRITERIA', o_error);
        
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_epis);
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_CM_EPIS_CRITERIA', o_error);
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_package_name,
                                              i_function => 'GET_CM_EPIS_CRITERIA',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_epis);
            RETURN FALSE;
    END get_cm_epis_criteria;

    /***********************************************************************************************************
    * Esta função retorna uma string com as condições de pesquisa especificadas pelo utilizador.
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               ID do profissional
    * @param      i_id_sys_btn_crit
    * @param      i_crit_val
    *
    * @param      o_error              mensagem de erro
    *
    * @return     uma string com os critérios a adicionar à cláusula where ou NUll caso não tenham sido
    *              especificadas quaisquer critérios de selecção
    * @author     Orlando Antunes
    * @alter      Pedro Teixeira : Passagem da querie de PK_VACC para PK_SEARCH
    * @version    2.3.6.
    * @since
    ***********************************************************************************************************/
    FUNCTION get_read_search_criteria
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN VARCHAR2 IS
    
        l_error      VARCHAR2(2000) := '';
        l_where      VARCHAR2(4000);
        v_where_cond VARCHAR2(4000);
    
    BEGIN
    
        --Leitura das condições de pesquisa
        l_where := NULL;
    
        pk_context_api.set_parameter('i_lang', i_lang);
    
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
            l_error      := 'SET WHERE';
            v_where_cond := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
                IF NOT get_criteria_condition(i_lang,
                                              i_prof,
                                              i_id_sys_btn_crit(i),
                                              REPLACE(i_crit_val(i), '''', '%'),
                                              v_where_cond,
                                              o_error)
                
                THEN
                    RETURN NULL;
                END IF;
            
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        --Esta string contem as condições a adicionar à cláusula where!
        RETURN l_where;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner_name,
                                              i_package  => g_package_name,
                                              i_function => 'GET_READ_SEARCH_CRITERIA',
                                              o_error    => o_error);
            RETURN l_where;
    END get_read_search_criteria;

    /***********************************************************************************************************
    *  returns professional photo or name depending on the imput parameters
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               ID do profissional
    * @param      i_prof_id            Professional ID from which we want to return the information
    * @param      i_patient            Patient ID when we want the information from last appointment
    * @param      i_ret_type           Return type: photo or name
    *
    * @return     the professional photo or name depending on the imput parameters
    * @author     Pedro Teixeira
    * @version    2.5.0.7.5
    * @since
    ***********************************************************************************************************/
    FUNCTION get_software_prof_photo
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_id  IN professional.id_professional%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_ret_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_error t_error_out;
    
        l_ret_photo      VARCHAR2(4000);
        l_ret_name       VARCHAR2(4000);
        l_ret_type_photo VARCHAR2(1) := 'P';
        l_ret_type_name  VARCHAR2(1) := 'N';
    
        CURSOR c_photo_from_prof_id IS
            SELECT pk_profphoto.get_prof_photo(profissional(i_prof_id, 0, 0)),
                   pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof_id)
              FROM dual;
    
        CURSOR c_photo_from_i_patient IS
            SELECT pk_profphoto.get_prof_photo(profissional(ei.id_professional, 0, 0)),
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ei.id_professional)
              FROM episode e, epis_info ei
             WHERE e.id_patient = i_patient
               AND e.flg_status IN (pk_alert_constant.g_epis_status_active,
                                    pk_alert_constant.g_epis_status_inactive,
                                    pk_alert_constant.g_epis_status_pendent)
               AND e.dt_begin_tstz IS NOT NULL
               AND ei.id_episode = e.id_episode
             ORDER BY e.dt_begin_tstz DESC;
    
    BEGIN
    
        IF i_prof_id IS NOT NULL
        THEN
            g_error := 'OPEN CURSOR C_PHOTO_FROM_PROF_ID';
            OPEN c_photo_from_prof_id;
            FETCH c_photo_from_prof_id
                INTO l_ret_photo, l_ret_name;
            CLOSE c_photo_from_prof_id;
        ELSIF i_patient IS NOT NULL
        THEN
            g_error := 'OPEN CURSOR c_photo_from_i_patient';
            OPEN c_photo_from_i_patient;
            FETCH c_photo_from_i_patient
                INTO l_ret_photo, l_ret_name;
            CLOSE c_photo_from_i_patient;
        END IF;
    
        IF i_ret_type = l_ret_type_photo
        THEN
            RETURN l_ret_photo;
        ELSIF i_ret_type = l_ret_type_name
        THEN
            RETURN l_ret_name;
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_SOFTWARE_PROF_PHOTO',
                                              l_error);
            RETURN NULL;
    END get_software_prof_photo;

    /**
    * Get patient's last episode type.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    *
    * @return               patient's last episode type
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7.6
    * @since                2010/01/13
    */
    FUNCTION get_last_epis_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN pk_translation.t_desc_translation IS
    
        l_last_et      pk_translation.t_desc_translation := NULL;
        l_id_epis_type episode.id_epis_type%TYPE;
    
        CURSOR c_last_et IS
            SELECT e.id_epis_type
              FROM episode e
             WHERE e.id_patient = i_patient
               AND e.flg_status IN (pk_alert_constant.g_epis_status_active,
                                    pk_alert_constant.g_epis_status_inactive,
                                    pk_alert_constant.g_epis_status_pendent)
               AND e.dt_begin_tstz IS NOT NULL
               AND e.flg_ehr IN (pk_alert_constant.g_epis_ehr_normal, pk_alert_constant.g_epis_ehr_schedule)
             ORDER BY e.dt_begin_tstz DESC;
    BEGIN
    
        OPEN c_last_et;
        FETCH c_last_et
            INTO l_id_epis_type;
        g_found := c_last_et%FOUND;
        CLOSE c_last_et;
    
        IF g_found
        THEN
            l_last_et := pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.' || l_id_epis_type);
        END IF;
    
        RETURN l_last_et;
    END get_last_epis_type;

    --See spec for full info
    FUNCTION get_all_patients_from_software
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_types table_number := table_number();
    
    BEGIN
    
        --log input parameters
        g_error := 'GET_ALL_PATIENTS_FROM_SOFTWARE P:' || i_prof.id || ' I:' || i_prof.institution || ' S:' ||
                   i_prof.software;
        pk_alertlog.log_info(text => g_error);
    
        --Get all epis_types associated with a given software
        SELECT id_epis_type
          BULK COLLECT
          INTO l_epis_types
          FROM epis_type_soft_inst etsi
         WHERE etsi.id_institution IN (i_prof.institution, 0)
           AND etsi.id_software = i_prof.software;
    
        --Get a distinct list of id_patients that have 
        --episode(s) of a given type within a software
        OPEN o_pat FOR
            SELECT DISTINCT id_patient
              FROM episode e
             WHERE e.id_institution = i_prof.institution
               AND e.id_epis_type IN (SELECT column_value
                                        FROM TABLE(l_epis_types));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
        
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_ALL_PATIENTS_FROM_SOFTWARE',
                                              'S',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            -- reset error state                
            pk_alert_exceptions.reset_error_state;
            -- return failure of function
            RETURN FALSE;
    END get_all_patients_from_software;

    /**********************************************************************************************
    * Returns canceled patients through a given criteria
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional id, institution and software    
    * @param   i_id_sys_btn_crit list of search criteria ids
    * @param   i_crit_val list of values for the criteria in  i_id_sys_btn_crit
    *
    * @author                    CRISTINA.OLIVEIRA
    * @version                   2.8.1.0
    * @since                     2019/12/11
    **********************************************************************************************/
    FUNCTION get_pat_criteria_cancelled
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_pat             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(32000);
        l_where_cond VARCHAR2(32000);
    
    BEGIN
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lista criterios de pesquisa e preenche clausula WHERE
            l_where_cond := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
            
                g_error  := 'Call get_criteria_condition';
                g_retval := get_criteria_condition(i_lang,
                                                   i_prof,
                                                   i_id_sys_btn_crit(i),
                                                   REPLACE(i_crit_val(i), '''', '%'),
                                                   l_where_cond,
                                                   o_error);
            
                IF NOT g_retval
                THEN
                    RETURN FALSE;
                END IF;
            
                l_where := l_where || l_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat FOR 'SELECT ' || chr(32) || 'wnd.ID_EPISODE ' || chr(32) || --
         'FROM (SELECT EPIS.ID_EPISODE ' || --
        chr(32) || --
         ' FROM EPISODE EPIS, ' || --
         ' EPIS_INFO F, ' || --     
         ' PATIENT PAT,' || --
         ' CLIN_RECORD CR, ' || --
         ' PROFESSIONAL P ' || --
         ' WHERE ' || --
         ' EPIS.FLG_EHR != ''E'' ' || --
         ' AND F.ID_EPISODE = EPIS.ID_EPISODE' || --
         ' AND EPIS.ID_INSTITUTION =' || i_prof.institution || --
         ' AND EPIS.ID_PATIENT= PAT.ID_PATIENT ' || --         
         ' AND EPIS.FLG_STATUS IN (' || g_pl || pk_alert_constant.g_flg_status_c || g_pl || ')' || --
         ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT' || --
         ' AND F.ID_PROFESSIONAL = P.ID_PROFESSIONAL(+)' || --
         ' AND CR.ID_INSTITUTION(+) =' || i_prof.institution || --
         ' ' || --
        l_where || --
         ' ) wnd';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_CANCELLED',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_criteria_cancelled;

    /**********************************************************************************************
    * Returns canceled patients through a given criteria
    *
    * @param   i_lang            Language associated to the professional executing the request
    * @param   i_prof            Professional id, institution and software    
    * @param   i_id_sys_btn_crit list of search criteria ids
    * @param   i_crit_val list of values for the criteria in  i_id_sys_btn_crit
    *
    * @author                    CRISTINA.OLIVEIRA
    * @version                   2.8.1.0
    * @since                     2019/12/11
    **********************************************************************************************/
    PROCEDURE init_params_search_grids_canc
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
        k_episode          CONSTANT NUMBER(24) := 5;
    
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
        l_lang CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_hand_off_type sys_config.value%TYPE;
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(k_episode);
        l_lst_id_sys_btn_crit table_number := table_number();
        o_pat                 pk_types.cursor_type;
        l_lst_pat             table_number := table_number();
    
        l_error t_error_out;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_id_prof', l_prof.id);
        pk_context_api.set_parameter('i_id_institution', l_prof.institution);
        pk_context_api.set_parameter('i_id_software', l_prof.software);
    
        CASE i_name
            WHEN 'i_episode' THEN
                o_id := l_episode;
            
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            
            WHEN 'g_cat_type_nurse' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            
            WHEN 'g_cf_pat_gender_abbr' THEN
                o_vc2 := g_cf_pat_gender_abbr;
            
            WHEN 'g_show_in_grid' THEN
                o_vc2 := g_show_in_grid;
            
            WHEN 'g_show_in_tooltip' THEN
                o_vc2 := g_show_in_tooltip;
            
            WHEN 'i_lang' THEN
                o_id := l_lang;
            
            WHEN 'i_prof_cat' THEN
                o_vc2 := pk_prof_utils.get_category(i_lang => l_lang, i_prof => l_prof);
            
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
                o_vc2 := l_hand_off_type;
            
            WHEN 'current_timestamp' THEN
                o_tstz := current_timestamp;
            
            WHEN 'g_epis_flg_status_cancel' THEN
                o_vc2 := pk_alert_constant.g_epis_status_cancel;
            
            WHEN 'g_flg_ehr_normal' THEN
                o_vc2 := pk_alert_constant.g_epis_ehr_normal;
            
            WHEN 'g_flg_ehr_scheduled' THEN
                o_vc2 := pk_alert_constant.g_epis_ehr_schedule;
            
            WHEN 'g_no' THEN
                o_vc2 := pk_alert_constant.g_no;
            
            WHEN 'g_yes' THEN
                o_vc2 := pk_alert_constant.g_yes;
            
            WHEN 'g_one' THEN
                o_id := g_one;
            
            WHEN 'g_selected' THEN
                o_vc2 := g_selected;
            
            WHEN 'g_zero' THEN
                o_id := g_zero;
            
            WHEN 'add_days_to_current' THEN
                o_tstz := pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(l_prof,
                                                                                          current_timestamp,
                                                                                          'DD'),
                                                         1);
            WHEN 'canc_where' THEN
                l_lst_id_sys_btn_crit := pk_utils.convert_tchar_tnumber(i_context_keys);
            
                IF i_context_vals.exists(1)
                THEN
                    g_retval := get_pat_criteria_cancelled(i_lang            => l_lang,
                                                           i_prof            => l_prof,
                                                           i_id_sys_btn_crit => l_lst_id_sys_btn_crit,
                                                           i_crit_val        => i_context_vals,
                                                           o_pat             => o_pat,
                                                           o_error           => l_error);
                    FETCH o_pat BULK COLLECT
                        INTO l_lst_pat;
                    CLOSE o_pat;
                END IF;
            
                -- delete all records from tbl_temp
                DELETE FROM tbl_temp t
                 WHERE t.vc_1 IN ('CANC_WHERE');
            
                INSERT INTO tbl_temp
                    (vc_1, num_1)
                    SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                     'CANC_WHERE', t.column_value
                      FROM TABLE(l_lst_pat) t;
            
                o_id := 1;
        END CASE;
    
    END init_params_search_grids_canc;

    FUNCTION get_inactive_search_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_INACTIVE_SEARCH_VALUES';
        k_action_submit  CONSTANT NUMBER := pk_dyn_form_constant.get_submit_action();
    
    BEGIN
    
        IF (i_action IS NULL OR i_action <> k_action_submit)
        THEN
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                      id_ds_component    => t.id_ds_component_child,
                                      internal_name      => t.internal_name_child,
                                      VALUE              => t.value,
                                      value_clob         => NULL,
                                      min_value          => NULL,
                                      max_value          => NULL,
                                      desc_value         => t.desc_value,
                                      desc_clob          => NULL,
                                      id_unit_measure    => NULL,
                                      desc_unit_measure  => NULL,
                                      flg_validation     => 'Y',
                                      err_msg            => NULL,
                                      flg_event_type     => t.flg_event_type,
                                      flg_multi_status   => NULL,
                                      idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           CASE dc.internal_name_child
                               WHEN 'DS_INSTITUTION' THEN
                                to_char(i_prof.institution)
                               WHEN 'DS_TYPE_OF_ENCOUNTER' THEN
                                g_appointment_type
                           END VALUE,
                           CASE dc.internal_name_child
                               WHEN 'DS_INSTITUTION' THEN
                                (SELECT pk_utils.get_institution_name(i_lang, i_prof.institution)
                                   FROM dual)
                               WHEN 'DS_TYPE_OF_ENCOUNTER' THEN
                                (SELECT pk_sysdomain.get_domain('TYPE_OF_ENCOUNTER', g_appointment_type, i_lang)
                                   FROM dual)
                           END desc_value,
                           dc.flg_event_type
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
             WHERE t.desc_value IS NOT NULL;
        
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_inactive_search_values;

    FUNCTION get_active_search_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_ACTIVE_SEARCH_VALUES';
        k_action_submit  CONSTANT NUMBER := pk_dyn_form_constant.get_submit_action();
    
    BEGIN
    
        IF (i_action IS NULL OR i_action <> k_action_submit)
        THEN
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                      id_ds_component    => t.id_ds_component_child,
                                      internal_name      => t.internal_name_child,
                                      VALUE              => t.value,
                                      value_clob         => NULL,
                                      min_value          => NULL,
                                      max_value          => NULL,
                                      desc_value         => t.desc_value,
                                      desc_clob          => NULL,
                                      id_unit_measure    => NULL,
                                      desc_unit_measure  => NULL,
                                      flg_validation     => 'Y',
                                      err_msg            => NULL,
                                      flg_event_type     => t.flg_event_type,
                                      flg_multi_status   => NULL,
                                      idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           CASE dc.internal_name_child
                               WHEN 'DS_TYPE_OF_ENCOUNTER' THEN
                                g_appointment_type
                           END VALUE,
                           CASE dc.internal_name_child
                               WHEN 'DS_TYPE_OF_ENCOUNTER' THEN
                                (SELECT pk_sysdomain.get_domain('TYPE_OF_ENCOUNTER', g_appointment_type, i_lang)
                                   FROM dual)
                           END desc_value,
                           dc.flg_event_type
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
             WHERE t.desc_value IS NOT NULL;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner_name,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_active_search_values;

    FUNCTION get_submit_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value IS
    
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_SUBMIT_VALUES';
        k_action_submit  CONSTANT NUMBER := pk_dyn_form_constant.get_submit_action();
        l_validate_pat_name_pattern sys_config.value%TYPE;
        l_pat_name_pattern          sys_config.value%TYPE;
        l_pat_name                  patient.name%TYPE;
        l_validation_res            pk_translation.t_desc_translation;
        l_index_curr_component      PLS_INTEGER;
        l_dt_birth                  pk_translation.t_desc_translation;
        l_dt_birth_hijiri           pk_translation.t_desc_translation;
        l_index_dt_birth_converted  PLS_INTEGER;
    
    BEGIN
    
        IF i_action = k_action_submit
           AND i_curr_component IS NOT NULL
        THEN
            l_index_curr_component := pk_utils.search_table_number(i_table  => i_tbl_mkt_rel,
                                                                   i_search => i_curr_component);
        
            IF l_index_curr_component != -1
            THEN
                IF i_tbl_int_name(l_index_curr_component) = 'DS_PATIENT_NAME'
                THEN
                    l_validate_pat_name_pattern := pk_sysconfig.get_config('ADT_VALIDATE_PAT_NAME_SEARCH', i_prof);
                
                    IF l_validate_pat_name_pattern = pk_alert_constant.g_yes
                    THEN
                        l_pat_name_pattern := pk_sysconfig.get_config('VALIDATE_PAT_NAME_SEARCH_PATTERN', i_prof);
                    
                        l_pat_name       := i_value(l_index_curr_component) (1);
                        l_validation_res := regexp_substr(l_pat_name, l_pat_name_pattern);
                    
                        --if the patient name do not match the regular expression configured
                        IF l_validation_res IS NULL
                        THEN
                            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                                      id_ds_component    => t.id_ds_component_child,
                                                      internal_name      => t.internal_name_child,
                                                      VALUE              => t.value,
                                                      value_clob         => NULL,
                                                      min_value          => NULL,
                                                      max_value          => NULL,
                                                      desc_value         => t.desc_value,
                                                      desc_clob          => NULL,
                                                      id_unit_measure    => NULL,
                                                      desc_unit_measure  => NULL,
                                                      flg_validation     => 'E',
                                                      err_msg            => pk_message.get_message(i_lang      => i_lang,
                                                                                                   i_prof      => i_prof,
                                                                                                   i_code_mess => 'ADT-00122'),
                                                      flg_event_type     => t.flg_event_type,
                                                      flg_multi_status   => NULL,
                                                      idx                => 1)
                              BULK COLLECT
                              INTO tbl_result
                              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                                           dc.id_ds_component_child,
                                           dc.internal_name_child,
                                           CASE dc.internal_name_child
                                               WHEN 'DS_PATIENT_NAME' THEN
                                                l_pat_name
                                           END VALUE,
                                           CASE dc.internal_name_child
                                               WHEN 'DS_PATIENT_NAME' THEN
                                                l_pat_name
                                           END desc_value,
                                           dc.flg_event_type
                                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                                         i_prof           => i_prof,
                                                                         i_patient        => NULL,
                                                                         i_component_name => i_root_name,
                                                                         i_action         => NULL)) dc) t
                             WHERE t.desc_value IS NOT NULL;
                        END IF;
                    ELSE
                        NULL;
                    END IF;
                
                ELSIF i_tbl_int_name(l_index_curr_component) IN ('UX_PATIENT_DTBIRTH', 'UX_PATIENT_DTBIRTH_ARABIC')
                THEN
                    IF i_tbl_int_name(l_index_curr_component) = ('UX_PATIENT_DTBIRTH')
                    THEN
                        l_dt_birth                 := i_value(l_index_curr_component) (1);
                        l_index_dt_birth_converted := pk_utils.search_table_varchar(i_table  => i_tbl_int_name,
                                                                                    i_search => 'UX_PATIENT_DTBIRTH_ARABIC');
                        l_dt_birth_hijiri          := i_value(l_index_dt_birth_converted) (1);
                    
                    ELSE
                        l_dt_birth_hijiri          := i_value(l_index_curr_component) (1);
                        l_index_dt_birth_converted := pk_utils.search_table_varchar(i_table  => i_tbl_int_name,
                                                                                    i_search => 'UX_PATIENT_DTBIRTH');
                        l_dt_birth                 := i_value(l_index_dt_birth_converted) (1);
                    END IF;
                
                    IF l_dt_birth IS NULL
                    THEN
                        l_dt_birth_hijiri := NULL;
                    END IF;
                
                    IF l_dt_birth_hijiri IS NULL
                    THEN
                        l_dt_birth := NULL;
                    END IF;
                
                    SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                              id_ds_component    => t.id_ds_component_child,
                                              internal_name      => t.internal_name_child,
                                              VALUE              => t.value,
                                              value_clob         => NULL,
                                              min_value          => NULL,
                                              max_value          => NULL,
                                              desc_value         => t.desc_value,
                                              desc_clob          => NULL,
                                              id_unit_measure    => NULL,
                                              desc_unit_measure  => NULL,
                                              flg_validation     => 'Y',
                                              err_msg            => NULL,
                                              flg_event_type     => t.flg_event_type,
                                              flg_multi_status   => NULL,
                                              idx                => 1)
                      BULK COLLECT
                      INTO tbl_result
                      FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                                   dc.id_ds_component_child,
                                   dc.internal_name_child,
                                   CASE dc.internal_name_child
                                       WHEN 'DS_BIRTH_DATE' THEN
                                        l_dt_birth
                                       WHEN 'DS_BIRTH_DATE_ARABIC' THEN
                                        l_dt_birth_hijiri
                                   END VALUE,
                                   CASE dc.internal_name_child
                                       WHEN 'DS_BIRTH_DATE' THEN
                                        l_dt_birth
                                       WHEN 'DS_BIRTH_DATE_ARABIC' THEN
                                        l_dt_birth_hijiri
                                   END desc_value,
                                   dc.flg_event_type
                              FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_patient        => NULL,
                                                                 i_component_name => i_root_name,
                                                                 i_action         => NULL)) dc) t
                     WHERE t.internal_name_child IN ('DS_BIRTH_DATE', 'DS_BIRTH_DATE_ARABIC');
                
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
                                              g_owner_name,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_submit_values;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(owner => g_owner_name, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);

    g_epis_active     := 'A';
    g_epis_inactive   := 'I';
    g_visit_active    := 'A';
    g_clin_rec_active := 'A';
    g_diag_available  := 'Y';
    g_diag_no_select  := 'N';
    g_diag_other      := 'Y';

    g_flg_doctor := 'D';
    g_flg_nurse  := 'N';
    g_flg_adm    := 'A';
    g_flg_aux    := 'O';

    g_diag_type_icd  := 'D';
    g_diag_type_icpc := 'P';
    g_instit_type_cs := 'C';
    g_instit_type_hs := 'H';

    g_sched_efectiv   := 'E';
    g_sched_scheduled := 'A';

    g_sched_cancel := 'C';

    g_exam_sched  := 'S';
    g_exam_result := 'R';

    g_exam_func  := 'F';
    g_exam_audio := 'A';
    g_exam_ortho := 'O';
    g_exam_image := 'I';
    g_exam_gastr := 'G';

    g_interv_fin := 'F';

    g_flg_time_n := 'N';
    g_flg_time_b := 'B';
    g_flg_time_e := 'E';

    g_flg_canc    := 'C';
    g_flg_intr    := 'I';
    g_flg_fin     := 'F';
    g_flg_read    := 'L';
    g_flg_pending := 'D';

    g_epis_canc := 'C';

    g_doc_active := 'A';

    g_disch_type_doctor := 'D';
    g_disch_type_adm    := 'M';
    g_disch_type_alert  := 'A';

    g_discharge_status_active   := 'A';
    g_domain_sch_outp_flg_sched := 'SCHEDULE_OUTP.FLG_SCHED';

    g_selected := 'S';
    g_yes      := 'Y';
    g_no       := 'N';

END pk_search;
/
