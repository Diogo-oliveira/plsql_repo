/*-- Last Change Revision: $Rev: 1924514 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2019-11-15 10:44:35 +0000 (sex, 15 nov 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_nic_cfg IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations   

    FUNCTION tf_inst_intervention
    (
        i_inst                IN institution.id_institution%TYPE,
        i_soft                IN software.id_software%TYPE DEFAULT NULL,
        i_limit               IN PLS_INTEGER DEFAULT pk_nic_cfg.k_default_bulk_limit,
        i_ignore_parent_class IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_nic_cfg_intervention_coll
        PIPELINED IS
        l_nic_term_version          nic_intervention.id_terminology_version%TYPE;
        l_language                  terminology_version.id_language%TYPE;
        l_cursor                    t_nic_cfg_intervention_cur;
        l_nic_cfg_intervention_coll t_nic_cfg_intervention_coll;
    BEGIN
    
        /*
        About i_ignore_parent_class parameter:
        NIC Interventions are grouped hierarchically into classes within domains 
        but there are a few interventions located in more than one class. The table NIC_CLASS_INTERV is used to model these relationships. 
        The flag i_ignore_parent_class is used to return just the distinct NIC Interventions regardless of they are included in more than one class.
        Notice when i_ignore_parent_class = 'Y' the field id_nic_class will be null.
        */
    
        -- Retrieves the terminology version of NIC Classification configured for the institution
        BEGIN
            l_nic_term_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nic,
                                                                        i_inst             => i_inst,
                                                                        i_soft             => i_soft);
        
        EXCEPTION
            WHEN pk_nnn_core.e_missing_cfg_term_version THEN
                --This institution has no configurations to use NIC Classification
                RETURN;
        END;
    
        l_language := pk_nnn_core.get_terminology_language(i_terminology_version => l_nic_term_version);
    
        -- NIC Interventions: show all interventions without custom settings + interventions with settings defined by a given institution
        -- This approach allows us to display all classification content with default settings with no need the institution first having to manually define it.
        OPEN l_cursor FOR
            SELECT NULL                       id_nic_cfg_intervention,
                   pk_alert_constant.g_active flg_status,
                   NULL                       dt_last_update,
                   ni.id_nic_intervention,
                   ni.id_terminology_version,
                   ni.intervention_code,
                   ni.code_name,
                   ni.code_definition,
                   ni.references,
                   nci.id_nic_class,
                   l_language                 id_language
              FROM nic_intervention ni
              LEFT JOIN nic_class_interv nci
                ON nci.id_nic_intervention = ni.id_nic_intervention
               AND i_ignore_parent_class = pk_alert_constant.get_no
             WHERE ni.id_terminology_version = l_nic_term_version
               AND NOT EXISTS (SELECT 1
                      FROM nic_cfg_intervention nicfg
                     WHERE nicfg.id_nic_intervention = ni.id_nic_intervention
                       AND nicfg.id_institution = i_inst)
            UNION ALL
            SELECT nicfg.id_nic_cfg_intervention,
                   nicfg.flg_status,
                   nicfg.dt_last_update,
                   ni.id_nic_intervention,
                   ni.id_terminology_version,
                   ni.intervention_code,
                   ni.code_name,
                   ni.code_definition,
                   ni.references,
                   nci.id_nic_class,
                   l_language id_language
              FROM nic_intervention ni
              LEFT JOIN nic_class_interv nci
                ON nci.id_nic_intervention = ni.id_nic_intervention
               AND i_ignore_parent_class = pk_alert_constant.get_no
             INNER JOIN nic_cfg_intervention nicfg
                ON ni.id_nic_intervention = nicfg.id_nic_intervention
             WHERE ni.id_terminology_version = l_nic_term_version
               AND nicfg.id_institution = i_inst;
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_nic_cfg_intervention_coll LIMIT i_limit;
            EXIT WHEN l_nic_cfg_intervention_coll.count = 0;
        
            FOR i IN 1 .. l_nic_cfg_intervention_coll.count
            LOOP
                PIPE ROW(l_nic_cfg_intervention_coll(i));
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
    END tf_inst_intervention;

    FUNCTION tf_inst_activity
    (
        i_inst  IN institution.id_institution%TYPE,
        i_soft  IN software.id_software%TYPE DEFAULT NULL,
        i_limit IN PLS_INTEGER DEFAULT pk_nic_cfg.k_default_bulk_limit
    ) RETURN t_nic_cfg_activity_coll
        PIPELINED IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'tf_inst_activity';
        l_nic_term_version           nic_activity.id_terminology_version%TYPE;
        l_language                   terminology_version.id_language%TYPE;
        l_cursor                     t_nic_cfg_activity_cur;
        l_nic_cfg_activity_coll      t_nic_cfg_activity_coll;
        l_default_flg_prn            nic_cfg_activity.flg_prn%TYPE;
        l_default_flg_time           nic_cfg_activity.flg_time%TYPE;
        l_default_flg_priorty        nic_cfg_activity.flg_priority%TYPE;
        l_default_recurr_option      nic_cfg_activity.id_order_recurr_option%TYPE;
        l_default_documentation_type nic_cfg_activity.flg_doc_type%TYPE;
        l_error                      t_error_out;
    BEGIN
        -- Retrieves the terminology version of NIC Classification configured for the institution
        BEGIN
            l_nic_term_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nic,
                                                                        i_inst             => i_inst,
                                                                        i_soft             => i_soft);
        EXCEPTION
            WHEN pk_nnn_core.e_missing_cfg_term_version THEN
                --This institution has no configurations to use NIC Classification
                RETURN;
        END;
    
        l_language := pk_nnn_core.get_terminology_language(i_terminology_version => l_nic_term_version);
    
        l_default_flg_priorty := pk_nnn_core.get_default_flg_priority();
        l_default_flg_prn     := pk_nnn_core.get_default_flg_prn(i_lang => l_language);
        l_default_flg_time    := pk_nnn_core.get_default_flg_time(i_lang => l_language,
                                                                  i_inst => i_inst,
                                                                  i_soft => i_soft);
        -- By default activities are documented by free-text notes. 
        -- This can be overrided if defined by configuration to use a template or a vital sign measurement
        l_default_documentation_type := pk_nic_cfg.g_activity_doctype_free_text;
    
        IF NOT pk_order_recurrence_api_db.get_def_order_recurr_option(i_lang                   => l_language,
                                                                      i_prof                   => profissional(id          => NULL,
                                                                                                               institution => i_inst,
                                                                                                               software    => i_soft),
                                                                      i_order_recurr_area      => pk_nnn_constant.g_ordrecurr_area_nic_activity,
                                                                      o_id_order_recurr_option => l_default_recurr_option,
                                                                      o_error                  => l_error)
        THEN
            pk_alertlog.log_error(text            => 'Error retrieving default recurrence option for NIC Activity area',
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            l_default_recurr_option := pk_nnn_constant.g_order_recurr_option_once;
        END IF;
    
        -- NIC activities: show all activitys without custom settings + activitys with settings defined by a given institution
        -- This approach allows us to display all classification content with default settings with no need the institution first having to manually define it.
        OPEN l_cursor FOR
            SELECT NULL                         id_nic_cfg_activity,
                   pk_alert_constant.g_active   flg_status,
                   NULL                         dt_last_update,
                   na.id_nic_activity,
                   na.id_terminology_version,
                   NULL                         interv_activity_code,
                   na.code_description,
                   na.flg_tasklist,
                   NULL                         rank,
                   l_language                   id_language,
                   l_default_flg_prn            flg_prn,
                   NULL                         code_notes_prn,
                   l_default_flg_time           flg_time,
                   l_default_flg_priorty        flg_priority,
                   l_default_recurr_option      id_order_recurr_option,
                   l_default_documentation_type flg_doc_type,
                   NULL                         doc_parameter
              FROM nic_activity na
             WHERE na.id_terminology_version = l_nic_term_version
               AND NOT EXISTS (SELECT 1
                      FROM nic_cfg_activity cfgna
                     WHERE cfgna.id_nic_activity = na.id_nic_activity
                       AND cfgna.id_institution = i_inst)
            UNION ALL
            SELECT cfgna.id_nic_cfg_activity,
                   cfgna.flg_status,
                   cfgna.dt_last_update,
                   na.id_nic_activity,
                   na.id_terminology_version,
                   NULL interv_activity_code,
                   na.code_description,
                   na.flg_tasklist,
                   NULL rank,
                   l_language id_language,
                   cfgna.flg_prn,
                   cfgna.code_notes_prn,
                   cfgna.flg_time,
                   cfgna.flg_priority,
                   coalesce(cfgna.id_order_recurr_option, l_default_recurr_option) id_order_recurr_option,
                   cfgna.flg_doc_type,
                   cfgna.doc_parameter
              FROM nic_activity na
             INNER JOIN nic_cfg_activity cfgna
                ON na.id_nic_activity = cfgna.id_nic_activity
             WHERE na.id_terminology_version = l_nic_term_version
               AND cfgna.id_institution = i_inst;
    
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_nic_cfg_activity_coll LIMIT i_limit;
            EXIT WHEN l_nic_cfg_activity_coll.count = 0;
        
            FOR i IN 1 .. l_nic_cfg_activity_coll.count
            LOOP
                PIPE ROW(l_nic_cfg_activity_coll(i));
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
    END tf_inst_activity;

    FUNCTION tf_inst_activity
    (
        i_inst             IN institution.id_institution%TYPE,
        i_soft             IN software.id_software%TYPE DEFAULT NULL,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        i_limit            IN PLS_INTEGER DEFAULT pk_nic_cfg.k_default_bulk_limit
    ) RETURN t_nic_cfg_activity_coll
        PIPELINED IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'tf_inst_activity';
        l_nic_term_version           nic_activity.id_terminology_version%TYPE;
        l_language                   terminology_version.id_language%TYPE;
        l_cursor                     t_nic_cfg_activity_cur;
        l_nic_cfg_activity_coll      t_nic_cfg_activity_coll;
        l_default_flg_prn            nic_cfg_activity.flg_prn%TYPE;
        l_default_flg_time           nic_cfg_activity.flg_time%TYPE;
        l_default_flg_priorty        nic_cfg_activity.flg_priority%TYPE;
        l_default_recurr_option      nic_cfg_activity.id_order_recurr_option%TYPE;
        l_default_documentation_type nic_cfg_activity.flg_doc_type%TYPE;
        l_error                      t_error_out;
    BEGIN
        -- Retrieves the terminology version of NIC Classification configured for the institution
        BEGIN
            l_nic_term_version := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nic,
                                                                        i_inst             => i_inst,
                                                                        i_soft             => i_soft);
        EXCEPTION
            WHEN pk_nnn_core.e_missing_cfg_term_version THEN
                --This institution has no configurations to use NIC Classification
                RETURN;
        END;
    
        l_language := pk_nnn_core.get_terminology_language(i_terminology_version => l_nic_term_version);
    
        l_default_flg_priorty := pk_nnn_core.get_default_flg_priority();
        l_default_flg_prn     := pk_nnn_core.get_default_flg_prn(i_lang => l_language);
        l_default_flg_time    := pk_nnn_core.get_default_flg_time(i_lang => l_language,
                                                                  i_inst => i_inst,
                                                                  i_soft => i_soft);
        -- By default activities are documented by free-text notes. 
        -- This can be overrided if defined by configuration to use a template or a vital sign measurement
        l_default_documentation_type := pk_nic_cfg.g_activity_doctype_free_text;
    
        IF NOT pk_order_recurrence_api_db.get_def_order_recurr_option(i_lang                   => l_language,
                                                                      i_prof                   => profissional(id          => NULL,
                                                                                                               institution => i_inst,
                                                                                                               software    => i_soft),
                                                                      i_order_recurr_area      => pk_nnn_constant.g_ordrecurr_area_nic_activity,
                                                                      o_id_order_recurr_option => l_default_recurr_option,
                                                                      o_error                  => l_error)
        THEN
            pk_alertlog.log_error(text            => 'Error retrieving default recurrence option for NIC Activity area',
                                  object_name     => g_package,
                                  sub_object_name => k_function_name);
            l_default_recurr_option := pk_nnn_constant.g_order_recurr_option_once;
        END IF;
    
        -- NIC activities: show all activitys without custom settings + activitys with settings defined by a given institution
        -- This approach allows us to display all classification content with default settings with no need the institution first having to manually define it.
        OPEN l_cursor FOR
            SELECT NULL                         id_nic_cfg_activity,
                   pk_alert_constant.g_active   flg_status,
                   NULL                         dt_last_update,
                   na.id_nic_activity,
                   na.id_terminology_version,
                   nia.interv_activity_code, -- The "real" NIC Activity code (because in the NIC classification a same activity have different codes according to the intervention)
                   na.code_description,
                   na.flg_tasklist,
                   nia.rank,
                   l_language                   id_language,
                   l_default_flg_prn            flg_prn,
                   NULL                         code_notes_prn,
                   l_default_flg_time           flg_time,
                   l_default_flg_priorty        flg_priority,
                   l_default_recurr_option      id_order_recurr_option,
                   l_default_documentation_type flg_doc_type,
                   NULL                         doc_parameter
              FROM nic_activity na
             INNER JOIN nic_interv_activity nia
                ON na.id_nic_activity = nia.id_nic_activity
             WHERE na.id_terminology_version = l_nic_term_version
               AND nia.id_nic_intervention = i_nic_intervention
               AND nia.flg_task = pk_alert_constant.g_no --  Activities defined as tasks does not appear in the listings to be ordered.
                  
               AND NOT EXISTS (SELECT 1
                      FROM nic_cfg_activity cfgna
                     WHERE cfgna.id_nic_activity = na.id_nic_activity
                       AND cfgna.id_institution = i_inst)
            UNION ALL
            SELECT cfgna.id_nic_cfg_activity,
                   cfgna.flg_status,
                   cfgna.dt_last_update,
                   na.id_nic_activity,
                   na.id_terminology_version,
                   nia.interv_activity_code, -- The "real" NIC Activity code (because in the NIC classification a same activity have different codes according to the intervention)
                   na.code_description,
                   na.flg_tasklist,
                   nia.rank,
                   l_language id_language,
                   cfgna.flg_prn,
                   cfgna.code_notes_prn,
                   cfgna.flg_time,
                   cfgna.flg_priority,
                   coalesce(cfgna.id_order_recurr_option, l_default_recurr_option) id_order_recurr_option,
                   cfgna.flg_doc_type,
                   cfgna.doc_parameter
              FROM nic_activity na
             INNER JOIN nic_interv_activity nia
                ON na.id_nic_activity = nia.id_nic_activity
             INNER JOIN nic_cfg_activity cfgna
                ON na.id_nic_activity = cfgna.id_nic_activity
             WHERE na.id_terminology_version = l_nic_term_version
               AND cfgna.id_institution = i_inst
               AND nia.id_nic_intervention = i_nic_intervention
               AND nia.flg_task = pk_alert_constant.g_no --  Activities defined as tasks does not appear in the listings to be ordered.
               AND NOT EXISTS (SELECT 1 -- Verifies the relationship between Intervention and Activity was not cancelled by the institution
                      FROM nic_cfg_interv_actv cfgnia
                     WHERE cfgnia.id_institution = i_inst
                       AND cfgnia.id_nic_intervention = nia.id_nic_intervention
                       AND cfgnia.id_nic_activity = nia.id_nic_activity
                       AND cfgnia.flg_lnk_status = pk_alert_constant.g_cancelled);
    
        LOOP
            FETCH l_cursor BULK COLLECT
                INTO l_nic_cfg_activity_coll LIMIT i_limit;
            EXIT WHEN l_nic_cfg_activity_coll.count = 0;
        
            FOR i IN 1 .. l_nic_cfg_activity_coll.count
            LOOP
                PIPE ROW(l_nic_cfg_activity_coll(i));
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
    END tf_inst_activity;

    PROCEDURE get_inst_interventions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_include_inactive IN nan_cfg_diagnosis.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_interventions    OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_inst_interventions';
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
    
        SELECT COUNT(*)
          INTO l_total_items
          FROM TABLE(tf_inst_intervention(i_inst                => i_prof.institution,
                                          i_soft                => i_prof.software,
                                          i_ignore_parent_class => pk_alert_constant.g_yes)) x
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
    
        OPEN o_interventions FOR
            SELECT x.id_nic_cfg_intervention,
                   x.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, x.dt_last_update, i_prof) dt_last_update_str,
                   x.id_nic_intervention,
                   x.id_terminology_version,
                   x.intervention_code,
                   x.intervention_name,
                   pk_translation.get_translation(i_lang, x.code_definition) intervention_definition,
                   x.references,
                   x.id_nic_class
              FROM (SELECT /*+ first_rows(10) */
                     row_number() over(ORDER BY nicfg.intervention_name) rn,
                     nicfg.id_nic_cfg_intervention,
                     nicfg.flg_status,
                     nicfg.dt_last_update,
                     nicfg.id_nic_intervention,
                     nicfg.id_terminology_version,
                     nicfg.intervention_code,
                     nicfg.intervention_name,
                     nicfg.code_definition,
                     nicfg.references,
                     nicfg.id_nic_class
                      FROM (SELECT pk_translation.get_translation(i_lang, tf.code_name) intervention_name, tf.*
                              FROM TABLE(tf_inst_intervention(i_inst                => i_prof.institution,
                                                              i_soft                => i_prof.software,
                                                              i_ignore_parent_class => pk_alert_constant.g_yes)) tf
                             WHERE tf.flg_status = pk_alert_constant.g_active
                                OR (tf.flg_status = pk_alert_constant.g_inactive AND
                                   i_include_inactive = pk_alert_constant.g_yes)) nicfg) x
             WHERE x.rn BETWEEN l_startindex AND (l_startindex + l_items_per_page - 1)
             ORDER BY rn;
    
    END get_inst_interventions;

    PROCEDURE get_inst_interventions
    (
        i_prof          IN profissional,
        i_noc_outcome   IN noc_outcome.id_noc_outcome %TYPE,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_interventions OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_inst_interventions';
        l_termi_vers_nnn_lnk nan_noc_nic_linkage.id_terminology_version%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_noc_outcome = ' || coalesce(to_char(i_noc_outcome), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- get the Terminology Version ID configured to being used for NNN-Linkages
        l_termi_vers_nnn_lnk := pk_nnn_core.get_inst_nnn_term_version(i_terminology_name => pk_nnn_constant.g_terminology_nnn_linkages,
                                                                      i_inst             => i_prof.institution,
                                                                      i_soft             => i_prof.software);
        OPEN o_interventions FOR
            SELECT nic.id_nic_intervention,
                   nic.intervention_code,
                   pk_nic_model.format_nic_name(i_label       => pk_translation.get_translation(nic.id_language,
                                                                                                nic.code_name),
                                                i_nic_code    => nic.intervention_code,
                                                i_code_format => pk_nic_model.g_code_format_end) intervention_name,
                   pk_translation.get_translation(nic.id_language, nic.code_definition) intervention_definition,
                   nnnl.flg_nic_link_type flg_link_type,
                   pk_sysdomain.get_domain_cached(i_lang        => nic.id_language,
                                                  i_value       => nnnl.flg_nic_link_type,
                                                  i_code_domain => pk_nnn_lnk_model.g_dom_nnn_lnk_flg_link_type) desc_flg_link_type,
                   pk_sysdomain.get_rank(i_lang     => nic.id_language,
                                         i_code_dom => pk_nnn_lnk_model.g_dom_nnn_lnk_flg_link_type,
                                         i_val      => nnnl.flg_nic_link_type) rank
              FROM (SELECT tf.id_nic_intervention,
                           tf.intervention_code,
                           tf.id_language,
                           tf.code_name,
                           tf.code_definition
                      FROM TABLE(pk_nic_cfg.tf_inst_intervention(i_inst                => i_prof.institution,
                                                                 i_soft                => i_prof.software,
                                                                 i_ignore_parent_class => pk_alert_constant.g_yes)) tf
                     WHERE tf.flg_status = pk_alert_constant.g_active) nic
             INNER JOIN (SELECT nnnl.intervention_code, nnnl.flg_nic_link_type
                           FROM nan_noc_nic_linkage nnnl
                          INNER JOIN noc_outcome no
                             ON no.outcome_code = nnnl.outcome_code
                          INNER JOIN nan_diagnosis nd
                             ON nd.diagnosis_code = nnnl.diagnosis_code
                          WHERE no.id_noc_outcome = i_noc_outcome
                            AND nd.id_nan_diagnosis = i_nan_diagnosis
                            AND nnnl.id_terminology_version = l_termi_vers_nnn_lnk) nnnl
                ON nic.intervention_code = nnnl.intervention_code
             ORDER BY rank, intervention_name;
    END get_inst_interventions;

    PROCEDURE get_inst_interventions
    (
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_interventions OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_inst_interventions';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_nan_diagnosis = ' || coalesce(to_char(i_nan_diagnosis), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- NANDA-NIC Linkages (using implicitly the terminology version of NIC Classification configured for the institution)
        OPEN o_interventions FOR
            SELECT nic.id_nic_intervention,
                   nic.intervention_code,
                   pk_nic_model.format_nic_name(i_label       => pk_translation.get_translation(nic.id_language,
                                                                                                nic.code_name),
                                                i_nic_code    => nic.intervention_code,
                                                i_code_format => pk_nic_model.g_code_format_end) intervention_name,
                   pk_translation.get_translation(nic.id_language, nic.code_definition) intervention_definition,
                   nnl.flg_link_type,
                   pk_sysdomain.get_domain_cached(i_lang        => nic.id_language,
                                                  i_value       => nnl.flg_link_type,
                                                  i_code_domain => pk_nnn_lnk_model.g_dom_nannic_lnk_flg_link_type) desc_flg_link_type,
                   pk_sysdomain.get_rank(i_lang     => nic.id_language,
                                         i_code_dom => pk_nnn_lnk_model.g_dom_nannic_lnk_flg_link_type,
                                         i_val      => nnl.flg_link_type) rank
              FROM (SELECT tf.id_nic_intervention,
                           tf.intervention_code,
                           tf.id_language,
                           tf.code_name,
                           tf.code_definition
                      FROM TABLE(pk_nic_cfg.tf_inst_intervention(i_inst                => i_prof.institution,
                                                                 i_soft                => i_prof.software,
                                                                 i_ignore_parent_class => pk_alert_constant.g_yes)) tf
                     WHERE tf.flg_status = pk_alert_constant.g_active) nic
             INNER JOIN (SELECT nnl.id_nic_intervention, nnl.flg_link_type
                           FROM nan_nic_linkage nnl
                          INNER JOIN nan_diagnosis nd
                             ON nd.diagnosis_code = nnl.diagnosis_code
                          WHERE nd.id_nan_diagnosis = i_nan_diagnosis) nnl
                ON nic.id_nic_intervention = nnl.id_nic_intervention
             ORDER BY rank, intervention_name;
    
    END get_inst_interventions;

    PROCEDURE get_inst_activities
    (
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        o_activities       OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_inst_activities';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_prof.institution), '<null>');
        g_error := g_error || ' i_nic_intervention = ' || coalesce(to_char(i_nic_intervention), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        OPEN o_activities FOR
            SELECT tf.id_nic_activity,
                   pk_translation.get_translation(tf.id_language, tf.code_description) activity_name
              FROM TABLE(tf_inst_activity(i_inst             => i_prof.institution,
                                          i_soft             => i_prof.software,
                                          i_nic_intervention => i_nic_intervention)) tf
             WHERE tf.flg_status = pk_alert_constant.g_active
             ORDER BY tf.rank, activity_name;
    
    END get_inst_activities;

    PROCEDURE get_inst_activities
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_include_inactive IN nan_cfg_diagnosis.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_activities       OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_inst_activities';
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
    
        SELECT COUNT(*)
          INTO l_total_items
          FROM TABLE(tf_inst_activity(i_inst => i_prof.institution, i_soft => i_prof.software)) x
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
    
        OPEN o_activities FOR
            SELECT x.id_nic_cfg_activity,
                   x.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, x.dt_last_update, i_prof) dt_last_update_str,
                   x.id_nic_activity,
                   x.id_terminology_version,
                   pk_translation.get_translation(i_lang, x.code_description) activity_name,
                   x.rank
              FROM (SELECT /*+ first_rows(10) */
                     row_number() over(ORDER BY nicfg.activity_name) rn,
                     nicfg.id_nic_cfg_activity,
                     nicfg.flg_status,
                     nicfg.dt_last_update,
                     nicfg.id_nic_activity,
                     nicfg.id_terminology_version,
                     nicfg.code_description,
                     nicfg.rank
                      FROM (SELECT pk_translation.get_translation(i_lang, tf.code_description) activity_name, tf.*
                              FROM TABLE(tf_inst_activity(i_inst => i_prof.institution, i_soft => i_prof.software)) tf
                             WHERE tf.flg_status = pk_alert_constant.g_active
                                OR (tf.flg_status = pk_alert_constant.g_inactive AND
                                   i_include_inactive = pk_alert_constant.g_yes)) nicfg) x
             WHERE x.rn BETWEEN l_startindex AND (l_startindex + l_items_per_page - 1)
             ORDER BY rn;
    
    END get_inst_activities;

    PROCEDURE get_inst_activity_tasks
    (
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        i_nic_activity     IN nic_activity.id_nic_activity%TYPE,
        o_activity_tasks   OUT pk_types.cursor_type
    ) IS
    BEGIN
        OPEN o_activity_tasks FOR
            SELECT t.id_nic_activity, t.activity_name
              FROM (
                    -- NIC activity tasks: show all activities defined as tasks without custom settings + activitys with settings defined by a given institution        
                    SELECT nia.id_nic_activity,
                            pk_nic_model.get_activity_name(i_nic_activity => nia.id_nic_activity) activity_name,
                            nia.rank
                      FROM nic_interv_activity nia
                     WHERE nia.id_nic_intervention = i_nic_intervention
                       AND nia.flg_task = pk_alert_constant.g_yes
                     START WITH nia.id_nic_activity = i_nic_activity
                    CONNECT BY PRIOR nia.id_nic_interv_activity = nia.id_parent
                           AND NOT EXISTS (SELECT 1
                                  FROM nic_cfg_activity cfgna
                                 WHERE cfgna.id_nic_activity = nia.id_nic_activity
                                   AND cfgna.id_institution = i_prof.institution)
                    UNION ALL
                    SELECT nia.id_nic_activity,
                            pk_nic_model.get_activity_name(i_nic_activity => nia.id_nic_activity) activity_name,
                            nia.rank
                      FROM nic_interv_activity nia
                     INNER JOIN nic_cfg_activity cfgna
                        ON nia.id_nic_activity = cfgna.id_nic_activity
                     WHERE nia.id_nic_intervention = i_nic_intervention
                       AND nia.flg_task = pk_alert_constant.g_yes --  Activities defined as tasks             
                       AND cfgna.id_institution = i_prof.institution
                       AND cfgna.flg_status = pk_alert_constant.g_active -- Activity in this institution is active
                     START WITH nia.id_nic_activity = i_nic_activity
                    CONNECT BY PRIOR nia.id_nic_interv_activity = nia.id_parent
                           AND NOT EXISTS
                     (SELECT 1 -- Verifies the relationship between Intervention and Activity was not cancelled by the institution
                                  FROM nic_cfg_interv_actv cfgnia
                                 WHERE cfgnia.id_institution = i_prof.institution
                                   AND cfgnia.id_nic_intervention = nia.id_nic_intervention
                                   AND cfgnia.id_nic_activity = nia.id_nic_activity
                                   AND cfgnia.flg_lnk_status = pk_alert_constant.g_cancelled)) t
             ORDER BY t.rank, t.activity_name;
    
    END get_inst_activity_tasks;

    PROCEDURE set_inst_intervention_status
    (
        i_institution      IN nic_cfg_intervention.id_institution%TYPE,
        i_nic_intervention IN nic_cfg_intervention.id_nic_intervention%TYPE,
        i_flg_status       IN nic_cfg_intervention.flg_status%TYPE
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_inst_intervention_status';
        l_nic_cfg_intervention nic_cfg_intervention.id_nic_cfg_intervention%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_institution), '<null>');
        g_error := g_error || ' i_nic_intervention = ' || coalesce(to_char(i_nic_intervention), '<null>');
        g_error := g_error || ' i_flg_status = ' || coalesce(to_char(i_flg_status), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Checks if the Intervention already exists in NIC_CFG_INTERVENTION table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT ncfg.id_nic_cfg_intervention
              INTO l_nic_cfg_intervention
              FROM nic_cfg_intervention ncfg
             WHERE ncfg.id_institution = i_institution
               AND ncfg.id_nic_intervention = i_nic_intervention;
        
            ts_nic_cfg_intervention.upd(id_nic_cfg_intervention_in => l_nic_cfg_intervention,
                                        flg_status_in              => i_flg_status,
                                        dt_last_update_in          => current_timestamp);
        EXCEPTION
            WHEN no_data_found THEN
                ts_nic_cfg_intervention.ins(id_institution_in      => i_institution,
                                            id_nic_intervention_in => i_nic_intervention,
                                            flg_status_in          => i_flg_status,
                                            dt_last_update_in      => current_timestamp);
        END;
    END set_inst_intervention_status;

    PROCEDURE set_inst_activity_status
    (
        i_institution  IN nic_cfg_activity.id_institution%TYPE,
        i_nic_activity IN nic_cfg_activity.id_nic_activity%TYPE,
        i_flg_status   IN nic_cfg_activity.flg_status%TYPE
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'set_inst_activity_status';
        l_nic_cfg_activity nic_cfg_activity.id_nic_cfg_activity%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_institution = ' || coalesce(to_char(i_institution), '<null>');
        g_error := g_error || ' i_nic_activity = ' || coalesce(to_char(i_nic_activity), '<null>');
        g_error := g_error || ' i_flg_status = ' || coalesce(to_char(i_flg_status), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Checks if the Activity already exists in NIC_CFG_ACTIVITY table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT ncfg.id_nic_cfg_activity
              INTO l_nic_cfg_activity
              FROM nic_cfg_activity ncfg
             WHERE ncfg.id_institution = i_institution
               AND ncfg.id_nic_activity = i_nic_activity;
        
            ts_nic_cfg_activity.upd(id_nic_cfg_activity_in => l_nic_cfg_activity,
                                    flg_status_in          => i_flg_status,
                                    dt_last_update_in      => current_timestamp);
        EXCEPTION
            WHEN no_data_found THEN
                ts_nic_cfg_activity.ins(id_institution_in  => i_institution,
                                        id_nic_activity_in => i_nic_activity,
                                        flg_status_in      => i_flg_status,
                                        dt_last_update_in  => current_timestamp);
        END;
    END set_inst_activity_status;

    PROCEDURE init_fltr_params_nic
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
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
                o_id := pk_nnn_core.get_terminology_language(i_terminology_name => pk_nnn_constant.g_terminology_nic,
                                                             i_inst             => l_prof.institution,
                                                             i_soft             => l_prof.software);
            WHEN 'i_code_format' THEN
                --TODO: This can be configurable by using a SYS_CONFIG in order to display or not the NANDA Code in search results
                -- Suggestion: create a new constant (flag) like g_code_format_cfg_search and modify the function pk_nan_model.format_nanda_name 
                -- to recongize this flag and evaluate the format settings.
                o_vc2 := pk_nic_model.g_code_format_end;
        END CASE;
    
    END init_fltr_params_nic;

    FUNCTION get_search_by_code_or_text
    (
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE,
        i_search IN pk_translation.t_desc
    ) RETURN table_t_search IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_search_by_code_or_text';
        l_out_rec              table_t_search := table_t_search(NULL);
        l_search               pk_translation.t_desc;
        l_nic_code             nic_intervention.intervention_code%TYPE;
        l_search_by_text       VARCHAR(1 CHAR) := pk_alert_constant.g_yes;
        l_search_by_code       VARCHAR(1 CHAR) := pk_alert_constant.g_yes;
        l_terminology_language terminology_version.id_language%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_inst = ' || coalesce(to_char(i_inst), '<null>');
        g_error := g_error || ' i_soft = ' || coalesce(to_char(i_soft), '<null>');
        g_error := g_error || ' i_search = ' || coalesce(i_search, '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- Language of the NIC terminology that is configured for this institution/software 
        -- Is used this var because the following SQL query can not reference the t.id_language in the inner query with which is joined.
        l_terminology_language := pk_nnn_core.get_terminology_language(i_terminology_name => pk_nnn_constant.g_terminology_nic,
                                                                       i_inst             => i_inst,
                                                                       i_soft             => i_soft);
    
        -- Evaluate if the search value is a number. 
        -- If so it enable to seach by NIC code, otherwise it is disabled.
        BEGIN
            l_search   := pk_lucene.escape_special_characters(i_string       => i_search,
                                                              i_use_wildcard => pk_alert_constant.g_no);
            l_nic_code := to_number(l_search);
        EXCEPTION
            WHEN OTHERS THEN
                l_search_by_code := pk_alert_constant.g_no;
        END;
    
        -- NIC Interventions     
        WITH inst_interventions AS
         (SELECT /*+ materialize */
           t.*
            FROM TABLE(tf_inst_intervention(i_inst                => i_inst,
                                            i_soft                => i_soft,
                                            i_ignore_parent_class => pk_alert_constant.g_yes)) t),
        
        -- Search filter by NIC label
        search_by_text AS
         (SELECT /*+ materialize */
           t.id_nic_intervention, lucne.code_translation, lucne.desc_translation, lucne.position, lucne.relevance
            FROM inst_interventions t
            JOIN (SELECT /*+opt_estimate(table a rows=1)*/
                  a.code_translation, a.desc_translation, a.position, a.relevance
                   FROM TABLE(pk_translation.get_search_translation(i_lang        => l_terminology_language,
                                                                    i_search      => i_search,
                                                                    i_column_name => 'NIC_INTERVENTION.CODE_NAME')) a) lucne
              ON lucne.code_translation = t.code_name
           WHERE l_search_by_text = pk_alert_constant.g_yes),
        
        -- Search filter by NIC code
        search_by_code AS
         (SELECT t.id_nic_intervention,
                 t.code_name code_translation,
                 pk_translation.get_translation(t.id_language, t.code_name) desc_translation,
                 NULL position,
                 NULL relevance
            FROM inst_interventions t
           WHERE l_search_by_code = pk_alert_constant.g_yes
             AND t.intervention_code = l_nic_code)
        
        -- Main query
        SELECT t_search(code_translation => t.code_translation,
                        desc_translation => t.desc_translation,
                        position         => t.position,
                        relevance        => t.relevance)
          BULK COLLECT
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

    FUNCTION is_linkable_interv_activity
    (
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        i_nic_activity     IN nic_activity.id_nic_activity%TYPE
    ) RETURN VARCHAR2 IS
        l_exists NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO l_exists
          FROM dual
         WHERE EXISTS (SELECT 1
                  FROM TABLE(tf_inst_activity(i_inst             => i_prof.institution,
                                              i_soft             => i_prof.software,
                                              i_nic_intervention => i_nic_intervention)) t
                 WHERE t.id_nic_activity = i_nic_activity);
    
        RETURN pk_utils.bool_to_flag(l_exists > 0);
    
    END is_linkable_interv_activity;

    FUNCTION get_activity_doctype
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_nic_activity IN nic_activity.id_nic_activity%TYPE
    ) RETURN t_nic_activity_doctype IS
        l_activity_doctype t_nic_activity_doctype;
    BEGIN
        SELECT na.flg_tasklist,
               cfgna.flg_doc_type,
               pk_sysdomain.get_domain(i_code_dom => pk_nic_cfg.g_dom_activity_flg_doc_type,
                                       i_val      => cfgna.flg_doc_type,
                                       i_lang     => i_lang) desc_doc_type,
               cfgna.doc_parameter,
               CASE cfgna.flg_doc_type
                   WHEN pk_nic_cfg.g_activity_doctype_template THEN
                    pk_touch_option_out.get_doc_template_desc(i_lang => i_lang, i_doc_template => cfgna.doc_parameter)
                   WHEN pk_nic_cfg.g_activity_doctype_vital_sign THEN
                    pk_vital_sign.get_vs_desc(i_lang       => i_lang,
                                              i_vital_sign => cfgna.doc_parameter,
                                              i_short_desc => pk_alert_constant.get_no)
                   WHEN pk_nic_cfg.g_activity_doctype_biometrics THEN
                    pk_vital_sign.get_vs_desc(i_lang       => i_lang,
                                              i_vital_sign => cfgna.doc_parameter,
                                              i_short_desc => pk_alert_constant.get_no)
                   ELSE
                    NULL
               END desc_doc_parameter,
               CASE cfgna.flg_doc_type
                   WHEN pk_nic_cfg.g_activity_doctype_template THEN
                   -- This doc_area is used to document activities using Touch-Option templates
                    pk_nnn_constant.g_doc_area_nic_activity
                   WHEN pk_nic_cfg.g_activity_doctype_free_text THEN
                   -- Free text documentation also uses Touch-option documentation to save data
                    pk_nnn_constant.g_doc_area_nic_activity
                   ELSE
                   -- May be possible in a future to document NIC Activities by using templates of other areas
                    NULL
               END id_doc_area
          INTO l_activity_doctype.flg_tasklist,
               l_activity_doctype.flg_doc_type,
               l_activity_doctype.desc_doc_type,
               l_activity_doctype.doc_parameter,
               l_activity_doctype.desc_doc_parameter,
               l_activity_doctype.id_doc_area
          FROM nic_cfg_activity cfgna
         INNER JOIN nic_activity na
            ON na.id_nic_activity = cfgna.id_nic_activity
         WHERE cfgna.id_institution = i_prof.institution
           AND cfgna.id_nic_activity = i_nic_activity;
    
        RETURN l_activity_doctype;
    
    EXCEPTION
        WHEN no_data_found THEN
            -- If not local configuration found, by default (except if activity is a tasklist) the documentation is done in free-text
            SELECT na.flg_tasklist,
                   pk_nic_cfg.g_activity_doctype_free_text flg_doc_type,
                   pk_sysdomain.get_domain(i_code_dom => pk_nic_cfg.g_dom_activity_flg_doc_type,
                                           i_val      => pk_nic_cfg.g_activity_doctype_free_text,
                                           i_lang     => i_lang) desc_doc_type
              INTO l_activity_doctype.flg_tasklist, l_activity_doctype.flg_doc_type, l_activity_doctype.desc_doc_type
              FROM nic_activity na
             WHERE na.id_nic_activity = i_nic_activity;
        
            RETURN l_activity_doctype;
    END get_activity_doctype;

    PROCEDURE get_activity_avg_duration
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_nic_activity IN nic_activity.id_nic_activity%TYPE,
        o_avg_duration OUT nic_cfg_activity.avg_duration%TYPE,
        o_uom_duration OUT nic_cfg_activity.id_unit_measure_duration%TYPE
    ) IS
        -- By default duration is zero minutes
        l_def_avg_duration CONSTANT nic_cfg_activity.avg_duration%TYPE := 0;
        l_def_uom_duration CONSTANT nic_cfg_activity.id_unit_measure_duration%TYPE := pk_order_recurrence_core.g_unit_measure_minute;
    BEGIN
        SELECT coalesce(cfgna.avg_duration, l_def_avg_duration) avg_duration,
               coalesce(cfgna.id_unit_measure_duration, l_def_uom_duration) uom_duration
          INTO o_avg_duration, o_uom_duration
          FROM nic_cfg_activity cfgna
         INNER JOIN nic_activity na
            ON na.id_nic_activity = cfgna.id_nic_activity
         WHERE cfgna.id_institution = i_prof.institution
           AND cfgna.id_nic_activity = i_nic_activity;
    
    EXCEPTION
        WHEN no_data_found THEN
            -- If not local configuration found, assumes default duration
            o_avg_duration := l_def_avg_duration;
            o_uom_duration := l_def_uom_duration;
    END get_activity_avg_duration;

    PROCEDURE get_activity_supplies
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_nic_activity IN nic_activity.id_nic_activity%TYPE,
        o_supplies     OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_activity_supplies';
        l_error t_error_out;
    
    BEGIN
        OPEN o_supplies FOR
            SELECT cfgas.id_supply,
                   cfgas.quantity,
                   pk_supplies_external_api_db.get_supply_desc(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_id_supply => cfgas.id_supply) desc_supply
              FROM nic_cfg_actv_supply cfgas
             WHERE cfgas.id_institution = i_prof.institution
               AND cfgas.id_nic_activity = i_nic_activity;
    
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'CALL pk_supplies_api_db.get_supplies_by_context';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            IF NOT pk_supplies_api_db.get_supplies_by_context(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_context  => table_varchar(i_nic_activity),
                                                              i_flg_context => pk_supplies_constant.g_context_nic_activity,
                                                              o_supplies    => o_supplies,
                                                              o_error       => l_error)
            THEN
                RAISE pk_nnn_constant.e_call_error;
            END IF;
    END get_activity_supplies;

    FUNCTION tf_nic_activity_supply
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_lst_nic_activity IN table_number
    ) RETURN t_coll_obj_nic_activity_supply IS
        l_lst_obj t_coll_obj_nic_activity_supply;
    BEGIN
    
        -- NIC activities supplies: return supplies defined in table nic_cfg_actv_supply by a given list of activities  
        -- If supplies not defined in table nic_cfg_actv_supply go to table supply_context          
        SELECT t_obj_nic_activity_supply(i_id_context          => NULL,
                                         i_id_supply           => NULL,
                                         i_id_supply_set       => NULL,
                                         i_id_supply_soft_inst => NULL,
                                         i_desc_supply         => NULL,
                                         i_desc_supply_set     => NULL,
                                         i_quantity            => NULL,
                                         i_dt_return           => NULL)
          BULK COLLECT
          INTO l_lst_obj
          FROM (SELECT sc.id_context,
                       nvl(si.id_supply, s.id_supply) id_supply,
                       pk_translation.get_translation(i_lang, nvl(si.code_supply, s.code_supply)) desc_supply,
                       sc.quantity quantity,
                       NULL dt_return,
                       (SELECT id_supply_soft_inst
                          FROM supply_soft_inst
                         WHERE id_supply = sc.id_supply
                           AND nvl(id_institution, 0) IN (0, i_prof.institution)
                           AND nvl(id_software, 0) IN (i_prof.software, 0)) id_supply_soft_inst
                
                  FROM supply_context sc
                  LEFT JOIN supply s
                    ON s.id_supply = sc.id_supply
                  LEFT JOIN supply_relation sr
                    ON sr.id_supply = s.id_supply
                  LEFT JOIN supply si
                    ON si.id_supply = sr.id_supply_item
                  JOIN TABLE(i_lst_nic_activity) id_c
                    ON id_c.column_value = sc.id_context
                 WHERE nvl(sc.id_professional, 0) IN (0, i_prof.id)
                   AND nvl(sc.id_institution, 0) IN (0, i_prof.institution)
                   AND nvl(sc.id_software, 0) IN (0, i_prof.software)
                   AND sc.flg_context = pk_supplies_constant.g_context_nic_activity
                   AND (nvl2(si.id_supply, s.id_supply, NULL) IS NULL OR
                        s.flg_type = pk_supplies_constant.g_supply_set_type)
                UNION ALL
                SELECT sc.id_context,
                       s.id_supply id_supply,
                       pk_translation.get_translation(i_lang, s.code_supply) desc_supply,
                       sc.quantity quantity,
                       NULL dt_return,
                       (SELECT id_supply_soft_inst
                          FROM supply_soft_inst
                         WHERE id_supply = sc.id_supply
                           AND nvl(id_institution, 0) IN (0, i_prof.institution)
                           AND nvl(id_software, 0) IN (i_prof.software, 0)) id_supply_soft_inst
                  FROM supply_context sc
                  LEFT JOIN supply s
                    ON s.id_supply = sc.id_supply
                  JOIN TABLE(i_lst_nic_activity) id_c
                    ON id_c.column_value = sc.id_context
                 WHERE nvl(sc.id_professional, 0) IN (0, i_prof.id)
                   AND nvl(sc.id_institution, 0) IN (0, i_prof.institution)
                   AND nvl(sc.id_software, 0) IN (0, i_prof.software)
                   AND sc.flg_context = pk_supplies_constant.g_context_nic_activity
                   AND s.flg_type IN (pk_supplies_constant.g_supply_kit_type, pk_supplies_constant.g_supply_set_type)
                   AND NOT EXISTS (SELECT 1
                          FROM nic_cfg_actv_supply cfgas
                         WHERE cfgas.id_nic_activity = sc.id_context
                           AND cfgas.id_institution = i_prof.institution)
                UNION ALL
                SELECT to_char(cfgas.id_nic_activity) id_context,
                       cfgas.id_supply,
                       pk_supplies_external_api_db.get_supply_desc(i_lang      => i_lang,
                                                                   i_prof      => i_prof,
                                                                   i_id_supply => cfgas.id_supply) desc_supply,
                       cfgas.quantity,
                       NULL dt_return,
                       (SELECT id_supply_soft_inst
                          FROM supply_soft_inst
                         WHERE id_supply = cfgas.id_supply
                           AND nvl(id_institution, 0) IN (0, i_prof.institution)
                           AND nvl(id_software, 0) IN (i_prof.software, 0)) id_supply_soft_inst
                  FROM nic_cfg_actv_supply cfgas
                 INNER JOIN TABLE(i_lst_nic_activity) t
                    ON t.column_value = cfgas.id_nic_activity
                 WHERE cfgas.id_institution = i_prof.institution) t;
    
        RETURN l_lst_obj;
    END tf_nic_activity_supply;

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_nic_cfg;
/
