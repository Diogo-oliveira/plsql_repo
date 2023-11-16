/*-- Last Change Revision: $Rev: 2026750 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:47 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_approval IS

    /**
    * Procedure that raises an error. 
    *
    * @param i_sqlcode            SQLCODE
    * @param i_sqlerr             SQLERR
    * @param i_func_name          Function that raised the error
    * @param i_error              Error custom text
    *
    * @version               2.5.0.5
    */
    PROCEDURE raise_error
    (
        i_sqlcode   VARCHAR2,
        i_sqlerr    VARCHAR2,
        i_func_name VARCHAR2,
        i_error     VARCHAR2
    ) IS
    BEGIN
        pk_alert_exceptions.raise_error(error_code_in => i_sqlcode,
                                        text_in       => pk_approval.g_package_name || '.' || i_func_name || ' ' ||
                                                         i_error || ' ' || i_sqlerr);
    END;

    /**
    * Gets the value representation of a property 
    *
    * @param i_value      Value of the property
    * @param i_val_table  Map of values and their representation
    * @param i_default    Default value
    * 
    * @return the value representation
    *
    * @version               2.5.0.5
    */
    FUNCTION get_value_representation
    (
        i_value     VARCHAR2,
        i_val_table val_representation_table,
        i_default   VARCHAR2
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'GET_VALUE_REPRESENTATION';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        FOR i IN 1 .. i_val_table.COUNT
        LOOP
            IF i_val_table(i).val = i_value
            THEN
                RETURN i_val_table(i) .representation;
            END IF;
        END LOOP;
        RETURN i_default;
    END;

    /**
    * Gets a property given its name 
    *
    * @param i_property_name Property name
    * 
    * @return the property type
    *
    * @version               2.5.0.5
    */
    FUNCTION get_property_by_name(i_property_name VARCHAR2) RETURN property_type IS
        l_func_name VARCHAR2(32) := 'GET_PROPERTY_BY_NAME';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        FOR i IN 1 .. g_properties.COUNT
        LOOP
            IF g_properties(i).name = i_property_name
            THEN
                RETURN g_properties(i);
            END IF;
        END LOOP;
    END;

    /**
    * Gets a property representation 
    *
    * @param i_property_name Property name
    * @param i_property_value Property value
    * 
    * @return the property representation
    *
    * @version               2.5.0.5
    */
    FUNCTION get_property_representation
    (
        i_property_name  VARCHAR2,
        i_property_value VARCHAR2
    ) RETURN VARCHAR2 IS
        property    property_type;
        l_func_name VARCHAR2(32) := 'GET_PROPERTY_REPRESENTATION';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
        FOR i IN 1 .. g_properties.COUNT
        LOOP
            property := get_property_by_name(i_property_name);
            RETURN get_value_representation(i_property_value, property.values_representations, property.default_value);
        END LOOP;
    END;

    /**
    * Return the string representation of the properties
    *
    * @param i_property_names Property name list
    * @param i_property_values Property value list
    * 
    * @return the property representation
    *
    * @version               2.5.0.5
    */
    FUNCTION make_apprv_properties_field
    (
        i_property_names  IN table_varchar,
        i_property_values IN table_varchar
    ) RETURN VARCHAR2 IS
        l_ret       approval_request.approval_properties%TYPE := '';
        l_func_name VARCHAR2(32) := 'MAKE_APPRV_PROPERTIES_FIELD';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
        IF i_property_names IS NULL
           OR i_property_names.COUNT = 0
        THEN
            RETURN l_ret;
        END IF;
        FOR i IN 1 .. i_property_names.COUNT
        LOOP
            l_ret := l_ret || get_property_representation(i_property_names(i), i_property_values(i));
        END LOOP;
        RETURN l_ret;
    END;

    /**
    * This function checks if a given episode is a nursing related episode
    *
    * @param i_et            ID_EPIS_TYPE
    *
    * @return                Y - if nurse related, N - otherwise
    *
    * @version               2.5.0.5
    */
    FUNCTION is_nurse_et(i_et NUMBER) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'IS_NURSE_ET';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
        IF i_et = pk_ehr_common.g_epis_type_enf_care
           OR i_et = pk_ehr_common.g_epis_type_enf_outp
           OR i_et = pk_ehr_common.g_epis_type_enf_pp
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    END;

    /**
    * Return the value of a string representation
    *
    * @param i_property_name       Property name list
    * @param i_approval_properties Property representation
    * 
    * @return the property value
    *
    * @version               2.5.0.5
    */
    FUNCTION get_property_value
    (
        i_property_name       VARCHAR,
        i_approval_properties approval_request.approval_properties%TYPE
    ) RETURN VARCHAR IS
        l_property property_type;
        l_val_rep  val_representation_table;
    
        l_func_name VARCHAR2(32) := 'GET_PROPERTY_VALUE';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        l_property := get_property_by_name(i_property_name);
        l_val_rep  := l_property.values_representations;
        FOR i IN 1 .. l_val_rep.COUNT
        LOOP
            IF instr(i_approval_properties, l_val_rep(i).representation) > 0
            THEN
                RETURN l_val_rep(i) .val;
            END IF;
        END LOOP;
        RETURN NULL;
    END;

    /**
    * This function returns a an list of the epis_type that available for the given professional
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional identifier
    *
    * @return                List of id_epis_type
    *
    * @version               2.5.0.5
    */
    FUNCTION get_inst_epis_type
    (
        i_lang IN LANGUAGE.id_language%TYPE,
        i_prof IN profissional
    ) RETURN et_rec_list_t
        PIPELINED IS
        l_nurse_count NUMBER;
    
        l_et_list et_rec_list_t;
    
        l_func_name VARCHAR2(32) := 'GET_INST_EPIS_TYPE';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        -- check nurse epis_type count
        g_error := 'CHECK NURSE EPIS_TYPE COUNT';
        SELECT COUNT('X')
          INTO l_nurse_count
          FROM epis_type et
         INNER JOIN epis_type_soft_inst etsi ON etsi.id_epis_type = et.id_epis_type
                                            AND etsi.id_institution IN
                                                (SELECT MAX(e2.id_institution)
                                                   FROM epis_type_soft_inst e2
                                                  WHERE e2.id_institution IN (0, i_prof.institution)
                                                    AND e2.id_epis_type = et.id_epis_type)
         WHERE etsi.id_software IN (SELECT si.id_software
                                      FROM software_institution si
                                     WHERE si.id_institution = i_prof.institution)
           AND et.id_epis_type IN
               (pk_ehr_common.g_epis_type_enf_care, pk_ehr_common.g_epis_type_enf_outp, pk_ehr_common.g_epis_type_enf_pp);
    
        -- get the epis_type
        g_error := 'GET THE EPIS_TYPE LIST';
        SELECT to_char(et.id_epis_type),
               pk_translation.get_translation(i_lang, et.code_epis_type) ||
               decode(is_nurse_et(et.id_epis_type),
                      pk_alert_constant.g_no,
                      '',
                      decode(l_nurse_count,
                             0,
                             '',
                             1,
                             '',
                             ' (' || REPLACE(pk_translation.get_translation(i_lang, s.code_software), '<br>', ' ') || ')')),
               et.rank,
               NULL icon BULK COLLECT
          INTO l_et_list
          FROM epis_type et
         INNER JOIN epis_type_soft_inst etsi ON etsi.id_epis_type = et.id_epis_type
                                            AND etsi.id_institution IN
                                                (SELECT MAX(e2.id_institution)
                                                   FROM epis_type_soft_inst e2
                                                  WHERE e2.id_institution IN (0, i_prof.institution)
                                                    AND e2.id_epis_type = et.id_epis_type)
         INNER JOIN software s ON s.id_software = etsi.id_software
         WHERE etsi.id_software IN (SELECT si.id_software
                                      FROM software_institution si
                                     WHERE si.id_institution = i_prof.institution);
    
        FOR i IN 1 .. l_et_list.COUNT
        LOOP
            PIPE ROW(l_et_list(i));
        END LOOP;
    
        RETURN;
    END;

    /**
    * Get all the approval types configured for the given professional
    *
    * @param i_prof          Professional identifier
    *
    * @return                List of id_approval_type
    */
    FUNCTION appr_req_has_config_prof(i_prof IN profissional) RETURN table_number IS
        l_types_appr_result table_number;
    
        l_func_name VARCHAR2(32) := 'APPR_REQ_HAS_CONFIG_PROF';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        SELECT ap.id_approval_type BULK COLLECT
          INTO l_types_appr_result
          FROM approval_permission ap
         INNER JOIN approval_prof_perm app ON app.id_approval_type = ap.id_approval_type
                                          AND app.id_institution = ap.id_institution
         INNER JOIN (SELECT dt.id_dept, d.id_department, d.id_clinical_service
                       FROM prof_dep_clin_serv p
                      INNER JOIN dep_clin_serv d ON d.id_dep_clin_serv = p.id_dep_clin_serv
                                                AND d.flg_available = pk_alert_constant.g_yes
                      INNER JOIN department dt ON dt.id_department = d.id_department
                                              AND d.flg_available = pk_alert_constant.g_yes
                      WHERE p.id_institution = i_prof.institution
                        AND p.id_professional = i_prof.id) pi ON (pi.id_dept = app.id_dept OR app.id_dept = 0)
                                                             AND (pi.id_department = app.id_department OR
                                                                 app.id_department = 0)
                                                             AND (pi.id_clinical_service = app.id_clinical_service OR
                                                                 app.id_clinical_service = 0);
    
        RETURN l_types_appr_result;
    END;

    /**
    * Runs an approval function
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional identifier
    * @param i_id_external            External identifier
    * @param i_id_approval_function   Approval type function
    *
    * @return                         The function return value in VARCHAR2
    */
    FUNCTION run_approval_function
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_external          IN approval_request.id_external%TYPE,
        i_id_approval_function IN approval_function.id_approval_function%TYPE,
        i_is_dml               IN VARCHAR
    ) RETURN VARCHAR2 IS
        l_func_name       VARCHAR2(32) := 'RUN_APPROVAL_FUNCTION';
        l_func_to_execute VARCHAR2(4000);
        l_result          VARCHAR2(4000);
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        g_error := 'GET FUNCTION TO EXECUTE: ' || i_id_approval_function;
        SELECT af.FUNCTION
          INTO l_func_to_execute
          FROM approval_function af
         WHERE af.id_approval_function = i_id_approval_function;
    
        IF i_is_dml = pk_alert_constant.g_yes
        THEN
            g_error := 'EXECUTE IMMEDIATE DML ' || i_id_approval_function;
        
            l_func_to_execute := 'BEGIN :1 := ' || l_func_to_execute || ' END;';
            EXECUTE IMMEDIATE l_func_to_execute
                USING OUT l_result, i_lang, i_prof.id, i_prof.institution, i_prof.software, i_id_external;
        
        ELSE
            g_error := 'EXECUTE IMMEDIATE' || i_id_approval_function;
            EXECUTE IMMEDIATE l_func_to_execute
                INTO l_result
                USING i_lang, i_prof.id, i_prof.institution, i_prof.software, i_id_external;
        
        END IF;
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
            RETURN NULL;
        
    END;

    /**
    * Send the active record in approval_request to history (approval_request_history)
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional identifier
    * @param i_id_approval_type       Approval type identifier
    * @param i_id_external            External identifier
    *
    * @return                         Nothing   
    */
    PROCEDURE send_curr_record_to_history
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) IS
        l_current_record approval_request%ROWTYPE;
    
        l_rowids table_varchar;
    
        l_error t_error_out;
    
        l_func_name VARCHAR2(32) := 'SEND_CURR_RECORD_TO_HISTORY';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        -- get the current record that will be sent to history
        g_error := 'GET CURRENT RECORD';
        SELECT *
          INTO l_current_record
          FROM approval_request ar
         WHERE ar.id_approval_type = i_id_approval_type
           AND ar.id_external = i_id_external;
    
        -- Insert the history record
        g_error := 'TS_APPROVAL_REQUEST_HIST.INS';
        ts_approval_request_hist.ins(id_approval_request_hist_in => ts_approval_request_hist.next_key,
                                     id_approval_type_in         => l_current_record.id_approval_type,
                                     id_external_in              => l_current_record.id_external,
                                     id_prof_resp_in             => l_current_record.id_prof_resp,
                                     flg_status_in               => l_current_record.flg_status,
                                     flg_action_in               => l_current_record.flg_action,
                                     id_prof_action_in           => l_current_record.id_prof_action,
                                     approval_properties_in      => l_current_record.approval_properties,
                                     dt_action_in                => l_current_record.dt_action,
                                     notes_in                    => l_current_record.notes,
                                     rows_out                    => l_rowids);
    
        g_error := 'T_DATA_GOV_MNT.PROCESS_INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'APPROVAL_REQUEST_HIST',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    
    END;

    /**
    * Returns the flg_status after doing some action
    *
    * @param i_flg_action             FLG_ACTION
    * @param i_prof                   Professional identifier
    * @param i_id_approval_type       Approval type identifier
    * @param i_id_external            External identifier
    *
    * @return                         The new FLG_STATUS (null if nothing changes)
    */
    FUNCTION get_new_status_by_action(i_flg_action IN approval_request.flg_action%TYPE)
        RETURN approval_request.flg_status%TYPE IS
        l_ret approval_request.flg_status%TYPE;
    
        l_func_name VARCHAR2(32) := 'GET_NEW_STATUS_BY_ACTION';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        CASE i_flg_action
            WHEN g_action_create_approval THEN
                l_ret := g_approval_request_pending;
            WHEN g_action_approve_approval THEN
                l_ret := g_approval_request_approved;
            WHEN g_action_reject_approval THEN
                l_ret := g_approval_request_rejected;
            WHEN g_action_cancel_request THEN
                l_ret := g_approval_request_cancelled;
            WHEN g_action_cancel_decision THEN
                l_ret := g_approval_request_pending;
            WHEN g_action_send_request THEN
                l_ret := g_approval_request_pending;
            WHEN g_action_update_request THEN
                l_ret := NULL;
            WHEN g_action_change_prof_resp THEN
                l_ret := NULL;
        END CASE;
        RETURN l_ret;
    END;

    /**
    * Returns the professional ID if the action is an atribution of approval to the given professional.
    * Null otherwise.
    *
    * @param i_prof                   Professional identifier
    * @param i_flg_action             Action performed
    *
    * @return       The professional ID if we the action is an atribution of approval to the given professional. Null otherwise.
    */
    FUNCTION get_prof_resp_by_action
    (
        i_prof       IN profissional,
        i_flg_action IN approval_request.flg_action%TYPE
    ) RETURN approval_request.id_prof_resp%TYPE IS
        l_ret approval_request.id_prof_resp%TYPE;
    
        l_func_name VARCHAR2(32) := 'GET_PROF_RESP_BY_ACTION';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        CASE i_flg_action
            WHEN g_action_change_prof_resp THEN
                l_ret := i_prof.id;
            ELSE
                l_ret := NULL;
        END CASE;
        RETURN l_ret;
    END;

    /**
    * Returns the professional ID if we the action is an update of an approval to the given professional.
    * Null otherwise.
    *
    * @param i_prof                   Professional identifier
    * @param i_flg_action             Action performed
    *
    * @return       The professional ID if we the action is an update of an approval to the given professional. Null otherwise.
    */
    FUNCTION get_prof_req_by_action
    (
        i_prof       IN profissional,
        i_flg_action IN approval_request.flg_action%TYPE
    ) RETURN approval_request.id_prof_req%TYPE IS
        l_ret approval_request.id_prof_req%TYPE;
    
        l_func_name VARCHAR2(32) := 'GET_PROF_REQ_BY_ACTION';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        CASE i_flg_action
            WHEN g_action_send_request THEN
                l_ret := i_prof.id;
            WHEN g_action_update_request THEN
                l_ret := i_prof.id;
            ELSE
                l_ret := NULL;
        END CASE;
        RETURN l_ret;
    END;

    /**
    * Updates an approval request
    *
    * @param i_prof                   Professional identifier
    * @param i_flg_action             Action performed
    * @param i_id_approval_type       Approval type
    * @param i_id_external            External Identifier
    * @param i_flg_action             Action taken
    * @param i_notes                  Notes
    * @param i_property_names         List of property names
    * @param i_property_values        List of property values
    *
    * @return       Nothing
    */
    PROCEDURE update_record
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_flg_action       IN approval_request.flg_action%TYPE,
        i_notes            IN approval_request.notes%TYPE DEFAULT NULL,
        i_property_names   IN table_varchar DEFAULT NULL,
        i_property_values  IN table_varchar DEFAULT NULL
    ) IS
        l_func_name VARCHAR2(32) := 'UPDATE_RECORD';
    
        l_rowids         table_varchar;
        l_flg_status     approval_request.flg_status%TYPE;
        l_prof_resp      approval_request.id_prof_resp%TYPE;
        l_prof_req       approval_request.id_prof_req%TYPE;
        l_properties     approval_request.approval_properties%TYPE;
        l_property_exist BOOLEAN := FALSE;
        l_error          t_error_out;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        -- check input parameters
        g_error := 'INVALID INPUT ARGUMENTS';
        IF i_flg_action IS NULL
        THEN
            RAISE g_exception;
        ELSE
            l_flg_status := get_new_status_by_action(i_flg_action);
            l_prof_resp  := get_prof_resp_by_action(i_prof, i_flg_action);
            l_prof_req   := get_prof_req_by_action(i_prof, i_flg_action);
        END IF;
    
        g_error := 'SEND_CURR_RECORD_TO_HISTORY';
        send_curr_record_to_history(i_lang, i_prof, i_id_approval_type, i_id_external);
    
        pk_approval.g_sysdate_tstz := current_timestamp;
    
        IF i_property_names IS NOT NULL
           AND i_property_names.COUNT > 0
        THEN
            l_property_exist := TRUE;
        END IF;
    
        g_error      := 'MAKE_APPRV_PROPERTIES_FIELD';
        l_properties := make_apprv_properties_field(i_property_names, i_property_values);
    
        g_error := 'UPDATE RECORD';
        ts_approval_request.upd(id_approval_type_in     => i_id_approval_type,
                                id_external_in          => i_id_external,
                                id_prof_req_in          => l_prof_req,
                                id_prof_req_nin         => TRUE,
                                id_prof_resp_in         => l_prof_resp,
                                id_prof_resp_nin        => TRUE,
                                flg_action_in           => i_flg_action,
                                id_prof_action_in       => i_prof.id,
                                flg_status_in           => l_flg_status,
                                flg_status_nin          => TRUE,
                                approval_properties_in  => l_properties,
                                approval_properties_nin => NOT l_property_exist,
                                notes_in                => i_notes,
                                notes_nin               => FALSE,
                                dt_action_in            => g_sysdate_tstz,
                                rows_out                => l_rowids);
    
        g_error := 'T_DATA_GOV_MNT.PROCESS_INSERT';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'APPROVAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => l_error);
    EXCEPTION
        WHEN OTHERS THEN
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
    END;

    /**
    * Checks if an approval belongs to the history (outdated).
    * An approval request is assumed outdated if is in the pending state and have overlimited the time of expiricy.
    *
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @return                Y - if belong to history, N - otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/21
    */
    FUNCTION approval_belongs_to_history
    (
        i_prof             IN profissional,
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'APPROVAL_BELONGS_TO_HISTORY';
    
        l_history VARCHAR2(1);
    
        -- Time that approval requests that are already approved, cancelled or rejected are displayed since the last action date
        l_time_to_expire NUMBER := pk_sysconfig.get_config('APPROVAL_REQUEST_HOURS_TO_EXPIRE', i_prof);
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        BEGIN
            SELECT pk_alert_constant.g_no
              INTO l_history
              FROM approval_request ar
             WHERE ar.id_approval_type = i_id_approval_type
               AND ar.id_external = i_id_external
               AND (ar.dt_action + (l_time_to_expire / 24) > current_timestamp OR
                   ar.flg_status = pk_approval.g_approval_request_pending);
        EXCEPTION
            WHEN no_data_found THEN
                l_history := pk_alert_constant.g_yes;
        END;
    
        RETURN l_history;
    EXCEPTION
        WHEN OTHERS THEN
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
    END;

    /**
    * Checks if an approval has notes (in any transaction).
    *
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @return                Y - if has notes, N - otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/21
    */
    FUNCTION approval_has_notes
    (
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'APPROVAL_HAS_NOTES';
    
        l_result VARCHAR2(1) := pk_alert_constant.g_no;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        g_error := 'CHECKING APPROVAL NOTES';
        BEGIN
            SELECT DISTINCT *
              INTO l_result
              FROM (SELECT pk_alert_constant.g_yes
                      FROM approval_request ar
                     WHERE ar.id_external = i_id_external
                       AND ar.id_approval_type = i_id_approval_type
                       AND ar.notes IS NOT NULL
                    UNION ALL
                    SELECT pk_alert_constant.g_yes
                      FROM approval_request_hist arh
                     WHERE arh.id_external = i_id_external
                       AND arh.id_approval_type = i_id_approval_type
                       AND arh.notes IS NOT NULL);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
            RETURN NULL;
    END;

    /**
    * This function provides the list of approval requests for all the grids on the Director software (search included).
    * It is based on filters, so if we want all the approval requests for a given patient, we just have to provide
    * the patient ID and activate the filter i_filter_by_patient using the value 'Y'
    *
    * @param i_lang                Language id
    * @param i_prof                Professional id
    * @param i_id_patient          Patient id
    * @param i_filter_by_prof      Professional filter (Y/N)
    * @param i_filter_by_patient   Patient  filter (Y/N)
    * @param i_filter_by_history   History  filter (Y/N)
    * @param i_filter_by_dcs       Dep_clin_serv filter (Y/N)
    * @param i_filter_by_search    Search screen filter (Y/N)
    * @param i_filter_by_prof_req  IN table_number DEFAULT NULL,
    * @param i_filter_by_dir_resp  Director responsible filter (id list/null)
    * @param i_filter_by_origin    Origin filter (id list/null)
    * @param i_filter_by_req_date  Requisition date filter (date list/null)
    * @param i_filter_by_app_type  Approval type filter (id list/null)
    * @param i_filter_by_app_state Approval status filter (flag list/null)
    * @param i_filter_by_app_desc  Approval description filter (desc list/null)
    *
    * @param o_approvals           Approval requests list
    * @param o_appr_types          Approval types list
    * @param o_error               Error object
    *
    * @return                True if success, false otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/21
    */
    FUNCTION get_approval_requests
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE DEFAULT NULL,
        i_filter_by_prof      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_patient   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_history   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_dcs       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_search    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_filter_by_prof_req  IN table_number DEFAULT NULL,
        i_filter_by_dir_resp  IN table_number DEFAULT NULL,
        i_filter_by_origin    IN table_number DEFAULT NULL,
        i_filter_by_req_date  IN VARCHAR2 DEFAULT NULL,
        i_filter_by_app_type  IN table_number DEFAULT NULL,
        i_filter_by_app_state IN table_varchar DEFAULT NULL,
        i_filter_by_app_desc  IN VARCHAR2 DEFAULT NULL,
        o_approvals           OUT pk_types.cursor_type,
        o_appr_types          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_APPROVAL_REQUEST_LIST';
    
        l_appr_type_with_access table_number := appr_req_has_config_prof(i_prof);
    
        l_label_with_notes sys_message.desc_message%TYPE := '(' ||
                                                            pk_message.get_message(i_lang      => i_lang,
                                                                                   i_prof      => i_prof,
                                                                                   i_code_mess => 'COMMON_M008') || ')';
    
        -- search related variables
        l_count NUMBER;
        l_limit NUMBER;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        -- get search parameters (if necessary)
        IF i_filter_by_search = pk_alert_constant.g_yes
        THEN
            g_error := 'GET SEARCH LIMIT';
            l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        
            g_error := 'GET SEARCH COUNT';
            SELECT COUNT(1)
              INTO l_count
              FROM approval_request ar
             INNER JOIN approval_type at ON at.id_approval_type = ar.id_approval_type
              LEFT JOIN episode e ON e.id_episode = ar.id_episode
              LEFT JOIN epis_info ei ON ei.id_episode = ar.id_episode
             WHERE
            -- COMMON FILTERS
            -- filter by institution
             e.id_institution = i_prof.institution
            -- GRID FILTERS --
            -- filter by expire date
             AND ((approval_belongs_to_history(i_prof, ar.id_approval_type, ar.id_external) = pk_alert_constant.g_no AND
             i_filter_by_history = pk_alert_constant.g_no) OR i_filter_by_history = pk_alert_constant.g_yes OR
             i_filter_by_search = pk_alert_constant.g_yes)
            -- filter by history records
             AND ((approval_belongs_to_history(i_prof, ar.id_approval_type, ar.id_external) = pk_alert_constant.g_yes AND
             i_filter_by_history = pk_alert_constant.g_yes) OR i_filter_by_history = pk_alert_constant.g_no OR
             i_filter_by_search = pk_alert_constant.g_yes)
            -- filter by professional
             AND ((ar.id_prof_resp = i_prof.id AND i_filter_by_prof = pk_alert_constant.g_yes) OR
             i_filter_by_prof = pk_alert_constant.g_no OR i_filter_by_search = pk_alert_constant.g_yes)
            -- filter by approval type configuration
             AND (ar.id_approval_type IN (SELECT *
                                        FROM TABLE(l_appr_type_with_access)) OR
             (ar.id_prof_resp = i_prof.id AND i_filter_by_prof = pk_alert_constant.g_yes))
            -- filter by dep_clin_serv
             AND (((ei.id_dep_clin_serv IN
             (SELECT id_dep_clin_serv
                   FROM prof_dep_clin_serv pdcs
                  WHERE pdcs.id_professional = i_prof.id
                    AND pdcs.flg_status = pk_approval.g_flg_selected
                    AND pdcs.id_institution IN (0, i_prof.institution)) AND
             i_filter_by_dcs = pk_alert_constant.g_yes) OR ei.id_dep_clin_serv IS NULL) OR
             i_filter_by_dcs = pk_alert_constant.g_no)
            -- filter by patient
             AND ((ar.id_patient = i_id_patient AND i_filter_by_patient = pk_alert_constant.g_yes) OR
             i_filter_by_patient = pk_alert_constant.g_no OR i_filter_by_search = pk_alert_constant.g_yes)
            -- SEARCH SCREEN FILTERS --
            -- filter by the professional that made the request
             AND (ar.id_prof_req IN (SELECT *
                                   FROM TABLE(i_filter_by_prof_req)) OR i_filter_by_prof_req IS NULL)
            -- filter by the director responsible for the request
             AND (ar.id_prof_resp IN (SELECT *
                                    FROM TABLE(i_filter_by_dir_resp)) OR i_filter_by_dir_resp IS NULL)
            -- filter by origin
             AND (e.id_epis_type IN (SELECT *
                                   FROM TABLE(i_filter_by_origin)) OR i_filter_by_origin IS NULL)
            -- filter by the date of the request
             AND ((pk_date_utils.to_char_insttimezone(i_prof, ar.dt_request, 'DD-MM-YYYY') = i_filter_by_req_date) OR
             i_filter_by_req_date IS NULL)
            -- filter by approval type
             AND (ar.id_approval_type IN (SELECT *
                                        FROM TABLE(i_filter_by_app_type)) OR i_filter_by_app_type IS NULL)
            -- filter by approval state
             AND (ar.flg_status IN (SELECT *
                                  FROM TABLE(i_filter_by_app_state)) OR i_filter_by_app_state IS NULL)
            -- filter by approval request description
             AND ((pk_utils.remove_upper_accentuation(run_approval_function(i_lang,
                                                                        i_prof,
                                                                        ar.id_external,
                                                                        at.id_approv_func_info,
                                                                        pk_alert_constant.g_no)) LIKE
             '%' || pk_utils.remove_upper_accentuation(i_filter_by_app_desc) || '%') OR i_filter_by_app_desc IS NULL);
        
            IF l_count > l_limit
            THEN
                RAISE pk_search.e_overlimit;
            END IF;
        
            IF l_count = 0
            THEN
                RAISE pk_search.e_noresults;
            END IF;
        END IF;
    
        g_error := 'OPEN O_APPROVALS';
        OPEN o_approvals FOR
            SELECT ar.id_approval_type,
                   ar.id_external,
                   run_approval_function(i_lang, i_prof, ar.id_external, at.id_approv_func_info, pk_alert_constant.g_no) approval_request_desc,
                   ar.id_patient,
                   pk_patient.get_patient_name(i_lang, ar.id_patient) patient_name,
                   ar.id_episode,
                   pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, e.id_epis_type) origin,
                   pk_ehr_common.get_visit_type_by_epis(i_lang, i_prof, e.id_episode, e.id_epis_type, ', ') origin_information,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_prof_req) prof_request_sender,
                   ar.id_prof_resp,
                   decode(ar.id_prof_resp,
                          NULL,
                          pk_approval.g_no_record_notation,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, ar.id_prof_resp)) prof_director,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    get_base_elapsed_time(ar.id_approval_type, ar.id_external),
                                                    i_prof.institution,
                                                    i_prof.software) request_hour,
                   pk_date_utils.dt_chr_tsz(i_lang, get_base_elapsed_time(ar.id_approval_type, ar.id_external), i_prof) request_date,
                   to_char(get_base_elapsed_time(ar.id_approval_type, ar.id_external),
                           pk_alert_constant.g_dt_yyyymmddhh24miss) order_date,
                   at.code_approval_icon approval_type_icon,
                   pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        decode(ar.flg_status,
                                                               pk_approval.g_approval_request_pending,
                                                               pk_alert_constant.g_display_type_date_icon,
                                                               pk_alert_constant.g_display_type_icon),
                                                        ar.flg_status,
                                                        NULL,
                                                        to_char(get_base_elapsed_time(ar.id_approval_type,
                                                                                      ar.id_external),
                                                                pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                        'APPROVAL_REQUEST.FLG_STATUS',
                                                        NULL,
                                                        decode(ar.flg_status,
                                                               pk_approval.g_approval_request_pending,
                                                               pk_approval.g_color_red,
                                                               NULL),
                                                        decode(ar.flg_status,
                                                               pk_approval.g_approval_request_pending,
                                                               pk_approval.g_color_icon,
                                                               NULL)) request_status,
                   ar.flg_status,
                   pk_approval.chk_cancel_director_decision(i_lang, i_prof, ar.id_approval_type, ar.id_external) can_cancel,
                   ar.approval_properties,
                   (SELECT af.file_name || '.' || af.file_extension
                      FROM application_file af
                     WHERE af.id_application_file = at.id_swf_file_detail) swf_file_detail,
                   (SELECT af.file_name || '.' || af.file_extension
                      FROM application_file af
                     WHERE af.id_application_file = at.id_swf_file_approve) swf_file_approve,
                   pk_sysdomain.get_rank(i_lang, 'APPROVAL_REQUEST.FLG_STATUS', ar.flg_status) rank,
                   decode(approval_belongs_to_history(i_prof, ar.id_approval_type, ar.id_external),
                          pk_alert_constant.g_no,
                          pk_approval.g_shortcut_patient_app,
                          pk_approval.g_shortcut_patient_hist) dest_shortcut,
                   decode(approval_has_notes(ar.id_approval_type, ar.id_external),
                          pk_alert_constant.g_yes,
                          l_label_with_notes,
                          NULL) with_notes
              FROM approval_request ar
             INNER JOIN approval_type at ON at.id_approval_type = ar.id_approval_type
              LEFT JOIN episode e ON e.id_episode = ar.id_episode
              LEFT JOIN epis_info ei ON ei.id_episode = ar.id_episode
             WHERE (ar.flg_status <> pk_approval.g_approval_request_cancelled OR
                   i_filter_by_search = pk_alert_constant.g_yes)
                  -- COMMON FILTERS
                  -- filter by institution
               AND e.id_institution = i_prof.institution
                  -- GRID FILTERS --
                  -- filter by expire date
               AND ((approval_belongs_to_history(i_prof, ar.id_approval_type, ar.id_external) = pk_alert_constant.g_no AND
                   i_filter_by_history = pk_alert_constant.g_no) OR i_filter_by_history = pk_alert_constant.g_yes OR
                   i_filter_by_search = pk_alert_constant.g_yes)
                  -- filter by history records
               AND ((approval_belongs_to_history(i_prof, ar.id_approval_type, ar.id_external) = pk_alert_constant.g_yes AND
                   i_filter_by_history = pk_alert_constant.g_yes) OR i_filter_by_history = pk_alert_constant.g_no OR
                   i_filter_by_search = pk_alert_constant.g_yes)
                  -- filter by professional
               AND ((ar.id_prof_resp = i_prof.id AND i_filter_by_prof = pk_alert_constant.g_yes) OR
                   i_filter_by_prof = pk_alert_constant.g_no OR i_filter_by_search = pk_alert_constant.g_yes)
                  -- filter by approval type configuration
               AND (ar.id_approval_type IN (SELECT *
                                              FROM TABLE(l_appr_type_with_access)) OR
                   (ar.id_prof_resp = i_prof.id AND i_filter_by_prof = pk_alert_constant.g_yes))
                  -- filter by dep_clin_serv
               AND (((ei.id_dep_clin_serv IN
                   (SELECT id_dep_clin_serv
                         FROM prof_dep_clin_serv pdcs
                        WHERE pdcs.id_professional = i_prof.id
                          AND pdcs.flg_status = pk_approval.g_flg_selected
                          AND pdcs.id_institution IN (0, i_prof.institution)) AND
                   i_filter_by_dcs = pk_alert_constant.g_yes) OR ei.id_dep_clin_serv IS NULL) OR
                   i_filter_by_dcs = pk_alert_constant.g_no)
                  -- filter by patient
               AND ((ar.id_patient = i_id_patient AND i_filter_by_patient = pk_alert_constant.g_yes) OR
                   i_filter_by_patient = pk_alert_constant.g_no OR i_filter_by_search = pk_alert_constant.g_yes)
                  -- SEARCH SCREEN FILTERS --
                  -- filter by the professional that made the request
               AND (ar.id_prof_req IN (SELECT *
                                         FROM TABLE(i_filter_by_prof_req)) OR i_filter_by_prof_req IS NULL)
                  -- filter by the director responsible for the request
               AND (ar.id_prof_resp IN (SELECT *
                                          FROM TABLE(i_filter_by_dir_resp)) OR i_filter_by_dir_resp IS NULL)
                  -- filter by origin
               AND (e.id_epis_type IN (SELECT *
                                         FROM TABLE(i_filter_by_origin)) OR i_filter_by_origin IS NULL)
                  -- filter by the date of the request
               AND ((pk_date_utils.to_char_insttimezone(i_prof, ar.dt_request, 'DD-MM-YYYY') = i_filter_by_req_date) OR
                   i_filter_by_req_date IS NULL)
                  -- filter by approval type
               AND (ar.id_approval_type IN (SELECT *
                                              FROM TABLE(i_filter_by_app_type)) OR i_filter_by_app_type IS NULL)
                  -- filter by approval state
               AND (ar.flg_status IN (SELECT *
                                        FROM TABLE(i_filter_by_app_state)) OR i_filter_by_app_state IS NULL)
                  -- filter by approval request description
               AND ((pk_utils.remove_upper_accentuation(run_approval_function(i_lang,
                                                                              i_prof,
                                                                              ar.id_external,
                                                                              at.id_approv_func_info,
                                                                              pk_alert_constant.g_no)) LIKE
                   '%' || pk_utils.remove_upper_accentuation(i_filter_by_app_desc) || '%') OR
                   i_filter_by_app_desc IS NULL)
             ORDER BY rank ASC, ar.dt_request ASC;
    
        g_error := 'OPEN O_APPR_TYPES';
        OPEN o_appr_types FOR
            SELECT at.id_approval_type,
                   at.id_parent,
                   pk_translation.get_translation(i_lang, at.code_approval_type) approval_type_desc,
                   at.code_approval_icon approval_type_icon
              FROM approval_type at
             WHERE at.id_approval_type IN (SELECT *
                                             FROM TABLE(l_appr_type_with_access))
             ORDER BY approval_type_desc ASC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_approvals);
            pk_types.open_my_cursor(o_appr_types);
            RETURN pk_search.overlimit_handler(i_lang, i_prof, pk_approval.g_package_name, l_func_name, o_error);
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_approvals);
            pk_types.open_my_cursor(o_appr_types);
            RETURN pk_search.noresult_handler(i_lang, i_prof, pk_approval.g_package_name, l_func_name, o_error);
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_approvals);
            pk_types.open_my_cursor(o_appr_types);
            RETURN FALSE;
    END;

    /**
    * Returns the date to use when counting time elapsed.
    *
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @return                The base time for the elapsed time
    *
    * @author                Sérgio Santos
    * @version               2.5.0.7
    * @since                 2009/12/09
    */
    FUNCTION get_base_elapsed_time
    (
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) RETURN approval_request.dt_action%TYPE IS
        l_time_elapsed approval_request.dt_action%TYPE;
    
        l_func_name VARCHAR2(32) := 'GET_BASE_ELAPSED_TIME';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        SELECT MAX(dt_action)
          INTO l_time_elapsed
          FROM (SELECT dt_action
                  FROM approval_request ar
                 WHERE ar.id_approval_type = i_id_approval_type
                   AND ar.id_external = i_id_external
                   AND ar.flg_action IN (g_action_create_approval, g_action_send_request)
                UNION ALL
                SELECT dt_action
                  FROM approval_request_hist arh
                 WHERE arh.id_approval_type = i_id_approval_type
                   AND arh.id_external = i_id_external
                   AND arh.flg_action IN (g_action_create_approval, g_action_send_request));
    
        RETURN l_time_elapsed;
    END;

    /**
    * Returns the professional assigned to a given approval request (null if none).
    *
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @return                The professional assigned to a given approval request (null if none)
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION chk_approv_request_resp
    (
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) RETURN professional.id_professional%TYPE IS
        l_prof_responsible professional.id_professional%TYPE;
    
        l_func_name VARCHAR2(32) := 'CHK_APPROV_REQUEST_RESP';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        SELECT ar.id_prof_resp
          INTO l_prof_responsible
          FROM approval_request ar
         WHERE ar.id_approval_type = i_id_approval_type
           AND ar.id_external = i_id_external;
    
        RETURN l_prof_responsible;
    END;

    /**
    * Checks if the provided approval requests have no responsible or are already assigned to another
    * professional.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_flg_show           Show modal window (Y - yes, N - no)
    * @param o_msg_title          Modal window title
    * @param o_msg_text_highlight Modal window highlighted text
    * @param o_msg_text_detail    Modal window detail text
    * @param o_button             Modal window buttons
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION check_prof_responsibility
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_approval_type   IN table_number,
        i_id_external        IN table_number,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text_highlight OUT VARCHAR2,
        o_msg_text_detail    OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CHECK_PROF_RESPONSIBILITY';
    
        l_prof_responsible_temp professional.id_professional%TYPE;
    
        l_no_responsible         BOOLEAN := FALSE;
        l_other_prof_responsible BOOLEAN := FALSE;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        -- check input parameters
        g_error := 'INVALID INPUT PARAMETERS';
        IF i_lang IS NULL
           OR i_prof IS NULL
           OR i_id_approval_type IS NULL
           OR i_id_approval_type.COUNT = 0
           OR i_id_external IS NULL
           OR i_id_external.COUNT = 0
           OR i_id_external.COUNT <> i_id_approval_type.COUNT
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'LOOP THE APPROVAL REQUESTS';
        FOR i IN 1 .. i_id_approval_type.COUNT
        LOOP
            -- get the professional responsible for the approval
            g_error := 'GET APPROVAL -> I_ID_APPROVAL_TYPE: ' || i_id_approval_type(i) || ' ID_EXTERNAL: ' ||
                       i_id_external(i);
            BEGIN
                l_prof_responsible_temp := chk_approv_request_resp(i_id_approval_type(i), i_id_external(i));
            EXCEPTION
                WHEN OTHERS THEN
                    g_error := 'APPROVAL NOT FOUND. I_ID_APPROVAL_TYPE: ' || i_id_approval_type(i) || ' ID_EXTERNAL: ' ||
                               i_id_external(i);
                    RAISE g_exception;
            END;
        
            l_no_responsible         := l_no_responsible OR l_prof_responsible_temp IS NULL;
            l_other_prof_responsible := l_other_prof_responsible OR l_prof_responsible_temp <> i_prof.id;
        
            -- if we already have a approval with no responsible and another with another professional responsible,
            -- the loop can be interrupted
            EXIT WHEN l_no_responsible AND l_other_prof_responsible;
        END LOOP;
    
        g_error := 'CONSTRUCT OUTPUT';
        IF l_no_responsible
           OR l_other_prof_responsible
        THEN
            o_flg_show           := pk_alert_constant.g_yes;
            o_msg_title          := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'APPROVAL_T011');
            o_msg_text_highlight := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'APPROVAL_T012');
            o_button             := 'NC';
        ELSE
            o_flg_show := pk_alert_constant.g_no;
        END IF;
    
        IF l_no_responsible
           AND l_other_prof_responsible
        THEN
            o_msg_text_detail := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => 'APPROVAL_T015');
        ELSE
            IF l_no_responsible
            THEN
                o_msg_text_detail := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'APPROVAL_T013');
            ELSIF l_other_prof_responsible
            THEN
                o_msg_text_detail := pk_message.get_message(i_lang      => i_lang,
                                                            i_prof      => i_prof,
                                                            i_code_mess => 'APPROVAL_T014');
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    /**
    * Assigns the given professional to the given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @return                Nothing
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    PROCEDURE assign_prof_to_appr_req
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_type.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) IS
        l_func_name VARCHAR2(32) := 'ASSIGN_PROF_TO_APPR_REQ';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        update_record(i_lang, i_prof, i_id_approval_type, i_id_external, pk_approval.g_action_change_prof_resp);
    END;

    /**
    * Checks and sets the professional responsible for the given approval request.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION set_prof_responsible_no_commit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN table_number,
        i_id_external      IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'SET_PROF_RESPONSIBLE_NO_COMMIT';
    
        l_prof_resp_aux professional.id_professional%TYPE;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        -- check input parameters
        g_error := 'INVALID INPUT PARAMETERS';
        IF i_lang IS NULL
           OR i_prof IS NULL
           OR i_id_approval_type IS NULL
           OR i_id_approval_type.COUNT = 0
           OR i_id_external IS NULL
           OR i_id_external.COUNT = 0
           OR i_id_external.COUNT <> i_id_approval_type.COUNT
        THEN
            RAISE g_exception;
        END IF;
    
        -- loop all the approval requests to assign to the current professional the responsability,
        -- except if the responsability is already assigned to him
        g_error := 'LOOP THE APPROVAL REQUESTS';
        FOR i IN 1 .. i_id_approval_type.COUNT
        LOOP
            g_error := 'GET CURRENT PROF RESPONSABILITY';
            -- get current prof responsability
            l_prof_resp_aux := chk_approv_request_resp(i_id_approval_type(i), i_id_external(i));
        
            IF i_prof.id <> l_prof_resp_aux
               OR l_prof_resp_aux IS NULL
            THEN
                --assign this professional responsible for this approval request
                g_error := 'ASSIGN_PROF_TO_APPR_REQ';
                assign_prof_to_appr_req(i_lang             => i_lang,
                                        i_prof             => i_prof,
                                        i_id_approval_type => i_id_approval_type(i),
                                        i_id_external      => i_id_external(i));
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    /**
    * Adds a new approval request for the director
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    * @param i_id_patient         Patient identifier
    * @param i_id_episode         Episode identifier
    * @param i_property_names     Properties identifiers
    * @param i_property_values    Properties values
    * @param i_notes              notes
    *
    * @param o_error              Error object
    *
    * @return                True if succed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/21
    */
    PROCEDURE add_approval_request_nocommit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_id_patient       IN approval_request.id_patient%TYPE,
        i_id_episode       IN approval_request.id_episode%TYPE,
        i_property_names   IN table_varchar,
        i_property_values  IN table_varchar,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_func_name VARCHAR2(32) := 'ADD_APPROVAL_REQUEST';
    
        l_rowids table_varchar;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        g_sysdate_tstz := current_timestamp;
    
        -- check input parameters
        g_error := 'INVALID INPUT PARAMETERS';
        IF i_lang IS NULL
           OR i_prof IS NULL
           OR i_id_approval_type IS NULL
           OR i_id_external IS NULL
           OR i_id_patient IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        -- check configurations
        g_error := 'CHECK CONFIGURATIONS';
        IF appr_req_has_config_prof(i_prof).COUNT = 0
        THEN
            g_error := 'THERE IS NO DIRECTOR SET THAT CAN ANSWER TO THIS REQUEST FOR APPROVAL';
            RAISE g_exception;
        END IF;
    
        -- add the new record
        g_error := 'TS_APPROVAL_REQUEST.INS';
        ts_approval_request.ins(id_approval_type_in    => i_id_approval_type,
                                id_external_in         => i_id_external,
                                id_prof_req_in         => i_prof.id,
                                id_patient_in          => i_id_patient,
                                id_episode_in          => i_id_episode,
                                dt_request_in          => g_sysdate_tstz,
                                flg_status_in          => pk_approval.g_approval_request_pending,
                                flg_action_in          => pk_approval.g_action_create_approval,
                                id_prof_action_in      => i_prof.id,
                                approval_properties_in => make_apprv_properties_field(i_property_names,
                                                                                      i_property_values),
                                dt_action_in           => g_sysdate_tstz,
                                notes_in               => i_notes,
                                rows_out               => l_rowids);
    
        g_error := 'T_DATA_GOV_MNT.PROCESS_INSERT';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'APPROVAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
    END;

    /**
    * Returns the given approval type row from the table approval_type
    *
    * @param i_id_approval_type   Approval type identifier
    *
    * @return                The approval type row
    */
    FUNCTION get_approval_type_record(i_id_approval_type approval_type.id_approval_type%TYPE) RETURN approval_type%ROWTYPE IS
        l_ret approval_type%ROWTYPE;
    
        l_func_name VARCHAR2(32) := 'GET_APPROVAL_TYPE_RECORD';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        SELECT *
          INTO l_ret
          FROM approval_type at
         WHERE at.id_approval_type = i_id_approval_type;
        RETURN l_ret;
    END;

    /**
    * Returns the sql responsible for approving an approval request of a given approval type
    *
    * @param i_id_approval_type   Approval type identifier
    *
    * @return                A VARCHAR2 with the SQL
    */
    FUNCTION get_approv_func_approve(i_id_approval_type approval_type.id_approval_type%TYPE)
        RETURN approval_function.id_approval_function%TYPE IS
    
        l_func_name VARCHAR2(32) := 'GET_APPROV_FUNC_APPROVE';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN get_approval_type_record(i_id_approval_type) .id_approv_func_approve;
    END;

    /**
    * Approve a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION approve_appr_request_no_commit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'APPROVE_APPR_REQUEST_NO_COMMIT';
        l_func_to_execute approval_function.id_approval_function%TYPE;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        g_error           := 'GET FUNCTION TO EXECUTE';
        l_func_to_execute := get_approv_func_approve(i_id_approval_type);
    
        g_error := 'RUN_APPROVAL_FUNCTION';
        IF run_approval_function(i_lang                 => i_lang,
                                 i_prof                 => i_prof,
                                 i_id_external          => i_id_external,
                                 i_id_approval_function => l_func_to_execute,
                                 i_is_dml               => pk_alert_constant.g_yes) = pk_alert_constant.g_no
        THEN
            g_error := 'ERROR CALLING ' || l_func_to_execute;
            RAISE g_exception;
        ELSE
            g_error := 'UPDATE_RECORD';
            update_record(i_lang, i_prof, i_id_approval_type, i_id_external, g_action_approve_approval, i_notes);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    /**
    * Returns the sql responsible for rejecting an approval request of a given approval type
    *
    * @param i_id_approval_type   Approval type identifier
    *
    * @return                A VARCHAR2 with the SQL
    */
    FUNCTION get_approv_func_reject(i_id_approval_type approval_type.id_approval_type%TYPE)
        RETURN approval_function.id_approval_function%TYPE IS
    
        l_func_name VARCHAR2(32) := 'GET_APPROV_FUNC_REJECT';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN get_approval_type_record(i_id_approval_type) .id_approv_func_reject;
    END;

    /**
    * Reject a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION reject_appr_request_no_commit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'REJECT_APPR_REQUEST_NO_COMMIT';
        l_func_to_execute approval_function.id_approval_function%TYPE;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        g_error           := 'GET FUNCTION TO EXECUTE';
        l_func_to_execute := get_approv_func_reject(i_id_approval_type);
        IF run_approval_function(i_lang, i_prof, i_id_external, l_func_to_execute, pk_alert_constant.g_yes) =
           pk_alert_constant.g_no
        THEN
            g_error := 'ERROR CALLING ' || l_func_to_execute;
            RAISE g_exception;
        ELSE
            update_record(i_lang, i_prof, i_id_approval_type, i_id_external, g_action_reject_approval, i_notes);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    /**
    * Returns the sql responsible for checking the cancel possibility of an approval request of 
    * a given approval type
    *
    * @param i_id_approval_type   Approval type identifier
    *
    * @return                A VARCHAR2 with the SQL
    */
    FUNCTION get_approv_func_chk_cancel(i_id_approval_type approval_type.id_approval_type%TYPE)
        RETURN approval_function.id_approval_function%TYPE IS
    
        l_func_name VARCHAR2(32) := 'GET_APPROV_FUNC_CHK_CANCEL';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN get_approval_type_record(i_id_approval_type) .id_approv_func_chk_canc;
    END;

    /**
    * Checks if the decision made by an approval request can be cancelled
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                Y - Can cancel the decision, N - otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION chk_cancel_director_decision
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'CHK_CANCEL_DIRECTOR_DECISION';
    
        l_current_status approval_request.flg_status%TYPE;
        l_prof_resp      professional.id_professional%TYPE;
    
        l_id_func approval_function.id_approval_function%TYPE;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        -- check input parameters
        g_error := 'INVALID INPUT PARAMETERS';
        IF i_prof IS NULL
           OR i_id_approval_type IS NULL
           OR i_id_external IS NULL
        THEN
            RAISE g_exception;
        END IF;
    
        -- get the director and the status
        g_error := 'GET THE DIRECTOR AND THE STATUS';
        SELECT ar.id_prof_resp, ar.flg_status
          INTO l_prof_resp, l_current_status
          FROM approval_request ar
         WHERE ar.id_approval_type = i_id_approval_type
           AND ar.id_external = i_id_external;
    
        -- check if the director responsible is the same that the given professional
        IF l_prof_resp <> i_prof.id
           OR l_prof_resp IS NULL
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        -- check if the decision can be cancelled based on the status of the approval request
        IF l_current_status = pk_approval.g_approval_request_pending
           OR l_current_status = pk_approval.g_approval_request_cancelled
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        -- get the function id to execute
        SELECT at.id_approv_func_chk_canc
          INTO l_id_func
          FROM approval_type at
         WHERE at.id_approval_type = i_id_approval_type;
    
        -- check if the approval request can be cancelled based on an external function
        RETURN run_approval_function(i_lang, i_prof, i_id_external, l_id_func, pk_alert_constant.g_no);
    EXCEPTION
        WHEN OTHERS THEN
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
            RETURN pk_alert_constant.g_no;
    END;

    /**
    * Returns the sql responsible for cancelling an approval request of a given approval type
    *
    * @param i_id_approval_type   Approval type identifier
    *
    * @return                A VARCHAR2 with the SQL
    */
    FUNCTION get_approv_func_cancel(i_id_approval_type approval_type.id_approval_type%TYPE)
        RETURN approval_function.id_approval_function%TYPE IS
    
        l_func_name VARCHAR2(32) := 'GET_APPROV_FUNC_CANCEL';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN get_approval_type_record(i_id_approval_type) .id_approv_func_cancel;
    END;

    /**
    * Cancel a decision of a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    FUNCTION canc_appr_req_decis_no_commit
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_approval_type   IN approval_request.id_approval_type%TYPE,
        i_id_external        IN approval_request.id_external%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text_highlight OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'CANC_APPR_REQ_DECIS_NO_COMMIT';
    
        l_func_to_execute approval_function.id_approval_function%TYPE;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        g_error           := 'GET FUNCTION TO EXECUTE';
        l_func_to_execute := get_approv_func_chk_cancel(i_id_approval_type);
    
        IF run_approval_function(i_lang, i_prof, i_id_external, l_func_to_execute, pk_alert_constant.g_no) =
           pk_alert_constant.g_no
        THEN
            o_flg_show           := pk_alert_constant.g_yes;
            o_msg_title          := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'APPROVAL_T024');
            o_msg_text_highlight := pk_message.get_message(i_lang      => i_lang,
                                                           i_prof      => i_prof,
                                                           i_code_mess => 'APPROVAL_T027');
        ELSE
            g_error           := 'UPDATE THE RECORD';
            l_func_to_execute := get_approv_func_cancel(i_id_approval_type);
            IF run_approval_function(i_lang, i_prof, i_id_external, l_func_to_execute, pk_alert_constant.g_yes) =
               pk_alert_constant.g_no
            THEN
                g_error    := 'ERROR CALLING ' || l_func_to_execute;
                o_flg_show := pk_alert_constant.g_no;
                RAISE g_exception;
            ELSE
                update_record(i_lang, i_prof, i_id_approval_type, i_id_external, g_action_cancel_decision);
            
                o_flg_show := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    /**
    * Cancel a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    PROCEDURE cancel_appr_req_nocommit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_func_name VARCHAR2(32) := 'CANCEL_APPR_REQ_NOCOMMIT';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        update_record(i_lang, i_prof, i_id_approval_type, i_id_external, g_action_cancel_request, i_notes);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
    END;

    /**
    * Update a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    * @param i_property_names     Properties identifiers
    * @param i_property_values    Properties values
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    PROCEDURE update_appr_req_nocommit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_property_names   IN table_varchar,
        i_property_values  IN table_varchar,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_func_name VARCHAR2(32) := 'UPDATE_APPR_REQ_NOCOMMIT';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        update_record(i_lang,
                      i_prof,
                      i_id_approval_type,
                      i_id_external,
                      g_action_update_request,
                      i_notes,
                      i_property_names,
                      i_property_values);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
    END;

    /**
    * Send a given approval request
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_approval_type   Approval type identifier
    * @param i_id_external        External identifier
    * @param i_property_names     Properties identifiers
    * @param i_property_values    Properties values
    * @param i_notes              Notes
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Eduardo Lourenço
    * @version               2.5.0.5
    * @since                 2009/07/24
    */
    PROCEDURE send_appr_req_nocommit
    (
        i_lang             IN LANGUAGE.id_language%TYPE,
        i_prof             IN profissional,
        i_id_approval_type IN approval_request.id_approval_type%TYPE,
        i_id_external      IN approval_request.id_external%TYPE,
        i_property_names   IN table_varchar,
        i_property_values  IN table_varchar,
        i_notes            IN approval_request.notes%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_func_name VARCHAR2(32) := 'SEND_APPR_REQ_NOCOMMIT';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        update_record(i_lang,
                      i_prof,
                      i_id_approval_type,
                      i_id_external,
                      g_action_send_request,
                      i_notes,
                      i_property_names,
                      i_property_values);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
    END;

    /*
    * Function used in the match functionality
    *
    * @param i_lang         Language id
    * @param i_prof         Professional id
    * @param i_episode_temp Temporary episode id
    * @param i_episode      Episode id
    * @param i_patient      Patient id
    * @param i_patient_temp Temporary patient id
    *
    * @param o_error        Error object    
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/08/18
    */
    FUNCTION approval_match
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'APPROVAL_MATCH';
    
        l_rowids table_varchar;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        g_error  := 'APPROVAL_REQUEST';
        l_rowids := table_varchar();
        ts_approval_request.upd(id_patient_in => i_patient,
                                id_episode_in => i_episode,
                                where_in      => ' ID_EPISODE = ' || i_episode_temp,
                                rows_out      => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'APPROVAL_REQUEST', l_rowids, o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END;

    /**
    * Function used in the reset functionality
    * (approval_request_hist table)
    *
    * @param i_episode      Episode id
    *
    * @param o_error        Error object    
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/08/18   
    */
    FUNCTION approval_request_hist_reset(i_id_episode IN episode.id_episode%TYPE) RETURN table_varchar IS
        l_func_name VARCHAR2(32) := 'APPROVAL_REQUEST_HIST_RESET';
    
        l_local_rowids table_varchar := table_varchar();
        l_temp_rowid   table_varchar := table_varchar();
    
        l_appr_list app_pk_rec_list;
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        g_error := 'GET APPROVAL REQUESTS TO DELETE';
        SELECT ar.id_approval_type, ar.id_external BULK COLLECT
          INTO l_appr_list
          FROM approval_request ar
         WHERE ar.id_episode = i_id_episode;
    
        FOR i IN 1 .. l_appr_list.COUNT
        LOOP
            g_error := 'DELETE FROM APPROVAL_REQUEST_HIST. id_approval_type = ' || l_appr_list(i)
                      .id_approval_type || ' id_external = ' || l_appr_list(i).id_external;
            DELETE FROM approval_request_hist arh
             WHERE arh.id_approval_type = l_appr_list(i).id_approval_type
               AND arh.id_external = l_appr_list(i).id_external
            RETURNING ROWID BULK COLLECT INTO l_temp_rowid;
        
            l_local_rowids := l_local_rowids MULTISET UNION DISTINCT l_temp_rowid;
        END LOOP;
    
        RETURN l_local_rowids;
    EXCEPTION
        WHEN OTHERS THEN
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
            RETURN NULL;
    END;

    /**
    * Function used in the reset functionality
    * (approval_request table)
    *
    * @param i_episode      Episode id
    *
    * @param o_error        Error object    
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Sérgio Santos
    * @version               2.5.0.5
    * @since                 2009/08/18   
    */
    FUNCTION approval_request_reset(i_id_episode IN episode.id_episode%TYPE) RETURN table_varchar IS
        l_func_name VARCHAR2(32) := 'APPROVAL_REQUEST_RESET';
    
        l_local_rowids table_varchar := table_varchar();
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        g_error := 'DELETE FROM APPROVAL_REQUEST';
        DELETE FROM approval_request ar
         WHERE ar.id_episode = i_id_episode
        RETURNING ROWID BULK COLLECT INTO l_local_rowids;
    
        RETURN l_local_rowids;
    EXCEPTION
        WHEN OTHERS THEN
            raise_error(SQLCODE, SQLERRM, l_func_name, g_error);
            RETURN NULL;
    END;

    /**
    * Initialize a property
    *
    * @param i_name            Episode id
    * @param i_values          List of possible values
    * @param i_representations List of possible representations
    * @param i_default         Default value
    *
    * @return                  A property type
    *
    * @version               2.5.0.5
    */
    FUNCTION initialize_prop
    (
        i_name            VARCHAR2,
        i_values          table_varchar,
        i_representations table_varchar,
        i_default         VARCHAR2
    ) RETURN property_type IS
        l_prop_values        val_representation_table;
        l_val_representation val_representation_type;
        l_property_type      property_type;
    
        l_func_name VARCHAR2(32) := 'INITIALIZE_PROP';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        l_property_type.name := i_name;
        l_prop_values        := val_representation_table();
        l_prop_values.EXTEND(i_values.COUNT);
        FOR i IN 1 .. i_values.COUNT
        LOOP
            l_val_representation.val := i_values(i);
            l_val_representation.representation := i_representations(i);
            l_prop_values(i) := l_val_representation;
        END LOOP;
        l_property_type.values_representations := l_prop_values;
        l_property_type.default_value          := i_default;
        RETURN l_property_type;
    END;

    /**
    * Initialize the attach property
    *
    * @return                  the attach property
    *
    * @version               2.5.0.5
    */
    FUNCTION initialize_attach_prop RETURN property_type IS
    
        l_func_name VARCHAR2(32) := 'INITIALIZE_ATTACH_PROP';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN initialize_prop('ATTACH', table_varchar('Y', 'N'), table_varchar('A', 'a'), ' ');
    END;

    /**
    * Initialize the photo property
    *
    * @return                  the photo property
    *
    * @version               2.5.0.5
    */
    FUNCTION initialize_photo_prop RETURN property_type IS
    
        l_func_name VARCHAR2(32) := 'INITIALIZE_PHOTO_PROP';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN initialize_prop('PHOTO', table_varchar('Y', 'N'), table_varchar('P', 'p'), ' ');
    END;

    /**
    * Initialize all the existent properties
    *
    * @version               2.5.0.5
    */
    PROCEDURE initialize_properties IS
        l_attach_property property_type;
        l_photo_property  property_type;
    
        l_func_name VARCHAR2(32) := 'INITIALIZE_PROPERTIES';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        l_attach_property := initialize_attach_prop();
        l_photo_property  := initialize_photo_prop();
    
        g_properties := property_table(l_attach_property, l_photo_property);
    END;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_info
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'SIMULATE_APPR_FUNC_INFO';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN 'Exame teste simulado nº ' || i_id_external;
    END;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_chk_cancel
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'SIMULATE_APPR_FUNC_CHK_CANCEL';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        IF MOD(i_id_external, 2) = 0
        THEN
            RETURN 'Y';
        ELSE
            RETURN 'N';
        END IF;
    END;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_cancel
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'SIMULATE_APPR_FUNC_CANCEL';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        IF MOD(i_id_external, 2) = 0
        THEN
            RETURN 'Y';
        ELSE
            RETURN 'N';
        END IF;
    END;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_approve
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'SIMULATE_APPR_FUNC_APPROVE';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN 'Y';
    END;

    /**
    * SIMULATION FUNCTION - TO BE DELETED
    */
    FUNCTION simulate_appr_func_reject
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_id_external IN approval_request.id_external%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(32) := 'SIMULATE_APPR_FUNC_REJECT';
    BEGIN
        pk_alertlog.log_info(text            => 'Begin execution of:',
                             object_name     => pk_approval_pbl_ux.g_package_name,
                             sub_object_name => l_func_name);
    
        RETURN 'Y';
    END;
BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

    initialize_properties();
END pk_approval;
/
