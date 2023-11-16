/*-- Last Change Revision: $Rev: 1857411 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2018-07-27 09:57:01 +0100 (sex, 27 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_nan_cfg IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    FUNCTION tf_inst_diagnosis
    (
        i_inst  IN institution.id_institution%TYPE,
        i_soft  IN software.id_software%TYPE DEFAULT NULL,
        i_limit IN PLS_INTEGER DEFAULT pk_nan_cfg.k_default_bulk_limit
    ) RETURN t_nan_cfg_diagnosis_coll
        PIPELINED IS
        l_nan_term_version       nan_diagnosis.id_terminology_version%TYPE;
        l_language               terminology_version.id_language%TYPE;
        l_cursor                 t_nan_cfg_diagnosis_cur;
        l_nan_cfg_diagnosis_coll t_nan_cfg_diagnosis_coll;
    BEGIN
        -- Retrieves the terminology version of NANDA-I Classification configured for the institution
        BEGIN
            l_nan_term_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nanda,
                                                                        i_inst             => i_inst,
                                                                        i_soft             => i_soft);
        EXCEPTION
            WHEN pk_nnn_core.e_missing_cfg_term_version THEN
                --This institution has no configurations to use NANDA Classification
                RETURN;
        END;
        l_language := pk_nnn_core.get_terminology_language(i_terminology_version => l_nan_term_version);
    
        -- NANDA Diagnoses: show all diagnoses without custom settings + diagnoses with settings defined by a given institution
        -- This approach allows us to display all classification content with default settings with no need the institution first having to manually define it.
    
        OPEN l_cursor FOR
            SELECT NULL                       id_nan_cfg_diagnosis,
                   pk_alert_constant.g_active flg_status,
                   NULL                       dt_last_update,
                   nd.id_nan_diagnosis,
                   nd.id_terminology_version,
                   nd.diagnosis_code,
                   nd.code_name,
                   nd.code_definition,
                   nd.year_approved,
                   nd.year_revised,
                   nd.loe,
                   nd.references,
                   nd.id_nan_class,
                   l_language                 id_language
              FROM nan_diagnosis nd
             WHERE nd.id_terminology_version = l_nan_term_version
               AND NOT EXISTS (SELECT 1
                      FROM nan_cfg_diagnosis ndcfg
                     WHERE ndcfg.id_nan_diagnosis = nd.id_nan_diagnosis
                       AND ndcfg.id_institution = i_inst)
            UNION ALL
            SELECT ndcfg.id_nan_cfg_diagnosis,
                   ndcfg.flg_status,
                   ndcfg.dt_last_update,
                   nd.id_nan_diagnosis,
                   nd.id_terminology_version,
                   nd.diagnosis_code,
                   nd.code_name,
                   nd.code_definition,
                   nd.year_approved,
                   nd.year_revised,
                   nd.loe,
                   nd.references,
                   nd.id_nan_class,
                   l_language id_language
              FROM nan_diagnosis nd
             INNER JOIN nan_cfg_diagnosis ndcfg
                ON nd.id_nan_diagnosis = ndcfg.id_nan_diagnosis
             WHERE nd.id_terminology_version = l_nan_term_version
               AND ndcfg.id_institution = i_inst;
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_nan_cfg_diagnosis_coll LIMIT i_limit;
            EXIT WHEN l_nan_cfg_diagnosis_coll.count = 0;
        
            FOR i IN 1 .. l_nan_cfg_diagnosis_coll.count
            LOOP
                PIPE ROW(l_nan_cfg_diagnosis_coll(i));
            END LOOP;
        
        END LOOP;
        CLOSE l_cursor;
    
        RETURN;
    EXCEPTION
        WHEN no_data_needed THEN
            -- Perform cleanup operations
            IF l_cursor%ISOPEN
            THEN
                CLOSE l_cursor;
            END IF;
            RETURN;
    END tf_inst_diagnosis;

    PROCEDURE get_nan_domains
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        o_data OUT pk_nan_model.t_nan_domain_cur
    ) IS
        l_lang                language.id_language%TYPE;
        l_terminology_version nan_domain.id_terminology_version%TYPE;
    BEGIN
        l_terminology_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nanda,
                                                                       i_inst             => i_prof.institution,
                                                                       i_soft             => i_prof.software);
    
        l_lang := pk_nnn_core.get_terminology_language(i_terminology_version => l_terminology_version);
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        OPEN o_data FOR
            SELECT nd.id_nan_domain,
                   nd.domain_code,
                   pk_translation.get_translation(l_lang, nd.code_name) domain_name,
                   pk_translation.get_translation(l_lang, nd.code_definition) domain_definition
              FROM nan_domain nd
             WHERE nd.id_terminology_version = l_terminology_version
                  -- Has active NANDA diagnoses
               AND EXISTS
             (SELECT 1
                      FROM TABLE(pk_nan_cfg.tf_inst_diagnosis(i_inst => i_prof.institution, i_soft => i_prof.software)) ndx
                     INNER JOIN nan_class nc
                        ON ndx.id_nan_class = nc.id_nan_class
                     WHERE nc.id_nan_domain = nd.id_nan_domain)
             ORDER BY nd.rank, domain_name;
    END get_nan_domains;

    PROCEDURE get_nan_classes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_nan_domain IN nan_class.id_nan_domain%TYPE,
        o_data       OUT pk_nan_model.t_nan_class_cur
    ) IS
        l_lang                language.id_language%TYPE;
        l_terminology_version nan_class.id_terminology_version%TYPE;
    BEGIN
        l_terminology_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nanda,
                                                                       i_inst             => i_prof.institution,
                                                                       i_soft             => i_prof.software);
    
        l_lang := pk_nnn_core.get_terminology_language(i_terminology_version => l_terminology_version);
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
        OPEN o_data FOR
            SELECT nc.id_nan_class,
                   nc.class_code,
                   pk_translation.get_translation(l_lang, nc.code_name) class_name,
                   pk_translation.get_translation(l_lang, nc.code_definition) class_definition,
                   nc.id_nan_domain
              FROM nan_class nc
             INNER JOIN nan_domain nd
                ON nc.id_nan_domain = nd.id_nan_domain
             WHERE nd.id_terminology_version = l_terminology_version
               AND nd.id_nan_domain = i_nan_domain
                  -- Has active NANDA diagnoses
               AND EXISTS
             (SELECT 1
                      FROM TABLE(pk_nan_cfg.tf_inst_diagnosis(i_inst => i_prof.institution, i_soft => i_prof.software)) ndx
                     WHERE ndx.id_nan_class = nc.id_nan_class)
             ORDER BY nc.rank, class_name;
    END get_nan_classes;

    PROCEDURE get_nan_diagnoses
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nan_class        IN nan_class.id_nan_class%TYPE DEFAULT NULL,
        i_include_inactive IN nan_cfg_diagnosis.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_diagnosis        OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_nan_diagnoses';
        l_startindex     NUMBER(24);
        l_items_per_page NUMBER(24);
        l_total_items    NUMBER(24);
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_paging = ' || coalesce(i_paging, '<null>');
        g_error := g_error || ' i_startindex = ' || coalesce(to_char(i_startindex), '<null>');
        g_error := g_error || ' i_items_per_page = ' || coalesce(to_char(i_items_per_page), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT count(*)
          INTO l_total_items
          FROM TABLE(tf_inst_diagnosis(i_inst => i_prof.institution, i_soft => i_prof.software)) x
         WHERE x.id_nan_class = nvl(i_nan_class, x.id_nan_class)
           AND (x.flg_status = pk_alert_constant.g_active OR
               (x.flg_status = pk_alert_constant.g_inactive AND i_include_inactive = pk_alert_constant.g_yes));
    
        o_total_items := l_total_items;
    
        IF i_paging = pk_alert_constant.g_no
        THEN
            -- Returns all the resultset
            l_startindex     := 1;
            l_items_per_page := l_total_items;
        ELSE
            l_startindex     := nvl(i_startindex, 1);
            l_items_per_page := nvl(i_items_per_page, 10);
        
            IF l_startindex < 1
            THEN
                -- Minimum inbound 
                l_startindex := 1;
            END IF;
        
            IF l_startindex > l_total_items
            THEN
                -- Force to not return data
                l_startindex := l_total_items + 1;
            END IF;
        END IF;
    
        OPEN o_diagnosis FOR
            SELECT x.id_nan_diagnosis,
                   x.diagnosis_code,
                   pk_nan_model.format_nanda_name(i_label       => x.diagnosis_name,
                                                  i_nanda_code  => x.diagnosis_code,
                                                  i_code_format => pk_nan_model.g_code_format_end) diagnosis_name,
                   pk_translation.get_translation(x.id_language, x.code_definition) diagnosis_definition,
                   CAST(MULTISET (SELECT ndc.id_nan_def_chars
                           FROM nan_def_chars ndc
                          WHERE ndc.id_nan_diagnosis = x.id_nan_diagnosis) AS table_number) lst_def_chars,
                   CAST(MULTISET (SELECT rskf.id_nan_risk_factor
                           FROM nan_risk_factor rskf
                          WHERE rskf.id_nan_diagnosis = x.id_nan_diagnosis) AS table_number) lst_risk_factors,
                   
                   CAST(MULTISET (SELECT relf.id_nan_related_factor
                           FROM nan_related_factor relf
                          WHERE relf.id_nan_diagnosis = x.id_nan_diagnosis) AS table_number) lst_rel_factors
              FROM (SELECT /*+ first_rows(10) */
                     row_number() over(ORDER BY ndcfg.diagnosis_name) rn,
                     ndcfg.id_language,
                     ndcfg.id_nan_diagnosis,
                     ndcfg.diagnosis_code,
                     ndcfg.diagnosis_name,
                     ndcfg.code_definition
                      FROM (SELECT pk_translation.get_translation(tf.id_language, tf.code_name) diagnosis_name, tf.*
                              FROM TABLE(tf_inst_diagnosis(i_inst => i_prof.institution, i_soft => i_prof.software)) tf
                             WHERE tf.id_nan_class = nvl(i_nan_class, tf.id_nan_class)
                               AND (tf.flg_status = pk_alert_constant.g_active OR
                                   (tf.flg_status = pk_alert_constant.g_inactive AND
                                   i_include_inactive = pk_alert_constant.g_yes))) ndcfg) x
             WHERE x.rn BETWEEN l_startindex AND (l_startindex + l_items_per_page - 1)
             ORDER BY rn;
    
    END get_nan_diagnoses;

    PROCEDURE set_inst_diagnosis_status
    (
        i_institution   IN nan_cfg_diagnosis.id_institution%TYPE,
        i_nan_diagnosis IN nan_cfg_diagnosis.id_nan_diagnosis%TYPE,
        i_flg_status    IN nan_cfg_diagnosis.flg_status%TYPE
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_inst_diagnosis_status';
        l_nan_cfg_diagnosis nan_cfg_diagnosis.id_nan_cfg_diagnosis%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_institution), '<null>');
        g_error := g_error || ' i_nan_diagnosis = ' || coalesce(to_char(i_nan_diagnosis), '<null>');
        g_error := g_error || ' i_flg_status = ' || coalesce(to_char(i_flg_status), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        BEGIN
            SELECT ncfg.id_nan_cfg_diagnosis
              INTO l_nan_cfg_diagnosis
              FROM nan_cfg_diagnosis ncfg
             WHERE ncfg.id_institution = i_institution
               AND ncfg.id_nan_diagnosis = i_nan_diagnosis;
            ts_nan_cfg_diagnosis.upd(id_nan_cfg_diagnosis_in => l_nan_cfg_diagnosis,
                                     flg_status_in           => i_flg_status,
                                     dt_last_update_in       => current_timestamp);
        EXCEPTION
            WHEN no_data_found THEN
                ts_nan_cfg_diagnosis.ins(id_institution_in   => i_institution,
                                         id_nan_diagnosis_in => i_nan_diagnosis,
                                         flg_status_in       => i_flg_status,
                                         dt_last_update_in   => current_timestamp);
        END;
    
    END set_inst_diagnosis_status;

    PROCEDURE init_fltr_params_nanda
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        k_function_name    CONSTANT VARCHAR2(30 CHAR) := 'init_fltr_params_nanda';
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        
                                                        i_context_ids(g_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
        l_terminology_version nan_diagnosis.id_terminology_version%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_context_ids = ' || coalesce(pk_utils.concat_table(i_context_ids, ','), '<null>');
        g_error := g_error || ' i_context_vals = ' || coalesce(pk_utils.concat_table(i_context_vals, ','), '<null>');
        g_error := g_error || ' i_name = ' || coalesce(i_name, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'i_terminology_language' THEN
                l_terminology_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nanda,
                                                                               i_inst             => l_prof.institution,
                                                                               i_soft             => l_prof.software);
            
                o_id := pk_nnn_core.get_terminology_language(i_terminology_version => l_terminology_version);
            WHEN 'i_code_format' THEN
                --TODO: This can be configurable by using a SYS_CONFIG in order to display or not the NANDA Code in search results
                -- Suggestion: create a new constant (flag) like g_code_format_cfg_search and modify the function pk_nan_model.format_nanda_name 
                -- to recongize this flag and evaluate the format settings.
                o_vc2 := pk_nan_model.g_code_format_end;
        END CASE;
    
    END init_fltr_params_nanda;

    FUNCTION get_search_by_code_or_text
    (
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE,
        i_search IN pk_translation.t_desc
    ) RETURN table_t_search IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_search_by_code_or_text';
        l_out_rec              table_t_search := table_t_search(NULL);
        l_search               pk_translation.t_desc;
        l_nanda_code           nan_diagnosis.diagnosis_code%TYPE;
        l_search_by_text       VARCHAR(1 CHAR) := pk_alert_constant.g_yes;
        l_search_by_code       VARCHAR(1 CHAR) := pk_alert_constant.g_yes;
        l_terminology_language terminology_version.id_language%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_inst = ' || coalesce(to_char(i_inst), '<null>');
        g_error := g_error || ' i_soft = ' || coalesce(to_char(i_soft), '<null>');
        g_error := g_error || ' i_search = ' || coalesce(i_search, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Language of the NANDA terminology that is configured for this institution/software 
        -- Is used this var because the following SQL query can not reference the t.id_language in the inner query with which is joined.
        l_terminology_language := pk_nnn_core.get_terminology_language(i_terminology_name => pk_nnn_constant.g_terminology_nanda,
                                                                       i_inst             => i_inst,
                                                                       i_soft             => i_soft);
    
        -- Evaluate if the search value is a number. 
        -- If so it enable to seach by NANDA code, otherwise it is disabled.
        BEGIN
            l_search     := pk_lucene.escape_special_characters(i_string       => i_search,
                                                                i_use_wildcard => pk_alert_constant.g_no);
            l_nanda_code := to_number(l_search);
        EXCEPTION
            WHEN OTHERS THEN
                l_search_by_code := pk_alert_constant.g_no;
        END;
    
        -- NANDA Diagnoses     
        WITH inst_diagnosis AS
         (SELECT /*+ materialize */
           t.*
            FROM TABLE(tf_inst_diagnosis(i_inst => i_inst, i_soft => i_soft)) t),
        
        -- Search filter by NANDA label
        search_by_text AS
         (SELECT /*+ materialize */
           t.id_nan_diagnosis, lucne.code_translation, lucne.desc_translation, lucne.position, lucne.relevance
            FROM inst_diagnosis t
            JOIN (SELECT /*+opt_estimate(table a rows=1)*/
                  a.code_translation, a.desc_translation, a.position, a.relevance
                   FROM TABLE(pk_translation.get_search_translation(i_lang        => l_terminology_language,
                                                                    i_search      => i_search,
                                                                    i_column_name => 'NAN_DIAGNOSIS.CODE_NAME')) a) lucne
              ON lucne.code_translation = t.code_name
           WHERE l_search_by_text = pk_alert_constant.g_yes),
        
        -- Search filter by NANDA code
        search_by_code AS
         (SELECT t.id_nan_diagnosis,
                 t.code_name code_translation,
                 pk_translation.get_translation(t.id_language, t.code_name) desc_translation,
                 NULL position,
                 NULL relevance
            FROM inst_diagnosis t
           WHERE l_search_by_code = pk_alert_constant.g_yes
             AND t.diagnosis_code = l_nanda_code)
        
        -- Main query
        SELECT t_search(code_translation => t.code_translation,
                        desc_translation => t.desc_translation,
                        position         => t.position,
                        relevance        => t.relevance) BULK COLLECT
          INTO l_out_rec
          FROM (SELECT t.*
                  FROM search_by_text t
                 WHERE l_search_by_text = pk_alert_constant.g_yes
                UNION ALL
                SELECT t.*
                  FROM search_by_code t
                 WHERE l_search_by_code = pk_alert_constant.g_yes) t;
    
        RETURN l_out_rec;
    END get_search_by_code_or_text;

    FUNCTION is_linkable_diagnosis_outcome
    (
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE
    ) RETURN VARCHAR2 IS
        l_termi_vers_nnn_lnk nan_noc_nic_linkage.id_terminology_version%TYPE;
        l_exists             NUMBER;
    BEGIN
        -- get the Terminology Version ID configured to being used for NNN-Linkages
        l_termi_vers_nnn_lnk := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nnn_linkages,
                                                                      i_inst             => i_prof.institution,
                                                                      i_soft             => i_prof.software);
    
        SELECT count(*)
          INTO l_exists
          FROM dual
         WHERE EXISTS (
                -- Check if linkage is valid because it is defined in the classification NANDA, NOC, and NIC Linkages (NNN)
                SELECT 1
                  FROM nan_noc_nic_linkage nnnl
                 INNER JOIN nan_diagnosis nd
                    ON nd.diagnosis_code = nnnl.diagnosis_code
                 INNER JOIN noc_outcome no
                    ON no.outcome_code = nnnl.outcome_code
                 WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                   AND no.id_noc_outcome = i_noc_outcome
                   AND nnnl.id_terminology_version = l_termi_vers_nnn_lnk
                      -- Not exist a custom linkage definition for this pair in this institution 
                   AND NOT EXISTS (SELECT 1
                          FROM nan_noc_cfg_linkage nncl
                         WHERE nncl.id_institution = i_prof.institution
                           AND nncl.id_nan_diagnosis = i_nan_diagnosis
                           AND nncl.id_noc_outcome = i_noc_outcome)
                UNION ALL
                -- Check if linkage is valid because it is defined in the classification NANDA-NOC linkages                
                SELECT 1
                  FROM nan_noc_linkage nnl
                 INNER JOIN nan_diagnosis nd
                    ON nd.diagnosis_code = nnl.diagnosis_code
                 WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                   AND nnl.id_noc_outcome = i_noc_outcome
                      -- Not exist a custom linkage definition for this pair in this institution 
                   AND NOT EXISTS (SELECT 1
                          FROM nan_noc_cfg_linkage nncl
                         WHERE nncl.id_institution = i_prof.institution
                           AND nncl.id_nan_diagnosis = i_nan_diagnosis
                           AND nncl.id_noc_outcome = i_noc_outcome)
                UNION ALL
                -- Check if the linkage is valid because is defined (and active) by a custom linkage in this institution
                SELECT 1
                  FROM nan_noc_cfg_linkage nncl
                 WHERE nncl.id_institution = i_prof.institution
                   AND nncl.id_nan_diagnosis = i_nan_diagnosis
                   AND nncl.id_noc_outcome = i_noc_outcome
                   AND nncl.flg_lnk_status = pk_alert_constant.g_active);
    
        RETURN pk_utils.bool_to_flag(l_exists > 0);
    
    END is_linkable_diagnosis_outcome;

    FUNCTION is_linkable_diagnosis_interv
    (
        i_prof             IN profissional,
        i_nan_diagnosis    IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE
    ) RETURN VARCHAR2 IS
        l_termi_vers_nnn_lnk nan_noc_nic_linkage.id_terminology_version%TYPE;
        l_exists             NUMBER;
    BEGIN
        -- Gets the Terminology Version ID configured to being used for NNN-Linkages
        l_termi_vers_nnn_lnk := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nnn_linkages,
                                                                      i_inst             => i_prof.institution,
                                                                      i_soft             => i_prof.software);
    
        SELECT count(*)
          INTO l_exists
          FROM dual
         WHERE EXISTS (
                -- Check if linkage is valid because it is defined in the classification NANDA, NOC, and NIC Linkages (NNN)
                SELECT 1
                  FROM nan_noc_nic_linkage nnnl
                 INNER JOIN nan_diagnosis nd
                    ON nd.diagnosis_code = nnnl.diagnosis_code
                 INNER JOIN nic_intervention ni
                    ON ni.intervention_code = nnnl.intervention_code
                 WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                   AND ni.id_nic_intervention = i_nic_intervention
                   AND nnnl.id_terminology_version = l_termi_vers_nnn_lnk
                      -- Not exist a custom linkage definition for this pair in this institution 
                   AND NOT EXISTS (SELECT 1
                          FROM nan_nic_cfg_linkage nncl
                         WHERE nncl.id_institution = i_prof.institution
                           AND nncl.id_nan_diagnosis = i_nan_diagnosis
                           AND nncl.id_nic_intervention = i_nic_intervention)
                UNION ALL
                -- Check if linkage is valid because it is defined in the classification NANDA-NIC linkages                
                SELECT 1
                  FROM nan_nic_linkage nnl
                 INNER JOIN nan_diagnosis nd
                    ON nd.diagnosis_code = nnl.diagnosis_code
                 WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                   AND nnl.id_nic_intervention = i_nic_intervention
                      -- Not exist a custom linkage definition for this pair in this institution 
                   AND NOT EXISTS (SELECT 1
                          FROM nan_nic_cfg_linkage nncl
                         WHERE nncl.id_institution = i_prof.institution
                           AND nncl.id_nan_diagnosis = i_nan_diagnosis
                           AND nncl.id_nic_intervention = i_nic_intervention)
                UNION ALL
                -- Check if the linkage is valid because is defined (and active) by a custom linkage in this institution
                SELECT 1
                  FROM nan_nic_cfg_linkage nncl
                 WHERE nncl.id_institution = i_prof.institution
                   AND nncl.id_nan_diagnosis = i_nan_diagnosis
                   AND nncl.id_nic_intervention = i_nic_intervention
                   AND nncl.flg_lnk_status = pk_alert_constant.g_active);
        RETURN pk_utils.bool_to_flag(l_exists > 0);
    
    END is_linkable_diagnosis_interv;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_nan_cfg;
/
