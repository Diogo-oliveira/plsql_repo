/*-- Last Change Revision: $Rev: 1658139 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:24:35 +0000 (seg, 10 nov 2014) $*/
CREATE OR REPLACE PACKAGE BODY pk_noc_model IS

    -- Private type declarations

    -- Private constant declarations
    k_dom_scale_level_none CONSTANT pk_translation.t_code := 'NOC_SCALE_LEVEL.CODE_NOC_SCALE_LEVEL.0';

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    PROCEDURE insert_into_noc_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN noc_domain.id_terminology_version%TYPE,
        i_domain_code         IN noc_domain.domain_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN noc_domain.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN noc_domain.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN noc_domain.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN noc_domain.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_noc_domain';
        l_rec       noc_domain%ROWTYPE;
        l_lst_rowid table_varchar;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_domain_code = ' || coalesce(i_domain_code, '<null>');
        g_error := g_error || ' i_name = ' || coalesce(i_name, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.domain_code            := i_domain_code;
        l_rec.rank                   := i_rank;
        l_rec.id_inst_owner          := i_inst_owner;
        l_rec.id_concept_version     := i_concept_version;
        l_rec.id_concept_term        := i_concept_term;
    
        BEGIN
            -- Insert-optimistic
            ts_noc_domain.ins(rec_in => l_rec, gen_pky_in => TRUE, handle_error_in => FALSE, rows_out => l_lst_rowid);
        
            SELECT nd.code_name, nd.code_definition
              INTO l_rec.code_name, l_rec.code_definition
              FROM noc_domain nd
             WHERE nd.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT nd.id_noc_domain, nd.code_name, nd.code_definition
                  INTO l_rec.id_noc_domain, l_rec.code_name, l_rec.code_definition
                  FROM noc_domain nd
                 WHERE nd.id_terminology_version = l_rec.id_terminology_version
                   AND nd.domain_code = l_rec.domain_code;
            
                ts_noc_domain.upd(rec_in => l_rec);
            
        END;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_name,
                                               i_desc_trans => i_name);
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_definition,
                                               i_desc_trans => i_definition);
    
    END insert_into_noc_domain;

    PROCEDURE insert_into_noc_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN noc_class.id_terminology_version%TYPE,
        i_domain_code         IN noc_domain.domain_code%TYPE,
        i_class_code          IN noc_class.class_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN noc_class.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN noc_class.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN noc_class.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN noc_class.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_noc_class';
        l_rec       noc_class%ROWTYPE;
        l_lst_rowid table_varchar;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_domain_code = ' || coalesce(i_domain_code, '<null>');
        g_error := g_error || ' i_class_code = ' || coalesce(i_class_code, '<null>');
        g_error := g_error || ' i_name = ' || coalesce(i_name, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NOC Domain to which NOC Class belongs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT id_noc_domain
              INTO l_rec.id_noc_domain
              FROM noc_domain nd
             WHERE nd.id_terminology_version = i_terminology_version
               AND nd.domain_code = i_domain_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NOC Domain Code not found in NOC_DOMAIN.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_noc_domain',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_domain_code',
                                                       value3_in           => coalesce(i_domain_code, '<null>'));
                    RAISE e_invalid_noc_domain;
                END;
        END;
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.class_code             := i_class_code;
        l_rec.rank                   := i_rank;
        l_rec.id_inst_owner          := i_inst_owner;
        l_rec.id_concept_version     := i_concept_version;
        l_rec.id_concept_term        := i_concept_term;
    
        BEGIN
            -- Insert-optimistic
            ts_noc_class.ins(rec_in => l_rec, gen_pky_in => TRUE, handle_error_in => FALSE, rows_out => l_lst_rowid);
        
            SELECT nc.code_name, nc.code_definition
              INTO l_rec.code_name, l_rec.code_definition
              FROM noc_class nc
             WHERE nc.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT nc.id_noc_class, nc.code_name, nc.code_definition
                  INTO l_rec.id_noc_class, l_rec.code_name, l_rec.code_definition
                  FROM noc_class nc
                 WHERE nc.id_terminology_version = l_rec.id_terminology_version
                   AND nc.class_code = l_rec.class_code;
            
                ts_noc_class.upd(rec_in => l_rec);
            
        END;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_name,
                                               i_desc_trans => i_name);
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_definition,
                                               i_desc_trans => i_definition);
    END insert_into_noc_class;

    PROCEDURE insert_into_noc_scale
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN noc_scale.id_terminology_version%TYPE,
        i_scale_code          IN noc_scale.scale_code%TYPE,
        i_scale_description   IN pk_translation.t_desc_translation,
        i_description_level_1 IN pk_translation.t_desc_translation,
        i_description_level_2 IN pk_translation.t_desc_translation,
        i_description_level_3 IN pk_translation.t_desc_translation,
        i_description_level_4 IN pk_translation.t_desc_translation,
        i_description_level_5 IN pk_translation.t_desc_translation,
        i_inst_owner          IN noc_scale.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN noc_scale.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN noc_scale.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_noc_scale';
        l_rec       noc_scale%ROWTYPE;
        l_rec_level noc_scale_level%ROWTYPE;
        l_lst_rowid table_varchar;
        l_level     noc_scale_level.scale_level_value%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_scale_code = ' || coalesce(i_scale_code, '<null>');
        g_error := g_error || ' i_scale_description = ' || coalesce(i_scale_description, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.scale_code             := i_scale_code;
        l_rec.id_inst_owner          := i_inst_owner;
        l_rec.id_concept_version     := i_concept_version;
        l_rec.id_concept_term        := i_concept_term;
    
        BEGIN
            -- Insert-optimistic
            ts_noc_scale.ins(rec_in => l_rec, gen_pky_in => TRUE, handle_error_in => FALSE, rows_out => l_lst_rowid);
        
            SELECT ns.code_noc_scale
              INTO l_rec.code_noc_scale
              FROM noc_scale ns
             WHERE ns.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT ns.id_noc_scale, ns.code_noc_scale
                  INTO l_rec.id_noc_scale, l_rec.code_noc_scale
                  FROM noc_scale ns
                 WHERE ns.id_terminology_version = i_terminology_version
                   AND ns.scale_code = i_scale_code;
            
                ts_noc_scale.upd(rec_in => l_rec);
            
        END;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_noc_scale,
                                               i_desc_trans => i_scale_description);
    
        -- Likert levels 1 to 5
        FOR l_level IN 1 .. 5
        LOOP
            l_rec_level.id_noc_scale_level     := NULL;
            l_rec_level.id_terminology_version := i_terminology_version;
            l_rec_level.scale_code             := i_scale_code;
            l_rec_level.scale_level_value      := l_level;
            l_rec_level.code_noc_scale_level   := NULL;
            l_rec_level.rank                   := l_level;
            BEGIN
                -- Insert-optimistic                                               
                ts_noc_scale_level.ins(rec_in          => l_rec_level,
                                       gen_pky_in      => TRUE,
                                       handle_error_in => FALSE,
                                       rows_out        => l_lst_rowid);
            
                SELECT nsl.code_noc_scale_level
                  INTO l_rec_level.code_noc_scale_level
                  FROM noc_scale_level nsl
                 WHERE nsl.rowid = l_lst_rowid(1);
            EXCEPTION
                WHEN dup_val_on_index THEN
                    -- Entry already exist, then just update
                    SELECT nsl.id_noc_scale_level, nsl.code_noc_scale_level
                      INTO l_rec_level.id_noc_scale_level, l_rec_level.code_noc_scale_level
                      FROM noc_scale_level nsl
                     WHERE nsl.id_terminology_version = i_terminology_version
                       AND nsl.scale_code = i_scale_code
                       AND nsl.scale_level_value = l_level;
                
                    ts_noc_scale_level.upd(rec_in => l_rec_level);
            END;
            pk_translation.insert_into_translation(i_lang       => i_lang,
                                                   i_code_trans => l_rec_level.code_noc_scale_level,
                                                   i_desc_trans => (CASE l_level
                                                                       WHEN 1 THEN
                                                                        i_description_level_1
                                                                       WHEN 2 THEN
                                                                        i_description_level_2
                                                                       WHEN 3 THEN
                                                                        i_description_level_3
                                                                       WHEN 4 THEN
                                                                        i_description_level_4
                                                                       WHEN 5 THEN
                                                                        i_description_level_5
                                                                   END));
        
        END LOOP;
    
    END insert_into_noc_scale;

    PROCEDURE insert_into_noc_outcome
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN noc_outcome.id_terminology_version%TYPE,
        i_class_code          IN noc_class.class_code%TYPE,
        i_outcome_code        IN noc_outcome.outcome_code%TYPE,
        i_scale_codes         IN table_varchar,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_references          IN noc_outcome.references%TYPE DEFAULT NULL,
        i_inst_owner          IN noc_outcome.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept             IN noc.id_concept%TYPE DEFAULT NULL,
        i_concept_version     IN noc_outcome.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN noc_outcome.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_noc_outcome';
        TYPE t_scale_id_coll IS TABLE OF noc_scale.id_noc_scale%TYPE INDEX BY VARCHAR2(200 CHAR);
        l_rec          noc_outcome%ROWTYPE;
        l_lst_rowid    table_varchar;
        l_scale_codes  table_varchar;
        l_lst_scale_id t_scale_id_coll;
        l_idx          noc_scale.scale_code%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_class_code = ' || coalesce(i_class_code, '<null>');
        g_error := g_error || ' i_outcome_code = ' || coalesce(to_char(i_outcome_code), '<null>');
        g_error := g_error || ' i_scale_code = ' ||
                   coalesce(pk_utils.concat_table(i_tab => i_scale_codes, i_delim => ','), '<null>');
        g_error := g_error || ' i_name = ' || coalesce(i_name, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Validating NOC Scales';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_scale_codes := coalesce(i_scale_codes, table_varchar());
    
        FOR scale IN (SELECT ns.id_noc_scale, ns.scale_code
                        FROM noc_scale ns
                       WHERE ns.id_terminology_version = i_terminology_version
                         AND ns.scale_code IN (SELECT /*+ dynamic_sampling(t 2) */
                                                t.column_value
                                                 FROM TABLE(l_scale_codes) t))
        LOOP
            l_lst_scale_id(scale.scale_code) := scale.id_noc_scale;
        
        END LOOP;
    
        IF l_scale_codes.count() = 0
           OR l_scale_codes.count() != l_lst_scale_id.count()
        THEN
            DECLARE
                l_err_id PLS_INTEGER;
            BEGIN
                g_error := 'Invalid i_scale_codes. NOC Scale Codes not found in NOC_SCALE';
                pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_noc_scale',
                                                   err_instance_id_out => l_err_id,
                                                   text_in             => g_error,
                                                   name1_in            => 'function_name',
                                                   value1_in           => k_function_name,
                                                   name2_in            => 'i_terminology_version',
                                                   value2_in           => coalesce(to_char(i_terminology_version),
                                                                                   '<null>'),
                                                   name3_in            => 'i_scale_codes',
                                                   value3_in           => coalesce(pk_utils.concat_table(i_tab   => l_scale_codes,
                                                                                                         i_delim => ','),
                                                                                   '<null>'));
                RAISE e_invalid_noc_class;
            END;
        END IF;
    
        g_error := 'Retrieves surrogate key of NOC Class to which NOC Outcome belongs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT id_noc_class
              INTO l_rec.id_noc_class
              FROM noc_class nc
             WHERE nc.id_terminology_version = i_terminology_version
               AND nc.class_code = i_class_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NOC Class Code not found in NOC_CLASS.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_noc_class',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_class_code',
                                                       value3_in           => coalesce(i_class_code, '<null>'));
                    RAISE e_invalid_noc_class;
                END;
        END;
    
        g_error := 'Checks if the NOC Outcome Code already exists in NOC lookup table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT n.outcome_code
              INTO l_rec.outcome_code
              FROM noc n
             WHERE n.outcome_code = i_outcome_code;
        EXCEPTION
            WHEN no_data_found THEN
                -- NOC Outcome Code doesn't exist, then add it
                ts_noc.ins(outcome_code_in  => i_outcome_code,
                           id_concept_in    => i_concept,
                           id_inst_owner_in => k_inst_owner_default);
                l_rec.outcome_code := i_outcome_code;
        END;
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.references             := i_references;
        -- Some outcomes have used two scales in combination to measure the outcomes (and outcome's indicators). 
        -- In these cases, the first scale code in the array (i_scale_codes(1]) is defined as the primary scale used to determine Outcome scores.
        l_rec.id_noc_scale       := l_lst_scale_id(i_scale_codes(1));
        l_rec.id_inst_owner      := i_inst_owner;
        l_rec.id_concept_version := i_concept_version;
        l_rec.id_concept_term    := i_concept_term;
    
        BEGIN
            -- Insert-optimistic
            ts_noc_outcome.ins(rec_in => l_rec, gen_pky_in => TRUE, handle_error_in => FALSE, rows_out => l_lst_rowid);
        
            SELECT no.id_noc_outcome, no.code_name, no.code_definition
              INTO l_rec.id_noc_outcome, l_rec.code_name, l_rec.code_definition
              FROM noc_outcome no
             WHERE no.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT no.id_noc_outcome, no.code_name, no.code_definition
                  INTO l_rec.id_noc_outcome, l_rec.code_name, l_rec.code_definition
                  FROM noc_outcome no
                 WHERE no.id_terminology_version = l_rec.id_terminology_version
                   AND no.outcome_code = l_rec.outcome_code;
            
                ts_noc_outcome.upd(rec_in => l_rec);
        END;
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_name,
                                               i_desc_trans => i_name);
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_definition,
                                               i_desc_trans => i_definition);
    
        -- Saves the list of scales associated with the NOC Outcome that can be used by NOC Indicators
        l_idx := l_lst_scale_id.first;
        WHILE l_idx IS NOT NULL
        LOOP
            ts_noc_outcome_scale.upd_ins(id_noc_outcome_in => l_rec.id_noc_outcome,
                                         id_noc_scale_in   => l_lst_scale_id(l_idx),
                                         flg_primary_in    => (CASE l_idx
                                                                  WHEN i_scale_codes(1) THEN
                                                                   pk_alert_constant.g_yes
                                                                  ELSE
                                                                   pk_alert_constant.g_no
                                                              END));
            l_idx := l_lst_scale_id.next(l_idx);
        END LOOP;
    
    END insert_into_noc_outcome;

    PROCEDURE insert_into_noc_indicator
    (
        i_lang                   IN language.id_language%TYPE,
        i_terminology_version    IN nic_activity.id_terminology_version%TYPE,
        i_outcome_code           IN noc_outcome.outcome_code%TYPE,
        i_indicator_code         IN noc_indicator.indicator_code%TYPE,
        i_outcome_indicator_code IN noc_outcome_indicator.outcome_indicator_code%TYPE,
        i_description            IN pk_translation.t_desc_translation,
        i_scale_code             IN noc_scale.scale_code%TYPE DEFAULT NULL,
        i_rank                   IN noc_outcome_indicator.rank%TYPE DEFAULT NULL,
        i_inst_owner             IN noc_indicator.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version        IN noc_indicator.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term           IN noc_indicator.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_noc_indicator';
        l_rec                   noc_indicator%ROWTYPE;
        l_rec_outcome_indicator noc_outcome_indicator%ROWTYPE;
        l_lst_rowid             table_varchar;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_outcome_code = ' || coalesce(to_char(i_outcome_code), '<null>');
        g_error := g_error || ' i_indicator_code = ' || coalesce(to_char(i_indicator_code), '<null>');
        g_error := g_error || ' i_outcome_indicator_code = ' || coalesce(to_char(i_outcome_indicator_code), '<null>');
        g_error := g_error || ' i_description = ' || coalesce(i_description, '<null>');
        g_error := g_error || ' i_rank = ' || coalesce(i_rank, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NOC Outcome associated with NOC Indicator';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT no.id_noc_outcome
              INTO l_rec_outcome_indicator.id_noc_outcome
              FROM noc_outcome no
             WHERE no.id_terminology_version = i_terminology_version
               AND no.outcome_code = i_outcome_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NOC Outcome Code not found in NOC_OUTCOME.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_noc_outcome',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_outcome_code',
                                                       value3_in           => coalesce(i_outcome_code, '<null>'));
                    RAISE e_invalid_noc_outcome;
                END;
        END;
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.indicator_code         := i_indicator_code;
        -- Assumes that NOC Classification has no "Other indicator" included in the standard content
        l_rec.flg_other          := pk_alert_constant.g_no;
        l_rec.id_inst_owner      := i_inst_owner;
        l_rec.id_concept_version := i_concept_version;
        l_rec.id_concept_term    := i_concept_term;
    
        BEGIN
            -- Insert-optimistic
            ts_noc_indicator.ins(rec_in          => l_rec,
                                 gen_pky_in      => TRUE,
                                 handle_error_in => FALSE,
                                 rows_out        => l_lst_rowid);
        
            SELECT ni.id_noc_indicator, ni.code_description
              INTO l_rec.id_noc_indicator, l_rec.code_description
              FROM noc_indicator ni
             WHERE ni.rowid = l_lst_rowid(1);
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT ni.id_noc_indicator, ni.code_description
                  INTO l_rec.id_noc_indicator, l_rec.code_description
                  FROM noc_indicator ni
                 WHERE ni.id_terminology_version = i_terminology_version
                   AND ni.indicator_code = i_indicator_code;
            
                ts_noc_indicator.upd(rec_in => l_rec);
            
        END;
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_description,
                                               i_desc_trans => i_description);
    
        IF i_scale_code IS NOT NULL
        THEN
            g_error := 'Check if the referred scale for the NOC Indicator is allowed/associated with the NOC Outcome';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            BEGIN
                SELECT nos.id_noc_scale
                  INTO l_rec_outcome_indicator.id_noc_scale
                  FROM noc_outcome_scale nos
                 INNER JOIN noc_scale ns
                    ON nos.id_noc_scale = ns.id_noc_scale
                 WHERE ns.id_terminology_version = i_terminology_version
                   AND ns.scale_code = i_scale_code
                   AND nos.id_noc_outcome = l_rec_outcome_indicator.id_noc_outcome;
            EXCEPTION
                WHEN no_data_found THEN
                    DECLARE
                        l_err_id PLS_INTEGER;
                    BEGIN
                        g_error := 'Invalid scale for Indicator. The scale is not allowed/associated with referred NOC Outcome';
                        pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_noc_domain',
                                                           err_instance_id_out => l_err_id,
                                                           text_in             => g_error,
                                                           name1_in            => 'function_name',
                                                           value1_in           => k_function_name,
                                                           name2_in            => 'i_terminology_version',
                                                           value2_in           => coalesce(to_char(i_terminology_version),
                                                                                           '<null>'),
                                                           name3_in            => 'i_scale_code',
                                                           value3_in           => coalesce(i_scale_code, '<null>'));
                        RAISE e_invalid_noc_scale;
                    END;
            END;
        
        END IF;
    
        l_rec_outcome_indicator.id_noc_indicator       := l_rec.id_noc_indicator;
        l_rec_outcome_indicator.outcome_indicator_code := i_outcome_indicator_code;
        l_rec_outcome_indicator.rank                   := i_rank;
    
        BEGIN
            ts_noc_outcome_indicator.ins(rec_in => l_rec_outcome_indicator, handle_error_in => FALSE);
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update              
                ts_noc_outcome_indicator.upd(rec_in => l_rec_outcome_indicator);
            
        END;
    
    END insert_into_noc_indicator;

    FUNCTION format_noc_name
    (
        i_label           IN pk_translation.t_desc_translation,
        i_noc_code        IN noc_outcome.outcome_code%TYPE,
        i_code_format     IN VARCHAR2,
        i_additional_info IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache IS
        l_desc pk_translation.t_desc_translation;
    
    BEGIN
        IF i_label IS NULL
        THEN
            RETURN NULL;
        END IF;
        IF nvl(i_code_format, pk_alert_constant.g_no) = pk_alert_constant.g_no
           OR i_noc_code IS NULL
        THEN
            l_desc := i_label;
        ELSE
            -- Outcome code may appear before or after description,
            -- depending on the configuration ("S"tart or "E"nd);
            IF i_code_format = pk_nan_model.g_code_format_start
            THEN
                l_desc := '(' || TRIM(to_char(i_noc_code, g_noc_code_format)) || ') ';
            
                l_desc := l_desc || i_label;
            ELSIF i_code_format = pk_nan_model.g_code_format_end
            THEN
                l_desc := i_label || ' ' || '(' || TRIM(to_char(i_noc_code, g_noc_code_format)) || ')';
            
            ELSE
                l_desc := i_label;
            END IF;
        END IF;
    
        IF i_additional_info IS NOT NULL
        THEN
            l_desc := l_desc || ' - (' || i_additional_info || ')';
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END format_noc_name;

    FUNCTION format_indicator_name
    (
        i_label                  IN pk_translation.t_desc_translation,
        i_outcome_indicator_code IN noc_outcome_indicator.outcome_indicator_code%TYPE,
        i_code_format            IN VARCHAR2,
        i_additional_info        IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache IS
        l_desc pk_translation.t_desc_translation;
    
    BEGIN
        IF i_label IS NULL
        THEN
            RETURN NULL;
        END IF;
        IF nvl(i_code_format, pk_alert_constant.g_no) = pk_alert_constant.g_no
           OR i_outcome_indicator_code IS NULL
        THEN
            l_desc := i_label;
        ELSE
            -- Indicator code may appear before or after description,
            -- depending on the configuration ("S"tart or "E"nd);
            IF i_code_format = pk_nan_model.g_code_format_start
            THEN
                l_desc := '(' || TRIM(to_char(i_outcome_indicator_code, g_noc_indicator_code_format)) || ') ';
            
                l_desc := l_desc || i_label;
            ELSIF i_code_format = pk_nan_model.g_code_format_end
            THEN
                l_desc := i_label || ' ' || '(' || TRIM(to_char(i_outcome_indicator_code, g_noc_indicator_code_format)) || ')';
            
            ELSE
                l_desc := i_label;
            END IF;
        END IF;
    
        IF i_additional_info IS NOT NULL
        THEN
            l_desc := l_desc || ' - (' || i_additional_info || ')';
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END format_indicator_name;

    FUNCTION get_noc_outcome
    (
        i_lang        IN language.id_language%TYPE,
        i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE
    ) RETURN t_obj_noc_outcome IS
        l_lang language.id_language%TYPE;
        l_obj  t_obj_noc_outcome;
    BEGIN
    
        SELECT pk_nnn_core.get_terminology_language(i_terminology_version => no.id_terminology_version)
          INTO l_lang
          FROM noc_outcome no
         WHERE no.id_noc_outcome = i_noc_outcome;
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        SELECT t_obj_noc_outcome(i_id_noc_outcome => no.id_noc_outcome,
                                 i_noc_code       => no.outcome_code,
                                 i_name           => pk_translation.get_translation(i_lang      => l_lang,
                                                                                    i_code_mess => no.code_name),
                                 i_definition     => pk_translation.get_translation(i_lang      => l_lang,
                                                                                    i_code_mess => no.code_definition),
                                 i_noc_scale      => get_scale(i_noc_scale => no.id_noc_scale),
                                 i_references     => no.references,
                                 i_class          => t_obj_noc_class(i_id_noc_class => nc.id_noc_class,
                                                                     i_class_code   => nc.class_code,
                                                                     i_name         => pk_translation.get_translation(l_lang,
                                                                                                                      nc.code_name),
                                                                     i_definition   => pk_translation.get_translation(l_lang,
                                                                                                                      nc.code_definition),
                                                                     i_domain       => t_obj_noc_domain(i_id_noc_domain => nd.id_noc_domain,
                                                                                                        i_domain_code   => nd.domain_code,
                                                                                                        i_name          => pk_translation.get_translation(l_lang,
                                                                                                                                                          nd.code_name),
                                                                                                        i_definition    => pk_translation.get_translation(l_lang,
                                                                                                                                                          nd.code_definition))))
        
          INTO l_obj
          FROM noc_outcome no
         INNER JOIN noc_class nc
            ON no.id_noc_class = nc.id_noc_class
         INNER JOIN noc_domain nd
            ON nc.id_noc_domain = nd.id_noc_domain
         WHERE no.id_noc_outcome = i_noc_outcome;
    
        RETURN l_obj;
    
    END get_noc_outcome;

    FUNCTION get_outcome_code(i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE) RETURN noc_outcome.outcome_code%TYPE IS
        l_outcome_code noc_outcome.outcome_code%TYPE;
    BEGIN
        SELECT noc_o.outcome_code
          INTO l_outcome_code
          FROM noc_outcome noc_o
         WHERE noc_o.id_noc_outcome = i_noc_outcome;
    
        RETURN l_outcome_code;
    END get_outcome_code;

    FUNCTION get_indicator_code(i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE)
        RETURN noc_indicator.indicator_code%TYPE IS
        l_indicator_code noc_indicator.indicator_code%TYPE;
    BEGIN
        SELECT noc_i.indicator_code
          INTO l_indicator_code
          FROM noc_indicator noc_i
         WHERE noc_i.id_noc_indicator = i_noc_indicator;
    
        RETURN l_indicator_code;
    END get_indicator_code;

    FUNCTION get_outcome_indicator_code
    (
        i_noc_outcome   IN noc_outcome_indicator.id_noc_outcome%TYPE,
        i_noc_indicator IN noc_outcome_indicator.id_noc_indicator%TYPE
    ) RETURN noc_outcome_indicator.outcome_indicator_code%TYPE IS
        l_outcome_indicator_code noc_outcome_indicator.outcome_indicator_code%TYPE;
    BEGIN
        SELECT noc_oi.outcome_indicator_code
          INTO l_outcome_indicator_code
          FROM noc_outcome_indicator noc_oi
         WHERE noc_oi.id_noc_outcome = i_noc_outcome
           AND noc_oi.id_noc_indicator = i_noc_indicator;
    
        RETURN l_outcome_indicator_code;
    END get_outcome_indicator_code;

    FUNCTION get_outcome_name
    (
        i_noc_outcome     IN noc_outcome.id_noc_outcome%TYPE,
        i_code_format     IN VARCHAR2 DEFAULT g_code_format_none,
        i_additional_info IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache IS
        l_name     pk_translation.t_desc_translation;
        l_noc_code noc_outcome.outcome_code%TYPE;
    BEGIN
        SELECT pk_translation.get_translation(i_lang      => pk_nnn_core.get_terminology_language(i_terminology_version => no.id_terminology_version),
                                              i_code_mess => no.code_name) name,
               no.outcome_code
          INTO l_name, l_noc_code
          FROM noc_outcome no
         WHERE no.id_noc_outcome = i_noc_outcome;
    
        RETURN format_noc_name(i_label           => l_name,
                               i_noc_code        => l_noc_code,
                               i_code_format     => i_code_format,
                               i_additional_info => i_additional_info);
    END get_outcome_name;

    FUNCTION get_indicator_name(i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE)
        RETURN pk_translation.t_desc_translation result_cache IS
        l_name pk_translation.t_desc_translation;
    BEGIN
        SELECT pk_translation.get_translation(i_lang      => pk_nnn_core.get_terminology_language(i_terminology_version => ni.id_terminology_version),
                                              i_code_mess => ni.code_description) name
          INTO l_name
          FROM noc_indicator ni
         WHERE ni.id_noc_indicator = i_noc_indicator;
    
        RETURN l_name;
    END get_indicator_name;

    PROCEDURE get_scale
    (
        i_noc_scale       IN noc_scale.id_noc_scale%TYPE,
        i_flg_option_none IN VARCHAR DEFAULT pk_alert_constant.g_yes,
        o_scale_info      OUT pk_types.cursor_type,
        o_scale_levels    OUT pk_types.cursor_type
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_scale';
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_noc_scale = ' || coalesce(to_char(i_noc_scale), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- returns information of a scale
        OPEN o_scale_info FOR
            SELECT pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => ns.id_terminology_version),
                                                  ns.code_noc_scale) scale_name,
                   ns.scale_code
              FROM noc_scale ns
             WHERE ns.id_noc_scale = i_noc_scale;
    
        -- returns a list of levels of a scale              
        OPEN o_scale_levels FOR
            SELECT t.scale_level_name, t.scale_level_value
              FROM (SELECT pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => ns.id_terminology_version),
                                                          nsl.code_noc_scale_level) scale_level_name,
                           nsl.scale_level_value,
                           nsl.rank
                      FROM noc_scale ns
                     INNER JOIN noc_scale_level nsl
                        ON (ns.scale_code = nsl.scale_code AND ns.id_terminology_version = nsl.id_terminology_version)
                     WHERE ns.id_noc_scale = i_noc_scale
                    
                    UNION ALL
                    SELECT pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => ns.id_terminology_version),
                                                          k_dom_scale_level_none) scale_level_name,
                           NULL scale_level_value,
                           999 rank
                      FROM noc_scale ns
                     WHERE ns.id_noc_scale = i_noc_scale
                       AND i_flg_option_none = pk_alert_constant.g_yes) t
             ORDER BY t.rank;
    
    END get_scale;

    FUNCTION get_scale(i_noc_scale IN noc_scale.id_noc_scale%TYPE) RETURN t_obj_noc_scale IS
        l_obj t_obj_noc_scale;
    BEGIN
    
        -- gets information of the scale    
        SELECT t_obj_noc_scale(i_id_noc_scale   => ns.id_noc_scale,
                               i_scale_code     => ns.scale_code,
                               i_desc_noc_scale => pk_translation.get_translation(i_lang      => pk_nnn_core.get_terminology_language(i_terminology_version => ns.id_terminology_version),
                                                                                  i_code_mess => ns.code_noc_scale))
          INTO l_obj
          FROM noc_scale ns
         WHERE ns.id_noc_scale = i_noc_scale;
    
        -- gets list of levels of the scale
        SELECT t_obj_likert_scale_level(i_scale_level_value      => nsl.scale_level_value,
                                        i_desc_scale_level_value => pk_translation.get_translation(i_lang      => pk_nnn_core.get_terminology_language(i_terminology_version => ns.id_terminology_version),
                                                                                                   i_code_mess => nsl.code_noc_scale_level)) BULK COLLECT
          INTO l_obj.lst_scale_level
          FROM noc_scale ns
         INNER JOIN noc_scale_level nsl
            ON (ns.scale_code = nsl.scale_code AND ns.id_terminology_version = nsl.id_terminology_version)
         WHERE ns.id_noc_scale = i_noc_scale
         ORDER BY nsl.rank;
    
        RETURN l_obj;
    
    END get_scale;

    FUNCTION get_scale_level_name
    (
        i_lang              IN language.id_language%TYPE,
        i_noc_scale         IN noc_scale.id_noc_scale%TYPE,
        i_scale_level_value IN noc_scale_level.scale_level_value%TYPE
    ) RETURN VARCHAR2 IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_scale_level_name';
        l_scale_level_name pk_translation.t_desc_translation;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_noc_scale = ' || coalesce(to_char(i_noc_scale), '<null>');
        g_error := g_error || ' i_scale_level_value = ' || coalesce(to_char(i_scale_level_value), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        -- returns the name of a given scale level value
        IF i_scale_level_value IS NULL
        THEN
            l_scale_level_name := pk_translation.get_translation(i_lang, k_dom_scale_level_none);
        ELSE
            SELECT pk_translation.get_translation(pk_nnn_core.get_terminology_language(i_terminology_version => ns.id_terminology_version),
                                                  nsl.code_noc_scale_level)
              INTO l_scale_level_name
              FROM noc_scale ns
             INNER JOIN noc_scale_level nsl
                ON (ns.scale_code = nsl.scale_code AND ns.id_terminology_version = nsl.id_terminology_version)
             WHERE ns.id_noc_scale = i_noc_scale
               AND nsl.scale_level_value = i_scale_level_value;
        END IF;
    
        RETURN l_scale_level_name;
    END get_scale_level_name;

    FUNCTION get_outcome_scale(i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE) RETURN noc_scale.id_noc_scale%TYPE IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_outcome_scale';
        l_noc_scale noc_scale.id_noc_scale%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_noc_outcome = ' || coalesce(to_char(i_noc_outcome), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        SELECT noc.id_noc_scale
          INTO l_noc_scale
          FROM noc_outcome noc
         WHERE noc.id_noc_outcome = i_noc_outcome;
        RETURN l_noc_scale;
    END get_outcome_scale;

    FUNCTION get_indicator_scale
    (
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE,
        i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE
    ) RETURN noc_scale.id_noc_scale%TYPE IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_indicator_scale';
        l_noc_scale noc_scale.id_noc_scale%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_noc_outcome = ' || coalesce(to_char(i_noc_outcome), '<null>');
        g_error := g_error || ' i_noc_indicator = ' || coalesce(to_char(i_noc_indicator), '<null>');
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        --Indicator's scale ID. When NULL assumes the Outcome's scale
        SELECT coalesce(noi.id_noc_scale, noc.id_noc_scale) id_noc_scale
          INTO l_noc_scale
          FROM noc_outcome_indicator noi
         INNER JOIN noc_outcome noc
            ON noi.id_noc_outcome = noc.id_noc_outcome
         WHERE noi.id_noc_outcome = i_noc_outcome
           AND noi.id_noc_indicator = i_noc_indicator;
        RETURN l_noc_scale;
    END get_indicator_scale;

    FUNCTION get_outcome_scale_level_name
    (
        i_lang              IN language.id_language%TYPE,
        i_noc_outcome       IN noc_outcome.id_noc_outcome%TYPE,
        i_scale_level_value IN noc_scale_level.scale_level_value%TYPE
    ) RETURN VARCHAR2 IS
        l_noc_scale noc_scale.id_noc_scale%TYPE;
    BEGIN
        l_noc_scale := get_outcome_scale(i_noc_outcome => i_noc_outcome);
        RETURN get_scale_level_name(i_lang              => i_lang,
                                    i_noc_scale         => l_noc_scale,
                                    i_scale_level_value => i_scale_level_value);
    
    END get_outcome_scale_level_name;

    FUNCTION get_indicator_scale_level_name
    (
        i_lang              IN language.id_language%TYPE,
        i_noc_outcome       IN noc_outcome.id_noc_outcome%TYPE,
        i_noc_indicator     IN noc_indicator.id_noc_indicator%TYPE,
        i_scale_level_value IN noc_scale_level.scale_level_value%TYPE
    ) RETURN VARCHAR2 IS
        l_noc_scale noc_scale.id_noc_scale%TYPE;
    BEGIN
        l_noc_scale := get_indicator_scale(i_noc_outcome => i_noc_outcome, i_noc_indicator => i_noc_indicator);
        RETURN get_scale_level_name(i_lang              => i_lang,
                                    i_noc_scale         => l_noc_scale,
                                    i_scale_level_value => i_scale_level_value);
    
    END get_indicator_scale_level_name;

    FUNCTION get_noc_indicator
    (
        i_lang          IN language.id_language%TYPE,
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE,
        i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE
    ) RETURN t_obj_noc_indicator IS
        l_lang language.id_language%TYPE;
        l_obj  t_obj_noc_indicator;
    
    BEGIN
        SELECT pk_nnn_core.get_terminology_language(i_terminology_version => ni.id_terminology_version)
          INTO l_lang
          FROM noc_indicator ni
         WHERE ni.id_noc_indicator = i_noc_indicator;
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        SELECT t_obj_noc_indicator(id_noc_indicator       => ni.id_noc_indicator,
                                   description            => pk_translation.get_translation(i_lang      => l_lang,
                                                                                            i_code_mess => ni.code_description),
                                   flg_other              => ni.flg_other,
                                   outcome_indicator_code => get_outcome_indicator_code(i_noc_outcome   => i_noc_outcome,
                                                                                        i_noc_indicator => ni.id_noc_indicator),
                                   noc_scale              => get_scale(i_noc_scale => get_indicator_scale(i_noc_outcome   => i_noc_outcome,
                                                                                                          i_noc_indicator => ni.id_noc_indicator)))
          INTO l_obj
          FROM noc_indicator ni
         WHERE ni.id_noc_indicator = i_noc_indicator;
    
        RETURN l_obj;
    
    END get_noc_indicator;

    FUNCTION get_terminology_information(i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE)
        RETURN pk_nnn_in.t_terminology_info_rec IS
        l_terminology_version noc_outcome.id_terminology_version%TYPE;
        l_terminology_info    pk_nnn_in.t_terminology_info_rec;
    BEGIN
        SELECT no.id_terminology_version
          INTO l_terminology_version
          FROM noc_outcome no
         WHERE no.id_noc_outcome = i_noc_outcome;
    
        l_terminology_info := pk_nnn_in.get_terminology_information(i_terminology_version => l_terminology_version);
    
        RETURN l_terminology_info;
    END get_terminology_information;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_noc_model;
/
