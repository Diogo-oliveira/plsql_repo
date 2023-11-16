/*-- Last Change Revision: $Rev: 1658139 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:24:35 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_nan_model IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    PROCEDURE insert_into_nan_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_domain.id_terminology_version%TYPE,
        i_domain_code         IN nan_domain.domain_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN nan_domain.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN nan_domain.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_domain.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_domain.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nan_domain';
        l_rec       nan_domain%ROWTYPE;
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
            ts_nan_domain.ins(rec_in => l_rec, gen_pky_in => TRUE, handle_error_in => FALSE, rows_out => l_lst_rowid);
        
            SELECT nd.code_name, nd.code_definition
              INTO l_rec.code_name, l_rec.code_definition
              FROM nan_domain nd
             WHERE nd.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT nd.id_nan_domain, nd.code_name, nd.code_definition
                  INTO l_rec.id_nan_domain, l_rec.code_name, l_rec.code_definition
                  FROM nan_domain nd
                 WHERE nd.id_terminology_version = l_rec.id_terminology_version
                   AND nd.domain_code = l_rec.domain_code;
            
                ts_nan_domain.upd(rec_in => l_rec);
            
        END;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_name,
                                               i_desc_trans => i_name);
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_definition,
                                               i_desc_trans => i_definition);
    
    END insert_into_nan_domain;

    PROCEDURE insert_into_nan_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_domain_code         IN nan_domain.domain_code%TYPE,
        i_class_code          IN nan_class.class_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN nan_class.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN nan_class.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_class.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_class.id_concept_term%TYPE DEFAULT NULL
        
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nan_class';
        l_rec       nan_class%ROWTYPE;
        l_lst_rowid table_varchar;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_domain_code = ' || coalesce(i_domain_code, '<null>');
        g_error := g_error || ' i_class_code = ' || coalesce(i_class_code, '<null>');
        g_error := g_error || ' i_name = ' || coalesce(i_name, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NANDA Domain to which NANDA Class belongs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT id_nan_domain
              INTO l_rec.id_nan_domain
              FROM nan_domain nd
             WHERE nd.id_terminology_version = i_terminology_version
               AND nd.domain_code = i_domain_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NANDA Domain Code not found in NAN_DOMAIN.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nanda_domain',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_domain_code',
                                                       value3_in           => coalesce(i_domain_code, '<null>'));
                    RAISE e_invalid_nanda_domain;
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
            ts_nan_class.ins(rec_in => l_rec, gen_pky_in => TRUE, handle_error_in => FALSE, rows_out => l_lst_rowid);
        
            SELECT nc.code_name, nc.code_definition
              INTO l_rec.code_name, l_rec.code_definition
              FROM nan_class nc
             WHERE nc.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT nc.id_nan_class, nc.code_name, nc.code_definition
                  INTO l_rec.id_nan_class, l_rec.code_name, l_rec.code_definition
                  FROM nan_class nc
                 WHERE nc.id_terminology_version = l_rec.id_terminology_version
                   AND nc.class_code = l_rec.class_code;
            
                ts_nan_class.upd(rec_in => l_rec);
            
        END;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_name,
                                               i_desc_trans => i_name);
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_definition,
                                               i_desc_trans => i_definition);
    
    END insert_into_nan_class;

    PROCEDURE insert_into_nan_diagnosis
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_class_code          IN nan_class.class_code%TYPE,
        i_diagnosis_code      IN nan_diagnosis.diagnosis_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_year_approved       IN nan_diagnosis.year_approved%TYPE DEFAULT NULL,
        i_year_revised        IN nan_diagnosis.year_revised%TYPE DEFAULT NULL,
        i_loe                 IN nan_diagnosis.loe%TYPE DEFAULT NULL,
        i_references          IN nan_diagnosis.references%TYPE DEFAULT NULL,
        i_inst_owner          IN nan_class.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept             IN nan.id_concept%TYPE DEFAULT NULL,
        i_concept_version     IN nan_class.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_class.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nan_diagnosis';
        l_rec       nan_diagnosis%ROWTYPE;
        l_lst_rowid table_varchar;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_class_code = ' || coalesce(i_class_code, '<null>');
        g_error := g_error || ' i_diagnosis_code = ' || coalesce(to_char(i_diagnosis_code, '00000'), '<null>');
        g_error := g_error || ' i_name = ' || coalesce(i_name, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NANDA Class to which NANDA Diagnosis belongs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT nc.id_nan_class
              INTO l_rec.id_nan_class
              FROM nan_class nc
             WHERE nc.id_terminology_version = i_terminology_version
               AND nc.class_code = i_class_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NANDA Class Code not found in NAN_CLASS.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nanda_domain',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_class_code',
                                                       value3_in           => coalesce(i_class_code, '<null>'));
                    RAISE e_invalid_nanda_class;
                END;
        END;
    
        g_error := 'Checks if the NANDA Diagnosis Code already exists in NAN lookup table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT n.diagnosis_code
              INTO l_rec.diagnosis_code
              FROM nan n
             WHERE n.diagnosis_code = i_diagnosis_code;
        EXCEPTION
            WHEN no_data_found THEN
                -- NANDA Diagnosis Code doesn't exist, then add it
                ts_nan.ins(diagnosis_code_in => i_diagnosis_code,
                           id_concept_in     => i_concept,
                           id_inst_owner_in  => k_inst_owner_default);
                l_rec.diagnosis_code := i_diagnosis_code;
        END;
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.year_approved          := i_year_approved;
        l_rec.year_revised           := i_year_revised;
        l_rec.loe                    := i_loe;
        l_rec.references             := i_references;
        l_rec.id_inst_owner          := i_inst_owner;
        l_rec.id_concept_version     := i_concept_version;
        l_rec.id_concept_term        := i_concept_term;
    
        BEGIN
            -- Insert-optimistic
            ts_nan_diagnosis.ins(rec_in          => l_rec,
                                 gen_pky_in      => TRUE,
                                 handle_error_in => FALSE,
                                 rows_out        => l_lst_rowid);
        
            SELECT nd.code_name, nd.code_definition
              INTO l_rec.code_name, l_rec.code_definition
              FROM nan_diagnosis nd
             WHERE nd.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT nd.id_nan_diagnosis, nd.code_name, nd.code_definition
                  INTO l_rec.id_nan_diagnosis, l_rec.code_name, l_rec.code_definition
                  FROM nan_diagnosis nd
                 WHERE nd.id_terminology_version = l_rec.id_terminology_version
                   AND nd.diagnosis_code = l_rec.diagnosis_code;
            
                ts_nan_diagnosis.upd(rec_in => l_rec);
            
        END;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_name,
                                               i_desc_trans => i_name);
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_definition,
                                               i_desc_trans => i_definition);
    
    END insert_into_nan_diagnosis;

    PROCEDURE insert_into_def_characteristic
    
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_def_chars.id_terminology_version%TYPE,
        i_diagnosis_code      IN nan_diagnosis.diagnosis_code%TYPE,
        i_def_char_code       IN nan_def_chars.def_char_code%TYPE,
        i_description         IN pk_translation.t_desc_translation,
        i_inst_owner          IN nan_def_chars.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_def_chars.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_def_chars.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_def_characteristic';
        l_rec       nan_def_chars%ROWTYPE;
        l_lst_rowid table_varchar;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_diagnosis_code = ' || coalesce(to_char(i_diagnosis_code, '00000'), '<null>');
        g_error := g_error || ' i_def_char_code = ' || coalesce(i_def_char_code, '<null>');
        g_error := g_error || ' i_description = ' || coalesce(i_description, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NANDA Diagnosis to which Defining Characteristic belongs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT nd.id_nan_diagnosis
              INTO l_rec.id_nan_diagnosis
              FROM nan_diagnosis nd
             WHERE nd.id_terminology_version = i_terminology_version
               AND nd.diagnosis_code = i_diagnosis_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NANDA Diagnosis Code not found in NAN_DIAGNOSIS.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nanda_diagnosis',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_diagnosis_code',
                                                       value3_in           => coalesce(i_diagnosis_code, '<null>'));
                    RAISE e_invalid_nanda_diagnosis;
                END;
        END;
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.def_char_code          := i_def_char_code;
        l_rec.id_inst_owner          := i_inst_owner;
        l_rec.id_concept_version     := i_concept_version;
        l_rec.id_concept_term        := i_concept_term;
    
        BEGIN
            -- Insert-optimistic
            ts_nan_def_chars.ins(rec_in          => l_rec,
                                 gen_pky_in      => TRUE,
                                 handle_error_in => FALSE,
                                 rows_out        => l_lst_rowid);
            SELECT dc.code_description
              INTO l_rec.code_description
              FROM nan_def_chars dc
             WHERE dc.rowid = l_lst_rowid(1);
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT dc.id_nan_def_chars, dc.code_description
                  INTO l_rec.id_nan_def_chars, l_rec.code_description
                  FROM nan_def_chars dc
                 WHERE dc.id_terminology_version = i_terminology_version
                   AND dc.def_char_code = i_def_char_code;
            
                ts_nan_def_chars.upd(rec_in => l_rec);
        END;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_description,
                                               i_desc_trans => i_description);
    END insert_into_def_characteristic;

    PROCEDURE insert_into_related_factors
    
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_related_factor.id_terminology_version%TYPE,
        i_diagnosis_code      IN nan_diagnosis.diagnosis_code%TYPE,
        i_rel_factor_code     IN nan_related_factor.rel_factor_code%TYPE,
        i_description         IN pk_translation.t_desc_translation,
        i_inst_owner          IN nan_related_factor.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_related_factor.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_related_factor.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_related_factors';
        l_rec       nan_related_factor%ROWTYPE;
        l_lst_rowid table_varchar;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_diagnosis_code = ' || coalesce(to_char(i_diagnosis_code, '00000'), '<null>');
        g_error := g_error || ' i_rel_factor_code = ' || coalesce(i_rel_factor_code, '<null>');
        g_error := g_error || ' i_description = ' || coalesce(i_description, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NANDA Diagnosis to which Related Factor belongs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT nd.id_nan_diagnosis
              INTO l_rec.id_nan_diagnosis
              FROM nan_diagnosis nd
             WHERE nd.id_terminology_version = i_terminology_version
               AND nd.diagnosis_code = i_diagnosis_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NANDA Diagnosis Code not found in NAN_DIAGNOSIS.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nanda_diagnosis',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_diagnosis_code',
                                                       value3_in           => coalesce(i_diagnosis_code, '<null>'));
                    RAISE e_invalid_nanda_diagnosis;
                END;
        END;
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.rel_factor_code        := i_rel_factor_code;
        l_rec.id_inst_owner          := i_inst_owner;
        l_rec.id_concept_version     := i_concept_version;
        l_rec.id_concept_term        := i_concept_term;
    
        BEGIN
            -- Insert-optimistic
            ts_nan_related_factor.ins(rec_in          => l_rec,
                                      gen_pky_in      => TRUE,
                                      handle_error_in => FALSE,
                                      rows_out        => l_lst_rowid);
            SELECT relf.code_description
              INTO l_rec.code_description
              FROM nan_related_factor relf
             WHERE relf.rowid = l_lst_rowid(1);
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT relf.id_nan_related_factor, relf.code_description
                  INTO l_rec.id_nan_related_factor, l_rec.code_description
                  FROM nan_related_factor relf
                 WHERE relf.id_terminology_version = i_terminology_version
                   AND relf.rel_factor_code = i_rel_factor_code;
            
                ts_nan_related_factor.upd(rec_in => l_rec);
        END;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_description,
                                               i_desc_trans => i_description);
    END insert_into_related_factors;

    PROCEDURE insert_into_risk_factors
    
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_risk_factor.id_terminology_version%TYPE,
        i_diagnosis_code      IN nan_diagnosis.diagnosis_code%TYPE,
        i_risk_factor_code    IN nan_risk_factor.risk_factor_code%TYPE,
        i_description         IN pk_translation.t_desc_translation,
        i_inst_owner          IN nan_risk_factor.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_risk_factor.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_risk_factor.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_risk_factors';
        l_rec       nan_risk_factor%ROWTYPE;
        l_lst_rowid table_varchar;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_diagnosis_code = ' || coalesce(to_char(i_diagnosis_code, '00000'), '<null>');
        g_error := g_error || ' i_risk_factor_code = ' || coalesce(i_risk_factor_code, '<null>');
        g_error := g_error || ' i_description = ' || coalesce(i_description, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NANDA Diagnosis to which Risk Factor belongs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT nd.id_nan_diagnosis
              INTO l_rec.id_nan_diagnosis
              FROM nan_diagnosis nd
             WHERE nd.id_terminology_version = i_terminology_version
               AND nd.diagnosis_code = i_diagnosis_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NANDA Diagnosis Code not found in NAN_DIAGNOSIS.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nanda_diagnosis',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_diagnosis_code',
                                                       value3_in           => coalesce(i_diagnosis_code, '<null>'));
                    RAISE e_invalid_nanda_diagnosis;
                END;
        END;
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.risk_factor_code       := i_risk_factor_code;
        l_rec.id_inst_owner          := i_inst_owner;
        l_rec.id_concept_version     := i_concept_version;
        l_rec.id_concept_term        := i_concept_term;
    
        BEGIN
            -- Insert-optimistic
            ts_nan_risk_factor.ins(rec_in          => l_rec,
                                   gen_pky_in      => TRUE,
                                   handle_error_in => FALSE,
                                   rows_out        => l_lst_rowid);
            SELECT rskf.code_description
              INTO l_rec.code_description
              FROM nan_risk_factor rskf
             WHERE rskf.rowid = l_lst_rowid(1);
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT rskf.id_nan_risk_factor, rskf.code_description
                  INTO l_rec.id_nan_risk_factor, l_rec.code_description
                  FROM nan_risk_factor rskf
                 WHERE rskf.id_terminology_version = i_terminology_version
                   AND rskf.risk_factor_code = i_risk_factor_code;
            
                ts_nan_risk_factor.upd(rec_in => l_rec);
        END;
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_description,
                                               i_desc_trans => i_description);
    
    END insert_into_risk_factors;

    FUNCTION format_nanda_name
    (
        i_label           IN pk_translation.t_desc_translation,
        i_nanda_code      IN nan_diagnosis.diagnosis_code%TYPE,
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
           OR i_nanda_code IS NULL
        THEN
            l_desc := i_label;
        ELSE
            -- Diagnosis code may appear before or after description,
            -- depending on the configuration ("S"tart or "E"nd);
            IF i_code_format = pk_nan_model.g_code_format_start
            THEN
                l_desc := '(' || TRIM(to_char(i_nanda_code, g_nanda_code_format)) || ') ';
            
                l_desc := l_desc || i_label;
            ELSIF i_code_format = pk_nan_model.g_code_format_end
            THEN
                l_desc := i_label || ' ' || '(' || TRIM(to_char(i_nanda_code, g_nanda_code_format)) || ')';
            
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
    END format_nanda_name;

    -- Getters

    PROCEDURE get_nan_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_domain.id_terminology_version%TYPE,
        o_data                OUT t_nan_domain_cur
    ) IS
        l_lang language.id_language%TYPE;
    BEGIN
        l_lang := pk_nnn_core.get_terminology_language(i_terminology_version => i_terminology_version);
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
             WHERE nd.id_terminology_version = i_terminology_version
             ORDER BY nd.rank, domain_name;
    END get_nan_domain;

    PROCEDURE get_nan_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_domain.id_terminology_version%TYPE,
        i_domain_code         IN nan_domain.domain_code%TYPE,
        o_data                OUT t_nan_domain_cur
    ) IS
        l_lang language.id_language%TYPE;
    BEGIN
        l_lang := pk_nnn_core.get_terminology_language(i_terminology_version => i_terminology_version);
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
             WHERE nd.id_terminology_version = i_terminology_version
               AND nd.domain_code = i_domain_code
             ORDER BY nd.rank, domain_name;
    END get_nan_domain;

    PROCEDURE get_nan_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        o_data                OUT t_nan_class_cur
    ) IS
        l_lang language.id_language%TYPE;
    BEGIN
        l_lang := pk_nnn_core.get_terminology_language(i_terminology_version => i_terminology_version);
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
             WHERE nc.id_terminology_version = i_terminology_version
             ORDER BY nd.rank, nc.rank, class_name;
    
    END get_nan_class;

    PROCEDURE get_nan_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_domain_code         IN nan_domain.domain_code%TYPE,
        o_data                OUT t_nan_class_cur
    ) IS
        l_lang language.id_language%TYPE;
    BEGIN
        l_lang := pk_nnn_core.get_terminology_language(i_terminology_version => i_terminology_version);
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
             WHERE nd.id_terminology_version = i_terminology_version
               AND nd.domain_code = i_domain_code
             ORDER BY nc.rank, class_name;
    END get_nan_class;

    PROCEDURE get_nan_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_class_code          IN nan_class.class_code%TYPE,
        o_data                OUT t_nan_class_cur
    ) IS
    BEGIN
        OPEN o_data FOR
            SELECT nc.id_nan_class,
                   nc.class_code,
                   pk_translation.get_translation(i_lang, nc.code_name) class_name,
                   pk_translation.get_translation(i_lang, nc.code_definition) class_definition,
                   nc.id_nan_domain
              FROM nan_class nc
             WHERE nc.id_terminology_version = i_terminology_version
               AND nc.class_code = i_class_code;
    END get_nan_class;

    PROCEDURE get_nan_diagnosis
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_class_code          IN nan_class.class_code%TYPE,
        i_paging              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_startindex          IN NUMBER DEFAULT 1,
        i_items_per_page      IN NUMBER DEFAULT 10,
        o_data                OUT t_nan_diagnosis_cur,
        o_total_items         OUT NUMBER
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_nan_diagnosis';
        l_lang language.id_language%TYPE;
    BEGIN
    
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_class_code = ' || coalesce(i_class_code, '<null>');
        g_error := g_error || ' i_paging = ' || coalesce(i_paging, '<null>');
        g_error := g_error || ' i_startindex = ' || coalesce(to_char(i_startindex), '<null>');
        g_error := g_error || ' i_items_per_page = ' || coalesce(to_char(i_items_per_page), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_lang := pk_nnn_core.get_terminology_language(i_terminology_version => i_terminology_version);
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        SELECT count(*)
          INTO o_total_items
          FROM nan_diagnosis nd
         INNER JOIN nan_class nc
            ON nd.id_nan_class = nc.id_nan_class
         WHERE nc.id_terminology_version = i_terminology_version
           AND nc.class_code = i_class_code;
    
        IF i_paging = pk_alert_constant.g_yes
        THEN
            OPEN o_data FOR
                SELECT x.id_nan_diagnosis,
                       x.diagnosis_code,
                       x.diagnosis_name,
                       x.diagnosis_definition,
                       x.year_approved,
                       x.year_revised,
                       x.loe,
                       x.references,
                       x.id_nan_class
                  FROM (SELECT /*+ first_rows(10) */
                         row_number() over(ORDER BY pk_translation.get_translation(l_lang, nd.code_name)) rn,
                         nd.id_nan_diagnosis,
                         nd.diagnosis_code,
                         pk_translation.get_translation(l_lang, nd.code_name) diagnosis_name,
                         pk_translation.get_translation(l_lang, nd.code_definition) diagnosis_definition,
                         nd.year_approved,
                         nd.year_revised,
                         nd.loe,
                         nd.references,
                         nd.id_nan_class
                          FROM nan_diagnosis nd
                         INNER JOIN nan_class nc
                            ON nc.id_nan_class = nd.id_nan_class
                         WHERE nc.id_terminology_version = i_terminology_version
                           AND nc.class_code = i_class_code
                         ORDER BY diagnosis_name, nd.id_nan_diagnosis) x
                 WHERE x.rn BETWEEN i_startindex AND (i_startindex + i_items_per_page - 1);
        ELSE
            OPEN o_data FOR
                SELECT nd.id_nan_diagnosis,
                       nd.diagnosis_code,
                       pk_translation.get_translation(l_lang, nd.code_name) diagnosis_name,
                       pk_translation.get_translation(l_lang, nd.code_definition) diagnosis_definition,
                       nd.year_approved,
                       nd.year_revised,
                       nd.loe,
                       nd.references,
                       nd.id_nan_class
                  FROM nan_diagnosis nd
                 INNER JOIN nan_class nc
                    ON nc.id_nan_class = nd.id_nan_class
                 WHERE nc.id_terminology_version = i_terminology_version
                   AND nc.class_code = i_class_code
                 ORDER BY diagnosis_name;
        END IF;
    
    END get_nan_diagnosis;

    FUNCTION get_nan_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE
    ) RETURN t_obj_nan_diagnosis IS
        l_lang language.id_language%TYPE;
        l_obj  t_obj_nan_diagnosis;
    BEGIN
    
        SELECT pk_nnn_core.get_terminology_language(i_terminology_version => nd.id_terminology_version)
          INTO l_lang
          FROM nan_diagnosis nd
         WHERE nd.id_nan_diagnosis = i_nan_diagnosis;
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        SELECT t_obj_nan_diagnosis(id_nan_diagnosis => ndx.id_nan_diagnosis,
                                   nanda_code       => ndx.diagnosis_code,
                                   name             => pk_translation.get_translation(l_lang, ndx.code_name),
                                   definition       => pk_translation.get_translation(l_lang, ndx.code_definition),
                                   year_approved    => ndx.year_approved,
                                   year_revised     => ndx.year_revised,
                                   loe              => ndx.loe,
                                   references       => ndx.references,
                                   CLASS            => t_obj_nan_class(id_nan_class => nc.id_nan_class,
                                                                       class_code   => nc.class_code,
                                                                       name         => pk_translation.get_translation(l_lang,
                                                                                                                      nc.code_name),
                                                                       definition   => pk_translation.get_translation(l_lang,
                                                                                                                      nc.code_definition),
                                                                       domain       => t_obj_nan_domain(id_nan_domain => nd.id_nan_domain,
                                                                                                        domain_code   => nd.domain_code,
                                                                                                        name          => pk_translation.get_translation(l_lang,
                                                                                                                                                        nd.code_name),
                                                                                                        definition    => pk_translation.get_translation(l_lang,
                                                                                                                                                        nd.code_definition)))) nan_diagnosis_obj
          INTO l_obj
          FROM nan_diagnosis ndx
         INNER JOIN nan_class nc
            ON ndx.id_nan_class = nc.id_nan_class
         INNER JOIN nan_domain nd
            ON nc.id_nan_domain = nd.id_nan_domain
         WHERE ndx.id_nan_diagnosis = i_nan_diagnosis;
    
        RETURN l_obj;
    END get_nan_diagnosis;

    PROCEDURE get_defined_characteristics
    (
        i_lang           IN language.id_language%TYPE,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_startindex     IN NUMBER DEFAULT 1,
        i_items_per_page IN NUMBER DEFAULT 10,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_defined_characteristics';
        l_lang language.id_language%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_nan_diagnosis = ' || coalesce(to_char(i_nan_diagnosis), '<null>');
        g_error := g_error || ' i_paging = ' || coalesce(i_paging, '<null>');
        g_error := g_error || ' i_startindex = ' || coalesce(to_char(i_startindex), '<null>');
        g_error := g_error || ' i_items_per_page = ' || coalesce(to_char(i_items_per_page), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        BEGIN
            SELECT count(*) total_items,
                   pk_nnn_core.get_terminology_language(i_terminology_version => nd.id_terminology_version) term_language
              INTO o_total_items, l_lang
              FROM nan_def_chars ndc
             INNER JOIN nan_diagnosis nd
                ON nd.id_nan_diagnosis = ndc.id_nan_diagnosis
             WHERE nd.id_nan_diagnosis = i_nan_diagnosis
             GROUP BY nd.id_nan_diagnosis, nd.id_terminology_version;
        EXCEPTION
            WHEN no_data_found THEN
                -- There are no related factors for this diagnosis
                o_total_items := 0;
        END;
    
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        IF i_paging = pk_alert_constant.g_yes
        THEN
            OPEN o_data FOR
                SELECT x.id_nan_def_chars, x.def_char_code, x.description
                  FROM (SELECT /*+ first_rows(10) */
                         row_number() over(ORDER BY pk_translation.get_translation(l_lang, ndc.code_description)) rn,
                         ndc.id_nan_def_chars,
                         ndc.def_char_code,
                         pk_translation.get_translation(l_lang, ndc.code_description) description
                          FROM nan_def_chars ndc
                         INNER JOIN nan_diagnosis nd
                            ON nd.id_nan_diagnosis = ndc.id_nan_diagnosis
                         WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                         ORDER BY description, ndc.id_nan_def_chars) x
                 WHERE x.rn BETWEEN i_startindex AND (i_startindex + i_items_per_page - 1);
        ELSE
            OPEN o_data FOR
                SELECT ndc.id_nan_def_chars,
                       ndc.def_char_code,
                       pk_translation.get_translation(l_lang, ndc.code_description) description
                  FROM nan_def_chars ndc
                 INNER JOIN nan_diagnosis nd
                    ON nd.id_nan_diagnosis = ndc.id_nan_diagnosis
                 WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                 ORDER BY description;
        END IF;
    
    END get_defined_characteristics;

    PROCEDURE get_related_factors
    (
        i_lang           IN language.id_language%TYPE,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_startindex     IN NUMBER DEFAULT 1,
        i_items_per_page IN NUMBER DEFAULT 10,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_related_factors';
        l_lang language.id_language%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_nan_diagnosis = ' || coalesce(to_char(i_nan_diagnosis), '<null>');
        g_error := g_error || ' i_paging = ' || coalesce(i_paging, '<null>');
        g_error := g_error || ' i_startindex = ' || coalesce(to_char(i_startindex), '<null>');
        g_error := g_error || ' i_items_per_page = ' || coalesce(to_char(i_items_per_page), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        BEGIN
            SELECT count(*) total_items,
                   pk_nnn_core.get_terminology_language(i_terminology_version => nd.id_terminology_version) term_language
              INTO o_total_items, l_lang
              FROM nan_related_factor nrf
             INNER JOIN nan_diagnosis nd
                ON nd.id_nan_diagnosis = nrf.id_nan_diagnosis
             WHERE nd.id_nan_diagnosis = i_nan_diagnosis
             GROUP BY nd.id_nan_diagnosis, nd.id_terminology_version;
        EXCEPTION
            WHEN no_data_found THEN
                -- There are no related factors for this diagnosis
                o_total_items := 0;
        END;
    
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        IF i_paging = pk_alert_constant.g_yes
        THEN
            OPEN o_data FOR
                SELECT x.id_nan_related_factor, x.rel_factor_code, x.description
                  FROM (SELECT /*+ first_rows(10) */
                         row_number() over(ORDER BY pk_translation.get_translation(l_lang, nrf.code_description)) rn,
                         nrf.id_nan_related_factor,
                         nrf.rel_factor_code,
                         pk_translation.get_translation(l_lang, nrf.code_description) description
                          FROM nan_related_factor nrf
                         INNER JOIN nan_diagnosis nd
                            ON nd.id_nan_diagnosis = nrf.id_nan_diagnosis
                         WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                         ORDER BY description, nrf.id_nan_related_factor) x
                 WHERE x.rn BETWEEN i_startindex AND (i_startindex + i_items_per_page - 1);
        ELSE
            OPEN o_data FOR
                SELECT nrf.id_nan_related_factor,
                       nrf.rel_factor_code,
                       pk_translation.get_translation(l_lang, nrf.code_description) description
                  FROM nan_related_factor nrf
                 INNER JOIN nan_diagnosis nd
                    ON nd.id_nan_diagnosis = nrf.id_nan_diagnosis
                 WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                 ORDER BY description;
        END IF;
    
    END get_related_factors;

    PROCEDURE get_risk_factors
    (
        i_lang           IN language.id_language%TYPE,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_startindex     IN NUMBER DEFAULT 1,
        i_items_per_page IN NUMBER DEFAULT 10,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'get_risk_factors';
        l_lang language.id_language%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_nan_diagnosis = ' || coalesce(to_char(i_nan_diagnosis), '<null>');
        g_error := g_error || ' i_paging = ' || coalesce(i_paging, '<null>');
        g_error := g_error || ' i_startindex = ' || coalesce(to_char(i_startindex), '<null>');
        g_error := g_error || ' i_items_per_page = ' || coalesce(to_char(i_items_per_page), '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        BEGIN
            SELECT count(*),
                   pk_nnn_core.get_terminology_language(i_terminology_version => nd.id_terminology_version) term_language
              INTO o_total_items, l_lang
              FROM nan_risk_factor rskf
             INNER JOIN nan_diagnosis nd
                ON nd.id_nan_diagnosis = rskf.id_nan_diagnosis
             WHERE nd.id_nan_diagnosis = i_nan_diagnosis
             GROUP BY nd.id_nan_diagnosis, nd.id_terminology_version;
        EXCEPTION
            WHEN no_data_found THEN
                -- There are no related factors for this diagnosis
                o_total_items := 0;
        END;
    
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        IF i_paging = pk_alert_constant.g_yes
        THEN
            OPEN o_data FOR
                SELECT x.id_nan_risk_factor, x.risk_factor_code, x.description
                  FROM (SELECT /*+ first_rows(10) */
                         row_number() over(ORDER BY pk_translation.get_translation(l_lang, rskf.code_description)) rn,
                         rskf.id_nan_risk_factor,
                         rskf.risk_factor_code,
                         pk_translation.get_translation(l_lang, rskf.code_description) description
                          FROM nan_risk_factor rskf
                         INNER JOIN nan_diagnosis nd
                            ON nd.id_nan_diagnosis = rskf.id_nan_diagnosis
                         WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                         ORDER BY description, rskf.id_nan_risk_factor) x
                 WHERE x.rn BETWEEN i_startindex AND (i_startindex + i_items_per_page - 1);
        ELSE
            OPEN o_data FOR
                SELECT rskf.id_nan_risk_factor,
                       rskf.risk_factor_code,
                       pk_translation.get_translation(l_lang, rskf.code_description) description
                  FROM nan_risk_factor rskf
                 INNER JOIN nan_diagnosis nd
                    ON nd.id_nan_diagnosis = rskf.id_nan_diagnosis
                 WHERE nd.id_nan_diagnosis = i_nan_diagnosis
                 ORDER BY description;
        END IF;
    
    END get_risk_factors;

    FUNCTION get_nanda_code(i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE)
        RETURN nan_diagnosis.diagnosis_code%TYPE IS
        l_nanda_code nan_diagnosis.diagnosis_code%TYPE;
    BEGIN
        SELECT nd.diagnosis_code
          INTO l_nanda_code
          FROM nan_diagnosis nd
         WHERE nd.id_nan_diagnosis = i_nan_diagnosis;
        RETURN l_nanda_code;
    END get_nanda_code;

    FUNCTION get_nan_diagnosis_name
    (
        i_nan_diagnosis   IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_code_format     IN VARCHAR2 DEFAULT g_code_format_none,
        i_additional_info IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache IS
        l_nanda_label pk_translation.t_desc_translation;
        l_nanda_code  nan_diagnosis.diagnosis_code%TYPE;
    
    BEGIN
        SELECT pk_translation.get_translation(i_lang      => pk_nnn_core.get_terminology_language(i_terminology_version => nd.id_terminology_version),
                                              i_code_mess => nd.code_name) name,
               nd.diagnosis_code
          INTO l_nanda_label, l_nanda_code
          FROM nan_diagnosis nd
         WHERE nd.id_nan_diagnosis = i_nan_diagnosis;
    
        RETURN format_nanda_name(i_label           => l_nanda_label,
                                 i_nanda_code      => l_nanda_code,
                                 i_code_format     => i_code_format,
                                 i_additional_info => i_additional_info);
    
    END get_nan_diagnosis_name;

    FUNCTION get_terminology_information(i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE)
        RETURN pk_nnn_in.t_terminology_info_rec IS
        l_terminology_version nan_diagnosis.id_terminology_version%TYPE;
        l_terminology_info    pk_nnn_in.t_terminology_info_rec;
    BEGIN
        SELECT nd.id_terminology_version
          INTO l_terminology_version
          FROM nan_diagnosis nd
         WHERE nd.id_nan_diagnosis = i_nan_diagnosis;
    
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
END pk_nan_model;
/
