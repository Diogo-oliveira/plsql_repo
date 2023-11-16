/*-- Last Change Revision: $Rev: 2026991 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:39 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_doc_activity IS

    g_error VARCHAR2(2000);

    -------------------------------------------------------------------------------------------------
    --
    --                               INTERNAL METHODS
    --
    -------------------------------------------------------------------------------------------------

    /**
    * Get required and optional parameters for this profissional
    *
    * @param i_lang              id language
    * @param i_prof              professional, software and institution ids
    * @param i_operation         operation name
    * @param i_target            target name
    * @param o_operation_param   type with types for the operation
    * @param o_error             error message
    *
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    * 
    * @author        jorge.costa
    * @version       2
    * @since         15/11/2014
    */
    FUNCTION get_operation_parameters
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_operation       IN VARCHAR2,
        i_target          IN VARCHAR2,
        o_operation_param OUT NOCOPY doc_param_list,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_records          table_number;
        l_profile_template NUMBER;
        l_category         NUMBER;
    
        l_number NUMBER;
    
        CURSOR param IS
            SELECT dap.param_name, NULL, daop.flg_required, NULL
              FROM doc_operation_conf doc
             INNER JOIN doc_act_op_param daop
                ON daop.operation_name = doc.operation_name
               AND daop.target_name = doc.operation_name
               AND daop.source_name = doc.source_name
             INNER JOIN doc_operation do
                ON doc.operation_name = do.operation_name
               AND do.operation_name = i_operation
             INNER JOIN doc_act_param dap
                ON daop.param_name = dap.param_name
             INNER JOIN doc_act_entity dae
                ON doc.target_name = dae.entity_name
               AND dae.entity_name = i_target
             WHERE daop.id_record IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       column_value id
                                        FROM TABLE(l_records) t);
    
    BEGIN
        g_error            := 'Getting profile template';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error    := 'Getting professional category';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        l_records := pk_core_config.get_config_records(i_area             => 'DOC_ACTIVITY',
                                                       i_prof             => i_prof,
                                                       i_market           => 0,
                                                       i_category         => l_category,
                                                       i_profile_template => l_profile_template,
                                                       i_prof_dcs         => table_number(0),
                                                       i_episode_dcs      => 0);
    
        l_number := l_records.count;
        g_error  := 'Getting parameters';
        OPEN param;
        FETCH param BULK COLLECT
            INTO o_operation_param;
        CLOSE param;
    
        RETURN TRUE;
    
    END get_operation_parameters;

    FUNCTION get_operation_description
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_operation_name IN VARCHAR2,
        i_target         IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_description VARCHAR2(200 CHAR);
    
        l_transmit_operation VARCHAR2(200 CHAR) := 'TRANSMIT';
    
    BEGIN
        -- If the document was transmitted, the translation has to be specific for the target
        IF i_operation_name = l_transmit_operation
        THEN
        
            IF i_target = 'EMAIL'
            THEN
                SELECT pk_message.get_message(i_lang, 'ARCHIVE_DETAIL_FIELDS_T020')
                  INTO l_description
                  FROM dual;
            ELSE
                SELECT pk_translation.get_translation(i_lang, do.code_operation) || ' (' ||
                       pk_translation.get_translation(i_lang, dat.code_entity) || ')'
                  INTO l_description
                  FROM doc_operation do
                 INNER JOIN doc_act_entity dat
                    ON dat.entity_name = i_target
                 WHERE do.operation_name = i_operation_name;
            END IF;
        
        ELSE
            SELECT pk_translation.get_translation(i_lang, do.code_operation)
              INTO l_description
              FROM doc_operation do
             WHERE do.operation_name = i_operation_name;
        END IF;
    
        RETURN l_description;
    END;

    /**
    * Get specific activity occurred on the document
    *
    * @param i_lang              id language
    * @param i_prof              professional, software and institution ids
    * @param i_oid_doc           document oid
    * @param i_op_source         operation source name
    * @param i_op_target         operation target name
    * @param i_id_operation      operation name
    * @param o_doc_activity      type with activity occurred
    * @param o_error             error message
    *
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION get_specific_doc_activity
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_oid_doc      IN VARCHAR2,
        i_op_source    IN VARCHAR2,
        i_op_target    IN VARCHAR2,
        i_id_operation IN VARCHAR2,
        o_doc_activity OUT t_doc_activity_list,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        doc_external_oid sys_config.value%TYPE;
    
        l_records          table_number;
        l_profile_template NUMBER;
        l_category         NUMBER;
    
        l_number NUMBER;
    
        l_doc     NUMBER;
        l_doc_aux doc_external.doc_oid%TYPE;
    BEGIN
    
        g_error          := 'Get document OID base';
        doc_external_oid := pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL', i_prof);
    
        g_error            := 'Getting profile template';
        l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error    := 'Getting professional category';
        l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        l_records := pk_core_config.get_config_records(i_area             => 'DOC_ACTIVITY',
                                                       i_prof             => i_prof,
                                                       i_market           => 0,
                                                       i_category         => l_category,
                                                       i_profile_template => l_profile_template,
                                                       i_prof_dcs         => table_number(0),
                                                       i_episode_dcs      => 0);
    
        l_number := l_records.count;
    
        l_doc_aux := regexp_replace(i_oid_doc, doc_external_oid || '.', '');
        IF instr(l_doc_aux, '.') = 0
        THEN
            l_doc := to_number(l_doc_aux);
        END IF;
        g_error := 'Select document activity';
        WITH doc_versions AS
         (SELECT de.id_doc_external
            FROM doc_external de
           WHERE de.doc_oid = i_oid_doc
          UNION
          SELECT de.id_doc_external
            FROM doc_external de
           WHERE de.id_doc_external = l_doc)
        SELECT t_doc_activity(prof.name,
                              prof.id_professional,
                              to_char(da.dt_operation, 'yyyy/mm/dd HH24:MI:SS TZR'),
                              da.dt_operation,
                              get_operation_description(i_lang, i_prof, do.operation_name, dae_t.entity_name),
                              do.operation_name,
                              da.id_institution,
                              pk_translation.get_translation(i_lang,
                                                             'INSTITUTION.CODE_INSTITUTION.' || da.id_institution),
                              da.id_doc_external,
                              dae_s.entity_name,
                              pk_translation.get_translation(i_lang, dae_s.code_entity),
                              dae_t.entity_name,
                              pk_translation.get_translation(i_lang, dae_t.code_entity),
                              CAST(MULTISET
                                   (SELECT t_param(dp.param_name, pk_translation.get_translation_trs(dap.param_value))
                                      FROM doc_activity_param dap,
                                           doc_act_param      dp,
                                           doc_operation_conf doc,
                                           doc_act_op_param   daop
                                     WHERE doc.operation_name = daop.operation_name
                                       AND doc.target_name = daop.target_name
                                       AND doc.source_name = daop.source_name
                                       AND dap.id_doc_activity = da.id_doc_activity
                                       AND dap.param_name = daop.param_name
                                       AND daop.id_record IN (SELECT *
                                                                FROM TABLE(l_records))
                                       AND daop.flg_visible_on_ux = g_flg_yes
                                       AND dap.param_name = dp.param_name
                                     ORDER BY daop.rank) AS t_param_list))
          BULK COLLECT
          INTO o_doc_activity
          FROM doc_activity da
         INNER JOIN doc_operation_conf doc
            ON da.id_doc_operation_conf = doc.id_doc_operation_config
         INNER JOIN professional prof
            ON da.id_professional = prof.id_professional
         INNER JOIN doc_operation do
            ON doc.operation_name = do.operation_name
         INNER JOIN doc_versions dv
            ON da.id_doc_external = dv.id_doc_external
         INNER JOIN doc_act_entity dae_s
            ON doc.source_name = dae_s.entity_name
         INNER JOIN doc_act_entity dae_t
            ON doc.target_name = dae_t.entity_name
         WHERE doc.operation_name = nvl(i_id_operation, doc.operation_name)
           AND doc.source_name = nvl(i_op_source, doc.source_name)
           AND doc.target_name = nvl(i_op_target, doc.target_name)
           AND da.flg_status = 'S'
         ORDER BY da.dt_operation DESC;
    
        RETURN TRUE;
    
    END get_specific_doc_activity;

    -------------------------------------------------------------------------------------------------
    --
    --                                PUBLIC METHODS
    --
    -------------------------------------------------------------------------------------------------

    /**
    * Log activity on the document
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_doc_id            document id
    * @param i_operation         Operation code
    * @param i_source            Source code
    * @param i_target            Target code
    * @param i_status            Operation status
    * @param i_operation_param   Operation parameters
    * 
    * @value i_status            {*} 'P' Pending {*} 'A' Active
    * 
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION log_document_activity
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_doc_id          IN NUMBER,
        i_operation       IN VARCHAR2,
        i_source          IN VARCHAR2,
        i_target          IN VARCHAR2,
        i_status          IN VARCHAR2 DEFAULT 'S',
        i_operation_param IN t_param_list,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_doc_operation_conf   NUMBER;
        l_operation_parameters    doc_param_list;
        l_parameters_to_insert    doc_param_list;
        l_parameterstoinsertcount NUMBER;
        l_existparameter          BOOLEAN;
    
        l_newdocactivityid      NUMBER;
        l_newdocactivityparamid NUMBER;
        l_translation_trs_code  VARCHAR2(200 CHAR);
    
        l_rows_out table_varchar;
    
        required_parameters_missing EXCEPTION;
    
        l_num_docs NUMBER(24);
    BEGIN
        g_error := 'Verify if document is a doc_External entry';
        SELECT COUNT(*)
          INTO l_num_docs
          FROM doc_external d
         WHERE d.id_doc_external = i_doc_id;
    
        IF l_num_docs = 0
        THEN
            RETURN TRUE;
        END IF;
    
        SELECT doc.id_doc_operation_config
          INTO l_id_doc_operation_conf
          FROM doc_operation_conf doc
         WHERE doc.operation_name = i_operation
           AND doc.target_name = i_target
           AND doc.source_name = i_source
           AND doc.flg_available = g_flg_yes;
    
        g_error := 'Getting parameters for this operation';
        IF NOT get_operation_parameters(i_lang            => i_lang,
                                        i_prof            => i_prof,
                                        i_operation       => i_operation,
                                        i_target          => i_target,
                                        o_operation_param => l_operation_parameters,
                                        o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- Before regist operation, it's necessary verify if all required parameters are filled in
    
        IF l_operation_parameters.count > 0
        THEN
            --l_parameters_to_insert    := doc_param_list();
            l_parameterstoinsertcount := 0;
            --l_parameters_to_insert.extend(l_parametersToInsertCount);
        
            g_error := 'Checking and creating list with operation parameters';
            FOR i IN 1 .. l_operation_parameters.count
            LOOP
            
                l_existparameter := FALSE;
            
                FOR j IN 1 .. i_operation_param.count
                LOOP
                    IF l_operation_parameters(i).param_name = i_operation_param(j).param_name
                    THEN
                        l_parameterstoinsertcount := l_parameterstoinsertcount + 1;
                    
                        l_parameters_to_insert(l_parameterstoinsertcount).param_name := i_operation_param(j).param_name;
                        l_parameters_to_insert(l_parameterstoinsertcount).flg_required := NULL;
                        l_parameters_to_insert(l_parameterstoinsertcount).param_value := i_operation_param(j).param_value;
                    
                        l_existparameter := TRUE;
                    END IF;
                END LOOP;
            
                IF l_operation_parameters(i).flg_required = g_flg_yes
                THEN
                    IF NOT l_existparameter
                    THEN
                        RAISE required_parameters_missing;
                    END IF;
                END IF;
            
            END LOOP;
        
            -- Inserting document activity
            g_error            := 'Inserting document activity';
            l_newdocactivityid := seq_doc_activity.nextval;
            ts_doc_activity.ins(id_doc_activity_in       => l_newdocactivityid,
                                id_doc_external_in       => i_doc_id,
                                id_professional_in       => i_prof.id,
                                id_institution_in        => i_prof.institution,
                                dt_operation_in          => current_timestamp,
                                flg_status_in            => nvl(i_status, 'S'),
                                id_doc_operation_conf_in => l_id_doc_operation_conf,
                                rows_out                 => l_rows_out);
        
            -- Inserting document activity parameters
            g_error := 'Inserting document activity';
            FOR i IN 1 .. l_parameterstoinsertcount
            LOOP
            
                l_newdocactivityparamid := seq_doc_activity_param.nextval;
                l_translation_trs_code  := g_translation_trs_code_base || l_newdocactivityparamid;
                pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                      i_code   => l_translation_trs_code,
                                                      i_desc   => l_parameters_to_insert(i).param_value,
                                                      i_module => 'DOC_ACTIVITY_PARAM');
            
                ts_doc_activity_param.ins(id_doc_activity_param_in => l_newdocactivityparamid,
                                          id_doc_activity_in       => l_newdocactivityid,
                                          param_name_in            => l_parameters_to_insert(i).param_name,
                                          param_value_in           => l_translation_trs_code);
            END LOOP;
        
        ELSE
            g_error            := 'Inserting document activity';
            l_newdocactivityid := seq_doc_activity.nextval;
            ts_doc_activity.ins(id_doc_activity_in       => l_newdocactivityid,
                                id_doc_external_in       => i_doc_id,
                                id_professional_in       => i_prof.id,
                                id_institution_in        => i_prof.institution,
                                dt_operation_in          => current_timestamp,
                                flg_status_in            => nvl(i_status, 'S'),
                                id_doc_operation_conf_in => l_id_doc_operation_conf,
                                rows_out                 => l_rows_out);
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'No data found';
            o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
            RETURN FALSE;
        
        WHEN required_parameters_missing THEN
            g_error := 'Required parameters are missing';
            o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            ROLLBACK;
            IF SQLCODE = -20001
            THEN
                g_error := 'You are trying to update a resgist with an invalid status';
                o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
                pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
            
                RETURN FALSE;
            ELSE
                RAISE;
            END IF;
        
    END log_document_activity;

    /**
    * Update last registered operation on the document to fail
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_doc_id            document id
    * @param i_operation         Operation code
    * @param i_source            Source code
    * @param i_target            Target code
    * @param i_operation_param   Operation parameters
    * 
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION delete_document_activity
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_doc_id    IN NUMBER,
        i_operation IN VARCHAR2,
        i_source    IN VARCHAR2,
        i_target    IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_iddocactivity NUMBER;
    
    BEGIN
    
        g_error := 'Select document history log';
        WITH doc_versions AS
         (SELECT de.id_doc_external
            FROM doc_external de, doc_external deg
           WHERE deg.id_doc_external = i_doc_id
             AND deg.id_grupo = de.id_grupo)
        SELECT MAX(da.id_doc_activity)
          INTO l_iddocactivity
          FROM doc_activity da, doc_versions dv, doc_operation_conf doc
         WHERE da.id_doc_external = dv.id_doc_external
           AND da.id_doc_operation_conf = doc.id_doc_operation_config
           AND doc.operation_name = i_operation
           AND doc.target_name = i_target
           AND doc.source_name = i_source;
    
        g_error := 'Delete operation parameters';
        DELETE FROM doc_activity_param dap
         WHERE dap.id_doc_activity = l_iddocactivity;
    
        g_error := 'Update document activity to fail';
        ts_doc_activity.upd(id_doc_activity_in => l_iddocactivity, flg_status_in => 'F');
        --ts_doc_activity.del(id_doc_activity_in => l_idDocActivity);
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
            RETURN FALSE;
        
    END delete_document_activity;

    /**
    * Uptade registered activity status
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc_activity   Activity id
    * @param i_new_status        New status
    * @param i_source            Source code
    * @param i_target            Target code
    * @param i_operation_param   Operation parameters
    * 
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION update_doc_activity_status
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_doc_activity IN NUMBER,
        i_new_status      IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'Updating field';
        ts_doc_activity.upd(id_doc_activity_in => i_id_doc_activity, flg_status_in => i_new_status);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20001
            THEN
                g_error := 'You are trying to update a resgist with an invalid status';
                o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
                pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
            
                RETURN FALSE;
            ELSE
                RAISE;
            END IF;
    END;

    FUNCTION update_doc_activity_status
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_param      IN t_param,
        i_new_status IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_idactivity NUMBER;
    BEGIN
        g_error := 'Getting id doc activity';
        SELECT dap.id_doc_activity
          INTO l_idactivity
          FROM doc_activity_param dap
         INNER JOIN doc_act_param dp
            ON dap.param_name = dp.param_name
           AND dp.param_name = i_param.param_name
         WHERE dbms_lob.compare(to_clob(pk_translation.get_translation_trs(dap.param_value)),
                                to_clob(i_param.param_value)) = 0;
    
        g_error := 'Call update_doc_activity_status';
        RETURN update_doc_activity_status(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_id_doc_activity => l_idactivity,
                                          i_new_status      => i_new_status,
                                          o_error           => o_error);
    
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'No data found for activity with ' || i_param.param_name || ' = ' || i_param.param_value;
            o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            IF SQLCODE = -01422
            THEN
                g_error := 'More than 1 activity with ' || i_param.param_name || ' = ' ||
                           pk_translation.get_translation_trs(i_param.param_value);
                o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
                pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
                RETURN FALSE;
            ELSIF SQLCODE = -20001
            THEN
                g_error := 'You are trying to update a resgist with an invalid status';
                o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
                pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
            
                RETURN FALSE;
            ELSE
                RAISE;
            END IF;
        
    END;

    /**
    * Get document activity
    *
    * @param i_lang              id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    * @param o_doc_activity      type with ocurred activity
    * @param o_error             error message
    *
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION get_doc_activity
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_doc       IN VARCHAR2,
        o_doc_activity OUT t_doc_activity_list,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        doc_external_oid sys_config.value%TYPE;
        l_doc_oid        VARCHAR2(200 CHAR);
    BEGIN
    
        g_error          := 'Get document OID base';
        doc_external_oid := pk_sysconfig.get_config('ALERT_OID_HIE_DOC_EXTERNAL', i_prof);
        -- 
        g_error := 'Get id group';
        SELECT nvl(de.doc_oid, doc_external_oid || '.' || nvl(de.id_grupo, de.id_doc_external))
          INTO l_doc_oid
          FROM doc_external de
         WHERE de.id_doc_external = i_id_doc;
    
        g_error := 'Select document history log';
        RETURN get_specific_doc_activity(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_oid_doc      => l_doc_oid,
                                         i_op_source    => NULL,
                                         i_op_target    => NULL,
                                         i_id_operation => NULL,
                                         o_doc_activity => o_doc_activity,
                                         o_error        => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20001
            THEN
                o_error := t_error_out(SQLCODE, SQLERRM, g_error, NULL, NULL, NULL, NULL, NULL);
                g_error := SQLCODE || ' ' || SQLERRM;
                pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
            
                RETURN FALSE;
            ELSE
                RAISE;
            END IF;
    END get_doc_activity;

    /**
    * Get document activity
    *
    * @param i_lang              id language
    * @param i_prof              professional, software and institution ids
    * @param i_oid_doc           document oid
    * @param o_doc_activity      type with ocurred activity
    * @param o_error             error message
    *
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION get_doc_activity
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_oid_doc      IN VARCHAR2,
        o_doc_activity OUT t_doc_activity_list,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Select document history log';
        RETURN get_specific_doc_activity(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_oid_doc      => i_oid_doc,
                                         i_op_source    => NULL,
                                         i_op_target    => NULL,
                                         i_id_operation => NULL,
                                         o_doc_activity => o_doc_activity,
                                         o_error        => o_error);
    END get_doc_activity;

    /**
    * Get sent emails with document
    *
    * @param i_lang              id language
    * @param i_prof              professional, software and institution ids
    * @param i_id_doc            document id
    * @param o_doc_activity      type with ocurred activity
    * @param o_error             error message
    *
    * @return                    Return BOOLEAN
    *
    * @author        jorge.costa
    * @version       1
    * @since         21/05/2014
    */
    FUNCTION get_sent_emails
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_id_doc       IN NUMBER,
        o_doc_activity OUT t_doc_activity_list,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        doc_external_oid sys_config.value%TYPE;
    BEGIN
        g_error := 'Get document OID base';
        SELECT s.value
          INTO doc_external_oid
          FROM sys_config s
         WHERE s.id_sys_config = 'ALERT_OID_HIE_DOC_EXTERNAL';
    
        g_error := 'Getting specific document activity';
        RETURN get_specific_doc_activity(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_oid_doc      => doc_external_oid,
                                         i_op_source    => 'EHR',
                                         i_op_target    => 'EMAIL',
                                         i_id_operation => 'TRANSMIT',
                                         o_doc_activity => o_doc_activity,
                                         o_error        => o_error);
    
    END;

BEGIN
    -- Log init
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);

    pk_alertlog.log_init(owner => g_package_owner, object_name => g_package_name);

END pk_doc_activity;
/
