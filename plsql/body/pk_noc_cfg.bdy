/*-- Last Change Revision: $Rev: 1857415 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2018-07-27 10:00:28 +0100 (sex, 27 jul 2018) $*/
CREATE OR REPLACE PACKAGE BODY pk_noc_cfg IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    FUNCTION get_linked_outcomes
    (
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE
    ) RETURN table_number IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_linked_outcomes';
        l_lst_outcomes   table_number;
        l_term_v_nnn_lnk nan_noc_nic_linkage.id_terminology_version%TYPE;
        l_term_v_noc     noc_outcome.id_terminology_version%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_software = ' || coalesce(to_char(i_prof.software), '<null>');
        g_error := g_error || ' i_nan_diagnosis = ' || coalesce(to_char(i_nan_diagnosis), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Retrieves the terminology version of NNN-Linkages configured for the institution
        l_term_v_nnn_lnk := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nnn_linkages,
                                                                  i_inst             => i_prof.institution,
                                                                  i_soft             => i_prof.software);
    
        -- Retrieves the terminology version of NOC Classification configured for the institution
        l_term_v_noc := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_noc,
                                                              i_inst             => i_prof.institution,
                                                              i_soft             => i_prof.software);
        -- Retrieves a collection of id_noc_outcome that are linked to the NANDA diagnosis as input argument
        SELECT id_noc_outcome BULK COLLECT
          INTO l_lst_outcomes
          FROM (
                -- Retrieve linked NOC outcomes that are defined in the classification NANDA, NOC, and NIC Linkages (NNN)
                SELECT DISTINCT no.id_noc_outcome
                  FROM nan_noc_nic_linkage nnnl
                 INNER JOIN nan_diagnosis nd
                    ON nd.diagnosis_code = nnnl.diagnosis_code
                 INNER JOIN noc_outcome no
                    ON no.outcome_code = nnnl.outcome_code
                   AND no.id_terminology_version = l_term_v_noc
                 WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                   AND nnnl.id_terminology_version = l_term_v_nnn_lnk
                      -- Not exist a custom linkage definition for this pair in this institution
                   AND NOT EXISTS (SELECT 1
                          FROM nan_noc_cfg_linkage nncl
                         WHERE nncl.id_institution = i_prof.institution
                           AND nncl.id_nan_diagnosis = nd.id_nan_diagnosis
                           AND nncl.id_noc_outcome = no.id_noc_outcome)
                UNION
                -- Retrieve linked NOC outcomes that are defined in the classification NANDA-NOC linkages                
                SELECT nnl.id_noc_outcome
                  FROM nan_noc_linkage nnl
                 INNER JOIN noc_outcome no
                    ON nnl.id_noc_outcome = no.id_noc_outcome
                 INNER JOIN nan_diagnosis nd
                    ON nd.diagnosis_code = nnl.diagnosis_code
                 WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                   AND no.id_terminology_version = l_term_v_noc
                      -- Not exist a custom linkage definition for this pair in this institution 
                   AND NOT EXISTS (SELECT 1
                          FROM nan_noc_cfg_linkage nncl
                         WHERE nncl.id_institution = i_prof.institution
                           AND nncl.id_nan_diagnosis = nd.id_nan_diagnosis
                           AND nncl.id_noc_outcome = no.id_noc_outcome)
                UNION
                -- Retrieve linked NOC outcomes that are defined (and active) by a custom linkage in this institution
                SELECT nncl.id_noc_outcome
                  FROM nan_noc_cfg_linkage nncl
                 INNER JOIN noc_outcome no
                    ON nncl.id_noc_outcome = no.id_noc_outcome
                 WHERE nncl.id_institution = i_prof.institution
                   AND nncl.id_nan_diagnosis = i_nan_diagnosis
                   AND nncl.flg_lnk_status = pk_alert_constant.g_active
                   AND no.id_terminology_version = l_term_v_noc);
    
        RETURN l_lst_outcomes;
    
    END get_linked_outcomes;

    FUNCTION tf_inst_outcome
    (
        i_inst  IN institution.id_institution%TYPE,
        i_soft  IN software.id_software%TYPE DEFAULT NULL,
        i_limit IN PLS_INTEGER DEFAULT pk_noc_cfg.k_default_bulk_limit
    ) RETURN t_noc_cfg_outcome_coll
        PIPELINED IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'tf_inst_outcome';
        l_noc_term_version      noc_outcome.id_terminology_version%TYPE;
        l_language              terminology_version.id_language%TYPE;
        l_cursor                t_noc_cfg_outcome_cur;
        l_noc_cfg_outcome_coll  t_noc_cfg_outcome_coll;
        l_default_flg_prn       noc_cfg_outcome.flg_prn%TYPE;
        l_default_flg_time      noc_cfg_outcome.flg_time%TYPE;
        l_default_flg_priorty   noc_cfg_outcome.flg_priority%TYPE;
        l_default_recurr_option noc_cfg_outcome.id_order_recurr_option%TYPE;
        l_error                 t_error_out;
    BEGIN
        -- Retrieves the terminology version of NOC Classification configured for the institution
        BEGIN
            l_noc_term_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_noc,
                                                                        i_inst             => i_inst,
                                                                        i_soft             => i_soft);
        EXCEPTION
            WHEN pk_nnn_core.e_missing_cfg_term_version THEN
                --This institution has no configurations to use NOC Classification
                RETURN;
        END;
        l_language := pk_nnn_core.get_terminology_language(i_terminology_version => l_noc_term_version);
    
        l_default_flg_priorty := pk_nnn_core.get_default_flg_priority();
        l_default_flg_prn     := pk_nnn_core.get_default_flg_prn(i_lang => l_language);
        l_default_flg_time    := pk_nnn_core.get_default_flg_time(i_lang => l_language,
                                                                  i_inst => i_inst,
                                                                  i_soft => i_soft);
        IF NOT pk_order_recurrence_api_db.get_def_order_recurr_option(i_lang                   => l_language,
                                                                      i_prof                   => profissional(id          => NULL,
                                                                                                               institution => i_inst,
                                                                                                               software    => i_soft),
                                                                      i_order_recurr_area      => pk_nnn_constant.g_ordrecurr_area_noc_outcome,
                                                                      o_id_order_recurr_option => l_default_recurr_option,
                                                                      o_error                  => l_error)
        THEN
            pk_alertlog.log_error(text            => 'Error retrieving default recurrence option for NOC Outcome area',
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            l_default_recurr_option := pk_nnn_constant.g_order_recurr_option_no_sch;
        END IF;
    
        -- NOC Outcomes: show all outcomes without custom settings + outcomes with settings defined by a given institution
        -- This approach allows us to display all classification content with default settings with no need the institution first having to manually define it.
        OPEN l_cursor FOR
            SELECT NULL                       id_noc_cfg_outcome,
                   pk_alert_constant.g_active flg_status,
                   NULL                       dt_last_update,
                   no.id_noc_outcome,
                   no.id_terminology_version,
                   no.outcome_code,
                   no.code_name,
                   no.code_definition,
                   no.id_noc_scale,
                   no.references,
                   no.id_noc_class,
                   l_language                 id_language,
                   l_default_flg_prn          flg_prn,
                   NULL                       code_notes_prn,
                   l_default_flg_time         flg_time,
                   l_default_flg_priorty      flg_priority,
                   l_default_recurr_option    id_order_recurr_option
              FROM noc_outcome no
             WHERE no.id_terminology_version = l_noc_term_version
               AND NOT EXISTS (SELECT 1
                      FROM noc_cfg_outcome nocfg
                     WHERE nocfg.id_noc_outcome = no.id_noc_outcome
                       AND nocfg.id_institution = i_inst)
            UNION ALL
            SELECT nocfg.id_noc_cfg_outcome,
                   nocfg.flg_status,
                   nocfg.dt_last_update,
                   no.id_noc_outcome,
                   no.id_terminology_version,
                   no.outcome_code,
                   no.code_name,
                   no.code_definition,
                   no.id_noc_scale,
                   no.references,
                   no.id_noc_class,
                   l_language id_language,
                   nocfg.flg_prn,
                   nocfg.code_notes_prn,
                   nocfg.flg_time,
                   nocfg.flg_priority,
                   coalesce(nocfg.id_order_recurr_option, l_default_recurr_option) id_order_recurr_option
              FROM noc_outcome no
             INNER JOIN noc_cfg_outcome nocfg
                ON no.id_noc_outcome = nocfg.id_noc_outcome
             WHERE no.id_terminology_version = l_noc_term_version
               AND nocfg.id_institution = i_inst;
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_noc_cfg_outcome_coll LIMIT i_limit;
            EXIT WHEN l_noc_cfg_outcome_coll.count = 0;
        
            FOR i IN 1 .. l_noc_cfg_outcome_coll.count
            LOOP
                PIPE ROW(l_noc_cfg_outcome_coll(i));
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
    END tf_inst_outcome;

    FUNCTION tf_inst_indicator
    (
        i_inst        IN institution.id_institution%TYPE,
        i_soft        IN software.id_software%TYPE DEFAULT NULL,
        i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE,
        i_limit       IN PLS_INTEGER DEFAULT pk_noc_cfg.k_default_bulk_limit
    ) RETURN t_noc_cfg_indicator_coll
        PIPELINED IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'tf_inst_indicator';
        l_noc_term_version       noc_indicator.id_terminology_version%TYPE;
        l_language               terminology_version.id_language%TYPE;
        l_cursor                 t_noc_cfg_indicator_cur;
        l_noc_cfg_indicator_coll t_noc_cfg_indicator_coll;
        l_default_flg_prn        noc_cfg_indicator.flg_prn%TYPE;
        l_default_flg_time       noc_cfg_indicator.flg_time%TYPE;
        l_default_flg_priorty    noc_cfg_indicator.flg_priority%TYPE;
        l_default_recurr_option  noc_cfg_indicator.id_order_recurr_option%TYPE;
        l_error                  t_error_out;
    BEGIN
        -- Retrieves the terminology version of NOC Classification configured for the institution
        BEGIN
            l_noc_term_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_noc,
                                                                        i_inst             => i_inst,
                                                                        i_soft             => i_soft);
        EXCEPTION
            WHEN pk_nnn_core.e_missing_cfg_term_version THEN
                --This institution has no configurations to use NOC Classification
                RETURN;
        END;
        l_language := pk_nnn_core.get_terminology_language(i_terminology_version => l_noc_term_version);
    
        l_default_flg_priorty := pk_nnn_core.get_default_flg_priority();
        l_default_flg_prn     := pk_nnn_core.get_default_flg_prn(i_lang => l_language);
        l_default_flg_time    := pk_nnn_core.get_default_flg_time(i_lang => l_language,
                                                                  i_inst => i_inst,
                                                                  i_soft => i_soft);
        IF NOT pk_order_recurrence_api_db.get_def_order_recurr_option(i_lang                   => l_language,
                                                                      i_prof                   => profissional(id          => NULL,
                                                                                                               institution => i_inst,
                                                                                                               software    => i_soft),
                                                                      i_order_recurr_area      => pk_nnn_constant.g_ordrecurr_area_noc_indicator,
                                                                      o_id_order_recurr_option => l_default_recurr_option,
                                                                      o_error                  => l_error)
        THEN
            pk_alertlog.log_error(text            => 'Error retrieving default recurrence option for NOC Indicator area',
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            l_default_recurr_option := pk_nnn_constant.g_order_recurr_option_no_sch;
        END IF;
    
        -- NOC indicators: show all indicators without custom settings + indicators with settings defined by a given institution
        -- This approach allows us to display all classification content with default settings with no need the institution first having to manually define it.
        OPEN l_cursor FOR
            SELECT NULL id_noc_cfg_indicator,
                   pk_alert_constant.g_active flg_status,
                   NULL dt_last_update,
                   ni.id_noc_indicator,
                   ni.id_terminology_version,
                   noi.outcome_indicator_code,
                   ni.code_description,
                   ni.flg_other,
                   noi.id_noc_outcome,
                   coalesce(noi.id_noc_scale, noc.id_noc_scale) id_noc_scale,
                   noi.rank,
                   l_language id_language,
                   l_default_flg_prn flg_prn,
                   NULL code_notes_prn,
                   l_default_flg_time flg_time,
                   l_default_flg_priorty flg_priority,
                   l_default_recurr_option id_order_recurr_option
              FROM noc_indicator ni
             INNER JOIN noc_outcome_indicator noi
                ON noi.id_noc_indicator = ni.id_noc_indicator
             INNER JOIN noc_outcome noc
                ON noi.id_noc_outcome = noc.id_noc_outcome
             WHERE ni.id_terminology_version = l_noc_term_version
               AND noi.id_noc_outcome = i_noc_outcome
               AND NOT EXISTS (SELECT 1
                      FROM noc_cfg_indicator nci
                     WHERE nci.id_noc_indicator = ni.id_noc_indicator
                       AND nci.id_institution = i_inst)
            UNION ALL
            SELECT nci.id_noc_cfg_indicator,
                   nci.flg_status,
                   nci.dt_last_update,
                   ni.id_noc_indicator,
                   ni.id_terminology_version,
                   noi.outcome_indicator_code,
                   ni.code_description,
                   ni.flg_other,
                   noi.id_noc_outcome,
                   coalesce(noi.id_noc_scale, noc.id_noc_scale) id_noc_scale,
                   noi.rank,
                   l_language id_language,
                   nci.flg_prn,
                   nci.code_notes_prn,
                   nci.flg_time,
                   nci.flg_priority,
                   coalesce(nci.id_order_recurr_option, l_default_recurr_option) id_order_recurr_option
              FROM noc_indicator ni
             INNER JOIN noc_cfg_indicator nci
                ON ni.id_noc_indicator = nci.id_noc_indicator
             INNER JOIN noc_cfg_outcome_ind ncoi
                ON ncoi.id_noc_indicator = nci.id_noc_indicator
             INNER JOIN noc_outcome_indicator noi
                ON (noi.id_noc_indicator = ncoi.id_noc_indicator AND noi.id_noc_outcome = ncoi.id_noc_outcome)
             INNER JOIN noc_outcome noc
                ON noi.id_noc_outcome = noc.id_noc_outcome
             WHERE ni.id_terminology_version = l_noc_term_version
               AND nci.id_institution = i_inst
               AND ncoi.id_noc_outcome = i_noc_outcome
               AND NOT EXISTS (SELECT 1 -- Verifies the relationship between Outcomes and Indicators was not cancelled by the institution
                      FROM noc_cfg_outcome_ind cfgnoi
                     WHERE cfgnoi.id_institution = i_inst
                       AND cfgnoi.id_noc_outcome = noi.id_noc_outcome
                       AND cfgnoi.id_noc_indicator = noi.id_noc_indicator
                       AND cfgnoi.flg_lnk_status = pk_alert_constant.g_cancelled)
             ORDER BY rank;
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_noc_cfg_indicator_coll LIMIT i_limit;
            EXIT WHEN l_noc_cfg_indicator_coll.count = 0;
        
            FOR i IN 1 .. l_noc_cfg_indicator_coll.count
            LOOP
                PIPE ROW(l_noc_cfg_indicator_coll(i));
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
    END tf_inst_indicator;

    FUNCTION tf_inst_indicator
    (
        i_inst  IN institution.id_institution%TYPE,
        i_soft  IN software.id_software%TYPE DEFAULT NULL,
        i_limit IN PLS_INTEGER DEFAULT pk_noc_cfg.k_default_bulk_limit
    ) RETURN t_noc_cfg_indicator_coll
        PIPELINED IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'tf_inst_indicator';
        l_noc_term_version       noc_indicator.id_terminology_version%TYPE;
        l_language               terminology_version.id_language%TYPE;
        l_cursor                 t_noc_cfg_indicator_cur;
        l_noc_cfg_indicator_coll t_noc_cfg_indicator_coll;
        l_default_flg_prn        noc_cfg_indicator.flg_prn%TYPE;
        l_default_flg_time       noc_cfg_indicator.flg_time%TYPE;
        l_default_flg_priorty    noc_cfg_indicator.flg_priority%TYPE;
        l_default_recurr_option  noc_cfg_indicator.id_order_recurr_option%TYPE;
        l_error                  t_error_out;
    BEGIN
        -- Retrieves the terminology version of NOC Classification configured for the institution
        BEGIN
            l_noc_term_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_noc,
                                                                        i_inst             => i_inst,
                                                                        i_soft             => i_soft);
        
        EXCEPTION
            WHEN pk_nnn_core.e_missing_cfg_term_version THEN
                --This institution has no configurations to use NOC Classification
                RETURN;
        END;
        l_language            := pk_nnn_core.get_terminology_language(i_terminology_version => l_noc_term_version);
        l_default_flg_priorty := pk_nnn_core.get_default_flg_priority();
        l_default_flg_prn     := pk_nnn_core.get_default_flg_prn(i_lang => l_language);
        l_default_flg_time    := pk_nnn_core.get_default_flg_time(i_lang => l_language,
                                                                  i_inst => i_inst,
                                                                  i_soft => i_soft);
        IF NOT pk_order_recurrence_api_db.get_def_order_recurr_option(i_lang                   => l_language,
                                                                      i_prof                   => profissional(id          => NULL,
                                                                                                               institution => i_inst,
                                                                                                               software    => i_soft),
                                                                      i_order_recurr_area      => pk_nnn_constant.g_ordrecurr_area_noc_indicator,
                                                                      o_id_order_recurr_option => l_default_recurr_option,
                                                                      o_error                  => l_error)
        THEN
            pk_alertlog.log_error(text            => 'Error retrieving default recurrence option for NOC Indicator area',
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            l_default_recurr_option := pk_nnn_constant.g_order_recurr_option_no_sch;
        END IF;
    
        -- NOC indicators: show all indicators without custom settings + indicators with settings defined by a given institution
        -- This approach allows us to display all classification content with default settings with no need the institution first having to manually define it.
        OPEN l_cursor FOR
            SELECT NULL                       id_noc_cfg_indicator,
                   pk_alert_constant.g_active flg_status,
                   NULL                       dt_last_update,
                   ni.id_noc_indicator,
                   ni.id_terminology_version,
                   NULL                       outcome_indicator_code,
                   ni.code_description,
                   ni.flg_other,
                   NULL                       id_noc_outcome,
                   NULL                       id_noc_scale,
                   NULL                       rank,
                   l_language                 id_language,
                   l_default_flg_prn          flg_prn,
                   NULL                       code_notes_prn,
                   l_default_flg_time         flg_time,
                   l_default_flg_priorty      flg_priority,
                   l_default_recurr_option    id_order_recurr_option
              FROM noc_indicator ni
             WHERE ni.id_terminology_version = l_noc_term_version
               AND NOT EXISTS (SELECT 1
                      FROM noc_cfg_indicator nci
                     WHERE nci.id_noc_indicator = ni.id_noc_indicator
                       AND nci.id_institution = i_inst)
            UNION ALL
            SELECT nci.id_noc_cfg_indicator,
                   nci.flg_status,
                   nci.dt_last_update,
                   ni.id_noc_indicator,
                   ni.id_terminology_version,
                   NULL outcome_indicator_code,
                   ni.code_description,
                   ni.flg_other,
                   NULL id_noc_outcome,
                   NULL id_noc_scale,
                   NULL rank,
                   l_language id_language,
                   nci.flg_prn,
                   nci.code_notes_prn,
                   nci.flg_time,
                   nci.flg_priority,
                   coalesce(nci.id_order_recurr_option, l_default_recurr_option) id_order_recurr_option
              FROM noc_indicator ni
             INNER JOIN noc_cfg_indicator nci
                ON ni.id_noc_indicator = nci.id_noc_indicator
             WHERE ni.id_terminology_version = l_noc_term_version
               AND nci.id_institution = i_inst;
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_noc_cfg_indicator_coll LIMIT i_limit;
            EXIT WHEN l_noc_cfg_indicator_coll.count = 0;
        
            FOR i IN 1 .. l_noc_cfg_indicator_coll.count
            LOOP
                PIPE ROW(l_noc_cfg_indicator_coll(i));
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
    END tf_inst_indicator;

    PROCEDURE get_noc_outcomes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_include_inactive IN noc_cfg_outcome.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_outcomes         OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_noc_outcomes';
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
          FROM TABLE(tf_inst_outcome(i_inst => i_prof.institution, i_soft => i_prof.software)) x
         WHERE x.flg_status = pk_alert_constant.g_active
            OR (x.flg_status = pk_alert_constant.g_inactive AND i_include_inactive = pk_alert_constant.g_yes);
    
        o_total_items := l_total_items;
    
        IF i_paging = pk_alert_constant.g_no
        THEN
            -- Returns all the resultset
            l_startindex     := 1;
            l_items_per_page := l_total_items;
        ELSE
            l_startindex     := i_startindex;
            l_items_per_page := i_items_per_page;
        
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
    
        OPEN o_outcomes FOR
            SELECT x.id_noc_cfg_outcome,
                   x.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, x.dt_last_update, i_prof) dt_last_update_str,
                   x.id_noc_outcome,
                   x.id_terminology_version,
                   x.outcome_code,
                   pk_noc_model.format_noc_name(i_label       => x.outcome_name,
                                                i_noc_code    => x.outcome_code,
                                                i_code_format => pk_noc_model.g_code_format_end) outcome_name,
                   pk_translation.get_translation(i_lang, x.code_definition) outcome_definition,
                   x.references,
                   x.id_noc_class
              FROM (SELECT /*+ first_rows(10) */
                     row_number() over(ORDER BY nocfg.outcome_name) rn,
                     nocfg.id_noc_cfg_outcome,
                     nocfg.flg_status,
                     nocfg.dt_last_update,
                     nocfg.id_noc_outcome,
                     nocfg.id_terminology_version,
                     nocfg.outcome_code,
                     nocfg.outcome_name,
                     nocfg.code_definition,
                     nocfg.references,
                     nocfg.id_noc_class
                      FROM (SELECT pk_translation.get_translation(i_lang, tf.code_name) outcome_name, tf.*
                              FROM TABLE(tf_inst_outcome(i_inst => i_prof.institution, i_soft => i_prof.software)) tf
                             WHERE tf.flg_status = pk_alert_constant.g_active
                                OR (tf.flg_status = pk_alert_constant.g_inactive AND
                                   i_include_inactive = pk_alert_constant.g_yes)) nocfg) x
             WHERE x.rn BETWEEN l_startindex AND (l_startindex + l_items_per_page - 1)
             ORDER BY rn;
    
    END get_noc_outcomes;

    PROCEDURE get_noc_outcomes
    (
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_outcomes      OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_noc_outcomes';
        l_term_v_noc noc_outcome.id_terminology_version%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_nan_diagnosis = ' || coalesce(to_char(i_nan_diagnosis), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves the terminology version of NOC Classification configured for the institution';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_term_v_noc := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_noc,
                                                              i_inst             => i_prof.institution,
                                                              i_soft             => i_prof.software);
    
        g_error := 'Retrieves the NOC Outcomes';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        OPEN o_outcomes FOR
            SELECT noc.id_noc_outcome,
                   noc.outcome_code,
                   pk_noc_model.format_noc_name(i_label       => pk_translation.get_translation(noc.id_language,
                                                                                                noc.code_name),
                                                i_noc_code    => noc.outcome_code,
                                                i_code_format => pk_noc_model.g_code_format_end) outcome_name,
                   pk_translation.get_translation(noc.id_language, noc.code_definition) outcome_definition,
                   noc.id_noc_scale,
                   k_default_scale_level default_scale_level_value,
                   pk_noc_model.get_scale_level_name(i_lang              => noc.id_language,
                                                     i_noc_scale         => noc.id_noc_scale,
                                                     i_scale_level_value => k_default_scale_level) default_scale_level_name,
                   
                   nnl.flg_link_type,
                   pk_sysdomain.get_domain_cached(i_lang        => noc.id_language,
                                                  i_value       => nnl.flg_link_type,
                                                  i_code_domain => pk_nnn_lnk_model.g_dom_nannoc_lnk_flg_link_type) desc_flg_link_type,
                   pk_sysdomain.get_rank(i_lang     => noc.id_language,
                                         i_code_dom => pk_nnn_lnk_model.g_dom_nannoc_lnk_flg_link_type,
                                         i_val      => nnl.flg_link_type) rank
              FROM (SELECT tf.id_noc_outcome,
                           tf.outcome_code,
                           tf.id_language,
                           tf.code_name,
                           tf.code_definition,
                           tf.id_noc_scale
                      FROM TABLE(pk_noc_cfg.tf_inst_outcome(i_inst => i_prof.institution, i_soft => i_prof.software)) tf
                     WHERE tf.flg_status = pk_alert_constant.g_active) noc
             INNER JOIN ( -- Retrieve linked NOC outcomes that are defined in the classification NANDA-NOC linkages                
                         SELECT nnl.id_noc_outcome, nnl.flg_link_type
                           FROM nan_noc_linkage nnl
                          INNER JOIN noc_outcome no
                             ON nnl.id_noc_outcome = no.id_noc_outcome
                          INNER JOIN nan_diagnosis nd
                             ON nd.diagnosis_code = nnl.diagnosis_code
                          WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                            AND no.id_terminology_version = l_term_v_noc
                               -- Not exist a custom linkage definition for this pair in this institution 
                            AND NOT EXISTS (SELECT 1
                                   FROM nan_noc_cfg_linkage nncl
                                  WHERE nncl.id_institution = i_prof.institution
                                    AND nncl.id_nan_diagnosis = nd.id_nan_diagnosis
                                    AND nncl.id_noc_outcome = no.id_noc_outcome)
                         UNION ALL
                         -- Retrieve linked NOC outcomes that are defined (and active) by a custom linkage in this institution
                         SELECT nncl.id_noc_outcome, nnl.flg_link_type
                           FROM nan_noc_cfg_linkage nncl
                          INNER JOIN noc_outcome no
                             ON nncl.id_noc_outcome = no.id_noc_outcome
                          INNER JOIN nan_diagnosis nd
                             ON nncl.id_nan_diagnosis = nd.id_nan_diagnosis
                           LEFT JOIN nan_noc_linkage nnl
                             ON no.id_noc_outcome = nnl.id_noc_outcome
                            AND nd.diagnosis_code = nnl.diagnosis_code
                          WHERE nncl.id_institution = i_prof.institution
                            AND nncl.id_nan_diagnosis = i_nan_diagnosis
                            AND nncl.flg_lnk_status = pk_alert_constant.g_active
                            AND no.id_terminology_version = l_term_v_noc) nnl
                ON noc.id_noc_outcome = nnl.id_noc_outcome
             ORDER BY rank, outcome_name;
    
    END get_noc_outcomes;

    PROCEDURE get_noc_indicators
    (
        i_prof        IN profissional,
        i_noc_outcome IN noc_outcome.id_noc_outcome %TYPE,
        o_indicators  OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_noc_indicators';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_noc_outcome = ' || coalesce(to_char(i_noc_outcome), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        OPEN o_indicators FOR
            SELECT tf.id_noc_indicator,
                   pk_translation.get_translation(tf.id_language, tf.code_description) indicator_name,
                   tf.id_noc_scale,
                   k_default_scale_level default_scale_level_value,
                   pk_noc_model.get_scale_level_name(i_lang              => tf.id_language,
                                                     i_noc_scale         => tf.id_noc_scale,
                                                     i_scale_level_value => k_default_scale_level) default_scale_level_name
              FROM TABLE(tf_inst_indicator(i_inst        => i_prof.institution,
                                           i_soft        => i_prof.software,
                                           i_noc_outcome => i_noc_outcome)) tf
             ORDER BY rank, indicator_name;
    
    END get_noc_indicators;

    PROCEDURE get_noc_indicators
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_include_inactive IN noc_cfg_indicator.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_indicators       OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_noc_indicators';
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
          FROM TABLE(tf_inst_indicator(i_inst => i_prof.institution, i_soft => i_prof.software)) x
         WHERE x.flg_status = pk_alert_constant.g_active
            OR (x.flg_status = pk_alert_constant.g_inactive AND i_include_inactive = pk_alert_constant.g_yes);
    
        o_total_items := l_total_items;
    
        IF i_paging = pk_alert_constant.g_no
        THEN
            -- Returns all the resultset
            l_startindex     := 1;
            l_items_per_page := l_total_items;
        ELSE
            l_startindex     := i_startindex;
            l_items_per_page := i_items_per_page;
        
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
    
        OPEN o_indicators FOR
            SELECT x.id_noc_cfg_indicator,
                   x.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, x.dt_last_update, i_prof) dt_last_update_str,
                   x.id_noc_indicator,
                   x.id_terminology_version,
                   x.indicator_name,
                   x.flg_other,
                   x.id_noc_outcome,
                   x.rank
              FROM (SELECT /*+ first_rows(10) */
                     row_number() over(ORDER BY nocfg.indicator_name) rn,
                     nocfg.id_noc_cfg_indicator,
                     nocfg.flg_status,
                     nocfg.dt_last_update,
                     nocfg.id_noc_indicator,
                     nocfg.id_terminology_version,
                     nocfg.indicator_name,
                     nocfg.flg_other,
                     nocfg.id_noc_outcome,
                     nocfg.rank
                      FROM (SELECT pk_translation.get_translation(i_lang, tf.code_description) indicator_name, tf.*
                              FROM TABLE(tf_inst_indicator(i_inst => i_prof.institution, i_soft => i_prof.software)) tf
                             WHERE tf.flg_status = pk_alert_constant.g_active
                                OR (tf.flg_status = pk_alert_constant.g_inactive AND
                                   i_include_inactive = pk_alert_constant.g_yes)) nocfg) x
             WHERE x.rn BETWEEN l_startindex AND (l_startindex + l_items_per_page - 1)
             ORDER BY rn;
    
    END get_noc_indicators;

    PROCEDURE set_inst_outcome_status
    (
        i_institution IN noc_cfg_outcome.id_institution%TYPE,
        i_noc_outcome IN noc_cfg_outcome.id_noc_outcome%TYPE,
        i_flg_status  IN noc_cfg_outcome.flg_status%TYPE
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_inst_outcome_status';
        l_noc_cfg_outcome noc_cfg_outcome.id_noc_cfg_outcome%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_institution), '<null>');
        g_error := g_error || ' i_noc_outcome = ' || coalesce(to_char(i_noc_outcome), '<null>');
        g_error := g_error || ' i_flg_status = ' || coalesce(to_char(i_flg_status), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        BEGIN
        
            SELECT ncfg.id_noc_cfg_outcome
              INTO l_noc_cfg_outcome
              FROM noc_cfg_outcome ncfg
             WHERE ncfg.id_institution = i_institution
               AND ncfg.id_noc_outcome = i_noc_outcome;
        
            ts_noc_cfg_outcome.upd(id_noc_cfg_outcome_in => l_noc_cfg_outcome,
                                   flg_status_in         => i_flg_status,
                                   dt_last_update_in     => current_timestamp);
        EXCEPTION
            WHEN no_data_found THEN
                ts_noc_cfg_outcome.ins(id_institution_in => i_institution,
                                       id_noc_outcome_in => i_noc_outcome,
                                       flg_status_in     => i_flg_status,
                                       dt_last_update_in => current_timestamp);
        END;
    END set_inst_outcome_status;

    PROCEDURE set_inst_indicator_status
    (
        i_institution   IN noc_cfg_indicator.id_institution%TYPE,
        i_noc_indicator IN noc_cfg_indicator.id_noc_indicator%TYPE,
        i_flg_status    IN noc_cfg_indicator.flg_status%TYPE
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_inst_outcome_status';
        l_noc_cfg_indicador noc_cfg_indicator.id_noc_cfg_indicator%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_institution), '<null>');
        g_error := g_error || ' indicator = ' || coalesce(to_char(l_noc_cfg_indicador), '<null>');
        g_error := g_error || ' i_flg_status = ' || coalesce(to_char(i_flg_status), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        BEGIN
        
            SELECT ncfg.id_noc_cfg_indicator
              INTO l_noc_cfg_indicador
              FROM noc_cfg_indicator ncfg
             WHERE ncfg.id_institution = i_institution
               AND ncfg.id_noc_indicator = i_noc_indicator;
        
            ts_noc_cfg_indicator.upd(id_noc_cfg_indicator_in => l_noc_cfg_indicador,
                                     flg_status_in           => i_flg_status,
                                     dt_last_update_in       => current_timestamp);
        EXCEPTION
            WHEN no_data_found THEN
                ts_noc_cfg_indicator.ins(id_institution_in   => i_institution,
                                         id_noc_indicator_in => i_noc_indicator,
                                         flg_status_in       => i_flg_status,
                                         dt_last_update_in   => current_timestamp);
        END;
    END set_inst_indicator_status;

    PROCEDURE init_fltr_params_noc
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
    BEGIN
    
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
                o_id := pk_nnn_core.get_terminology_language(i_terminology_name => pk_nnn_constant.g_terminology_noc,
                                                             i_inst             => l_prof.institution,
                                                             i_soft             => l_prof.software);
            WHEN 'i_code_format' THEN
                --TODO: This can be configurable by using a SYS_CONFIG in order to display or not the NOC Code in search results
                -- Suggestion: create a new constant (flag) like g_code_format_cfg_search and modify the function pk_noc_model.format_noc_name 
                -- to recongize this flag and evaluate the format settings.
                o_vc2 := pk_nan_model.g_code_format_end;
        END CASE;
    
    END init_fltr_params_noc;

    FUNCTION get_search_by_code_or_text
    (
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE,
        i_search IN pk_translation.t_desc
    ) RETURN table_t_search IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_search_by_code_or_text';
        l_out_rec              table_t_search := table_t_search(NULL);
        l_search               pk_translation.t_desc;
        l_noc_code             noc_outcome.outcome_code%TYPE;
        l_search_by_text       VARCHAR(1 CHAR) := pk_alert_constant.g_yes;
        l_search_by_code       VARCHAR(1 CHAR) := pk_alert_constant.g_yes;
        l_terminology_language terminology_version.id_language%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_inst = ' || coalesce(to_char(i_inst), '<null>');
        g_error := g_error || ' i_soft = ' || coalesce(to_char(i_soft), '<null>');
        g_error := g_error || ' i_search = ' || coalesce(i_search, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Language of the NOC terminology that is configured for this institution/software 
        -- Is used this var because the following SQL query can not reference the t.id_language in the inner query with which is joined.
        l_terminology_language := pk_nnn_core.get_terminology_language(i_terminology_name => pk_nnn_constant.g_terminology_noc,
                                                                       i_inst             => i_inst,
                                                                       i_soft             => i_soft);
    
        -- Evaluate if the search value is a number. 
        -- If so it enable to seach by NOC Outcome code, otherwise it is disabled.
        BEGIN
            l_search   := pk_lucene.escape_special_characters(i_string       => i_search,
                                                              i_use_wildcard => pk_alert_constant.g_no);
            l_noc_code := to_number(l_search);
        EXCEPTION
            WHEN OTHERS THEN
                l_search_by_code := pk_alert_constant.g_no;
        END;
    
        -- NOC Outcomes
        WITH inst_outcomes AS
         (SELECT /*+ materialize */
           t.*
            FROM TABLE(tf_inst_outcome(i_inst => i_inst, i_soft => i_soft)) t),
        
        -- Search filter by NOC Outcome label
        search_by_text AS
         (SELECT /*+ materialize */
           t.id_noc_outcome, lucne.code_translation, lucne.desc_translation, lucne.position, lucne.relevance
            FROM inst_outcomes t
            JOIN (SELECT /*+opt_estimate(table a rows=1)*/
                  a.code_translation, a.desc_translation, a.position, a.relevance
                   FROM TABLE(pk_translation.get_search_translation(i_lang        => l_terminology_language,
                                                                    i_search      => i_search,
                                                                    i_column_name => 'NOC_OUTCOME.CODE_NAME')) a) lucne
              ON lucne.code_translation = t.code_name
           WHERE l_search_by_text = pk_alert_constant.g_yes),
        
        -- Search filter by NOC Outcome code
        search_by_code AS
         (SELECT t.id_noc_outcome,
                 t.code_name code_translation,
                 pk_translation.get_translation(t.id_language, t.code_name) desc_translation,
                 NULL position,
                 NULL relevance
            FROM inst_outcomes t
           WHERE l_search_by_code = pk_alert_constant.g_yes
             AND t.outcome_code = l_noc_code)
        
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

    FUNCTION is_linkable_outcome_indicator
    (
        i_prof          IN profissional,
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE,
        i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE
    ) RETURN VARCHAR2 IS
        l_exists NUMBER;
    BEGIN
        SELECT count(*)
          INTO l_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM TABLE(tf_inst_indicator(i_inst        => i_prof.institution,
                                               i_soft        => i_prof.software,
                                               i_noc_outcome => i_noc_outcome)) t
                 WHERE t.id_noc_indicator = i_noc_indicator);
    
        RETURN pk_utils.bool_to_flag(l_exists > 0);
    
    END is_linkable_outcome_indicator;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_noc_cfg;
/
