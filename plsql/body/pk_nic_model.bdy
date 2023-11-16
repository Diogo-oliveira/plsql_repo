/*-- Last Change Revision: $Rev: 1658139 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:24:35 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE BODY pk_nic_model IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    PROCEDURE insert_into_nic_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nic_domain.id_terminology_version%TYPE,
        i_domain_code         IN nic_domain.domain_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN nic_domain.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN nic_domain.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nic_domain.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nic_domain.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nic_domain';
        l_rec       nic_domain%ROWTYPE;
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
            ts_nic_domain.ins(rec_in => l_rec, gen_pky_in => TRUE, handle_error_in => FALSE, rows_out => l_lst_rowid);
        
            SELECT nd.code_name, nd.code_definition
              INTO l_rec.code_name, l_rec.code_definition
              FROM nic_domain nd
             WHERE nd.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT nd.id_nic_domain, nd.code_name, nd.code_definition
                  INTO l_rec.id_nic_domain, l_rec.code_name, l_rec.code_definition
                  FROM nic_domain nd
                 WHERE nd.id_terminology_version = l_rec.id_terminology_version
                   AND nd.domain_code = l_rec.domain_code;
            
                ts_nic_domain.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            
        END;
    
        --insert <translation> records
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_name,
                                               i_desc_trans => i_name);
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_definition,
                                               i_desc_trans => i_definition);
    END insert_into_nic_domain;

    PROCEDURE insert_into_nic_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nic_class.id_terminology_version%TYPE,
        i_domain_code         IN nic_domain.domain_code%TYPE,
        i_class_code          IN nic_class.class_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN nic_class.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN nic_class.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nic_class.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nic_class.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nic_class';
        l_rec       nic_class%ROWTYPE;
        l_lst_rowid table_varchar;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_domain_code = ' || coalesce(i_domain_code, '<null>');
        g_error := g_error || ' i_class_code = ' || coalesce(i_class_code, '<null>');
        g_error := g_error || ' i_name = ' || coalesce(i_name, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of nic Domain to which nic Class belongs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT id_nic_domain
              INTO l_rec.id_nic_domain
              FROM nic_domain nd
             WHERE nd.id_terminology_version = i_terminology_version
               AND nd.domain_code = i_domain_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'nic Domain Code not found in nic_domain.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nic_domain',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_domain_code',
                                                       value3_in           => coalesce(i_domain_code, '<null>'));
                    RAISE e_invalid_nic_domain;
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
            ts_nic_class.ins(rec_in => l_rec, gen_pky_in => TRUE, handle_error_in => FALSE, rows_out => l_lst_rowid);
        
            SELECT nc.code_name, nc.code_definition
              INTO l_rec.code_name, l_rec.code_definition
              FROM nic_class nc
             WHERE nc.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT nc.id_nic_class, nc.code_name, nc.code_definition
                  INTO l_rec.id_nic_class, l_rec.code_name, l_rec.code_definition
                  FROM nic_class nc
                 WHERE nc.id_terminology_version = l_rec.id_terminology_version
                   AND nc.class_code = l_rec.class_code;
            
                ts_nic_class.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            
        END;
    
        --insert <translation> records
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_name,
                                               i_desc_trans => i_name);
    
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_definition,
                                               i_desc_trans => i_definition);
    END insert_into_nic_class;

    PROCEDURE insert_into_nic_intervention
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nic_intervention.id_terminology_version%TYPE,
        i_class_code          IN nic_class.class_code%TYPE,
        i_intervention_code   IN nic_intervention.intervention_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_references          IN nic_intervention.references%TYPE DEFAULT NULL,
        i_inst_owner          IN nic_intervention.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept             IN nic.id_concept%TYPE DEFAULT NULL,
        i_concept_version     IN nic_intervention.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nic_intervention.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nic_intervention';
        l_rec          nic_intervention%ROWTYPE;
        l_lst_rowid    table_varchar;
        l_id_nic_class nic_class.id_nic_class%TYPE;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_class_code = ' || coalesce(i_class_code, '<null>');
        g_error := g_error || ' i_intervention_code = ' || coalesce(to_char(i_intervention_code), '<null>');
        g_error := g_error || ' i_name = ' || coalesce(i_name, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NIC Class to which NIC Interventions belongs';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT nc.id_nic_class
              INTO l_id_nic_class
              FROM nic_class nc
             WHERE nc.id_terminology_version = i_terminology_version
               AND nc.class_code = i_class_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NIC Class Code not found in nic_class.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nic_class',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_class_code',
                                                       value3_in           => coalesce(i_class_code, '<null>'));
                    RAISE e_invalid_nic_class;
                END;
        END;
    
        g_error := 'Checks if the NIC Interventions Code already exists in NIC table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT n.intervention_code
              INTO l_rec.intervention_code
              FROM nic n
             WHERE n.intervention_code = i_intervention_code;
        EXCEPTION
            WHEN no_data_found THEN
                ts_nic.ins(intervention_code_in => i_intervention_code,
                           id_concept_in        => i_concept,
                           id_inst_owner_in     => k_inst_owner_default);
        END;
    
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.intervention_code      := i_intervention_code;
        l_rec.references             := i_references;
        l_rec.id_inst_owner          := i_inst_owner;
        l_rec.id_concept_version     := i_concept_version;
        l_rec.id_concept_term        := i_concept_term;
    
        g_error := 'Checks if the Intervention already exists in NIC_INTERVENTION table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            -- Insert-optimistic
            ts_nic_intervention.ins(rec_in          => l_rec,
                                    gen_pky_in      => TRUE,
                                    handle_error_in => FALSE,
                                    rows_out        => l_lst_rowid);
        
            SELECT nd.code_name, nd.code_definition, nd.id_nic_intervention
              INTO l_rec.code_name, l_rec.code_definition, l_rec.id_nic_intervention
              FROM nic_intervention nd
             WHERE nd.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT ni.id_nic_intervention, ni.code_name, ni.code_definition
                  INTO l_rec.id_nic_intervention, l_rec.code_name, l_rec.code_definition
                  FROM nic_intervention ni
                 WHERE ni.id_terminology_version = l_rec.id_terminology_version
                   AND ni.intervention_code = l_rec.intervention_code;
            
                ts_nic_intervention.upd(rec_in => l_rec, rows_out => l_lst_rowid);
            
        END;
    
        g_error := 'Checks if the Intervention/Class already exists in NIC_CLASS_INTERV relational table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT nci.id_nic_intervention
              INTO l_rec.id_nic_intervention
              FROM nic_class_interv nci
             WHERE nci.id_nic_intervention = l_rec.id_nic_intervention
               AND nci.id_nic_class = l_id_nic_class;
        EXCEPTION
            WHEN no_data_found THEN
                ts_nic_class_interv.ins(id_nic_class_in        => l_id_nic_class,
                                        id_nic_intervention_in => l_rec.id_nic_intervention);
        END;
    
        --insert <translation> records
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_name,
                                               i_desc_trans => i_name);
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_definition,
                                               i_desc_trans => i_definition);
    
    END insert_into_nic_intervention;

    PROCEDURE insert_into_nic_activity
    (
        i_lang                 IN language.id_language%TYPE,
        i_terminology_version  IN nic_activity.id_terminology_version%TYPE,
        i_intervention_code    IN nic_intervention.intervention_code%TYPE,
        i_activity_code        IN nic_activity.activity_code%TYPE,
        i_interv_activity_code IN nic_interv_activity.interv_activity_code%TYPE,
        i_rank                 IN nic_interv_activity.rank%TYPE,
        i_description          IN pk_translation.t_desc_translation,
        i_flg_tasklist         IN nic_activity.flg_tasklist%TYPE DEFAULT pk_alert_constant.g_no,
        i_flg_task             IN nic_interv_activity.flg_task%TYPE DEFAULT pk_alert_constant.g_no,
        i_parent_activity_code IN nic_activity.activity_code%TYPE DEFAULT NULL,
        i_inst_owner           IN nic_activity.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version      IN nic_activity.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term         IN nic_activity.id_concept_term%TYPE DEFAULT NULL
    ) IS
        k_function_name CONSTANT VARCHAR2(30 CHAR) := 'insert_into_nic_activity';
        l_rec                       nic_activity%ROWTYPE;
        l_rec_interv_activity       nic_interv_activity%ROWTYPE;
        l_lst_rowid                 table_varchar;
        l_id_nic_intervention       nic_intervention.id_nic_intervention%TYPE;
        l_id_interv_activity_parent nic_interv_activity.id_parent%TYPE;
        l_invalid_parent            BOOLEAN;
        l_err_id                    PLS_INTEGER;
    BEGIN
        g_error := 'Input arguments:';
        g_error := g_error || ' i_lang = ' || coalesce(to_char(i_lang), '<null>');
        g_error := g_error || ' i_terminology_version = ' || coalesce(to_char(i_terminology_version), '<null>');
        g_error := g_error || ' i_intervention_code = ' || coalesce(to_char(i_intervention_code), '<null>');
        g_error := g_error || ' i_activity_code = ' || coalesce(i_activity_code, '<null>');
        g_error := g_error || ' i_interv_activity_code = ' || coalesce(i_interv_activity_code, '<null>');
        g_error := g_error || ' i_description = ' || coalesce(i_description, '<null>');
    
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        g_error := 'Retrieves surrogate key of NIC Intervention';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        BEGIN
            SELECT ni.id_nic_intervention
              INTO l_id_nic_intervention
              FROM nic_intervention ni
             WHERE ni.id_terminology_version = i_terminology_version
               AND ni.intervention_code = i_intervention_code;
        EXCEPTION
            WHEN no_data_found THEN
                DECLARE
                    l_err_id PLS_INTEGER;
                BEGIN
                    g_error := 'NIC Intervention Code not found in nic_intervention.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_nic_intervention',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_intervention_code',
                                                       value3_in           => coalesce(i_intervention_code, '<null>'));
                    RAISE e_invalid_nic_intervention;
                END;
        END;
    
        /*
        An Activity is created as a tasklist to group a set of NIC Activities that do not make sense be possible to request 
        and document individually but used as if they were items of a checklist when an intervention is performed.
        
        Example: "Execute bladder Irrigation" is an activity created and defined as tasklist by the ALERT content team,
        so, when ACTIVITY.FLG_TASKLIST="Y" means the entry does not form part of the NIC Classification. 
        
        A NIC Activity defined within a NIC Intervention as NIC_INTERV_ACTIVITY.FLG_TASK=Y are item tasks of a parent Activity.
        The activities defined as tasks does not appear in the listings to be ordered because, as explained before, are intended that do not make sense 
        be possible to request and document them individually.
        
        When NIC_INTERV_ACTIVITY.FLG_TASK=Y then must exists a NIC_ACTIVITY defined as FLG_TASKLIST=Y associated to this same NIC_INTERVENTION.
        
        Example:
        
        NIC_INTERVENTION: 
        10| "Bladder Irrigation"
        
        NIC_ACTIVITY: 
        20| "Execute Bladder irrigation"           | flg_tasklist="Y" <-- Is an activity created by ALERT and used as parent to group a set of NIC Activites.
        21| "Explain the procedure to the patient" | flg_tasklist="N" <-- Is an Activity defined by NIC - Nursing Interventions Classification
        
        NIC_INTERV_ACTIVITY:
        30| id_nic_intervention=10 | id_nic_activity=20 | flg_task="N" | id_parent=NULL
        31| id_nic_intervention=10 | id_nic_activity=21 | flg_task="Y" | id_parent=30
        
        */
    
        -- Sanity check about definition of NIC Activities as tasklist/tasks
        CASE
            WHEN i_parent_activity_code IS NOT NULL
                 AND i_flg_task != pk_alert_constant.g_yes THEN
                g_error := 'The i_parent_activity_code is only applicable when an activity is defined as i_task = Y';
            
                l_invalid_parent := TRUE;
            WHEN i_parent_activity_code IS NULL
                 AND i_flg_task = pk_alert_constant.g_yes THEN
                g_error := 'When an activity is defined as i_task = Y the i_parent_activity_code needs to be filled';
            
                l_invalid_parent := TRUE;
            WHEN i_flg_tasklist = pk_alert_constant.g_yes
                 AND (i_parent_activity_code IS NOT NULL OR i_flg_task = pk_alert_constant.g_yes) THEN
                g_error := 'An activity used as tasklist cannot be a task or have i_parent_activity_code filled';
            
                l_invalid_parent := TRUE;
            ELSE
                l_invalid_parent := FALSE;
        END CASE;
    
        IF l_invalid_parent
        THEN
            pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_parent_nic_activity',
                                               err_instance_id_out => l_err_id,
                                               text_in             => g_error,
                                               name1_in            => 'function_name',
                                               value1_in           => k_function_name,
                                               name2_in            => 'i_terminology_version',
                                               value2_in           => coalesce(to_char(i_terminology_version), '<null>'),
                                               name3_in            => 'i_parent_activity_code',
                                               value3_in           => coalesce(i_parent_activity_code, '<null>'),
                                               name4_in            => 'i_flg_task',
                                               value4_in           => coalesce(i_flg_task, '<null>'),
                                               name5_in            => 'i_flg_tasklist',
                                               value5_in           => coalesce(i_flg_tasklist, '<null>'));
            RAISE e_invalid_parent_nic_activity;
        END IF;
    
        IF i_parent_activity_code IS NOT NULL
        THEN
            g_error := 'Retrieves surrogate key of parent Activity defined as tasklisk';
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
            BEGIN
                SELECT nia.id_nic_interv_activity
                  INTO l_id_interv_activity_parent
                  FROM nic_interv_activity nia
                 INNER JOIN nic_activity na
                    ON na.id_nic_activity = nia.id_nic_activity
                 WHERE na.id_terminology_version = i_terminology_version
                   AND na.activity_code = i_parent_activity_code
                   AND na.flg_tasklist = pk_alert_constant.g_yes
                   AND nia.id_nic_intervention = l_id_nic_intervention;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'Parent NIC Activity not found in nic_interv_activity, or was not defined as tasklist.';
                    pk_alert_exceptions.register_error(error_name_in       => 'e_invalid_parent_nic_activity',
                                                       err_instance_id_out => l_err_id,
                                                       text_in             => g_error,
                                                       name1_in            => 'function_name',
                                                       value1_in           => k_function_name,
                                                       name2_in            => 'i_terminology_version',
                                                       value2_in           => coalesce(to_char(i_terminology_version),
                                                                                       '<null>'),
                                                       name3_in            => 'i_parent_activity_code',
                                                       value3_in           => coalesce(i_parent_activity_code, '<null>'));
                    RAISE e_invalid_parent_nic_activity;
            END;
        ELSE
            l_id_interv_activity_parent := NULL;
        END IF;
    
        g_error := 'Checks if the NIC Activity Code already exists in NIC_ACTIVITY table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
        l_rec.id_terminology_version := i_terminology_version;
        l_rec.activity_code          := i_activity_code;
        l_rec.flg_tasklist           := i_flg_tasklist;
        l_rec.id_inst_owner          := i_inst_owner;
        l_rec.id_concept_version     := i_concept_version;
        l_rec.id_concept_term        := i_concept_term;
        BEGIN
            -- Insert-optimistic
            ts_nic_activity.ins(rec_in => l_rec, gen_pky_in => TRUE, handle_error_in => FALSE, rows_out => l_lst_rowid);
        
            SELECT na.id_nic_activity, na.code_description
              INTO l_rec.id_nic_activity, l_rec.code_description
              FROM nic_activity na
             WHERE na.rowid = l_lst_rowid(1);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT na.id_nic_activity, na.code_description
                  INTO l_rec.id_nic_activity, l_rec.code_description
                  FROM nic_activity na
                 WHERE na.id_terminology_version = l_rec.id_terminology_version
                   AND na.activity_code = l_rec.activity_code;
            
                ts_nic_activity.upd(rec_in => l_rec, rows_out => l_lst_rowid);
        END;
    
        g_error := 'Checks if the Intervention/Activity already exists in NIC_INTERV_ACTIVITY relational table';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => k_function_name);
    
        l_rec_interv_activity.id_nic_intervention  := l_id_nic_intervention;
        l_rec_interv_activity.id_nic_activity      := l_rec.id_nic_activity;
        l_rec_interv_activity.interv_activity_code := i_interv_activity_code;
        l_rec_interv_activity.rank                 := i_rank;
        l_rec_interv_activity.flg_task             := i_flg_task;
        l_rec_interv_activity.id_parent            := l_id_interv_activity_parent;
        BEGIN
            -- Insert-optimistic
            ts_nic_interv_activity.ins(rec_in          => l_rec_interv_activity,
                                       gen_pky_in      => TRUE,
                                       handle_error_in => FALSE,
                                       rows_out        => l_lst_rowid);
        
        EXCEPTION
            WHEN dup_val_on_index THEN
                -- Entry already exist, then just update
                SELECT nia.id_nic_interv_activity
                  INTO l_rec_interv_activity.id_nic_interv_activity
                  FROM nic_interv_activity nia
                 WHERE nia.id_nic_intervention = l_rec_interv_activity.id_nic_intervention
                   AND nia.id_nic_activity = l_rec_interv_activity.id_nic_activity;
            
                ts_nic_interv_activity.upd(id_nic_interv_activity_in => l_rec_interv_activity.id_nic_interv_activity,
                                           interv_activity_code_in   => l_rec_interv_activity.interv_activity_code,
                                           rank_in                   => l_rec_interv_activity.rank,
                                           flg_task_in               => l_rec_interv_activity.flg_task,
                                           id_parent_in              => l_rec_interv_activity.id_parent,
                                           id_parent_nin             => FALSE,
                                           rows_out                  => l_lst_rowid);
        END;
    
        --insert <translation> record  
        pk_translation.insert_into_translation(i_lang       => i_lang,
                                               i_code_trans => l_rec.code_description,
                                               i_desc_trans => i_description);
    
    END insert_into_nic_activity;

    FUNCTION format_nic_name
    (
        i_label           IN pk_translation.t_desc_translation,
        i_nic_code        IN nic_intervention.intervention_code%TYPE,
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
           OR i_nic_code IS NULL
        THEN
            l_desc := i_label;
        ELSE
            -- Outcome code may appear before or after description,
            -- depending on the configuration ("S"tart or "E"nd);
            IF i_code_format = pk_nic_model.g_code_format_start
            THEN
                l_desc := '(' || TRIM(to_char(i_nic_code, g_nic_code_format)) || ') ';
            
                l_desc := l_desc || i_label;
            ELSIF i_code_format = pk_nic_model.g_code_format_end
            THEN
                l_desc := i_label || ' ' || '(' || TRIM(to_char(i_nic_code, g_nic_code_format)) || ')';
            
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
    END format_nic_name;

    FUNCTION get_intervention_code(i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE)
        RETURN nic_intervention.intervention_code %TYPE IS
        l_intervention_code nic_intervention.intervention_code%TYPE;
    BEGIN
        SELECT nic_i.intervention_code
          INTO l_intervention_code
          FROM nic_intervention nic_i
         WHERE nic_i.id_nic_intervention = i_nic_intervention;
        RETURN l_intervention_code;
    END get_intervention_code;

    FUNCTION get_activity_code(i_nic_activity IN nic_activity.id_nic_activity%TYPE) RETURN nic_activity.activity_code %TYPE IS
        l_activity_code nic_activity.activity_code%TYPE;
    BEGIN
        SELECT nic_a.activity_code
          INTO l_activity_code
          FROM nic_activity nic_a
         WHERE nic_a.id_nic_activity = i_nic_activity;
        RETURN l_activity_code;
    END get_activity_code;

    FUNCTION get_interv_activity_code
    (
        i_nic_intervention IN nic_interv_activity.id_nic_intervention%TYPE,
        i_nic_activity     IN nic_interv_activity.id_nic_activity%TYPE
    ) RETURN nic_interv_activity.interv_activity_code%TYPE IS
        l_interv_activity_code nic_interv_activity.interv_activity_code%TYPE;
    BEGIN
        SELECT nic_ia.interv_activity_code
          INTO l_interv_activity_code
          FROM nic_interv_activity nic_ia
         WHERE nic_ia.id_nic_intervention = i_nic_intervention
           AND nic_ia.id_nic_activity = i_nic_activity;
        RETURN l_interv_activity_code;
    END get_interv_activity_code;

    FUNCTION get_intervention_name
    (
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        i_code_format      IN VARCHAR2 DEFAULT g_code_format_none,
        i_additional_info  IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache IS
        l_name     pk_translation.t_desc_translation;
        l_nic_code nic_intervention.intervention_code%TYPE;
    BEGIN
    
        SELECT pk_translation.get_translation(i_lang      => pk_nnn_core.get_terminology_language(i_terminology_version => nic.id_terminology_version),
                                              i_code_mess => nic.code_name) name,
               nic.intervention_code
          INTO l_name, l_nic_code
          FROM nic_intervention nic
         WHERE nic.id_nic_intervention = i_nic_intervention;
    
        RETURN format_nic_name(i_label           => l_name,
                               i_nic_code        => l_nic_code,
                               i_code_format     => i_code_format,
                               i_additional_info => i_additional_info);
    
    END get_intervention_name;

    FUNCTION get_activity_name(i_nic_activity IN nic_activity.id_nic_activity%TYPE)
        RETURN pk_translation.t_desc_translation result_cache IS
        l_name pk_translation.t_desc_translation;
    BEGIN
        SELECT pk_translation.get_translation(i_lang      => pk_nnn_core.get_terminology_language(i_terminology_version => na.id_terminology_version),
                                              i_code_mess => na.code_description) name
          INTO l_name
          FROM nic_activity na
         WHERE na.id_nic_activity = i_nic_activity;
    
        RETURN l_name;
    END get_activity_name;

    FUNCTION get_nic_intervention
    (
        i_lang             IN language.id_language%TYPE,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE
    ) RETURN t_obj_nic_intervention IS
        l_lang language.id_language%TYPE;
        l_obj  t_obj_nic_intervention;
    BEGIN
    
        SELECT pk_nnn_core.get_terminology_language(i_terminology_version => ni.id_terminology_version)
          INTO l_lang
          FROM nic_intervention ni
         WHERE ni.id_nic_intervention = i_nic_intervention;
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        SELECT t_obj_nic_intervention(i_id_nic_intervention => ni.id_nic_intervention,
                                      i_nic_code            => ni.intervention_code,
                                      i_name                => pk_translation.get_translation(i_lang      => l_lang,
                                                                                              i_code_mess => ni.code_name),
                                      i_definition          => pk_translation.get_translation(i_lang      => l_lang,
                                                                                              i_code_mess => ni.code_definition),
                                      i_references          => ni.references)
          INTO l_obj
          FROM nic_intervention ni
         WHERE ni.id_nic_intervention = i_nic_intervention;
    
        -- NIC Interventions are grouped hierarchically into classes within domains 
        -- but there are a few interventions located in more than one class. 
        -- So, lhe classes are retrieved in a collection
        SELECT t_obj_nic_class(i_id_nic_class => nc.id_nic_class,
                               i_class_code   => nc.class_code,
                               i_name         => pk_translation.get_translation(i_lang      => l_lang,
                                                                                i_code_mess => nc.code_name),
                               i_definition   => pk_translation.get_translation(i_lang      => l_lang,
                                                                                i_code_mess => nc.code_definition),
                               i_domain       => t_obj_nic_domain(i_id_nic_domain => nd.id_nic_domain,
                                                                  i_domain_code   => nd.domain_code,
                                                                  i_name          => pk_translation.get_translation(i_lang      => l_lang,
                                                                                                                    i_code_mess => nd.code_name),
                                                                  i_definition    => pk_translation.get_translation(i_lang      => l_lang,
                                                                                                                    i_code_mess => nd.code_definition))) BULK COLLECT
          INTO l_obj.lst_class
          FROM nic_class_interv nci
         INNER JOIN nic_class nc
            ON nci.id_nic_class = nc.id_nic_class
         INNER JOIN nic_domain nd
            ON nc.id_nic_domain = nd.id_nic_domain
         WHERE nci.id_nic_intervention = i_nic_intervention;
    
        RETURN l_obj;
    END get_nic_intervention;

    FUNCTION get_nic_activity
    (
        i_lang             IN language.id_language%TYPE,
        i_nic_intervention IN nic_interv_activity.id_nic_intervention%TYPE,
        i_nic_activity     IN nic_interv_activity.id_nic_activity%TYPE
    ) RETURN t_obj_nic_activity IS
        l_lang language.id_language%TYPE;
        l_obj  t_obj_nic_activity;
    
    BEGIN
        SELECT pk_nnn_core.get_terminology_language(i_terminology_version => na.id_terminology_version)
          INTO l_lang
          FROM nic_activity na
         WHERE na.id_nic_activity = i_nic_activity;
        IF coalesce(l_lang, 0) = 0
        THEN
            l_lang := i_lang;
        END IF;
    
        SELECT t_obj_nic_activity(i_id_nic_activity      => na.id_nic_activity,
                                  i_description          => pk_translation.get_translation(i_lang      => l_lang,
                                                                                           i_code_mess => na.code_description),
                                  i_interv_activity_code => get_interv_activity_code(i_nic_intervention => i_nic_intervention,
                                                                                     i_nic_activity     => i_nic_activity))
          INTO l_obj
          FROM nic_activity na
         WHERE na.id_nic_activity = i_nic_activity;
    
        RETURN l_obj;
    END get_nic_activity;

    FUNCTION is_tasklist(i_nic_activity IN nic_activity.id_nic_activity%TYPE) RETURN nic_activity.flg_tasklist%TYPE result_cache IS
        l_flg_tasklist nic_activity.flg_tasklist%TYPE;
    BEGIN
        SELECT na.flg_tasklist
          INTO l_flg_tasklist
          FROM nic_activity na
         WHERE na.id_nic_activity = i_nic_activity;
    
        RETURN l_flg_tasklist;
    END is_tasklist;

    FUNCTION get_terminology_information(i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE)
        RETURN pk_nnn_in.t_terminology_info_rec IS
        l_terminology_version nic_intervention.id_terminology_version%TYPE;
        l_terminology_info    pk_nnn_in.t_terminology_info_rec;
    BEGIN
        SELECT ni.id_terminology_version
          INTO l_terminology_version
          FROM nic_intervention ni
         WHERE ni.id_nic_intervention = i_nic_intervention;
    
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
END pk_nic_model;
/
