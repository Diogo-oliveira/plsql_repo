/*-- Last Change Revision: $Rev: 2027272 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_nurse IS

    -- ***********************************************************************************************
    FUNCTION get_pat_age
    (
        i_lang   IN language.id_language%TYPE,
        i_id_pat IN patient.id_patient%TYPE,
        i_prof   IN profissional
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retornar idade do doente 
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                       I_ID_PAT - ID do doente 
                  Saida:   
          
          CRIAÇÃO: CRS 2005/03/23 
          NOTAS: Como se trata de um cálculo frequente/ necessário noutras funções cujo 
               único retorno é um array, é conveniente q haja uma função q possa ser 
             utilizada dentro de um SELECT
                     2006-11-08 LG, inclui o campo age, idade estimada, no cálculo da idade 
        *********************************************************************************/
        l_months NUMBER;
        l_days   NUMBER;
        l_age    VARCHAR2(50);
    
        CURSOR c_pat IS
            SELECT tab_age.months, tab_age.days, tab_age.age
              FROM patient p,
                   (SELECT pat1.age,
                           months_between(SYSDATE, pat1.dt_birth) months,
                           (SYSDATE - pat1.dt_birth) days,
                           pat1.id_patient
                      FROM patient pat1
                     WHERE pat1.id_patient = i_id_pat
                       AND pat1.flg_status = g_patient_active) tab_age
             WHERE p.id_patient = i_id_pat
               AND p.flg_status = g_patient_active
               AND tab_age.id_patient = p.id_patient;
    
    BEGIN
        g_error := 'GET CURSOR';
        OPEN c_pat;
        FETCH c_pat
            INTO l_months, l_days, l_age;
        g_found := c_pat%NOTFOUND;
        CLOSE c_pat;
    
        IF g_found
        THEN
            RETURN NULL;
        END IF;
    
        g_error := 'GET AGE';
        IF (l_age IS NULL)
        THEN
            --LG 2006-11-08
            IF l_months < 1
            THEN
                l_age := trunc(l_days);
            
            ELSIF l_months < 36
            THEN
                l_age := trunc(l_months);
            
            ELSE
                l_age := trunc(l_months / 12);
            END IF;
        END IF;
    
        RETURN l_age;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_pat_age;
    -- ###############################################################################################

    FUNCTION get_scales_class_pat
    (
        i_lang              NUMBER,
        i_value             IN scales_doc_value.value%TYPE,
        i_scales            NUMBER,
        i_id_patient        IN patient.id_patient%TYPE,
        i_prof              IN profissional,
        i_id_scales_formula IN scales_formula.id_scales_formula%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:  
           PARAMETROS:  Entrada: I_VALUE- 
                                 I_SCALES- 
                                
        
                  Saida: O_DESC_SCALES_CLASS-
                                 O_ERROR - erro
        
          CRIAÇÃO: SF 2006/11/17
          NOTAS:
        *********************************************************************************/
    
        CURSOR c_scales_class(l_age NUMBER) IS
            SELECT sc.code_scales_class desc_class
              FROM scales_class sc
              JOIN scales_formula sf
                ON sf.id_scales_formula = sc.id_scales_formula
             WHERE sf.id_scales = i_scales
               AND sc.max_value >= i_value
               AND sc.min_value <= i_value
               AND sc.flg_available = 'Y'
               AND (sc.age_min IS NULL OR sc.age_min <= nvl(l_age, sc.age_min))
               AND (sc.age_max IS NULL OR sc.age_max >= nvl(l_age, sc.age_max))
               AND (sc.id_scales_formula = i_id_scales_formula OR i_id_scales_formula IS NULL);
    
        l_scales_class VARCHAR2(2000);
        --l_error        VARCHAR2(4000);
        l_age NUMBER;
    
    BEGIN
    
        l_age := pk_inp_nurse.get_pat_age(i_lang => i_lang, i_id_pat => i_id_patient, i_prof => i_prof);
    
        --l_error := 'GET CURSOR C_SCALES_CLASS ';
        OPEN c_scales_class(l_age);
        FETCH c_scales_class
            INTO l_scales_class;
        CLOSE c_scales_class;
        --
        RETURN l_scales_class;
    
    END get_scales_class_pat;

    FUNCTION get_scales_class
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_value             IN scales_class.max_value%TYPE,
        i_scales            IN scales.id_scales%TYPE,
        i_scope             IN NUMBER,
        i_scope_type        IN VARCHAR2 DEFAULT pk_alert_constant.g_scope_type_episode,
        i_id_scales_formula IN scales_formula.id_scales_formula%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:  
           PARAMETROS:  Entrada: I_VALUE- 
                                 I_SCALES- 
                                
        
                  Saida: O_DESC_SCALES_CLASS-
                                 O_ERROR - erro
        
          CRIAÇÃO: SF 2006/11/17
          NOTAS:
        *********************************************************************************/
    
        l_scales_class translation.desc_lang_1%TYPE;
        l_patient      patient.id_patient%TYPE;
    
    BEGIN
    
        IF i_scope_type = pk_alert_constant.g_scope_type_patient
        THEN
            l_patient := i_scope;
        ELSIF i_scope_type = pk_alert_constant.g_scope_type_episode
        THEN
            g_error := 'CALL pk_episode.get_id_patient: ' || i_scope;
            pk_alertlog.log_debug(g_error);
            l_patient := pk_episode.get_id_patient(i_episode => i_scope);
        ELSE
            SELECT v.id_patient
              INTO l_patient
              FROM visit v
             WHERE v.id_visit = i_scope;
        END IF;
    
        g_error := 'CALL get_scales_class';
        pk_alertlog.log_debug(g_error);
        l_scales_class := get_scales_class_pat(i_lang              => i_lang,
                                               i_value             => i_value,
                                               i_scales            => i_scales,
                                               i_id_patient        => l_patient,
                                               i_prof              => i_prof,
                                               i_id_scales_formula => i_id_scales_formula);
    
        --
        RETURN l_scales_class;
    
    END get_scales_class;

    FUNCTION get_scales_det
    (
        i_lang               IN NUMBER,
        i_epis_documentation IN NUMBER,
        o_scales_det         OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar o detalhe da escala de Norton
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                                 I_EPIS_DOCUMENTATION  - Episódio da documentation
        
                  Saida: O_SCALES_DET   
                                 O_ERROR - Erro
        
          CRIAÇÃO: SF 2006/11/17
          NOTAS:
        *********************************************************************************/
        --
    BEGIN
        g_error := 'GET CURSOR O_EPIS_BARTCHART';
        OPEN o_scales_det FOR
            SELECT eb.id_epis_documentation,
                   dc.id_doc_component,
                   pk_translation.get_translation(i_lang, dc.code_doc_component) desc_doc_component,
                   pk_translation.get_translation(i_lang, decr.code_element_close) desc_element
              FROM epis_documentation     eb,
                   epis_documentation_det ebd,
                   documentation          d,
                   doc_element            de,
                   doc_component          dc,
                   doc_element_crit       decr,
                   doc_criteria           dcr,
                   scales_doc_value       sdv
             WHERE eb.id_epis_documentation = i_epis_documentation
               AND eb.id_epis_documentation = ebd.id_epis_documentation(+)
               AND d.id_documentation(+) = ebd.id_documentation
               AND de.id_doc_element = ebd.id_doc_element
               AND d.id_doc_component = dc.id_doc_component(+)
               AND dc.flg_available(+) = g_available
               AND d.flg_available(+) = g_available
               AND ebd.id_doc_element_crit = decr.id_doc_element_crit
               AND decr.id_doc_criteria = dcr.id_doc_criteria
               AND sdv.id_doc_element(+) = de.id_doc_element;
        --
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
                                              'GET_SCALES_DET',
                                              o_error);
            pk_types.open_my_cursor(o_scales_det);
            RETURN FALSE;
        
    END;

    FUNCTION update_scales_task
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN NUMBER,
        i_prof     IN profissional,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Actualizar a coluna das escalas(Norton ou Braden) da tabela GRID_TASK  
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
                   I_EPISODE - ID do episódio
                                 I_PROF - ID do profissional
                                 
                  Saida: O_ERROR - erro 
        
          CRIAÇÃO: SF 2006/11/24  
          NOTAS:
        *********************************************************************************/
        l_scales_value scales_doc_value.value%TYPE;
        l_max          NUMBER;
        l_out          VARCHAR2(100);
        l_grid_task    grid_task%ROWTYPE;
        l_short_scales sys_shortcut.id_sys_shortcut%TYPE;
        --
        -- Obter ID do atalho
        CURSOR c_short_scales IS
            SELECT id_sys_shortcut
              FROM sys_shortcut
             WHERE intern_name = 'GRID_SCALES'
               AND id_software = i_prof.software
               AND id_institution IN (0, i_prof.institution)
             ORDER BY id_institution DESC;
    
        CURSOR c_scales IS
            SELECT eb.id_epis_documentation,
                   eb.flg_status,
                   pk_scales_core.get_main_score(i_lang, i_prof, eb.id_epis_documentation) soma
              FROM epis_documentation eb,
                   (SELECT MAX(ed.id_epis_documentation) epis_doc_max
                      FROM epis_documentation ed
                     WHERE ed.id_episode = i_episode
                       AND ed.flg_status = 'A') MAX
             WHERE eb.id_episode = i_episode
               AND eb.flg_status = g_active
               AND eb.id_doc_area = i_doc_area
               AND eb.flg_status = g_episode_flg_status_active
               AND max.epis_doc_max = eb.id_epis_documentation
             GROUP BY eb.id_epis_documentation, eb.flg_status
             ORDER BY eb.id_epis_documentation DESC;
        --
        l_flg_status    epis_documentation.flg_status%TYPE;
        l_grid_doc_area sys_config.value%TYPE;
    BEGIN
        g_found := FALSE;
    
        g_error := 'CALL pk_sysconfig.get_config: RISK_DOC_AREA.';
        pk_alertlog.log_debug(g_error);
        l_grid_doc_area := pk_sysconfig.get_config(i_code_cf => pk_scales_constant.g_grids_doc_area_sc,
                                                   i_prof    => i_prof);
    
        IF (l_grid_doc_area IS NOT NULL AND i_doc_area = to_number(l_grid_doc_area))
        THEN
        
            g_error := 'OPEN C_SHORT_SCALES';
            OPEN c_short_scales;
            FETCH c_short_scales
                INTO l_short_scales;
            CLOSE c_short_scales;
        
            g_error := 'OPEN C_SCALES';
            OPEN c_scales;
            FETCH c_scales
                INTO l_max, l_flg_status, l_scales_value;
            g_found := c_scales%FOUND;
            CLOSE c_scales;
        
            g_error := 'GET L_OUT';
            IF g_found
            THEN
                --   594|T||20||||
                l_out := '|' || g_numeric || '||' || l_scales_value || '||||0x787864|||||';
            END IF;
            -- 
            g_error := 'GET SHORTCUT';
            IF l_out IS NOT NULL
            THEN
                l_out := l_short_scales || l_out;
            
                l_grid_task.id_episode  := i_episode;
                l_grid_task.scale_value := l_out;
            
                --Actualiza estado da tarefa em GRID_TASK para o episódio correspondente
            
                IF NOT pk_grid.update_grid_task(i_lang => i_lang, i_grid_task => l_grid_task, o_error => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'UPDATE_SCALES_TASK',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
            ELSE
            
                l_grid_task.id_episode  := i_episode;
                l_grid_task.scale_value := l_out;
            
                UPDATE grid_task
                   SET scale_value = l_grid_task.scale_value
                 WHERE id_episode = l_grid_task.id_episode;
            
            END IF;
        
        END IF;
    
        --
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_SCALES_TASK',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /*  Returns the summary page values that does not have a registry (edition exchange). 
    * So, it indicates the registries that has a reason to do not being filled.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_doc_area                documentation area ID
    * @param i_flg_scope               Scope: P -patient; E- episode; V-visit; S-session
    * @param i_scope                   id_patient, id_visit, id_episode according to i_flg_type
    * @param i_coll_epis_doc           Table number with id_epis_documentation
    * @param i_start_date              Begin date (optional)        
    * @param i_end_date                End date (optional)
    * @param o_doc_not_register        Cursor containing the reason to not document the assessment    
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.0.5
    * @since                           06-01-2011
    **********************************************************************************************/
    FUNCTION get_doc_not_register
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_doc_area         IN doc_area.id_doc_area%TYPE,
        i_flg_scope        IN VARCHAR2,
        i_scope            IN patient.id_patient%TYPE,
        i_coll_epis_doc    IN table_number,
        i_start_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_doc_not_register OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exchange_record             CONSTANT VARCHAR2(1 CHAR) := 'X';
        l_no_documentation_title_code CONSTANT sys_message.code_message%TYPE := 'COMMON_T021';
    
        l_no_documentation_title sys_message.desc_message%TYPE;
    
        l_internal_error EXCEPTION;
        l_patient patient.id_patient%TYPE;
        l_episode episode.id_episode%TYPE;
        l_visit   visit.id_visit%TYPE;
    
    BEGIN
        l_no_documentation_title := pk_message.get_message(i_lang, l_no_documentation_title_code);
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_flg_scope,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        -- Get reasons to NOT document this assessment
        g_error := 'CALL TO GET_SCALES_LIST';
        pk_alertlog.log_debug(g_error);
        OPEN o_doc_not_register FOR
            SELECT t.id_epis_documentation,
                   t.flg_status,
                   t.id_doc_template,
                   t.id_doc_area,
                   t.id_epis_context id_cancel_reason,
                   l_no_documentation_title || ':' desc_title_cancel_reason,
                   decode(t.id_epis_context,
                          NULL,
                          '',
                          pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, t.id_epis_context)) desc_cancel_reason,
                   pk_string_utils.clob_to_sqlvarchar2(t.notes) notes,
                   t.flg_edition_type
              FROM (SELECT ed.id_epis_documentation,
                           ed.flg_status,
                           ed.id_doc_template,
                           ed.id_doc_area,
                           ed.id_epis_context,
                           ed.notes,
                           ed.flg_edition_type,
                           ed.dt_creation_tstz,
                           e.id_episode,
                           ed.id_episode_context,
                           e.id_visit
                      FROM epis_documentation ed
                      JOIN episode e
                        ON e.id_episode = ed.id_episode
                     WHERE e.id_patient = l_patient
                       AND ed.id_doc_area = i_doc_area
                       AND ed.flg_status = g_active
                       AND ed.flg_edition_type = l_exchange_record
                       AND ed.id_epis_documentation IN (SELECT column_value
                                                          FROM TABLE(i_coll_epis_doc))
                       AND rownum > 0) t
             WHERE (t.id_episode = coalesce(l_episode, t.id_episode) OR
                   t.id_episode_context = coalesce(l_episode, t.id_episode_context))
               AND t.id_visit = coalesce(l_visit, t.id_visit)
               AND t.dt_creation_tstz >= coalesce(i_start_date, t.dt_creation_tstz)
               AND t.dt_creation_tstz <= coalesce(i_end_date, t.dt_creation_tstz)
             ORDER BY t.dt_creation_tstz DESC;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN l_internal_error THEN
            pk_types.open_my_cursor(o_doc_not_register);
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DOC_NOT_REGISTER',
                                              o_error);
            pk_types.open_my_cursor(o_doc_not_register);
            RETURN FALSE;
    END get_doc_not_register;

    /*  Returns the summary page values for the scale evaluation summary page.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_doc_area                documentation area ID
    * @param i_id_episode              Episode identifier; mandatory if i_flg_scope='E'
    * @param i_flg_scope               Scope: P -patient; E- episode; V-visit
    * @param i_scope                   Scope ID (Episode ID; Visit ID; Patient ID)    
    * @param i_flg_calc_scores         Y-calculate and return the total score. N-otherwise
    * @param i_start_date              Begin date (optional)        
    * @param i_end_date                End date (optional)
    * @param i_paging                  Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param i_start_record            First record. Just considered when paging is used. Default 1
    * @param i_num_records             Number of records to be retrieved. Just considered when paging is used.  Default 20
    * @param o_doc_area_register       Cursor with the doc area info register
    * @param o_doc_area_val            Cursor containing the completed info for episode
    * @param o_doc_not_register        Cursor containing the reason to not document the assessment    
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.0.5
    * @since                           06-01-2011
    **********************************************************************************************/
    FUNCTION get_scales_summ_page_int
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_doc_area           IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_scope          IN VARCHAR2,
        i_scope              IN NUMBER,
        i_flg_calc_scores    IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_start_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 20,
        i_num_record_show    IN NUMBER DEFAULT NULL,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_scales         OUT pk_types.cursor_type,
        o_doc_not_register   OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(30) := 'GET_SCALES_SUMM_PAGE_INT';
    
        e_doc_area_value_ids EXCEPTION;
        e_doc_area_value     EXCEPTION;
        e_scales_list        EXCEPTION;
        e_doc_not_register   EXCEPTION;
    
        l_order_by sys_config.value%TYPE;
    
        l_coll_epis_doc      table_number;
        l_coll_epis_anamn    table_number;
        l_coll_epis_rev_sys  table_number;
        l_coll_epis_obs      table_number;
        l_coll_epis_past_fsh table_number;
        l_coll_epis_recomend table_number;
    
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
    
        g_error := 'Get configuration of the chronological order to apply to records';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_owner, sub_object_name => l_function_name);
    
        l_order_by := pk_sysconfig.get_config('HISTORY_ORDER_BY', i_prof);
        l_order_by := nvl(l_order_by, 'DESC');
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_IDS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_touch_option.get_doc_area_value_ids(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_doc_area           => table_number(i_doc_area),
                                                      i_scope              => table_number(i_scope),
                                                      i_scope_type         => i_flg_scope,
                                                      i_order              => l_order_by,
                                                      i_fltr_start_date    => i_start_date,
                                                      i_fltr_end_date      => i_end_date,
                                                      i_paging             => i_paging,
                                                      i_start_record       => i_start_record,
                                                      i_num_records        => i_num_records,
                                                      o_record_count       => o_record_count,
                                                      o_coll_epis_doc      => l_coll_epis_doc,
                                                      o_coll_epis_anamn    => l_coll_epis_anamn,
                                                      o_coll_epis_rev_sys  => l_coll_epis_rev_sys,
                                                      o_coll_epis_obs      => l_coll_epis_obs,
                                                      o_coll_epis_past_fsh => l_coll_epis_past_fsh,
                                                      o_coll_epis_recomend => l_coll_epis_recomend,
                                                      o_error              => o_error)
        
        THEN
            RAISE e_doc_area_value_ids;
        END IF;
    
        IF i_flg_scope = pk_alert_constant.g_scope_type_patient
        THEN
            l_id_patient := i_scope;
        ELSE
            g_error := 'CALL pk_episode.get_id_patient: i_id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
        END IF;
    
        g_error := 'CALL PK_TOUCH_OPTION.GET_DOC_AREA_VALUE_INTERNAL';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_touch_option.get_doc_area_value_internal(i_lang               => i_lang,
                                                           i_prof               => i_prof,
                                                           i_id_episode         => i_id_episode,
                                                           i_id_patient         => l_id_patient,
                                                           i_doc_area           => i_doc_area,
                                                           i_epis_doc           => l_coll_epis_doc,
                                                           i_epis_anamn         => NULL,
                                                           i_epis_rev_sys       => NULL,
                                                           i_epis_obs           => NULL,
                                                           i_epis_past_fsh      => NULL,
                                                           i_epis_recomend      => NULL,
                                                           i_flg_show_fm        => pk_alert_constant.g_no,
                                                           i_order              => l_order_by,
                                                           i_num_record_show    => i_num_record_show,
                                                           o_doc_area_register  => o_doc_area_register,
                                                           o_doc_area_val       => o_doc_area_val,
                                                           o_template_layouts   => o_template_layouts,
                                                           o_doc_area_component => o_doc_area_component,
                                                           o_error              => o_error)
        THEN
            RAISE e_doc_area_value;
        END IF;
    
        IF (i_flg_calc_scores = pk_alert_constant.g_yes)
        THEN
            g_error := 'CALL TO GET_SCALES_LIST';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            IF NOT pk_scales_core.get_scales_list(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_doc_area      => i_doc_area,
                                                  i_scope         => i_scope,
                                                  i_scope_type    => i_flg_scope,
                                                  i_start_date    => i_start_date,
                                                  i_end_date      => i_end_date,
                                                  i_coll_epis_doc => l_coll_epis_doc,
                                                  o_scales_list   => o_doc_scales,
                                                  o_error         => o_error)
            THEN
                RAISE e_scales_list;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_doc_scales);
        END IF;
    
        g_error := 'CALL get_doc_not_register. i_flg_scope: ' || i_flg_scope || '; i_scope: ' || i_scope;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT get_doc_not_register(i_lang             => i_lang,
                                    i_prof             => i_prof,
                                    i_doc_area         => i_doc_area,
                                    i_flg_scope        => i_flg_scope,
                                    i_scope            => i_scope,
                                    i_coll_epis_doc    => l_coll_epis_doc,
                                    i_start_date       => i_start_date,
                                    i_end_date         => i_end_date,
                                    o_doc_not_register => o_doc_not_register,
                                    o_error            => o_error)
        THEN
            RAISE e_doc_not_register;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN e_scales_list THEN
            pk_types.open_my_cursor(o_doc_scales);
            pk_types.open_my_cursor(o_doc_not_register);
        
            RETURN FALSE;
        WHEN e_doc_not_register THEN
            pk_types.open_my_cursor(o_doc_not_register);
        
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
        
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_scales);
            pk_types.open_my_cursor(o_doc_not_register);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        
            RETURN FALSE;
    END get_scales_summ_page_int;

    --
    /********************************************************************************************
    *  Returns the summary page values for the scale evaluation summary page.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_doc_area                documentation area ID
    * @param i_id_episode              the episode id
    * @param o_doc_area_register       Cursor with the doc area info register
    * @param o_doc_area_val            Cursor containing the completed info for episode
    * @param o_doc_scales              Cursor containing the association between documentation elements and scale values    
    * @param o_doc_not_register        Cursor containing the reason to not document the assessment    
    * @param   o_template_layouts   Cursor containing the layout for each template used
    * @param   o_doc_area_component Cursor containing the components for each template used 
    * @param   o_record_count       Indicates the number of records that match filters criteria
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          José Silva
    * @version                         1.0
    * @since                           12-11-2007
    **********************************************************************************************/
    FUNCTION get_scales_summ_page
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_doc_area           IN NUMBER,
        i_id_episode         IN NUMBER,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_scales         OUT pk_types.cursor_type,
        o_doc_not_register   OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        err_summ_page_doc_area_value EXCEPTION;
        err_get_scales_list          EXCEPTION;
    
        l_id_patient patient.id_patient%TYPE;
    
    BEGIN
        g_error := 'CALL pk_episode.get_id_patient: i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
    
        g_error := 'CALL get_scales_summ_page: i_doc_area: ' || i_doc_area || '; i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT get_scales_summ_page_int(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_doc_area           => i_doc_area,
                                        i_flg_scope          => pk_inp_util.g_scope_patient_p,
                                        i_id_episode         => i_id_episode,
                                        i_scope              => l_id_patient,
                                        o_doc_area_register  => o_doc_area_register,
                                        o_doc_area_val       => o_doc_area_val,
                                        o_doc_scales         => o_doc_scales,
                                        o_doc_not_register   => o_doc_not_register,
                                        o_template_layouts   => o_template_layouts,
                                        o_doc_area_component => o_doc_area_component,
                                        o_record_count       => o_record_count,
                                        o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCALES_SUMM_PAGE',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_scales);
            pk_types.open_my_cursor(o_doc_not_register);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            RETURN FALSE;
    END get_scales_summ_page;

    /*  Returns the summary page values for the scale evaluation summary page.
    * This functions can by filter by episode, patient or visit according to the given i_flg_scope.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_doc_area                documentation area ID
    * @param i_id_episode              Episode identifier; mandatory if i_flg_scope='E'
    * @param i_flg_scope               Scope: P -patient; E- episode; V-visit; S-session
    * @param i_scope                   For i_flg_scope = P, i_scope regards to id_patient
    *                                  For i_flg_scope = V, i_scope regards to id_visit
    *                                  For i_flg_scope = E, i_scope regards to id_episode
    * @param i_start_date              Start date
    * @param i_end_date                End date
    * @param o_doc_area_register       Cursor with the doc area info register
    * @param o_doc_area_val            Cursor containing the completed info for episode
    * @param o_doc_scales              Cursor containing the association between documentation elements and scale values    
    * @param o_doc_not_register        Cursor containing the reason to not document the assessment
    * @param o_template_layouts        Cursor containing the layout for each template used
    * @param o_doc_area_component      Cursor containing the components for each template used 
    * @param o_record_count            Indicates the number of records that match filters criteria
    * @param o_groups                  Groups info: indicated the id_documentations that belongs to each group
    * @param o_scores                  Scores info    
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.0.5
    * @since                           06-01-2011
    *
    * DEPENDENCIES: REPORTS
    **********************************************************************************************/
    FUNCTION get_scales_summ_page
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_doc_area           IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_scope          IN VARCHAR2,
        i_scope              IN NUMBER,
        i_start_date         IN VARCHAR2 DEFAULT NULL,
        i_end_date           IN VARCHAR2 DEFAULT NULL,
        i_num_record_show    IN NUMBER DEFAULT NULL,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_not_register   OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_groups             OUT pk_types.cursor_type,
        o_scores             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient    patient.id_patient%TYPE;
        l_visit      visit.id_visit%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_doc_scales pk_types.cursor_type;
    
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_start_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_start_date,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Convert end date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_end_date,
                                             i_timezone  => NULL,
                                             o_timestamp => l_end_date,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_scales_summ_page: i_doc_area: ' || i_doc_area || '; i_flg_scope: ' || i_flg_scope ||
                   '; i_id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT get_scales_summ_page_int(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_doc_area           => i_doc_area,
                                        i_flg_scope          => i_flg_scope,
                                        i_id_episode         => i_id_episode,
                                        i_scope              => i_scope,
                                        i_flg_calc_scores    => pk_alert_constant.g_no,
                                        i_start_date         => l_start_date,
                                        i_end_date           => l_end_date,
                                        i_num_record_show    => i_num_record_show,
                                        o_doc_area_register  => o_doc_area_register,
                                        o_doc_area_val       => o_doc_area_val,
                                        o_doc_scales         => l_doc_scales,
                                        o_doc_not_register   => o_doc_not_register,
                                        o_template_layouts   => o_template_layouts,
                                        o_doc_area_component => o_doc_area_component,
                                        o_record_count       => o_record_count,
                                        o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL pk_scales_formulas.get_groups. i_id_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_formulas.get_groups(i_lang     => i_lang,
                                             i_prof     => i_prof,
                                             i_doc_area => i_doc_area,
                                             i_scales   => NULL,
                                             o_groups   => o_groups,
                                             o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_flg_scope,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_scales_core.get_saved_scores. i_id_patient: ' || l_patient || ' i_id_visit: ' || l_visit ||
                   ' i_id_episode: ' || l_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.get_saved_scores(i_lang                  => i_lang,
                                               i_prof                  => i_prof,
                                               i_id_epis_documentation => NULL,
                                               i_id_patient            => l_patient,
                                               i_id_visit              => l_visit,
                                               i_id_episode            => l_episode,
                                               i_id_doc_area           => i_doc_area,
                                               i_start_date            => i_start_date,
                                               i_end_date              => i_end_date,
                                               o_scores                => o_scores,
                                               o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCALES_SUMM_PAGE',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_not_register);
            pk_types.open_my_cursor(o_scores);
            pk_types.open_my_cursor(o_groups);
            RETURN FALSE;
    END get_scales_summ_page;

    /*  Returns the summary page values for the scale evaluation summary page with pagination
    *
    * @param    i_lang                    Language identifier
    * @param    i_prof                    Professional, software and institution identifiers
    * @param    i_doc_area                Documentation area identifier
    * @param    i_id_episode              Episode identifier; mandatory if i_flg_scope='E'
    * @param    i_scope                   Scope identifier (Episode identifier; Visit identifier; Patient identifier)
    * @param    i_flg_scope               Scope: P -patient; E- episode; V-visit
    * @param    i_paging                  Use paging ('Y' Yes; 'N' No) Default 'N'
    * @param    i_start_record            First record. Just considered when paging is used. Default 1
    * @param    i_num_records             Number of records to be retrieved. Just considered when paging is used.  Default 20
    *
    * @param    o_doc_area_register       Cursor with the doc area info register
    * @param    o_doc_area_val            Cursor containing the completed info for episode
    * @param    o_doc_scales              Cursor containing the association between documentation elements and scale values    
    * @param    o_doc_not_register        Cursor containing the reason to not document the assessment
    * @param    o_template_layouts        Cursor containing the layout for each template used
    * @param    o_doc_area_component      Cursor containing the components for each template used 
    * @param    o_record_count            Indicates the number of records that match filters criteria
    * @param    o_error                   Error message
    *
    * @return                             true (sucess), false (error)
    *
    * @value    i_flg_scope               {*} 'E'- Episode {*} 'P'- Patient {*} 'V'- Visit
    * @value    i_paging                  {*} 'Y'- Yes {*} 'N'- No
    *
    * @author                             Sofia Mendes
    * @version                            2.6.0.5
    * @since                              06-01-2011
    *
    * @author                             ANTONIO.NETO
    * @version                            2.6.2.1
    * @since                              16-May-2012
    **********************************************************************************************/
    FUNCTION get_scales_summ_page
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_doc_area           IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_scope              IN NUMBER,
        i_flg_scope          IN VARCHAR2,
        i_paging             IN VARCHAR2 DEFAULT 'N',
        i_start_record       IN NUMBER DEFAULT 1,
        i_num_records        IN NUMBER DEFAULT 20,
        o_doc_area_register  OUT pk_types.cursor_type,
        o_doc_area_val       OUT pk_types.cursor_type,
        o_doc_scales         OUT pk_types.cursor_type,
        o_doc_not_register   OUT pk_types.cursor_type,
        o_template_layouts   OUT pk_types.cursor_type,
        o_doc_area_component OUT pk_types.cursor_type,
        o_record_count       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_scales_summ_page_int EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL get_scales_summ_page: i_doc_area: ' || i_doc_area || '; i_id_episode: ' || i_id_episode ||
                   '; i_scope: ' || i_scope;
        pk_alertlog.log_debug(g_error);
        IF NOT get_scales_summ_page_int(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_doc_area           => i_doc_area,
                                        i_id_episode         => i_id_episode,
                                        i_scope              => i_scope,
                                        i_flg_scope          => i_flg_scope,
                                        i_paging             => i_paging,
                                        i_start_record       => i_start_record,
                                        i_num_records        => i_num_records,
                                        o_doc_area_register  => o_doc_area_register,
                                        o_doc_area_val       => o_doc_area_val,
                                        o_doc_scales         => o_doc_scales,
                                        o_doc_not_register   => o_doc_not_register,
                                        o_template_layouts   => o_template_layouts,
                                        o_doc_area_component => o_doc_area_component,
                                        o_record_count       => o_record_count,
                                        o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCALES_SUMM_PAGE',
                                              o_error);
        
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_doc_area_val);
            pk_types.open_my_cursor(o_doc_scales);
            pk_types.open_my_cursor(o_doc_not_register);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
        
            RETURN FALSE;
    END get_scales_summ_page;
    FUNCTION cancel_epis_documentation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes       IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_touch_option.cancel_epis_documentation(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_id_epis_doc   => i_id_epis_doc,
                                                         i_notes         => i_notes,
                                                         i_test          => pk_alert_constant.get_no,
                                                         i_cancel_reason => i_id_cancel_reason,
                                                         o_flg_show      => o_flg_show,
                                                         o_msg_title     => o_msg_title,
                                                         o_msg_text      => o_msg_text,
                                                         o_button        => o_button,
                                                         o_error         => o_error);
    
    END cancel_epis_documentation;
    /********************************************************************************************
    *  Cancel docuemnttion of ulcer risk assessment
    *  It also updates the scales task.
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_id_episode                 id do episode
    * @param i_doc_area                   doc_area id
    * @param i_id_epis_doc                the documentation episode ID to cancelled
    * @param i_id_cancel_reason           Cancel reason
    * @param i_notes                      Cancel Notes
    * @param i_flg_show                   Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title                  Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text                   Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                     Botões a mostrar: N - Não, R - lido, C - confirmado
    * @param o_error                      Error message
    *                    
    * @return                             true or false on success or error
    *
    * @author                          Carlos Ferreira
    * @version                         1.0
    * @since                           18-02-2008
    **********************************************************************************************/
    FUNCTION cancel_scale_epis_doc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes       IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_scales_core.cancel_scales_score_vs(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_id_episode       => i_id_episode,
                                                     i_id_epis_doc      => i_id_epis_doc,
                                                     i_id_cancel_reason => i_id_cancel_reason,
                                                     i_notes            => i_notes,
                                                     o_error            => o_error)
        THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_SCALE_EPIS_DOC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        END IF;
    
        IF NOT pk_touch_option.cancel_epis_documentation(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_id_epis_doc   => i_id_epis_doc,
                                                         i_notes         => i_notes,
                                                         i_test          => pk_alert_constant.get_no,
                                                         i_cancel_reason => i_id_cancel_reason,
                                                         o_flg_show      => o_flg_show,
                                                         o_msg_title     => o_msg_title,
                                                         o_msg_text      => o_msg_text,
                                                         o_button        => o_button,
                                                         o_error         => o_error)
        THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_SCALE_EPIS_DOC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
            IF NOT update_scales_task(i_lang     => i_lang,
                                      i_episode  => i_id_episode,
                                      i_doc_area => i_doc_area,
                                      i_prof     => i_prof,
                                      o_error    => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'CANCEL_SCALE_EPIS_DOC',
                                                  o_error);
                pk_utils.undo_changes;
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
                                              'CANCEL_SCALE_EPIS_DOC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_scale_epis_doc;

    /********************************************************************************************
    * Gets documentation values associated with an area (doc_area) of a template (doc_template). 
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param i_prof_cat_type              professional category
    * @param i_doc_area                   doc_area id
    * @param i_doc_template               doc_template id
    * @param i_epis_documentation         epis documentation id
    * @param i_flg_type                   A Agree, E edit, N - new 
    * @param i_id_documentation           array with id documentation,
    * @param i_id_doc_element             array with doc elements
    * @param i_id_doc_element_crit        array with doc elements crit
    * @param i_value                      array with values,
    * @param i_notes                      note
    * @param i_id_doc_element_qualif      array with doc elements qualif  
    * @param i_epis_context               context id (Ex: id_interv_presc_det, id_exam...)
    * @param i_summary_and_notes          template summary to be included on clinical notes
    * @param i_episode_context            context episode id  used in preoperative ORIS area by OUTP, INP, EDIS 
    * @param i_flg_table_origin            Table source when is a record edition. Default: D - EPIS_DOCUMENTATION
    * @param o_error                       Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit {*} 'A' Agree {*} 'U' Update from previous assessment {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBSERVATION
    * @value i_flg_commit                  {*} 'Y'  For commit, 'N' otherwise
    * @value o_schow_action                Returns if is necessary to show pop-up with actions
    * @value o_action                      Returns actions for the result
    * @value o_score                       Returns result score                                    
    *                    
    * @return                             true or false on success or error
    *
    * @author                             Rita Lopes, based on pk_touch_option.set_epis_documentation
    * @version                            1.0   
    * @since                              08-04-2010
    *
    **********************************************************************************************/
    FUNCTION get_scales_evaluation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_show_action        OUT VARCHAR2,
        o_action             OUT pk_types.cursor_type,
        o_title_message      OUT VARCHAR2,
        o_desc_message       OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_action_available(v_summ scales_class.min_value%TYPE) IS
            SELECT DISTINCT flg_available, scalesactiongroup, descritive
              FROM (SELECT sagsi.flg_available,
                           sc.id_scales_action_group scalesactiongroup,
                           pk_translation.get_translation(i_lang, s.code_scale_score) descritive
                      FROM documentation                 d,
                           doc_element                   de,
                           scales_doc_value              sdv,
                           scales_class                  sc,
                           scales_action_group           sag,
                           scales_action                 sa,
                           scales_action_group_soft_inst sagsi,
                           scales                        s,
                           scales_formula                sf,
                           doc_template_area_doc         dtad
                     WHERE dtad.id_doc_template = i_doc_template
                       AND dtad.id_doc_area = i_doc_area
                       AND dtad.id_documentation = d.id_documentation
                       AND d.id_documentation = de.id_documentation
                       AND sdv.id_doc_element = de.id_doc_element
                       AND sdv.id_scales = s.id_scales
                       AND sc.id_scales_action_group = sag.id_scales_action_group
                       AND sa.id_scales_action = sagsi.id_scales_action
                       AND sag.id_scales_action_group = sagsi.id_scales_action_group
                       AND sagsi.id_software IN (0, i_prof.software)
                       AND sagsi.id_institution IN (0, i_prof.institution)
                       AND v_summ BETWEEN sc.min_value AND sc.max_value
                       AND sc.flg_available = g_available
                       AND sa.flg_available = g_available
                          --                       AND sasi.flg_available = g_available
                       AND s.id_scales = sf.id_scales
                       AND sf.id_scales_formula = sc.id_scales_formula
                     ORDER BY sagsi.id_institution DESC, sagsi.id_software DESC, sagsi.flg_available);
        r_action_available c_action_available%ROWTYPE;
    
        l_summ                NUMBER(24);
        l_scales_action_group scales_action_group.id_scales_action_group%TYPE;
        l_doc_template        translation.code_translation%TYPE;
        l_scales_desc         translation.code_translation%TYPE;
        l_flg_available       scales_action_group_soft_inst.flg_available%TYPE := 'N';
    
    BEGIN
        g_error := 'CALL pk_scales_core.get_main_score. i_id_epis_documentation: ' || i_epis_documentation;
        pk_alertlog.log_debug(g_error);
        l_summ := pk_scales_core.get_main_score(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_id_epis_documentation => i_epis_documentation);
    
        --        BEGIN
    
        OPEN c_action_available(l_summ);
        FETCH c_action_available
            INTO r_action_available;
        IF c_action_available%FOUND
        THEN
            l_flg_available       := r_action_available.flg_available;
            l_scales_action_group := r_action_available.scalesactiongroup;
            l_scales_desc         := r_action_available.descritive;
        
        ELSE
            o_show_action := g_value_n;
            pk_types.open_my_cursor(o_action);
        END IF;
        CLOSE c_action_available;
    
        IF l_flg_available = g_available
        THEN
        
            SELECT pk_translation.get_translation(i_lang, dt.code_doc_template)
              INTO l_doc_template
              FROM doc_template dt
             WHERE dt.id_doc_template = i_doc_template;
        
            OPEN o_action FOR
                SELECT sa.id_scales_action,
                       sa.internal_name,
                       pk_translation.get_translation(i_lang, sa.code_scales_action) action,
                       decode(sasi.flg_default, NULL, sa.flg_default, sasi.flg_default) flg_default
                  FROM scales_action sa, scales_action_group_soft_inst sasi
                 WHERE sa.id_scales_action = sasi.id_scales_action
                   AND sasi.id_software IN (0, i_prof.software)
                   AND sasi.id_institution IN (0, i_prof.institution)
                   AND sasi.id_scales_action_group = l_scales_action_group
                   AND sa.flg_available = g_available
                   AND sasi.flg_available = g_available
                 ORDER BY sa.rank;
        
            o_show_action   := pk_alert_constant.get_yes;
            o_title_message := REPLACE(pk_message.get_message(i_lang, 'SCALES_T039'), '%%1', l_doc_template) || l_summ || ' ' ||
                               l_scales_desc || '.';
            o_desc_message  := pk_message.get_message(i_lang, 'SCALES_T040') || ' ' || l_doc_template || ' ' ||
                               pk_message.get_message(i_lang, 'SCALES_T036') || ' ' || l_summ || ' ' || l_scales_desc || '.';
        
        ELSE
            o_show_action := g_value_n;
            pk_types.open_my_cursor(o_action);
        END IF;
    
        /*        EXCEPTION
                    WHEN no_data_found THEN
                        o_show_action := g_value_n;
                        pk_types.open_my_cursor(o_action);
                    WHEN OTHERS THEN
                        pk_types.open_my_cursor(o_action);
                        o_show_action := g_value_n;
                END;
        */
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_action);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCALES_EVALUATION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
    END get_scales_evaluation;

    /********************************************************************************************
    * Answer to avaliaton action
    *
    * @param i_lang                       language id
    * @param i_prof                       professional, software and institution ids
    * @param o_error                       Error message
    *
    * @return                             true or false on success or error
    *
    * @author                             Rita Lopes
    * @version                            1.0   
    * @since                              09-04-2010
    *
    **********************************************************************************************/
    FUNCTION set_scales_action
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_action_intern_name IN scales_action.internal_name%TYPE,
        i_scales_action      IN scales_action.id_scales_action%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_patient         IN patient.id_patient%TYPE,
        i_notes_reason       IN consult_req.reason_for_visit%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dep_clin_service clinical_service.id_clinical_service%TYPE;
        l_consult_req      consult_req.id_consult_req%TYPE;
        l_opinion          opinion.id_opinion%TYPE;
        l_opinion_hist     opinion_hist.id_opinion_hist%TYPE;
        l_lst_rows         table_varchar;
    
        l_tbl_ds_cmpt_mkt_rel table_number;
        l_tbl_val             table_table_varchar;
        l_tbl_val_clob        table_clob;
    
    BEGIN
    
        IF i_action_intern_name = 'FOLLOWUP_REQUEST'
        THEN
            -- Inserir um pedido de acompanhamento        
            IF NOT pk_opinion.set_consult_request(i_lang,
                                                  i_prof,
                                                  i_id_episode,
                                                  i_id_patient,
                                                  NULL, -- opinion
                                                  pk_opinion.g_flg_type_nutritionist, --i_opinion_type,
                                                  NULL, --i_clin_serv,
                                                  i_notes_reason, --i_reason_ft 
                                                  NULL, --i_reason_mc => 
                                                  NULL,
                                                  NULL,
                                                  pk_opinion.g_any_prof, -- i_prof_id 
                                                  NULL, --i_notes
                                                  pk_alert_constant.g_yes, --i_do_commit
                                                  pk_alert_constant.g_no,
                                                  NULL,
                                                  l_tbl_ds_cmpt_mkt_rel,
                                                  l_tbl_val,
                                                  l_tbl_val_clob,
                                                  l_opinion,
                                                  l_opinion_hist,
                                                  o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSIF i_action_intern_name = 'CONSULT_REQUEST'
        THEN
            -- Inserir um pedido de consulta com um dep_clin_serv por defeito (sys_config)
            l_dep_clin_service := pk_sysconfig.get_config('PARAMEDICAL_REQUESTS_DEFAULT_DEP_CLIN_SERV', i_prof);
            IF l_dep_clin_service = -1
            THEN
                RETURN FALSE;
            END IF;
        
            IF NOT pk_consult_req.set_consult_req(i_lang             => i_lang,
                                                  i_episode          => i_id_episode,
                                                  i_prof_req         => i_prof,
                                                  i_pat              => i_id_patient,
                                                  i_instit_requests  => NULL,
                                                  i_instit_requested => NULL,
                                                  i_consult_type     => NULL,
                                                  i_clinical_service => NULL,
                                                  i_dt_scheduled_str => NULL,
                                                  i_flg_type_date    => NULL,
                                                  i_notes            => NULL,
                                                  i_dep_clin_serv    => l_dep_clin_service,
                                                  i_prof_requested   => -1,
                                                  i_prof_cat_type    => 'U',
                                                  i_id_complaint     => NULL,
                                                  i_flg_type         => 'S',
                                                  o_consult_req      => l_consult_req,
                                                  o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        ELSE
            RETURN TRUE;
        END IF;
    
        -- Confirmar que deve ser assim
        g_error := 'UPDATING EPIS_DOCUMENTATION';
        ts_epis_documentation.upd(id_epis_documentation_in => i_epis_documentation,
                                  id_scales_action_in      => i_scales_action,
                                  rows_out                 => l_lst_rows);
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DOCUMENTATION',
                                      i_rowids       => l_lst_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_SCALES_ACTION'));
    
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
                                              'SET_SCALES_ACTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
        
    END set_scales_action;

    /********************************************************************************************
    *  Checks if an episode has records for a provided assessment.
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_episode                 Episode ID
    * @param i_id_doc_area             Documentation area ID
    * @param i_cancel_area             Cancel reason area 
    * @param o_flg_show                Show warning modal window?
    * @param o_flg_write               Professional has permission to document the assessment?
    * @param o_reasons                 Reasons to not fill the assessment
    * @param o_error                   Error message
    *
    * @value o_flg_show                {*} 'Y' Yes {*} 'N' No 
    * @value o_flg_write               {*} 'Y' Yes {*} 'N' No 
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          José Brito
    * @version                         2.5.0.7.8
    * @since                           03-12-2010
    **********************************************************************************************/
    FUNCTION check_assessment_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        i_cancel_area IN cancel_rea_area.intern_name%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_flg_write   OUT summary_page_access.flg_write%TYPE,
        o_reasons     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(200 CHAR) := 'CHECK_ASSESSMENT_WARNING';
        l_internal_error EXCEPTION;
        l_no_results          CONSTANT NUMBER(6) := 0;
        l_year_months         CONSTANT NUMBER(6) := 12;
        l_decimal             CONSTANT NUMBER(6) := 0;
        l_first_result        CONSTANT NUMBER(6) := 1;
        l_undetermined_gender CONSTANT VARCHAR2(1 CHAR) := 'I';
    
        l_count                NUMBER(6);
        l_show_warning_message BOOLEAN := TRUE;
        l_config_show_warn CONSTANT sys_config.id_sys_config%TYPE := 'SPUTOVAMO_SHOW_WARNING';
    
        l_profile_template      profile_template.id_profile_template%TYPE;
        l_flg_write             summary_page_access.flg_write%TYPE;
        l_id_doc_area           doc_area.id_doc_area%TYPE;
        l_age                   patient.age%TYPE;
        l_gender                patient.gender%TYPE;
        l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        l_id_market             market.id_market%TYPE;
    
    BEGIN
    
        g_error := 'GET ID MARKET';
        pk_alertlog.log_debug(g_error);
        SELECT nvl(i.id_market, pk_alert_constant.g_inst_all)
          INTO l_id_market
          FROM institution i
         WHERE i.id_institution = i_prof.institution;
    
        g_error := 'CHECK ID_DOC_AREA AVAILABILITY - INSTITUTION';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(*)
          INTO l_count
          FROM TABLE(pk_touch_option.tf_doc_area_inst_soft(i_id_doc_area,
                                                           i_prof.institution,
                                                           l_id_market,
                                                           i_prof.software));
    
        IF l_count > l_no_results -- Documentation area is available. Validate if warning message is required.
           AND pk_sysconfig.get_config(l_config_show_warn, i_prof) = pk_alert_constant.g_yes
        THEN
            -- Get professional profile 
            g_error := 'GET PROFILE';
            pk_alertlog.log_debug(g_error);
            l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
        
            -- Check patient's age and gender
            g_error := 'GET PATIENT DATA';
            pk_alertlog.log_debug(g_error);
            SELECT pat.gender,
                   nvl(pat.age, trunc(months_between(SYSDATE, pat.dt_birth) / l_year_months, l_decimal)) age_in_years
              INTO l_gender, l_age
              FROM episode epis
              JOIN patient pat
                ON pat.id_patient = epis.id_patient
             WHERE epis.id_episode = i_episode;
        
            -- Check if documentation area is applicable to the current patient;
            -- Also check if professional has 'write' permissions
            BEGIN
                g_error := 'CHECK ID_DOC_AREA AVAILABILITY - PATIENT';
                pk_alertlog.log_debug(g_error);
                SELECT da.id_doc_area, spa.flg_write
                  INTO l_id_doc_area, l_flg_write
                  FROM doc_area da
                  JOIN summary_page_section s
                    ON s.id_doc_area = da.id_doc_area
                  JOIN summary_page_access spa
                    ON spa.id_summary_page_section = s.id_summary_page_section
                 WHERE da.id_doc_area = i_id_doc_area
                   AND spa.id_profile_template = l_profile_template
                   AND (da.gender IS NULL OR da.gender = l_gender OR l_gender = l_undetermined_gender)
                   AND (da.age_min IS NULL OR da.age_min <= l_age OR l_age IS NULL)
                   AND (da.age_max IS NULL OR da.age_max >= l_age OR l_age IS NULL);
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_doc_area := NULL;
                    l_flg_write   := NULL;
            END;
        
            -- Check if patient has records for the given documentation area.
            BEGIN
                g_error := 'CHECK EXISTING RECORDS';
                pk_alertlog.log_debug(g_error);
                SELECT id_epis_documentation
                  INTO l_id_epis_documentation
                  FROM (SELECT ed.id_epis_documentation,
                               ed.dt_creation_tstz,
                               row_number() over(ORDER BY ed.dt_creation_tstz DESC) rn
                          FROM epis_documentation ed
                         WHERE ed.id_episode = i_episode
                           AND ed.id_doc_area = i_id_doc_area
                           AND ed.flg_status = g_active
                           AND ed.dt_creation_tstz IS NOT NULL)
                 WHERE rn = l_first_result;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_epis_documentation := NULL;
            END;
        
            IF l_id_epis_documentation IS NULL
               AND l_id_doc_area IS NOT NULL
            THEN
                -- Show warning message.
                o_flg_show := pk_alert_constant.g_yes;
            
                -- Return write permissions
                o_flg_write := l_flg_write;
            
                IF i_cancel_area IS NOT NULL
                THEN
                    -- Get reasons to not document the doc area.
                    g_error := 'GET REASONS';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_cancel_reason.get_cancel_reason_list(i_lang    => i_lang,
                                                                   i_prof    => i_prof,
                                                                   i_area    => i_cancel_area,
                                                                   o_reasons => o_reasons,
                                                                   o_error   => o_error)
                    THEN
                        RAISE l_internal_error;
                    END IF;
                ELSE
                    pk_types.open_my_cursor(o_reasons);
                END IF;
            
            ELSE
                -- DON'T SHOW WARNING MESSAGE:
                -- Patient has records in the provided doc area.
                -- or
                -- Doc area not applicable to the current patient.
                l_show_warning_message := FALSE;
            END IF;
        
        ELSE
            -- DON'T SHOW WARNING MESSAGE:
            -- Documentation area not available for the current market/institution/software.
            l_show_warning_message := FALSE;
        END IF;
    
        IF NOT l_show_warning_message
        THEN
            -- Don't show warning message.
            g_error := 'ID_DOC_AREA NOT AVAILABLE';
            pk_alertlog.log_debug(g_error);
            o_flg_show := pk_alert_constant.g_no;
            pk_types.open_my_cursor(o_reasons);
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
            pk_types.open_my_cursor(o_reasons);
            RETURN FALSE;
    END check_assessment_warning;

    /********************************************************************************************
    *  Set the reason for NOT document the assessment
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info
    * @param i_id_episode              Episode ID
    * @param i_id_doc_area             Documentation Area ID
    * @param i_id_cancel_reason        Cancel reason ID
    * @param i_notes                   Notes
    * @param o_id_epis_documentation   New documentation ID
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          José Brito
    * @version                         2.5.0.7.8
    * @since                           03-12-2010
    **********************************************************************************************/
    FUNCTION set_scale_no_doc_reason
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_doc_area           IN doc_area.id_doc_area%TYPE,
        i_id_cancel_reason      IN cancel_reason.id_cancel_reason%TYPE,
        i_notes                 IN epis_documentation.notes%TYPE,
        o_id_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       CONSTANT VARCHAR2(200 CHAR) := 'SET_SCALE_NO_DOC_REASON';
        l_exchange_record CONSTANT VARCHAR2(1 CHAR) := 'X';
    
        l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
    
        l_rowids table_varchar;
    
        l_sysdate TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        l_sysdate := current_timestamp;
    
        g_error := 'GET NEW ID';
        pk_alertlog.log_debug(g_error);
        SELECT ts_epis_documentation.next_key
          INTO l_id_epis_documentation
          FROM dual;
    
        g_error := 'SET REASON FOR NOT DOCUMENT';
        pk_alertlog.log_debug(g_error);
        ts_epis_documentation.ins(id_epis_documentation_in       => l_id_epis_documentation,
                                  id_epis_complaint_in           => NULL,
                                  id_episode_in                  => i_id_episode,
                                  id_professional_in             => i_prof.id,
                                  id_prof_last_update_in         => i_prof.id,
                                  flg_status_in                  => 'A',
                                  id_doc_area_in                 => i_id_doc_area,
                                  id_prof_cancel_in              => NULL,
                                  notes_cancel_in                => '',
                                  id_doc_template_in             => NULL,
                                  notes_in                       => i_notes,
                                  id_epis_documentation_paren_in => NULL,
                                  dt_creation_tstz_in            => l_sysdate,
                                  dt_last_update_tstz_in         => l_sysdate,
                                  dt_cancel_tstz_in              => NULL,
                                  id_epis_context_in             => i_id_cancel_reason,
                                  id_episode_context_in          => i_id_episode,
                                  flg_edition_type_in            => l_exchange_record,
                                  rows_out                       => l_rowids);
    
        g_error := 'DATA GOVERNANCE PROCESSING';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_DOCUMENTATION', l_rowids, o_error);
    
        o_id_epis_documentation := l_id_epis_documentation;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_scale_no_doc_reason;

    /********************************************************************************************
    *  Get the scores of the elements associated to an doc_area
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional info    
    * @param i_id_doc_area             Documentation Area ID    
    * @param o_score                   New documentation ID
    * @param o_groups                  Groups info
    * @param o_id_scales               Scales identifier
    * @param o_error                   Error message
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           24-Mai-2011
    **********************************************************************************************/
    FUNCTION get_elements_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_doc_area        IN doc_area.id_doc_area%TYPE,
        i_id_doc_template IN doc_template.id_doc_template%TYPE,
        o_score           OUT pk_types.cursor_type,
        o_groups          OUT pk_types.cursor_type,
        o_id_scales       OUT scales.id_scales%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_SCORE. i_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_formulas.get_elements_score(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_doc_area        => i_doc_area,
                                                     i_id_doc_template => i_id_doc_template,
                                                     o_score           => o_score,
                                                     o_groups          => o_groups,
                                                     o_id_scales       => o_id_scales,
                                                     o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_score);
            pk_types.open_my_cursor(o_groups);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ELEMENTS_SCORE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_elements_score;

    /********************************************************************************************
    *  Get the score (total or partial) as well as the class description.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_episode               Episode Id
    * @param i_id_scales_group          Scales group Id
    * @param i_id_scales                Scales Id 
    * @param i_id_documentation         Documentation parent Id
    * @param i_doc_elements             Doc elements Ids
    * @param i_values                   Values inserted by the user for each doc_element
    * @param i_flg_score_type           'P' - partial score; T - total score.
    * @param i_nr_answered_questions    Nr of ansered questions or filled elements
    * @param o_main_scores              Main scores results
    * @param o_descs                    Scales decritions and complementary formulas results.
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_score
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_scales_group       IN scales_group.id_scales_group%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        i_id_documentation      IN documentation.id_documentation%TYPE,
        i_doc_elements          IN table_number,
        i_values                IN table_number,
        i_flg_score_type        IN VARCHAR2,
        i_nr_answered_questions IN PLS_INTEGER,
        o_main_scores           OUT pk_types.cursor_type,
        o_descs                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_scales_formulas.get_score';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_formulas.get_score(i_lang                  => i_lang,
                                            i_prof                  => i_prof,
                                            i_id_episode            => i_id_episode,
                                            i_id_scales_group       => i_id_scales_group,
                                            i_id_scales             => i_id_scales,
                                            i_id_documentation      => i_id_documentation,
                                            i_doc_elements          => i_doc_elements,
                                            i_values                => i_values,
                                            i_flg_score_type        => i_flg_score_type,
                                            i_nr_answered_questions => i_nr_answered_questions,
                                            o_main_scores           => o_main_scores,
                                            o_descs                 => o_descs,
                                            o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_main_scores);
            pk_types.open_my_cursor(o_descs);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_main_scores);
            pk_types.open_my_cursor(o_descs);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_ELEMENTS_SCORE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_score;

    /**
    * Sets documentation values associated with an area (doc_area) of a template (doc_template). 
    * Includes support for vital signs.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_prof_cat_type              Professional category
    * @param   i_epis                       Episode ID
    * @param   i_doc_area                   Documentation area ID
    * @param   i_doc_template               Touch-option template ID
    * @param   i_epis_documentation         Epis documentation ID
    * @param   i_flg_type                   Operation that was applied to save this entry
    * @param   i_id_documentation           Array with id documentation
    * @param   i_id_doc_element             Array with doc elements
    * @param   i_id_doc_element_crit        Array with doc elements crit
    * @param   i_value                      Array with values
    * @param   i_notes                      Free text documentation / Additional notes
    * @param   i_id_doc_element_qualif      Array with element quantifications/qualifications 
    * @param   i_epis_context               Context ID (Ex: id_interv_presc_det, id_exam...)
    * @param   i_summary_and_notes          Template's summary to be included in clinical notes
    * @param   i_episode_context            Context episode id  used in preoperative ORIS area by OUTP, INP, EDIS
    * @param   i_flg_table_origin           Table source when is a record edition. Default: D - EPIS_DOCUMENTATION
    * @param   i_vs_element_list            List of template's elements ID (id_doc_element) filled with vital signs
    * @param   i_vs_save_mode_list          List of flags to indicate the applicable mode to save each vital signs measurement
    * @param   i_vs_list                    List of vital signs ID (id_vital_sign)
    * @param   i_vs_value_list              List of vital signs values
    * @param   i_vs_uom_list                List of units of measurement (id_unit_measure)
    * @param   i_vs_scales_list             List of scales (id_vs_scales_element)
    * @param   i_vs_date_list               List of measurement date. Values are serialized as strings (YYYYMMDDhh24miss)
    * @param   i_vs_read_list               List of saved vital sign measurement (id_vital_sign_read)
    * @param   i_flags                      List of flags that identify the scope of the score: Scale, Documentation, Group
    * @param   i_ids                        List of ids: Scale, Documentation, Group
    * @param   i_scores                     List of calculated scores
    * @param   i_id_scales_formulas         Score calculation formulas Ids
    * @param   o_epis_documentation         The epis_documentation ID created
    * @param   o_id_epis_scales_score       The epis_scales_score ID created
    * @param   o_error                      Error message
    *
    * @value i_flg_type                    {*} 'N'  New {*} 'E' Edit/Correct {*} 'A' Agree(deprecated) {*} 'U' Update/Copy&Edit {*} 'O' No changes
    * @value i_flg_table_origin            {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBS
    * @value i_save_mode_list              {*} 'N' Creates a new measurement and associates it with element. {*} 'E' Edits the measurement and associates it with element. {*} 'R' Reviews the measurement and associates it with element. {*} 'A' Associates the measurement with the element but does not perform any operation in referred vital sign
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   08-Jul-2011
    */
    FUNCTION set_epis_doc_scales
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        i_flags                 IN table_varchar,
        i_ids                   IN table_number,
        i_scores                IN table_varchar,
        i_id_scales_formulas    IN table_number,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_touch_option.set_epis_documentation';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.set_epis_doc_scales(i_lang                  => i_lang,
                                                  i_prof                  => i_prof,
                                                  i_prof_cat_type         => i_prof_cat_type,
                                                  i_epis                  => i_epis,
                                                  i_doc_area              => i_doc_area,
                                                  i_doc_template          => i_doc_template,
                                                  i_epis_documentation    => i_epis_documentation,
                                                  i_flg_type              => i_flg_type,
                                                  i_id_documentation      => i_id_documentation,
                                                  i_id_doc_element        => i_id_doc_element,
                                                  i_id_doc_element_crit   => i_id_doc_element_crit,
                                                  i_value                 => i_value,
                                                  i_notes                 => i_notes,
                                                  i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                  i_epis_context          => i_epis_context,
                                                  i_summary_and_notes     => i_summary_and_notes,
                                                  i_episode_context       => i_episode_context,
                                                  i_flg_table_origin      => i_flg_table_origin,
                                                  i_vs_element_list       => i_vs_element_list,
                                                  i_vs_save_mode_list     => i_vs_save_mode_list,
                                                  i_vs_list               => i_vs_list,
                                                  i_vs_value_list         => i_vs_value_list,
                                                  i_vs_uom_list           => i_vs_uom_list,
                                                  i_vs_scales_list        => i_vs_scales_list,
                                                  i_vs_date_list          => i_vs_date_list,
                                                  i_vs_read_list          => i_vs_read_list,
                                                  i_flags                 => i_flags,
                                                  i_ids                   => i_ids,
                                                  i_scores                => i_scores,
                                                  i_id_scales_formulas    => i_id_scales_formulas,
                                                  i_dt_clinical           => i_dt_clinical,
                                                  o_epis_documentation    => o_epis_documentation,
                                                  o_id_epis_scales_score  => o_id_epis_scales_score,
                                                  o_error                 => o_error)
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'SET_EPIS_DOC_SCALES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_doc_scales;
    FUNCTION set_epis_doc_scales
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_documentation.notes%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE DEFAULT NULL,
        i_flg_table_origin      IN VARCHAR2 DEFAULT 'D',
        i_vs_element_list       IN table_number,
        i_vs_save_mode_list     IN table_varchar,
        i_vs_list               IN table_number,
        i_vs_value_list         IN table_number,
        i_vs_uom_list           IN table_number,
        i_vs_scales_list        IN table_number,
        i_vs_date_list          IN table_varchar,
        i_vs_read_list          IN table_number,
        i_flags                 IN table_varchar,
        i_ids                   IN table_number,
        i_scores                IN table_varchar,
        i_id_scales_formulas    IN table_number,
        i_id_edit_reason        IN table_number,
        i_notes_edit            IN table_clob,
        i_dt_clinical           IN VARCHAR2 DEFAULT NULL,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_id_epis_scales_score  OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_touch_option.set_epis_documentation';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.set_epis_doc_scales(i_lang                  => i_lang,
                                                  i_prof                  => i_prof,
                                                  i_prof_cat_type         => i_prof_cat_type,
                                                  i_epis                  => i_epis,
                                                  i_doc_area              => i_doc_area,
                                                  i_doc_template          => i_doc_template,
                                                  i_epis_documentation    => i_epis_documentation,
                                                  i_flg_type              => i_flg_type,
                                                  i_id_documentation      => i_id_documentation,
                                                  i_id_doc_element        => i_id_doc_element,
                                                  i_id_doc_element_crit   => i_id_doc_element_crit,
                                                  i_value                 => i_value,
                                                  i_notes                 => i_notes,
                                                  i_id_doc_element_qualif => i_id_doc_element_qualif,
                                                  i_epis_context          => i_epis_context,
                                                  i_summary_and_notes     => i_summary_and_notes,
                                                  i_episode_context       => i_episode_context,
                                                  i_flg_table_origin      => i_flg_table_origin,
                                                  i_vs_element_list       => i_vs_element_list,
                                                  i_vs_save_mode_list     => i_vs_save_mode_list,
                                                  i_vs_list               => i_vs_list,
                                                  i_vs_value_list         => i_vs_value_list,
                                                  i_vs_uom_list           => i_vs_uom_list,
                                                  i_vs_scales_list        => i_vs_scales_list,
                                                  i_vs_date_list          => i_vs_date_list,
                                                  i_vs_read_list          => i_vs_read_list,
                                                  i_flags                 => i_flags,
                                                  i_ids                   => i_ids,
                                                  i_scores                => i_scores,
                                                  i_id_scales_formulas    => i_id_scales_formulas,
                                                  i_id_edit_reason        => i_id_edit_reason,
                                                  i_notes_edit            => i_notes_edit,
                                                  i_dt_clinical           => i_dt_clinical,
                                                  o_epis_documentation    => o_epis_documentation,
                                                  o_id_epis_scales_score  => o_id_epis_scales_score,
                                                  o_error                 => o_error)
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'SET_EPIS_DOC_SCALES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_epis_doc_scales;
    /********************************************************************************************
    *  Get the documentation actual info and the respective scores.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_id_epis_documentation    Epis documentation Id        
    * @param i_id_scales                Scales Id    
    * @param o_groups                   Groups info: indicated the id_documentations that belongs o each group
    * @param o_scores                   Scores info
    * @param o_epis_doc_register        array with the detail info register
    * @param o_epis_document_val        array with detail of documentation
    * @param o_template_layouts         Cursor containing the layout for each template used
    * @param o_doc_area_component       Cursor containing the components for each template used 
    * @param o_record_count             Indicates the number of records that match filters criteria
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.1.1
    * @since                           25-Mai-2011
    **********************************************************************************************/
    FUNCTION get_scores_detail
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_scales             IN scales.id_scales%TYPE,
        o_groups                OUT pk_types.cursor_type,
        o_scores                OUT pk_types.cursor_type,
        o_doc_area_register     OUT pk_types.cursor_type,
        o_epis_document_val     OUT pk_types.cursor_type,
        o_template_layouts      OUT pk_types.cursor_type,
        o_doc_area_component    OUT pk_types.cursor_type,
        o_record_count          OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_scales scales.id_scales%TYPE := i_id_scales;
    BEGIN
    
        IF (i_id_scales IS NULL)
        THEN
            BEGIN
                SELECT DISTINCT sdv.id_scales
                  INTO l_id_scales
                  FROM scales_doc_value sdv
                 INNER JOIN doc_element de
                    ON de.id_doc_element = sdv.id_doc_element
                 INNER JOIN documentation doc
                    ON doc.id_documentation = de.id_documentation
                 INNER JOIN doc_template_area_doc dtad
                    ON dtad.id_documentation = doc.id_documentation
                 INNER JOIN epis_documentation ed
                    ON ed.id_doc_area = dtad.id_doc_area
                   AND ed.id_doc_template = dtad.id_doc_template
                 WHERE ed.id_epis_documentation = i_id_epis_documentation
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_scales := NULL;
            END;
        END IF;
    
        g_error := 'CALL pk_scales_core.get_scores_detail';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.get_scores_detail(i_lang                  => i_lang,
                                                i_prof                  => i_prof,
                                                i_id_epis_documentation => i_id_epis_documentation,
                                                i_id_scales             => l_id_scales,
                                                o_groups                => o_groups,
                                                o_scores                => o_scores,
                                                o_doc_area_register     => o_doc_area_register,
                                                o_epis_document_val     => o_epis_document_val,
                                                o_template_layouts      => o_template_layouts,
                                                o_doc_area_component    => o_doc_area_component,
                                                o_record_count          => o_record_count,
                                                o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_epis_document_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_groups);
            pk_types.open_my_cursor(o_scores);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_doc_area_register);
            pk_types.open_my_cursor(o_epis_document_val);
            pk_types.open_my_cursor(o_template_layouts);
            pk_types.open_my_cursor(o_doc_area_component);
            pk_types.open_my_cursor(o_groups);
            pk_types.open_my_cursor(o_scores);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              g_package_name,
                                              'GET_SCORES_DETAIL',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_scores_detail;

    /**********************************************************************************************
    * Get the documentation info and respective scores in single page detail
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_episode            id episode
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.5
    * @since                         30/08/2016 
    ***********************************************************************************************/
    FUNCTION get_scores_detail_pn
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(20 CHAR) := 'GET_SCORES_DETAIL_PN';
    
        l_id_patient patient.id_patient%TYPE;
    
        l_doc_areas table_number := table_number();
    
        l_cur_section  pk_summary_page.t_cur_section;
        l_coll_section pk_summary_page.t_coll_section;
    
        l_value CLOB;
    
        e_summary_page EXCEPTION;
    
        l_documented sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_code_mess => 'EDIS_CHIEF_COMPLAINT_T008');
        l_updated    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_code_mess => 'EDIS_CHIEF_COMPLAINT_T009');
        l_total_msg  sys_message.code_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_code_mess => pk_scales_constant.g_total_msg);
        l_doc_notes  sys_message.code_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_code_mess => 'DOCUMENTATION_T010');
        l_cancel_reason sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M072');
        l_cancel_notes  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M073');
    
        CURSOR c_template_info(l_doc_areas table_number) IS
            SELECT pk_translation.get_translation(i_lang, dt.code_doc_template) template_desc,
                   ed.id_epis_documentation,
                   ed.id_epis_documentation_parent,
                   ed.id_doc_area,
                   ess.score_value,
                   ed.flg_status,
                   ed.notes,
                   pk_sysdomain.get_domain(i_code_dom => pk_touch_option.g_domain_epis_doc_flg_status,
                                           i_val      => ed.flg_status,
                                           i_lang     => i_lang) status_desc,
                   ed.dt_creation_tstz dt_create,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(ed.flg_status,
                                                      pk_touch_option.g_canceled,
                                                      ed.dt_cancel_tstz,
                                                      ed.dt_last_update_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_register,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    decode(ed.flg_status,
                                                           pk_touch_option.g_canceled,
                                                           ed.id_prof_cancel,
                                                           ed.id_professional)) nick_name,
                   COUNT(1) over() total_rows,
                   ed.id_cancel_reason,
                   ed.notes_cancel cancel_notes
              FROM epis_documentation ed
              LEFT JOIN epis_scales_score ess
                ON ess.id_epis_documentation = ed.id_epis_documentation
              LEFT JOIN doc_template dt
                ON ed.id_doc_template = dt.id_doc_template
             WHERE ed.id_episode = i_id_episode
               AND ed.id_doc_area IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                       t.column_value
                                        FROM TABLE(l_doc_areas) t)
               AND ed.flg_status <> pk_alert_constant.g_inactive
             ORDER BY dt_creation_tstz DESC;
    
        CURSOR c_template_val(l_id_epis_doc epis_documentation.id_epis_documentation%TYPE) IS
            SELECT TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   pk_touch_option.get_element_description(i_lang,
                                                           i_prof,
                                                           de.flg_type,
                                                           edd.value,
                                                           edd.value_properties,
                                                           decr.id_doc_element_crit,
                                                           de.id_unit_measure_reference,
                                                           de.id_master_item,
                                                           decr.code_element_close) desc_element
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN documentation d
                ON d.id_documentation = edd.id_documentation
             INNER JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
             WHERE ed.id_epis_documentation = l_id_epis_doc;
    
    BEGIN
    
        g_error := 'CALL PK_EPISODE.GET_ID_PATIENT: I_ID_EPISODE: ' || i_id_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
    
        g_error := 'CALL PK_SUMMARY_PAGE.GET_SUMMARY_PAGE_SECTIONS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => 34,
                                                         i_pat             => l_id_patient,
                                                         o_sections        => l_cur_section,
                                                         o_error           => o_error)
        THEN
            RAISE e_summary_page;
        END IF;
    
        g_error := 'fetch o_sections cursor';
        FETCH l_cur_section BULK COLLECT
            INTO l_coll_section;
    
        g_error := 'save all doc_areas into variable';
        FOR i IN l_coll_section.first .. l_coll_section.last
        LOOP
            l_doc_areas.extend();
            l_doc_areas(l_doc_areas.count) := l_coll_section(i).id_doc_area;
        END LOOP;
    
        g_error := 'Initialize history table';
        pk_edis_hist.init_vars;
    
        FOR r_template_info IN c_template_info(l_doc_areas)
        LOOP
            IF r_template_info.flg_status <> pk_touch_option.g_epis_bartchart_out
            THEN
                g_error := 'Create a new line in history table with current history record';
                pk_edis_hist.add_line(i_history        => r_template_info.id_epis_documentation,
                                      i_dt_hist        => r_template_info.dt_create,
                                      i_record_state   => r_template_info.flg_status,
                                      i_desc_rec_state => r_template_info.status_desc);
            
                g_error := 'Add title';
                pk_edis_hist.add_value(i_label => r_template_info.template_desc,
                                       i_value => CASE
                                                      WHEN r_template_info.flg_status = pk_alert_constant.g_cancelled THEN
                                                       ' (' || r_template_info.status_desc || ')'
                                                      ELSE
                                                       ' '
                                                  END,
                                       i_type  => pk_edis_hist.g_type_title);
                IF (r_template_info.flg_status = pk_alert_constant.g_cancelled)
                THEN
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_cancel_reason,
                                                       i_value => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                                          i_prof             => i_prof,
                                                                                                          i_id_cancel_reason => r_template_info.id_cancel_reason),
                                                       i_type  => pk_edis_hist.g_type_content);
                
                    g_error := 'call pk_edis_hist.add_value_if_not_null';
                    pk_edis_hist.add_value_if_not_null(i_label => l_cancel_notes,
                                                       i_value => r_template_info.cancel_notes,
                                                       i_type  => pk_edis_hist.g_type_content);
                END IF;
            
                pk_edis_hist.add_value_if_not_null(i_label => l_total_msg || ': ',
                                                   i_value => to_clob(r_template_info.score_value),
                                                   i_type  => pk_edis_hist.g_type_title);
            
                g_error := 'Add content';
                FOR r_template_val IN c_template_val(r_template_info.id_epis_documentation)
                LOOP
                    pk_edis_hist.add_value_if_not_null(i_label => r_template_val.desc_doc_component,
                                                       i_value => r_template_val.desc_element,
                                                       i_type  => pk_edis_hist.g_type_content);
                END LOOP;
            
                g_error := 'ADD EMPTY LINE';
                pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
            
                g_error := 'ADITIONAL_NOTES';
                pk_edis_hist.add_value_if_not_null(i_label => l_doc_notes,
                                                   i_value => r_template_info.notes,
                                                   i_type  => pk_edis_hist.g_type_content);
            
                g_error := 'Add signature';
                pk_edis_hist.add_value(i_label => CASE
                                                      WHEN r_template_info.id_epis_documentation_parent IS NOT NULL
                                                           OR r_template_info.flg_status = pk_alert_constant.g_cancelled THEN
                                                       l_updated
                                                      ELSE
                                                       l_documented
                                                  END,
                                       i_value => r_template_info.nick_name || '; ' || r_template_info.dt_register,
                                       i_type  => pk_edis_hist.g_type_signature);
            
                IF c_template_info%ROWCOUNT <> r_template_info.total_rows
                THEN
                    g_error := 'Add white line';
                    pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_empty_line);
                    pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_white_line);
                END IF;
            
            END IF;
        END LOOP;
    
        -- The output must be in this format
        OPEN o_history FOR
            SELECT t.id_history,
                   t.tbl_labels,
                   t.tbl_values,
                   t.tbl_types,
                   t.tbl_info_labels,
                   t.tbl_info_values,
                   t.tbl_codes,
                   t.dt_history,
                   (SELECT COUNT(*)
                      FROM TABLE(t.tbl_types)) count_elems
              FROM TABLE(pk_edis_hist.tf_hist) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_history);
            RETURN FALSE;
    END get_scores_detail_pn;

    /***********************************************************************************************
    * Get the documentation info and respective scores for history of changes in single page detail
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_episode            id episode
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Vanessa Barsottelli
    * @version                       2.6.5
    * @since                         30/08/2016 
    ***********************************************************************************************/
    FUNCTION get_scores_detail_pn_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_history    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(25 CHAR) := 'GET_SCORES_DETAIL_PN_HIST';
    
        l_id_patient patient.id_patient%TYPE;
    
        e_summary_page EXCEPTION;
    
        l_doc_tree  table_number;
        l_doc_areas table_number := table_number();
    
        l_cur_section  pk_summary_page.t_cur_section;
        l_coll_section pk_summary_page.t_coll_section;
    
        l_creation     sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T030');
        l_edition      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T029');
        l_cancellation sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T032');
        l_new_record   sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'COMMON_T031');
        l_documented   sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'EDIS_CHIEF_COMPLAINT_T008');
        l_total_msg    sys_message.code_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => pk_scales_constant.g_total_msg);
        l_doc_notes    sys_message.code_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_prof      => i_prof,
                                                                               i_code_mess => 'DOCUMENTATION_T010');
        l_cancel_reason sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M072');
        l_cancel_notes  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_prof      => i_prof,
                                                                                i_code_mess => 'COMMON_M073');
    
        --Get only the parents IDS
        CURSOR c_template_ids(l_doc_areas table_number) IS
            SELECT ed.id_epis_documentation, ed.flg_edition_type, COUNT(1) over() total_rows
              FROM epis_documentation ed
             WHERE ed.id_episode = i_id_episode
               AND ed.id_doc_area IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                       t.column_value
                                        FROM TABLE(l_doc_areas) t)
               AND ed.flg_status <> pk_alert_constant.g_inactive
             ORDER BY nvl(ed.dt_last_update_tstz, ed.dt_creation_tstz) DESC;
    
        --Get the parent info
        CURSOR c_template_info(l_id_documentation table_number) IS
            WITH doc AS
             (SELECT dt.code_doc_template,
                     ed.id_epis_documentation,
                     ed.id_epis_documentation_parent,
                     ess.score_value,
                     ed.flg_edition_type,
                     ed.flg_status,
                     ed.dt_creation_tstz,
                     ed.dt_last_update_tstz,
                     ed.dt_cancel_tstz,
                     ed.id_professional,
                     ed.id_episode,
                     ed.notes,
                     ed.id_cancel_reason,
                     ed.notes_cancel cancel_notes
                FROM epis_documentation ed
               INNER JOIN doc_template dt
                  ON ed.id_doc_template = dt.id_doc_template
                LEFT JOIN epis_scales_score ess
                  ON ess.id_epis_documentation = ed.id_epis_documentation
               WHERE ed.id_epis_documentation IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                   t.column_value
                                                    FROM TABLE(l_id_documentation) t))
            SELECT pk_translation.get_translation(i_lang, t.code_doc_template) template_desc,
                   t.id_epis_documentation,
                   t.score_value,
                   t.flg_edition_type,
                   t.flg_status,
                   pk_sysdomain.get_domain(i_code_dom => pk_touch_option.g_domain_epis_doc_flg_status,
                                           i_val      => t.flg_status,
                                           i_lang     => i_lang) status_desc,
                   t.dt_creation_tstz dt_create,
                   pk_date_utils.date_char_tsz(i_lang, t.dt_last_update_tstz, i_prof.institution, i_prof.software) dt_register,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_professional) nick_name,
                   t.notes,
                   t.id_cancel_reason,
                   t.cancel_notes
              FROM (SELECT doc.code_doc_template,
                           doc.id_epis_documentation,
                           doc.score_value,
                           doc.flg_edition_type,
                           doc.flg_status,
                           doc.dt_creation_tstz,
                           decode(doc.flg_status,
                                  pk_touch_option.g_canceled,
                                  doc.dt_cancel_tstz,
                                  doc.dt_last_update_tstz) dt_last_update_tstz,
                           doc.id_professional,
                           doc.id_episode,
                           doc.notes,
                           doc.id_cancel_reason,
                           doc.cancel_notes
                      FROM doc
                    UNION ALL
                    SELECT doc.code_doc_template,
                           doc.id_epis_documentation_parent id_epis_documentation,
                           doc.score_value,
                           pk_touch_option.g_flg_edition_type_edit flg_edition_type,
                           pk_touch_option.g_epis_bartchart_out flg_status,
                           doc.dt_creation_tstz,
                           doc.dt_last_update_tstz - INTERVAL '1' SECOND dt_last_update_tstz,
                           doc.id_professional,
                           doc.id_episode,
                           doc.notes,
                           doc.id_cancel_reason,
                           doc.cancel_notes
                      FROM doc
                     WHERE doc.id_epis_documentation_parent IS NOT NULL
                       AND doc.flg_status = pk_touch_option.g_canceled) t
             ORDER BY nvl(t.dt_last_update_tstz, t.dt_creation_tstz) DESC;
    
        --Get the child values
        CURSOR c_template_val(l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE) IS
            SELECT TRIM(pk_translation.get_translation(i_lang, dc.code_doc_component)) desc_doc_component,
                   pk_touch_option.get_element_description(i_lang,
                                                           i_prof,
                                                           de.flg_type,
                                                           edd.value,
                                                           edd.value_properties,
                                                           decr.id_doc_element_crit,
                                                           de.id_unit_measure_reference,
                                                           de.id_master_item,
                                                           decr.code_element_close) desc_element
              FROM epis_documentation ed
             INNER JOIN epis_documentation_det edd
                ON ed.id_epis_documentation = edd.id_epis_documentation
             INNER JOIN documentation d
                ON d.id_documentation = edd.id_documentation
             INNER JOIN doc_component dc
                ON dc.id_doc_component = d.id_doc_component
             INNER JOIN doc_element_crit decr
                ON decr.id_doc_element_crit = edd.id_doc_element_crit
             INNER JOIN doc_element de
                ON de.id_doc_element = decr.id_doc_element
             WHERE ed.id_epis_documentation = l_id_epis_documentation;
    BEGIN
    
        g_error := 'CALL PK_EPISODE.GET_ID_PATIENT: I_ID_EPISODE: ' || i_id_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
    
        g_error := 'CALL PK_SUMMARY_PAGE.GET_SUMMARY_PAGE_SECTIONS';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => 34,
                                                         i_pat             => l_id_patient,
                                                         o_sections        => l_cur_section,
                                                         o_error           => o_error)
        THEN
            RAISE e_summary_page;
        END IF;
    
        g_error := 'FETCH O_SECTIONS CURSOR';
        FETCH l_cur_section BULK COLLECT
            INTO l_coll_section;
    
        g_error := 'SAVE ALL DOC_AREAS INTO VARIABLE';
        FOR i IN l_coll_section.first .. l_coll_section.last
        LOOP
            l_doc_areas.extend();
            l_doc_areas(l_doc_areas.count) := l_coll_section(i).id_doc_area;
        END LOOP;
    
        g_error := 'INITIALIZE HISTORY TABLE';
        pk_edis_hist.init_vars;
    
        FOR r_template_ids IN c_template_ids(l_doc_areas)
        LOOP
            IF r_template_ids.flg_edition_type IN
               (pk_touch_option.g_flg_edition_type_new, pk_touch_option.g_flg_edition_type_update)
            THEN
                --Get epis_documentation hierarchy
                l_doc_tree := table_number();
                BEGIN
                    SELECT aux.tb_ids
                      INTO l_doc_tree
                      FROM (SELECT pk_utils.str_split_n(substr(sys_connect_by_path(ed.id_epis_documentation, ','), 2),
                                                        ',') tb_ids,
                                   connect_by_isleaf isleaf
                              FROM epis_documentation ed
                             WHERE ed.id_episode = i_id_episode
                            CONNECT BY ed.id_epis_documentation_parent = PRIOR ed.id_epis_documentation
                                   AND ed.flg_edition_type <> pk_touch_option.g_flg_edition_type_update
                             START WITH ed.id_epis_documentation = r_template_ids.id_epis_documentation) aux
                     WHERE aux.isleaf = 1
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_doc_tree := table_number();
                END;
            
                --Loop through parent info
                FOR r_template_info IN c_template_info(l_doc_tree)
                LOOP
                    IF r_template_ids.id_epis_documentation = r_template_ids.id_epis_documentation
                    THEN
                        g_error := 'CREATE A NEW LINE IN HISTORY TABLE WITH CURRENT HISTORY RECORD';
                        pk_edis_hist.add_line(i_history        => r_template_info.id_epis_documentation,
                                              i_dt_hist        => r_template_info.dt_create,
                                              i_record_state   => r_template_info.flg_status,
                                              i_desc_rec_state => r_template_info.status_desc);
                    
                        g_error := 'ADD TITLE';
                        pk_edis_hist.add_value(i_label => r_template_info.template_desc,
                                               i_value => CASE
                                                              WHEN r_template_info.flg_status = pk_alert_constant.g_cancelled THEN
                                                               ' (' || l_cancellation || ')'
                                                              WHEN r_template_info.flg_edition_type IN
                                                                   (pk_touch_option.g_flg_edition_type_new,
                                                                    pk_touch_option.g_flg_edition_type_update) THEN
                                                               ' (' || l_creation || ')'
                                                              ELSE
                                                               ' (' || l_edition || ')'
                                                          END,
                                               i_type  => pk_edis_hist.g_type_title);
                        IF (r_template_info.flg_status = pk_alert_constant.g_cancelled)
                        THEN
                            g_error := 'call pk_edis_hist.add_value_if_not_null';
                            pk_edis_hist.add_value_if_not_null(i_label => l_cancel_reason,
                                                               i_value => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                                                  i_prof             => i_prof,
                                                                                                                  i_id_cancel_reason => r_template_info.id_cancel_reason),
                                                               i_type  => pk_edis_hist.g_type_content);
                        
                            g_error := 'call pk_edis_hist.add_value_if_not_null';
                            pk_edis_hist.add_value_if_not_null(i_label => l_cancel_notes,
                                                               i_value => r_template_info.cancel_notes,
                                                               i_type  => pk_edis_hist.g_type_content);
                        END IF;
                    
                        pk_edis_hist.add_value_if_not_null(i_label => l_total_msg || ': ',
                                                           i_value => to_clob(r_template_info.score_value),
                                                           i_type  => pk_edis_hist.g_type_title);
                    
                        g_error := 'ADD CONTENT';
                        FOR r_template_val IN c_template_val(r_template_info.id_epis_documentation)
                        LOOP
                            pk_edis_hist.add_value_if_not_null(i_label => r_template_val.desc_doc_component,
                                                               i_value => r_template_val.desc_element,
                                                               i_type  => pk_edis_hist.g_type_content);
                        END LOOP;
                    
                        g_error := 'ADD EMPTY LINE';
                        pk_edis_hist.add_value(i_label => NULL,
                                               i_value => NULL,
                                               i_type  => pk_edis_hist.g_type_empty_line);
                    
                        g_error := 'ADITIONAL_NOTES';
                        pk_edis_hist.add_value_if_not_null(i_label => l_doc_notes,
                                                           i_value => r_template_info.notes,
                                                           i_type  => pk_edis_hist.g_type_content);
                    
                        g_error := 'ADD SIGNATURE';
                        pk_edis_hist.add_value(i_label => l_documented,
                                               i_value => r_template_info.nick_name || '; ' ||
                                                          r_template_info.dt_register,
                                               i_type  => pk_edis_hist.g_type_signature);
                    
                        g_error := 'ADD EMPTY LINE';
                        pk_edis_hist.add_value(i_label => NULL,
                                               i_value => NULL,
                                               i_type  => pk_edis_hist.g_type_empty_line);
                    
                        IF r_template_info.flg_edition_type NOT IN
                           (pk_touch_option.g_flg_edition_type_new, pk_touch_option.g_flg_edition_type_update)
                        THEN
                            g_error := 'ADD SLASH LINE';
                            pk_edis_hist.add_value(i_label => NULL,
                                                   i_value => NULL,
                                                   i_type  => pk_edis_hist.g_type_slash_line);
                        END IF;
                    END IF;
                END LOOP;
            
                IF c_template_ids%ROWCOUNT <> r_template_ids.total_rows
                THEN
                    g_error := 'ADD WHITE LINE';
                    pk_edis_hist.add_value(i_label => NULL, i_value => NULL, i_type => pk_edis_hist.g_type_white_line);
                END IF;
            END IF;
        END LOOP;
    
        -- The output must be in this format
        OPEN o_history FOR
            SELECT t.id_history,
                   t.tbl_labels,
                   t.tbl_values,
                   t.tbl_types,
                   t.tbl_info_labels,
                   t.tbl_info_values,
                   t.tbl_codes,
                   t.dt_history,
                   (SELECT COUNT(*)
                      FROM TABLE(t.tbl_types)) count_elems
              FROM TABLE(pk_edis_hist.tf_hist) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_history);
            RETURN FALSE;
    END get_scores_detail_pn_hist;

--
-- ********************************************************************************
-- ************************************ CONSTRUCTOR *******************************
-- ********************************************************************************
BEGIN

    g_software_intern_name := 'INP';
    g_pos_status_domain    := 'INP_POSITIONING_STATUS';

    g_epis_stat_inactive := 'I';

    g_episode_flg_status_active   := 'A';
    g_episode_flg_status_temp     := 'T';
    g_episode_flg_status_canceled := 'C';
    g_episode_flg_status_inactive := 'I';

    g_hours_in_a_day      := 24;
    g_minutes_in_a_hour   := 60;
    g_seconds_in_a_minute := 60;

    g_seconds_in_a_day := g_hours_in_a_day * g_minutes_in_a_hour * g_seconds_in_a_minute;

    g_flg_pos_executed  := 'E';
    g_active            := 'A';
    g_flg_pos_requested := 'R';
    g_flg_pos_canceled  := 'C';
    g_separador         := chr(10) || '-------------------------------------------------------------' || chr(10);

    g_available := 'Y';

    g_text           := 'T';
        g_numeric := 'N';
    g_no_color       := 'X';
    g_patient_active := 'A';
    g_outdated       := 'O';
    g_canceled       := 'C';

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END;
/
