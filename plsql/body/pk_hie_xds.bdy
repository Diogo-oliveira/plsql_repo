/*-- Last Change Revision: $Rev: 2027204 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_hie_xds IS
    g_package_name  VARCHAR2(32 CHAR);
    g_package_owner VARCHAR2(32 CHAR);
    g_error         VARCHAR2(4000 CHAR);
    g_exception EXCEPTION;

    /********************************************************************************************
    * Submit a document for HIE - for internal use only
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Doc external identifier
    * @param i_conf_code                 Conf code
    * @param i_desc_conf_code            Conf code description
    * @param i_code_coding_schema        Conf code schema
    * @param i_conf_code_set             Conf code set
    * @param i_desc_conf_code_set        Conf code set description
    * @param i_flg_status                Flag status
    * @param i_xds_doc_submission        Document submission Id - if null then we will get from sequence
    * @param i_value                     Transactional Model field: Value (amount of money) of the document submission to HIE.
    * @param i_currency                  Transactional Model field: Currency used in the transaction
    * @param i_desc_item                 Transactional Model field: Code of the document submited
    *    
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Carlos Guilherme
    * @version 2.6.0.4
    * @since   17-Nov-2010
    **********************************************************************************************/
    FUNCTION set_submit_doc_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        i_value              IN xds_document_submission.value%TYPE,
        i_currency           IN currency.id_currency%TYPE,
        i_desc_item          IN xds_document_submission.desc_item%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Submit a document for HIE - for internal use only
    *
    * @param i_lang                      Language id
    * @param i_prof                      Professional type
    * @param i_doc_external              Doc external identifier
    * @param i_conf_code                 Conf code
    * @param i_desc_conf_code            Conf code description
    * @param i_code_coding_schema        Conf code schema
    * @param i_conf_code_set             Conf code set
    * @param i_desc_conf_code_set        Conf code set description
    * @param i_flg_status                Flag status
    * @param i_xds_doc_submission        Document submission Id - if null then we will get from sequence
    * @param i_value                     Transactional Model field: Value (amount of money) of the document submission to HIE.
    * @param i_currency                  Transactional Model field: Currency used in the transaction
    * @param i_desc_item                 Transactional Model field: Code of the document submited
    * @param i_send_to_hie               Flag to indicate if document is to be sent to INTER-ALERT (Y|N)
    *    
    * @param o_error                     Error message
    *                        
    * @return                            True or False on success or error
    *
    * @author  Carlos Guilherme
    * @version 2.6.0.5
    * @since   22-dez-2010
    **********************************************************************************************/
    FUNCTION set_submit_doc_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        i_value              IN xds_document_submission.value%TYPE,
        i_currency           IN currency.id_currency%TYPE,
        i_desc_item          IN xds_document_submission.desc_item%TYPE,
        i_flg_send_to_hie    IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_available_documents
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_documents OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_profile_template profile_template.id_profile_template%TYPE;
    
    BEGIN
    
        l_prof_profile_template := pk_prof_utils.get_prof_profile_template(i_prof);
    
        OPEN o_documents FOR
            SELECT xdd.id_doc_external,
                   xdd.doc_author_institution,
                   xdd.type_code_display_name document,
                   (SELECT pk_translation.get_translation(i_lang, l.code_language)
                      FROM LANGUAGE l
                     WHERE l.id_language = xdd.id_language) doc_language,
                   pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                   xdd.pract_set_code_display_name episode_specialty,
                   xdd.subm_author_institution,
                   pk_date_utils.date_send_tsz(i_lang, xdd.submission_time, i_prof) submission_time,
                   pk_date_utils.date_send_tsz(i_lang, xdd.med_discharge_time, i_prof) med_discharge_time
            
              FROM v_xds_document_data xdd
             INNER JOIN epis_type et
                ON et.id_epis_type = xdd.id_epis_type
             WHERE xdd.id_episode = i_episode;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_AVAILABLE_DOCUMENTS');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
    END get_available_documents;

    FUNCTION get_document_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_doc_external  IN doc_external.id_doc_external%TYPE,
        o_document_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_document_info FOR
            SELECT xdd.id_doc_external,
                   xdd.doc_author_institution,
                   xdd.type_code_display_name document,
                   (SELECT pk_translation.get_translation(i_lang, l.code_language)
                      FROM LANGUAGE l
                     WHERE l.id_language = xdd.id_language) doc_language,
                   pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                   xdd.pract_set_code_display_name episode_specialty,
                   xdd.subm_author_institution,
                   pk_date_utils.date_send_tsz(i_lang, xdd.submission_time, i_prof) submission_time,
                   pk_date_utils.date_send_tsz(i_lang, xdd.med_discharge_time, i_prof) med_discharge_time,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, i_prof.id) current_prof_person
              FROM v_xds_document_data xdd
             INNER JOIN epis_type et
                ON et.id_epis_type = xdd.id_epis_type
             WHERE xdd.id_doc_external = i_doc_external;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOCUMENT_INFO');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
        
    END get_document_info;

    FUNCTION get_confidentiality_levels
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_conf_levels OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        OPEN o_conf_levels FOR
            SELECT cl.id_xds_confidentiality_level,
                   pk_translation.get_translation(i_lang, cl.code_confidentiality_level) desc_confidentiality_level,
                   rank
              FROM xds_confidentiality_level cl
             ORDER BY cl.rank, desc_confidentiality_level;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_CONFIDENTIALITY_LEVELS');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END get_confidentiality_levels;

    FUNCTION set_publish_document
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_doc_external            IN doc_external.id_doc_external%TYPE,
        i_conf_level              IN xds_confidentiality_level.id_xds_confidentiality_level%TYPE,
        o_xds_document_submission OUT xds_document_submission.id_xds_document_submission%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_doc_external doc_external.id_doc_external%TYPE;
    
    BEGIN
    
        g_error := 'Select the outside id_doc_external (id_grupo)';
        SELECT nvl(id_grupo, id_doc_external)
          INTO l_id_doc_external
          FROM doc_external
         WHERE id_doc_external = i_doc_external;
    
        g_error := 'Update old records with status I';
        UPDATE xds_document_submission xds
           SET xds.flg_status = g_subm_status_i, xds.dt_update = current_timestamp
         WHERE xds.id_doc_external = l_id_doc_external;
    
        g_error := 'Insert into XDS_DOCUMENT_SUBMISSION';
        INSERT INTO xds_document_submission
            (id_xds_document_submission,
             id_doc_external,
             id_professional,
             id_institution,
             --id_xds_confidentiality_level,
             dt_submission_time,
             flg_submission_status,
             flg_status,
             dt_create,
             dt_update)
        VALUES
            (seq_xds_document_submission.nextval,
             l_id_doc_external,
             i_prof.id,
             i_prof.institution,
             --i_conf_level,
             current_timestamp,
             pk_hie_constants.g_xds_submission_status_pend,
             g_subm_status_a,
             current_timestamp,
             current_timestamp)
        RETURNING id_xds_document_submission INTO o_xds_document_submission;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_PUBLISH_DOCUMENT');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
            END;
    END set_publish_document;

    FUNCTION get_confidentiality_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_conf_level xds_confidentiality_level.id_xds_confidentiality_level%TYPE
    ) RETURN VARCHAR2 IS
        l_desc pk_translation.t_desc_translation := NULL;
    BEGIN
        IF i_conf_level IS NOT NULL
        THEN
            SELECT pk_translation.get_translation(i_lang, xcl.code_confidentiality_level)
              INTO l_desc
              FROM xds_confidentiality_level xcl
             WHERE xcl.id_xds_confidentiality_level = i_conf_level;
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_ret       BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_PUBLISH_DOCUMENT');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error_out);
                RETURN NULL;
            END;
    END get_confidentiality_desc;

    /********************************************************************************************
    * Enables HIE XDS document sharing functionality
    * This function should be used only by configurations in order to enable the use of HIE XDS. 
    *
    * @param i_institution               Institution ID
    * @param i_enabled                   Functionality enabled (True/False)
    *                        
    * @return                            True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.5.0.7.3
    * @since   02-Dec-09
    **********************************************************************************************/
    FUNCTION set_xds_enabled
    (
        i_institution IN institution.id_institution%TYPE,
        i_enabled     IN BOOLEAN
    ) RETURN BOOLEAN IS
    
        l_value sys_config.value%TYPE;
    BEGIN
        IF i_enabled
        THEN
            l_value := pk_alert_constant.g_yes;
        ELSE
            l_value := pk_alert_constant.g_no;
        END IF;
    
        MERGE INTO sys_config sc
        USING (SELECT pk_hie_constants.g_xds_cfg_xds_enabled id_sys_config,
                      i_institution id_institution,
                      0 id_software,
                      'T' fill_type,
                      l_value VALUE
                 FROM dual) sys_conf
        ON (sc.id_sys_config = sys_conf.id_sys_config AND sc.id_institution = sys_conf.id_institution AND sc.id_software = sys_conf.id_software)
        WHEN MATCHED THEN
            UPDATE
               SET sc.value = sys_conf.value
        WHEN NOT MATCHED THEN
            INSERT
                (id_sys_config,
                 VALUE,
                 id_institution,
                 id_software,
                 fill_type,
                 client_configuration,
                 internal_configuration,
                 global_configuration,
                 desc_sys_config,
                 flg_schema)
            VALUES
                (sys_conf.id_sys_config,
                 sys_conf.value,
                 sys_conf.id_institution,
                 sys_conf.id_software,
                 sys_conf.fill_type,
                 pk_alert_constant.g_no,
                 pk_alert_constant.g_no,
                 pk_alert_constant.g_no,
                 (SELECT desc_sys_config
                    FROM (SELECT desc_sys_config
                            FROM sys_config cc
                           WHERE cc.id_sys_config = pk_hie_constants.g_xds_cfg_xds_enabled
                             AND cc.id_institution IN (i_institution, 0)
                             AND cc.id_software = 0
                           ORDER BY id_software DESC, id_institution DESC)
                   WHERE rownum < 2),
                 'A');
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_lang      NUMBER := to_number(pk_login_sysconfig.get_config('LANGUAGE'));
            BEGIN
                l_error_in.set_all(l_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_XDS_ENABLED');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END set_xds_enabled;

    FUNCTION get_report_transaction_number
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_report        IN epis_report.id_epis_report%TYPE,
        o_doc_submission_oid OUT VARCHAR2,
        o_doc_submission     OUT xds_document_submission.id_xds_document_submission%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Get next value';
        SELECT seq_xds_document_submission.nextval
          INTO o_doc_submission
          FROM dual;
    
        g_error              := 'Create OID';
        o_doc_submission_oid := pk_sysconfig.get_config('ALERT_OID_HIE_XDS_DOCUMENT_SUBMISSION_OID_SHORT', i_prof) || '.' ||
                                o_doc_submission;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_REPORT_TRANSACCION_NUMBER');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END get_report_transaction_number;

    FUNCTION set_submit_doc_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN set_submit_doc_internal(i_lang,
                                       i_prof,
                                       i_doc_external,
                                       i_conf_code,
                                       i_desc_conf_code,
                                       i_code_coding_schema,
                                       i_conf_code_set,
                                       i_desc_conf_code_set,
                                       i_flg_status,
                                       i_xds_doc_submission,
                                       NULL, -- i_value
                                       NULL, -- i_currency
                                       NULL, -- i_desc_item
                                       o_error);
    END set_submit_doc_internal;

    FUNCTION set_submit_doc_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        i_value              IN xds_document_submission.value%TYPE,
        i_currency           IN currency.id_currency%TYPE,
        i_desc_item          IN xds_document_submission.desc_item%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN set_submit_doc_internal(i_lang,
                                       i_prof,
                                       i_doc_external,
                                       i_conf_code,
                                       i_desc_conf_code,
                                       i_code_coding_schema,
                                       i_conf_code_set,
                                       i_desc_conf_code_set,
                                       i_flg_status,
                                       i_xds_doc_submission,
                                       i_value,
                                       i_currency,
                                       i_desc_item,
                                       'N', -- by default, doesn't send to HIE
                                       o_error);
    
    END set_submit_doc_internal;

    FUNCTION set_submit_doc_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        i_value              IN xds_document_submission.value%TYPE,
        i_currency           IN currency.id_currency%TYPE,
        i_desc_item          IN xds_document_submission.desc_item%TYPE,
        i_flg_send_to_hie    IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_xds_document_submission xds_document_submission.id_xds_document_submission%TYPE;
        l_has_records             VARCHAR2(1) := 'N';
        l_has_records_set         VARCHAR2(1) := 'N';
        l_id_doc_external         doc_external.id_doc_external%TYPE;
    
        l_exception EXCEPTION;
    
    BEGIN
        g_error := 'select the real id_doc_external for the outside - the id_grupo';
        SELECT nvl(id_grupo, id_doc_external)
          INTO l_id_doc_external
          FROM doc_external
         WHERE id_doc_external = i_doc_external;
    
        g_error := 'verify if the parameter is not null';
        IF i_conf_code.count > 0
        THEN
            l_has_records := 'Y';
            --else
            -- should return error
        END IF;
        --
        g_error := 'verify if the parameter is not null';
        IF i_conf_code_set.count > 0
        THEN
            l_has_records_set := 'Y';
            --else
            -- should return error
        END IF;
    
        g_error := 'Get seq_xds_document_submission.nextval';
        IF i_xds_doc_submission IS NULL
        THEN
            SELECT seq_xds_document_submission.nextval
              INTO l_xds_document_submission
              FROM dual;
        ELSE
            l_xds_document_submission := i_xds_doc_submission;
        END IF;
    
        g_error := 'Update old records with status I';
        UPDATE xds_document_submission xds
           SET xds.flg_status = g_subm_status_i, xds.dt_update = current_timestamp
         WHERE xds.id_doc_external = l_id_doc_external;
    
        g_error := 'Create a record in xds_document_submission with READY status';
        INSERT INTO xds_document_submission
            (id_xds_document_submission,
             id_doc_external,
             id_professional,
             id_institution,
             dt_submission_time,
             flg_submission_status,
             flg_submission_type,
             VALUE,
             id_currency,
             desc_item,
             flg_status,
             dt_create,
             dt_update)
        VALUES
            (l_xds_document_submission,
             l_id_doc_external,
             i_prof.id,
             i_prof.institution,
             current_timestamp,
             nvl(i_flg_status, g_flg_submission_status_n),
             nvl(i_flg_status, g_flg_submission_status_n),
             i_value,
             i_currency,
             i_desc_item,
             g_subm_status_a,
             current_timestamp,
             current_timestamp);
    
        -- log activity 
        g_error := 'Error registering document activity';
        IF NOT pk_doc_activity.log_document_activity(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_doc_id          => i_doc_external,
                                                     i_operation       => 'TRANSMIT',
                                                     i_source          => 'EHR',
                                                     i_target          => 'HIE',
                                                     i_operation_param => NULL,
                                                     o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'Insert into xds_document_sub_conf_code';
        IF l_has_records = 'Y'
        THEN
            FOR i IN 1 .. i_conf_code.count
            LOOP
                g_error := 'Create a record in xds_document_sub_conf_code (' || i || ')';
                INSERT INTO xds_document_sub_conf_code
                    (id_xds_document_sub_conf_code,
                     id_xds_document_submission,
                     conf_code,
                     desc_conf_code,
                     coding_schema)
                VALUES
                    (seq_xds_doc_sub_conf_code.nextval,
                     l_xds_document_submission,
                     i_conf_code(i),
                     i_desc_conf_code(i),
                     i_code_coding_schema(i));
            END LOOP;
        END IF;
        --
        g_error := 'Insert into xds_doc_sub_conf_code_set';
        IF l_has_records_set = 'Y'
        THEN
            FOR i IN 1 .. i_conf_code_set.count
            LOOP
                g_error := 'Create a record in xds_doc_sub_conf_code_set (' || i || ')';
                INSERT INTO xds_doc_sub_conf_code_set
                    (id_xds_doc_sub_conf_code_set, id_xds_document_submission, desc_conf_code_set)
                VALUES
                    (i_conf_code_set(i), l_xds_document_submission, i_desc_conf_code_set(i));
            END LOOP;
        END IF;
    
        --Tell INTER-ALERT to send Docs
        IF i_flg_send_to_hie = 'Y'
        THEN
            g_error := 'Sending id_doc_external ' || l_id_doc_external || 'to HIE';
            pk_ia_event_xds.xds_document_new(i_prof.institution, l_id_doc_external);
            --so faz commit se for p/ o INTER-AELRT. Se nao, é a função de Topo do PK_DOC que faz o commit;
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            BEGIN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_SUBMIT_DOC_INTERNAL',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END;
    END set_submit_doc_internal;

    FUNCTION set_submit_doc_internal
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_conf_code          table_varchar;
        l_desc_conf_code     table_varchar;
        l_code_coding_schema table_varchar;
        l_conf_code_set      table_varchar;
        l_desc_conf_code_set table_varchar;
    
    BEGIN
        g_error              := 'select default conf_values from sys_config';
        l_conf_code          := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_CONF_CODE', i_prof)); --Default value from SYS_CONFIG
        l_desc_conf_code     := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_DESC_CONF_CODE', i_prof)); --Default value from SYS_CONFIG
        l_code_coding_schema := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_CODE_CODING_SCHEMA', i_prof)); --Default value from SYS_CONFIG
        l_conf_code_set      := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_CONF_CODE_SET', i_prof)); --Default value from SYS_CONFIG
        l_desc_conf_code_set := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_DESC_CONF_CODE_SET', i_prof)); --Default value from SYS_CONFIG
    
        g_error := 'set_submit_doc_internal(com os paramentros todos)';
        RETURN set_submit_doc_internal(i_lang, --i_lang
                                       i_prof, --i_prof
                                       i_doc_external, --i_doc_external
                                       l_conf_code, --i_conf_code,
                                       l_desc_conf_code, --i_desc_conf_code,
                                       l_code_coding_schema, --i_code_coding_schema,
                                       l_conf_code_set, --i_conf_code_set
                                       l_desc_conf_code_set, --i_desc_conf_code_set
                                       g_flg_submission_status_n, --i_flg_status
                                       NULL, --i_xds_doc_submission
                                       o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_lang      NUMBER := to_number(pk_login_sysconfig.get_config('LANGUAGE'));
            BEGIN
                l_error_in.set_all(l_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_SUBMIT_DOC_INTERNAL');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END set_submit_doc_internal;

    FUNCTION set_submit_doc_for_reports
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        i_value              IN xds_document_submission.value%TYPE,
        i_currency           IN currency.id_currency%TYPE,
        i_desc_item          IN xds_document_submission.desc_item%TYPE,
        i_flg_send_to_hie    IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        RETURN set_submit_doc_internal(i_lang,
                                       i_prof,
                                       i_doc_external,
                                       i_conf_code,
                                       i_desc_conf_code,
                                       i_code_coding_schema,
                                       i_conf_code_set,
                                       i_desc_conf_code_set,
                                       i_flg_status,
                                       i_xds_doc_submission,
                                       i_value,
                                       i_currency,
                                       i_desc_item,
                                       i_flg_send_to_hie, -- by default, doesn't send to HIE
                                       o_error);
    
    END set_submit_doc_for_reports;

    FUNCTION get_doc_ext_by_epis_report(i_epis_report IN epis_report.id_epis_report%TYPE) RETURN NUMBER IS
        l_doc_external doc_external.id_doc_external%TYPE;
    BEGIN
        g_error := 'Get doc external from epis_report';
        SELECT id_doc_external
          INTO l_doc_external
          FROM epis_report er
         WHERE er.id_epis_report = i_epis_report;
    
        RETURN l_doc_external;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    --
    FUNCTION set_send_report_to_hie
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_report     IN epis_report.id_epis_report%TYPE,
        i_value           IN xds_document_submission.value%TYPE,
        i_currency        IN currency.id_currency%TYPE,
        i_desc_item       IN VARCHAR2,
        i_flg_send_to_hie IN VARCHAR2,
        i_hie_type        IN VARCHAR2,
        --
        o_xds_doc_submission IN OUT xds_document_submission.id_xds_document_submission%TYPE,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hie_type           sys_config.value%TYPE := pk_sysconfig.get_config('HIE_TYPE', i_prof);
        l_has_phr            VARCHAR2(1);
        l_doc_external       doc_external.id_doc_external%TYPE;
        l_report_oid         VARCHAR2(255);
        l_patient_id         patient.id_patient%TYPE;
        l_conf_code          table_varchar;
        l_desc_conf_code     table_varchar;
        l_code_coding_schema table_varchar;
        l_conf_code_set      table_varchar;
        l_desc_conf_code_set table_varchar;
    
        CURSOR c_patient IS
            SELECT e.id_patient
              FROM epis_report er, episode e
             WHERE er.id_epis_report = i_epis_report
               AND er.id_episode = e.id_episode;
    
    BEGIN
        IF i_flg_send_to_hie = g_flg_send_to_hie_y
        THEN
            g_error        := 'Get doc external from epis_report';
            l_doc_external := get_doc_ext_by_epis_report(i_epis_report);
        
            g_error := 'get_report_transaccion_number - Returns o_submission_id';
            IF o_xds_doc_submission IS NOT NULL
            THEN
                IF NOT get_report_transaction_number(i_lang,
                                                     i_prof,
                                                     i_epis_report,
                                                     l_report_oid,
                                                     o_xds_doc_submission,
                                                     o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            g_error              := 'select default conf_values from sys_config';
            l_conf_code          := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_CONF_CODE', i_prof)); --Default value from SYS_CONFIG
            l_desc_conf_code     := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_DESC_CONF_CODE', i_prof)); --Default value from SYS_CONFIG
            l_code_coding_schema := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_CODE_CODING_SCHEMA', i_prof)); --Default value from SYS_CONFIG
            l_conf_code_set      := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_CONF_CODE_SET', i_prof)); --Default value from SYS_CONFIG
            l_desc_conf_code_set := table_varchar(pk_sysconfig.get_config('HIE_DEFAULT_DESC_CONF_CODE_SET', i_prof)); --Default value from SYS_CONFIG
        
            IF l_hie_type = g_hie_type_d
            THEN
                OPEN c_patient;
                FETCH c_patient
                    INTO l_patient_id;
                CLOSE c_patient;
            
                g_error := 'If epis_report does not have id patient we will not call ADT API';
                IF l_patient_id IS NULL
                THEN
                    l_has_phr := g_has_phr_n;
                ELSE
                
                    g_error := 'Call ADT API that validates id patient has active PHR';
                    IF NOT pk_adt.has_external_account(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_patient => l_patient_id,
                                                       o_error   => o_error)
                    THEN
                        l_has_phr := g_has_phr_n;
                    ELSE
                        l_has_phr := g_has_phr_y;
                    END IF;
                
                END IF;
                --
                IF l_has_phr = g_has_phr_y
                THEN
                    g_error := 'submit_doc with READY status';
                    IF NOT set_submit_doc_internal(i_lang, --i_lang
                                                   i_prof, --i_prof
                                                   l_doc_external, --i_doc_external
                                                   l_conf_code, --i_conf_code,
                                                   l_desc_conf_code, --i_desc_conf_code,
                                                   l_code_coding_schema, --i_code_coding_schema,
                                                   l_conf_code_set, --i_conf_code_set
                                                   l_desc_conf_code_set, --i_desc_conf_code_set
                                                   g_flg_submission_status_n, --i_flg_status
                                                   o_xds_doc_submission, --i_xds_doc_submission
                                                   i_value,
                                                   i_currency,
                                                   i_desc_item,
                                                   'Y', -- send doc to HIE through INTER-ALERT
                                                   o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSIF l_has_phr = g_has_phr_n
                THEN
                    g_error := 'submit_doc with PENDING status';
                    IF NOT set_submit_doc_internal(i_lang,
                                                   i_prof,
                                                   l_doc_external,
                                                   l_conf_code, --i_conf_code,
                                                   l_desc_conf_code, --i_desc_conf_code,
                                                   l_code_coding_schema, --i_code_coding_schema,
                                                   l_conf_code_set, --i_conf_code_set
                                                   l_desc_conf_code_set, --i_desc_conf_code_set
                                                   g_flg_submission_status_p,
                                                   o_xds_doc_submission, --i_xds_doc_submission
                                                   i_value,
                                                   i_currency,
                                                   i_desc_item, --doesn't send to INTER-aELRT
                                                   o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                END IF;
            ELSIF l_hie_type = g_hie_type_r
            THEN
                g_error := 'submit_doc with READY status';
                IF NOT set_submit_doc_internal(i_lang,
                                               i_prof,
                                               l_doc_external,
                                               l_conf_code, --i_conf_code,
                                               l_desc_conf_code, --i_desc_conf_code,
                                               l_code_coding_schema, --i_code_coding_schema,
                                               l_conf_code_set, --i_conf_code_set
                                               l_desc_conf_code_set, --i_desc_conf_code_set
                                               g_flg_submission_status_n,
                                               o_xds_doc_submission, --i_xds_doc_submission
                                               i_value,
                                               i_currency,
                                               i_desc_item,
                                               'Y', -- send doc to HIE through INTER-ALERT
                                               o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
            RETURN TRUE;
        ELSE
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_SEND_REPORT_TO_HIE');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END set_send_report_to_hie;

    --
    FUNCTION set_send_pending_docs_to_hie
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_id_group IN institution_group.id_group%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_doc_externals table_number := table_number();
        l_inst             table_number := table_number();
        my_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'Get all related institutions';
    
        SELECT DISTINCT (id_institution)
          BULK COLLECT
          INTO l_inst
          FROM institution_group ig
         WHERE ig.id_group = i_id_group
           AND ig.flg_relation = pk_sysconfig.get_config('ADT_INSTITUTION_GROUP_ADT_FLG_TYPE', i_prof);
    
        IF l_inst.count = 0
        THEN
            RAISE my_exception;
        END IF;
    
        g_error := 'select id_doc_externals to be sent through INTER-ALERT';
        SELECT xds.id_doc_external
          BULK COLLECT
          INTO l_id_doc_externals
          FROM xds_document_submission xds, doc_external de
         WHERE de.id_patient = i_patient
           AND de.id_institution IN (SELECT column_value
                                       FROM TABLE(l_inst))
           AND de.flg_status = 'A'
           AND xds.id_doc_external = nvl(de.id_grupo, de.id_doc_external) -- todos os joins com a DOC_EXTERNAL tem de ser feitos pelo ID_GRUPO
           AND xds.flg_submission_status = g_flg_submission_status_p;
    
        g_error := 'Update all patient PENDING records to READY';
        UPDATE xds_document_submission xds
           SET xds.flg_submission_status = g_flg_submission_status_n, xds.dt_update = current_timestamp
         WHERE xds.flg_submission_status = g_flg_submission_status_p
           AND xds.id_doc_external IN (SELECT nvl(de.id_grupo, de.id_doc_external) -- todos os joins com a DOC_EXTERNAL tem de ser feitos pelo ID_GRUPO
                                         FROM doc_external de
                                        WHERE de.id_patient = i_patient
                                          AND de.flg_status = 'A'
                                          AND de.id_institution IN (SELECT column_value
                                                                      FROM TABLE(l_inst)))
           AND xds.flg_status = g_subm_status_a;
    
        --Tell INTER-ALERT to send Docs
        FOR i IN 1 .. l_id_doc_externals.count
        LOOP
            g_error := 'Sending id_doc_external ' || l_id_doc_externals(i) || 'to HIE';
            pk_ia_event_xds.xds_document_new(i_prof.institution, l_id_doc_externals(i));
        END LOOP;
    
        --ToDo XDS_DOCUMENT_SUB_CONF_LEVEL
        --Not needed because those records don't need any update
        COMMIT;
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_SEND_PENDING_DOCS_TO_HIE');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END set_send_pending_docs_to_hie;

    --
    FUNCTION delist_doc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN delist_doc(i_lang, i_prof, i_doc_external, TRUE, o_error);
    END delist_doc;

    --
    FUNCTION delist_doc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        i_do_commit    IN BOOLEAN,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_xds_doc IS
            SELECT xds.flg_submission_status
              FROM doc_external de, xds_document_submission xds
             WHERE de.id_doc_external = i_doc_external
               AND xds.id_doc_external = nvl(de.id_grupo, de.id_doc_external) --O join com a DOC_EXTERNAL tem de ser feito com o ID_GRUPO
               AND xds.flg_status = g_subm_status_a;
    
        l_status          xds_document_submission.flg_submission_status%TYPE;
        l_id_doc_external doc_external.id_doc_external%TYPE;
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'select the real id_doc_external for the outside - the id_grupo';
        SELECT nvl(id_grupo, id_doc_external)
          INTO l_id_doc_external
          FROM doc_external
         WHERE id_doc_external = i_doc_external;
    
        --check if that document was ever published 
        OPEN c_xds_doc;
        FETCH c_xds_doc
            INTO l_status;
        CLOSE c_xds_doc;
    
        -- it only makes sense to delete a document if it was published previously
        -- or not deleted previously
        IF SQL%FOUND
        THEN
            g_error := 'Update old records with status I';
            UPDATE xds_document_submission xds
               SET xds.flg_status = g_subm_status_i, xds.dt_update = current_timestamp
             WHERE xds.id_doc_external = l_id_doc_external;
        
            g_error := 'Create a record in xds_document_submission with DELIST status';
            INSERT INTO xds_document_submission
                (id_xds_document_submission,
                 id_doc_external,
                 id_professional,
                 id_institution,
                 dt_submission_time,
                 flg_submission_status,
                 flg_submission_type,
                 flg_status,
                 dt_create,
                 dt_update)
            VALUES
                (seq_xds_document_submission.nextval,
                 l_id_doc_external,
                 i_prof.id,
                 i_prof.institution,
                 current_timestamp,
                 g_flg_submission_status_d,
                 g_flg_submission_status_d,
                 g_subm_status_a,
                 current_timestamp,
                 current_timestamp);
        
            -- LOG ACTIVITY
            -- log activity 
            g_error := 'Error registering document activity';
            IF NOT pk_doc_activity.log_document_activity(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_doc_id          => l_id_doc_external,
                                                         i_operation       => 'DELIST',
                                                         i_source          => 'EHR',
                                                         i_target          => 'HIE',
                                                         i_operation_param => NULL,
                                                         o_error           => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        IF i_do_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_package_owner, g_package_name, 'DELIST_DOC');
            
                pk_utils.undo_changes;
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END delist_doc;

    --
    FUNCTION cancel_pending_docs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Update all patient PENDING records to CANCELED';
        UPDATE xds_document_submission xds
           SET xds.flg_submission_status = g_flg_submission_status_c, xds.dt_update = current_timestamp
         WHERE xds.flg_submission_status = g_flg_submission_status_p
           AND xds.id_doc_external IN (SELECT nvl(de.id_grupo, de.id_doc_external) -- o join com a doc_external tem que ser com o ID_GRUPO
                                         FROM doc_external de
                                        WHERE de.id_patient = i_patient)
           AND xds.flg_status = g_subm_status_a;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'CANCEL_PENDING_DOCS');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END cancel_pending_docs;

    --
    FUNCTION get_doc_sub_from_doc_ext
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        o_xds_doc_submission OUT xds_document_submission.id_xds_document_submission%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_xds_doc IS
            SELECT MAX(xds.id_xds_document_submission)
              FROM xds_document_submission xds
             WHERE xds.id_doc_external = (SELECT nvl(id_grupo, id_doc_external)
                                            FROM doc_external
                                           WHERE id_doc_external = i_doc_external) -- o join com a Doc_External tem de ser feito com o ID_GRUPO
               AND xds.flg_status = g_subm_status_a;
    BEGIN
        OPEN c_xds_doc;
        FETCH c_xds_doc
            INTO o_xds_doc_submission;
        CLOSE c_xds_doc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_DOC_SUB_FROM_DOC_EXT');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END get_doc_sub_from_doc_ext;
    --

    FUNCTION get_doc_sub_from_doc_ext
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_error        OUT t_error_out
    ) RETURN xds_document_submission.id_xds_document_submission%TYPE IS
    
        l_xds_doc_submission xds_document_submission.id_xds_document_submission%TYPE;
    BEGIN
    
        IF NOT get_doc_sub_from_doc_ext(i_lang, i_prof, i_doc_external, l_xds_doc_submission, o_error)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_xds_doc_submission;
    
    END get_doc_sub_from_doc_ext;
    --

    FUNCTION update_document_submission
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_flg_status         IN xds_document_submission.flg_submission_status%TYPE,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_xds_doc_submission IN xds_document_submission.id_xds_document_submission%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_xds_doc_submission xds_document_submission.id_xds_document_submission%TYPE;
    
    BEGIN
        g_error := 'Validate input parameter';
        IF i_xds_doc_submission IS NULL
           AND i_doc_external IS NOT NULL
        THEN
            l_xds_doc_submission := pk_hie_xds.get_doc_sub_from_doc_ext(i_lang         => i_lang,
                                                                        i_prof         => i_prof,
                                                                        i_doc_external => i_doc_external,
                                                                        o_error        => o_error);
        ELSE
            l_xds_doc_submission := i_xds_doc_submission;
        END IF;
    
        IF i_xds_doc_submission IS NOT NULL
        THEN
            g_error := 'Update document submission status';
            UPDATE xds_document_submission xds
               SET xds.flg_submission_status = i_flg_status, xds.dt_update = current_timestamp
             WHERE xds.id_xds_document_submission = l_xds_doc_submission
                  --To assure that we do not send a cancel message twice
               AND xds.flg_submission_status != g_flg_submission_status_c
               AND xds.flg_status = g_subm_status_a;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'UPDATE_DOCUMENT_SUBMISSION');
            
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END update_document_submission;

    FUNCTION get_institution_group_adt
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_inst_group  OUT institution_group.id_group%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_inst IS
            SELECT id_group
              FROM institution_group ig
             WHERE ig.id_institution = i_institution
               AND ig.flg_relation = 'ADT';
    
    BEGIN
        OPEN c_inst;
        FETCH c_inst
            INTO o_inst_group;
        CLOSE c_inst;
    
        RETURN TRUE;
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_INSTITUTION_GROUP_ADT');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END get_institution_group_adt;

    FUNCTION get_institution_group_adt
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE
    ) RETURN NUMBER IS
        l_inst_group institution_group.id_group%TYPE;
        l_error      t_error_out;
    BEGIN
        IF NOT get_institution_group_adt(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_institution => i_institution,
                                         o_inst_group  => l_inst_group,
                                         o_error       => l_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN l_inst_group;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
            BEGIN
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_INSTITUTION_GROUP_ADT');
                RETURN NULL;
            END;
    END get_institution_group_adt;

    --
    FUNCTION has_doc_ext_been_published(i_id_doc_external IN doc_external.id_doc_external%TYPE) RETURN BOOLEAN IS
        l_number table_number;
    
    BEGIN
        SELECT 1
          BULK COLLECT
          INTO l_number
          FROM xds_document_submission xds
         WHERE xds.id_doc_external = (SELECT nvl(id_grupo, id_doc_external)
                                        FROM doc_external
                                       WHERE id_doc_external = i_id_doc_external)
           AND xds.flg_status = 'A'
           AND xds.flg_submission_type != g_flg_submission_status_d;
    
        RETURN SQL%FOUND;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END has_doc_ext_been_published;

    --
    FUNCTION set_submit_or_upd_doc_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_doc_external       IN doc_external.id_doc_external%TYPE,
        i_conf_code          IN table_varchar,
        i_desc_conf_code     IN table_varchar,
        i_code_coding_schema IN table_varchar,
        i_conf_code_set      IN table_varchar,
        i_desc_conf_code_set IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        -- If it's not the first time, it will be an update
        -- else, it will be new publication
        IF has_doc_ext_been_published(i_doc_external)
        THEN
            -- delete doc. user has update the doc and sent no  Conf codes
            IF i_conf_code_set IS NULL
               OR i_conf_code_set.count = 0
            THEN
                IF NOT delist_doc(i_lang, i_prof, i_doc_external, o_error)
                THEN
                    RAISE l_exception;
                END IF;
            ELSE
                -- update doc   
                IF NOT set_submit_doc_internal(i_lang,
                                               i_prof,
                                               i_doc_external, --i_doc_external  ,
                                               i_conf_code,
                                               i_desc_conf_code,
                                               i_code_coding_schema,
                                               i_conf_code_set,
                                               i_desc_conf_code_set,
                                               g_flg_submission_status_u, --i_flg_status (UPDATE),
                                               NULL,
                                               o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        ELSE
        
            -- If user dont define the conf codes
            IF i_conf_code_set IS NOT NULL
               AND i_conf_code_set.count > 0
            THEN
            
                IF NOT set_submit_doc_internal(i_lang,
                                               i_prof,
                                               i_doc_external, --i_doc_external  ,
                                               i_conf_code,
                                               i_desc_conf_code,
                                               i_code_coding_schema,
                                               i_conf_code_set,
                                               i_desc_conf_code_set,
                                               g_flg_submission_status_n, --i_flg_status (NEW),
                                               NULL,
                                               o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in  t_error_in := t_error_in();
                l_error_out t_error_out;
                l_lang      NUMBER := to_number(pk_login_sysconfig.get_config('LANGUAGE'));
            BEGIN
                l_error_in.set_all(l_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'SET_SUBMIT_OR_UPD_DOC_INTERNAL');
                RETURN pk_alert_exceptions.process_error(l_error_in, l_error_out);
            END;
    END set_submit_or_upd_doc_internal;

    FUNCTION set_submit_doc_error
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_doc_external IN doc_external.id_doc_external%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
        l_id_grupo                   doc_external.id_grupo%TYPE;
        l_id_xds_document_submission xds_document_submission.id_xds_document_submission%TYPE;
        l_id_doc_external            doc_external.id_doc_external%TYPE;
    
        l_result BOOLEAN;
    BEGIN
    
        g_error := 'get the outside id_DOC_EXTERNAL - (the id_grupo) ';
        SELECT nvl(id_grupo, id_doc_external)
          INTO l_id_doc_external
          FROM doc_external
         WHERE id_doc_external = i_doc_external;
    
        g_error := 'Get last id_xds_document_submission by id_doc_external ';
        BEGIN
            SELECT id_xds_document_submission
              INTO l_id_xds_document_submission
              FROM (SELECT id_xds_document_submission
                      FROM xds_document_submission xds
                     WHERE id_doc_external = l_id_doc_external
                       AND xds.flg_status = 'I'
                     ORDER BY xds.dt_update, xds.dt_create DESC)
             WHERE rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF l_id_xds_document_submission IS NULL
        THEN
            --it means that there are no inactive records for this document
            --This was the first submission for this document. 
            --Once it wasn't sucessfull, we will delete it
        
            g_error := 'Delete from XDS_DOC_SUB_CONF_CODE_SET ';
            DELETE FROM xds_doc_sub_conf_code_set s
             WHERE s.id_xds_document_submission IN
                   (SELECT x.id_xds_document_submission
                      FROM xds_document_submission x
                     WHERE id_doc_external = l_id_doc_external);
        
            g_error := 'Delete from XDS_DOCUMENT_SUB_CONF_CODE ';
            DELETE FROM xds_document_sub_conf_code s
             WHERE s.id_xds_document_submission IN
                   (SELECT x.id_xds_document_submission
                      FROM xds_document_submission x
                     WHERE id_doc_external = l_id_doc_external);
        
            g_error := 'Delete from XDS_DOCUMENT_SUB_CONF_CODE ';
            DELETE FROM xds_document_submission x
             WHERE id_doc_external = l_id_doc_external;
        
            -- delete the history that indicates that the document was shared
            l_result := pk_doc_activity.delete_document_activity(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_doc_id    => l_id_doc_external,
                                                                 i_operation => 'TRANSMIT',
                                                                 i_source    => 'EHR',
                                                                 i_target    => 'HIE',
                                                                 o_error     => o_error);
        
        ELSE
            --there was a previous action before this attempt. 
            -- that attempt (submissoin was l_id_xds_document_submission
            --lets restore the previous value
        
            --delete current records
            g_error := 'Delete from XDS_DOC_SUB_CONF_CODE_SET ';
            DELETE FROM xds_doc_sub_conf_code_set s
             WHERE s.id_xds_document_submission IN (SELECT x.id_xds_document_submission
                                                      FROM xds_document_submission x
                                                     WHERE id_doc_external = l_id_doc_external
                                                       AND flg_status = 'A');
        
            g_error := 'Delete from XDS_DOCUMENT_SUB_CONF_CODE ';
            DELETE FROM xds_document_sub_conf_code s
             WHERE s.id_xds_document_submission IN (SELECT x.id_xds_document_submission
                                                      FROM xds_document_submission x
                                                     WHERE id_doc_external = l_id_doc_external
                                                       AND flg_status = 'A');
        
            g_error := 'Delete from XDS_DOCUMENT_SUB_CONF_CODE ';
            DELETE FROM xds_document_submission x
             WHERE id_doc_external = l_id_doc_external
               AND flg_status = 'A';
        
            --activating previous record
            UPDATE xds_document_submission x
               SET x.flg_status = 'A', x.dt_update = current_timestamp
             WHERE x.id_xds_document_submission = l_id_xds_document_submission;
        
            -- delete the history that indicates that the document was shared
            l_result := pk_doc_activity.delete_document_activity(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_doc_id    => l_id_doc_external,
                                                                 i_operation => 'TRANSMIT',
                                                                 i_source    => 'EHR',
                                                                 i_target    => 'HIE',
                                                                 o_error     => o_error);
        
        END IF;
    
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
                                              'SET_SUBMIT_DOC_ERROR',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_submit_doc_error;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_hie_xds;
/
